package llm

import (
	"context"
	"encoding/base64"
	"net/http"
	"os"
	"testing"
	"time"
)

// Live check: LLM_LIVE=1 with LLM_BASE_URL, LLM_API_KEY, LLM_IMAGE (a PNG).
// Confirms the image-parts encoding is accepted by each model.
func TestLiveVision(t *testing.T) {
	if os.Getenv("LLM_LIVE") != "1" {
		t.Skip("set LLM_LIVE=1 to call the real chat API with an image")
	}
	png, err := os.ReadFile(os.Getenv("LLM_IMAGE"))
	if err != nil {
		t.Fatal(err)
	}
	img := "data:image/png;base64," + base64.StdEncoding.EncodeToString(png)
	for _, model := range []string{"gpt-6-luna", "gpt-5.4-mini"} {
		c := New(os.Getenv("LLM_BASE_URL"), os.Getenv("LLM_API_KEY"), model, &http.Client{Timeout: 60 * time.Second})
		res, err := c.Complete(context.Background(), []Message{
			{Role: "system", Content: "Is this image a sticker, an emoji, or a like icon, as opposed to a photo, screenshot or document? Answer STICKER or OTHER."},
			{Role: "user", Content: "Classify this image.", Images: []string{img}, ImageDetail: "low"},
		})
		if err != nil {
			t.Fatalf("%s: %v", model, err)
		}
		t.Logf("%s: %s", model, res.Content)
	}
}
