package answereval

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"strings"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/knowledge"
)

// SeedKeyPrefix marks documents that Seed added, so a later seed may update
// them and nothing else.
const SeedKeyPrefix = "answer-eval-seed-"

// SeedStore is the part of knowledge.Service that Seed needs.
type SeedStore interface {
	List(ctx context.Context, accountID int64) ([]knowledge.Document, error)
	Upsert(ctx context.Context, d knowledge.Document) (knowledge.Document, int64, int, error)
}

type seedFAQ struct {
	Question string `json:"question"`
	Answer   string `json:"answer"`
}

// Seed loads a JSON list of {"question","answer"} FAQs into an account of a
// throwaway database, for CI. It refuses an account that holds any document
// it did not add itself, so it can never mix test data into real knowledge.
// It returns how many FAQs it loaded.
func Seed(ctx context.Context, kb SeedStore, accountID int64, path string) (int, error) {
	faqs, err := readFAQs(path)
	if err != nil {
		return 0, err
	}
	existing, err := kb.List(ctx, accountID)
	if err != nil {
		return 0, err
	}
	for _, d := range existing {
		if !strings.HasPrefix(d.SourceKey, SeedKeyPrefix) {
			return 0, fmt.Errorf("account %d already has knowledge (%q); seed only an empty test database", accountID, d.Title)
		}
	}
	for i, f := range faqs {
		d := knowledge.Document{AccountID: accountID, Kind: knowledge.KindFAQ, Title: f.Question, Content: f.Answer,
			SourceKey: fmt.Sprintf("%s%03d", SeedKeyPrefix, i+1)}
		if _, _, _, err := kb.Upsert(ctx, d); err != nil {
			return i, fmt.Errorf("seed FAQ %d: %w", i+1, err)
		}
	}
	return len(faqs), nil
}

func readFAQs(path string) ([]seedFAQ, error) {
	raw, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	var faqs []seedFAQ
	if err := json.Unmarshal(raw, &faqs); err != nil {
		return nil, fmt.Errorf("parse %s: %w", path, err)
	}
	if len(faqs) == 0 {
		return nil, errors.New(path + ": no FAQs")
	}
	for i, f := range faqs {
		if strings.TrimSpace(f.Question) == "" || strings.TrimSpace(f.Answer) == "" {
			return nil, fmt.Errorf("%s: FAQ %d needs a question and an answer", path, i+1)
		}
	}
	return faqs, nil
}
