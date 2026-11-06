package trace

import (
	"io"
	"log/slog"
	"os"
	"testing"
	"time"
)

// Live check against a real Langfuse project: set LANGFUSE_LIVE=1 plus
// LANGFUSE_BASE_URL, LANGFUSE_PUBLIC_KEY and LANGFUSE_SECRET_KEY. It sends one
// sample turn tagged environment "dev-check"; look it up in Langfuse.
func TestLiveExportToLangfuse(t *testing.T) {
	if os.Getenv("LANGFUSE_LIVE") != "1" {
		t.Skip("set LANGFUSE_LIVE=1 to send a sample trace")
	}
	// Arrange
	e := NewExporter(Config{
		BaseURL: os.Getenv("LANGFUSE_BASE_URL"), PublicKey: os.Getenv("LANGFUSE_PUBLIC_KEY"),
		SecretKey: os.Getenv("LANGFUSE_SECRET_KEY"), Environment: "dev-check", FlushEvery: time.Hour,
	}, slog.New(slog.NewTextHandler(io.Discard, nil)))
	turn := sampleTurn()
	now := time.Now()
	shift := now.Sub(turn.Start)
	turn.Start, turn.End = turn.Start.Add(shift), turn.End.Add(shift)
	for _, s := range []*Step{turn.Rewrite, turn.Search, &turn.Generation.Step} {
		s.Start, s.End = s.Start.Add(shift), s.End.Add(shift)
	}

	// Act
	e.Record(turn)
	e.Close()

	// Assert: the export itself logs a warning on failure; check the project for the trace.
	if e.Dropped() != 0 {
		t.Fatal("turn dropped")
	}
}
