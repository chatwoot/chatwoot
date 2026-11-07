// Package oauth lets AI apps (Claude, ChatGPT, ...) connect to the MCP
// endpoint with OAuth 2.1: dynamic client registration, authorization code
// with PKCE (S256 only), short-lived access tokens and rotating refresh
// tokens. The owner approves each app with the admin password and picks one
// account and read-only or read-write access.
package oauth

import (
	"context"
	"crypto/rand"
	"encoding/base64"
	"errors"
	"time"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/mcp"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// Client is a registered app.
type Client struct {
	ID           string
	Name         string
	RedirectURIs []string
	CreatedAt    time.Time
}

// Code is a one-time authorization code (stored hashed, valid one minute).
type Code struct {
	Hash, ClientID, RedirectURI, Challenge, Resource string
	AccountID                                        int64
	CanWrite                                         bool
	ExpiresAt                                        time.Time
}

// Grant is one app's approved access to one account.
type Grant struct {
	ID               int64
	AccountID        int64
	ClientID         string
	ClientName       string
	CanWrite         bool
	RefreshExpiresAt time.Time
	CreatedAt        time.Time
	LastUsedAt       time.Time
	RevokedAt        time.Time
}

// Errors the handlers turn into OAuth error codes.
var (
	ErrNotFound     = errors.New("not found")
	ErrRefreshReuse = errors.New("refresh token used twice; the connection was revoked")
	ErrCodeReuse    = errors.New("authorization code used twice; the connection it made was revoked")
)

// Store persists clients, codes and grants (schema v6).
type Store interface {
	RegisterClient(ctx context.Context, name string, redirectURIs []string) (Client, error)
	Client(ctx context.Context, id string) (Client, error)
	SaveCode(ctx context.Context, c Code) error
	TakeCode(ctx context.Context, hash string) (Code, error)
	// CreateGrant stores an approved app, links it to the code that made it
	// and issues its first access token.
	CreateGrant(ctx context.Context, g Grant, codeHash, refreshHash string, ttl time.Duration) (Grant, string, error)
	// Refresh rotates the refresh token and issues a new access token, in
	// one transaction.
	Refresh(ctx context.Context, oldHash, newHash, clientID string, expires time.Time, ttl time.Duration) (Grant, string, error)
	RevokeByRefresh(ctx context.Context, hash, clientID string) error
	Grants(ctx context.Context, accountID int64) ([]Grant, error)
	RevokeGrant(ctx context.Context, accountID, id int64) error
}

// random returns n random bytes in unpadded base64url.
func random(n int) string {
	b := make([]byte, n)
	if _, err := rand.Read(b); err != nil {
		panic(err) // crypto/rand never fails on supported platforms
	}
	return base64.RawURLEncoding.EncodeToString(b)
}

// Postgres implements Store.
type Postgres struct {
	Pool *pgxpool.Pool
}

// RegisterClient implements Store. At most 1000 clients are kept: the oldest
// that never completed a sign-in are dropped first.
func (p *Postgres) RegisterClient(ctx context.Context, name string, redirectURIs []string) (Client, error) {
	c := Client{ID: "aisvc_client_" + random(18), Name: name, RedirectURIs: redirectURIs}
	_, _ = p.Pool.Exec(ctx, `DELETE FROM oauth_clients WHERE client_id IN (
		SELECT client_id FROM oauth_clients WHERE last_used_at IS NULL ORDER BY created_at
		LIMIT GREATEST((SELECT count(*) FROM oauth_clients) - 999, 0))`)
	err := p.Pool.QueryRow(ctx, `INSERT INTO oauth_clients (client_id, client_name, redirect_uris)
		VALUES ($1, $2, $3) RETURNING created_at`, c.ID, c.Name, c.RedirectURIs).Scan(&c.CreatedAt)
	return c, err
}

// Client implements Store.
func (p *Postgres) Client(ctx context.Context, id string) (Client, error) {
	c := Client{ID: id}
	err := p.Pool.QueryRow(ctx, `SELECT client_name, redirect_uris, created_at FROM oauth_clients WHERE client_id = $1`, id).
		Scan(&c.Name, &c.RedirectURIs, &c.CreatedAt)
	if errors.Is(err, pgx.ErrNoRows) {
		return Client{}, ErrNotFound
	}
	return c, err
}

// SaveCode implements Store (and clears codes expired over a day ago).
func (p *Postgres) SaveCode(ctx context.Context, c Code) error {
	_, _ = p.Pool.Exec(ctx, `DELETE FROM oauth_codes WHERE expires_at < now() - interval '1 day'`)
	_, err := p.Pool.Exec(ctx, `INSERT INTO oauth_codes (code_hash, client_id, redirect_uri, code_challenge, account_id, can_write, resource, expires_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`, c.Hash, c.ClientID, c.RedirectURI, c.Challenge, c.AccountID, c.CanWrite, c.Resource, c.ExpiresAt)
	return err
}

// TakeCode implements Store: a code works once, even if the exchange then
// fails. Presenting a used code again revokes the connection it created
// (OAuth 2.1 §4.1.3).
func (p *Postgres) TakeCode(ctx context.Context, hash string) (Code, error) {
	c := Code{Hash: hash}
	err := p.Pool.QueryRow(ctx, `UPDATE oauth_codes SET used_at = now()
		WHERE code_hash = $1 AND used_at IS NULL AND expires_at > now()
		RETURNING client_id, redirect_uri, code_challenge, account_id, can_write, resource, expires_at`, hash).
		Scan(&c.ClientID, &c.RedirectURI, &c.Challenge, &c.AccountID, &c.CanWrite, &c.Resource, &c.ExpiresAt)
	if err == nil {
		return c, nil
	}
	if !errors.Is(err, pgx.ErrNoRows) {
		return Code{}, err
	}
	var grantID *int64
	err = p.Pool.QueryRow(ctx, `SELECT grant_id FROM oauth_codes WHERE code_hash = $1 AND used_at IS NOT NULL`, hash).Scan(&grantID)
	if errors.Is(err, pgx.ErrNoRows) {
		return Code{}, ErrNotFound
	}
	if err != nil {
		return Code{}, err
	}
	if grantID != nil {
		if err := p.revokeWhere(ctx, `id = $1`, *grantID); err != nil && !errors.Is(err, ErrNotFound) {
			return Code{}, err
		}
	}
	return Code{}, ErrCodeReuse
}

// reuseGrace: a refresh token presented again within this time of its
// rotation is treated as a client retry or parallel request, not a leak.
const reuseGrace = 30 * time.Second

// CreateGrant implements Store. It also prunes the account's grants that
// were revoked or expired more than 30 days ago.
func (p *Postgres) CreateGrant(ctx context.Context, g Grant, codeHash, refreshHash string, ttl time.Duration) (Grant, string, error) {
	tx, err := p.Pool.Begin(ctx)
	if err != nil {
		return Grant{}, "", err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	if _, err := tx.Exec(ctx, `DELETE FROM oauth_grants WHERE account_id = $1
		AND (revoked_at < now() - interval '30 days' OR refresh_expires_at < now() - interval '30 days')`, g.AccountID); err != nil {
		return Grant{}, "", err
	}
	if err := tx.QueryRow(ctx, `INSERT INTO oauth_grants (account_id, client_id, client_name, can_write, refresh_hash, refresh_expires_at)
		VALUES ($1, $2, $3, $4, $5, $6) RETURNING id, created_at`, g.AccountID, g.ClientID, g.ClientName, g.CanWrite, refreshHash, g.RefreshExpiresAt).
		Scan(&g.ID, &g.CreatedAt); err != nil {
		return Grant{}, "", err
	}
	if _, err := tx.Exec(ctx, `UPDATE oauth_clients SET last_used_at = now() WHERE client_id = $1`, g.ClientID); err != nil {
		return Grant{}, "", err
	}
	if _, err := tx.Exec(ctx, `UPDATE oauth_codes SET grant_id = $2 WHERE code_hash = $1`, codeHash, g.ID); err != nil {
		return Grant{}, "", err
	}
	access, err := issueAccess(ctx, tx, g, ttl)
	if err != nil {
		return Grant{}, "", err
	}
	return g, access, tx.Commit(ctx)
}

const grantColumns = `id, account_id, client_id, client_name, can_write, refresh_expires_at, created_at, last_used_at, revoked_at`

func scanGrant(row pgx.Row) (Grant, error) {
	var g Grant
	var used, revoked *time.Time
	err := row.Scan(&g.ID, &g.AccountID, &g.ClientID, &g.ClientName, &g.CanWrite, &g.RefreshExpiresAt, &g.CreatedAt, &used, &revoked)
	if used != nil {
		g.LastUsedAt = *used
	}
	if revoked != nil {
		g.RevokedAt = *revoked
	}
	return g, err
}

// revokeTokens marks a grant's access tokens revoked too, so code that only
// checks mcp_tokens (an older binary during a rollout) also refuses them.
func revokeTokens(ctx context.Context, tx pgx.Tx, grantID int64) error {
	_, err := tx.Exec(ctx, `UPDATE mcp_tokens SET revoked_at = now() WHERE grant_id = $1 AND revoked_at IS NULL`, grantID)
	return err
}

// Refresh implements Store. Presenting the previous refresh token again,
// more than reuseGrace after it was rotated, means it was copied: the whole
// grant is revoked (OAuth 2.1 §4.3.1).
func (p *Postgres) Refresh(ctx context.Context, oldHash, newHash, clientID string, expires time.Time, ttl time.Duration) (Grant, string, error) {
	tx, err := p.Pool.Begin(ctx)
	if err != nil {
		return Grant{}, "", err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	g, err := scanGrant(tx.QueryRow(ctx, `UPDATE oauth_grants
		SET prev_refresh_hash = refresh_hash, refresh_hash = $2, refresh_expires_at = $4, last_used_at = now(), rotated_at = now(),
		    used_refresh = (array_append(used_refresh, refresh_hash))[greatest(cardinality(used_refresh) - 18, 1):]
		WHERE refresh_hash = $1 AND client_id = $3 AND revoked_at IS NULL AND refresh_expires_at > now()
		RETURNING `+grantColumns, oldHash, newHash, clientID, expires))
	if err == nil {
		access, err := issueAccess(ctx, tx, g, ttl)
		if err != nil {
			return Grant{}, "", err
		}
		return g, access, tx.Commit(ctx)
	}
	if !errors.Is(err, pgx.ErrNoRows) {
		return Grant{}, "", err
	}
	var id int64
	// The token just replaced, presented again within the grace period: a
	// retry or a parallel call, refused without revoking. Any other used
	// token (older, or after the grace period) means it was copied.
	err = tx.QueryRow(ctx, `UPDATE oauth_grants SET revoked_at = now()
		WHERE client_id = $2 AND revoked_at IS NULL AND $1 = ANY(used_refresh)
		  AND NOT (prev_refresh_hash = $1 AND rotated_at >= now() - make_interval(secs => $3))
		RETURNING id`, oldHash, clientID, reuseGrace.Seconds()).Scan(&id)
	if errors.Is(err, pgx.ErrNoRows) {
		return Grant{}, "", ErrNotFound
	}
	if err != nil {
		return Grant{}, "", err
	}
	if err := revokeTokens(ctx, tx, id); err != nil {
		return Grant{}, "", err
	}
	if err := tx.Commit(ctx); err != nil {
		return Grant{}, "", err
	}
	return Grant{}, "", ErrRefreshReuse
}

// RevokeByRefresh implements Store (RFC 7009: unknown tokens are not an error).
func (p *Postgres) RevokeByRefresh(ctx context.Context, hash, clientID string) error {
	return p.revokeWhere(ctx, `refresh_hash = $1 AND client_id = $2`, hash, clientID)
}

func (p *Postgres) revokeWhere(ctx context.Context, where string, args ...any) error {
	tx, err := p.Pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	var id int64
	err = tx.QueryRow(ctx, `UPDATE oauth_grants SET revoked_at = now() WHERE `+where+` AND revoked_at IS NULL RETURNING id`, args...).Scan(&id)
	if errors.Is(err, pgx.ErrNoRows) {
		return ErrNotFound
	}
	if err != nil {
		return err
	}
	if err := revokeTokens(ctx, tx, id); err != nil {
		return err
	}
	return tx.Commit(ctx)
}

// issueAccess inserts an MCP access token tied to the grant and drops the
// grant's tokens that expired over a day ago.
func issueAccess(ctx context.Context, tx pgx.Tx, g Grant, ttl time.Duration) (string, error) {
	plain, hash, err := mcp.NewToken()
	if err != nil {
		return "", err
	}
	if _, err := tx.Exec(ctx, `DELETE FROM mcp_tokens WHERE grant_id = $1 AND expires_at < now() - interval '1 day'`, g.ID); err != nil {
		return "", err
	}
	_, err = tx.Exec(ctx, `INSERT INTO mcp_tokens (account_id, name, can_write, token_hash, expires_at, grant_id)
		VALUES ($1, $2, $3, $4, $5, $6)`, g.AccountID, g.ClientName, g.CanWrite, hash, time.Now().Add(ttl), g.ID)
	return plain, err
}

// Grants implements Store: the account's connected apps, newest first.
func (p *Postgres) Grants(ctx context.Context, accountID int64) ([]Grant, error) {
	rows, err := p.Pool.Query(ctx, `SELECT `+grantColumns+` FROM oauth_grants WHERE account_id = $1
		ORDER BY revoked_at IS NOT NULL, created_at DESC LIMIT 100`, accountID)
	if err != nil {
		return nil, err
	}
	return pgx.CollectRows(rows, func(r pgx.CollectableRow) (Grant, error) { return scanGrant(r) })
}

// RevokeGrant implements Store; its access tokens stop working at once.
func (p *Postgres) RevokeGrant(ctx context.Context, accountID, id int64) error {
	return p.revokeWhere(ctx, `id = $1 AND account_id = $2`, id, accountID)
}
