package admin

import (
	"os"
	"testing"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/pdftext"
)

// TestMain lets this test binary act as the PDF reader's child process.
func TestMain(m *testing.M) {
	if pdftext.IsChild() {
		os.Exit(pdftext.RunChild(os.Stdin, os.Stdout))
	}
	os.Exit(m.Run())
}
