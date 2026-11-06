package bot

import (
	"context"
	"encoding/base64"
	"fmt"
	"log/slog"
	"strings"
	"time"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/llm"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/profile"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/trace"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/webhook"
)

// Fetcher downloads an attachment (media.Fetcher, locked to the Chatwoot host).
type Fetcher interface {
	Fetch(ctx context.Context, url string) ([]byte, string, error)
}

// Transcriber turns a voice note into text (media.Transcriber).
type Transcriber interface {
	Transcribe(ctx context.Context, audio []byte, filename string) (string, error)
}

// Media limits per customer message.
const (
	maxImages     = 3
	maxImageBytes = 5 << 20
)

const stickerInstruction = "Look at the image. Is it a sticker, an emoji, or a thumbs-up/like icon, " +
	"as opposed to a photo, a screenshot or a document? Answer with exactly one word: STICKER or OTHER."

// incoming is a customer message as the model will see it.
type incoming struct {
	text   string
	images []string // data: URLs for the vision model
}

// features are the business's media switches; off when the profile can't load.
func (b *Bot) features(ctx context.Context, log *slog.Logger, acct int64) profile.Features {
	if b.opts.Profiles == nil {
		return profile.Features{}
	}
	p, err := b.opts.Profiles.Get(ctx, acct)
	if err != nil {
		log.Warn("business features lookup failed; media features off", "error", err)
		return profile.Features{}
	}
	return p.Features
}

// readMessage turns text and attachments into what the model sees. ok is
// false when nothing is left to answer (only files the bot may not or cannot
// read), and the caller hands off. Every failure falls back to that handoff.
func (b *Bot) readMessage(ctx context.Context, log *slog.Logger, ev webhook.Event, f profile.Features, tr *trace.Turn) (incoming, bool) {
	text := capText(ev.Content)
	if len(ev.Attachments) == 0 {
		return incoming{text: text}, strings.TrimSpace(text) != ""
	}
	var notes, images, kinds []string
	readable, unreadable := false, false
	for _, a := range ev.Attachments {
		switch {
		case a.FileType == "audio" && f.Voice && b.opts.Transcriber != nil && b.opts.Fetcher != nil && !readable:
			spoken := b.transcribe(ctx, log, a, tr)
			if spoken == "" {
				unreadable = true
				continue
			}
			notes = append(notes, "[Voice message, transcribed] "+capText(spoken))
			readable = true
			kinds = append(kinds, "voice")
		case a.FileType == "image" && f.Images && b.opts.Fetcher != nil && len(images) < maxImages:
			if img := b.image(ctx, log, a); img != "" {
				images = append(images, img)
				kinds = append(kinds, "image")
				continue
			}
			unreadable = true
		case a.FileType == "image" && f.Stickers && b.opts.Fetcher != nil && b.opts.StickerLLM != nil &&
			strings.TrimSpace(ev.Content) == "" && len(ev.Attachments) == 1:
			if b.isSticker(ctx, log, a) {
				notes = append(notes, "[The customer sent a sticker or like]")
				readable = true
				kinds = append(kinds, "sticker")
				continue
			}
			unreadable = true
		default:
			unreadable = true
		}
	}
	if len(images) > 0 {
		notes = append(notes, fmt.Sprintf("[The customer sent %d photo(s), attached to this message]", len(images)))
	}
	if unreadable {
		notes = append(notes, ev.AttachmentNote())
	}
	tr.Media = strings.Join(kinds, ",")
	full := strings.TrimSpace(strings.Join(append([]string{text}, notes...), "\n"))
	ok := strings.TrimSpace(text) != "" || readable || len(images) > 0
	return incoming{text: full, images: images}, ok
}

func (b *Bot) transcribe(ctx context.Context, log *slog.Logger, a webhook.Attachment, tr *trace.Turn) string {
	step := &trace.Step{Start: time.Now()}
	tr.Transcribe = step
	defer func() { step.End = time.Now() }()
	audio, _, err := b.opts.Fetcher.Fetch(ctx, a.DataURL)
	if err != nil {
		log.Warn("voice note download failed", "error", err)
		step.Err = "download failed"
		return ""
	}
	ext := a.Extension
	if ext == "" {
		ext = "m4a"
	}
	spoken, err := b.opts.Transcriber.Transcribe(ctx, audio, "voice."+strings.TrimPrefix(ext, "."))
	if err != nil {
		log.Warn("voice note transcription failed", "error", err)
		step.Err = "transcription failed"
		return ""
	}
	step.Output = spoken
	return strings.TrimSpace(spoken)
}

func (b *Bot) image(ctx context.Context, log *slog.Logger, a webhook.Attachment) string {
	data, ctype, err := b.opts.Fetcher.Fetch(ctx, a.DataURL)
	if err != nil || len(data) == 0 || len(data) > maxImageBytes {
		log.Warn("image download failed or too large", "bytes", len(data))
		return ""
	}
	if !strings.HasPrefix(ctype, "image/") {
		ctype = "image/jpeg"
	}
	return "data:" + ctype + ";base64," + base64.StdEncoding.EncodeToString(data)
}

func (b *Bot) isSticker(ctx context.Context, log *slog.Logger, a webhook.Attachment) bool {
	img := b.image(ctx, log, a)
	if img == "" {
		return false
	}
	res, err := b.opts.StickerLLM.Complete(ctx, []llm.Message{
		{Role: "system", Content: stickerInstruction},
		{Role: "user", Content: "Classify this image.", Images: []string{img}, ImageDetail: "low"},
	})
	if err != nil {
		log.Warn("sticker check failed", "error", err)
		return false
	}
	return strings.Contains(strings.ToUpper(res.Content), "STICKER")
}
