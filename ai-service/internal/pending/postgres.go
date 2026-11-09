package pending

import (
	"context"
	"errors"
	"fmt"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// Postgres implements Store on schema v12 (ai_pending_changes).
type Postgres struct {
	Pool *pgxpool.Pool
}

// Propose implements Store.
func (p *Postgres) Propose(ctx context.Context, c Change) (int64, error) {
	if c.Kind != KindProfile && c.Kind != KindDocument {
		return 0, fmt.Errorf("unknown change kind %q", c.Kind)
	}
	tx, err := p.Pool.Begin(ctx)
	if err != nil {
		return 0, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck // no-op after commit
	// One proposer per account at a time, so the cap cannot be raced.
	if _, err := tx.Exec(ctx, "SELECT pg_advisory_xact_lock(hashtext('ai_pending_changes'), $1::int)", int32(c.AccountID)); err != nil {
		return 0, err
	}
	var waiting int
	var exists bool
	if err := tx.QueryRow(ctx, `SELECT count(*), coalesce(bool_or(kind = $2 AND target = $3), false)
		FROM ai_pending_changes WHERE account_id = $1`, c.AccountID, c.Kind, c.Target).Scan(&waiting, &exists); err != nil {
		return 0, err
	}
	if !exists && waiting >= MaxPerAccount {
		return 0, ErrFull
	}
	var tok any
	if c.TokenID > 0 {
		tok = c.TokenID
	}
	var id int64
	err = tx.QueryRow(ctx, `
		INSERT INTO ai_pending_changes (account_id, kind, target, proposed, actor, token_id)
		VALUES ($1, $2, $3, $4, $5, $6)
		ON CONFLICT (account_id, kind, target) DO UPDATE SET
			proposed = CASE WHEN ai_pending_changes.kind = 'profile'
			                THEN ai_pending_changes.proposed || EXCLUDED.proposed
			                ELSE EXCLUDED.proposed END,
			actor    = CASE WHEN position(', ' || EXCLUDED.actor || ', ' in ', ' || ai_pending_changes.actor || ', ') > 0
			                THEN ai_pending_changes.actor
			                ELSE left(ai_pending_changes.actor || ', ' || EXCLUDED.actor, 512) END,
			token_id = EXCLUDED.token_id,
			version  = ai_pending_changes.version + 1,
			at       = now()
		RETURNING id`, c.AccountID, c.Kind, c.Target, []byte(c.Proposed), c.Actor, tok).Scan(&id)
	if err != nil {
		return 0, err
	}
	return id, tx.Commit(ctx)
}

const columns = `id, account_id, kind, target, proposed, actor, coalesce(token_id, 0), version, at`

func scan(r pgx.CollectableRow) (Change, error) {
	var c Change
	var proposed []byte
	err := r.Scan(&c.ID, &c.AccountID, &c.Kind, &c.Target, &proposed, &c.Actor, &c.TokenID, &c.Version, &c.At)
	c.Proposed = proposed
	return c, err
}

// List implements Store.
func (p *Postgres) List(ctx context.Context, accountID int64) ([]Change, error) {
	rows, err := p.Pool.Query(ctx, `SELECT `+columns+` FROM ai_pending_changes WHERE account_id = $1 ORDER BY at, id`, accountID)
	if err != nil {
		return nil, err
	}
	return pgx.CollectRows(rows, scan)
}

// Get implements Store.
func (p *Postgres) Get(ctx context.Context, accountID, id int64) (Change, error) {
	rows, err := p.Pool.Query(ctx, `SELECT `+columns+` FROM ai_pending_changes WHERE account_id = $1 AND id = $2`, accountID, id)
	if err != nil {
		return Change{}, err
	}
	c, err := pgx.CollectExactlyOneRow(rows, scan)
	if errors.Is(err, pgx.ErrNoRows) {
		return Change{}, ErrNotFound
	}
	return c, err
}

// Remove implements Store.
func (p *Postgres) Remove(ctx context.Context, accountID, id int64, version int) error {
	var current int
	err := p.Pool.QueryRow(ctx, `
		WITH gone AS (DELETE FROM ai_pending_changes WHERE account_id = $1 AND id = $2 AND version = $3 RETURNING version)
		SELECT coalesce((SELECT version FROM gone), (SELECT -version FROM ai_pending_changes WHERE account_id = $1 AND id = $2), 0)`,
		accountID, id, version).Scan(&current)
	switch {
	case err != nil:
		return err
	case current > 0:
		return nil
	case current < 0:
		return ErrChanged
	}
	return ErrNotFound
}

// Count implements Store.
func (p *Postgres) Count(ctx context.Context, accountID int64) (int, error) {
	var n int
	err := p.Pool.QueryRow(ctx, `SELECT count(*) FROM ai_pending_changes WHERE account_id = $1`, accountID).Scan(&n)
	return n, err
}
