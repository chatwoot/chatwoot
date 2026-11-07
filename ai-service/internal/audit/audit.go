// Package audit records changes made on the admin pages and lists recent
// changes from both the admin pages and AI tools (kb_audit).
package audit

import (
	"context"
	"encoding/json"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// Event is one change.
type Event struct {
	AccountID int64 // 0 for service-wide settings
	Actor     string
	Action    string
	Summary   string
	Before    any // the old version, when something was changed or deleted
	At        time.Time
}

// Store records and lists events.
type Store interface {
	Record(ctx context.Context, e Event) error
	// Recent lists the account's latest changes from the admin pages and
	// from AI tools, newest first.
	Recent(ctx context.Context, accountID int64, limit int) ([]Event, error)
}

// Postgres implements Store (schema v8 admin_events, v5 kb_audit).
type Postgres struct {
	Pool *pgxpool.Pool
}

// Record implements Store.
func (p *Postgres) Record(ctx context.Context, e Event) error {
	var before []byte
	if e.Before != nil {
		var err error
		if before, err = json.Marshal(e.Before); err != nil {
			return err
		}
	}
	var acct any
	if e.AccountID > 0 {
		acct = e.AccountID
	}
	_, err := p.Pool.Exec(ctx, `INSERT INTO admin_events (account_id, actor, action, summary, before) VALUES ($1, $2, $3, $4, $5)`,
		acct, e.Actor, e.Action, e.Summary, before)
	return err
}

// Recent implements Store.
func (p *Postgres) Recent(ctx context.Context, accountID int64, limit int) ([]Event, error) {
	rows, err := p.Pool.Query(ctx, `
		SELECT at, actor, action, summary FROM admin_events WHERE account_id = $1 OR account_id IS NULL
		UNION ALL
		SELECT at, actor, 'knowledge ' || action, COALESCE(before->>'title', source_key, 'document ' || document_id::text, '')
		FROM kb_audit WHERE account_id = $1
		ORDER BY at DESC LIMIT $2`, accountID, max(limit, 1))
	if err != nil {
		return nil, err
	}
	return pgx.CollectRows(rows, func(r pgx.CollectableRow) (Event, error) {
		e := Event{AccountID: accountID}
		err := r.Scan(&e.At, &e.Actor, &e.Action, &e.Summary)
		return e, err
	})
}
