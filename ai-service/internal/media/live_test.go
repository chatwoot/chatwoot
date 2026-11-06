package media

import (
	"context"
	"os"
	"testing"
)

// Live check: MEDIA_LIVE=1 with LLM_BASE_URL, LLM_API_KEY and MEDIA_AUDIO
// (path to a short voice file). Prints the transcript.
func TestLiveTranscribe(t *testing.T) {
	if os.Getenv("MEDIA_LIVE") != "1" {
		t.Skip("set MEDIA_LIVE=1 to call the real transcription API")
	}
	audio, err := os.ReadFile(os.Getenv("MEDIA_AUDIO"))
	if err != nil {
		t.Fatal(err)
	}
	for _, model := range []string{"gpt-4o-mini-transcribe", "gpt-4o-transcribe"} {
		for _, prompt := range []string{"", os.Getenv("MEDIA_PROMPT")} {
			tr := &Transcriber{BaseURL: os.Getenv("LLM_BASE_URL"), APIKey: os.Getenv("LLM_API_KEY"), Model: model, Prompt: prompt}
			text, err := tr.Transcribe(context.Background(), audio, "voice.m4a")
			if err != nil || text == "" {
				t.Fatalf("transcribe %s: %q %v", model, text, err)
			}
			t.Logf("%s prompt=%v: %s", model, prompt != "", text)
		}
	}
}
