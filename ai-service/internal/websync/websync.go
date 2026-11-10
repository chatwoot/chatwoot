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
	"sync"
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
	Kind          string // KindPage or KindFeed
	Items         int    // rows in a feed at the last good check
}

// Source kinds.
const (
	KindPage = "page" // one web page → one document
	KindFeed = "feed" // a CSV or JSON Lines file → one document per row
)

// IsFeed reports whether the source is a data feed.
func (s Source) IsFeed() bool { return s.Kind == KindFeed }

// Store persists sources.
type Store interface {
	Add(ctx context.Context, accountID int64, url, kind string) (Source, error)
	List(ctx context.Context, accountID int64) ([]Source, error)
	Get(ctx context.Context, accountID, id int64) (Source, error)
	Remove(ctx context.Context, accountID, id int64) error
	// Claim takes pages that are due (oldest first), marking them as being
	// checked so another run or replica skips them.
	Claim(ctx context.Context, limit int) ([]Source, error)
	// ClaimOne takes one page for "Sync now"; ErrBusy if it is being checked.
	ClaimOne(ctx context.Context, accountID, id int64) (Source, error)
	// Save stores a check result; ErrNotFound if the page was removed meanwhile.
	Save(ctx context.Context, s Source) error
	// SetInterval changes how often a page is checked (hours).
	SetInterval(ctx context.Context, accountID, id int64, hours int) error
	// MarkAllDue schedules every page of the account for the next run.
	MarkAllDue(ctx context.Context, accountID int64) (int, error)
}

// Intervals are the schedule choices offered on the admin page (hours).
var Intervals = []int{1, 6, 24, 168}

// Key is the knowledge document key for a page.
func Key(url string) string { return "web:" + url }

// MaxPages is the most pages one account can keep in sync.
const MaxPages = 200

// Fetcher downloads a page or a data file (webfetch.Fetcher).
type Fetcher interface {
	Fetch(ctx context.Context, url string) (webfetch.Page, error)
	FetchData(ctx context.Context, url string) (webfetch.Page, error)
}

// Errors.
var (
	ErrDuplicate = errors.New("this page is already in the list")
	ErrTooMany   = errors.New("this account already keeps 200 pages in sync; remove one first")
	ErrBusy      = errors.New("this page is being checked right now; try again in a minute")
)

// GoneGrace is how long a page that disappeared stays (hidden) before its
// document is deleted.
const GoneGrace = 7 * 24 * time.Hour

// Syncer checks pages and updates the knowledge base.
type Syncer struct {
	kickOnce sync.Once
	kick     chan struct{}

	Store     Store
	Knowledge *knowledge.Service
	Fetcher   Fetcher
	Events    audit.Store // optional
	Logger    *slog.Logger
	// Location is the business time zone for feed row dates; nil is UTC.
	Location *time.Location
	// Background runs CheckLater's work; nil starts a goroutine (tests run it inline).
	Background func(func())
	Now        func() time.Time
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

// Check fetches one source and updates its documents.
func (s *Syncer) Check(ctx context.Context, src Source) (Outcome, error) {
	if src.IsFeed() {
		return s.checkFeed(ctx, src)
	}
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
		_, err := s.Knowledge.GetByKey(ctx, src.AccountID, Key(src.URL))
		if err == nil {
			src.Status, src.Error, src.Title = "ok", "", title
			return Unchanged, s.Store.Save(ctx, src)
		}
		if !errors.Is(err, knowledge.ErrNotFound) {
			return Failed, err
		}
		// the document was deleted by hand: save it again below
	}
	// The page may have been removed while it was being fetched.
	if _, err := s.Store.Get(ctx, src.AccountID, src.ID); errors.Is(err, ErrNotFound) {
		return Failed, err
	}
	before, _, _, err := s.Knowledge.Upsert(ctx, knowledge.Document{AccountID: src.AccountID, Kind: knowledge.KindText,
		Title: title, Content: text, SourceKey: Key(src.URL)})
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
	doc, err := s.Knowledge.GetByKey(ctx, src.AccountID, Key(src.URL))
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
	for _, known := range []error{webfetch.ErrBlocked, webfetch.ErrNotText, webfetch.ErrTooLarge, webfetch.ErrBadResponse, webfetch.ErrOffSite, webfetch.ErrGoogleSignIn} {
		if errors.Is(err, known) {
			return err.Error()
		}
	}
	return "could not reach the site"
}

// Run checks due pages every interval until ctx ends, one at a time. A batch
// of 50 slow pages can take longer than the interval; the ticker then simply
// waits for it. Kick starts a run early.
func (s *Syncer) Run(ctx context.Context, every time.Duration) {
	t := time.NewTicker(every)
	defer t.Stop()
	for {
		s.RunOnce(ctx)
		select {
		case <-ctx.Done():
			return
		case <-t.C:
		case <-s.kicks():
		}
	}
}

func (s *Syncer) kicks() chan struct{} {
	s.kickOnce.Do(func() { s.kick = make(chan struct{}, 1) })
	return s.kick
}

// Kick asks the running scheduler to check due pages now (non-blocking).
func (s *Syncer) Kick() {
	select {
	case s.kicks() <- struct{}{}:
	default:
	}
}

// RunOnce checks the pages that are due.
func (s *Syncer) RunOnce(ctx context.Context) {
	if s.Knowledge == nil || s.Knowledge.Embedder.Model() == "" {
		return // nothing can be indexed without an embeddings provider
	}
	due, err := s.Store.Claim(ctx, 50)
	if err != nil {
		s.Logger.Error("web sync: list due pages", "error", err)
		return
	}
	for _, src := range due {
		if ctx.Err() != nil {
			return
		}
		outcome := s.checkSafely(ctx, src)
		s.Logger.Info("web page checked", "account_id", src.AccountID, "source_id", src.ID, "outcome", outcome)
	}
}

// checkSafely runs one check with a time limit and turns a panic into a
// failed check, so one bad page cannot stop the service.
func (s *Syncer) checkSafely(ctx context.Context, src Source) (outcome Outcome) {
	limit := 2 * time.Minute
	if src.IsFeed() {
		limit = 10 * time.Minute // up to 500 rows, each embedded when it changes
	}
	cctx, cancel := context.WithTimeout(ctx, limit)
	defer cancel()
	defer func() {
		if r := recover(); r != nil {
			s.Logger.Error("web page check panicked", "account_id", src.AccountID, "source_id", src.ID)
			src.Status, src.Error, src.CheckedAt = "error", "the page could not be processed", s.now()
			_ = s.Store.Save(context.WithoutCancel(ctx), src)
			outcome = Failed
		}
	}()
	outcome, _ = s.Check(cctx, src)
	return outcome
}
