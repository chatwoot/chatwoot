package websync

import (
	"context"
	"errors"
	"io"
	"log/slog"
	"strings"
	"testing"
	"time"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/knowledge"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/webfetch"
)

// --- fakes ---

type kstore struct {
	docs    []knowledge.Document
	next    int64
	embeds  int
	updates int
}

func (s *kstore) Insert(_ context.Context, d knowledge.Document, _ string, _ []knowledge.Chunk) (int64, error) {
	s.next++
	d.ID = s.next
	s.docs = append(s.docs, d)
	return d.ID, nil
}
func (s *kstore) ReplaceChunks(context.Context, knowledge.Document, string, []knowledge.Chunk) error {
	return nil
}
func (s *kstore) List(context.Context, int64, string) ([]knowledge.Document, error) {
	return s.docs, nil
}
func (s *kstore) Delete(_ context.Context, _, id int64) error {
	for i, d := range s.docs {
		if d.ID == id {
			s.docs = append(s.docs[:i], s.docs[i+1:]...)
			return nil
		}
	}
	return knowledge.ErrNotFound
}
func (s *kstore) Search(context.Context, knowledge.Query) ([]knowledge.Hit, error) { return nil, nil }
func (s *kstore) Get(_ context.Context, _, id int64) (knowledge.Document, error) {
	for _, d := range s.docs {
		if d.ID == id {
			return d, nil
		}
	}
	return knowledge.Document{}, knowledge.ErrNotFound
}
func (s *kstore) Update(_ context.Context, d knowledge.Document, _ string, _ []knowledge.Chunk) error {
	s.updates++
	for i, cur := range s.docs {
		if cur.ID == d.ID {
			d.SourceKey = cur.SourceKey
			s.docs[i] = d
			return nil
		}
	}
	return knowledge.ErrNotFound
}
func (s *kstore) MarkUsed(context.Context, int64, []int64) error { return nil }
func (s *kstore) GetByKey(_ context.Context, _ int64, key string) (knowledge.Document, error) {
	for _, d := range s.docs {
		if d.SourceKey == key {
			return d, nil
		}
	}
	return knowledge.Document{}, knowledge.ErrNotFound
}

type emb struct{ calls *int }

func (emb) Model() string { return "m" }
func (e emb) Embed(_ context.Context, t []string) ([][]float32, error) {
	*e.calls++
	return make([][]float32, len(t)), nil
}

type srcStore struct{ saved []Source }

func (s *srcStore) Add(context.Context, int64, string, string) (Source, error) { return Source{}, nil }
func (s *srcStore) List(context.Context, int64) ([]Source, error)              { return nil, nil }
func (s *srcStore) Get(context.Context, int64, int64) (Source, error)          { return Source{}, nil }
func (s *srcStore) Remove(context.Context, int64, int64) error                 { return nil }
func (s *srcStore) Claim(context.Context, int) ([]Source, error)               { return nil, nil }
func (s *srcStore) SetInterval(context.Context, int64, int64, int) error       { return nil }
func (s *srcStore) MarkAllDue(context.Context, int64) (int, error)             { return 0, nil }
func (s *srcStore) ClaimOne(context.Context, int64, int64) (Source, error) {
	return Source{}, nil
}
func (s *srcStore) Save(_ context.Context, src Source) error {
	s.saved = append(s.saved, src)
	return nil
}
func (s *srcStore) last() Source { return s.saved[len(s.saved)-1] }

type page struct {
	html string
	data string // FetchData body
	err  error
}

func (p *page) FetchData(context.Context, string) (webfetch.Page, error) {
	return webfetch.Page{ContentType: "text/csv", Body: []byte(p.data)}, p.err
}

func (p *page) Fetch(context.Context, string) (webfetch.Page, error) {
	return webfetch.Page{ContentType: "text/html", Body: []byte(p.html)}, p.err
}

func env() (*Syncer, *kstore, *srcStore, *page, *time.Time, *int) {
	ks, ss, pg := &kstore{}, &srcStore{}, &page{}
	embeds := 0
	now := time.Date(2026, 11, 7, 12, 0, 0, 0, time.UTC)
	return &Syncer{
		Store: ss, Fetcher: pg, Logger: slog.New(slog.NewJSONHandler(io.Discard, nil)), Now: func() time.Time { return now },
		Knowledge: &knowledge.Service{Store: ks, Embedder: emb{&embeds}, TopK: 4, ChunkRunes: 800},
	}, ks, ss, pg, &now, &embeds
}

const url = "https://www.johnstockeraistudio.com/legal/refund"

// --- tests ---

func TestCheck_AddThenUnchangedThenUpdated(t *testing.T) {
	// Arrange
	s, ks, ss, pg, _, embeds := env()
	pg.html = "<title>Refund</title><main><h1>Refund</h1><p>No refunds for digital goods.</p></main>"
	src := Source{ID: 1, AccountID: 1, URL: url}

	// Act
	added, err1 := s.Check(context.Background(), src)
	src = ss.last()
	afterAdd := *embeds
	same, err2 := s.Check(context.Background(), src)
	src = ss.last()
	pg.html = "<title>Refund</title><main><h1>Refund</h1><p>Refund within 14 days.</p></main>"
	updated, err3 := s.Check(context.Background(), src)

	// Assert
	if err1 != nil || err2 != nil || err3 != nil || added != Added || same != Unchanged || updated != Updated {
		t.Fatalf("outcomes %v %v %v errs %v %v %v", added, same, updated, err1, err2, err3)
	}
	if *embeds != afterAdd+1 {
		t.Errorf("an unchanged page was re-embedded: %d embed calls after add, %d total", afterAdd, *embeds)
	}
	if len(ks.docs) != 1 || ks.docs[0].SourceKey != Key(url) || ks.docs[0].Title != "Refund" || ks.docs[0].Content == "" {
		t.Fatalf("docs = %+v", ks.docs)
	}
	if ss.last().Status != "ok" || ss.last().ContentHash == "" {
		t.Errorf("source = %+v", ss.last())
	}
}

func TestCheck_GoneHidesThenDeletesAndComesBack(t *testing.T) {
	// Arrange
	s, ks, ss, pg, now, _ := env()
	pg.html = "<title>Promo</title><p>Loy Krathong promo 2,900</p>"
	if _, err := s.Check(context.Background(), Source{ID: 1, AccountID: 1, URL: url}); err != nil {
		t.Fatal(err)
	}

	// Act: the page disappears.
	pg.err = webfetch.ErrNotFound
	hidden, _ := s.Check(context.Background(), ss.last())
	hiddenDoc := ks.docs[0]
	*now = now.Add(GoneGrace + time.Hour)
	deleted, _ := s.Check(context.Background(), ss.last())
	docsAfterDelete := len(ks.docs)
	// ...and comes back later.
	pg.err = nil
	back, _ := s.Check(context.Background(), ss.last())

	// Assert
	if hidden != Hidden || hiddenDoc.ValidUntil.IsZero() || hiddenDoc.Status(*now) != knowledge.StatusExpired {
		t.Fatalf("hidden=%v doc=%+v", hidden, hiddenDoc)
	}
	if deleted != Deleted || docsAfterDelete != 0 {
		t.Fatalf("deleted=%v docs=%d", deleted, docsAfterDelete)
	}
	if back != Added || len(ks.docs) != 1 || !ks.docs[0].ValidUntil.IsZero() || ss.last().Status != "ok" {
		t.Fatalf("back=%v docs=%+v", back, ks.docs)
	}
}

func TestCheck_ErrorKeepsLastVersion(t *testing.T) {
	// Arrange
	s, ks, ss, pg, _, _ := env()
	pg.html = "<title>Price</title><p>3,900</p>"
	if _, err := s.Check(context.Background(), Source{ID: 1, AccountID: 1, URL: url}); err != nil {
		t.Fatal(err)
	}

	// Act
	pg.err = errors.New("dial tcp: i/o timeout")
	out, err := s.Check(context.Background(), ss.last())

	// Assert
	if out != Failed || err == nil || len(ks.docs) != 1 || !ks.docs[0].ValidUntil.IsZero() {
		t.Fatalf("out=%v docs=%+v", out, ks.docs)
	}
	if src := ss.last(); src.Status != "error" || src.Error != "could not reach the site" {
		t.Fatalf("source = %+v (internal error text must not be shown)", src)
	}
}

func TestCheck_EmptyPageIsAnError(t *testing.T) {
	// Arrange
	s, ks, ss, pg, _, _ := env()
	pg.html = "<html><body><script>app()</script><nav>menu</nav></body></html>"

	// Act
	out, _ := s.Check(context.Background(), Source{ID: 1, AccountID: 1, URL: url})

	// Assert
	if out != Failed || len(ks.docs) != 0 || ss.last().Error == "" {
		t.Fatalf("out=%v docs=%d src=%+v", out, len(ks.docs), ss.last())
	}
}

func TestCheck_DocumentDeletedByHandIsRestored(t *testing.T) {
	// Arrange
	s, ks, ss, pg, _, _ := env()
	pg.html = "<title>Price</title><p>3,900</p>"
	if _, err := s.Check(context.Background(), Source{ID: 1, AccountID: 1, URL: url}); err != nil {
		t.Fatal(err)
	}
	ks.docs = nil // the owner deleted the document

	// Act
	out, err := s.Check(context.Background(), ss.last())

	// Assert
	if err != nil || out != Added || len(ks.docs) != 1 {
		t.Fatalf("out=%v err=%v docs=%d", out, err, len(ks.docs))
	}
}

type panicFetch struct{}

func (panicFetch) Fetch(context.Context, string) (webfetch.Page, error) { panic("parser bug") }
func (panicFetch) FetchData(context.Context, string) (webfetch.Page, error) {
	panic("parser bug")
}

func TestCheckSafely_PanicBecomesFailedCheck(t *testing.T) {
	// Arrange
	s, _, ss, _, _, _ := env()
	s.Fetcher = panicFetch{}

	// Act
	out := s.checkSafely(context.Background(), Source{ID: 1, AccountID: 1, URL: url})

	// Assert
	if out != Failed || ss.last().Status != "error" {
		t.Fatalf("out=%v saved=%+v", out, ss.saved)
	}
}

func TestKick_DoesNotBlock(t *testing.T) {
	s, _, _, _, _, _ := env()
	s.Kick()
	s.Kick() // a second kick while one is pending is dropped, not blocking
}

func (s *kstore) ListByKeyPrefix(_ context.Context, acct int64, prefix string) ([]knowledge.Document, error) {
	var out []knowledge.Document
	for _, d := range s.docs {
		if (d.AccountID == acct || d.AccountID == 0) && d.SourceKey != "" && strings.HasPrefix(d.SourceKey, prefix) {
			out = append(out, d)
		}
	}
	return out, nil
}
