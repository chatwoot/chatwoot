// Package audit records changes made on the admin pages and lists recent
// changes from both the admin pages and AI tools (kb_audit).
package audit

import (
	"context"
	"encoding/json"
	"sync"
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
	// RetentionDays: entries older than this are deleted from both logs
	// (they can hold old document text); 0 keeps everything.
	RetentionDays int

	mu     sync.Mutex
	pruned time.Time
}

// prune deletes old entries at most once an hour.
func (p *Postgres) prune(ctx context.Context) {
	if p.RetentionDays <= 0 {
		return
	}
	p.mu.Lock()
	due := time.Since(p.pruned) > time.Hour
	if due {
		p.pruned = time.Now()
	}
	p.mu.Unlock()
	if !due {
		return
	}
	for _, table := range []string{"admin_events", "kb_audit"} {
		_, _ = p.Pool.Exec(ctx, `DELETE FROM `+table+` WHERE at < now() - make_interval(days => $1)`, p.RetentionDays)
	}
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
	p.prune(ctx)
	_, err := p.Pool.Exec(ctx, `INSERT INTO admin_events (account_id, actor, action, summary, before) VALUES ($1, $2, $3, $4, $5)`,
		acct, e.Actor, e.Action, e.Summary, before)
	return err
}

// Recent implements Store.
func (p *Postgres) Recent(ctx context.Context, accountID int64, limit int) ([]Event, error) {
	// Each branch reads its index in order and stops at the limit.
	rows, err := p.Pool.Query(ctx, `
		SELECT at, actor, action, summary FROM (
			(SELECT at, id, 1 AS src, actor, action, summary FROM admin_events WHERE account_id = $1 ORDER BY at DESC, id DESC LIMIT $2)
			UNION ALL
			(SELECT at, id, 2, actor, action, summary FROM admin_events WHERE account_id IS NULL ORDER BY at DESC, id DESC LIMIT $2)
			UNION ALL
			(SELECT at, id, 3,
			        CASE WHEN actor LIKE 'mcp:%' THEN substr(actor, 5) || ' (AI tool)' ELSE actor END,
			        CASE action WHEN 'create' THEN 'knowledge added' WHEN 'update' THEN 'knowledge edited' ELSE 'knowledge deleted' END,
			        COALESCE(before->>'title', source_key, 'document ' || document_id::text, '')
			   FROM kb_audit WHERE account_id = $1 ORDER BY at DESC, id DESC LIMIT $2)
		) e ORDER BY at DESC, src, id DESC LIMIT $2`, accountID, max(limit, 1))
	if err != nil {
		return nil, err
	}
	return pgx.CollectRows(rows, func(r pgx.CollectableRow) (Event, error) {
		e := Event{AccountID: accountID}
		err := r.Scan(&e.At, &e.Actor, &e.Action, &e.Summary)
		return e, err
	})
}
