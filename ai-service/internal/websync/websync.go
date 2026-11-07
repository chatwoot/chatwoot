// Package websync keeps public website pages in the knowledge base: each page
// is a document whose source key is its URL. A scheduled check re-fetches it;
// unchanged pages (same content fingerprint) cost nothing, changed pages are
// updated in place, and a page that disappears is hidden at once and deleted
// after a week.
package websync

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"log/slog"
	"strings"
	"time"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/audit"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/knowledge"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/webfetch"
)

// Source is one page being kept in sync.
type Source struct {
	ID            int64
	AccountID     int64
	URL           string
	Title         string
	IntervalHours int
	ContentHash   string
	Status        string // new, ok, error, gone
	Error         string
	CheckedAt     time.Time
	ChangedAt     time.Time
	GoneSince     time.Time
	CreatedAt     time.Time
}

// Store persists sources.
type Store interface {
	Add(ctx context.Context, accountID int64, url string) (Source, error)
	List(ctx context.Context, accountID int64) ([]Source, error)
	Get(ctx context.Context, accountID, id int64) (Source, error)
	Remove(ctx context.Context, accountID, id int64) error
	Due(ctx context.Context, limit int) ([]Source, error)
	Save(ctx context.Context, s Source) error
}

// Fetcher downloads a page (webfetch.Fetcher).
type Fetcher interface {
	Fetch(ctx context.Context, url string) (webfetch.Page, error)
}

// ErrDuplicate means the account already syncs that URL.
var ErrDuplicate = errors.New("this page is already in the list")

// GoneGrace is how long a page that disappeared stays (hidden) before its
// document is deleted.
const GoneGrace = 7 * 24 * time.Hour

// Syncer checks pages and updates the knowledge base.
type Syncer struct {
	Store     Store
	Knowledge *knowledge.Service
	Fetcher   Fetcher
	Events    audit.Store // optional
	Logger    *slog.Logger
	Now       func() time.Time
}

func (s *Syncer) now() time.Time {
	if s.Now != nil {
		return s.Now()
	}
	return time.Now()
}

// Outcome says what a check did.
type Outcome string

// Outcomes.
const (
	Added     Outcome = "added"
	Updated   Outcome = "updated"
	Unchanged Outcome = "unchanged"
	Hidden    Outcome = "hidden"  // the page disappeared; the document is hidden
	Deleted   Outcome = "deleted" // gone for over a week; the document is deleted
	Failed    Outcome = "failed"  // the page could not be read; the last version stays
)

// Check fetches one page and updates its document.
func (s *Syncer) Check(ctx context.Context, src Source) (Outcome, error) {
	src.CheckedAt = s.now()
	page, err := s.Fetcher.Fetch(ctx, src.URL)
	if errors.Is(err, webfetch.ErrNotFound) {
		return s.gone(ctx, src)
	}
	if err != nil {
		src.Status, src.Error = "error", errText(err)
		if saveErr := s.Store.Save(ctx, src); saveErr != nil {
			return Failed, saveErr
		}
		s.Logger.Warn("web page check failed", "account_id", src.AccountID, "source_id", src.ID, "error", src.Error)
		return Failed, err
	}
	title, text := webfetch.Text(page)
	if strings.TrimSpace(text) == "" {
		src.Status, src.Error = "error", "the page has no readable text"
		_ = s.Store.Save(ctx, src)
		return Failed, errors.New(src.Error)
	}
	if title == "" {
		title = src.URL
	}
	if r := []rune(title); len(r) > knowledge.MaxTitleRunes {
		title = string(r[:knowledge.MaxTitleRunes])
	}
	if r := []rune(text); len(r) > knowledge.MaxContentRunes {
		text = string(r[:knowledge.MaxContentRunes])
	}
	sum := sha256.Sum256([]byte(title + "\x00" + text))
	hash := hex.EncodeToString(sum[:])
	wasGone := src.Status == "gone"
	if hash == src.ContentHash && !wasGone {
		src.Status, src.Error, src.Title = "ok", "", title
		return Unchanged, s.Store.Save(ctx, src)
	}
	before, _, _, err := s.Knowledge.Upsert(ctx, knowledge.Document{AccountID: src.AccountID, Kind: knowledge.KindText,
		Title: title, Content: text, SourceKey: src.URL})
	if err != nil {
		src.Status, src.Error = "error", "could not save to the knowledge base"
		_ = s.Store.Save(ctx, src)
		s.Logger.Warn("web page save failed", "account_id", src.AccountID, "source_id", src.ID, "error", err)
		return Failed, err
	}
	outcome := Updated
	if before.ID == 0 {
		outcome = Added
	}
	src.Status, src.Error, src.Title, src.ContentHash, src.ChangedAt, src.GoneSince = "ok", "", title, hash, s.now(), time.Time{}
	if err := s.Store.Save(ctx, src); err != nil {
		return outcome, err
	}
	s.event(ctx, src, "web page "+string(outcome), before)
	return outcome, nil
}

// gone hides the document at once and deletes it after GoneGrace.
func (s *Syncer) gone(ctx context.Context, src Source) (Outcome, error) {
	if src.GoneSince.IsZero() {
		src.GoneSince = s.now()
	}
	src.Status, src.Error = "gone", "the page no longer exists (404 or 410)"
	doc, err := s.Knowledge.GetByKey(ctx, src.AccountID, src.URL)
	outcome := Hidden
	switch {
	case errors.Is(err, knowledge.ErrNotFound):
		// nothing to hide
	case err != nil:
		return Failed, err
	case s.now().Sub(src.GoneSince) >= GoneGrace:
		if err := s.Knowledge.Delete(ctx, src.AccountID, doc.ID); err != nil {
			return Failed, err
		}
		outcome = Deleted
		s.event(ctx, src, "web page deleted (gone for a week)", doc)
	case doc.ValidUntil.IsZero() || doc.ValidUntil.After(s.now()):
		hidden := doc
		hidden.ValidUntil = s.now()
		if hidden.ValidFrom.After(hidden.ValidUntil) {
			hidden.ValidFrom = time.Time{}
		}
		if _, err := s.Knowledge.Update(ctx, hidden); err != nil {
			return Failed, err
		}
		s.event(ctx, src, "web page hidden (no longer exists)", doc)
	}
	src.ContentHash = "" // a page that comes back is re-saved
	return outcome, s.Store.Save(ctx, src)
}

func (s *Syncer) event(ctx context.Context, src Source, action string, before knowledge.Document) {
	if s.Events == nil {
		return
	}
	var copyBefore any
	if before.ID != 0 {
		copyBefore = map[string]any{"id": before.ID, "key": before.SourceKey, "title": before.Title, "content": before.Content}
	}
	if err := s.Events.Record(ctx, audit.Event{AccountID: src.AccountID, Actor: "website sync", Action: action,
		Summary: src.Title, Before: copyBefore}); err != nil {
		s.Logger.Error("web sync change not recorded", "account_id", src.AccountID, "error", err)
	}
}

func errText(err error) string {
	for _, known := range []error{webfetch.ErrBlocked, webfetch.ErrNotText, webfetch.ErrTooLarge, webfetch.ErrBadResponse} {
		if errors.Is(err, known) {
			return err.Error()
		}
	}
	return "could not reach the site"
}

// Run checks due pages every interval until ctx ends, one at a time.
func (s *Syncer) Run(ctx context.Context, every time.Duration) {
	t := time.NewTicker(every)
	defer t.Stop()
	for {
		s.RunOnce(ctx)
		select {
		case <-ctx.Done():
			return
		case <-t.C:
		}
	}
}

// RunOnce checks the pages that are due.
func (s *Syncer) RunOnce(ctx context.Context) {
	if s.Knowledge == nil || s.Knowledge.Embedder.Model() == "" {
		return // nothing can be indexed without an embeddings provider
	}
	due, err := s.Store.Due(ctx, 50)
	if err != nil {
		s.Logger.Error("web sync: list due pages", "error", err)
		return
	}
	for _, src := range due {
		if ctx.Err() != nil {
			return
		}
		cctx, cancel := context.WithTimeout(ctx, 2*time.Minute)
		outcome, _ := s.Check(cctx, src)
		cancel()
		s.Logger.Info("web page checked", "account_id", src.AccountID, "source_id", src.ID, "outcome", outcome)
	}
}
