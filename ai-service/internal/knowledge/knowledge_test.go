package knowledge

import (
	"context"
	"errors"
	"strings"
	"testing"
	"time"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/embed"
)

type fakeEmbedder struct {
	model string
	calls [][]string
	err   error
}

func (f *fakeEmbedder) Model() string { return f.model }
func (f *fakeEmbedder) Embed(_ context.Context, texts []string) ([][]float32, error) {
	f.calls = append(f.calls, texts)
	if f.err != nil {
		return nil, f.err
	}
	out := make([][]float32, len(texts))
	for i := range texts {
		out[i] = []float32{float32(i)}
	}
	return out, nil
}

type fakeStore struct {
	docs     []Document
	inserted []Chunk
	insModel string
	replaced map[int64][]Chunk
	query    Query
	hits     []Hit
	updated  Document
	used     []int64
}

func (f *fakeStore) Insert(_ context.Context, d Document, model string, chunks []Chunk) (int64, error) {
	f.inserted, f.insModel = chunks, model
	return 42, nil
}
func (f *fakeStore) ReplaceChunks(_ context.Context, id int64, _ string, chunks []Chunk) error {
	if f.replaced == nil {
		f.replaced = map[int64][]Chunk{}
	}
	f.replaced[id] = chunks
	return nil
}
func (f *fakeStore) List(context.Context, int64, string) ([]Document, error) { return f.docs, nil }
func (f *fakeStore) Delete(context.Context, int64, int64) error              { return nil }
func (f *fakeStore) Search(_ context.Context, q Query) ([]Hit, error) {
	f.query = q
	return f.hits, nil
}

func (f *fakeStore) Get(_ context.Context, _, id int64) (Document, error) {
	for _, d := range f.docs {
		if d.ID == id {
			return d, nil
		}
	}
	return Document{}, ErrNotFound
}
func (f *fakeStore) Update(_ context.Context, d Document, _ string, chunks []Chunk) error {
	f.updated, f.inserted = d, chunks
	return nil
}
func (f *fakeStore) MarkUsed(_ context.Context, _ int64, ids []int64) error {
	f.used = append(f.used, ids...)
	return nil
}

func newService(st *fakeStore, em *fakeEmbedder) *Service {
	return &Service{Store: st, Embedder: em, TopK: 4, MinScore: 0.3, ChunkRunes: 800}
}

func TestValidate_ReportsEveryProblem(t *testing.T) {
	// Arrange
	d := Document{AccountID: 0, InboxID: -1, Kind: KindFAQ, Title: "  ", Content: ""}

	// Act
	_, err := d.Validate()

	// Assert
	for _, want := range []string{"account ID", "inbox ID", "Question is required", "content is required"} {
		if err == nil || !strings.Contains(err.Error(), want) {
			t.Errorf("error %v missing %q", err, want)
		}
	}
}

func TestAdd_FAQChunkCarriesQuestion(t *testing.T) {
	// Arrange
	st, em := &fakeStore{}, &fakeEmbedder{model: "m1"}
	svc := newService(st, em)

	// Act
	id, n, err := svc.Add(context.Background(), Document{
		AccountID: 1, Kind: KindFAQ, Title: " ร้านเปิดกี่โมง ", Content: "9:00–18:00 ทุกวัน\r\n",
	})

	// Assert
	if err != nil || id != 42 || n != 1 {
		t.Fatalf("id=%d n=%d err=%v", id, n, err)
	}
	if st.insModel != "m1" || st.inserted[0].Content != "Q: ร้านเปิดกี่โมง\nA: 9:00–18:00 ทุกวัน" {
		t.Errorf("model=%q chunk=%q", st.insModel, st.inserted[0].Content)
	}
}

func TestAdd_TextChunksCarryTitle(t *testing.T) {
	// Arrange
	st, em := &fakeStore{}, &fakeEmbedder{model: "m1"}
	svc := newService(st, em)
	svc.ChunkRunes = 150
	body := strings.Repeat("ย่อหน้าหนึ่ง ", 20) + "\n\n" + strings.Repeat("ย่อหน้าสอง ", 20)

	// Act
	_, n, err := svc.Add(context.Background(), Document{AccountID: 1, Kind: KindText, Title: "Shipping", Content: body})

	// Assert
	if err != nil || n < 2 {
		t.Fatalf("n=%d err=%v", n, err)
	}
	for _, c := range st.inserted {
		if !strings.HasPrefix(c.Content, "Shipping\n\n") {
			t.Errorf("chunk without title: %q", c.Content[:20])
		}
	}
}

func TestAdd_NoEmbedderFails(t *testing.T) {
	// Arrange
	svc := newService(&fakeStore{}, &fakeEmbedder{model: ""})

	// Act
	_, _, err := svc.Add(context.Background(), Document{AccountID: 1, Kind: KindText, Title: "t", Content: "c"})

	// Assert
	if !errors.Is(err, embed.ErrNotConfigured) {
		t.Errorf("err = %v", err)
	}
}

func TestRetrieve_DropsWeakHitsAndScopesQuery(t *testing.T) {
	// Arrange
	st := &fakeStore{hits: []Hit{{ChunkID: 1, Score: 0.8}, {ChunkID: 2, Score: 0.31}, {ChunkID: 3, Score: 0.2}}}
	svc := newService(st, &fakeEmbedder{model: "m1"})

	// Act
	hits, err := svc.Retrieve(context.Background(), 7, 3, "  ค่าส่งเท่าไหร่  ")

	// Assert
	if err != nil || len(hits) != 2 || hits[1].ChunkID != 2 {
		t.Fatalf("hits=%+v err=%v", hits, err)
	}
	if st.query.AccountID != 7 || st.query.InboxID != 3 || st.query.Model != "m1" || st.query.Limit != 4 {
		t.Errorf("query = %+v", st.query)
	}
}

func TestRetrieve_EmptyQueryOrNoEmbedderSkipsSearch(t *testing.T) {
	// Arrange
	em := &fakeEmbedder{model: "m1"}
	svc := newService(&fakeStore{}, em)
	off := newService(&fakeStore{}, &fakeEmbedder{})

	// Act
	h1, err1 := svc.Retrieve(context.Background(), 1, 0, "  ")
	h2, err2 := off.Retrieve(context.Background(), 1, 0, "hello")

	// Assert
	if h1 != nil || err1 != nil || h2 != nil || err2 != nil || len(em.calls) != 0 {
		t.Errorf("h1=%v err1=%v h2=%v err2=%v calls=%d", h1, err1, h2, err2, len(em.calls))
	}
}

func TestReindex_OnlyStaleUnlessForced(t *testing.T) {
	// Arrange
	st := &fakeStore{docs: []Document{
		{ID: 1, AccountID: 1, Kind: KindText, Title: "fresh", Content: "a", Chunks: 1},
		{ID: 2, AccountID: 1, Kind: KindText, Title: "stale", Content: "b", Chunks: 1, StaleChunks: 1},
		{ID: 3, AccountID: 1, Kind: KindText, Title: "empty", Content: "c"},
	}}
	svc := newService(st, &fakeEmbedder{model: "m2"})

	// Act
	n, err := svc.Reindex(context.Background(), 1, false)
	all, errAll := svc.Reindex(context.Background(), 1, true)

	// Assert
	if err != nil || n != 2 {
		t.Fatalf("n=%d err=%v, want 2 (stale + never indexed)", n, err)
	}
	if errAll != nil || all != 3 {
		t.Errorf("forced: n=%d err=%v", all, errAll)
	}
}

func TestAdd_MarkdownSectionsBecomeSeparateChunks(t *testing.T) {
	// Arrange
	st := &fakeStore{}
	svc := newService(st, &fakeEmbedder{model: "m1"})
	body := "# Menu\n\n## Coffee\nlatte 70\n\n## Tea\nthai tea 60"

	// Act
	_, n, err := svc.Add(context.Background(), Document{AccountID: 1, Kind: KindText, Title: "Menu", Content: body})

	// Assert
	if err != nil || n != 2 {
		t.Fatalf("n=%d err=%v", n, err)
	}
	if st.inserted[0].Content != "Menu — Coffee\n\nlatte 70" || st.inserted[1].Content != "Menu — Tea\n\nthai tea 60" {
		t.Errorf("chunks = %q / %q", st.inserted[0].Content, st.inserted[1].Content)
	}
}

// byQuery returns hits chosen by the query vector's first value.
type byQueryStore struct {
	fakeStore
	perQuery map[float32][]Hit
}

func (b *byQueryStore) Search(_ context.Context, q Query) ([]Hit, error) {
	return b.perQuery[q.Vector[0]], nil
}

func TestRetrieve_SeveralQueriesMergeByBestScore(t *testing.T) {
	// Arrange: query 0 (current message) finds the payment FAQ; query 1
	// (previous + current) is dominated by the menu document.
	st := &byQueryStore{perQuery: map[float32][]Hit{
		0: {{ChunkID: 7, Title: "payment", Score: 0.45}, {ChunkID: 1, Title: "menu", Score: 0.31}},
		1: {{ChunkID: 1, Title: "menu", Score: 0.6}, {ChunkID: 2, Title: "menu", Score: 0.5}, {ChunkID: 3, Title: "menu", Score: 0.4}},
	}}
	em := &fakeEmbedder{model: "m1"}
	svc := &Service{Store: st, Embedder: em, TopK: 3, MinScore: 0.3}

	// Act
	hits, err := svc.Retrieve(context.Background(), 1, 0, "current", "previous\ncurrent", " ")

	// Assert
	if err != nil {
		t.Fatal(err)
	}
	if len(em.calls) != 1 || len(em.calls[0]) != 2 {
		t.Errorf("want one embed call with 2 inputs, got %v", em.calls)
	}
	ids := []int64{}
	for _, h := range hits {
		ids = append(ids, h.ChunkID)
	}
	if len(ids) != 3 || ids[0] != 1 || ids[1] != 2 || ids[2] != 7 || hits[0].Score != 0.6 {
		t.Errorf("merged = %v (%+v)", ids, hits)
	}
}

func TestRetrieve_EveryQueryKeepsItsBestHit(t *testing.T) {
	// Arrange: the context query (previous + current) scores three overview
	// chunks above the current message's only real answer (system requirements).
	st := &byQueryStore{perQuery: map[float32][]Hit{
		0: {{ChunkID: 9, Title: "requirements", Score: 0.43}},
		1: {{ChunkID: 1, Title: "overview", Score: 0.67}, {ChunkID: 2, Title: "overview", Score: 0.6}, {ChunkID: 3, Title: "overview", Score: 0.55}},
	}}
	svc := &Service{Store: st, Embedder: &fakeEmbedder{model: "m1"}, TopK: 3, MinScore: 0.3}

	// Act
	hits, err := svc.Retrieve(context.Background(), 1, 0, "does it run on Windows?", "is there AutoCut?\ndoes it run on Windows?")

	// Assert
	if err != nil {
		t.Fatal(err)
	}
	var ids []int64
	for _, h := range hits {
		ids = append(ids, h.ChunkID)
	}
	if len(ids) != 3 || ids[0] != 1 || ids[1] != 2 || ids[2] != 9 {
		t.Errorf("hits = %v, want [1 2 9]: the current message's best hit must survive, sorted by score", ids)
	}
}

func TestStatus_FollowsValidityWindow(t *testing.T) {
	now := time.Date(2026, 11, 7, 12, 0, 0, 0, time.UTC)
	cases := map[string]struct {
		d    Document
		want string
	}{
		"open":           {Document{}, StatusActive},
		"inside":         {Document{ValidFrom: now.Add(-time.Hour), ValidUntil: now.Add(time.Hour)}, StatusActive},
		"not started":    {Document{ValidFrom: now.Add(time.Minute)}, StatusScheduled},
		"ended":          {Document{ValidUntil: now.Add(-time.Minute)}, StatusExpired},
		"ends right now": {Document{ValidUntil: now}, StatusExpired},
	}
	for name, c := range cases {
		// Act
		got := c.d.Status(now)

		// Assert
		if got != c.want {
			t.Errorf("%s: status = %q, want %q", name, got, c.want)
		}
	}
}

func TestValidate_EndBeforeStart(t *testing.T) {
	// Arrange
	day := time.Date(2026, 12, 1, 0, 0, 0, 0, time.UTC)
	d := Document{AccountID: 1, Kind: KindFAQ, Title: "q", Content: "a", ValidFrom: day, ValidUntil: day}

	// Act
	_, err := d.Validate()

	// Assert
	if err == nil || !strings.Contains(err.Error(), "end date must be after the start date") {
		t.Fatalf("err = %v", err)
	}
}

func TestUpdate_ReembedsAndStores(t *testing.T) {
	// Arrange
	st := &fakeStore{}
	s := newService(st, &fakeEmbedder{model: "m"})
	d := Document{ID: 9, AccountID: 1, Kind: KindFAQ, Title: " ราคา ", Content: "3,900 บาท"}

	// Act
	n, err := s.Update(context.Background(), d)

	// Assert
	if err != nil || n != 1 || st.updated.ID != 9 || st.updated.Title != "ราคา" || len(st.inserted) != 1 {
		t.Fatalf("n=%d err=%v updated=%+v", n, err, st.updated)
	}
}

func TestUpdate_RejectsMissingIDAndBadInput(t *testing.T) {
	// Arrange
	st := &fakeStore{}
	s := newService(st, &fakeEmbedder{model: "m"})

	// Act
	_, noID := s.Update(context.Background(), Document{AccountID: 1, Kind: KindFAQ, Title: "q", Content: "a"})
	_, bad := s.Update(context.Background(), Document{ID: 3, AccountID: 1, Kind: KindFAQ, Title: "", Content: "a"})

	// Assert
	if !errors.Is(noID, ErrNotFound) || bad == nil || st.updated.ID != 0 {
		t.Fatalf("noID=%v bad=%v updated=%+v", noID, bad, st.updated)
	}
}

func TestSimilar_OnePerDocumentAboveThresholdIncludingInactive(t *testing.T) {
	// Arrange
	st := &fakeStore{hits: []Hit{
		{ChunkID: 1, DocumentID: 5, Title: "Price", Score: 0.93},
		{ChunkID: 2, DocumentID: 5, Title: "Price", Score: 0.90},
		{ChunkID: 3, DocumentID: 7, Title: "Self", Score: 0.99},
		{ChunkID: 4, DocumentID: 8, Title: "Loose", Score: 0.60},
	}}
	s := newService(st, &fakeEmbedder{model: "m"})

	// Act
	got, err := s.Similar(context.Background(), Document{ID: 7, AccountID: 1, Kind: KindFAQ, Title: "ราคา", Content: "3,900"})

	// Assert
	if err != nil || len(got) != 1 || got[0].DocumentID != 5 {
		t.Fatalf("got=%+v err=%v", got, err)
	}
	if !st.query.IncludeInactive || st.query.AccountID != 1 {
		t.Fatalf("query = %+v", st.query)
	}
}

func TestMarkUsed_CountsEachDocumentOnce(t *testing.T) {
	// Arrange
	st := &fakeStore{}
	s := newService(st, &fakeEmbedder{model: "m"})

	// Act
	err := s.MarkUsed(context.Background(), 1, []Hit{{DocumentID: 5}, {DocumentID: 5}, {DocumentID: 6}})

	// Assert
	if err != nil || len(st.used) != 2 {
		t.Fatalf("used=%v err=%v", st.used, err)
	}
}
