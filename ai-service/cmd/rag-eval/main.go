// Command rag-eval measures knowledge base retrieval against a set of test
// questions, using the same database, embeddings provider and thresholds as
// ai-service. Run it inside the ai-service container:
//
//	docker compose exec ai-service /rag-eval -cases /data/eval.json
//
// The cases file is a JSON array of {"question", "account_id", "inbox_id", "expect"};
// "expect" is part of the expected document's title, or "" when the bot
// should find nothing and hand off.
package main

import (
	"context"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"os"
	"time"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/config"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/knowledge"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/settings"
)

func main() {
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, "rag-eval:", err)
		os.Exit(1)
	}
}

func run() error {
	casesPath := flag.String("cases", "/data/eval.json", "JSON file with test questions")
	topK := flag.Int("k", 0, "hits per question (default RAG_TOP_K)")
	minScore := flag.Float64("min-score", -2, "similarity threshold (default RAG_MIN_SCORE)")
	minFound := flag.Float64("min-found", 0, "exit 1 if the answerable found rate (0-1) is below this")
	flag.Parse()

	cfg, err := config.FromEnv()
	if err != nil {
		return err
	}
	if cfg.DatabaseURL == "" {
		return errors.New("DATABASE_URL is not set")
	}
	raw, err := os.ReadFile(*casesPath)
	if err != nil {
		return err
	}
	var cases []knowledge.EvalCase
	if err := json.Unmarshal(raw, &cases); err != nil {
		return fmt.Errorf("parse %s: %w", *casesPath, err)
	}

	store, err := settings.Open(cfg.SettingsPath, settings.Defaults(cfg))
	if err != nil {
		return err
	}
	embedder := settings.NewEmbedder(store.Get(), cfg.LLMTimeout)
	if embedder == nil {
		return errors.New("no embeddings provider configured (set it on /admin)")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Minute)
	defer cancel()
	pg, err := knowledge.OpenPostgres(ctx, cfg.DatabaseURL)
	if err != nil {
		return err
	}
	defer pg.Pool.Close()

	svc := &knowledge.Service{Store: pg, Embedder: embedder, TopK: cfg.RAGTopK, MinScore: cfg.RAGMinScore, ChunkRunes: cfg.RAGChunkRunes}
	if *topK > 0 {
		svc.TopK = *topK
	}
	if *minScore >= -1 {
		svc.MinScore = *minScore
	}
	fmt.Printf("model %s · top %d · min score %.2f · %d cases\n\n", embedder.Model(), svc.TopK, svc.MinScore, len(cases))

	rep := knowledge.Evaluate(ctx, svc.Retrieve, cases)
	rep.Write(os.Stdout)
	if rep.Answerable > 0 && float64(rep.Found)/float64(rep.Answerable) < *minFound {
		return fmt.Errorf("found rate below %.2f", *minFound)
	}
	return nil
}
