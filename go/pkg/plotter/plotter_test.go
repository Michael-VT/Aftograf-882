package plotter

import "testing"

func TestSyncFromStateBuildsSegment(t *testing.T) {
	p := New()
	p.SyncFromState(10, 20, true, 2)
	p.SyncFromState(30, 20, true, 2)
	p.SyncFromState(30, 20, false, 2)
	if len(p.Lines) != 1 {
		t.Fatalf("line count=%d, want 1", len(p.Lines))
	}
	line := p.Lines[0]
	if line.X1 != 10 || line.Y1 != 20 || line.X2 != 30 || line.Y2 != 20 || line.Pen != 2 {
		t.Fatalf("unexpected line: %+v", line)
	}
}
