package websync

import (
	"context"
	"errors"
	"sort"
	"strings"
	"testing"
	"time"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/knowledge"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/webfetch"
)

const sheet = "https://docs.google.com/spreadsheets/d/e/abc/pub?output=csv"

func feedSrc() Source {
	return Source{ID: 7, AccountID: 1, URL: sheet, Kind: KindFeed, Status: "new"}
}

func keys(ks *kstore) string {
	var out []string
	for _, d := range ks.docs {
		state := ""
		if !d.ValidUntil.IsZero() {
			state = "(hidden)"
		}
		out = append(out, d.SourceKey+state)
	}
	sort.Strings(out)
	return strings.Join(out, ",")
}

func TestFeed_AddThenUnchangedThenChanges(t *testing.T) {
	// Arrange
	s, ks, ss, pg, _, embeds := env()
	pg.data = "id,question,answer,title,content\nfaq-1,Open hours?,9 to 6,,\ndoc-1,,,Refunds,No refunds\nold,,,Old,Gone soon\n"
	ctx := context.Background()

	// Act
	first, err1 := s.Check(ctx, feedSrc())
	afterFirst := *embeds
	same, err2 := s.Check(ctx, ss.last())
	afterSame := *embeds
	pg.data = "id,question,answer,title,content\nfaq-1,Open hours?,9 to 7,,\ndoc-1,,,Refunds,No refunds\nnew-1,,,New,Fresh row\n"
	changed, err3 := s.Check(ctx, ss.last())

	// Assert
	for _, err := range []error{err1, err2, err3} {
		if err != nil {
			t.Fatal(err)
		}
	}
	if first != Added || same != Unchanged || changed != Updated {
		t.Errorf("outcomes = %s, %s, %s; want added, unchanged, updated", first, same, changed)
	}
	// Third check: one changed row, one new row, and hiding the removed row
	// (Update re-indexes it) = 3 more.
	if afterFirst != 3 || afterSame != 3 || *embeds != 6 {
		t.Errorf("embed calls = %d, %d, %d; want 3, 3 (unchanged costs nothing), 6", afterFirst, afterSame, *embeds)
	}
	if got := keys(ks); got != "feed:7:doc-1,feed:7:faq-1,feed:7:new-1,feed:7:old(hidden)" {
		t.Errorf("docs = %s", got)
	}
	last := ss.last()
	if last.Status != "ok" || last.Items != 3 || last.Title != "Google Sheet (CSV)" {
		t.Errorf("source = %+v", last)
	}
	for _, d := range ks.docs {
		if d.SourceKey == "feed:7:faq-1" && (d.Kind != knowledge.KindFAQ || d.Content != "9 to 7") {
			t.Errorf("faq row = %+v", d)
		}
	}
}

func TestFeed_RemovedRowDeletedAfterAWeekUnlessItReturns(t *testing.T) {
	// Arrange
	s, ks, ss, pg, now, _ := env()
	ctx := context.Background()
	pg.data = "id,title,content\na,A,one\nb,B,two\n"
	_, _ = s.Check(ctx, feedSrc())
	pg.data = "id,title,content\na,A,one\n"
	_, _ = s.Check(ctx, ss.last())
	hidden := keys(ks)

	// Act: b comes back after 3 days; later c-less file for 8 days deletes b.
	*now = now.Add(72 * time.Hour)
	pg.data = "id,title,content\na,A,one\nb,B,two\n"
	_, _ = s.Check(ctx, ss.last())
	back := keys(ks)
	pg.data = "id,title,content\na,A,one\n"
	_, _ = s.Check(ctx, ss.last())
	*now = now.Add(8 * 24 * time.Hour)
	_, _ = s.Check(ctx, ss.last())

	// Assert
	if hidden != "feed:7:a,feed:7:b(hidden)" || back != "feed:7:a,feed:7:b" || keys(ks) != "feed:7:a" {
		t.Errorf("hidden=%s back=%s final=%s", hidden, back, keys(ks))
	}
}

func TestFeed_RowThatChangesKindIsReplaced(t *testing.T) {
	// Arrange
	s, ks, ss, pg, _, _ := env()
	ctx := context.Background()
	pg.data = "id,question,answer,title,content\nx,Q?,A,,\n"
	_, _ = s.Check(ctx, feedSrc())

	// Act
	pg.data = "id,question,answer,title,content\nx,,,Now a doc,Longer text\n"
	_, err := s.Check(ctx, ss.last())

	// Assert
	if err != nil || len(ks.docs) != 1 || ks.docs[0].Kind != knowledge.KindText || ks.docs[0].Title != "Now a doc" {
		t.Errorf("err=%v docs=%+v", err, ks.docs)
	}
}

func TestFeed_BadFileChangesNothing(t *testing.T) {
	// Arrange
	s, ks, ss, pg, _, _ := env()
	ctx := context.Background()
	pg.data = "id,title,content\na,A,one\n"
	_, _ = s.Check(ctx, feedSrc())
	before := keys(ks)
	cases := map[string]string{
		"sign-in page instead of CSV": "<!doctype html><html><body>Sign in</body></html>",
		"no id column":                "title,content\nA,one\n",
		"rows without ids":            "id,title,content\n,A,one\n",
	}

	for name, body := range cases {
		// Act
		pg.data = body
		outcome, err := s.Check(ctx, ss.last())

		// Assert
		if outcome != Failed || err == nil || ss.last().Status != "error" || keys(ks) != before {
			t.Errorf("%s: outcome=%s err=%v status=%s docs=%s", name, outcome, err, ss.last().Status, keys(ks))
		}
	}
}

func TestFeed_UnreachableKeepsRowsAndGoneHidesThem(t *testing.T) {
	// Arrange
	s, ks, ss, pg, _, _ := env()
	ctx := context.Background()
	pg.data = "id,title,content\na,A,one\nb,B,two\n"
	_, _ = s.Check(ctx, feedSrc())

	// Act
	pg.err = errors.New("dial tcp: timeout")
	down, _ := s.Check(ctx, ss.last())
	afterDown := keys(ks)
	pg.err = webfetch.ErrNotFound
	gone, _ := s.Check(ctx, ss.last())

	// Assert
	if down != Failed || afterDown != "feed:7:a,feed:7:b" {
		t.Errorf("down=%s docs=%s, want failed and rows kept", down, afterDown)
	}
	if gone != Hidden || keys(ks) != "feed:7:a(hidden),feed:7:b(hidden)" || ss.last().Status != "gone" {
		t.Errorf("gone=%s docs=%s status=%s", gone, keys(ks), ss.last().Status)
	}
}

func TestFeed_SkippedRowsReported(t *testing.T) {
	// Arrange
	s, _, ss, pg, _, _ := env()
	pg.data = "id,title,content\na,A,one\n,No id,two\na,Dup,three\n"

	// Act
	_, err := s.Check(context.Background(), feedSrc())

	// Assert
	last := ss.last()
	if err != nil || last.Status != "ok" || last.Items != 1 || !strings.HasPrefix(last.Error, "2 rows skipped: row 3: no id") {
		t.Errorf("err=%v source=%+v", err, last)
	}
}

func TestRemoveDocuments_OnlyThisSource(t *testing.T) {
	// Arrange
	s, ks, _, _, _, _ := env()
	ks.docs = []knowledge.Document{
		{ID: 1, AccountID: 1, SourceKey: "feed:7:a"},
		{ID: 2, AccountID: 1, SourceKey: "feed:7:b"},
		{ID: 3, AccountID: 1, SourceKey: "feed:70:a"}, // another feed whose ID starts with 7
		{ID: 4, AccountID: 1, SourceKey: "product-001"},
		{ID: 5, AccountID: 1, SourceKey: Key(url)},
	}

	// Act
	n, err := s.RemoveDocuments(context.Background(), feedSrc())
	m, err2 := s.RemoveDocuments(context.Background(), Source{ID: 1, AccountID: 1, URL: url, Kind: KindPage})

	// Assert
	if err != nil || err2 != nil || n != 2 || m != 1 || keys(ks) != "feed:70:a,product-001" {
		t.Errorf("n=%d m=%d err=%v %v docs=%s", n, m, err, err2, keys(ks))
	}
}

func TestFeedTitle(t *testing.T) {
	cases := map[string]string{
		sheet: "Google Sheet (CSV)",
		"https://raw.githubusercontent.com/x/y/main/faq.jsonl": "faq.jsonl (JSONL)",
		"https://example.com/":                                 "example.com (JSONL)",
	}
	for in, want := range cases {
		format := "JSONL"
		if strings.Contains(in, "google") {
			format = "CSV"
		}
		if got := feedTitle(in, format); got != want {
			t.Errorf("feedTitle(%q) = %q, want %q", in, got, want)
		}
	}
}

func TestFeed_RowDatesBecomeTheWindowAndStay(t *testing.T) {
	// Arrange
	s, ks, ss, pg, now, embeds := env()
	bkk, _ := time.LoadLocation("Asia/Bangkok")
	s.Location = bkk
	pg.data = "id,title,content,start_date,last_day\npromo,Sale,20% off,2026-11-01,2026-11-05\n"
	ctx := context.Background()

	// Act: today (7 Nov) the promotion has already ended; later checks change nothing.
	_, err := s.Check(ctx, feedSrc())
	afterFirst := *embeds
	*now = now.Add(30 * 24 * time.Hour)
	again, _ := s.Check(ctx, ss.last())

	// Assert
	if err != nil || len(ks.docs) != 1 {
		t.Fatalf("err=%v docs=%+v", err, ks.docs)
	}
	d := ks.docs[0]
	wantFrom := time.Date(2026, 11, 1, 0, 0, 0, 0, bkk)
	wantUntil := time.Date(2026, 11, 6, 0, 0, 0, 0, bkk)
	if !d.ValidFrom.Equal(wantFrom) || !d.ValidUntil.Equal(wantUntil) {
		t.Errorf("window = %v – %v, want %v – %v", d.ValidFrom, d.ValidUntil, wantFrom, wantUntil)
	}
	if again != Unchanged || *embeds != afterFirst || len(ks.docs) != 1 {
		t.Errorf("again=%s embeds %d→%d docs=%d: an expired row in the file must stay as it is, not be deleted or re-indexed",
			again, afterFirst, *embeds, len(ks.docs))
	}
}

func TestFeed_RemovedDuringCheckLeavesNoRows(t *testing.T) {
	// Arrange: the owner presses Remove while the file is being applied.
	s, ks, ss, pg, _, _ := env()
	pg.data = "id,title,content\na,A,one\nb,B,two\n"
	ss.removed = true

	// Act
	outcome, err := s.Check(context.Background(), feedSrc())

	// Assert
	if outcome != Failed || !errors.Is(err, ErrNotFound) || len(ks.docs) != 0 {
		t.Errorf("outcome=%s err=%v docs=%s, want failed and no rows left", outcome, err, keys(ks))
	}
}

func TestFeed_NULCellDoesNotBlockHidingRemovedRows(t *testing.T) {
	// Arrange
	s, ks, ss, pg, _, _ := env()
	ctx := context.Background()
	pg.data = "id,title,content\na,A,one\nb,B,two\n"
	_, _ = s.Check(ctx, feedSrc())

	// Act: b is removed and a gets a NUL in its text.
	pg.data = "id,title,content\na,A,o\x00ne!\n"
	outcome, err := s.Check(ctx, ss.last())

	// Assert
	if err != nil || outcome != Updated || keys(ks) != "feed:7:a,feed:7:b(hidden)" {
		t.Errorf("outcome=%s err=%v docs=%s", outcome, err, keys(ks))
	}
}
