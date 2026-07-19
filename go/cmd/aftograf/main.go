package main

import (
	"fmt"

	"fyne.io/fyne/v2"
	"fyne.io/fyne/v2/app"

	aftograf "github.com/Michael-VT/Aftograf-882/pkg/app"
)

func main() {
	fmt.Println("[aftograf] creating application window")
	sim := aftograf.New()
	a := app.New()
	w := a.NewWindow("Aftograf-882 Debuger v1.0.18")
	w.Resize(fyne.NewSize(1400, 900))
	w.SetContent(sim.MakeWindow(w))
	fmt.Println("[aftograf] entering GUI event loop")
	w.ShowAndRun()
	fmt.Println("[aftograf] GUI event loop finished")
}
