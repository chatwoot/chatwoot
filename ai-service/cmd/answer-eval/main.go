// Command answer-eval grades the bot's real replies to test conversations,
// using the same database, knowledge base, business profiles, query rewrite
// and chat model as ai-service. It sends nothing to Chatwoot. Run it inside
// the ai-service container:
//
//	docker compose exec ai-service /answer-eval -cases /data/answers.json
//
// The cases file is a JSON array of answereval.Case. Each case costs about
// two chat-model calls per turn (rewrite + reply) plus one judge call; a
// voice note in "files" adds a transcription. Files are read from the
// cases file's folder.
package main

import (
	"context"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
	"log/slog"
	"os"
	"path/filepath"
	"time"
	_ "time/tzdata" // the distroless image has no zoneinfo; TIMEZONE needs it

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/answereval"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/bot"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/config"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/handoff"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/knowledge"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/llm"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/memory"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/profile"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/settings"
)

func main() {
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, "answer-eval:", err)
		os.Exit(1)
	}
}

func run() error {
	casesPath := flag.String("cases", "/data/answers.json", "JSON file with test conversations")
	judgeModel := flag.String("judge-model", "", "model for the judge on the primary provider (default: the bot's model)")
	noRewrite := flag.Bool("no-rewrite", false, "search without the Thai/English query rewrite (to compare)")
	minPass := flag.Float64("min-pass", 0, "exit 1 if the pass rate (0-1) is below this")
	verbose := flag.Bool("v", false, "print every reply, not only failing ones")
	jsonOut := flag.String("json", "", "also write every full reply and verdict to this JSON file")
	rewriteModel := flag.String("rewrite-model", "\x00", "model for the query rewrite (default REWRITE_MODEL, else the bot's model)")
	strictFaithful := flag.Bool("strict-faithful", false, "exit 1 if any reply invents facts (judge: not faithful)")
	seedKB := flag.String("seed-kb", "", "first load this JSON list of {question, answer} FAQs into -seed-account (empty test databases only, for CI)")
	seedAccount := flag.Int64("seed-account", 1, "account that -seed-kb loads into")
	flag.Parse()

	cfg, err := config.FromEnv()
	if err != nil {
		return err
	}
	if cfg.DatabaseURL == "" {
		return errors.New("DATABASE_URL is not set")
	}
	cases, err := readCases(*casesPath)
	if err != nil {
		return err
	}

	store, err := settings.Open(cfg.SettingsPath, settings.Defaults(cfg))
	if err != nil {
		return err
	}
	current := store.Get()
	quiet := slog.New(slog.NewJSONHandler(io.Discard, nil))
	chat := settings.NewCompleter(current, cfg.LLMTimeout, quiet)
	embedder := settings.NewEmbedder(current, cfg.LLMTimeout)
	if chat == nil || embedder == nil {
		return errors.New("chat or embeddings provider not configured (set them on /admin)")
	}
	judgeSettings := current
	judgeSettings.Fallback = settings.Provider{}
	if *judgeModel != "" {
		judgeSettings.Primary.Model = *judgeModel
	}
	judge := settings.NewCompleter(judgeSettings, cfg.LLMTimeout, quiet)
	// The judge stays on one model, but when the primary answers 429 (rate
	// limit or no credit left) it grades with the backup provider instead
	// of failing every case. The report says how often that happened.
	var judgeBackup llm.Completer
	judgeBackupLabel := "none"
	if current.Fallback.Configured() {
		judgeBackup = settings.NewCompleter(settings.LLM{Primary: current.Fallback}, cfg.LLMTimeout, quiet)
		judgeBackupLabel = current.Fallback.Model
	}
	backupVerdicts := new(answereval.BackupCounter)

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Minute)
	defer cancel()
	pg, err := knowledge.OpenPostgres(ctx, cfg.DatabaseURL)
	if err != nil {
		return err
	}
	defer pg.Pool.Close()
	profiles := &profile.Postgres{Pool: pg.Pool}
	kb := &knowledge.Service{Store: pg, Embedder: embedder, TopK: cfg.RAGTopK, MinScore: cfg.RAGMinScore, ChunkRunes: cfg.RAGChunkRunes}
	if *seedKB != "" {
		n, err := answereval.Seed(ctx, kb, *seedAccount, *seedKB)
		if err != nil {
			return err
		}
		fmt.Printf("seeded %d FAQs into account %d\n", n, *seedAccount)
	}

	opts := bot.Options{
		LLM:            chat,
		Knowledge:      kb,
		Profiles:       profiles,
		History:        memory.NewHistory(cfg.HistoryLimit, time.Hour, nil),
		SystemPrompt:   cfg.SystemPrompt,
		HandoffMessage: cfg.HandoffMessage,
		Location:       cfg.Location,
		Logger:         quiet,
	}
	// A case may set the bot's clock (promotions that ended, deadlines).
	var caseNow time.Time
	opts.Now = func() time.Time {
		if caseNow.IsZero() {
			return time.Now()
		}
		return caseNow
	}
	if *rewriteModel == "\x00" {
		*rewriteModel = cfg.RewriteModel
	}
	rewriteSettings := settings.RewriteSettings(current, *rewriteModel)
	if !*noRewrite {
		opts.Rewriter = &bot.LLMRewriter{LLM: settings.NewCompleter(rewriteSettings, cfg.LLMTimeout, quiet)}
	}
	b := bot.New(opts, 1, 1)

	rewriteLabel := "off"
	if !*noRewrite {
		rewriteLabel = rewriteSettings.Primary.Model
	}
	fmt.Printf("model %s · judge %s (backup on 429: %s) · rewrite %s · %d cases\n\n",
		current.Primary.Model, judgeSettings.Primary.Model, judgeBackupLabel, rewriteLabel, len(cases))
	started := time.Now()
	rep := answereval.Run(ctx, answereval.Runner{
		Answerer: b,
		Media:    b,
		Handoff:  handoff.New(cfg.HandoffKeywords),
		Judge:    answereval.LLMJudge{LLM: judge, Backup: judgeBackup, BackupUsed: backupVerdicts},
		Split:    bot.SplitHandoff,
		SetNow:   func(t time.Time) { caseNow = t },
		Profile: func(ctx context.Context, acct int64) string {
			p, err := profiles.Get(ctx, acct)
			if err != nil {
				return ""
			}
			return profile.Prompt("", p)
		},
	}, cases)
	rep.Verbose = *verbose
	if *jsonOut != "" {
		if err := writeJSON(*jsonOut, rep); err != nil {
			return err
		}
	}
	rep.Write(os.Stdout)
	elapsed := time.Since(started)
	fmt.Printf("Took %s (%.1fs per case)\n", elapsed.Round(time.Second), elapsed.Seconds()/float64(max(len(cases), 1)))
	if n := backupVerdicts.Load(); n > 0 {
		fmt.Printf("Judge: the primary was rate-limited (429); %d of %d verdicts came from the backup judge %s\n",
			n, len(rep.Results), judgeBackupLabel)
	}
	if len(rep.Results) > 0 && float64(rep.Passed)/float64(len(rep.Results)) < *minPass {
		return fmt.Errorf("pass rate below %.2f", *minPass)
	}
	if n := rep.Unfaithful(); *strictFaithful && n > 0 {
		return fmt.Errorf("%d replies invented facts", n)
	}
	return nil
}

func readCases(path string) ([]answereval.Case, error) {
	raw, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	var cases []answereval.Case
	if err := json.Unmarshal(raw, &cases); err != nil {
		return nil, fmt.Errorf("parse %s: %w", path, err)
	}
	if err := answereval.Validate(cases); err != nil {
		return nil, err
	}
	return cases, answereval.LoadFiles(cases, filepath.Dir(path))
}

func writeJSON(path string, rep answereval.Report) error {
	f, err := os.Create(path)
	if err != nil {
		return err
	}
	if err := rep.WriteJSON(f); err != nil {
		_ = f.Close()
		return err
	}
	return f.Close()
}
