// Package mcp is the Model Context Protocol endpoint: AI tools such as Claude
// and Codex read, write and test an account's knowledge base through it.
// Each request carries a bearer token tied to one account and a scope.
package mcp

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// TokenPrefix marks ai-service MCP tokens, so secret scanners can find a leaked one.
const TokenPrefix = "aisvc_mcp_"

// Token is an MCP access token's record. The token itself is never stored.
type Token struct {
	ID         int64
	AccountID  int64
	Name       string
	CanWrite   bool
	CreatedAt  time.Time
	LastUsedAt time.Time
	ExpiresAt  time.Time // zero = never
	RevokedAt  time.Time
}

// tokenLen is the exact length of a token: the prefix plus 32 bytes in
// unpadded base64url. Anything else is refused without a database query.
const tokenLen = len(TokenPrefix) + 43

// ErrUnavailable means tokens could not be checked (database down).
var ErrUnavailable = errors.New("token check unavailable")

// ErrInvalidToken means the token is unknown or revoked.
var ErrInvalidToken = errors.New("invalid or revoked token")

// Tokens creates, checks and revokes tokens.
type Tokens interface {
	Create(ctx context.Context, accountID int64, name string, canWrite bool, ttl time.Duration) (plain string, t Token, err error)
	Lookup(ctx context.Context, plain string) (Token, error)
	List(ctx context.Context, accountID int64) ([]Token, error)
	Revoke(ctx context.Context, accountID, id int64) error
}

// AuditEntry is one change made through MCP. Before holds the document as it
// was (nil when it was created), so a change can be undone by hand.
type AuditEntry struct {
	AccountID  int64
	DocumentID int64
	SourceKey  string
	Action     string // create, update, delete
	Actor      string
	TokenID    int64
	Before     any
}

// Auditor records changes.
type Auditor interface {
	Record(ctx context.Context, e AuditEntry) error
}

// NewToken returns a random token and its storage hash.
func NewToken() (plain, hash string, err error) {
	b := make([]byte, 32)
	if _, err := rand.Read(b); err != nil {
		return "", "", err
	}
	plain = TokenPrefix + base64.RawURLEncoding.EncodeToString(b)
	return plain, HashToken(plain), nil
}

// WellFormed reports whether plain has a token's exact shape.
func WellFormed(plain string) bool {
	if len(plain) != tokenLen || !strings.HasPrefix(plain, TokenPrefix) {
		return false
	}
	_, err := base64.RawURLEncoding.DecodeString(plain[len(TokenPrefix):])
	return err == nil
}

// HashToken is the stored form of a token (SHA-256, hex). Tokens carry 256
// random bits, so a fast hash is enough; there is nothing to brute-force.
func HashToken(plain string) string {
	sum := sha256.Sum256([]byte(plain))
	return hex.EncodeToString(sum[:])
}

// Postgres stores tokens and the audit trail (schema v5 tables).
type Postgres struct {
	Pool *pgxpool.Pool
}

// Create implements Tokens. ttl 0 means the token never expires.
func (p *Postgres) Create(ctx context.Context, accountID int64, name string, canWrite bool, ttl time.Duration) (string, Token, error) {
	name = strings.TrimSpace(name)
	if accountID < 1 || name == "" || len([]rune(name)) > 80 {
		return "", Token{}, errors.New("a token needs an account and a name of at most 80 characters")
	}
	plain, hash, err := NewToken()
	if err != nil {
		return "", Token{}, err
	}
	t := Token{AccountID: accountID, Name: name, CanWrite: canWrite}
	var expires any
	if ttl > 0 {
		t.ExpiresAt = time.Now().Add(ttl)
		expires = t.ExpiresAt
	}
	err = p.Pool.QueryRow(ctx, `INSERT INTO mcp_tokens (account_id, name, can_write, token_hash, expires_at)
		VALUES ($1, $2, $3, $4, $5) RETURNING id, created_at`, accountID, name, canWrite, hash, expires).Scan(&t.ID, &t.CreatedAt)
	return plain, t, err
}

// Lookup implements Tokens. It stamps last_used_at at most once a minute,
// so a burst of calls does not write the row every time.
func (p *Postgres) Lookup(ctx context.Context, plain string) (Token, error) {
	if !WellFormed(plain) {
		return Token{}, ErrInvalidToken
	}
	var t Token
	var used, expires *time.Time
	err := p.Pool.QueryRow(ctx, `SELECT id, account_id, name, can_write, created_at, last_used_at, expires_at
		FROM mcp_tokens t WHERE token_hash = $1 AND revoked_at IS NULL AND (expires_at IS NULL OR expires_at > now())
		  AND (grant_id IS NULL OR EXISTS (SELECT 1 FROM oauth_grants g WHERE g.id = t.grant_id AND g.account_id = t.account_id AND g.revoked_at IS NULL))`, HashToken(plain)).
		Scan(&t.ID, &t.AccountID, &t.Name, &t.CanWrite, &t.CreatedAt, &used, &expires)
	if errors.Is(err, pgx.ErrNoRows) {
		return Token{}, ErrInvalidToken
	}
	if err != nil {
		return Token{}, fmt.Errorf("%w: %v", ErrUnavailable, err)
	}
	if expires != nil {
		t.ExpiresAt = *expires
	}
	if used == nil || time.Since(*used) > time.Minute {
		if _, err := p.Pool.Exec(ctx, `UPDATE mcp_tokens SET last_used_at = now() WHERE id = $1`, t.ID); err == nil {
			t.LastUsedAt = time.Now()
		}
	} else {
		t.LastUsedAt = *used
	}
	return t, nil
}

// List implements Tokens: the account's tokens, newest first, revoked included.
func (p *Postgres) List(ctx context.Context, accountID int64) ([]Token, error) {
	rows, err := p.Pool.Query(ctx, `SELECT id, account_id, name, can_write, created_at, last_used_at, revoked_at, expires_at
		FROM mcp_tokens WHERE account_id = $1 AND grant_id IS NULL ORDER BY created_at DESC, id DESC LIMIT 100`, accountID)
	if err != nil {
		return nil, err
	}
	return pgx.CollectRows(rows, func(r pgx.CollectableRow) (Token, error) {
		var t Token
		var used, revoked, expires *time.Time
		err := r.Scan(&t.ID, &t.AccountID, &t.Name, &t.CanWrite, &t.CreatedAt, &used, &revoked, &expires)
		if expires != nil {
			t.ExpiresAt = *expires
		}
		if used != nil {
			t.LastUsedAt = *used
		}
		if revoked != nil {
			t.RevokedAt = *revoked
		}
		return t, err
	})
}

// Revoke implements Tokens.
func (p *Postgres) Revoke(ctx context.Context, accountID, id int64) error {
	tag, err := p.Pool.Exec(ctx, `UPDATE mcp_tokens SET revoked_at = now()
		WHERE id = $1 AND account_id = $2 AND revoked_at IS NULL AND grant_id IS NULL`, id, accountID)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return ErrInvalidToken
	}
	return nil
}

// Record implements Auditor.
func (p *Postgres) Record(ctx context.Context, e AuditEntry) error {
	var before []byte
	if e.Before != nil {
		var err error
		if before, err = json.Marshal(e.Before); err != nil {
			return err
		}
	}
	var docID, key, tokenID any
	if e.TokenID > 0 {
		tokenID = e.TokenID
	}
	if e.DocumentID > 0 {
		docID = e.DocumentID
	}
	if e.SourceKey != "" {
		key = e.SourceKey
	}
	_, err := p.Pool.Exec(ctx, `INSERT INTO kb_audit (account_id, document_id, source_key, action, actor, token_id, before)
		VALUES ($1, $2, $3, $4, $5, $6, $7)`, e.AccountID, docID, key, e.Action, e.Actor, tokenID, before)
	return err
}
