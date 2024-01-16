//go:build darwin || freebsd || netbsd || openbsd

package readline

import (
	"golang.org/x/sys/unix"
)

func getTermios(fd int) (*Termios, error) {
	tos, err := unix.IoctlGetTermios(fd, unix.TIOCGETA)
	if err != nil {
		return nil, err
	}
	return &Termios{
		Iflag:  tos.Iflag,
		Oflag:  tos.Oflag,
		Cflag:  tos.Cflag,
		Lflag:  tos.Lflag,
		Cc:     tos.Cc,
		Ispeed: tos.Ispeed,
		Ospeed: tos.Ospeed,
	}, nil
}

func setTermios(fd int, termios *Termios) error {
	tos := &unix.Termios{
		Iflag:  termios.Iflag,
		Oflag:  termios.Oflag,
		Cflag:  termios.Cflag,
		Lflag:  termios.Lflag,
		Cc:     termios.Cc,
		Ispeed: termios.Ispeed,
		Ospeed: termios.Ospeed,
	}
	err := unix.IoctlSetTermios(fd, unix.TIOCGETA, tos)
	return err
}
