// Package knowledge is the knowledge base the bot answers from (RAG):
// documents are split into chunks, embedded, stored in Postgres (pgvector),
// and searched per Chatwoot account and inbox.
package knowledge

import (
	"context"
	"errors"
	"fmt"
	"sort"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/embed"
)

// Kind is the type of a knowledge document.
type Kind string

// Document kinds.
const (
	KindFAQ  Kind = "faq"  // Title is the question, Content the answer
	KindText Kind = "text" // free text or Markdown
)

// Limits for what an admin can add.
const (
	MaxTitleRunes   = 300
	MaxContentRunes = 200_000
)

// Document is one knowledge item. InboxID 0 means "all inboxes of the account".
type Document struct {
	ID        int64
	AccountID int64
	InboxID   int64
	Kind      Kind
	Title     string
	Content   string
	UpdatedAt time.Time
	// SourceKey is the document's ID in an outside source (MCP, a sheet row,
	// a doc, a URL), unique per account; empty for documents added by hand.
	SourceKey string

	// Optional validity window: zero means open-ended. Outside it the bot
	// does not see the document.
	ValidFrom, ValidUntil time.Time

	// Usage: how often customer questions retrieved this document.
	UseCount   int64
	LastUsedAt time.Time

	// Filled by List.
	Chunks      int
	StaleChunks int // embedded with a different model than the current one
}

// Document states for the admin list.
const (
	StatusActive    = "active"
	StatusScheduled = "scheduled"
	StatusExpired   = "expired"
)

// Status says whether the bot can use the document at now.
func (d Document) Status(now time.Time) string {
	switch {
	case !d.ValidUntil.IsZero() && !now.Before(d.ValidUntil):
		return StatusExpired
	case !d.ValidFrom.IsZero() && now.Before(d.ValidFrom):
		return StatusScheduled
	}
	return StatusActive
}

// Chunk is one embedded piece of a document.
type Chunk struct {
	Ord       int
	Content   string
	Embedding []float32
}

// Hit is a chunk returned by a search, with cosine similarity in [−1, 1].
type Hit struct {
	ChunkID    int64
	DocumentID int64
	Title      string
	Content    string
	Score      float64
}

// Query is a vector search inside one account (and inbox).
type Query struct {
	AccountID int64
	InboxID   int64
	Model     string
	Vector    []float32
	Limit     int
	// IncludeInactive also searches scheduled and expired documents (the
	// duplicate check); the bot never sets it.
	IncludeInactive bool
}

// Store persists documents and chunks.
type Store interface {
	Insert(ctx context.Context, d Document, model string, chunks []Chunk) (int64, error)
	ReplaceChunks(ctx context.Context, d Document, model string, chunks []Chunk) error
	List(ctx context.Context, accountID int64, model string) ([]Document, error)
	Delete(ctx context.Context, accountID, id int64) error
	Search(ctx context.Context, q Query) ([]Hit, error)
	Get(ctx context.Context, accountID, id int64) (Document, error)
	Update(ctx context.Context, d Document, model string, chunks []Chunk) error
	MarkUsed(ctx context.Context, accountID int64, documentIDs []int64) error
	GetByKey(ctx context.Context, accountID int64, key string) (Document, error)
}

// MaxKeyRunes bounds a source key (long enough for a URL).
const MaxKeyRunes = 500

// DuplicateScore is the similarity above which a new document is reported
// as probably repeating an existing one.
const DuplicateScore = 0.85

// ErrNotFound means no document matched.
var ErrNotFound = errors.New("document not found")

// ErrChanged means the document was edited after it was read; the write was skipped.
var ErrChanged = errors.New("document changed since it was read")

// Service adds, re-indexes and searches knowledge.
type Service struct {
	Store      Store
	Embedder   embed.Embedder
	TopK       int     // hits returned by Retrieve
	MinScore   float64 // hits below this similarity are dropped
	ChunkRunes int     // max runes per chunk
}

// Validate checks a document an admin wants to add and trims it.
func (d Document) Validate() (Document, error) {
	d.Title = strings.TrimSpace(d.Title)
	d.Content = strings.TrimSpace(strings.ReplaceAll(d.Content, "\r\n", "\n"))
	var errs []error
	if d.AccountID < 1 {
		errs = append(errs, errors.New("account ID must be a positive number"))
	}
	if d.InboxID < 0 {
		errs = append(errs, errors.New("inbox ID must be blank or a positive number"))
	}
	if d.Kind != KindFAQ && d.Kind != KindText {
		errs = append(errs, errors.New("unknown document kind"))
	}
	label := "Title"
	if d.Kind == KindFAQ {
		label = "Question"
	}
	switch n := utf8.RuneCountInString(d.Title); {
	case n == 0:
		errs = append(errs, fmt.Errorf("%s is required", label))
	case n > MaxTitleRunes:
		errs = append(errs, fmt.Errorf("%s is longer than %d characters", label, MaxTitleRunes))
	}
	switch n := utf8.RuneCountInString(d.Content); {
	case n == 0:
		errs = append(errs, errors.New("content is required"))
	case n > MaxContentRunes:
		errs = append(errs, fmt.Errorf("content is longer than %d characters; split it into several documents", MaxContentRunes))
	case !utf8.ValidString(d.Content):
		errs = append(errs, errors.New("content must be UTF-8 text"))
	}
	d.SourceKey = strings.TrimSpace(d.SourceKey)
	if n := utf8.RuneCountInString(d.SourceKey); n > MaxKeyRunes || strings.ContainsAny(d.SourceKey, " \t\r\n") {
		errs = append(errs, fmt.Errorf("source key must be at most %d characters with no spaces", MaxKeyRunes))
	}
	if !d.ValidFrom.IsZero() && !d.ValidUntil.IsZero() && !d.ValidUntil.After(d.ValidFrom) {
		errs = append(errs, errors.New("the end date must be after the start date"))
	}
	return d, errors.Join(errs...)
}

// chunkTexts builds what gets embedded. Every chunk carries the document
// title (or the FAQ question), plus its Markdown section heading, so a chunk
// makes sense on its own.
func (s *Service) chunkTexts(d Document) []string {
	if d.Kind == KindFAQ {
		return s.withPrefix("Q: "+d.Title+"\nA: ", d.Content)
	}
	var out []string
	for _, sec := range Sections(d.Content) {
		prefix := d.Title
		if sec.Heading != "" && sec.Heading != d.Title {
			prefix += " — " + sec.Heading
		}
		out = append(out, s.withPrefix(prefix+"\n\n", sec.Body)...)
	}
	return out
}

func (s *Service) withPrefix(prefix, body string) []string {
	size := max(s.ChunkRunes-utf8.RuneCountInString(prefix), 100)
	var out []string
	for _, part := range Split(body, size) {
		out = append(out, prefix+part)
	}
	return out
}

func (s *Service) embedChunks(ctx context.Context, d Document) (string, []Chunk, error) {
	model := s.Embedder.Model()
	if model == "" {
		return "", nil, embed.ErrNotConfigured
	}
	texts := s.chunkTexts(d)
	vecs, err := s.Embedder.Embed(ctx, texts)
	if err != nil {
		return "", nil, err
	}
	chunks := make([]Chunk, len(texts))
	for i, t := range texts {
		chunks[i] = Chunk{Ord: i, Content: t, Embedding: vecs[i]}
	}
	return model, chunks, nil
}

// Add validates, chunks, embeds and stores a document. Returns its ID.
func (s *Service) Add(ctx context.Context, d Document) (int64, int, error) {
	d, err := d.Validate()
	if err != nil {
		return 0, 0, err
	}
	model, chunks, err := s.embedChunks(ctx, d)
	if err != nil {
		return 0, 0, err
	}
	id, err := s.Store.Insert(ctx, d, model, chunks)
	return id, len(chunks), err
}

// Get returns one document of the account.
func (s *Service) Get(ctx context.Context, accountID, id int64) (Document, error) {
	return s.Store.Get(ctx, accountID, id)
}

// Update validates, re-chunks and re-embeds an edited document and replaces
// it in place. Returns the new chunk count.
func (s *Service) Update(ctx context.Context, d Document) (int, error) {
	if d.ID < 1 {
		return 0, ErrNotFound
	}
	d, err := d.Validate()
	if err != nil {
		return 0, err
	}
	model, chunks, err := s.embedChunks(ctx, d)
	if err != nil {
		return 0, err
	}
	return len(chunks), s.Store.Update(ctx, d, model, chunks)
}

// GetByKey returns the account's document with this source key.
func (s *Service) GetByKey(ctx context.Context, accountID int64, key string) (Document, error) {
	return s.Store.GetByKey(ctx, accountID, strings.TrimSpace(key))
}

// Upsert stores d by its source key: an existing document with that key is
// replaced in place (re-chunked, usage kept), otherwise d is added. Returns
// the stored document as it was before (zero when created), its ID and the
// chunk count.
func (s *Service) Upsert(ctx context.Context, d Document) (before Document, id int64, chunks int, err error) {
	d, err = d.Validate()
	if err != nil {
		return Document{}, 0, 0, err
	}
	if d.SourceKey == "" {
		return Document{}, 0, 0, errors.New("source key is required")
	}
	cur, err := s.Store.GetByKey(ctx, d.AccountID, d.SourceKey)
	switch {
	case errors.Is(err, ErrNotFound):
		id, chunks, err = s.Add(ctx, d)
		return Document{}, id, chunks, err
	case err != nil:
		return Document{}, 0, 0, err
	}
	d.ID, d.Kind = cur.ID, cur.Kind
	chunks, err = s.Update(ctx, d)
	return cur, cur.ID, chunks, err
}

// Similar returns existing documents (active or not) that probably say the
// same thing as d: one hit per document, best first, d itself excluded.
func (s *Service) Similar(ctx context.Context, d Document) ([]Hit, error) {
	d, err := d.Validate()
	if err != nil {
		return nil, err
	}
	model := s.Embedder.Model()
	texts := s.chunkTexts(d)
	if model == "" || len(texts) == 0 {
		return nil, nil
	}
	vecs, err := s.Embedder.Embed(ctx, texts[:1])
	if err != nil {
		return nil, err
	}
	hits, err := s.Store.Search(ctx, Query{AccountID: d.AccountID, InboxID: d.InboxID, Model: model,
		Vector: vecs[0], Limit: 8, IncludeInactive: true})
	if err != nil {
		return nil, err
	}
	var out []Hit
	seen := map[int64]bool{d.ID: d.ID != 0}
	for _, h := range hits {
		if h.Score >= DuplicateScore && !seen[h.DocumentID] {
			seen[h.DocumentID] = true
			out = append(out, h)
		}
	}
	return out, nil
}

// MarkUsed counts one use for each distinct document behind hits.
func (s *Service) MarkUsed(ctx context.Context, accountID int64, hits []Hit) error {
	var ids []int64
	seen := map[int64]bool{}
	for _, h := range hits {
		if !seen[h.DocumentID] {
			seen[h.DocumentID] = true
			ids = append(ids, h.DocumentID)
		}
	}
	return s.Store.MarkUsed(ctx, accountID, ids)
}

// List returns an account's documents with chunk counts.
func (s *Service) List(ctx context.Context, accountID int64) ([]Document, error) {
	return s.Store.List(ctx, accountID, s.Embedder.Model())
}

// Delete removes a document and its chunks.
func (s *Service) Delete(ctx context.Context, accountID, id int64) error {
	return s.Store.Delete(ctx, accountID, id)
}

// Reindex re-embeds every document of the account whose chunks were made
// with another model (or all of them when force is set). Returns how many
// documents were re-indexed.
func (s *Service) Reindex(ctx context.Context, accountID int64, force bool) (int, error) {
	docs, err := s.List(ctx, accountID)
	if err != nil {
		return 0, err
	}
	n := 0
	for _, d := range docs {
		if !force && d.StaleChunks == 0 && d.Chunks > 0 {
			continue
		}
		model, chunks, err := s.embedChunks(ctx, d)
		if err != nil {
			return n, fmt.Errorf("re-index %q: %w", d.Title, err)
		}
		switch err := s.Store.ReplaceChunks(ctx, d, model, chunks); {
		case errors.Is(err, ErrChanged), errors.Is(err, ErrNotFound):
			continue // edited (already re-embedded) or deleted meanwhile
		case err != nil:
			return n, err
		}
		n++
	}
	return n, nil
}

// Retrieve finds the chunks most similar to any of the queries in the
// account, limited to the inbox's documents plus account-wide ones. Weak
// matches are dropped. The TopK slots are filled round-robin by rank (each
// query's best hit, then each query's second best, ...), so a query whose
// matches all score higher (often the one carrying earlier context) cannot
// crowd out another query's answer. The result is sorted by best score.
func (s *Service) Retrieve(ctx context.Context, accountID, inboxID int64, queries ...string) ([]Hit, error) {
	model := s.Embedder.Model()
	queries = cleanQueries(queries)
	if len(queries) == 0 || model == "" {
		return nil, nil
	}
	vecs, err := s.Embedder.Embed(ctx, queries)
	if err != nil {
		return nil, err
	}
	best := map[int64]Hit{}
	perQuery := make([][]Hit, 0, len(vecs))
	for _, v := range vecs {
		hits, err := s.Store.Search(ctx, Query{
			AccountID: accountID, InboxID: inboxID, Model: model, Vector: v, Limit: s.TopK,
		})
		if err != nil {
			return nil, err
		}
		var kept []Hit
		for _, h := range hits {
			if h.Score < s.MinScore {
				continue
			}
			kept = append(kept, h)
			if prev, seen := best[h.ChunkID]; !seen || h.Score > prev.Score {
				best[h.ChunkID] = h
			}
		}
		sort.SliceStable(kept, func(i, j int) bool { return kept[i].Score > kept[j].Score })
		perQuery = append(perQuery, kept)
	}
	out := roundRobin(perQuery, best, s.TopK)
	sort.SliceStable(out, func(i, j int) bool { return out[i].Score > out[j].Score })
	return out, nil
}

// roundRobin takes rank 1 of every query, then rank 2, ... until limit
// distinct chunks are chosen; each chunk carries its best score.
func roundRobin(perQuery [][]Hit, best map[int64]Hit, limit int) []Hit {
	var out []Hit
	chosen := map[int64]bool{}
	for rank := 0; len(out) < limit; rank++ {
		more := false
		for _, hits := range perQuery {
			if rank >= len(hits) || len(out) >= limit {
				continue
			}
			more = true
			if id := hits[rank].ChunkID; !chosen[id] {
				chosen[id] = true
				out = append(out, best[id])
			}
		}
		if !more {
			break
		}
	}
	return out
}

func cleanQueries(in []string) []string {
	var out []string
	seen := map[string]bool{}
	for _, q := range in {
		q = strings.TrimSpace(q)
		if q != "" && !seen[q] {
			seen[q] = true
			out = append(out, q)
		}
	}
	return out
}
