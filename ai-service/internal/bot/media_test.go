package bot

import (
	"context"
	"errors"
	"strings"
	"testing"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/llm"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/profile"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/webhook"
)

type fakeFetcher struct {
	files map[string][]byte
	err   error
	calls int
}

func (f *fakeFetcher) Fetch(_ context.Context, url string) ([]byte, string, error) {
	f.calls++
	if f.err != nil {
		return nil, "", f.err
	}
	b, ok := f.files[url]
	if !ok {
		return nil, "", errors.New("not found")
	}
	return b, "image/png", nil
}

type fakeTranscriber struct {
	text string
	err  error
	hint *string
}

func (f fakeTranscriber) Transcribe(_ context.Context, _ []byte, _, hint string) (string, error) {
	if f.hint != nil {
		*f.hint = hint
	}
	return f.text, f.err
}

type scripted struct {
	reply string
	got   []llm.Message
}

func (s *scripted) Complete(_ context.Context, m []llm.Message) (llm.Result, error) {
	s.got = m
	return llm.Result{Content: s.reply, Model: "small"}, nil
}

func mediaBot(feats profile.Features, main *fakeLLM) (*Bot, *fakeChatwoot, *fakeFetcher, *scripted) {
	cw := &fakeChatwoot{}
	b, _ := newBot(cw, main)
	b.opts.Profiles = &fakeProfiles{byAccount: map[int64]profile.Profile{1: {AccountID: 1, BusinessName: "Johnstocker AI Studio", About: "คอร์ส AutoCut", Features: feats}}}
	f := &fakeFetcher{files: map[string][]byte{"https://chat/voice.m4a": []byte("AUDIO"), "https://chat/a.png": []byte("PNG")}}
	sticker := &scripted{reply: "STICKER"}
	b.opts.Fetcher, b.opts.Transcriber, b.opts.StickerLLM = f, fakeTranscriber{text: "ผ่อนได้ไหมคะ"}, sticker
	return b, cw, f, sticker
}

func fileJob(text string, atts ...webhook.Attachment) Job {
	j := customerMsg(text)
	j.Event.Attachments = atts
	if strings.TrimSpace(text) == "" {
		j.Decision = webhook.HandOff
	}
	return j
}

var (
	voiceNote = webhook.Attachment{FileType: "audio", DataURL: "https://chat/voice.m4a", Extension: "m4a"}
	photo     = webhook.Attachment{FileType: "image", DataURL: "https://chat/a.png"}
)

func lastUser(m []llm.Message) llm.Message { return m[len(m)-1] }

func TestMedia_VoiceOnIsTranscribedAndAnswered(t *testing.T) {
	// Arrange
	main := &fakeLLM{reply: "ผ่อนได้ค่ะ"}
	b, cw, _, _ := mediaBot(profile.Features{Voice: true}, main)

	// Act
	b.Process(context.Background(), fileJob("", voiceNote))

	// Assert
	if got := cw.joined(); got != "typing:on | msg:ผ่อนได้ค่ะ | typing:off" {
		t.Fatalf("calls = %s, want a normal reply", got)
	}
	if u := lastUser(main.got); !strings.Contains(u.Content, "ผ่อนได้ไหมคะ") || !strings.Contains(strings.ToLower(u.Content), "voice") {
		t.Errorf("model saw %q, want the transcript marked as a voice message", u.Content)
	}
}

func TestMedia_FeaturesOffHandOffAsBefore(t *testing.T) {
	for name, job := range map[string]Job{"voice": fileJob("", voiceNote), "photo": fileJob("", photo)} {
		t.Run(name, func(t *testing.T) {
			// Arrange
			b, cw, f, _ := mediaBot(profile.Features{}, &fakeLLM{reply: "x"})
			b.opts.AttachmentMessage = "got your file"

			// Act
			b.Process(context.Background(), job)

			// Assert
			if got := cw.joined(); got != "msg:got your file | note:"+ReasonAttachment+" | handoff" {
				t.Errorf("calls = %s", got)
			}
			if f.calls != 0 {
				t.Error("nothing may be downloaded when the feature is off")
			}
		})
	}
}

func TestMedia_SpokenHandoffRequestHandsOff(t *testing.T) {
	// Arrange
	b, cw, _, _ := mediaBot(profile.Features{Voice: true}, &fakeLLM{reply: "unused"})
	b.opts.Transcriber = fakeTranscriber{text: "I want a human please"}

	// Act
	b.Process(context.Background(), fileJob("", voiceNote))

	// Assert
	if got := cw.joined(); !strings.Contains(got, "note:"+ReasonCustomerAsked) {
		t.Errorf("calls = %s, want a customer-request handoff", got)
	}
}

func TestMedia_ImagesOnGoToTheModel(t *testing.T) {
	// Arrange
	main := &fakeLLM{reply: "นี่คือหน้าจอติดตั้งค่ะ"}
	b, cw, _, _ := mediaBot(profile.Features{Images: true}, main)

	// Act
	b.Process(context.Background(), fileJob("ติดตรงนี้ค่ะ", photo))

	// Assert
	u := lastUser(main.got)
	if len(u.Images) != 1 || !strings.HasPrefix(u.Images[0], "data:image/png;base64,") || !strings.Contains(u.Content, "ติดตรงนี้ค่ะ") {
		t.Errorf("model message = %+v, want the text plus the photo", u)
	}
	if !strings.Contains(cw.joined(), "msg:นี่คือหน้าจอติดตั้งค่ะ") {
		t.Errorf("calls = %s", cw.joined())
	}
	for _, m := range main.got[:len(main.got)-1] {
		if len(m.Images) > 0 {
			t.Error("only the current message may carry images")
		}
	}
}

func TestMedia_StickerGetsAShortReply(t *testing.T) {
	// Arrange
	main := &fakeLLM{reply: "ขอบคุณค่ะ 😊"}
	b, cw, _, sticker := mediaBot(profile.Features{Stickers: true}, main)

	// Act
	b.Process(context.Background(), fileJob("", photo))

	// Assert
	if got := cw.joined(); got != "typing:on | msg:ขอบคุณค่ะ 😊 | typing:off" {
		t.Fatalf("calls = %s, want a reply and no handoff", got)
	}
	if len(sticker.got) == 0 || len(lastUser(sticker.got).Images) != 1 || lastUser(sticker.got).ImageDetail != "low" {
		t.Error("the sticker check must look at the image at low detail")
	}
	if u := lastUser(main.got); len(u.Images) != 0 || !strings.Contains(u.Content, "sticker") {
		t.Errorf("answer model saw %+v, want a sticker note and no image", u)
	}
}

func TestMedia_StickerOnButItIsAPhotoHandsOff(t *testing.T) {
	// Arrange
	b, cw, _, sticker := mediaBot(profile.Features{Stickers: true}, &fakeLLM{reply: "x"})
	sticker.reply = "OTHER"

	// Act
	b.Process(context.Background(), fileJob("", photo))

	// Assert
	if got := cw.joined(); !strings.Contains(got, "note:"+ReasonAttachment) {
		t.Errorf("calls = %s, want an attachment handoff", got)
	}
}

func TestMedia_FailuresAndUnsupportedFilesHandOff(t *testing.T) {
	cases := map[string]func(*Bot, *fakeFetcher) Job{
		"download fails": func(_ *Bot, f *fakeFetcher) Job { f.err = errors.New("boom"); return fileJob("", voiceNote) },
		"transcribe fails": func(b *Bot, _ *fakeFetcher) Job {
			b.opts.Transcriber = fakeTranscriber{err: errors.New("x")}
			return fileJob("", voiceNote)
		},
		"empty transcript": func(b *Bot, _ *fakeFetcher) Job {
			b.opts.Transcriber = fakeTranscriber{text: " "}
			return fileJob("", voiceNote)
		},
		"pdf file": func(*Bot, *fakeFetcher) Job {
			return fileJob("", webhook.Attachment{FileType: "file", DataURL: "https://chat/a.png"})
		},
	}
	for name, setup := range cases {
		t.Run(name, func(t *testing.T) {
			// Arrange
			b, cw, f, _ := mediaBot(profile.Features{Voice: true, Images: true, Stickers: true}, &fakeLLM{reply: "x"})
			job := setup(b, f)

			// Act
			b.Process(context.Background(), job)

			// Assert
			if got := cw.joined(); !strings.Contains(got, "note:"+ReasonAttachment) || !strings.Contains(got, "handoff") {
				t.Errorf("calls = %s, want an attachment handoff", got)
			}
		})
	}
}

func TestMedia_TranscriptionGetsTheBusinessVocabulary(t *testing.T) {
	// Arrange
	b, _, _, _ := mediaBot(profile.Features{Voice: true}, &fakeLLM{reply: "ok"})
	var hint string
	b.opts.Transcriber = fakeTranscriber{text: "ผ่อนได้ไหม", hint: &hint}

	// Act
	b.Process(context.Background(), fileJob("", voiceNote))

	// Assert
	if hint != "Johnstocker AI Studio. คอร์ส AutoCut" {
		t.Errorf("hint = %q, want the business name and description", hint)
	}
}
