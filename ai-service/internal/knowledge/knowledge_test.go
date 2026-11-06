package knowledge

import (
	"context"
	"errors"
	"strings"
	"testing"

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
