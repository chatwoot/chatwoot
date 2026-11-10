// Command comment-eval benchmarks comment-reply reviewers (internal/comments)
// on labelled cases: how often each one would send a reply it should hold,
// how well it reads intent, how sure it is, how fast and how costly.
//
//	LLM_API_KEY=… go run ./cmd/comment-eval -llm anthropic/claude-haiku-5.5,openai/gpt-5.6-luna
//	TYPESAFE_API_KEY=… go run ./cmd/comment-eval -jev jev-latest
//
// LLM_BASE_URL defaults to OpenRouter; its public model list gives prices.
// Jev's price is the published $0.042 per million input tokens (output free).
// Cases are mock data: a fictional business, labelled by hand.
// Issue: DEV-Johnstocker/chatwoot#1
package main

import (
	"bufio"
	"context"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"hash/fnv"
	"io"
	"log/slog"
	"math"
	"net/http"
	"net/url"
	"os"
	"sort"
	"strings"
	"sync"
	"text/tabwriter"
	"time"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/comments"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/llm"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/profile"
)

// Case is one labelled comment and draft.
type Case struct {
	ID         string          `json:"id"`
	Name       string          `json:"name"`
	Comment    string          `json:"comment"`
	Draft      string          `json:"draft"`
	WantIntent comments.Intent `json:"want_intent"`
	WantPass   bool            `json:"want_pass"`
	Note       string          `json:"note"`
}

// Price is dollars per million tokens.
type Price struct{ In, Out float64 }

// Result is one reviewer's answer to one case.
type Result struct {
	Case   Case
	Review comments.Review
	Err    error
}

// Summary is one reviewer's score.
type Summary struct {
	Reviewer       string        `json:"reviewer"`
	Cases          int           `json:"cases"`
	Errors         int           `json:"errors"`
	DecisionAcc    float64       `json:"decision_accuracy"`
	FalseSends     int           `json:"false_sends"`  // would send what it should hold
	MissedSends    int           `json:"missed_sends"` // would hold what could go out
	IntentAcc      float64       `json:"intent_accuracy"`
	Brier          float64       `json:"brier"` // of PSend against the label; lower is better
	P50            time.Duration `json:"p50_ns"`
	P95            time.Duration `json:"p95_ns"`
	AvgIn          float64       `json:"avg_input_tokens"`
	AvgOut         float64       `json:"avg_output_tokens"`
	CostPer1000    float64       `json:"usd_per_1000_comments"`
	PriceKnown     bool          `json:"price_known"`
	FalseSendCases []string      `json:"false_send_cases"`
}

func main() {
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, "comment-eval:", err)
		os.Exit(1)
	}
}

func run() error {
	casesPath := flag.String("cases", "testdata/comment-eval/cases.jsonl", "labelled cases (JSON Lines)")
	profilePath := flag.String("profile", "testdata/comment-eval/profile.json", "business profile (JSON)")
	llmModels := flag.String("llm", "", "comma-separated chat models on LLM_BASE_URL")
	jevModel := flag.String("jev", "", "Jev model (needs TYPESAFE_API_KEY), e.g. jev-latest")
	workers := flag.Int("concurrency", 4, "cases run at once per reviewer")
	jsonOut := flag.String("json", "", "also write the full results here")
	tune := flag.Bool("tune", false, "pick thresholds per reviewer on the tuning half (no false sends), report on the held-out half")
	jevBare := flag.Bool("jev-no-criteria", false, "also run Jev without the yes/no criteria, for comparison")
	swap := flag.Bool("swap", false, "with -tune: tune on the other half and test on the first (cross-check)")
	flag.Parse()

	cases, err := loadCases(*casesPath)
	if err != nil {
		return err
	}
	p, err := loadProfile(*profilePath)
	if err != nil {
		return err
	}
	reviewers, prices, err := buildReviewers(*llmModels, *jevModel, *jevBare)
	if err != nil {
		return err
	}
	if len(reviewers) == 0 {
		return errors.New("nothing to run: pass -llm and/or -jev")
	}

	var summaries []Summary
	all := map[string][]Result{}
	for _, name := range sortedKeys(reviewers) {
		results := runAll(reviewers[name], cases, p, *workers)
		all[name] = results
		price, known := prices[name]
		if !*tune {
			summaries = append(summaries, Summarize(name, results, price, known))
			continue
		}
		tuneSet, testSet := Split(results)
		if *swap {
			tuneSet, testSet = testSet, tuneSet
		}
		start := startThresholds(name)
		best := Tune(tuneSet, start)
		fmt.Printf("%s tuned on %d cases: %+v\n", name, len(tuneSet), best)
		summaries = append(summaries,
			Summarize(name+" (default, held-out)", Redecide(testSet, start), price, known),
			Summarize(name+" (tuned, held-out)", Redecide(testSet, best), price, known))
	}
	n := len(cases)
	if *tune {
		tuneSet, testSet := Split(all[sortedKeys(all)[0]])
		n = len(testSet)
		if *swap {
			n = len(tuneSet)
		}
	}
	printTable(os.Stdout, summaries, n)
	if *jsonOut != "" {
		return writeJSON(*jsonOut, summaries, all)
	}
	return nil
}

func loadCases(path string) ([]Case, error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer f.Close()
	var out []Case
	sc := bufio.NewScanner(f)
	sc.Buffer(make([]byte, 1<<20), 1<<20)
	for n := 1; sc.Scan(); n++ {
		line := strings.TrimSpace(sc.Text())
		if line == "" {
			continue
		}
		var c Case
		if err := json.Unmarshal([]byte(line), &c); err != nil || c.ID == "" || !c.WantIntent.Valid() {
			return nil, fmt.Errorf("%s line %d: need id, comment, draft, want_intent, want_pass", path, n)
		}
		out = append(out, c)
	}
	return out, sc.Err()
}

func loadProfile(path string) (profile.Profile, error) {
	raw, err := os.ReadFile(path)
	if err != nil {
		return profile.Profile{}, err
	}
	var v struct{ BusinessName, About, Tone, Contact, Rules string }
	var m map[string]string
	if err := json.Unmarshal(raw, &m); err != nil {
		return profile.Profile{}, err
	}
	v.BusinessName, v.About, v.Tone, v.Contact, v.Rules = m["business_name"], m["about"], m["tone"], m["contact"], m["rules"]
	return profile.Profile{BusinessName: v.BusinessName, About: v.About, Tone: v.Tone, Contact: v.Contact, Rules: v.Rules}, nil
}

// safeURL refuses to send an API key over plain http, except to this machine.
func safeURL(raw string) error {
	u, err := url.Parse(raw)
	if err != nil || u.Host == "" {
		return fmt.Errorf("%q is not a URL", raw)
	}
	if u.Scheme == "https" || (u.Scheme == "http" && (u.Hostname() == "127.0.0.1" || u.Hostname() == "localhost")) {
		return nil
	}
	return fmt.Errorf("refusing to send an API key to %s over %s", u.Host, u.Scheme)
}

func buildReviewers(llmModels, jevModel string, jevBare bool) (map[string]comments.Reviewer, map[string]Price, error) {
	reviewers, prices := map[string]comments.Reviewer{}, map[string]Price{}
	base := strings.TrimRight(envOr("LLM_BASE_URL", "https://openrouter.ai/api/v1"), "/")
	if err := safeURL(base); llmModels != "" && err != nil {
		return nil, nil, err
	}
	if err := safeURL(envOr("TYPESAFE_URL", comments.DefaultJevURL)); jevModel != "" && err != nil {
		return nil, nil, err
	}
	var catalog map[string]Price
	for _, m := range splitList(llmModels) {
		key := os.Getenv("LLM_API_KEY")
		if key == "" {
			return nil, nil, errors.New("-llm needs LLM_API_KEY")
		}
		// No MaxTokens: OpenAI's current models reject max_tokens, and the
		// service does not set it for them either.
		c := llm.New(base, key, m, &http.Client{Timeout: 90 * time.Second})
		name := "llm:" + m
		reviewers[name] = &comments.LLMReviewer{LLM: c, Model: m}
		if catalog == nil {
			// OpenRouter's public list prices models from other providers too
			// ("openai/<model>" for api.openai.com).
			catalog = openRouterPrices("https://openrouter.ai/api/v1")
		}
		for _, id := range []string{m, "openai/" + m} {
			if pr, ok := catalog[id]; ok {
				prices[name] = pr
				break
			}
		}
	}
	if jevModel != "" {
		key := os.Getenv("TYPESAFE_API_KEY")
		if key == "" {
			slog.Warn("skipping jev: TYPESAFE_API_KEY is not set")
		} else {
			name := "jev:" + jevModel
			reviewers[name] = &comments.JevReviewer{APIKey: key, Model: jevModel, URL: envOr("TYPESAFE_URL", comments.DefaultJevURL)}
			prices[name] = Price{In: comments.JevPricePerMInput, Out: 0}
			if jevBare {
				bare := name + ":no-criteria"
				reviewers[bare] = &comments.JevReviewer{APIKey: key, Model: jevModel, URL: envOr("TYPESAFE_URL", comments.DefaultJevURL), NoCriteria: true}
				prices[bare] = prices[name]
			}
		}
	}
	return reviewers, prices, nil
}

// openRouterPrices reads per-token prices from OpenRouter's public model
// list and returns dollars per million tokens. A failure returns nothing:
// costs then show as unknown.
func openRouterPrices(base string) map[string]Price {
	res, err := (&http.Client{Timeout: 20 * time.Second}).Get(base + "/models")
	if err != nil {
		return nil
	}
	defer res.Body.Close()
	var body struct {
		Data []struct {
			ID      string `json:"id"`
			Pricing struct {
				Prompt     string `json:"prompt"`
				Completion string `json:"completion"`
			} `json:"pricing"`
		} `json:"data"`
	}
	if json.NewDecoder(io.LimitReader(res.Body, 32<<20)).Decode(&body) != nil {
		return nil
	}
	out := map[string]Price{}
	for _, m := range body.Data {
		var in, o float64
		if _, err := fmt.Sscan(m.Pricing.Prompt, &in); err != nil {
			continue
		}
		if _, err := fmt.Sscan(m.Pricing.Completion, &o); err != nil {
			continue
		}
		out[m.ID] = Price{In: in * 1e6, Out: o * 1e6}
	}
	return out
}

func runAll(r comments.Reviewer, cases []Case, p profile.Profile, workers int) []Result {
	out := make([]Result, len(cases))
	sem := make(chan struct{}, max(workers, 1))
	var wg sync.WaitGroup
	for i, c := range cases {
		wg.Add(1)
		go func() {
			defer wg.Done()
			sem <- struct{}{}
			defer func() { <-sem }()
			ctx, cancel := context.WithTimeout(context.Background(), 90*time.Second)
			defer cancel()
			rv, err := r.Review(ctx, comments.Comment{FromName: c.Name, Message: c.Comment}, c.Draft, p)
			out[i] = Result{Case: c, Review: rv, Err: err}
		}()
	}
	wg.Wait()
	return out
}

// Summarize scores one reviewer. Failed calls count against accuracy (a
// reviewer that errors cannot send), and are listed separately.
func Summarize(name string, results []Result, price Price, known bool) Summary {
	s := Summary{Reviewer: name, Cases: len(results), PriceKnown: known}
	var lat []time.Duration
	var okDecisions, okIntent, scored int
	var brier, in, out float64
	for _, r := range results {
		if r.Err != nil {
			s.Errors++
			if r.Case.WantPass {
				s.MissedSends++
			} else {
				okDecisions++
			}
			continue
		}
		scored++
		lat = append(lat, r.Review.Latency)
		in += float64(r.Review.InputTokens)
		out += float64(r.Review.OutputTokens)
		if r.Review.Intent == r.Case.WantIntent {
			okIntent++
		}
		switch {
		case r.Review.Pass == r.Case.WantPass:
			okDecisions++
		case r.Review.Pass:
			s.FalseSends++
			s.FalseSendCases = append(s.FalseSendCases, r.Case.ID)
		default:
			s.MissedSends++
		}
		want := 0.0
		if r.Case.WantPass {
			want = 1
		}
		brier += math.Pow(r.Review.PSend()-want, 2)
	}
	if s.Cases > 0 {
		s.DecisionAcc = float64(okDecisions) / float64(s.Cases)
	}
	if scored > 0 {
		s.IntentAcc = float64(okIntent) / float64(scored)
		s.Brier = brier / float64(scored)
		s.AvgIn, s.AvgOut = in/float64(scored), out/float64(scored)
		s.CostPer1000 = (s.AvgIn*price.In + s.AvgOut*price.Out) / 1e6 * 1000
		sort.Slice(lat, func(a, b int) bool { return lat[a] < lat[b] })
		s.P50, s.P95 = percentile(lat, 0.50), percentile(lat, 0.95)
	}
	return s
}

func percentile(sorted []time.Duration, q float64) time.Duration {
	if len(sorted) == 0 {
		return 0
	}
	i := int(math.Ceil(q*float64(len(sorted)))) - 1
	return sorted[min(max(i, 0), len(sorted)-1)]
}

func printTable(w io.Writer, rows []Summary, cases int) {
	fmt.Fprintf(w, "%d mock cases (fictional business). False sends = would send a reply that should be held.\n\n", cases)
	tw := tabwriter.NewWriter(w, 0, 2, 2, ' ', 0)
	fmt.Fprintln(tw, "reviewer\tdecision acc\tfalse sends\tmissed sends\tintent acc\tbrier\tp50\tp95\tavg tok in/out\t$ / 1000 comments\terrors")
	for _, s := range rows {
		cost := "unknown"
		if s.PriceKnown {
			cost = fmt.Sprintf("%.4f", s.CostPer1000)
		}
		fmt.Fprintf(tw, "%s\t%.0f%%\t%d\t%d\t%.0f%%\t%.3f\t%s\t%s\t%.0f / %.0f\t%s\t%d\n", s.Reviewer, s.DecisionAcc*100, s.FalseSends, s.MissedSends,
			s.IntentAcc*100, s.Brier, s.P50.Round(time.Millisecond), s.P95.Round(time.Millisecond), s.AvgIn, s.AvgOut, cost, s.Errors)
	}
	_ = tw.Flush()
	for _, s := range rows {
		if len(s.FalseSendCases) > 0 {
			fmt.Fprintf(w, "\n%s false sends: %s", s.Reviewer, strings.Join(s.FalseSendCases, ", "))
		}
	}
	fmt.Fprintln(w)
}

func writeJSON(path string, summaries []Summary, all map[string][]Result) error {
	type row struct {
		ID     string          `json:"id"`
		Want   bool            `json:"want_pass"`
		Review comments.Review `json:"review"`
		Error  string          `json:"error,omitempty"`
	}
	detail := map[string][]row{}
	for name, results := range all {
		for _, r := range results {
			e := ""
			if r.Err != nil {
				e = r.Err.Error()
			}
			detail[name] = append(detail[name], row{ID: r.Case.ID, Want: r.Case.WantPass, Review: r.Review, Error: e})
		}
	}
	raw, err := json.MarshalIndent(map[string]any{"summaries": summaries, "results": detail}, "", "  ")
	if err != nil {
		return err
	}
	return os.WriteFile(path, raw, 0o600)
}

func envOr(key, def string) string {
	if v := strings.TrimSpace(os.Getenv(key)); v != "" {
		return v
	}
	return def
}

func splitList(s string) []string {
	var out []string
	for _, p := range strings.Split(s, ",") {
		if p = strings.TrimSpace(p); p != "" {
			out = append(out, p)
		}
	}
	return out
}

func sortedKeys[V any](m map[string]V) []string {
	keys := make([]string, 0, len(m))
	for k := range m {
		keys = append(keys, k)
	}
	sort.Strings(keys)
	return keys
}

// startThresholds is where tuning starts: the reviewer's own defaults.
func startThresholds(name string) comments.Thresholds {
	if strings.HasPrefix(name, "jev:") {
		return comments.JevThresholds
	}
	return comments.LLMThresholds
}

// Split divides results into a tuning half and a held-out half, balanced by
// label and stable across runs (FNV hash of the case ID).
func Split(results []Result) (tune, test []Result) {
	groups := map[bool][]Result{}
	for _, r := range results {
		groups[r.Case.WantPass] = append(groups[r.Case.WantPass], r)
	}
	for _, label := range []bool{true, false} {
		g := groups[label]
		sort.Slice(g, func(a, b int) bool { return hashID(g[a].Case.ID) < hashID(g[b].Case.ID) })
		for i, r := range g {
			if i%2 == 0 {
				tune = append(tune, r)
			} else {
				test = append(test, r)
			}
		}
	}
	return tune, test
}

func hashID(id string) uint32 {
	h := fnv.New32a()
	_, _ = h.Write([]byte(id))
	return h.Sum32()
}

// Redecide applies thresholds t to stored answers, as the service would.
func Redecide(results []Result, t comments.Thresholds) []Result {
	out := make([]Result, len(results))
	for i, r := range results {
		out[i] = r
		if r.Err == nil {
			out[i].Review = comments.Decide(r.Review, r.Case.Draft, t)
		}
	}
	return out
}

// score ranks thresholds: no false sends first, then right calls.
func score(results []Result) (falseSends, right int) {
	for _, r := range results {
		switch {
		case r.Err != nil:
			if !r.Case.WantPass {
				right++
			}
		case r.Review.Pass == r.Case.WantPass:
			right++
		case r.Review.Pass:
			falseSends++
		}
	}
	return falseSends, right
}

func better(fs, right, bestFS, bestRight int) bool {
	return fs < bestFS || (fs == bestFS && right > bestRight)
}

// Tune searches each threshold in turn over 0.50–0.95 (coordinate descent,
// three passes) for the fewest false sends, then the most right calls. On
// a tie it keeps the higher, safer bar.
func Tune(results []Result, start comments.Thresholds) comments.Thresholds {
	best := start
	bestFS, bestRight := score(Redecide(results, best))
	fields := []func(*comments.Thresholds) *float64{
		func(t *comments.Thresholds) *float64 { return &t.Intent },
		func(t *comments.Thresholds) *float64 { return &t.Genuine },
		func(t *comments.Thresholds) *float64 { return &t.Answers },
		func(t *comments.Thresholds) *float64 { return &t.Offer },
		func(t *comments.Thresholds) *float64 { return &t.Tone },
	}
	for pass := 0; pass < 3; pass++ {
		for _, field := range fields {
			for v := 0.95; v >= 0.499; v -= 0.05 {
				cand := best
				*field(&cand) = math.Round(v*100) / 100
				fs, right := score(Redecide(results, cand))
				if better(fs, right, bestFS, bestRight) {
					best, bestFS, bestRight = cand, fs, right
				}
			}
		}
	}
	return best
}
