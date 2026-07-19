package hpgl

import "testing"

func TestParseAbsoluteAndRelativeCommands(t *testing.T) {
	h := New()
	if err := h.Parse("IN;SP2;PU0,0;PD100,0;PR0,100;PA50,50;PU;"); err != nil {
		t.Fatal(err)
	}
	if len(h.Segments) != 3 {
		t.Fatalf("segment count=%d, want 3", len(h.Segments))
	}
	want := []LineSegment{
		{X1: 0, Y1: 0, X2: 100, Y2: 0, Pen: 2},
		{X1: 100, Y1: 0, X2: 100, Y2: 100, Pen: 2},
		{X1: 100, Y1: 100, X2: 50, Y2: 50, Pen: 2},
	}
	for i, got := range h.Segments {
		if got != want[i] {
			t.Errorf("segment %d=%+v, want %+v", i, got, want[i])
		}
	}
}

func TestParseNewlinesAndRejectsInvalidCoordinates(t *testing.T) {
	h := New()
	if err := h.Parse("IN\nPU 1,2\nPU 3,4\n"); err != nil {
		t.Fatal(err)
	}
	if len(h.Segments) != 0 {
		t.Fatalf("pen-up movement created %d segments", len(h.Segments))
	}
	if err := h.Parse("PD nope,2"); err == nil {
		t.Fatal("invalid coordinate was accepted")
	}
}
