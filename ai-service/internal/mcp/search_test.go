package mcp

import (
	"encoding/json"
	"strings"
	"testing"
	"time"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/knowledge"
)

func searchEnv() *env {
	e := newEnv()
	e.srv.Knowledge.MinScore = 0.3
	now := time.Now()
	e.st.docs = []knowledge.Document{
		{ID: 1, AccountID: 1, Kind: knowledge.KindFAQ, Title: "Shipping upcountry", Content: "Kerry, 1-3 days", SourceKey: "faq-shipping"},
		{ID: 2, AccountID: 1, Kind: knowledge.KindText, Title: "Old promo", Content: "10% off", ValidUntil: now.Add(-time.Hour), SourceKey: "web:https://shop.test/promo"},
		{ID: 3, AccountID: 1, Kind: knowledge.KindText, Title: "Returns", Content: strings.Repeat("ก", 900)},
	}
	e.st.hits = []knowledge.Hit{
		{ChunkID: 10, DocumentID: 1, Title: "Shipping upcountry", Content: "Kerry, 1-3 days", Score: 0.82},
		{ChunkID: 20, DocumentID: 2, Title: "Old promo", Content: "10% off", Score: 0.55},
		{ChunkID: 30, DocumentID: 3, Title: "Returns", Content: strings.Repeat("ก", 900), Score: 0.21},
	}
	return e
}

type searchOut struct {
	Results []struct {
		Rank        int    `json:"rank"`
		DocumentID  int64  `json:"document_id"`
		Key         string `json:"key"`
		Title       string `json:"title"`
		Status      string `json:"status"`
		Score       int    `json:"score"`
		Excerpt     string `json:"excerpt"`
		BotWouldUse bool   `json:"bot_would_use"`
		Synced      bool   `json:"synced"`
	} `json:"results"`
	Note string `json:"note"`
}

func TestSearch_RanksChunksWithScoresAndWhatTheBotWouldUse(t *testing.T) {
	// Arrange
	e := searchEnv()

	// Act: a read-only token may search.
	res := e.call(ro, "search_knowledge", map[string]any{"query": "ค่าส่งต่างจังหวัด", "include_inactive": true})

	// Assert
	if isErr(res) {
		t.Fatalf("error: %s", text(res))
	}
	var out searchOut
	if err := json.Unmarshal([]byte(text(res)), &out); err != nil {
		t.Fatalf("not JSON: %v %s", err, text(res))
	}
	if len(out.Results) != 3 || out.Results[0].Rank != 1 || out.Results[0].Key != "faq-shipping" || out.Results[0].Score != 82 {
		t.Fatalf("results = %+v", out.Results)
	}
	if !out.Results[0].BotWouldUse {
		t.Error("active hit above the bot's minimum score should be marked bot_would_use")
	}
	if out.Results[1].Status != knowledge.StatusExpired || out.Results[1].BotWouldUse || !out.Results[1].Synced || out.Results[0].Synced {
		t.Errorf("expired hit = %+v; the bot never uses expired documents", out.Results[1])
	}
	if out.Results[2].BotWouldUse {
		t.Error("hit below the bot's minimum score marked bot_would_use")
	}
	if n := len([]rune(out.Results[2].Excerpt)); n > maxExcerptRunes+1 {
		t.Errorf("excerpt is %d runes, want at most %d plus an ellipsis", n, maxExcerptRunes)
	}
	if out.Note == "" {
		t.Error("note about the bot rewriting questions is missing")
	}
	q := e.st.queries[len(e.st.queries)-1]
	if q.AccountID != 1 || !q.IncludeInactive || q.Limit != defaultSearchLimit {
		t.Errorf("query = %+v", q)
	}
	if e.st.marked != 0 {
		t.Error("searching must not count as customer use")
	}
}

func TestSearch_StaysInTheTokensAccountAndClampsLimit(t *testing.T) {
	// Arrange
	e := searchEnv()

	// Act
	foreign := e.call(other, "search_knowledge", map[string]any{"query": "shipping", "limit": 500})
	big := e.st.queries[len(e.st.queries)-1]
	e.call(rw, "search_knowledge", map[string]any{"query": "shipping", "limit": 2, "inbox_id": 7})
	small := e.st.queries[len(e.st.queries)-1]

	// Assert
	if big.AccountID != 2 || big.Limit != maxSearchLimit || big.IncludeInactive {
		t.Errorf("other account query = %+v", big)
	}
	if strings.Contains(text(foreign), "Shipping upcountry") {
		t.Error("another account's document came back")
	}
	if small.AccountID != 1 || small.Limit != 2 || small.InboxID != 7 {
		t.Errorf("limited query = %+v", small)
	}
}

func TestSearch_RefusesAnEmptyQuery(t *testing.T) {
	// Arrange
	e := searchEnv()

	// Act
	res := e.call(ro, "search_knowledge", map[string]any{"query": "   "})

	// Assert
	if !isErr(res) || !strings.Contains(text(res), "query is required") || len(e.st.queries) != 0 {
		t.Fatalf("empty query: err=%v searches=%d", isErr(res), len(e.st.queries))
	}
}
