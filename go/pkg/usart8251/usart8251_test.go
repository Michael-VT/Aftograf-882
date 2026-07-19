package usart8251

import "testing"

func TestReceiveCallbackAndConsumption(t *testing.T) {
	u := New()
	called := 0
	u.OnReceive = func() { called++ }
	u.ReceiveData(0x41)
	if called != 1 {
		t.Fatalf("receive callback count=%d, want 1", called)
	}
	if !u.RxPending() || u.Read(DataPort) != 0x41 || u.RxPending() {
		t.Fatal("received byte was not exposed and consumed correctly")
	}
}

func TestTransmitCallback(t *testing.T) {
	u := New()
	var got byte
	u.OnTransmit = func(v byte) { got = v }
	u.Write(DataPort, 0x55)
	if got != 0x55 {
		t.Fatalf("transmit callback=%02X, want 55", got)
	}
}
