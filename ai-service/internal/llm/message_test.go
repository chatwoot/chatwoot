package llm

import (
	"encoding/json"
	"strings"
	"testing"
)

func TestMessageJSON(t *testing.T) {
	// Arrange
	plain := Message{Role: "user", Content: "hi"}
	withImage := Message{Role: "user", Content: "what is this?", Images: []string{"data:image/png;base64,AAAA"}, ImageDetail: "low"}

	// Act
	a, _ := json.Marshal(plain)
	b, _ := json.Marshal(withImage)

	// Assert
	if string(a) != `{"role":"user","content":"hi"}` {
		t.Errorf("text message changed shape: %s", a)
	}
	for _, want := range []string{`"type":"text","text":"what is this?"`, `"type":"image_url"`, `"url":"data:image/png;base64,AAAA"`, `"detail":"low"`} {
		if !strings.Contains(string(b), want) {
			t.Errorf("image message missing %s: %s", want, b)
		}
	}
}

func TestMessageDecodesPlainReply(t *testing.T) {
	// Act
	var m Message
	err := json.Unmarshal([]byte(`{"role":"assistant","content":"ok"}`), &m)

	// Assert
	if err != nil || m.Content != "ok" {
		t.Fatalf("decode = %+v, %v", m, err)
	}
}
