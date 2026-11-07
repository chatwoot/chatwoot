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
	last_checked_at, last_changed_at, gone_since, created_at, kind, item_count`

// claimLease is how long a claimed source is left to one checker (longer
// than the slowest check, a 500-row feed).
const claimLease = 15 * time.Minute

func scan(row pgx.Row) (Source, error) {
	var s Source
	var checked, changed, gone *time.Time
	err := row.Scan(&s.ID, &s.AccountID, &s.URL, &s.Title, &s.IntervalHours, &s.ContentHash, &s.Status, &s.Error,
		&checked, &changed, &gone, &s.CreatedAt, &s.Kind, &s.Items)
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

// Add implements Store (at most MaxPages per account).
func (p *Postgres) Add(ctx context.Context, accountID int64, url, kind string) (Source, error) {
	if kind != KindPage && kind != KindFeed {
		return Source{}, errors.New("unknown source kind")
	}
	s, err := scan(p.Pool.QueryRow(ctx, `INSERT INTO web_sources (account_id, url, kind)
		SELECT $1, $2, $4 WHERE (SELECT count(*) FROM web_sources WHERE account_id = $1) < $3
		RETURNING `+columns, accountID, url, MaxPages, kind))
	if pgErr := (*pgconn.PgError)(nil); errors.As(err, &pgErr) && pgErr.Code == "23505" {
		return Source{}, ErrDuplicate
	}
	if errors.Is(err, pgx.ErrNoRows) {
		return Source{}, ErrTooMany
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

// Claim implements Store: due pages are leased (next_check_at pushed past
// the lease) in one statement, so concurrent runs never take the same page.
func (p *Postgres) Claim(ctx context.Context, limit int) ([]Source, error) {
	rows, err := p.Pool.Query(ctx, `UPDATE web_sources SET next_check_at = now() + make_interval(secs => $2),
		checking_until = now() + make_interval(secs => $2)
		WHERE id IN (SELECT id FROM web_sources WHERE (next_check_at IS NULL OR next_check_at <= now())
		               AND (checking_until IS NULL OR checking_until <= now())
		             ORDER BY next_check_at NULLS FIRST LIMIT $1 FOR UPDATE SKIP LOCKED)
		RETURNING `+columns, max(limit, 1), claimLease.Seconds())
	if err != nil {
		return nil, err
	}
	return pgx.CollectRows(rows, func(r pgx.CollectableRow) (Source, error) { return scan(r) })
}

// ClaimOne implements Store.
func (p *Postgres) ClaimOne(ctx context.Context, accountID, id int64) (Source, error) {
	s, err := scan(p.Pool.QueryRow(ctx, `UPDATE web_sources SET next_check_at = now() + make_interval(secs => $3),
		checking_until = now() + make_interval(secs => $3)
		WHERE id = $1 AND account_id = $2 AND (checking_until IS NULL OR checking_until <= now())
		  AND id IN (SELECT id FROM web_sources WHERE id = $1 FOR UPDATE SKIP LOCKED)
		RETURNING `+columns, id, accountID, claimLease.Seconds()))
	if errors.Is(err, pgx.ErrNoRows) {
		if _, getErr := p.Get(ctx, accountID, id); errors.Is(getErr, ErrNotFound) {
			return Source{}, ErrNotFound
		}
		return Source{}, ErrBusy
	}
	return s, err
}

// Save implements Store (the sync result fields only) and schedules the next
// check one interval later.
func (p *Postgres) Save(ctx context.Context, s Source) error {
	tag, err := p.Pool.Exec(ctx, `UPDATE web_sources SET title = $3, content_hash = $4, last_status = $5, last_error = $6,
		last_checked_at = $7, last_changed_at = $8, gone_since = $9, item_count = $10, checking_until = NULL,
		next_check_at = COALESCE($7, now()) + make_interval(hours => interval_hours)
		WHERE id = $1 AND account_id = $2`,
		s.ID, s.AccountID, s.Title, s.ContentHash, s.Status, s.Error, nullTime(s.CheckedAt), nullTime(s.ChangedAt), nullTime(s.GoneSince), max(s.Items, 0))
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return ErrNotFound
	}
	return nil
}

// SetInterval implements Store; the next check moves accordingly.
func (p *Postgres) SetInterval(ctx context.Context, accountID, id int64, hours int) error {
	tag, err := p.Pool.Exec(ctx, `UPDATE web_sources SET interval_hours = $3,
		next_check_at = COALESCE(last_checked_at, now()) + make_interval(hours => $3)
		WHERE id = $1 AND account_id = $2`, id, accountID, hours)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return ErrNotFound
	}
	return nil
}

// MarkAllDue implements Store.
func (p *Postgres) MarkAllDue(ctx context.Context, accountID int64) (int, error) {
	tag, err := p.Pool.Exec(ctx, `UPDATE web_sources SET next_check_at = NULL WHERE account_id = $1`, accountID)
	return int(tag.RowsAffected()), err
}
