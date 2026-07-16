// Package plotter implements the Aftograf-882 XY plotter mechanics,
// accepting movement commands and exposing generated line segments.
package plotter

import (
	"math"
	"github.com/Michael-VT/Aftograf-882/pkg/hpgl"
)

// StepsPerUnit is the number of stepper motor steps per plotter unit.
const StepsPerUnit = 40

// Plotter represents the physical XY plotter state.
type Plotter struct {
	// Current position in plotter units (floating point for sub-step
	// interpolation).
	XPos, YPos float64

	// PenDown is true when the pen is pressed against the paper.
	PenDown bool

	// PenNum is the currently selected pen (0 = stowed, 1-8 = active).
	PenNum int

	// Lines holds all line segments generated since the last reset.
	Lines []hpgl.LineSegment

	// Stepper positions in motor steps.
	StepX, StepY int

	// Target position in steps.
	TargetStepX, TargetStepY int

	// Stepper velocity in steps per tick.
	VelX, VelY float64

	// Maximum steps per tick.
	MaxSpeed float64

	// Acceleration in steps per tick^2.
	Accel float64
}

// New creates a new Plotter with default state.
func New() *Plotter {
	return &Plotter{
		MaxSpeed: 2.0,  // steps per tick
		Accel:    0.05, // steps per tick^2
	}
}

// ReadByte is a callback type for reading a byte from a memory address.
type ReadByte func(addr uint16) uint8

// SyncFromMemory reads the plotter command buffer from memory and processes
// new HP-GL commands. The memory layout is defined by the Aftograf-882
// firmware convention:
//   - A 256-byte buffer at a fixed address (configurable via paramAddr).
//   - The first two bytes at paramAddr hold the write pointer offset.
//   - The last processed offset is tracked internally.
func (p *Plotter) SyncFromMemory(paramAddr uint16, readByte ReadByte) {
	// Read the write pointer (offset into buffer).
	wp := uint16(readByte(paramAddr)) | uint16(readByte(paramAddr+1))<<8

	// Compute number of new bytes since last sync.
	bufferStart := paramAddr + 2
	bufferLen := uint16(256 - 2) // 254 bytes
	if wp > bufferLen {
		wp = bufferLen
	}

	// Track last processed offset.
	const lastOffAddr = 0xFFFF // sentinel: not stored in memory
	_ = lastOffAddr

	// For now, assume all bytes up to wp are new and are a complete
	// HP-GL command string. A real implementation would track the
	// last-read offset and parse incrementally.
	if wp == 0 {
		return
	}

	buf := make([]byte, wp)
	for i := uint16(0); i < wp; i++ {
		buf[i] = readByte(bufferStart + i)
	}

	// Parse as HP-GL text.
	hpglParser := hpgl.New()
	if err := hpglParser.Parse(string(buf)); err != nil {
		// Malformed command; skip silently for now.
		return
	}

	// Convert parsed segments into plotter lines.
	for _, seg := range hpglParser.Segments {
		x1 := float64(seg.X1)
		y1 := float64(seg.Y1)
		x2 := float64(seg.X2)
		y2 := float64(seg.Y2)

		// Apply plotter state to the segment.
		seg.Pen = p.PenNum
		_ = x1
		_ = y1

		p.Lines = append(p.Lines, seg)

		// Queue stepper movement to target.
		p.TargetStepX = int(math.Round(x2 * StepsPerUnit))
		p.TargetStepY = int(math.Round(y2 * StepsPerUnit))
	}

	// Update current position from last segment's endpoint.
	if len(hpglParser.Segments) > 0 {
		last := hpglParser.Segments[len(hpglParser.Segments)-1]
		p.XPos = float64(last.X2)
		p.YPos = float64(last.Y2)
	}

	// Sync pen state.
	p.PenDown = hpglParser.PenDown
	if hpglParser.PenNum > 0 {
		p.PenNum = hpglParser.PenNum
	}
}

// UpdateStepper advances the stepper motors one tick toward the target.
// Returns true if the stepper is still moving (not yet at target).
func (p *Plotter) UpdateStepper() bool {
	if p.StepX == p.TargetStepX && p.StepY == p.TargetStepY {
		p.VelX = 0
		p.VelY = 0
		return false // at target, idle
	}

	dx := float64(p.TargetStepX - p.StepX)
	dy := float64(p.TargetStepY - p.StepY)
	dist := math.Sqrt(dx*dx + dy*dy)

	if dist < 1 {
		p.StepX = p.TargetStepX
		p.StepY = p.TargetStepY
		return false
	}

	// Simple acceleration-limited velocity.
	dirX := dx / dist
	dirY := dy / dist

	// Accelerate toward max speed.
	targetVelX := dirX * p.MaxSpeed
	targetVelY := dirY * p.MaxSpeed

	velDiffX := targetVelX - p.VelX
	velDiffY := targetVelY - p.VelY
	velDist := math.Sqrt(velDiffX*velDiffX + velDiffY*velDiffY)

	if velDist > p.Accel {
		// Clamp acceleration.
		scale := p.Accel / velDist
		p.VelX += velDiffX * scale
		p.VelY += velDiffY * scale
	} else {
		p.VelX = targetVelX
		p.VelY = targetVelY
	}

	// Apply velocity.
	p.StepX += int(math.Round(p.VelX))
	p.StepY += int(math.Round(p.VelY))

	// Update continuous position from steps.
	p.XPos = float64(p.StepX) / StepsPerUnit
	p.YPos = float64(p.StepY) / StepsPerUnit

	// Check if we overshot.
	if (p.VelX > 0 && p.StepX > p.TargetStepX) || (p.VelX < 0 && p.StepX < p.TargetStepX) {
		p.StepX = p.TargetStepX
	}
	if (p.VelY > 0 && p.StepY > p.TargetStepY) || (p.VelY < 0 && p.StepY < p.TargetStepY) {
		p.StepY = p.TargetStepY
	}

	return p.StepX != p.TargetStepX || p.StepY != p.TargetStepY
}

// SetPen selects and optionally changes the pen.
// n = 0 stows the pen; 1-8 selects the corresponding pen stall.
func (p *Plotter) SetPen(n int) {
	if n < 0 || n > 8 {
		return
	}
	p.PenNum = n
}

// Reset resets the plotter to its initial state.
func (p *Plotter) Reset() {
	p.XPos = 0
	p.YPos = 0
	p.PenDown = false
	p.PenNum = 0
	p.Lines = nil
	p.StepX = 0
	p.StepY = 0
	p.TargetStepX = 0
	p.TargetStepY = 0
	p.VelX = 0
	p.VelY = 0
}
