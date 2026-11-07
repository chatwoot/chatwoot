package bot

import (
	"context"
	"encoding/base64"
	"fmt"
	"log/slog"
	"net/http"
	"strings"
	"time"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/llm"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/profile"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/trace"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/webhook"
)

// Fetcher downloads an attachment (media.Fetcher, locked to the Chatwoot host).
type Fetcher interface {
	Fetch(ctx context.Context, url string, max int64) ([]byte, string, error)
}

// Transcriber turns a voice note into text. hint lists the business's own
// words (name, products) so they are spelled right.
type Transcriber interface {
	Transcribe(ctx context.Context, audio []byte, filename, hint string) (string, error)
}

// Media limits per customer message.
const (
	maxImages     = 3 // download attempts, failed ones included
	maxImageBytes = 5 << 20
	maxAudioBytes = 10 << 20
)

// visionTypes are the image formats the chat model accepts.
var visionTypes = map[string]bool{"image/png": true, "image/jpeg": true, "image/webp": true, "image/gif": true}

const stickerInstruction = "Look at the image. Is it a sticker, an emoji, or a thumbs-up/like icon, " +
	"as opposed to a photo, a screenshot or a document? Answer with exactly one word: STICKER or OTHER."

// incoming is a customer message as the model will see it.
type incoming struct {
	text   string
	images []string // data: URLs for the vision model
}

// mediaProfile is the business profile for media handling; empty (every
// feature off) when it can't load.
func (b *Bot) mediaProfile(ctx context.Context, log *slog.Logger, acct int64) profile.Profile {
	if b.opts.Profiles == nil {
		return profile.Profile{AccountID: acct}
	}
	p, err := b.opts.Profiles.Get(ctx, acct)
	if err != nil {
		log.Warn("business profile lookup failed; media features off", "error", err)
		return profile.Profile{AccountID: acct}
	}
	return p
}

// vocabulary is the transcription hint: business name and description.
func vocabulary(p profile.Profile) string {
	hint := []rune(strings.TrimSpace(p.BusinessName + ". " + p.About))
	if len(hint) > 300 {
		hint = hint[:300]
	}
	return strings.Trim(string(hint), ". ")
}

// readMessage turns text and attachments into what the model sees. ok is
// false when nothing is left to answer (only files the bot may not or cannot
// read), and the caller hands off. Every failure falls back to that handoff.
// fetch downloads the attachments: the Chatwoot fetcher for live messages,
// the uploaded files for a test.
func (b *Bot) readMessage(ctx context.Context, log *slog.Logger, ev webhook.Event, p profile.Profile, tr *trace.Turn, fetch Fetcher) (incoming, bool) {
	f := p.Features
	text := capText(ev.Content)
	if len(ev.Attachments) == 0 {
		return incoming{text: text}, strings.TrimSpace(text) != ""
	}
	var notes, images, kinds []string
	readable, unreadable := false, false
	tried := 0
	for _, a := range ev.Attachments {
		switch {
		case a.FileType == "audio" && f.Voice && b.opts.Transcriber != nil && fetch != nil && !readable:
			spoken := b.transcribe(ctx, log, fetch, a, vocabulary(p), tr)
			if spoken == "" {
				unreadable = true
				continue
			}
			notes = append(notes, "[Voice message, transcribed] "+capText(spoken))
			readable = true
			kinds = append(kinds, "voice")
		case a.FileType == "image" && f.Images && fetch != nil && tried < maxImages:
			tried++
			if img := b.image(ctx, log, fetch, a); img != "" {
				images = append(images, img)
				kinds = append(kinds, "image")
				continue
			}
			unreadable = true
		case a.FileType == "image" && f.Stickers && fetch != nil && b.opts.StickerLLM != nil &&
			strings.TrimSpace(ev.Content) == "" && len(ev.Attachments) == 1:
			if b.isSticker(ctx, log, fetch, a) {
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

func (b *Bot) transcribe(ctx context.Context, log *slog.Logger, fetch Fetcher, a webhook.Attachment, hint string, tr *trace.Turn) string {
	step := &trace.Step{Start: time.Now()}
	tr.Transcribe = step
	defer func() { step.End = time.Now() }()
	audio, _, err := fetch.Fetch(ctx, a.DataURL, maxAudioBytes)
	if err != nil {
		log.Warn("voice note download failed", "error", err)
		step.Err = "download failed"
		return ""
	}
	ext := a.Extension
	if ext == "" {
		ext = "m4a"
	}
	spoken, err := b.opts.Transcriber.Transcribe(ctx, audio, "voice."+strings.TrimPrefix(ext, "."), hint)
	if err != nil {
		log.Warn("voice note transcription failed", "error", err)
		step.Err = "transcription failed"
		return ""
	}
	step.Output = spoken
	return strings.TrimSpace(spoken)
}

func (b *Bot) image(ctx context.Context, log *slog.Logger, fetch Fetcher, a webhook.Attachment) string {
	data, ctype, err := fetch.Fetch(ctx, a.DataURL, maxImageBytes)
	if err != nil || len(data) == 0 {
		log.Warn("image download failed or too large")
		return ""
	}
	if ctype = strings.ToLower(strings.TrimSpace(strings.Split(ctype, ";")[0])); !visionTypes[ctype] {
		ctype = http.DetectContentType(data) // the stored type can be missing or generic
	}
	if !visionTypes[ctype] {
		log.Info("image type the model can't read", "type", ctype) // e.g. HEIC, SVG
		return ""
	}
	return "data:" + ctype + ";base64," + base64.StdEncoding.EncodeToString(data)
}

func (b *Bot) isSticker(ctx context.Context, log *slog.Logger, fetch Fetcher, a webhook.Attachment) bool {
	img := b.image(ctx, log, fetch, a)
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
	// Exact answer only: "OTHER, not a STICKER" must not count as a sticker.
	return strings.EqualFold(strings.Trim(strings.TrimSpace(res.Content), ".!"), "STICKER")
}
