package pdftext

import (
	"os"
	"testing"
	"time"
)

// TestMain lets this test binary act as the child process, so tests exercise
// the real isolation. Hostile-file tests use a short timeout.
func TestMain(m *testing.M) {
	if IsChild() {
		os.Exit(RunChild(os.Stdin, os.Stdout))
	}
	Timeout = 10 * time.Second
	os.Exit(m.Run())
}
