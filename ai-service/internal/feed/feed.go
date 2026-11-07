// Package feed reads a structured knowledge file (CSV with a header row, or
// JSON Lines) into rows that each become one knowledge document, keyed by the
// row's id. A Google Sheet published to the web as CSV is the common case.
//
// Columns (case-insensitive): id (required); question + answer for an FAQ;
// otherwise title (or category and section) + content (or text, body,
// description); optional start_date and last_day (YYYY-MM-DD) limit when the
// bot may use the row. Other columns are ignored.
package feed

import (
	"bytes"
	"crypto/sha256"
	"encoding/csv"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"strconv"
	"strings"
	"time"
	"unicode"
	"unicode/utf8"
)

// Limits.
const (
	MaxRows       = 500
	MaxIDRunes    = 120
	maxTitleRunes = 300     // knowledge.MaxTitleRunes
	maxTextRunes  = 200_000 // knowledge.MaxContentRunes
	maxProblems   = 5
)

// Row is one document from the feed.
type Row struct {
	ID        string
	FAQ       bool // Title is the question, Content the answer
	Title     string
	Content   string
	StartDate string // YYYY-MM-DD or ""
	LastDay   string // YYYY-MM-DD or "": the last day the bot may use it
}

// Result is a parsed feed.
type Result struct {
	Format   string // "CSV" or "JSONL"
	Rows     []Row
	Skipped  int
	Problems []string // the first few skipped rows and why
}

// ErrNotFeed means the file is not a CSV or JSON Lines feed with an id.
var ErrNotFeed = errors.New("not a data file: use CSV with a header row or JSON Lines, with an id column")

// Parse reads a CSV or JSON Lines file.
func Parse(body []byte) (Result, error) {
	body = bytes.TrimPrefix(body, []byte("\xef\xbb\xbf"))
	trimmed := bytes.TrimSpace(body)
	switch {
	case len(trimmed) == 0:
		return Result{}, errors.New("the file is empty")
	case !utf8.Valid(trimmed):
		return Result{}, errors.New("the file is not UTF-8 text")
	case trimmed[0] == '<':
		return Result{}, errors.New("this is a web page, not a data file (for a Google Sheet use File → Share → Publish to web → CSV)")
	case trimmed[0] == '[':
		return Result{}, errors.New("JSON arrays are not supported: put one JSON object per line (JSON Lines)")
	case trimmed[0] == '{':
		return parseJSONL(trimmed)
	}
	return parseCSV(trimmed)
}

func parseJSONL(body []byte) (Result, error) {
	res := Result{Format: "JSONL"}
	var b builder
	for n, line := range bytes.Split(body, []byte("\n")) {
		line = bytes.TrimSpace(line)
		if len(line) == 0 {
			continue
		}
		var obj map[string]any
		if err := json.Unmarshal(line, &obj); err != nil {
			return Result{}, fmt.Errorf("line %d is not a JSON object: put one object per line", n+1)
		}
		fields := make(map[string]string, len(obj))
		for k, v := range obj {
			fields[normKey(k)] = jsonText(v)
		}
		b.add(&res, n+1, fields)
	}
	return res, b.done(&res)
}

func parseCSV(body []byte) (Result, error) {
	r := csv.NewReader(bytes.NewReader(body))
	r.FieldsPerRecord = -1
	r.LazyQuotes = true
	header, err := r.Read()
	if err != nil {
		return Result{}, ErrNotFeed
	}
	cols := make([]string, len(header))
	hasID := false
	for i, h := range header {
		cols[i] = normKey(h)
		hasID = hasID || cols[i] == "id"
	}
	if !hasID {
		return Result{}, ErrNotFeed
	}
	res := Result{Format: "CSV"}
	var b builder
	for line := 2; ; line++ {
		rec, err := r.Read()
		if errors.Is(err, io.EOF) {
			break
		}
		if err != nil {
			return Result{}, fmt.Errorf("row %d could not be read: %v", line, err)
		}
		fields := make(map[string]string, len(cols))
		for i, v := range rec {
			if i < len(cols) && cols[i] != "" {
				fields[cols[i]] = v
			}
		}
		b.add(&res, line, fields)
	}
	return res, b.done(&res)
}

// builder turns field maps into rows, skipping bad and duplicate ones.
type builder struct {
	seen  map[string]bool
	total int
}

func (b *builder) add(res *Result, line int, f map[string]string) {
	b.total++
	if b.seen == nil {
		b.seen = map[string]bool{}
	}
	row, problem := toRow(f)
	switch {
	case problem == "" && b.seen[row.ID]:
		problem = "duplicate id " + row.ID
	case problem == "" && len(res.Rows) >= MaxRows:
		problem = fmt.Sprintf("only the first %d rows are used", MaxRows)
	}
	if problem != "" {
		res.Skipped++
		if len(res.Problems) < maxProblems {
			res.Problems = append(res.Problems, fmt.Sprintf("row %d: %s", line, problem))
		}
		return
	}
	b.seen[row.ID] = true
	res.Rows = append(res.Rows, row)
}

func (b *builder) done(res *Result) error {
	if b.total == 0 {
		return errors.New("the file has no rows")
	}
	return nil
}

func toRow(f map[string]string) (Row, string) {
	id := cleanID(f["id"])
	switch {
	case id == "":
		return Row{}, "no id"
	case utf8.RuneCountInString(id) > MaxIDRunes:
		return Row{}, fmt.Sprintf("id longer than %d characters", MaxIDRunes)
	}
	start, last := clean(f["start_date"]), first(f, "last_day", "end_date")
	for _, d := range []string{start, last} {
		if _, err := time.Parse(time.DateOnly, d); d != "" && err != nil {
			return Row{}, "dates must be YYYY-MM-DD (" + cut(d, 20) + ")"
		}
	}
	if start != "" && last != "" && last < start {
		return Row{}, "last_day is before start_date"
	}
	row, problem := rowText(id, f)
	row.StartDate, row.LastDay = start, last
	return row, problem
}

func rowText(id string, f map[string]string) (Row, string) {
	q, a := clean(f["question"]), clean(f["answer"])
	if q != "" && a != "" {
		return Row{ID: id, FAQ: true, Title: cut(q, maxTitleRunes), Content: cut(a, maxTextRunes)}, ""
	}
	content := first(f, "content", "text", "body", "description", "answer")
	if content == "" {
		return Row{}, "no text (content, text or answer)"
	}
	title := clean(f["title"])
	if title == "" {
		title = joinNonEmpty(": ", clean(f["category"]), clean(f["section"]))
	}
	if title == "" {
		title = first(f, "question", "name")
	}
	if title == "" {
		title = id
	}
	return Row{ID: id, Title: cut(title, maxTitleRunes), Content: cut(content, maxTextRunes)}, ""
}

// RowHash fingerprints a row's content, to skip unchanged rows.
func RowHash(r Row) string {
	sum := sha256.Sum256([]byte(fmt.Sprintf("%t\x00%s\x00%s\x00%s\x00%s", r.FAQ, r.Title, r.Content, r.StartDate, r.LastDay)))
	return hex.EncodeToString(sum[:])
}

// cleanID trims the id and joins inner whitespace with "-" (keys have no spaces).
func cleanID(s string) string {
	return strings.Join(strings.FieldsFunc(clean(s), unicode.IsSpace), "-")
}

// clean trims a cell, normalises line ends and drops NUL characters (a
// database text field cannot hold them).
func clean(s string) string {
	return strings.TrimSpace(strings.NewReplacer("\r\n", "\n", "\x00", "").Replace(s))
}

func first(f map[string]string, keys ...string) string {
	for _, k := range keys {
		if v := clean(f[k]); v != "" {
			return v
		}
	}
	return ""
}

func joinNonEmpty(sep string, parts ...string) string {
	out := parts[:0]
	for _, p := range parts {
		if p != "" {
			out = append(out, p)
		}
	}
	return strings.Join(out, sep)
}

func cut(s string, n int) string {
	if r := []rune(s); len(r) > n {
		return strings.TrimSpace(string(r[:n]))
	}
	return s
}

func normKey(k string) string {
	k = strings.ToLower(strings.TrimSpace(k))
	return strings.NewReplacer(" ", "_", "-", "_").Replace(k)
}

func jsonText(v any) string {
	switch t := v.(type) {
	case string:
		return t
	case float64:
		return strconv.FormatFloat(t, 'f', -1, 64)
	case bool:
		return strconv.FormatBool(t)
	case nil:
		return ""
	}
	b, _ := json.Marshal(v)
	return string(b)
}
