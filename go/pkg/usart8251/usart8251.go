// Package usart8251 emulates the Intel 8251 USART.
//
// Three I/O addresses control the device: data register (read/write),
// command register (write), and status register (read).  A simple buffered
// model provides TX/RX data paths suitable for system-level emulation.
package usart8251

const (
	// Port offsets relative to chip base.
	// Data port: write transmits, read receives.
	DataPort = 0
	// Command port (write): control register.
	// Status port (read): device status.
	CmdStatusPort = 1
)

// Status register bits.
const (
	StatusTxReady  = 0x01 // transmitter ready for data
	StatusRxReady  = 0x02 // receiver has data available
	StatusTxEmpty  = 0x04 // transmitter shift register empty
	StatusParity   = 0x08 // parity error
	StatusOverrun  = 0x10 // overrun error
	StatusFraming  = 0x20 // framing error
	StatusSyncDet  = 0x40 // sync detect
	StatusDSR      = 0x80 // data set ready
)

// Command register bits.
const (
	CmdTxEnable    = 0x01
	CmdDTR         = 0x02 // data terminal ready
	CmdRxEnable    = 0x04
	CmdSendBreak   = 0x08
	CmdErrReset    = 0x10 // reset error flags
	CmdRTS         = 0x20 // request to send
	CmdReset       = 0x40 // internal reset
	CmdHuntMode    = 0x80 // enter hunt mode
)

// Mode register bits decoded from the first command byte after reset.
// (Bits 7-6: baud factor, 5-4: character size, 3-2: parity enable/type,
//  1-0: stop bits.)
const (
	ModeBaudFactor1x   = 0x00 // 1x clock
	ModeBaudFactor16x  = 0x40 // 16x clock
	ModeBaudFactor64x  = 0x80 // 64x clock
	ModeChar5          = 0x00
	ModeChar6          = 0x10
	ModeChar7          = 0x20
	ModeChar8          = 0x30
	ModeParityDisable  = 0x00
	ModeParityOdd      = 0x04
	ModeParityEven     = 0x0C
	ModeStopBitsInhibit= 0x00 // (sync mode)
	ModeStopBits1      = 0x01
	ModeStopBits1_5    = 0x02
	ModeStopBits2      = 0x03
)

// USART8251 emulates one 8251 USART.
type USART8251 struct {
	// Data buffers.
	txBuf byte // last byte written to data port for transmission
	rxBuf byte // last byte received (available at data port)

	// Status register (read at CmdStatusPort).
	status byte

	// Command register (write at CmdStatusPort).
	command byte

	// Mode register — written as the first command byte after reset.
	mode byte

	// Internal state.
	hasMode bool // true once mode byte has been written after reset
	txEmpty bool // transmitter shift register + buffer both empty
}

// New creates a USART8251 with all registers reset.
func New() *USART8251 {
	return &USART8251{
		status:  StatusTxReady | StatusTxEmpty, // transmitter starts idle
		txEmpty: true,
	}
}

// Write writes to the device.
//
//   - offset 0: data — writes the transmit buffer (sets TX ready low until read).
//   - offset 1: if no mode byte has been written yet, stores it as the mode
//     register; otherwise writes the command register.
func (u *USART8251) Write(offset int, val byte) {
	switch offset {
	case DataPort:
		u.txBuf = val
		u.status &^= StatusTxReady // transmitter busy
		u.txEmpty = false
	case CmdStatusPort:
		if !u.hasMode {
			u.mode = val
			u.hasMode = true
			return
		}
		u.command = val
		if val&CmdReset != 0 {
			u.Reset()
			return
		}
		if val&CmdErrReset != 0 {
			u.status &^= StatusParity | StatusOverrun | StatusFraming
		}
		// TX/RX enable reflects in status.
		if val&CmdTxEnable != 0 {
			u.status |= StatusTxReady
		} else {
			u.status &^= StatusTxReady
		}
	}
}

// Read reads from the device.
//
//   - offset 0: data — returns the receive buffer.
//   - offset 1: status register.
func (u *USART8251) Read(offset int) byte {
	switch offset {
	case DataPort:
		// Consume received byte.
		u.status &^= StatusRxReady
		return u.rxBuf
	case CmdStatusPort:
		return u.status
	default:
		return 0
	}
}

// Reset resets the USART to its initial state.
func (u *USART8251) Reset() {
	u.txBuf = 0
	u.rxBuf = 0
	u.status = StatusTxReady | StatusTxEmpty
	u.command = 0
	u.mode = 0
	u.hasMode = false
	u.txEmpty = true
}

// ReceiveData places a byte into the receive buffer, setting RX ready.
// If the previous byte has not been read, the overrun error flag is set.
func (u *USART8251) ReceiveData(val byte) {
	if u.status&StatusRxReady != 0 {
		u.status |= StatusOverrun // previous byte not consumed
	}
	u.rxBuf = val
	u.status |= StatusRxReady
}

// TransmitComplete signals that the transmitter has finished sending the
// current byte and is ready for the next one.
func (u *USART8251) TransmitComplete() {
	u.status |= StatusTxReady
	u.txEmpty = true
}

// TxData returns the byte queued for transmission.
// Returns false if no data is pending.
func (u *USART8251) TxData() (byte, bool) {
	if u.txEmpty {
		return 0, false
	}
	return u.txBuf, true
}

// TxPending returns true when there is a byte ready for transmission.
func (u *USART8251) TxPending() bool {
	return !u.txEmpty && u.command&CmdTxEnable != 0
}

// RxPending returns true when a received byte is available.
func (u *USART8251) RxPending() bool {
	return u.status&StatusRxReady != 0
}

// Command returns the current command register value.
func (u *USART8251) Command() byte { return u.command }

// Mode returns the current mode register value.
func (u *USART8251) Mode() byte { return u.mode }

// ResetAcknowledged returns true if the USART is in a known reset state
// and ready to accept a mode byte on the next command write.
func (u *USART8251) ResetAcknowledged() bool {
	return !u.hasMode
}
