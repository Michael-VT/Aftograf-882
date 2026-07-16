// Package hpgl implements HP-GL (Hewlett-Packard Graphics Language) parsing
// for the Aftograf-882 emulator.
package hpgl

import (
	"fmt"
	"strconv"
	"strings"
)

// LineSegment represents a single plotted line.
type LineSegment struct {
	X1, Y1 int
	X2, Y2 int
	Pen    int // pen number used for this segment
}

// HPGL holds parsed HP-GL command state and generated segments.
type HPGL struct {
	// Commands is the raw command list parsed from input text.
	Commands []Command

	// Segments is the list of generated line segments.
	Segments []LineSegment

	// Current position (in plotter units).
	CurX, CurY int

	// PenDown is true when the pen is lowered (drawing).
	PenDown bool

	// PenNum is the currently selected pen (0 = none selected).
	PenNum int

	// Initialized is set true after an IN command.
	Initialized bool

	// Scale factors for coordinate mapping.
	ScaleX, ScaleY float64

	// Origin offset for coordinate mapping.
	OriginX, OriginY int
}

// Command represents a single HP-GL command and its arguments.
type Command struct {
	Op    string
	Args  []int
	Raw   string // original text
	Coord bool   // true if args are coordinate pairs
}

// New creates a new HPGL parser with default state.
func New() *HPGL {
	return &HPGL{
		ScaleX: 1.0,
		ScaleY: 1.0,
	}
}

// Reset clears all state back to defaults.
func (h *HPGL) Reset() {
	h.Commands = nil
	h.Segments = nil
	h.CurX = 0
	h.CurY = 0
	h.PenDown = false
	h.PenNum = 0
	h.Initialized = false
	h.ScaleX = 1.0
	h.ScaleY = 1.0
	h.OriginX = 0
	h.OriginY = 0
}

// Parse parses an HP-GL text string into commands and generates segments.
// Each command is separated by semicolons or newlines. Coordinates are
// comma-separated integers.
//
// Supported commands:
//
//	IN   - Initialize (reset plotter)
//	SP n - Select pen n (0 = none, 1-8 = pen number)
//	PU   - Pen up (stop drawing)
//	PU x,y,... - Pen up and move to absolute coordinates
//	PD   - Pen down (start drawing)
//	PD x,y,... - Pen down and draw to absolute coordinates
//	PA x,y[,x,y...] - Plot Absolute (draw lines to absolute coordinates)
//	PR dx,dy[,dx,dy...] - Plot Relative (draw lines relative to current pos)
func (h *HPGL) Parse(text string) error {
	// Normalize: split on semicolons and newlines.
	text = strings.ReplaceAll(text, "\r\n", "\n")
	text = strings.ReplaceAll(text, "\r", "\n")
	text = strings.ReplaceAll(text, ";", "\n")

	lines := strings.Split(text, "\n")
	for _, line := range lines {
		line = strings.TrimSpace(line)
		if line == "" {
			continue
		}
		if err := h.parseLine(line); err != nil {
			return fmt.Errorf("hpgl: %w", err)
		}
	}
	return nil
}

// parseLine parses a single command line.
func (h *HPGL) parseLine(line string) error {
	// Split on first space or comma to get the opcode.
	lineUpper := strings.ToUpper(line)

	// Find the opcode boundary.
	opEnd := len(lineUpper)
	for i, ch := range lineUpper {
		if ch < 'A' || ch > 'Z' {
			opEnd = i
			break
		}
	}

	op := lineUpper[:opEnd]
	argText := strings.TrimSpace(line[opEnd:])

	cmd := Command{
		Op:  op,
		Raw: line,
	}

	switch op {
	case "IN":
		return h.cmdIN(cmd)

	case "SP":
		return h.cmdSP(cmd, argText)

	case "PU":
		return h.cmdPU(cmd, argText)

	case "PD":
		return h.cmdPD(cmd, argText)

	case "PA":
		return h.cmdPA(cmd, argText)

	case "PR":
		return h.cmdPR(cmd, argText)

	default:
		// Unknown commands are silently ignored (HPGL convention).
		return nil
	}
}

// parseCoords parses a comma-separated list of integers into coordinate pairs.
func parseCoords(text string) ([]int, error) {
	if strings.TrimSpace(text) == "" {
		return nil, nil
	}
	parts := strings.Split(text, ",")
	coords := make([]int, 0, len(parts))
	for _, p := range parts {
		p = strings.TrimSpace(p)
		if p == "" {
			continue
		}
		v, err := strconv.Atoi(p)
		if err != nil {
			return nil, fmt.Errorf("invalid coordinate %q: %w", p, err)
		}
		coords = append(coords, v)
	}
	return coords, nil
}

// cmdIN handles the IN (Initialize) command.
func (h *HPGL) cmdIN(cmd Command) error {
	h.Reset()
	h.Initialized = true
	h.Commands = append(h.Commands, cmd)
	return nil
}

// cmdSP handles the SP (Select Pen) command.
func (h *HPGL) cmdSP(cmd Command, argText string) error {
	args, err := parseCoords(argText)
	if err != nil {
		return fmt.Errorf("SP: %w", err)
	}
	if len(args) < 1 {
		return nil // no pen number, ignore
	}
	n := args[0]
	if n < 0 || n > 8 {
		return fmt.Errorf("SP: pen number %d out of range (0-8)", n)
	}
	h.PenNum = n
	cmd.Args = []int{n}
	h.Commands = append(h.Commands, cmd)
	return nil
}

// cmdPU handles the PU (Pen Up) command.
// With coordinates: move to absolute position with pen up.
// Without coordinates: just lift the pen.
func (h *HPGL) cmdPU(cmd Command, argText string) error {
	coords, err := parseCoords(argText)
	if err != nil {
		return fmt.Errorf("PU: %w", err)
	}

	h.PenDown = false

	if len(coords) >= 2 {
		// Move to absolute coordinate, pen stays up.
		pairs := coords[:len(coords)&^1] // drop odd trailing value
		cmd.Coord = true
		cmd.Args = make([]int, len(pairs))
		copy(cmd.Args, pairs)

		for i := 0; i < len(pairs); i += 2 {
			x := pairs[i]
			y := pairs[i+1]
			h.CurX = x
			h.CurY = y
		}
	}

	h.Commands = append(h.Commands, cmd)
	return nil
}

// cmdPD handles the PD (Pen Down) command.
// With coordinates: draw to absolute coordinates.
// Without coordinates: just lower the pen.
func (h *HPGL) cmdPD(cmd Command, argText string) error {
	coords, err := parseCoords(argText)
	if err != nil {
		return fmt.Errorf("PD: %w", err)
	}

	h.PenDown = true

	if len(coords) >= 2 {
		pairs := coords[:len(coords)&^1]
		cmd.Coord = true
		cmd.Args = make([]int, len(pairs))
		copy(cmd.Args, pairs)

		for i := 0; i < len(pairs); i += 2 {
			x := pairs[i]
			y := pairs[i+1]
			h.addSegment(h.CurX, h.CurY, x, y)
			h.CurX = x
			h.CurY = y
		}
	}

	h.Commands = append(h.Commands, cmd)
	return nil
}

// cmdPA handles the PA (Plot Absolute) command.
// Draws lines from current position to each absolute coordinate.
func (h *HPGL) cmdPA(cmd Command, argText string) error {
	coords, err := parseCoords(argText)
	if err != nil {
		return fmt.Errorf("PA: %w", err)
	}

	if len(coords) < 2 {
		return nil
	}

	pairs := coords[:len(coords)&^1]
	cmd.Coord = true
	cmd.Args = make([]int, len(pairs))
	copy(cmd.Args, pairs)

	for i := 0; i < len(pairs); i += 2 {
		x := pairs[i]
		y := pairs[i+1]
		if h.PenDown {
			h.addSegment(h.CurX, h.CurY, x, y)
		}
		h.CurX = x
		h.CurY = y
	}

	h.Commands = append(h.Commands, cmd)
	return nil
}

// cmdPR handles the PR (Plot Relative) command.
// Draws lines offset from current position by dx,dy pairs.
func (h *HPGL) cmdPR(cmd Command, argText string) error {
	coords, err := parseCoords(argText)
	if err != nil {
		return fmt.Errorf("PR: %w", err)
	}

	if len(coords) < 2 {
		return nil
	}

	pairs := coords[:len(coords)&^1]
	cmd.Coord = true
	cmd.Args = make([]int, len(pairs))
	copy(cmd.Args, pairs)

	for i := 0; i < len(pairs); i += 2 {
		dx := pairs[i]
		dy := pairs[i+1]
		x := h.CurX + dx
		y := h.CurY + dy
		if h.PenDown {
			h.addSegment(h.CurX, h.CurY, x, y)
		}
		h.CurX = x
		h.CurY = y
	}

	h.Commands = append(h.Commands, cmd)
	return nil
}

// addSegment appends a line segment.
func (h *HPGL) addSegment(x1, y1, x2, y2 int) {
	h.Segments = append(h.Segments, LineSegment{
		X1:  x1,
		Y1:  y1,
		X2:  x2,
		Y2:  y2,
		Pen: h.PenNum,
	})
}
