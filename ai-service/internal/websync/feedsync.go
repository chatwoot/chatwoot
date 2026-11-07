package websync

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	neturl "net/url"
	"path"
	"strconv"
	"strings"
	"time"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/feed"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/knowledge"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/webfetch"
)

// FeedPrefix is the key prefix of a feed's documents.
func FeedPrefix(sourceID int64) string { return "feed:" + strconv.FormatInt(sourceID, 10) + ":" }

// FeedKey is the knowledge document key for one feed row.
func FeedKey(sourceID int64, rowID string) string { return FeedPrefix(sourceID) + rowID }

// FeedResult counts what a feed check changed.
type FeedResult struct {
	Added, Updated, Hidden, Deleted int
	Invalid                         int // rows the knowledge base refused
}

func (r FeedResult) changed() bool { return r.Added+r.Updated+r.Hidden+r.Deleted > 0 }

func (r FeedResult) String() string {
	return fmt.Sprintf("%d added, %d updated, %d hidden, %d deleted", r.Added, r.Updated, r.Hidden, r.Deleted)
}

// checkFeed downloads a CSV or JSON Lines file and brings its rows' documents
// in line: new rows are added, changed rows updated, rows that disappeared
// hidden at once and deleted after GoneGrace. A file that cannot be read or
// parsed changes nothing.
func (s *Syncer) checkFeed(ctx context.Context, src Source) (Outcome, error) {
	src.CheckedAt = s.now()
	page, err := s.Fetcher.FetchData(ctx, src.URL)
	if errors.Is(err, webfetch.ErrNotFound) {
		return s.feedGone(ctx, src)
	}
	if err != nil {
		return s.feedFailed(ctx, src, errText(err), err)
	}
	parsed, err := feed.Parse(page.Body)
	if err != nil {
		return s.feedFailed(ctx, src, err.Error(), err)
	}
	if len(parsed.Rows) == 0 {
		msg := "no usable rows"
		if len(parsed.Problems) > 0 {
			msg += " (" + parsed.Problems[0] + ")"
		}
		return s.feedFailed(ctx, src, msg, errors.New(msg))
	}
	// The source may have been removed while the file was downloading.
	if _, err := s.Store.Get(ctx, src.AccountID, src.ID); errors.Is(err, ErrNotFound) {
		return Failed, err
	}
	res, err := s.applyRows(ctx, src, parsed.Rows)
	if err != nil {
		src.Status, src.Error = "error", "could not save to the knowledge base"
		if saveErr := s.Store.Save(context.WithoutCancel(ctx), src); errors.Is(saveErr, ErrNotFound) {
			s.removedDuringCheck(ctx, src)
		}
		s.Logger.Warn("feed save failed", "account_id", src.AccountID, "source_id", src.ID, "result", res.String(), "error", err)
		return Failed, err
	}
	first := src.Status == "new"
	src.Status, src.Items, src.GoneSince = "ok", len(parsed.Rows), time.Time{}
	src.Error = skippedNote(parsed)
	src.ContentHash = rowsHash(parsed.Rows)
	if src.Title == "" || first {
		src.Title = feedTitle(src.URL, parsed.Format)
	}
	if res.changed() {
		src.ChangedAt = s.now()
		s.event(ctx, src, "data feed synced: "+res.String(), knowledge.Document{})
	}
	if res.Invalid > 0 {
		note := fmt.Sprintf("%d rows could not be saved", res.Invalid)
		src.Error = strings.TrimPrefix(strings.Join([]string{src.Error, note}, "; "), "; ")
	}
	if err := s.Store.Save(ctx, src); err != nil {
		if errors.Is(err, ErrNotFound) {
			s.removedDuringCheck(ctx, src)
		}
		return Failed, err
	}
	switch {
	case first:
		return Added, nil
	case res.changed():
		return Updated, nil
	}
	return Unchanged, nil
}

// applyRows upserts changed rows and retires documents whose row is gone.
func (s *Syncer) applyRows(ctx context.Context, src Source, rows []feed.Row) (FeedResult, error) {
	var res FeedResult
	existing, err := s.Knowledge.ListByKeyPrefix(ctx, src.AccountID, FeedPrefix(src.ID))
	if err != nil {
		return res, err
	}
	byKey := make(map[string]knowledge.Document, len(existing))
	for _, d := range existing {
		byKey[d.SourceKey] = d
	}
	now := s.now()
	for _, row := range rows {
		if err := ctx.Err(); err != nil {
			return res, err
		}
		key := FeedKey(src.ID, row.ID)
		cur, ok := byKey[key]
		delete(byKey, key)
		kind := knowledge.KindText
		if row.FAQ {
			kind = knowledge.KindFAQ
		}
		from, until := s.rowWindow(row)
		if ok && cur.Kind == kind && cur.Title == row.Title && cur.Content == row.Content &&
			cur.ValidFrom.Equal(from) && cur.ValidUntil.Equal(until) {
			continue
		}
		doc, verr := knowledge.Document{AccountID: src.AccountID, Kind: kind, Title: row.Title, Content: row.Content,
			SourceKey: key, ValidFrom: from, ValidUntil: until}.Validate()
		if verr != nil { // one bad row must not stop the others or the clean-up below
			res.Invalid++
			continue
		}
		if ok && cur.Kind != kind {
			// Upsert keeps a document's kind; a row that changed kind is replaced.
			if err := s.Knowledge.Delete(ctx, src.AccountID, cur.ID); err != nil {
				return res, err
			}
			ok = false
		}
		if _, _, _, err := s.Knowledge.Upsert(ctx, doc); err != nil {
			return res, err
		}
		if ok {
			res.Updated++
		} else {
			res.Added++
		}
	}
	for _, d := range byKey { // rows no longer in the file
		r, err := s.retire(ctx, d, now)
		if err != nil {
			return res, err
		}
		res.Hidden += r.Hidden
		res.Deleted += r.Deleted
	}
	return res, nil
}

// retire hides a document whose row disappeared, and deletes it once it has
// been hidden for GoneGrace.
func (s *Syncer) retire(ctx context.Context, d knowledge.Document, now time.Time) (FeedResult, error) {
	switch {
	case !d.ValidUntil.IsZero() && !d.ValidUntil.After(now) && now.Sub(d.ValidUntil) >= GoneGrace:
		return FeedResult{Deleted: 1}, s.Knowledge.Delete(ctx, d.AccountID, d.ID)
	case d.ValidUntil.IsZero() || d.ValidUntil.After(now):
		hidden := d
		hidden.ValidUntil = now
		if hidden.ValidFrom.After(now) {
			hidden.ValidFrom = time.Time{}
		}
		_, err := s.Knowledge.Update(ctx, hidden)
		return FeedResult{Hidden: 1}, err
	}
	return FeedResult{}, nil // already hidden, still within the grace period
}

// removedDuringCheck deletes rows written after the owner removed the source
// mid-check; nothing else would ever clean them up.
func (s *Syncer) removedDuringCheck(ctx context.Context, src Source) {
	n, err := s.RemoveDocuments(context.WithoutCancel(ctx), src)
	if err != nil {
		s.Logger.Error("feed removed during check: clean-up failed", "account_id", src.AccountID, "source_id", src.ID, "error", err)
		return
	}
	s.Logger.Info("feed removed during check: rows deleted", "account_id", src.AccountID, "source_id", src.ID, "deleted", n)
}

// rowWindow turns a row's dates into a validity window in the business time
// zone: from the start of start_date to the end of last_day. The file is the
// source of truth, so the document always gets exactly these dates.
func (s *Syncer) rowWindow(r feed.Row) (from, until time.Time) {
	loc := s.Location
	if loc == nil {
		loc = time.UTC
	}
	if r.StartDate != "" {
		from, _ = time.ParseInLocation(time.DateOnly, r.StartDate, loc)
	}
	if r.LastDay != "" {
		if t, err := time.ParseInLocation(time.DateOnly, r.LastDay, loc); err == nil {
			until = t.AddDate(0, 0, 1)
		}
	}
	return from, until
}

// feedGone: the file itself is gone (404/410); every row is retired.
func (s *Syncer) feedGone(ctx context.Context, src Source) (Outcome, error) {
	if src.GoneSince.IsZero() {
		src.GoneSince = s.now()
	}
	src.Status, src.Error = "gone", "the file no longer exists (404 or 410)"
	docs, err := s.Knowledge.ListByKeyPrefix(ctx, src.AccountID, FeedPrefix(src.ID))
	if err != nil {
		return Failed, err
	}
	var res FeedResult
	for _, d := range docs {
		r, err := s.retire(ctx, d, s.now())
		if err != nil {
			return Failed, err
		}
		res.Hidden += r.Hidden
		res.Deleted += r.Deleted
	}
	if res.changed() {
		s.event(ctx, src, "data feed gone: "+res.String(), knowledge.Document{})
	}
	src.ContentHash = ""
	outcome := Hidden
	if res.Deleted > 0 && res.Hidden == 0 {
		outcome = Deleted
	}
	return outcome, s.Store.Save(ctx, src)
}

func (s *Syncer) feedFailed(ctx context.Context, src Source, msg string, err error) (Outcome, error) {
	src.Status, src.Error = "error", msg
	if saveErr := s.Store.Save(ctx, src); saveErr != nil {
		return Failed, saveErr
	}
	// The message may quote the file (a row id, a cell); log only that it failed.
	s.Logger.Warn("feed check failed", "account_id", src.AccountID, "source_id", src.ID, "reason", logReason(err))
	return Failed, err
}

// RemoveDocuments deletes every document a source created (before the
// source itself is removed).
func (s *Syncer) RemoveDocuments(ctx context.Context, src Source) (int, error) {
	if !src.IsFeed() {
		d, err := s.Knowledge.GetByKey(ctx, src.AccountID, Key(src.URL))
		if errors.Is(err, knowledge.ErrNotFound) {
			return 0, nil
		}
		if err != nil {
			return 0, err
		}
		return 1, s.Knowledge.Delete(ctx, src.AccountID, d.ID)
	}
	docs, err := s.Knowledge.ListByKeyPrefix(ctx, src.AccountID, FeedPrefix(src.ID))
	if err != nil {
		return 0, err
	}
	for i, d := range docs {
		if err := s.Knowledge.Delete(ctx, src.AccountID, d.ID); err != nil {
			return i, err
		}
	}
	return len(docs), nil
}

func skippedNote(r feed.Result) string {
	if r.Skipped == 0 {
		return ""
	}
	note := fmt.Sprintf("%d rows skipped", r.Skipped)
	if len(r.Problems) > 0 {
		note += ": " + strings.Join(r.Problems, "; ")
	}
	return note
}

func rowsHash(rows []feed.Row) string {
	h := sha256.New()
	for _, r := range rows {
		h.Write([]byte(r.ID + "\x00" + feed.RowHash(r) + "\n"))
	}
	return hex.EncodeToString(h.Sum(nil))
}

// feedTitle names a feed in the list: "Google Sheet (CSV)" or the file name.
func feedTitle(raw, format string) string {
	u, err := neturl.Parse(raw)
	if err != nil {
		return format + " file"
	}
	host := strings.TrimPrefix(strings.ToLower(u.Hostname()), "www.")
	switch {
	case host == "docs.google.com" && strings.HasPrefix(u.Path, "/spreadsheets/"):
		return "Google Sheet (" + format + ")"
	case path.Base(u.Path) != "/" && path.Base(u.Path) != "." && path.Base(u.Path) != "pub":
		return path.Base(u.Path) + " (" + format + ")"
	}
	return host + " (" + format + ")"
}

// CheckLater runs one check in the background (a feed can take minutes);
// the source must already be claimed. The page shows the result on reload.
func (s *Syncer) CheckLater(ctx context.Context, src Source) {
	ctx = context.WithoutCancel(ctx)
	run := func() {
		outcome := s.checkSafely(ctx, src)
		s.Logger.Info("source checked", "account_id", src.AccountID, "source_id", src.ID, "kind", src.Kind, "outcome", outcome)
	}
	if s.Background != nil {
		s.Background(run)
		return
	}
	go run()
}

// logReason keeps fetch errors (no file content) and hides parse details.
func logReason(err error) string {
	for _, known := range []error{webfetch.ErrBlocked, webfetch.ErrNotText, webfetch.ErrTooLarge, webfetch.ErrBadResponse, webfetch.ErrOffSite} {
		if errors.Is(err, known) {
			return known.Error()
		}
	}
	if errors.Is(err, feed.ErrNotFeed) {
		return "not a data file"
	}
	return "the file could not be read or has no usable rows"
}
