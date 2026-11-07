package websync

import (
	"context"
	"errors"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
)

// ErrNotFound means no such source in the account.
var ErrNotFound = errors.New("page not found in the list")

// Postgres implements Store (schema v9).
type Postgres struct {
	Pool *pgxpool.Pool
}

const columns = `id, account_id, url, title, interval_hours, content_hash, last_status, last_error,
	last_checked_at, last_changed_at, gone_since, created_at`

func scan(row pgx.Row) (Source, error) {
	var s Source
	var checked, changed, gone *time.Time
	err := row.Scan(&s.ID, &s.AccountID, &s.URL, &s.Title, &s.IntervalHours, &s.ContentHash, &s.Status, &s.Error,
		&checked, &changed, &gone, &s.CreatedAt)
	if checked != nil {
		s.CheckedAt = *checked
	}
	if changed != nil {
		s.ChangedAt = *changed
	}
	if gone != nil {
		s.GoneSince = *gone
	}
	return s, err
}

func nullTime(t time.Time) any {
	if t.IsZero() {
		return nil
	}
	return t
}

// Add implements Store.
func (p *Postgres) Add(ctx context.Context, accountID int64, url string) (Source, error) {
	s, err := scan(p.Pool.QueryRow(ctx, `INSERT INTO web_sources (account_id, url) VALUES ($1, $2) RETURNING `+columns, accountID, url))
	if pgErr := (*pgconn.PgError)(nil); errors.As(err, &pgErr) && pgErr.Code == "23505" {
		return Source{}, ErrDuplicate
	}
	return s, err
}

// List implements Store.
func (p *Postgres) List(ctx context.Context, accountID int64) ([]Source, error) {
	rows, err := p.Pool.Query(ctx, `SELECT `+columns+` FROM web_sources WHERE account_id = $1 ORDER BY created_at DESC LIMIT 200`, accountID)
	if err != nil {
		return nil, err
	}
	return pgx.CollectRows(rows, func(r pgx.CollectableRow) (Source, error) { return scan(r) })
}

// Get implements Store.
func (p *Postgres) Get(ctx context.Context, accountID, id int64) (Source, error) {
	s, err := scan(p.Pool.QueryRow(ctx, `SELECT `+columns+` FROM web_sources WHERE id = $1 AND account_id = $2`, id, accountID))
	if errors.Is(err, pgx.ErrNoRows) {
		return Source{}, ErrNotFound
	}
	return s, err
}

// Remove implements Store.
func (p *Postgres) Remove(ctx context.Context, accountID, id int64) error {
	tag, err := p.Pool.Exec(ctx, `DELETE FROM web_sources WHERE id = $1 AND account_id = $2`, id, accountID)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return ErrNotFound
	}
	return nil
}

// Due implements Store: never checked, or last checked longer ago than the
// page's interval, oldest first.
func (p *Postgres) Due(ctx context.Context, limit int) ([]Source, error) {
	rows, err := p.Pool.Query(ctx, `SELECT `+columns+` FROM web_sources
		WHERE last_checked_at IS NULL OR last_checked_at < now() - make_interval(hours => interval_hours)
		ORDER BY last_checked_at NULLS FIRST LIMIT $1`, max(limit, 1))
	if err != nil {
		return nil, err
	}
	return pgx.CollectRows(rows, func(r pgx.CollectableRow) (Source, error) { return scan(r) })
}

// Save implements Store (the sync result fields only).
func (p *Postgres) Save(ctx context.Context, s Source) error {
	_, err := p.Pool.Exec(ctx, `UPDATE web_sources SET title = $3, content_hash = $4, last_status = $5, last_error = $6,
		last_checked_at = $7, last_changed_at = $8, gone_since = $9 WHERE id = $1 AND account_id = $2`,
		s.ID, s.AccountID, s.Title, s.ContentHash, s.Status, s.Error, nullTime(s.CheckedAt), nullTime(s.ChangedAt), nullTime(s.GoneSince))
	return err
}
