package app

import (
	"encoding/json"
	"fmt"
	"image"
	"image/color"
	"image/draw"
	"io"
	"strconv"
	"strings"
	"sync"

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

const appVersion = "v1.0.15"

// ───── helpers ─────

func textLine(txt string) *canvas.Text {
	t := canvas.NewText(txt, color.RGBA{200,200,200,255})
	t.TextStyle = fyne.TextStyle{Monospace: true}
	return t
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

// compactLabel is a monospace label compressed into a single container row.
func compactLabel(txt string) *widget.Label { return monoLabel(txt) }

// ───── AftografApp ─────

type AftografApp struct {
	CPU     *cpu.CPU8080
	MMU     *memory.MMU
	PPI1, PPI2 *ppi8255.PPI8255
	PIT     *pit8253.PIT8253
	USART   *usart8251.USART8251
	Plot    *plotter.Plotter
	HPGL    *hpgl.HPGL
	Setts   *settings.Settings

	Running   bool
	RomLoaded bool
	mu        sync.Mutex
	mainWin   fyne.Window
	speedIdx  int

	// Registers: display + editable entries
	regDisp [8]*widget.Label   // 0=A,1=BC,2=DE,3=HL,4=SP,5=PC,6=Flags,7=Cycles
	regEdit [6]*widget.Entry   // 0=A,1=B,2=C,3=D,4=E,5=SP
	regBCb, regDEb, regHLb, regSPb *widget.Button
	flagBtns [5]*widget.Button
	dipLEDs  []*canvas.Circle
	statusL  *widget.Label
	stackLbl [24]*widget.Label

	// Disassembler
	disasmAddr  uint16
	followPC    bool
	disasmSrch  string
	breakpoints map[uint16]bool
	disasmGrid  *fyne.Container
	disasmScroll *container.Scroll
	dsEntry     *widget.Entry

	// Memory viewer
	memAddr   uint16
	memSrch   string
	memGrid   *fyne.Container
	memScroll *container.Scroll
	memEntry  *widget.Entry

	// USART log
	uartLog   []string
	uartLogE  *widget.Entry

	// Plotter
	plotRast *canvas.Raster
	progBar  *widget.ProgressBar
	xL, yL, penL *widget.Label
	hpglStep int
}

func New() *AftografApp {
	app := &AftografApp{
		speedIdx:  3,
		followPC:  true,
		disasmSrch: "0000",
		memSrch:    "0000",
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
	return app
}

func (a *AftografApp) inPort(p uint8) uint8 {
	return a.MMU.Read(0xE000 | uint16(p))
}
func (a *AftografApp) outPort(p uint8, v uint8) {
	a.MMU.Write(0xE000 | uint16(p), v)
}

// ───── CPU control ─────

func (a *AftografApp) Step() {
	if !a.RomLoaded || a.CPU.Halt { return }
	a.Running = false; a.CPU.Step(); a.syncUI()
}
func (a *AftografApp) Run() {
	if a.Running || !a.RomLoaded || a.CPU.Halt { return }
	a.Running = true; a.syncUI()
	n := 10000
	for i := 0; i < n && a.Running && !a.CPU.Halt; i++ { a.CPU.Step() }
	a.Running = false; a.syncUI()
}
func (a *AftografApp) Pause() { a.Running = false }
func (a *AftografApp) Reset() {
	a.CPU.Reset(); a.MMU.LoadDefaultFirmware()
	a.RomLoaded, a.Running = true, false
	a.memAddr, a.disasmAddr = 0, 0
	a.Plot.Reset(); a.HPGL = hpgl.New(); a.hpglStep = 0
	a.syncUI()
}

// ───── refresh all ─────

func (a *AftografApp) syncUI() {
	if a.regDisp[0] == nil { return }
	// Labels update live; entries keep last-submitted value
	a.regDisp[0].SetText(fmt.Sprintf("A:%02X", a.CPU.A))
	a.regBCb.SetText(fmt.Sprintf("BC:%04X", a.CPU.GetBC()))
	a.regDEb.SetText(fmt.Sprintf("DE:%04X", a.CPU.GetDE()))
	a.regHLb.SetText(fmt.Sprintf("HL:%04X", a.CPU.GetHL()))
	a.regSPb.SetText(fmt.Sprintf("SP:%04X", a.CPU.SP))
	a.regDisp[5].SetText(fmt.Sprintf("PC:%04X", a.CPU.PC))
	fl := a.CPU.Flags
	bits := []struct{b uint8; n string}{{cpu.FlagS,"S"},{cpu.FlagZ,"Z"},{cpu.FlagAC,"AC"},{cpu.FlagP,"P"},{cpu.FlagCY,"CY"}}
	for i, f := range bits {
		on := fl&f.b != 0
		a.flagBtns[i].SetText(f.n)
		a.flagBtns[i].Importance = widget.HighImportance; if !on { a.flagBtns[i].Importance = widget.MediumImportance }
		a.flagBtns[i].Refresh()
	}
	a.regDisp[7].SetText(fmt.Sprintf("T:%d", a.CPU.Cycles))
	s := "STOP"; if a.Running { s = "RUN" }; if a.CPU.Halt { s = "HLT" }
	a.statusL.SetText(s)
	if a.followPC { a.disasmAddr = a.CPU.PC; a.disasmSrch = fmt.Sprintf("%04X", a.CPU.PC) }
	// DIP LEDs
	for i := 0; i < 8; i++ {
		on := a.PPI1.A&(1<<uint(i)) != 0
		a.dipLEDs[i].FillColor = color.RGBA{0,200,0,255}; if !on { a.dipLEDs[i].FillColor = color.RGBA{40,40,40,255} }
		a.dipLEDs[i].Refresh()
	}
	// Progress bar
	if a.progBar != nil && a.HPGL != nil && len(a.HPGL.Segments) > 0 {
		a.progBar.SetValue(float64(a.hpglStep) / float64(len(a.HPGL.Segments)))
	}
	a.refreshDisasm(); a.refreshMem(); a.refreshStack()
}

func (a *AftografApp) memJump(ad uint16) {
	a.memAddr = ad & 0xFFF0; a.memSrch = fmt.Sprintf("%04X", a.memAddr)
	if a.memEntry != nil { a.memEntry.SetText(a.memSrch) }; a.refreshMem()
}

// ───── Session save/load ─────

type sessionData struct {
	CPU     cpuState `json:"cpu"`
	BPs     []uint16 `json:"breakpoints"`
	MemAddr uint16   `json:"mem_addr"`
	DisAddr uint16   `json:"disasm_addr"`
}

type cpuState struct {
	A uint8  `json:"a"`
	B uint8  `json:"b"`
	C uint8  `json:"c"`
	D uint8  `json:"d"`
	E uint8  `json:"e"`
	H uint8  `json:"h"`
	L uint8  `json:"l"`
	SP uint16 `json:"sp"`
	PC uint16 `json:"pc"`
	Flags  uint8  `json:"flags"`
	Cycles uint64 `json:"cycles"`
	Halt   bool   `json:"halt"`
}

func (a *AftografApp) saveSession() {
	s := sessionData{
		CPU: cpuState{
			A: a.CPU.A, B: a.CPU.B, C: a.CPU.C,
			D: a.CPU.D, E: a.CPU.E, H: a.CPU.H, L: a.CPU.L,
			SP: a.CPU.SP, PC: a.CPU.PC, Flags: a.CPU.Flags,
			Cycles: a.CPU.Cycles, Halt: a.CPU.Halt,
		},
		MemAddr: a.memAddr,
		DisAddr: a.disasmAddr,
	}
	for ad := range a.breakpoints {
		s.BPs = append(s.BPs, ad)
	}
	data, _ := json.MarshalIndent(s, "", "  ")
	dialog.ShowFileSave(func(wc fyne.URIWriteCloser, err error) {
		if err != nil || wc == nil { return }
		defer wc.Close()
		wc.Write(data)
	}, a.mainWin)
}

func (a *AftografApp) loadSession() {
	if a.mainWin == nil { return }
	dialog.ShowFileOpen(func(r fyne.URIReadCloser, err error) {
		if err != nil || r == nil { return }
		defer r.Close()
		data, _ := io.ReadAll(r)
		var s sessionData
		if json.Unmarshal(data, &s) != nil { return }
		a.CPU.A, a.CPU.B, a.CPU.C = s.CPU.A, s.CPU.B, s.CPU.C
		a.CPU.D, a.CPU.E, a.CPU.H, a.CPU.L = s.CPU.D, s.CPU.E, s.CPU.H, s.CPU.L
		a.CPU.SP, a.CPU.PC, a.CPU.Flags = s.CPU.SP, s.CPU.PC, s.CPU.Flags
		a.CPU.Cycles, a.CPU.Halt = s.CPU.Cycles, s.CPU.Halt
		a.memAddr, a.disasmAddr = s.MemAddr, s.DisAddr
		a.breakpoints = make(map[uint16]bool)
		for _, ad := range s.BPs { a.breakpoints[ad] = true }
		a.syncUI()
	}, a.mainWin)
}

// ───── Disassembler ─────

func (a *AftografApp) refreshDisasm() {
	if a.disasmGrid == nil { return }
	a.disasmGrid.RemoveAll()
	pc := a.CPU.PC
	start := pc; if start > 0x20 { start -= 0x20 }
	addr, pcIdx, row := start, -1, 0
	for row < 50 && addr < 0xFFF0 {
		insns := disasm.Disassemble(addr, func(aa uint16) uint8 { return a.MMU.Read(aa) })
		for _, ins := range insns {
			if ins.Length == 0 { addr += 2; break }
			if row >= 50 { break }
			_, hasBP := a.breakpoints[ins.Address]
			marker := " "; if ins.Address == pc { marker = "→"; pcIdx = row }
			var hx string; for _, b := range ins.Bytes { hx += fmt.Sprintf("%02X ", b) }
			// BP toggle button (colored dot)
			bpLbl := "  "; if hasBP { bpLbl = "●" }
			bpBtn := widget.NewButton(bpLbl, func() {
				if hasBP { delete(a.breakpoints, ins.Address) } else { a.breakpoints[ins.Address] = true }
				a.refreshDisasm()
			})
			bpBtn.Importance = widget.LowImportance
			// PC marker
			mkLbl := marker
			// Address click → jump
			addrBtn := widget.NewButton(fmt.Sprintf("%04X", ins.Address), func() {
				a.disasmAddr = ins.Address; a.followPC = false
				a.disasmSrch = fmt.Sprintf("%04X", ins.Address)
				a.memJump(ins.Address); a.refreshDisasm()
			})
			addrBtn.Importance = widget.LowImportance
			// Bytes + mnemonic as plain text
			rest := textLine(fmt.Sprintf(" %-8s %s", hx, ins.Mnemonic))
			rowC := container.NewHBox(bpBtn, monoLabel(mkLbl), addrBtn, rest)
			a.disasmGrid.Add(rowC)
			row++; addr = ins.Address + uint16(ins.Length)
		}
	}
	if pcIdx == -1 && a.followPC { a.disasmAddr = pc; a.refreshDisasm(); return }
	a.disasmGrid.Refresh()
}

// memColor returns hex-color string for a memory address (ROM/RAM/I/O).
func memColor(addr uint16) color.RGBA {
	switch {
	case addr <= memory.RomEnd:
		return color.RGBA{180, 160, 120, 255} // brown/ROM
	case addr >= memory.RamStart && addr <= memory.RamEnd:
		return color.RGBA{200, 180, 60, 255} // gold/RAM
	case addr >= memory.PPI1Base && addr <= memory.UARTEnd:
		return color.RGBA{160, 100, 200, 255} // purple/I/O
	default:
		return color.RGBA{100, 100, 100, 255} // grey/unmapped
	}
}

func (a *AftografApp) refreshMem() {
	if a.memGrid == nil { return }
	a.memGrid.RemoveAll()
	emptyCol := color.RGBA{80, 80, 80, 255}
	for r := 0; r < 32; r++ {
		base := a.memAddr + uint16(r)*16
		// Address label (clickable → jump to this row)
		addrC := memColor(base)
		addrT := canvas.NewText(fmt.Sprintf("%04X", base), addrC)
		addrT.TextStyle = fyne.TextStyle{Monospace: true}
		addrBtn := widget.NewButton("", func() { a.memJump(base) })
		addrBtn.Importance = widget.LowImportance
		// Build byte row
		row := container.NewHBox(addrBtn, addrT)
		for c := 0; c < 16; c++ {
			ad := base + uint16(c)
			v := a.MMU.Peek(ad)
			cC := memColor(ad)
			valS := fmt.Sprintf("%02X", v)
			valB := widget.NewButton(valS, func() {
				dialog.ShowEntryDialog("Edit byte", fmt.Sprintf("New value for $%04X (hex):", ad),
					func(s string) {
						if v, e := strconv.ParseUint(s, 16, 8); e == nil {
							a.MMU.Poke(ad, uint8(v))
							a.refreshMem()
						}
					}, a.mainWin)
			})
			valB.Importance = widget.LowImportance
			// Color via a tiny square before the button
			dot := canvas.NewCircle(cC)
			dot.Resize(fyne.NewSize(4, 4))
			row.Add(dot)
			row.Add(valB)
		}
		// ASCII column
		sep := canvas.NewText(" |", emptyCol)
		sep.TextStyle = fyne.TextStyle{Monospace: true}
		row.Add(sep)
		for c := 0; c < 16; c++ {
			v := a.MMU.Peek(base + uint16(c))
			ch := "."
			if v >= 32 && v <= 126 { ch = string(rune(v)) }
			t := canvas.NewText(ch, emptyCol)
			t.TextStyle = fyne.TextStyle{Monospace: true}
			row.Add(t)
		}
		a.memGrid.Add(row)
	}
	a.memGrid.Refresh()
}
func (a *AftografApp) refreshStack() {
	sp := a.CPU.SP
	for i := range a.stackLbl {
		adr := sp + uint16(i)*2
		if adr < 0xFFF0 {
			v := uint16(a.MMU.Read(adr+1))<<8 | uint16(a.MMU.Read(adr))
			a.stackLbl[i].SetText(fmt.Sprintf("%04X:%04X", adr, v))
		} else {
			a.stackLbl[i].SetText(fmt.Sprintf("%04X:----", adr))
		}
	}
}

func (a *AftografApp) clearPlot() {
	a.Plot.Lines = nil; a.Plot.Reset(); a.HPGL = hpgl.New(); a.hpglStep = 0
	if a.progBar != nil { a.progBar.SetValue(0) }; if a.plotRast != nil { a.plotRast.Refresh() }
}

// ───── HPGL / Plotter ─────

func (a *AftografApp) loadHPGL() {
	if a.mainWin == nil { return }
	dialog.ShowFileOpen(func(r fyne.URIReadCloser, err error) {
		if err != nil || r == nil { return }
		defer r.Close()
		data, _ := io.ReadAll(r)
		a.HPGL = hpgl.New(); a.HPGL.Parse(string(data))
		a.Plot.Reset(); a.hpglStep = 0
		if a.progBar != nil { a.progBar.SetValue(0) }
		if a.plotRast != nil { a.plotRast.Refresh() }
	}, a.mainWin)
}
func (a *AftografApp) stepHPGL() {
	if a.HPGL == nil || a.hpglStep >= len(a.HPGL.Segments) { return }
	s := a.HPGL.Segments[a.hpglStep]; a.Plot.Lines = append(a.Plot.Lines, s); a.hpglStep++
	if a.progBar != nil { a.progBar.SetValue(float64(a.hpglStep) / float64(len(a.HPGL.Segments))) }
	if a.plotRast != nil { a.plotRast.Refresh() }
}
func (a *AftografApp) stepAll() {
	if a.HPGL == nil { return }
	for i := a.hpglStep; i < len(a.HPGL.Segments); i++ { a.Plot.Lines = append(a.Plot.Lines, a.HPGL.Segments[i]) }
	a.hpglStep = len(a.HPGL.Segments)
	if a.progBar != nil { a.progBar.SetValue(1) }; if a.plotRast != nil { a.plotRast.Refresh() }
}
func (a *AftografApp) plotRender(w, h int) image.Image {
	wi, hi := max(w,1), max(h,1)
	img := image.NewRGBA(image.Rect(0,0,wi,hi))
	draw.Draw(img, img.Bounds(), &image.Uniform{color.RGBA{245,240,232,255}}, image.Point{}, draw.Src)
	if a.Plot == nil || len(a.Plot.Lines) == 0 { return img }
	mnX, mxX := int(^uint(0)>>1), 0
	mnY, mxY := int(^uint(0)>>1), 0
	for _, s := range a.Plot.Lines {
		if s.X1 < mnX { mnX = s.X1 }; if s.X2 < mnX { mnX = s.X2 }
		if s.X1 > mxX { mxX = s.X1 }; if s.X2 > mxX { mxX = s.X2 }
		if s.Y1 < mnY { mnY = s.Y1 }; if s.Y2 < mnY { mnY = s.Y2 }
		if s.Y1 > mxY { mxY = s.Y1 }; if s.Y2 > mxY { mxY = s.Y2 }
	}
	if mxX-mnX < 1 { mxX = mnX+1 }; if mxY-mnY < 1 { mxY = mnY+1 }
	mg := 30.0
	sx := (float64(wi)-2*mg)/float64(mxX-mnX)
	sy := (float64(hi)-2*mg)/float64(mxY-mnY)
	sc := sx; if sy < sc { sc = sy }
	tx := func(x int) int { return int(mg + float64(x-mnX)*sc) }
	ty := func(y int) int { return int(float64(hi) - mg - float64(y-mnY)*sc) }
	gr := color.RGBA{210,200,180,255}
	for i := 0; i <= 10; i++ {
		x := int(mg + (float64(wi)-2*mg)*float64(i)/10.0)
		y := int(mg + (float64(hi)-2*mg)*float64(i)/10.0)
		for yy := int(mg); yy < hi-int(mg); yy++ { img.Set(x, yy, gr) }
		for xx := int(mg); xx < wi-int(mg); xx++ { img.Set(xx, y, gr) }
	}
	pens := []color.Color{color.RGBA{0,0,0,255}, color.RGBA{204,0,0,255}, color.RGBA{0,85,255,255}, color.RGBA{0,153,0,255}, color.RGBA{204,170,0,255}, color.RGBA{136,0,204,255}, color.RGBA{0,153,204,255}}
	for _, s := range a.Plot.Lines { drawLine(img, tx(s.X1), ty(s.Y1), tx(s.X2), ty(s.Y2), pens[s.Pen%len(pens)]) }
	return img
}
func drawLine(img *image.RGBA, x1,y1,x2,y2 int, c color.Color) {
	dx, dy := x2-x1, y2-y1; if dx < 0 { dx = -dx }; if dy < 0 { dy = -dy }
	sx, sy := 1,1; if x1 >= x2 { sx = -1 }; if y1 >= y2 { sy = -1 }
	e := dx-dy
	for { img.Set(x1,y1,c); if x1==x2 && y1==y2 { break }; e2 := 2*e; if e2 > -dy { e -= dy; x1 += sx }; if e2 < dx { e += dx; y1 += sy } }
}

// ───── GUI construction ─────

func (a *AftografApp) MakeWindow(w fyne.Window) fyne.CanvasObject {
	a.mainWin = w
	// ── Keyboard shortcuts ──
	w.Canvas().SetOnTypedKey(func(ev *fyne.KeyEvent) {
		switch ev.Name {
		case fyne.KeySpace, fyne.KeyRight:
			a.Step()
		case fyne.KeyR:
			a.Reset()
		case fyne.KeyF5:
			if a.Running { a.Pause() } else { go a.Run() }
		case fyne.KeyB:
			a.breakpoints[a.CPU.PC] = !a.breakpoints[a.CPU.PC]
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
	spdW := widget.NewSelect([]string{"1×","10×","100×","1K×","10K×","100K×"}, func(s string) {
		n := []string{"1×","10×","100×","1K×","10K×","100K×"}
		for i, v := range n { if v == s { a.speedIdx = i; break } }
	})
	spdW.SetSelected([]string{"1×","10×","100×","1K×","10K×","100K×"}[a.speedIdx])
	tool := container.NewHBox(
		widget.NewLabelWithStyle("Aftograf-882 "+appVersion, fyne.TextAlignLeading, fyne.TextStyle{Bold: true}),
		widget.NewSeparator(),
		widget.NewButtonWithIcon("Rst", theme.ViewRefreshIcon(), a.Reset),
		widget.NewButtonWithIcon("Stp", theme.MediaSkipNextIcon(), a.Step),
		widget.NewButtonWithIcon("Run", theme.MediaPlayIcon(), func() { go a.Run() }),
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
					"CPU: Click register buttons to jump to address\n"+
					"Disasm: Click address to jump, ● to toggle breakpoint\n"+
					"Memory: Click byte to edit, address to jump\n"+
					"Copy: Copy visible disassembly to clipboard",
				a.mainWin)
		}),
	)

	// ── LEFT: Registers (compact grid) ──
	buttonLabel := func(txt string, fn func()) *widget.Button {
		b := widget.NewButton(txt, fn); b.Importance = widget.LowImportance; return b
	}
	a.regBCb = buttonLabel("BC:----", func() { a.memJump(a.CPU.GetBC()) })
	a.regDEb = buttonLabel("DE:----", func() { a.memJump(a.CPU.GetDE()) })
	a.regHLb = buttonLabel("HL:----", func() { a.memJump(a.CPU.GetHL()) })
	a.regSPb = buttonLabel("SP:----", func() { a.memJump(a.CPU.SP) })
	for i := 0; i < 8; i++ { a.regDisp[i] = monoLabel("") }
	a.regDisp[0].SetText("A:--"); a.regDisp[5].SetText("PC:----")

	// Constrained entry for hex editing — Wraps in HBox+Spacer to limit width
	mkHexEntry := func(init string) *widget.Entry {
		e := widget.NewEntry()
		e.Text = init; e.TextStyle = fyne.TextStyle{Monospace: true}
		return e
	}
	// Register edit entries [0]=A [1]=B [2]=C [3]=D [4]=E [5]=SP
	for i := range a.regEdit { a.regEdit[i] = nil }
	a.regEdit[0] = mkHexEntry("00")
	a.regEdit[1] = mkHexEntry("00")
	a.regEdit[2] = mkHexEntry("00")
	a.regEdit[3] = mkHexEntry("00")
	a.regEdit[4] = mkHexEntry("00")
	a.regEdit[5] = mkHexEntry("0000")
	// Wire OnSubmitted to apply register values
	a.regEdit[0].OnSubmitted = func(s string) { if v, e := strconv.ParseUint(s, 16, 8); e == nil { a.CPU.A = uint8(v); a.syncUI() } }
	a.regEdit[1].OnSubmitted = func(s string) { if v, e := strconv.ParseUint(s, 16, 8); e == nil { a.CPU.B = uint8(v); a.syncUI() } }
	a.regEdit[2].OnSubmitted = func(s string) { if v, e := strconv.ParseUint(s, 16, 8); e == nil { a.CPU.C = uint8(v); a.syncUI() } }
	a.regEdit[3].OnSubmitted = func(s string) { if v, e := strconv.ParseUint(s, 16, 8); e == nil { a.CPU.D = uint8(v); a.syncUI() } }
	a.regEdit[4].OnSubmitted = func(s string) { if v, e := strconv.ParseUint(s, 16, 8); e == nil { a.CPU.E = uint8(v); a.syncUI() } }
	a.regEdit[5].OnSubmitted = func(s string) { if v, e := strconv.ParseUint(s, 16, 8); e == nil { a.CPU.SP = uint16(v); a.syncUI() } }

	// Build rows: use GridLayout(2) for paired columns, entries constrained by Border+Spacer
	entRow := func(label string, e *widget.Entry) *fyne.Container {
		return container.NewBorder(nil, nil, nil, layout.NewSpacer(), container.NewHBox(monoLabel(label), e))
	}
	regBox := container.New(layout.NewVBoxLayout(),
		container.NewGridWithColumns(2,
			entRow("A:", a.regEdit[0]),
			a.regBCb,
		),
		container.NewGridWithColumns(2,
			entRow("B:", a.regEdit[1]),
			entRow("C:", a.regEdit[2]),
		),
		container.NewGridWithColumns(2,
			entRow("D:", a.regEdit[3]),
			entRow("E:", a.regEdit[4]),
		),
		container.NewGridWithColumns(2,
			a.regHLb,
			entRow("SP:", a.regEdit[5]),
		),
		container.NewGridWithColumns(2,
			a.regDisp[5],
			a.regDisp[7],
		),
		container.NewHBox(monoLabel("F:"), widget.NewButton("PC→", func() { a.memJump(a.CPU.PC) })),
	)
	// Flag buttons
	fbits := []uint8{cpu.FlagS,cpu.FlagZ,cpu.FlagAC,cpu.FlagP,cpu.FlagCY}
	for i, fb := range []string{"S","Z","AC","P","CY"} {
		idx := i
		a.flagBtns[i] = widget.NewButton(fb, func() { a.CPU.Flags ^= fbits[idx]; a.CPU.Flags |= 2; a.syncUI() })
		a.flagBtns[i].Importance = widget.MediumImportance
		regBox.Add(a.flagBtns[i])
	}
	// DIP LEDs
	a.dipLEDs = make([]*canvas.Circle, 8)
	dipR := container.NewHBox(monoLabel("D7-D0:"))
	for i := 7; i >= 0; i-- {
		a.dipLEDs[i] = canvas.NewCircle(color.RGBA{40,40,40,255})
		a.dipLEDs[i].Resize(fyne.NewSize(8,8))
		dipR.Add(a.dipLEDs[i])
	}
	regBox.Add(dipR)
	regCard := widget.NewCard("CPU", "", regBox)

	// Stack
	for i := range a.stackLbl { a.stackLbl[i] = monoLabel(fmt.Sprintf("%04X:----", i*2)) }
	stackCol := container.NewVBox()
	for _, l := range a.stackLbl { stackCol.Add(l) }
	stackCard := widget.NewCard("Stack", "", container.New(layout.NewVBoxLayout(), stackCol))
	// USART
	uE := widget.NewEntry(); uE.SetPlaceHolder("hex (01 02 FF)"); uE.TextStyle = mono
	uStatus := monoLabel("TX:-- RX:--")
	a.uartLogE = widget.NewEntry(); a.uartLogE.Disable(); a.uartLogE.TextStyle = mono
	sendBtn := widget.NewButton("Send", func() {
		s := strings.TrimSpace(uE.Text)
		if s == "" { return }
		parts := strings.Fields(s)
		for _, p := range parts {
			if v, e := strconv.ParseUint(p, 16, 8); e == nil {
				a.USART.ReceiveData(uint8(v))
				a.uartLog = append(a.uartLog, fmt.Sprintf("RX: %02X", v))
				if len(a.uartLog) > 500 { a.uartLog = a.uartLog[len(a.uartLog)-500:] }
			}
		}
		uE.SetText("")
		// Update log display
		n := len(a.uartLog)
		start := 0; if n > 20 { start = n - 20 }
		var sb strings.Builder
		for _, l := range a.uartLog[start:] { sb.WriteString(l + "\n") }
		a.uartLogE.SetText(sb.String())
		// Update status
		txP := a.USART.TxPending()
		rxP := a.USART.RxPending()
		txS := "0"; if txP { txS = "1" }
		rxS := "0"; if rxP { rxS = "1" }
		uStatus.SetText(fmt.Sprintf("TX:%s RX:%s", txS, rxS))
	})
	usartB := widget.NewCard("USART", "",
		container.New(layout.NewVBoxLayout(),
			container.NewHBox(uE, sendBtn),
			uStatus,
			a.uartLogE,
		),
	)

	leftTabs := container.NewAppTabs(
		container.NewTabItem("CPU", regCard),
		container.NewTabItem("Stack", stackCard),
	)
	leftCol := container.New(layout.NewVBoxLayout(), leftTabs, usartB)
	leftSc := container.NewScroll(leftCol)

	// ── CENTER: Disassembler ──
	a.dsEntry = widget.NewEntry(); a.dsEntry.Text = a.disasmSrch; a.dsEntry.TextStyle = mono
	a.dsEntry.OnChanged = func(s string) { a.disasmSrch = s }
	dsNav := container.NewHBox(
		monoLabel("Disasm"), a.dsEntry,
		widget.NewButton("Go", func() {
			if v, e := strconv.ParseUint(a.disasmSrch, 16, 16); e == nil { a.disasmAddr = uint16(v); a.followPC = false; a.refreshDisasm() }
		}),
		widget.NewButton("◀", func() { if a.disasmAddr >= 0x10 { a.disasmAddr -= 0x10 }; a.refreshDisasm() }),
		widget.NewButton("▶", func() { a.disasmAddr += 0x10; a.refreshDisasm() }),
		widget.NewCheck("PC", func(v bool) { a.followPC = v; if v { a.disasmAddr = a.CPU.PC; a.refreshDisasm() } }),
		widget.NewButton("Copy", func() {
			var sb strings.Builder
			ad, r := a.disasmAddr, 0
			for r < 80 && ad < 0xFFF0 {
				insns := disasm.Disassemble(ad, func(aa uint16) uint8 { return a.MMU.Read(aa) })
				for _, ins := range insns {
					if ins.Length == 0 { ad += 2; break }
					if r >= 80 { break }
					var hx string; for _, b := range ins.Bytes { hx += fmt.Sprintf("%02X ", b) }
					_, hasBP := a.breakpoints[ins.Address]
					bp := "  "; if hasBP { bp = "●" }
					fmt.Fprintf(&sb, "%s%04X  %-8s %s\n", bp, ins.Address, hx, ins.Mnemonic)
					r++; ad = ins.Address + uint16(ins.Length)
				}
			}
			a.mainWin.Clipboard().SetContent(sb.String())
		}),
	)
	a.disasmGrid = container.New(layout.NewVBoxLayout())
	a.disasmScroll = container.NewScroll(a.disasmGrid)
	dsCard := widget.NewCard("Disassembler", "", container.NewBorder(dsNav, nil, nil, nil, a.disasmScroll))

	// CENTER: Memory
	a.memEntry = widget.NewEntry(); a.memEntry.Text = a.memSrch; a.memEntry.TextStyle = mono
	a.memEntry.OnChanged = func(s string) { a.memSrch = s }
	memNav := container.NewHBox(
		monoLabel("Mem"), a.memEntry,
		widget.NewButton("Go", func() {
			if v, e := strconv.ParseUint(a.memSrch, 16, 16); e == nil { a.memJump(uint16(v)) }
		}),
		widget.NewButton("◀", func() { if a.memAddr >= 0x100 { a.memJump(a.memAddr-0x100) } }),
		widget.NewButton("▶", func() { a.memJump(a.memAddr+0x100) }),
		widget.NewButton("HL", func() { a.memJump(a.CPU.GetHL()) }),
	)
	a.memGrid = container.New(layout.NewVBoxLayout())
	a.memScroll = container.NewScroll(a.memGrid)
	memCard := widget.NewCard("Memory", "", container.NewBorder(memNav, nil, nil, nil, a.memScroll))

	center := container.NewVSplit(dsCard, memCard); center.SetOffset(0.55)

	// ── RIGHT: Plotter ──
	a.plotRast = canvas.NewRaster(a.plotRender)
	a.xL = monoLabel("X:0"); a.yL = monoLabel("Y:0"); a.penL = monoLabel("Pen:↑#1")
	a.progBar = widget.NewProgressBar()
	hpglR := container.NewHBox(
		widget.NewButton("Load", a.loadHPGL),
		widget.NewButton("▶N", a.stepHPGL),
		widget.NewButton("▶A", a.stepAll),
		widget.NewButton("Clr", a.clearPlot),
	)
	plotB := container.NewBorder(
		container.NewVBox(container.NewHBox(a.xL,a.yL,a.penL), a.progBar, hpglR),
		nil, nil, nil, a.plotRast)
	plotCard := widget.NewCard("Plotter (A4)", "", plotB)

	// ── MAIN SPLIT ──
	cr := container.NewHSplit(center, plotCard); cr.SetOffset(0.6)
	mainS := container.NewHSplit(leftSc, cr); mainS.SetOffset(0.17)
	a.syncUI()
	return container.NewBorder(tool, nil, nil, nil, mainS)
}
