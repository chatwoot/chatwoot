package mcp

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"log/slog"
	"net/http"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/audit"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/bot"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/knowledge"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/memory"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/profile"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/ratelimit"
)

// Protocol versions this server speaks, newest first.
var protocolVersions = []string{"2025-06-18", "2025-03-26", "2024-11-05"}

const maxBody = 1 << 20

// Tester runs the bot's reply pipeline without Chatwoot (bot.Bot.Preview).
type Tester interface {
	Preview(ctx context.Context, acct, inbox int64, history []memory.Turn) bot.Preview
}

// Server serves MCP over streamable HTTP: one JSON-RPC message per POST,
// answered with JSON. It keeps no sessions and sends no server events.
type Server struct {
	Knowledge *knowledge.Service
	Tokens    Tokens
	Audit     Auditor
	Tester    Tester // nil hides the test_bot tool
	// Profiles, Sources, Checker and Events enable the business profile,
	// source and change-history tools; a nil one hides the tools needing it.
	Profiles profile.Store
	Sources  Sources
	Checker  Checker
	Events   audit.Store
	Location *time.Location // business time zone for dates; nil is UTC
	Logger   *slog.Logger
	Version  string
	// ResourceMetadata is the OAuth protected resource metadata URL, sent in
	// 401 answers so apps can find where to sign in; empty without OAuth.
	ResourceMetadata string

	// PerMinute caps calls per token (embedding and model calls cost money);
	// 0 means 60. TestPerMinute caps test_bot per account (each runs the full
	// reply pipeline); 0 means 10. PerIPMinute caps requests per client IP
	// before any token check; 0 means 120.
	PerMinute, TestPerMinute, PerIPMinute int

	limits   ratelimit.Limiter
	mu       sync.Mutex
	inFlight map[int64]int // test_bot calls running, per account
}

func (s *Server) now() time.Time { return time.Now() }

type rpcRequest struct {
	JSONRPC string          `json:"jsonrpc"`
	ID      json.RawMessage `json:"id,omitempty"`
	Method  string          `json:"method"`
	Params  json.RawMessage `json:"params,omitempty"`
}

type rpcError struct {
	Code    int    `json:"code"`
	Message string `json:"message"`
}

type rpcResponse struct {
	JSONRPC string          `json:"jsonrpc"`
	ID      json.RawMessage `json:"id"`
	Result  any             `json:"result,omitempty"`
	Error   *rpcError       `json:"error,omitempty"`
}

// JSON-RPC error codes.
const (
	codeParse          = -32700
	codeInvalidRequest = -32600
	codeMethodNotFound = -32601
	codeInvalidParams  = -32602
)

// ServeHTTP implements the endpoint. Errors that happen before a request is
// understood (auth, size, origin) are plain HTTP errors.
func (s *Server) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Cache-Control", "no-store")
	if r.Method != http.MethodPost {
		w.Header().Set("Allow", http.MethodPost)
		http.Error(w, "use POST (this server sends no event stream)", http.StatusMethodNotAllowed)
		return
	}
	// Browsers send Origin; AI tools do not. Refusing browser origins stops a
	// web page from using a token the browser happens to hold (DNS rebinding).
	if r.Header.Get("Origin") != "" {
		http.Error(w, "browser requests are not allowed", http.StatusForbidden)
		return
	}
	if !s.allow("ip:"+ratelimit.ClientIP(r), s.PerIPMinute, 120) {
		w.Header().Set("Retry-After", "60")
		http.Error(w, "too many requests; wait a minute", http.StatusTooManyRequests)
		return
	}
	tok, err := s.authenticate(r)
	if errors.Is(err, ErrUnavailable) {
		s.Logger.Error("mcp token check failed", "error", err)
		http.Error(w, "temporarily unavailable; try again", http.StatusServiceUnavailable)
		return
	}
	if err != nil {
		challenge := `Bearer realm="ai-service mcp"`
		if s.ResourceMetadata != "" {
			challenge = `Bearer resource_metadata="` + s.ResourceMetadata + `", scope="kb:read"`
		}
		w.Header().Set("WWW-Authenticate", challenge)
		http.Error(w, "missing, invalid, expired or revoked token", http.StatusUnauthorized)
		return
	}
	if !s.allow("token:"+strconv.FormatInt(tok.ID, 10), s.PerMinute, 60) {
		w.Header().Set("Retry-After", "60")
		http.Error(w, "too many requests for this token; wait a minute", http.StatusTooManyRequests)
		return
	}
	body, err := io.ReadAll(http.MaxBytesReader(w, r.Body, maxBody))
	if err != nil {
		http.Error(w, "request too large (max 1 MB)", http.StatusRequestEntityTooLarge)
		return
	}
	var req rpcRequest
	if err := json.Unmarshal(body, &req); err != nil || req.JSONRPC != "2.0" || req.Method == "" {
		code, msg := codeInvalidRequest, "expected one JSON-RPC 2.0 request (batches are not supported)"
		if err != nil && !json.Valid(body) {
			code, msg = codeParse, "invalid JSON"
		}
		writeJSON(w, http.StatusOK, rpcResponse{JSONRPC: "2.0", ID: json.RawMessage("null"), Error: &rpcError{code, msg}})
		return
	}
	if len(req.ID) == 0 { // notification: nothing to answer
		w.WriteHeader(http.StatusAccepted)
		return
	}
	result, rerr := s.dispatch(r.Context(), tok, req)
	resp := rpcResponse{JSONRPC: "2.0", ID: req.ID, Result: result, Error: rerr}
	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) authenticate(r *http.Request) (Token, error) {
	h := r.Header.Get("Authorization")
	plain, ok := strings.CutPrefix(h, "Bearer ")
	plain = strings.TrimSpace(plain)
	if !ok || !WellFormed(plain) { // no database query for junk
		return Token{}, ErrInvalidToken
	}
	return s.Tokens.Lookup(r.Context(), plain)
}

// allow counts one call for key against limit (def when limit is 0).
func (s *Server) allow(key string, limit, def int) bool {
	if limit <= 0 {
		limit = def
	}
	return s.limits.Allow(key, limit)
}

// startTest admits a test_bot call: at most 2 at once per account.
func (s *Server) startTest(acct int64) (done func(), ok bool) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.inFlight == nil {
		s.inFlight = map[int64]int{}
	}
	if s.inFlight[acct] >= 2 {
		return nil, false
	}
	s.inFlight[acct]++
	return func() {
		s.mu.Lock()
		defer s.mu.Unlock()
		s.inFlight[acct]--
	}, true
}

func (s *Server) dispatch(ctx context.Context, tok Token, req rpcRequest) (any, *rpcError) {
	switch req.Method {
	case "initialize":
		var p struct {
			ProtocolVersion string `json:"protocolVersion"`
		}
		_ = json.Unmarshal(req.Params, &p)
		version := protocolVersions[0]
		for _, v := range protocolVersions {
			if v == p.ProtocolVersion {
				version = v
			}
		}
		return map[string]any{
			"protocolVersion": version,
			"capabilities":    map[string]any{"tools": map[string]any{}},
			"serverInfo":      map[string]any{"name": "ai-service-knowledge", "version": s.Version},
			"instructions":    instructions(tok),
		}, nil
	case "ping":
		return map[string]any{}, nil
	case "tools/list":
		return map[string]any{"tools": s.toolList(tok)}, nil
	case "tools/call":
		var p struct {
			Name      string          `json:"name"`
			Arguments json.RawMessage `json:"arguments"`
		}
		if err := json.Unmarshal(req.Params, &p); err != nil || p.Name == "" {
			return nil, &rpcError{codeInvalidParams, "tools/call needs a tool name"}
		}
		return s.callTool(ctx, tok, p.Name, p.Arguments)
	}
	return nil, &rpcError{codeMethodNotFound, "unknown method " + req.Method}
}

func instructions(tok Token) string {
	s := "Knowledge base of one business (Chatwoot account). The support bot answers customers only from these documents. " +
		"Give every document a stable key (for example product-017 or a page URL) and update by that key instead of adding near-copies. " +
		"Call find_similar before adding something new, set last_day on promotions, and use test_bot to check how the bot answers after a change. " +
		"Documents with web: or feed: keys come from a website page or data file (list_sources); change the source, then sync_source."
	if !tok.CanWrite {
		s += " This token is read-only: tools that change things are not available."
	}
	return s
}

// toolError is a tool result the model should read and act on (not a protocol error).
func toolError(msg string) map[string]any {
	return map[string]any{"isError": true, "content": []map[string]any{{"type": "text", "text": msg}}}
}

func toolResult(v any) (map[string]any, *rpcError) {
	b, err := json.MarshalIndent(v, "", "  ")
	if err != nil {
		return nil, &rpcError{codeInvalidParams, "could not encode the result"}
	}
	return map[string]any{
		"content":           []map[string]any{{"type": "text", "text": string(b)}},
		"structuredContent": v,
	}, nil
}

func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(v)
}

var errReadOnly = userError("this token is read-only; create a read-write token on the admin page")

// userError is a message meant for the AI tool (bad input, not found). Any
// other error is reported as a generic failure; details stay in the log.
type userError string

func (e userError) Error() string { return string(e) }

func public(err error) string {
	var u userError
	if errors.As(err, &u) {
		return u.Error()
	}
	return "internal error; try again later"
}
