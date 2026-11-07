package bot

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"path"
	"strconv"
	"strings"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/memory"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/trace"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/webhook"
)

// Upload is a file attached in the /admin test chat or an answer-eval case,
// standing in for a Chatwoot attachment.
type Upload struct {
	Name string // original file name; only its extension is used
	Data []byte
}

// audioExts are the voice-note formats a test may upload.
var audioExts = map[string]bool{"ogg": true, "oga": true, "opus": true, "mp3": true, "m4a": true, "wav": true, "webm": true, "aac": true}

// audioSniffs are what http.DetectContentType says about those formats
// (m4a sniffs as video/mp4; raw mp3 and aac have no signature).
var audioSniffs = map[string]bool{"application/ogg": true, "video/mp4": true, "video/webm": true, "application/octet-stream": true}

// UploadKind classifies an upload the way Chatwoot labels attachments:
// "image" for formats the chat model reads (by content, not name), "audio"
// for a voice-note extension whose content does not contradict it, else
// "file". ext is the audio extension for the transcriber.
func UploadKind(u Upload) (kind, ext string) {
	sniff := strings.Split(http.DetectContentType(u.Data), ";")[0]
	if visionTypes[sniff] {
		return "image", ""
	}
	ext = strings.ToLower(strings.TrimPrefix(path.Ext(u.Name), "."))
	if audioExts[ext] && (strings.HasPrefix(sniff, "audio/") || audioSniffs[sniff]) {
		return "audio", ext
	}
	return "file", ""
}

// uploadFetcher serves uploads to readMessage under "upload:<n>" names, with
// the same size limits as downloads from Chatwoot.
type uploadFetcher []Upload

func (u uploadFetcher) Fetch(_ context.Context, name string, max int64) ([]byte, string, error) {
	i, err := strconv.Atoi(strings.TrimPrefix(name, "upload:"))
	if err != nil || !strings.HasPrefix(name, "upload:") || i < 0 || i >= len(u) {
		return nil, "", errors.New("unknown upload")
	}
	if int64(len(u[i].Data)) > max {
		return nil, "", fmt.Errorf("upload is over %d bytes", max)
	}
	return u[i].Data, http.DetectContentType(u[i].Data), nil
}

// PreviewMedia is Preview for a latest customer message with files: they go
// through the same media handling as live attachments (the business
// profile's switches, transcription, vision, sticker check, handoff for
// files the bot can't read). Nothing is downloaded, sent or traced.
// history ends with the customer's latest message, whose text may be empty.
func (b *Bot) PreviewMedia(parent context.Context, acct, inbox int64, history []memory.Turn, uploads []Upload) Preview {
	n := len(history)
	if len(uploads) == 0 || n == 0 || history[n-1].Role != "user" {
		return b.Preview(parent, acct, inbox, history)
	}
	ctx, cancel := context.WithTimeout(parent, b.timeout())
	defer cancel()
	log := b.opts.Logger.With("account_id", acct, "inbox_id", inbox)

	ev := webhook.Event{Content: history[n-1].Content, Account: webhook.Account{ID: acct}, Inbox: webhook.Inbox{ID: inbox}}
	for i, u := range uploads {
		kind, ext := UploadKind(u)
		ev.Attachments = append(ev.Attachments, webhook.Attachment{FileType: kind, DataURL: "upload:" + strconv.Itoa(i), Extension: ext})
	}
	tr := &trace.Turn{}
	in, ok := b.readMessage(ctx, log, ev, b.mediaProfile(ctx, log, acct), tr, uploadFetcher(uploads))
	media := Preview{Media: tr.Media}
	if tr.Transcribe != nil {
		media.Transcript = tr.Transcribe.Output
	}
	if !ok {
		msg := b.opts.AttachmentMessage
		if msg == "" {
			msg = b.opts.HandoffMessage
		}
		media.Reply, media.Handoff, media.Reason, media.Input = msg, true, ReasonAttachment, ev.AttachmentNote()
		return media
	}

	turns := append(append([]memory.Turn(nil), history[:n-1]...), memory.Turn{Role: "user", Content: in.text})
	var p Preview
	if b.opts.Handoff.Wants(in.text) {
		p = Preview{Reply: b.opts.HandoffMessage, Handoff: true, Reason: ReasonCustomerAsked}
	} else {
		res, hits, err := b.answer(ctx, log, acct, inbox, turns, &trace.Turn{}, in.images)
		p = previewOf(b, res.Content, res.Model, hits, err)
	}
	p.Input, p.Media, p.Transcript = in.text, media.Media, media.Transcript
	return p
}
