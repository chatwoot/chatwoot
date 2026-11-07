package bot

import (
	"context"
	"strings"
	"testing"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/memory"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/profile"
)

var (
	pngBytes = []byte("\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR")
	oggBytes = []byte("OggS\x00\x02\x00\x00\x00\x00\x00\x00\x00\x00")
	pdfBytes = []byte("%PDF-1.7\n")
)

func TestUploadKind(t *testing.T) {
	cases := map[string]struct {
		u         Upload
		kind, ext string
	}{
		"png":                 {Upload{Name: "a.PNG", Data: pngBytes}, "image", ""},
		"png named .ogg":      {Upload{Name: "a.ogg", Data: pngBytes}, "image", ""},
		"ogg voice":           {Upload{Name: "voice.OGG", Data: oggBytes}, "audio", "ogg"},
		"mp3 without ID3":     {Upload{Name: "v.mp3", Data: []byte{0xff, 0xfb, 0x90, 0x00}}, "audio", "mp3"},
		"text named .mp3":     {Upload{Name: "v.mp3", Data: []byte("hello there")}, "file", ""},
		"pdf":                 {Upload{Name: "menu.pdf", Data: pdfBytes}, "file", ""},
		"audio bytes no name": {Upload{Name: "", Data: oggBytes}, "file", ""},
	}
	for name, tc := range cases {
		t.Run(name, func(t *testing.T) {
			// Act
			kind, ext := UploadKind(tc.u)

			// Assert
			if kind != tc.kind || ext != tc.ext {
				t.Errorf("UploadKind() = %q, %q; want %q, %q", kind, ext, tc.kind, tc.ext)
			}
		})
	}
}

func userTurn(text string) []memory.Turn { return []memory.Turn{{Role: "user", Content: text}} }

func TestPreviewMedia_VoiceIsTranscribedAndAnswered(t *testing.T) {
	// Arrange
	main := &fakeLLM{reply: "ผ่อนได้ 10 เดือนค่ะ"}
	b, cw, live, _ := mediaBot(profile.Features{Voice: true}, main)

	// Act
	p := b.PreviewMedia(context.Background(), 1, 0, userTurn(""), []Upload{{Name: "voice.ogg", Data: oggBytes}})

	// Assert
	if p.Handoff || p.Reply != "ผ่อนได้ 10 เดือนค่ะ" || p.Media != "voice" || p.Transcript != "ผ่อนได้ไหมคะ" {
		t.Fatalf("preview = %+v", p)
	}
	if !strings.Contains(p.Input, "[Voice message, transcribed] ผ่อนได้ไหมคะ") {
		t.Errorf("input = %q, want the transcript", p.Input)
	}
	if last := main.got[len(main.got)-1]; !strings.Contains(last.Content, "ผ่อนได้ไหมคะ") {
		t.Errorf("model's last message = %q, want the transcript", last.Content)
	}
	if live.calls != 0 || len(cw.calls) != 0 {
		t.Errorf("chatwoot fetches = %d, messages = %d; a test must touch neither", live.calls, len(cw.calls))
	}
}

func TestPreviewMedia_ImageGoesToModel(t *testing.T) {
	// Arrange
	main := &fakeLLM{reply: "รูปนี้คือหน้าโปรแกรมค่ะ"}
	b, _, _, _ := mediaBot(profile.Features{Images: true}, main)

	// Act
	p := b.PreviewMedia(context.Background(), 1, 0, userTurn("อันนี้คืออะไร"), []Upload{{Name: "a.png", Data: pngBytes}})

	// Assert
	last := main.got[len(main.got)-1]
	if p.Handoff || p.Media != "image" || len(last.Images) != 1 || !strings.HasPrefix(last.Images[0], "data:image/png;base64,") {
		t.Fatalf("preview = %+v, last message images = %d", p, len(last.Images))
	}
	if !strings.Contains(last.Content, "อันนี้คืออะไร") {
		t.Errorf("last message = %q, want the typed text too", last.Content)
	}
}

func TestPreviewMedia_FeatureOffHandsOff(t *testing.T) {
	// Arrange
	main := &fakeLLM{reply: "unused"}
	b, _, _, _ := mediaBot(profile.Features{}, main)
	b.opts.AttachmentMessage = "thanks for the file"

	// Act
	p := b.PreviewMedia(context.Background(), 1, 0, userTurn(""), []Upload{{Name: "voice.ogg", Data: oggBytes}})

	// Assert
	if !p.Handoff || p.Reason != ReasonAttachment || p.Reply != "thanks for the file" || main.got != nil {
		t.Fatalf("preview = %+v, model called = %v", p, main.got != nil)
	}
}

func TestPreviewMedia_OtherFileWithTextIsNoted(t *testing.T) {
	// Arrange
	main := &fakeLLM{reply: "ขอบคุณค่ะ"}
	b, _, _, _ := mediaBot(profile.Features{Images: true, Voice: true}, main)

	// Act
	p := b.PreviewMedia(context.Background(), 1, 0, userTurn("ส่งเอกสารให้ค่ะ"), []Upload{{Name: "menu.pdf", Data: pdfBytes}})

	// Assert
	if p.Handoff || !strings.Contains(p.Input, "[The customer attached 1 file: file]") {
		t.Fatalf("preview = %+v", p)
	}
}

func TestPreviewMedia_OnlyOtherFileHandsOff(t *testing.T) {
	// Arrange
	main := &fakeLLM{reply: "unused"}
	b, _, _, _ := mediaBot(profile.Features{Images: true, Voice: true}, main)

	// Act
	p := b.PreviewMedia(context.Background(), 1, 0, userTurn(""), []Upload{{Name: "menu.pdf", Data: pdfBytes}})

	// Assert
	if !p.Handoff || p.Reason != ReasonAttachment || main.got != nil {
		t.Fatalf("preview = %+v", p)
	}
}

func TestPreviewMedia_TranscriptAskingForStaffHandsOff(t *testing.T) {
	// Arrange
	main := &fakeLLM{reply: "unused"}
	b, _, _, _ := mediaBot(profile.Features{Voice: true}, main)
	b.opts.Transcriber = fakeTranscriber{text: "I want a human"}

	// Act
	p := b.PreviewMedia(context.Background(), 1, 0, userTurn(""), []Upload{{Name: "v.ogg", Data: oggBytes}})

	// Assert
	if !p.Handoff || p.Reason != ReasonCustomerAsked || main.got != nil {
		t.Fatalf("preview = %+v", p)
	}
}

func TestPreviewMedia_TooLargeImageIsUnreadable(t *testing.T) {
	// Arrange
	main := &fakeLLM{reply: "unused"}
	b, _, _, _ := mediaBot(profile.Features{Images: true}, main)
	big := append(append([]byte(nil), pngBytes...), make([]byte, maxImageBytes)...)

	// Act
	p := b.PreviewMedia(context.Background(), 1, 0, userTurn(""), []Upload{{Name: "big.png", Data: big}})

	// Assert
	if !p.Handoff || p.Reason != ReasonAttachment || main.got != nil {
		t.Fatalf("preview = %+v; an over-limit image must not reach the model", p)
	}
}

func TestPreviewMedia_NoUploadsIsPlainPreview(t *testing.T) {
	// Arrange
	main := &fakeLLM{reply: "3,900 บาทค่ะ"}
	b, _, _, _ := mediaBot(profile.Features{}, main)

	// Act
	p := b.PreviewMedia(context.Background(), 1, 0, userTurn("ราคา"), nil)

	// Assert
	if p.Handoff || p.Reply != "3,900 บาทค่ะ" || p.Media != "" {
		t.Fatalf("preview = %+v", p)
	}
}
