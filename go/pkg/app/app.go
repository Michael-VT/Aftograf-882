package app

import (
	"encoding/json"
	"fmt"
	"image"
	"image/color"
	"image/draw"
	"io"
	"sort"
	"strconv"
	"strings"
	"sync"
	"time"

	"fyne.io/fyne/v2"
	"fyne.io/fyne/v2/canvas"
	"fyne.io/fyne/v2/container"
	"fyne.io/fyne/v2/dialog"
	"fyne.io/fyne/v2/layout"
	"fyne.io/fyne/v2/theme"
	"fyne.io/fyne/v2/widget"

	"github.com/Michael-VT/Aftograf-882/pkg/cpu"
	"github.com/Michael-VT/Aftograf-882/pkg/disasm"
	"github.com/Michael-VT/Aftograf-882/pkg/hpgl"
	"github.com/Michael-VT/Aftograf-882/pkg/memory"
	"github.com/Michael-VT/Aftograf-882/pkg/pit8253"
	"github.com/Michael-VT/Aftograf-882/pkg/plotter"
	"github.com/Michael-VT/Aftograf-882/pkg/ppi8255"
	"github.com/Michael-VT/Aftograf-882/pkg/settings"
	"github.com/Michael-VT/Aftograf-882/pkg/usart8251"
)

const appVersion = "v1.0.18"

// ───── Compact layout (zero-spacing vertical) ─────
type compactVBox struct{}

func (c *compactVBox) Layout(objects []fyne.CanvasObject, size fyne.Size) {
	y := float32(0)
	for _, o := range objects {
		if !o.Visible() {
			continue
		}
		o.Resize(fyne.NewSize(size.Width, o.MinSize().Height))
		o.Move(fyne.NewPos(0, y))
		y += o.MinSize().Height
	}
}
func (c *compactVBox) MinSize(objects []fyne.CanvasObject) fyne.Size {
	w, h := float32(0), float32(0)
	for _, o := range objects {
		if !o.Visible() {
			continue
		}
		s := o.MinSize()
		if s.Width > w {
			w = s.Width
		}
		h += s.Height
	}
	return fyne.NewSize(w, h)
}

type compactHBox struct{}

func (c *compactHBox) Layout(objects []fyne.CanvasObject, size fyne.Size) {
	x := float32(0)
	for _, o := range objects {
		if !o.Visible() {
			continue
		}
		o.Resize(o.MinSize())
		o.Move(fyne.NewPos(x, 0))
		x += o.MinSize().Width
	}
}
func (c *compactHBox) MinSize(objects []fyne.CanvasObject) fyne.Size {
	w, h := float32(0), float32(0)
	for _, o := range objects {
		if !o.Visible() {
			continue
		}
		s := o.MinSize()
		w += s.Width
		if s.Height > h {
			h = s.Height
		}
	}
	return fyne.NewSize(w, h)
}
func monoLabel(txt string) *widget.Label {
	l := widget.NewLabel(txt)
	l.TextStyle = fyne.TextStyle{Monospace: true}
	return l
}

// buttonLabel is a compact clickable text button (looks like a label).
func buttonLabel(txt string, fn func()) *widget.Button {
	b := widget.NewButton(txt, fn)
	b.Importance = widget.LowImportance
	return b
}

// clickLabel is a left-aligned monospace label tappable like a button.
// Uses the same natural row height as the disassembler list.
type clickLabel struct {
	widget.Label
	onTap   func()
	onTapAt func(*fyne.PointEvent)
}

func (c *clickLabel) Tapped(ev *fyne.PointEvent) {
	if c.onTapAt != nil {
		c.onTapAt(ev)
	} else if c.onTap != nil {
		c.onTap()
	}
}
func (c *clickLabel) MinSize() fyne.Size {
	s := c.Label.MinSize()
	// Match canvas.Text height used by the disassembler list, while keeping
	// the label's natural width for the complete memory dump row.
	text := canvas.NewText(c.Text, color.White)
	text.TextStyle = c.TextStyle
	textHeight := text.MinSize().Height
	if textHeight <= 0 {
		textHeight = s.Height
	}
	return fyne.NewSize(s.Width, textHeight)
}
func newClickLabel(text string, fn func()) *clickLabel {
	c := &clickLabel{onTap: fn}
	c.Text = text
	c.TextStyle = fyne.TextStyle{Monospace: true}
	c.Wrapping = fyne.TextTruncate
	c.ExtendBaseWidget(c)
	return c
}

// memoryByteAtColumn maps a monospace memory-dump character column to the
// byte represented by either its HEX or ASCII cell. Separators and address
// columns deliberately return false.
func memoryByteAtColumn(column int) (int, bool) {
	const hexStart = 6 // "0000  "
	for i := 0; i < 16; i++ {
		start := hexStart + i*3
		if i >= 8 {
			start++ // extra gap between the two groups of eight bytes
		}
		if column >= start && column < start+2 {
			return i, true
		}
	}
	const asciiStart = 57 // hex start + 48 chars + two spaces + '|'
	if column >= asciiStart && column < asciiStart+16 {
		return column - asciiStart, true
	}
	return 0, false
}

// debugLabel is a monospace label whose height is explicitly tied to the
// canvas.Text height used by the disassembler rows.
type debugLabel struct {
	widget.Label
	rowHeight float32
}

func (l *debugLabel) MinSize() fyne.Size {
	s := l.Label.MinSize()
	if l.rowHeight > 0 {
		s.Height = l.rowHeight
	}
	return s
}

func newDebugLabel(text string, rowHeight float32) *debugLabel {
	l := &debugLabel{rowHeight: rowHeight}
	l.Text = text
	l.TextStyle = fyne.TextStyle{Monospace: true}
	l.ExtendBaseWidget(l)
	return l
}

type debugRowLayout struct {
	height float32
}

func (l *debugRowLayout) Layout(objects []fyne.CanvasObject, size fyne.Size) {
	x := float32(0)
	for _, o := range objects {
		if !o.Visible() {
			continue
		}
		w := o.MinSize().Width
		o.Resize(fyne.NewSize(w, l.height))
		o.Move(fyne.NewPos(x, 0))
		x += w
	}
}

func (l *debugRowLayout) MinSize(objects []fyne.CanvasObject) fyne.Size {
	w := float32(0)
	for _, o := range objects {
		if o.Visible() {
			w += o.MinSize().Width
		}
	}
	return fyne.NewSize(w, l.height)
}

// ───── AftografApp ─────

type AftografApp struct {
	CPU        *cpu.CPU8080
	MMU        *memory.MMU
	PPI1, PPI2 *ppi8255.PPI8255
	PIT        *pit8253.PIT8253
	USART      *usart8251.USART8251
	Plot       *plotter.Plotter
	HPGL       *hpgl.HPGL
	Setts      *settings.Settings

	Running   bool
	RomLoaded bool
	mu        sync.Mutex
	mainWin   fyne.Window
	speedIdx  int

	pcCheck *widget.Check
	// Registers: display + editable entries
	regDisp                        [8]*widget.Label // 0=A,1=BC,2=DE,3=HL,4=SP,5=PC,6=Flags,7=Cycles
	regH, regL                     *widget.Entry
	regEdit                        [6]*widget.Entry // 0=A,1=B,2=C,3=D,4=E,5=SP
	regBCb, regDEb, regHLb, regSPb *widget.Button
	flagBtns                       [5]*widget.Button
	dipLEDs                        []*canvas.Circle
	statusL                        *widget.Label
	stackLbl                       [24]*debugLabel

	// Disassembler
	disasmAddr     uint16
	followPC       bool
	disasmSrch     string
	breakpoints    map[uint16]bool
	bpList         []uint16        // sorted breakpoint addresses (for display)
	bpLbl          *fyne.Container // breakpoint list VBox (rebuilt on refresh)
	bpPrev, bpNext *widget.Button  // navigation
	insnIndex      []uint16        // instruction start addresses (linear sweep)
	pcInsnIdx      int             // index into insnIndex for current PC (or -1)
	debugRowHeight float32         // content height shared by debug rows
	debugRowStep   float32         // row height plus list spacing, shared by lists
	pioLbl         *fyne.Container // peripheral I/O status VBox
	disasmList     *widget.List
	dsEntry        *widget.Entry

	// Memory viewer
	memAddr  uint16
	memSrch  string
	memList  *widget.List
	memEntry *widget.Entry

	// USART log
	uartLog  []string
	uartLogE *widget.Entry

	// Plotter
	plotRast     *canvas.Raster
	progBar      *widget.ProgressBar
	xL, yL, penL *widget.Label
	hpglStep     int
	hpglMode     bool
	pitRemainder uint64
}

func New() *AftografApp {
	app := &AftografApp{
		speedIdx:    3,
		followPC:    true,
		disasmSrch:  "0000",
		memSrch:     "0000",
		breakpoints: make(map[uint16]bool),
	}
	app.PPI1, app.PPI2 = ppi8255.New(), ppi8255.New()
	app.PIT, app.USART = pit8253.New(), usart8251.New()
	app.Plot, app.HPGL = plotter.New(), hpgl.New()
	app.Setts = settings.Default()
	app.MMU = memory.New(app.PPI1, app.PPI2, app.PIT, app.USART)
	app.MMU.LoadDefaultFirmware()
	app.RomLoaded = true
	app.CPU = cpu.New(
		func(a uint16) uint8 { return app.MMU.Read(a) },
		func(a uint16, v uint8) { app.MMU.Write(a, v) },
		func(p uint8) uint8 { return app.inPort(p) },
		func(p uint8, v uint8) { app.outPort(p, v) },
	)
	app.USART.OnReceive = func() { app.CPU.Intr = true }
	app.USART.OnTransmit = func(v byte) {
		app.uartLog = append(app.uartLog, fmt.Sprintf("TX: %02X", v))
		if len(app.uartLog) > 500 {
			app.uartLog = app.uartLog[len(app.uartLog)-500:]
		}
	}
	return app
}

func (a *AftografApp) inPort(p uint8) uint8 {
	// The firmware uses the two legacy direct USART ports in addition to the
	// memory-mapped EC00/EC01 registers.
	switch p {
	case 0x19:
		return a.USART.Read(usart8251.DataPort)
	case 0x28:
		return a.USART.Read(usart8251.CmdStatusPort)
	}
	return a.MMU.Read(0xE000 | uint16(p))
}
func (a *AftografApp) outPort(p uint8, v uint8) {
	switch p {
	case 0x19:
		a.USART.Write(usart8251.DataPort, v)
		return
	case 0x28:
		a.USART.Write(usart8251.CmdStatusPort, v)
		return
	}
	a.MMU.Write(0xE000|uint16(p), v)
}

// ───── CPU control ─────

func (a *AftografApp) Step() {
	a.mu.Lock()
	if !a.RomLoaded || a.Running || a.CPU.Halt {
		a.mu.Unlock()
		return
	}
	a.stepLocked()
	a.mu.Unlock()
	a.mu.Lock()
	a.followPC = true
	a.mu.Unlock()
	a.syncUI()
	a.refreshPlotCanvas()
}
func (a *AftografApp) Run() {
	a.mu.Lock()
	if a.Running || !a.RomLoaded || a.CPU.Halt {
		a.mu.Unlock()
		return
	}
	a.Running = true
	steps := []int{1, 10, 100, 1000, 10000, 100000}
	n := steps[3]
	if a.speedIdx >= 0 && a.speedIdx < len(steps) {
		n = steps[a.speedIdx]
	}
	a.mu.Unlock()
	a.syncUI()
	go func() {
		for {
			a.mu.Lock()
			if !a.Running || a.CPU.Halt {
				a.Running = false
				a.mu.Unlock()
				break
			}
			for i := 0; i < n && a.Running && !a.CPU.Halt; i++ {
				a.stepLocked()
				if a.breakpoints[a.CPU.PC] {
					a.Running = false
					break
				}
			}
			a.mu.Unlock()
			a.syncUI()
			a.refreshPlotCanvas()
			time.Sleep(16 * time.Millisecond)
		}
		a.mu.Lock()
		a.Running = false
		a.mu.Unlock()
		a.syncUI()
	}()
}
func (a *AftografApp) Pause() {
	a.mu.Lock()
	a.Running = false
	a.mu.Unlock()
}

// stepLocked executes one CPU instruction and advances the connected
// peripherals. The caller must hold a.mu.
func (a *AftografApp) stepLocked() {
	before := a.CPU.Cycles
	a.CPU.Step()
	cycles := a.CPU.Cycles - before
	divisor := uint64(a.Setts.PITDivisor)
	if divisor == 0 {
		divisor = 1
	}
	a.pitRemainder += cycles
	for a.pitRemainder >= divisor {
		a.PIT.Tick()
		a.pitRemainder -= divisor
	}
	a.syncPlotterLocked()
	if a.USART.TxPending() {
		a.USART.TransmitComplete()
	}
}

func (a *AftografApp) syncPlotterLocked() {
	if a.hpglMode {
		return
	}
	readWord := func(lo, hi uint16) int {
		return int(uint16(a.MMU.Peek(lo)) | uint16(a.MMU.Peek(hi))<<8)
	}
	x := readWord(0x6180, 0x6181)
	y := readWord(0x6186, 0x6187)
	penDown := a.MMU.Peek(0x63F0)&0x01 != 0
	pen := int(a.MMU.Peek(0x61E8) & 0x07)
	a.Plot.SyncFromState(x, y, penDown, pen)
	// The firmware exposes the stepper phase patterns through PPI1.
	a.Plot.UpdatePhase('x', a.PPI1.PortA())
	a.Plot.UpdatePhase('y', a.PPI1.PortB())
}

func (a *AftografApp) Reset() {
	a.mu.Lock()
	a.Running = false
	a.CPU.Reset()
	a.MMU.ClearRAM()
	a.PPI1.Reset()
	a.PPI2.Reset()
	a.PIT.Reset()
	a.USART.Reset()
	a.MMU.LoadDefaultFirmware()
	a.pitRemainder = 0
	a.RomLoaded = true
	a.memAddr, a.disasmAddr = 0, 0
	a.Plot.Reset()
	a.HPGL = hpgl.New()
	a.hpglStep = 0
	a.hpglMode = false
	a.mu.Unlock()
	a.syncUI()
	a.refreshPlotCanvas()
}

// ───── refresh all ─────

func (a *AftografApp) syncUI() {
	a.mu.Lock()
	defer a.mu.Unlock()
	if a.regDisp[0] == nil {
		return
	}
	// Labels & entries update live
	a.regDisp[0].SetText(fmt.Sprintf("A:%02X", a.CPU.A))
	if a.regEdit[0] != nil {
		a.regEdit[0].SetText(fmt.Sprintf("%02X", a.CPU.A))
	}
	a.regBCb.SetText(fmt.Sprintf("BC:%04X", a.CPU.GetBC()))
	if a.regEdit[1] != nil {
		a.regEdit[1].SetText(fmt.Sprintf("%02X", a.CPU.B))
	}
	if a.regEdit[2] != nil {
		a.regEdit[2].SetText(fmt.Sprintf("%02X", a.CPU.C))
	}
	a.regDEb.SetText(fmt.Sprintf("DE:%04X", a.CPU.GetDE()))
	if a.regEdit[3] != nil {
		a.regEdit[3].SetText(fmt.Sprintf("%02X", a.CPU.D))
	}
	if a.regEdit[4] != nil {
		a.regEdit[4].SetText(fmt.Sprintf("%02X", a.CPU.E))
	}
	a.regHLb.SetText(fmt.Sprintf("HL:%04X", a.CPU.GetHL()))
	a.regSPb.SetText("SP→")
	if a.regEdit[5] != nil {
		a.regEdit[5].SetText(fmt.Sprintf("%04X", a.CPU.SP))
	}
	a.regDisp[5].SetText(fmt.Sprintf("PC:%04X", a.CPU.PC))
	fl := a.CPU.Flags
	bits := []struct {
		b uint8
		n string
	}{{cpu.FlagS, "S"}, {cpu.FlagZ, "Z"}, {cpu.FlagAC, "AC"}, {cpu.FlagP, "P"}, {cpu.FlagCY, "CY"}}
	for i, f := range bits {
		on := fl&f.b != 0
		a.flagBtns[i].SetText(f.n)
		a.flagBtns[i].Importance = widget.HighImportance
		if !on {
			a.flagBtns[i].Importance = widget.MediumImportance
		}
		a.flagBtns[i].Refresh()
	}
	if a.regH != nil {
		a.regH.SetText(fmt.Sprintf("%02X", a.CPU.H))
	}
	if a.regL != nil {
		a.regL.SetText(fmt.Sprintf("%02X", a.CPU.L))
	}
	a.regDisp[7].SetText(fmt.Sprintf("Cycles: %d", a.CPU.Cycles))
	s := "STOP"
	if a.Running {
		s = "RUN"
	}
	if a.CPU.Halt {
		s = "HLT"
	}
	a.statusL.SetText(s)
	if a.followPC {
		a.disasmAddr = a.CPU.PC
		a.disasmSrch = fmt.Sprintf("%04X", a.CPU.PC)
	}
	// Do not call pcCheck.SetChecked while holding a.mu: Fyne invokes the
	// checkbox callback synchronously, and that callback also uses a.mu.
	// The checkbox is changed by the user; its state is therefore not pushed
	// back during a state refresh.
	// DIP LEDs
	for i := 0; i < 8; i++ {
		on := a.PPI1.A&(1<<uint(i)) != 0
		a.dipLEDs[i].FillColor = color.RGBA{0, 200, 0, 255}
		if !on {
			a.dipLEDs[i].FillColor = color.RGBA{40, 40, 40, 255}
		}
		a.dipLEDs[i].Refresh()
	}
	// Progress bar
	if a.progBar != nil && a.HPGL != nil && len(a.HPGL.Segments) > 0 {
		a.progBar.SetValue(float64(a.hpglStep) / float64(len(a.HPGL.Segments)))
	}
	a.refreshDisasm()
	a.refreshMem()
	a.refreshStack()
	a.refreshBreakpoints()
	a.refreshPIO()
	if a.xL != nil {
		a.xL.SetText(fmt.Sprintf("X:%d", int(a.Plot.XPos)))
		a.yL.SetText(fmt.Sprintf("Y:%d", int(a.Plot.YPos)))
		arrow := "↑"
		if a.Plot.PenDown {
			arrow = "↓"
		}
		a.penL.SetText(fmt.Sprintf("Pen:%s#%d", arrow, a.Plot.PenNum))
	}
	if a.uartLogE != nil {
		start := 0
		if len(a.uartLog) > 20 {
			start = len(a.uartLog) - 20
		}
		a.uartLogE.SetText(strings.Join(a.uartLog[start:], "\n"))
	}
}

func (a *AftografApp) refreshPlotCanvas() {
	if a.plotRast != nil {
		a.plotRast.Refresh()
	}
}

func (a *AftografApp) navigateBreakpoint(next bool) {
	a.mu.Lock()
	if len(a.bpList) < 2 {
		a.mu.Unlock()
		return
	}
	cur := int(a.disasmAddr)
	best := -1
	if next {
		for i, ad := range a.bpList {
			if int(ad) > cur {
				best = i
				break
			}
		}
		if best < 0 {
			best = 0
		}
	} else {
		for i := len(a.bpList) - 1; i >= 0; i-- {
			if int(a.bpList[i]) < cur {
				best = i
				break
			}
		}
		if best < 0 {
			best = len(a.bpList) - 1
		}
	}
	a.disasmAddr = a.bpList[best]
	a.followPC = false
	a.disasmSrch = fmt.Sprintf("%04X", a.disasmAddr)
	addr := a.disasmAddr
	a.mu.Unlock()
	a.refreshDisasm()
	a.memJump(addr)
}

func (a *AftografApp) memJump(ad uint16) {
	a.mu.Lock()
	a.memAddr = ad & 0xFFF0
	a.memSrch = fmt.Sprintf("%04X", a.memAddr)
	entry := a.memEntry
	list := a.memList
	textValue := a.memSrch
	memAddr := a.memAddr
	step := a.debugRowStep
	a.mu.Unlock()
	if entry != nil {
		entry.SetText(textValue)
	}
	if list != nil {
		id := int(memAddr / 16)
		// ScrollTo(id) makes the requested row the first useful anchor. The
		// previous id+17 workaround made HL=$6000 show $6090 instead.
		if step <= 0 {
			list.ScrollTo(widget.ListItemID(id))
		} else {
			list.ScrollToOffset(float32(id) * step)
		}
	}
}

type sessionData struct {
	CPU       cpuState           `json:"cpu"`
	BPs       []uint16           `json:"breakpoints"`
	RAM       []byte             `json:"ram,omitempty"`
	PlotLines []hpgl.LineSegment `json:"plot_lines,omitempty"`
	HPGL      *hpgl.HPGL         `json:"hpgl,omitempty"`
	HPGLStep  int                `json:"hpgl_step"`
	HPGLMode  bool               `json:"hpgl_mode"`
	MemAddr   uint16             `json:"mem_addr"`
	DisAddr   uint16             `json:"disasm_addr"`
	FollowPC  bool               `json:"follow_pc"`
}

type cpuState struct {
	A      uint8  `json:"a"`
	B      uint8  `json:"b"`
	C      uint8  `json:"c"`
	D      uint8  `json:"d"`
	E      uint8  `json:"e"`
	H      uint8  `json:"h"`
	L      uint8  `json:"l"`
	SP     uint16 `json:"sp"`
	PC     uint16 `json:"pc"`
	Flags  uint8  `json:"flags"`
	Cycles uint64 `json:"cycles"`
	Halt   bool   `json:"halt"`
	IE     bool   `json:"interrupt_enabled"`
	Intr   bool   `json:"interrupt_pending"`
}

func memColor(addr uint16) color.RGBA {
	switch {
	case addr <= 0x5FFF:
		return color.RGBA{180, 160, 120, 255}
	case addr >= 0x6000 && addr <= 0x67FF:
		return color.RGBA{200, 180, 60, 255}
	case addr >= 0xE000 && addr <= 0xEFFF:
		return color.RGBA{160, 100, 200, 255}
	default:
		return color.RGBA{100, 100, 100, 255}
	}
}

func (a *AftografApp) saveSession() {
	a.mu.Lock()
	s := sessionData{
		CPU: cpuState{
			A: a.CPU.A, B: a.CPU.B, C: a.CPU.C,
			D: a.CPU.D, E: a.CPU.E, H: a.CPU.H, L: a.CPU.L,
			SP: a.CPU.SP, PC: a.CPU.PC, Flags: a.CPU.Flags,
			Cycles: a.CPU.Cycles, Halt: a.CPU.Halt,
			IE: a.CPU.IE, Intr: a.CPU.Intr,
		},
		RAM:       append([]byte(nil), a.MMU.ReadRAM()...),
		PlotLines: append([]hpgl.LineSegment(nil), a.Plot.Lines...),
		HPGLStep:  a.hpglStep,
		HPGLMode:  a.hpglMode,
		MemAddr:   a.memAddr,
		DisAddr:   a.disasmAddr,
		FollowPC:  a.followPC,
	}
	if a.HPGL != nil {
		h := *a.HPGL
		s.HPGL = &h
	}
	for ad := range a.breakpoints {
		s.BPs = append(s.BPs, ad)
	}
	a.mu.Unlock()
	data, err := json.MarshalIndent(s, "", "  ")
	if err != nil {
		return
	}
	dialog.ShowFileSave(func(wc fyne.URIWriteCloser, err error) {
		if err != nil || wc == nil {
			return
		}
		defer wc.Close()
		_, _ = wc.Write(data)
	}, a.mainWin)
}

func (a *AftografApp) loadSession() {
	if a.mainWin == nil {
		return
	}
	dialog.ShowFileOpen(func(r fyne.URIReadCloser, err error) {
		if err != nil || r == nil {
			return
		}
		defer r.Close()
		data, readErr := io.ReadAll(r)
		if readErr != nil {
			return
		}

		var s sessionData
		if err := json.Unmarshal(data, &s); err != nil {
			return
		}
		a.mu.Lock()
		a.Running = false
		a.CPU.A = s.CPU.A
		a.CPU.B = s.CPU.B
		a.CPU.C = s.CPU.C
		a.CPU.D = s.CPU.D
		a.CPU.E = s.CPU.E
		a.CPU.H = s.CPU.H
		a.CPU.L = s.CPU.L
		a.CPU.SP = s.CPU.SP
		a.CPU.PC = s.CPU.PC
		a.CPU.Flags = s.CPU.Flags
		a.CPU.Cycles = s.CPU.Cycles
		a.CPU.Halt = s.CPU.Halt
		a.CPU.IE = s.CPU.IE
		a.CPU.Intr = s.CPU.Intr
		if s.RAM != nil {
			a.MMU.LoadRAM(s.RAM)
		}
		a.Plot.Lines = append([]hpgl.LineSegment(nil), s.PlotLines...)
		if s.HPGL != nil {
			h := *s.HPGL
			a.HPGL = &h
		} else {
			a.HPGL = hpgl.New()
		}
		a.hpglStep = s.HPGLStep
		a.hpglMode = s.HPGLMode
		a.memAddr = s.MemAddr
		a.disasmAddr = s.DisAddr
		a.followPC = s.FollowPC
		a.breakpoints = make(map[uint16]bool)
		for _, bp := range s.BPs {
			a.breakpoints[bp] = true
		}
		a.mu.Unlock()
		a.syncUI()
	}, a.mainWin)
}
func (a *AftografApp) refreshDisasm() {
	if a.disasmList == nil {
		return
	}
	// Rebuild instruction index from memory (linear sweep).
	// This ensures every row shows a complete instruction — no misaligned decodes.
	readByte := func(aa uint16) uint8 { return a.MMU.Peek(aa) }
	a.insnIndex = disasm.BuildInsnIndex(readByte)
	// Find the instruction index containing PC for highlighting
	a.pcInsnIdx = disasm.InsnIndexForAddr(a.insnIndex, a.CPU.PC)
	// Determine which instruction to scroll to
	target := a.pcInsnIdx
	if !a.followPC {
		target = disasm.InsnIndexForAddr(a.insnIndex, a.disasmAddr)
	}
	if target < 0 {
		target = 0
	}
	if a.debugRowStep <= 0 || a.disasmList.Size().Height <= 0 {
		a.disasmList.ScrollTo(widget.ListItemID(target))
	} else {
		visible := int(a.disasmList.Size().Height / a.debugRowStep)
		start := target - visible/2
		if start < 0 {
			start = 0
		}
		a.disasmList.ScrollToOffset(float32(start) * a.debugRowStep)
	}
	a.disasmList.Refresh()
}
func (a *AftografApp) refreshMem() {
	if a.memList == nil {
		return
	}
	a.memList.Refresh()
}

func (a *AftografApp) refreshStack() {
	sp := a.CPU.SP
	for i := range a.stackLbl {
		adr := sp + uint16(i)*2
		if adr < 0xFFF0 {
			v := uint16(a.MMU.Peek(adr+1))<<8 | uint16(a.MMU.Peek(adr))
			a.stackLbl[i].SetText(fmt.Sprintf("%04X:%04X", adr, v))
		} else {
			a.stackLbl[i].SetText(fmt.Sprintf("%04X:----", adr))
		}
	}
}
func (a *AftografApp) refreshBreakpoints() {
	if a.bpLbl == nil {
		return
	}
	a.bpList = make([]uint16, 0, len(a.breakpoints))
	for ad := range a.breakpoints {
		a.bpList = append(a.bpList, ad)
	}
	sort.Slice(a.bpList, func(i, j int) bool { return a.bpList[i] < a.bpList[j] })
	a.bpLbl.RemoveAll()
	if len(a.bpList) == 0 {
		a.bpLbl.Add(newDebugLabel("  (no breakpoints)", a.debugRowHeight))
	} else {
		for _, ad := range a.bpList {
			a2 := ad
			row := container.New(&debugRowLayout{height: a.debugRowHeight},
				newClickLabel(fmt.Sprintf("● %04X", ad), func() {
					a.disasmAddr = a2
					a.followPC = false
					a.disasmSrch = fmt.Sprintf("%04X", a2)
					a.memJump(a2)
					a.refreshDisasm()
				}),
				newClickLabel("✕", func() {
					delete(a.breakpoints, a2)
					a.refreshBreakpoints()
					a.refreshDisasm()
				}),
			)
			a.bpLbl.Add(row)
		}
	}
	if a.bpPrev != nil || a.bpNext != nil {
		hasPrevNext := len(a.bpList) >= 2
		if a.bpPrev != nil {
			if hasPrevNext {
				a.bpPrev.Enable()
			} else {
				a.bpPrev.Disable()
			}
		}
		if a.bpNext != nil {
			if hasPrevNext {
				a.bpNext.Enable()
			} else {
				a.bpNext.Disable()
			}
		}
	}

}
func (a *AftografApp) refreshPIO() {
	if a.pioLbl == nil {
		return
	}
	a.pioLbl.RemoveAll()
	addRow := func(name, address, data, description string) {
		a.pioLbl.Add(newDebugLabel(fmt.Sprintf("%-16s %-7s %-24s %s", name, address, data, description), a.debugRowHeight))
	}
	addSection := func(title string) {
		a.pioLbl.Add(newDebugLabel(title, a.debugRowHeight))
	}
	bin := func(v uint8) string {
		s := ""
		for i := 7; i >= 0; i-- {
			if v&(1<<uint(i)) != 0 {
				s += "1"
			} else {
				s += "0"
			}
		}
		return s
	}
	addRow("Name", "Address", "Data", "Description")
	// ── PPI1 (0xE000) ──
	addSection("── PPI1 ──")
	p1 := a.PPI1
	addRow("PPI1.A", "E000", fmt.Sprintf("%s (%02X)", bin(p1.PortA()), p1.PortA()), "port A")
	addRow("PPI1.B", "E001", fmt.Sprintf("%s (%02X)", bin(p1.PortB()), p1.PortB()), "port B")
	addRow("PPI1.C", "E002", fmt.Sprintf("%s (%02X)", bin(p1.PortC()), p1.PortC()), "port C")
	addRow("PPI1.CTL", "E003", fmt.Sprintf("%s (%02X)", bin(p1.Control()), p1.Control()), fmt.Sprintf("mode A:%d B:%d", p1.ModeA(), p1.ModeB()))
	// ── PPI2 (0xE400) ──
	addSection("── PPI2 ──")
	p2 := a.PPI2
	addRow("PPI2.A", "E400", fmt.Sprintf("%s (%02X)", bin(p2.PortA()), p2.PortA()), "port A")
	addRow("PPI2.B", "E401", fmt.Sprintf("%s (%02X)", bin(p2.PortB()), p2.PortB()), "port B")
	addRow("PPI2.C", "E402", fmt.Sprintf("%s (%02X)", bin(p2.PortC()), p2.PortC()), "port C")
	addRow("PPI2.CTL", "E403", fmt.Sprintf("%s (%02X)", bin(p2.Control()), p2.Control()), fmt.Sprintf("mode A:%d B:%d", p2.ModeA(), p2.ModeB()))
	// ── PIT (0xE800) ──
	modes := []string{"0:IO", "1:OS", "2:Rate", "3:SqWv", "4:STB", "5:HC"}
	accs := []string{"?", "LSB", "MSB", "16bit"}
	addSection("── PIT ──")
	for i := 0; i < 3; i++ {
		m := int(a.PIT.CounterMode(i))
		ma := "?"
		if m >= 0 && m < len(modes) {
			ma = modes[m]
		}
		af := int(a.PIT.CounterAccess(i))
		aa := "?"
		if af >= 0 && af < len(accs) {
			aa = accs[af]
		}
		addRow(fmt.Sprintf("PIT.CNT%d", i), fmt.Sprintf("%04X", 0xE800+i), fmt.Sprintf("%04X", a.PIT.CounterVal(i)), fmt.Sprintf("mode:%s access:%s", ma, aa))
	}
	// ── USART (0xEC00) ──
	u := a.USART
	s := u.Status()
	addSection("── USART ──")
	addRow("USART.DATA", "EC00", fmt.Sprintf("%02X", u.Data()), "data register")
	addRow("USART.STATUS", "EC01", fmt.Sprintf("%s (%02X)", bin(s), s), fmt.Sprintf("TXRDY:%d RXRDY:%d OVRN:%d FE:%d PE:%d",
		b2i(s&usart8251.StatusTxReady != 0),
		b2i(s&usart8251.StatusRxReady != 0),
		b2i(s&usart8251.StatusOverrun != 0),
		b2i(s&usart8251.StatusFraming != 0),
		b2i(s&usart8251.StatusParity != 0)))
	addRow("USART.CMD", "EC01", fmt.Sprintf("%s (%02X)", bin(u.Command()), u.Command()), "command register")
	addRow("USART.MODE", "EC00", fmt.Sprintf("%s (%02X)", bin(u.Mode()), u.Mode()), "mode register")
	// ── External ──
	addSection("── EXTERNAL ──")
	addRow("DIP LEDs", "E000", bin(p1.PortA()), "PPI1.A output")
	addRow("Keyboard", "—", "—", "2×6 (TODO)")
	addRow("Pen sensors", "—", "—", "TODO")
	addRow("Pen magazine", "—", "—", "TODO")
}
func b2i(b bool) int {
	if b {
		return 1
	}
	return 0
}
func (a *AftografApp) clearPlot() {
	a.mu.Lock()
	a.Plot.Lines = nil
	a.Plot.Reset()
	a.HPGL = hpgl.New()
	a.hpglStep = 0
	a.hpglMode = false
	a.mu.Unlock()
	if a.progBar != nil {
		a.progBar.SetValue(0)
	}
	if a.plotRast != nil {
		a.plotRast.Refresh()
	}
}

// ───── HPGL / Plotter ─────

func (a *AftografApp) loadHPGL() {
	if a.mainWin == nil {
		return
	}
	dialog.ShowFileOpen(func(r fyne.URIReadCloser, err error) {
		if err != nil || r == nil {
			return
		}
		defer r.Close()
		data, readErr := io.ReadAll(r)
		if readErr != nil {
			return
		}
		if err := a.loadHPGLText(string(data)); err != nil {
			dialog.ShowError(err, a.mainWin)
			return
		}
		if a.progBar != nil {
			a.progBar.SetValue(0)
		}
		if a.plotRast != nil {
			a.plotRast.Refresh()
		}
	}, a.mainWin)
}

// loadHPGLText loads and immediately renders a complete direct HPGL preview.
// The step buttons remain available for advancing/replaying the parsed list,
// but loading a file no longer leaves the canvas empty.
func (a *AftografApp) loadHPGLText(text string) error {
	h := hpgl.New()
	if err := h.Parse(text); err != nil {
		return fmt.Errorf("HPGL: %w", err)
	}
	a.mu.Lock()
	a.HPGL = h
	a.Plot.Reset()
	a.Plot.Lines = append([]hpgl.LineSegment(nil), h.Segments...)
	a.hpglStep = len(h.Segments)
	a.hpglMode = true
	a.mu.Unlock()
	return nil
}
func (a *AftografApp) stepHPGL() {
	a.mu.Lock()
	if a.HPGL == nil || a.hpglStep >= len(a.HPGL.Segments) {
		a.mu.Unlock()
		return
	}
	s := a.HPGL.Segments[a.hpglStep]
	a.Plot.Lines = append(a.Plot.Lines, s)
	a.hpglStep++
	a.mu.Unlock()
	if a.progBar != nil {
		a.progBar.SetValue(float64(a.hpglStep) / float64(len(a.HPGL.Segments)))
	}
	if a.plotRast != nil {
		a.plotRast.Refresh()
	}
}
func (a *AftografApp) stepAll() {
	a.mu.Lock()
	if a.HPGL == nil {
		a.mu.Unlock()
		return
	}
	for i := a.hpglStep; i < len(a.HPGL.Segments); i++ {
		a.Plot.Lines = append(a.Plot.Lines, a.HPGL.Segments[i])
	}
	a.hpglStep = len(a.HPGL.Segments)
	a.mu.Unlock()
	if a.progBar != nil {
		a.progBar.SetValue(1)
	}
	if a.plotRast != nil {
		a.plotRast.Refresh()
	}
}
func (a *AftografApp) plotRender(w, h int) image.Image {
	a.mu.Lock()
	lines := append([]hpgl.LineSegment(nil), a.Plot.Lines...)
	a.mu.Unlock()
	wi, hi := max(w, 1), max(h, 1)
	img := image.NewRGBA(image.Rect(0, 0, wi, hi))
	draw.Draw(img, img.Bounds(), &image.Uniform{color.RGBA{245, 240, 232, 255}}, image.Point{}, draw.Src)
	if len(lines) == 0 {
		return img
	}
	mnX, mxX := int(^uint(0)>>1), 0
	mnY, mxY := int(^uint(0)>>1), 0
	for _, s := range lines {
		if s.X1 < mnX {
			mnX = s.X1
		}
		if s.X2 < mnX {
			mnX = s.X2
		}
		if s.X1 > mxX {
			mxX = s.X1
		}
		if s.X2 > mxX {
			mxX = s.X2
		}
		if s.Y1 < mnY {
			mnY = s.Y1
		}
		if s.Y2 < mnY {
			mnY = s.Y2
		}
		if s.Y1 > mxY {
			mxY = s.Y1
		}
		if s.Y2 > mxY {
			mxY = s.Y2
		}
	}
	if mxX-mnX < 1 {
		mxX = mnX + 1
	}
	if mxY-mnY < 1 {
		mxY = mnY + 1
	}
	mg := 30.0
	sx := (float64(wi) - 2*mg) / float64(mxX-mnX)
	sy := (float64(hi) - 2*mg) / float64(mxY-mnY)
	sc := sx
	if sy < sc {
		sc = sy
	}
	tx := func(x int) int { return int(mg + float64(x-mnX)*sc) }
	ty := func(y int) int { return int(float64(hi) - mg - float64(y-mnY)*sc) }
	gr := color.RGBA{210, 200, 180, 255}
	for i := 0; i <= 10; i++ {
		x := int(mg + (float64(wi)-2*mg)*float64(i)/10.0)
		y := int(mg + (float64(hi)-2*mg)*float64(i)/10.0)
		for yy := int(mg); yy < hi-int(mg); yy++ {
			img.Set(x, yy, gr)
		}
		for xx := int(mg); xx < wi-int(mg); xx++ {
			img.Set(xx, y, gr)
		}
	}
	pens := []color.Color{color.RGBA{0, 0, 0, 255}, color.RGBA{204, 0, 0, 255}, color.RGBA{0, 85, 255, 255}, color.RGBA{0, 153, 0, 255}, color.RGBA{204, 170, 0, 255}, color.RGBA{136, 0, 204, 255}, color.RGBA{0, 153, 204, 255}}
	for _, s := range lines {
		drawLine(img, tx(s.X1), ty(s.Y1), tx(s.X2), ty(s.Y2), pens[s.Pen%len(pens)])
	}
	return img
}
func drawLine(img *image.RGBA, x1, y1, x2, y2 int, c color.Color) {
	dx, dy := x2-x1, y2-y1
	if dx < 0 {
		dx = -dx
	}
	if dy < 0 {
		dy = -dy
	}
	sx, sy := 1, 1
	if x1 >= x2 {
		sx = -1
	}
	if y1 >= y2 {
		sy = -1
	}
	e := dx - dy
	for {
		img.Set(x1, y1, c)
		if x1 == x2 && y1 == y2 {
			break
		}
		e2 := 2 * e
		if e2 > -dy {
			e -= dy
			x1 += sx
		}
		if e2 < dx {
			e += dx
			y1 += sy
		}
	}
}

// ───── GUI construction ─────

func (a *AftografApp) MakeWindow(w fyne.Window) fyne.CanvasObject {
	a.mainWin = w
	rowSample := canvas.NewText("0000  00  NOP", color.RGBA{200, 200, 200, 255})
	rowSample.TextStyle = fyne.TextStyle{Monospace: true}
	a.debugRowHeight = rowSample.MinSize().Height
	if a.debugRowHeight <= 0 {
		a.debugRowHeight = 18
	}
	a.debugRowStep = a.debugRowHeight + theme.Size(theme.SizeNamePadding)
	// ── Keyboard shortcuts ──
	w.Canvas().SetOnTypedKey(func(ev *fyne.KeyEvent) {
		switch ev.Name {
		case fyne.KeySpace, fyne.KeyRight:
			a.Step()
		case fyne.KeyR:
			a.Reset()
		case fyne.KeyF5:
			if a.Running {
				a.Pause()
			} else {
				go a.Run()
			}
		case fyne.KeyB:
			a.mu.Lock()
			a.breakpoints[a.CPU.PC] = !a.breakpoints[a.CPU.PC]
			a.mu.Unlock()
			a.refreshBreakpoints()
			a.refreshDisasm()
		case fyne.KeySlash:
			dialog.ShowInformation("Help",
				"Space/→ : Step\nR : Reset\nF5 : Run/Pause\nB : Toggle breakpoint\n? : Help\nEsc : Close",
				w)
		case fyne.KeyEscape:
			// Close any open dialogs by doing nothing special
		}
	})
	mono := fyne.TextStyle{Monospace: true}
	// ── Toolbar ──
	a.statusL = widget.NewLabel("STOP")
	spdW := widget.NewSelect([]string{"1×", "10×", "100×", "1K×", "10K×", "100K×"}, func(s string) {
		a.mu.Lock()
		n := []string{"1×", "10×", "100×", "1K×", "10K×", "100K×"}
		for i, v := range n {
			if v == s {
				a.speedIdx = i
				break
			}
		}
		a.mu.Unlock()
	})
	spdW.SetSelected([]string{"1×", "10×", "100×", "1K×", "10K×", "100K×"}[a.speedIdx])
	tool := container.NewHBox(
		widget.NewLabelWithStyle("Aftograf-882 "+appVersion, fyne.TextAlignLeading, fyne.TextStyle{Bold: true}),
		widget.NewSeparator(),
		widget.NewButtonWithIcon("Rst", theme.ViewRefreshIcon(), a.Reset),
		widget.NewButtonWithIcon("Stp", theme.MediaSkipNextIcon(), a.Step),
		widget.NewButtonWithIcon("Run", theme.MediaPlayIcon(), a.Run),
		widget.NewButtonWithIcon("Pause", theme.MediaPauseIcon(), a.Pause),
		widget.NewSeparator(), a.statusL,
		widget.NewSeparator(), widget.NewLabel("Spd:"), spdW,
		widget.NewSeparator(),
		widget.NewButton("Save", a.saveSession),
		widget.NewButton("Load", a.loadSession),
		widget.NewButton("?", func() {
			dialog.ShowInformation("Aftograf-882 Help",
				"Keyboard shortcuts:\n"+
					"Space/→ : Step\n"+
					"R : Reset\n"+
					"F5 : Run/Pause\n"+
					"B : Toggle breakpoint at PC\n"+
					"? : This help\n\n"+
					"CPU: Click button to jump to address\n"+
					"Disasm: Click row to jump, ● for BP\n"+
					"Memory: Click row to jump",
				a.mainWin)
		}),
	)
	buttonLabel := func(txt string, fn func()) *widget.Button {
		b := widget.NewButton(txt, fn)
		b.Importance = widget.LowImportance
		return b
	}
	a.regBCb = buttonLabel("BC:", func() { a.mu.Lock(); v := a.CPU.GetBC(); a.mu.Unlock(); a.memJump(v) })
	a.regDEb = buttonLabel("DE:", func() { a.mu.Lock(); v := a.CPU.GetDE(); a.mu.Unlock(); a.memJump(v) })
	a.regHLb = buttonLabel("HL:", func() { a.mu.Lock(); v := a.CPU.GetHL(); a.mu.Unlock(); a.memJump(v) })
	a.regSPb = buttonLabel("SP→", func() { a.mu.Lock(); v := a.CPU.SP; a.mu.Unlock(); a.memJump(v) })
	for i := 0; i < 8; i++ {
		a.regDisp[i] = monoLabel("")
	}

	// Editable hex entries
	mkHexEntry := func(init string) *widget.Entry {
		e := widget.NewEntry()
		e.Text = init
		e.TextStyle = fyne.TextStyle{Monospace: true}
		return e
	}
	for i := range a.regEdit {
		a.regEdit[i] = nil
	}
	a.regEdit[0] = mkHexEntry("00")   // A
	a.regEdit[1] = mkHexEntry("00")   // B
	a.regEdit[2] = mkHexEntry("00")   // C
	a.regEdit[3] = mkHexEntry("00")   // D
	a.regEdit[4] = mkHexEntry("00")   // E
	a.regEdit[5] = mkHexEntry("0000") // SP
	setReg8 := func(dst *uint8) func(string) {
		return func(s string) {
			if v, e := strconv.ParseUint(strings.TrimSpace(s), 16, 8); e == nil {
				a.mu.Lock()
				*dst = uint8(v)
				a.mu.Unlock()
				a.syncUI()
			}
		}
	}
	a.regEdit[0].OnSubmitted = setReg8(&a.CPU.A)
	a.regEdit[1].OnSubmitted = setReg8(&a.CPU.B)
	a.regEdit[2].OnSubmitted = setReg8(&a.CPU.C)
	a.regEdit[3].OnSubmitted = setReg8(&a.CPU.D)
	a.regEdit[4].OnSubmitted = setReg8(&a.CPU.E)
	a.regEdit[5].OnSubmitted = func(s string) {
		if v, e := strconv.ParseUint(strings.TrimSpace(s), 16, 16); e == nil {
			a.mu.Lock()
			a.CPU.SP = uint16(v)
			a.mu.Unlock()
			a.syncUI()
		}
	}

	regBox := container.New(&compactVBox{})
	// Row 1: A
	regBox.Add(container.New(&compactHBox{},
		monoLabel("A:"), a.regEdit[0],
	))
	// Row 2: BC pair
	regBox.Add(container.New(&compactHBox{},
		a.regBCb,
		monoLabel("B:"), a.regEdit[1],
		monoLabel("C:"), a.regEdit[2],
	))
	// Row 3: DE pair
	regBox.Add(container.New(&compactHBox{},
		a.regDEb,
		monoLabel("D:"), a.regEdit[3],
		monoLabel("E:"), a.regEdit[4],
	))
	// Row 4: HL pair
	a.regH = mkHexEntry("00")
	a.regL = mkHexEntry("00")
	a.regH.OnSubmitted = setReg8(&a.CPU.H)
	a.regL.OnSubmitted = setReg8(&a.CPU.L)
	regBox.Add(container.New(&compactHBox{},
		a.regHLb,
		monoLabel("H:"), a.regH,
		monoLabel("L:"), a.regL,
	))
	// Row 5: SP button + entry + PC label
	// Use regular HBox for proper entry width allocation
	spEntry := container.NewGridWrap(fyne.NewSize(72, a.regEdit[5].MinSize().Height), a.regEdit[5])
	regBox.Add(container.NewHBox(
		a.regSPb, spEntry, a.regDisp[5],
	))
	// Row 6: Cycles
	regBox.Add(container.New(&compactHBox{},
		a.regDisp[7],
	))
	// Row 7: Flags — horizontal buttons
	fbits := []uint8{cpu.FlagS, cpu.FlagZ, cpu.FlagAC, cpu.FlagP, cpu.FlagCY}
	flagRow := container.New(&compactHBox{})
	for i, fb := range []string{"S", "Z", "AC", "P", "CY"} {
		idx := i
		a.flagBtns[i] = widget.NewButton(fb, func() { a.mu.Lock(); a.CPU.Flags ^= fbits[idx]; a.CPU.Flags |= 2; a.mu.Unlock(); a.syncUI() })
		a.flagBtns[i].Importance = widget.MediumImportance
		flagRow.Add(a.flagBtns[i])
	}
	regBox.Add(flagRow)
	// Row 8: DIP LEDs (D7-D0)
	a.dipLEDs = make([]*canvas.Circle, 8)
	dipRow := container.New(&compactHBox{}, monoLabel("D7-D0:"))
	for i := 7; i >= 0; i-- {
		a.dipLEDs[i] = canvas.NewCircle(color.RGBA{40, 40, 40, 255})
		a.dipLEDs[i].Resize(fyne.NewSize(7, 7))
		dipRow.Add(a.dipLEDs[i])
	}
	regBox.Add(dipRow)
	regCard := widget.NewCard("CPU", "", regBox)

	// Stack
	for i := range a.stackLbl {
		a.stackLbl[i] = newDebugLabel(fmt.Sprintf("%04X:----", i*2), a.debugRowHeight)
	}
	stackCol := container.NewVBox()
	for _, l := range a.stackLbl {
		stackCol.Add(l)
	}
	stackCard := widget.NewCard("Stack", "", container.New(layout.NewVBoxLayout(), stackCol))
	// USART
	uE := widget.NewEntry()
	uE.SetPlaceHolder("hex (01 02 FF)")
	uE.TextStyle = mono
	uStatus := monoLabel("TX:-- RX:--")
	a.uartLogE = widget.NewEntry()
	a.uartLogE.Disable()
	a.uartLogE.TextStyle = mono
	sendBtn := widget.NewButton("Send", func() {
		s := strings.TrimSpace(uE.Text)
		if s == "" {
			return
		}
		parts := strings.Fields(s)
		a.mu.Lock()
		for _, p := range parts {
			if v, e := strconv.ParseUint(p, 16, 8); e == nil {
				a.USART.ReceiveData(uint8(v))
				a.uartLog = append(a.uartLog, fmt.Sprintf("RX: %02X", v))
				if len(a.uartLog) > 500 {
					a.uartLog = a.uartLog[len(a.uartLog)-500:]
				}
			}
		}
		a.mu.Unlock()
		uE.SetText("")
		// Update log display
		n := len(a.uartLog)
		start := 0
		if n > 20 {
			start = n - 20
		}
		var sb strings.Builder
		for _, l := range a.uartLog[start:] {
			sb.WriteString(l + "\n")
		}
		a.uartLogE.SetText(sb.String())
		// Update status
		txP := a.USART.TxPending()
		rxP := a.USART.RxPending()
		txS := "0"
		if txP {
			txS = "1"
		}
		rxS := "0"
		if rxP {
			rxS = "1"
		}
		uStatus.SetText(fmt.Sprintf("TX:%s RX:%s", txS, rxS))
	})
	usartB := widget.NewCard("USART", "",
		container.New(layout.NewVBoxLayout(),
			container.NewHBox(uE, sendBtn),
			uStatus,
			a.uartLogE,
		),
	)
	// Breakpoints panel
	a.bpLbl = container.NewVBox()
	bpScroll := container.NewScroll(a.bpLbl)
	bpCard := widget.NewCard("Breakpoints", "", bpScroll)
	a.refreshBreakpoints()
	// PIO panel
	a.pioLbl = container.NewVBox()
	pioScroll := container.NewScroll(a.pioLbl)
	pioCard := widget.NewCard("I/O", "", pioScroll)
	a.refreshPIO()
	leftTabs := container.NewAppTabs(
		container.NewTabItem("CPU", regCard),
		container.NewTabItem("Stack", stackCard),
		container.NewTabItem("BP", bpCard),
		container.NewTabItem("I/O", pioCard),
	)
	leftCol := container.New(layout.NewVBoxLayout(), leftTabs, usartB)
	leftSc := container.NewScroll(leftCol)

	// ── CENTER: Disassembler ──
	a.dsEntry = widget.NewEntry()
	a.dsEntry.Text = a.disasmSrch
	a.dsEntry.TextStyle = mono
	a.dsEntry.OnChanged = func(s string) { a.mu.Lock(); a.disasmSrch = s; a.mu.Unlock() }
	pcCheck := widget.NewCheck("PC", func(v bool) {
		a.mu.Lock()
		a.followPC = v
		if v {
			a.disasmAddr = a.CPU.PC
		}
		a.mu.Unlock()
		if v {
			a.refreshDisasm()
		}
	})
	a.pcCheck = pcCheck
	// BP navigation buttons (create before HBox, reference inside)
	a.bpPrev = widget.NewButton("◀", func() {
		a.navigateBreakpoint(false)
	})
	a.bpNext = widget.NewButton("▶", func() {
		a.navigateBreakpoint(true)
	})
	dsNav := container.NewHBox(
		monoLabel("BP  PC  Address  HEX code  Mnemonic"), a.dsEntry,
		widget.NewButton("Go", func() {
			if v, e := strconv.ParseUint(a.disasmSrch, 16, 16); e == nil {
				a.disasmAddr = uint16(v)
				a.followPC = false
				a.refreshDisasm()
			}
		}),
		widget.NewButton("◀", func() {
			if a.disasmAddr >= 0x40 {
				a.disasmAddr -= 0x40
			} else {
				a.disasmAddr = 0
			}
			a.followPC = false
			a.refreshDisasm()
		}),
		widget.NewButton("▶", func() { a.disasmAddr += 0x40; a.followPC = false; a.refreshDisasm() }),
		pcCheck,
		widget.NewButton("Copy", func() {
			var sb strings.Builder
			ad, r := a.disasmAddr, 0
			for r < 80 && uint32(ad) < 0x10000 {
				insns := disasm.Disassemble(ad, func(aa uint16) uint8 { return a.MMU.Peek(aa) })
				for _, ins := range insns {
					if ins.Length == 0 {
						ad += 2
						break
					}
					if r >= 80 {
						break
					}
					var hx string
					for _, b := range ins.Bytes {
						hx += fmt.Sprintf("%02X ", b)
					}
					_, hasBP := a.breakpoints[ins.Address]
					bp := "  "
					if hasBP {
						bp = "● "
					}
					hx = strings.TrimSpace(hx)
					fmt.Fprintf(&sb, "%s  %s  %04X  %-8s  %-12s\n", bp, "  ", ins.Address, hx, ins.Mnemonic)
					r++
					ad = ins.Address + uint16(ins.Length)
				}
			}
			a.mainWin.Clipboard().SetContent(sb.String())
		}),
		widget.NewSeparator(),
		monoLabel("BP"), a.bpPrev, a.bpNext,
	)
	// Build initial instruction index so the list starts with correct count
	a.insnIndex = disasm.BuildInsnIndex(func(aa uint16) uint8 { return a.MMU.Peek(aa) })
	a.pcInsnIdx = disasm.InsnIndexForAddr(a.insnIndex, a.CPU.PC)
	textItem := func() fyne.CanvasObject {
		t := canvas.NewText("", color.RGBA{200, 200, 200, 255})
		t.TextStyle = fyne.TextStyle{Monospace: true}
		return t
	}
	a.disasmList = widget.NewList(
		func() int { return len(a.insnIndex) },
		textItem,
		func(id widget.ListItemID, obj fyne.CanvasObject) {
			if int(id) >= len(a.insnIndex) {
				return
			}
			addr := a.insnIndex[id]
			insns := disasm.Disassemble(addr, func(aa uint16) uint8 { return a.MMU.Peek(aa) })
			if len(insns) == 0 || insns[0].Length == 0 {
				return
			}
			ins := &insns[0]
			// Highlight if this is the instruction containing PC
			isPC := int(id) == a.pcInsnIdx
			_, hasBP := a.breakpoints[ins.Address]
			var hx string
			for _, b := range ins.Bytes {
				hx += fmt.Sprintf("%02X ", b)
			}
			hx = strings.TrimSpace(hx)
			bpStr := "  "
			if hasBP {
				bpStr = "● "
			}
			pcStr := "  "
			if isPC {
				pcStr = "→ "
			}
			t := obj.(*canvas.Text)
			t.Text = fmt.Sprintf("%s  %s  %04X  %-8s  %-12s", bpStr, pcStr, ins.Address, hx, ins.Mnemonic)
			if isPC {
				t.Color = color.RGBA{125, 207, 255, 255}
			} else {
				t.Color = color.RGBA{200, 200, 200, 255}
			}
			t.Refresh()
		},
	)
	a.disasmList.OnSelected = func(id widget.ListItemID) {
		a.mu.Lock()
		if int(id) >= len(a.insnIndex) {
			a.mu.Unlock()
			return
		}
		addr := a.insnIndex[id]
		a.breakpoints[addr] = !a.breakpoints[addr]
		a.disasmAddr = addr
		a.followPC = false
		a.disasmSrch = fmt.Sprintf("%04X", addr)
		a.mu.Unlock()
		a.refreshBreakpoints()
		a.memJump(addr)
		a.refreshDisasm()
	}
	dsCard := widget.NewCard("Disassembler", "", container.NewBorder(dsNav, nil, nil, nil, a.disasmList))

	// CENTER: Memory
	a.memEntry = widget.NewEntry()
	a.memEntry.Text = a.memSrch
	a.memEntry.TextStyle = mono
	a.memEntry.OnChanged = func(s string) { a.mu.Lock(); a.memSrch = s; a.mu.Unlock() }
	memNav := container.NewHBox(
		monoLabel("Mem"), a.memEntry,
		widget.NewButton("Go", func() {
			a.mu.Lock()
			s := a.memSrch
			a.mu.Unlock()
			if v, e := strconv.ParseUint(s, 16, 16); e == nil {
				a.memJump(uint16(v))
			}
		}),
		widget.NewButton("◀", func() {
			a.mu.Lock()
			ad := a.memAddr
			a.mu.Unlock()
			if ad >= 0x400 {
				a.memJump(ad - 0x400)
			} else {
				a.memJump(0)
			}
		}),
		widget.NewButton("▶", func() { a.mu.Lock(); ad := a.memAddr; a.mu.Unlock(); a.memJump(ad + 0x400) }),
		widget.NewButton("HL", func() { a.mu.Lock(); ad := a.CPU.GetHL(); a.mu.Unlock(); a.memJump(ad) }),
	)
	// Memory — virtual-scroll list through all 64KB. Keep each row as one
	// compact monospace label so the hexadecimal dump remains visible in the
	// center pane. Clicking a HEX or ASCII cell edits that exact byte.
	a.memList = widget.NewList(
		func() int { return 4096 },
		func() fyne.CanvasObject {
			return newClickLabel("", nil)
		},
		func(id widget.ListItemID, obj fyne.CanvasObject) {
			base := uint16(id) * 16
			row := obj.(*clickLabel)
			var hexSb strings.Builder
			var asciiSb strings.Builder
			for c := range 16 {
				v := a.MMU.Peek(base + uint16(c))
				if c == 8 {
					hexSb.WriteString("  ")
				} else if c > 0 {
					hexSb.WriteByte(' ')
				}
				fmt.Fprintf(&hexSb, "%02X", v)
				if v >= 32 && v <= 126 {
					asciiSb.WriteByte(v)
				} else {
					asciiSb.WriteByte('.')
				}
			}
			row.SetText(fmt.Sprintf("%04X  %s  |%s|", base, hexSb.String(), asciiSb.String()))
			row.TextStyle = mono
			row.onTap = func() { a.editMemoryByte(base) }
			row.onTapAt = func(ev *fyne.PointEvent) {
				char := canvas.NewText("0", color.White)
				char.TextStyle = mono
				charWidth := char.MinSize().Width
				if charWidth <= 0 {
					a.editMemoryByte(base)
					return
				}
				column := int(ev.Position.X / charWidth)
				if offset, ok := memoryByteAtColumn(column); ok {
					a.editMemoryByte(base + uint16(offset))
					return
				}
				// Keep the previous row-click behaviour for the address or spacing.
				a.editMemoryByte(base)
			}
			row.Refresh()
		},
	)
	a.memList.HideSeparators = true
	a.memList.OnSelected = func(id widget.ListItemID) {
		a.memJump(uint16(id) * 16)
	}
	memCard := widget.NewCard("Memory", "", container.NewBorder(memNav, nil, nil, nil, a.memList))

	center := container.NewVSplit(dsCard, memCard)
	center.SetOffset(0.55)

	// ── RIGHT: Plotter ──
	a.plotRast = canvas.NewRaster(a.plotRender)
	a.xL = monoLabel("X:0")
	a.yL = monoLabel("Y:0")
	a.penL = monoLabel("Pen:↑#1")
	a.progBar = widget.NewProgressBar()
	hpglR := container.NewHBox(
		widget.NewButton("Load", a.loadHPGL),
		widget.NewButton("▶N", a.stepHPGL),
		widget.NewButton("▶A", a.stepAll),
		widget.NewButton("Clr", a.clearPlot),
	)
	plotB := container.NewBorder(
		container.NewVBox(container.NewHBox(a.xL, a.yL, a.penL), a.progBar, hpglR),
		nil, nil, nil, a.plotRast)
	plotCard := widget.NewCard("Plotter (A4)", "", plotB)

	// ── MAIN SPLIT ──
	cr := container.NewHSplit(center, plotCard)
	cr.SetOffset(0.6)
	mainS := container.NewHSplit(leftSc, cr)
	mainS.SetOffset(0.17)
	a.syncUI()
	return container.NewBorder(tool, nil, nil, nil, mainS)
}

func (a *AftografApp) editMemoryByte(addr uint16) {
	if a.mainWin == nil {
		return
	}
	a.mu.Lock()
	current := a.MMU.Peek(addr)
	a.mu.Unlock()
	d := dialog.NewEntryDialog(fmt.Sprintf("Memory %04X", addr), "Enter hex byte", func(s string) {
		v, err := strconv.ParseUint(strings.TrimSpace(s), 16, 8)
		if err != nil {
			return
		}
		a.mu.Lock()
		a.MMU.Poke(addr, uint8(v))
		a.mu.Unlock()
		a.syncUI()
	}, a.mainWin)
	d.SetText(fmt.Sprintf("%02X", current))
	d.Show()
}
