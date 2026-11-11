package comments

import (
	"context"
	"encoding/json"
	"errors"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
)

// Postgres implements Store on schema v13 (fb_comments).
type Postgres struct {
	Pool *pgxpool.Pool
}

// Add implements Store.
func (p *Postgres) Add(ctx context.Context, c Comment) (bool, error) {
	tag, err := p.Pool.Exec(ctx, `
		INSERT INTO fb_comments (account_id, page_id, comment_id, post_id, parent_id, from_id, from_name, message, created_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
		ON CONFLICT (comment_id) DO NOTHING`,
		c.AccountID, c.PageID, c.CommentID, c.PostID, c.ParentID, c.FromID, c.FromName, c.Message, c.CreatedAt)
	if err != nil {
		return false, permanent(err)
	}
	return tag.RowsAffected() == 1, nil
}

// permanent marks errors a retry cannot fix: the row breaks a check or holds
// a value Postgres cannot store (SQLSTATE classes 22 and 23).
func permanent(err error) error {
	var pg *pgconn.PgError
	if errors.As(err, &pg) && (strings.HasPrefix(pg.Code, "22") || strings.HasPrefix(pg.Code, "23")) {
		return errors.Join(ErrRejected, err)
	}
	return err
}

// Forget implements Store.
func (p *Postgres) Forget(ctx context.Context, c Comment) error {
	_, err := p.Pool.Exec(ctx, `
		INSERT INTO fb_comments (account_id, page_id, comment_id, from_id, created_at, status)
		VALUES ($1, $2, $3, '', now(), 'removed')
		ON CONFLICT (comment_id) DO UPDATE SET status = 'removed', message = '', from_name = '',
			reason = '', draft = '', reply = '', error = '', version = fb_comments.version + 1`,
		c.AccountID, c.PageID, c.CommentID)
	return permanent(err)
}

const columns = `id, account_id, page_id, comment_id, post_id, parent_id, from_id, from_name, message, created_at,
	intent, reason, draft, status, reply, decided_by, coalesce(decided_at, 'epoch'), error, version, attempts, review, received_at`

func scan(r pgx.CollectableRow) (Comment, error) {
	var c Comment
	var review []byte
	err := r.Scan(&c.ID, &c.AccountID, &c.PageID, &c.CommentID, &c.PostID, &c.ParentID, &c.FromID, &c.FromName, &c.Message, &c.CreatedAt,
		&c.Intent, &c.Reason, &c.Draft, &c.Status, &c.Reply, &c.DecidedBy, &c.DecidedAt, &c.Error, &c.Version, &c.Attempts, &review, &c.Received)
	if c.DecidedAt.Equal(time.Unix(0, 0)) {
		c.DecidedAt = time.Time{}
	}
	if err == nil && review != nil {
		var rv Review
		if json.Unmarshal(review, &rv) == nil {
			c.Review = &rv
		}
	}
	return c, err
}

func (p *Postgres) query(ctx context.Context, sql string, args ...any) ([]Comment, error) {
	rows, err := p.Pool.Query(ctx, `SELECT `+columns+` FROM fb_comments `+sql, args...)
	if err != nil {
		return nil, err
	}
	return pgx.CollectRows(rows, scan)
}

// Unscored implements Store.
func (p *Postgres) Unscored(ctx context.Context, limit int) ([]Comment, error) {
	return p.query(ctx, `WHERE status = 'new' ORDER BY attempts, received_at, id LIMIT $1`, limit)
}

// Score implements Store.
func (p *Postgres) Score(ctx context.Context, id int64, intent Intent, reason, draft string) error {
	status := StatusWaiting
	if intent == IntentOther {
		status = StatusIgnored
	}
	tag, err := p.Pool.Exec(ctx, `
		UPDATE fb_comments SET intent = $2, reason = $3, draft = $4, status = $5, version = version + 1
		WHERE id = $1 AND status = 'new'`, id, intent, reason, draft, status)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return ErrNotFound
	}
	return nil
}

// Retry implements Store.
func (p *Postgres) Retry(ctx context.Context, id int64) error {
	tag, err := p.Pool.Exec(ctx, `
		UPDATE fb_comments SET attempts = attempts + 1,
			status  = CASE WHEN attempts + 1 >= $2 THEN 'waiting' ELSE status END,
			reason  = CASE WHEN attempts + 1 >= $2 THEN $3 ELSE reason END,
			version = CASE WHEN attempts + 1 >= $2 THEN version + 1 ELSE version END
		WHERE id = $1 AND status = 'new'`, id, MaxScoreAttempts, UnscoredReason)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return ErrNotFound
	}
	return nil
}

// Waiting implements Store.
func (p *Postgres) Waiting(ctx context.Context, accountID int64) ([]Comment, error) {
	return p.query(ctx, `WHERE account_id = $1 AND status = 'waiting' ORDER BY created_at DESC, id DESC LIMIT $2`, accountID, MaxWaitingShown)
}

// Recent implements Store.
func (p *Postgres) Recent(ctx context.Context, accountID int64, limit int) ([]Comment, error) {
	return p.query(ctx, `WHERE account_id = $1 AND status NOT IN ('new', 'waiting', 'removed')
		ORDER BY coalesce(decided_at, received_at) DESC, id DESC LIMIT $2`, accountID, limit)
}

// Get implements Store.
func (p *Postgres) Get(ctx context.Context, accountID, id int64) (Comment, error) {
	list, err := p.query(ctx, `WHERE account_id = $1 AND id = $2`, accountID, id)
	if err != nil {
		return Comment{}, err
	}
	if len(list) == 0 {
		return Comment{}, ErrNotFound
	}
	return list[0], nil
}

// Claim implements Store.
func (p *Postgres) Claim(ctx context.Context, accountID, id int64, version int) (Comment, error) {
	rows, err := p.Pool.Query(ctx, `WITH claimed AS (
		UPDATE fb_comments SET status = 'sending', version = version + 1
		WHERE account_id = $1 AND id = $2 AND status = 'waiting' AND version = $3 RETURNING *)
		SELECT `+columns+` FROM claimed`, accountID, id, version)
	if err != nil {
		return Comment{}, err
	}
	c, err := pgx.CollectExactlyOneRow(rows, scan)
	if errors.Is(err, pgx.ErrNoRows) {
		return Comment{}, p.missing(ctx, accountID, id)
	}
	return c, err
}

// missing tells ErrChanged (the row exists) from ErrNotFound.
func (p *Postgres) missing(ctx context.Context, accountID, id int64) error {
	if _, err := p.Get(ctx, accountID, id); err != nil {
		return err
	}
	return ErrChanged
}

// Finish implements Store.
func (p *Postgres) Finish(ctx context.Context, id int64, status Status, reply, by, errText string) error {
	var tag interface{ RowsAffected() int64 }
	var err error
	if status == StatusWaiting {
		tag, err = p.Pool.Exec(ctx, `UPDATE fb_comments SET status = 'waiting', error = $2, version = version + 1
			WHERE id = $1 AND status = 'sending'`, id, clip(errText, 500))
	} else {
		tag, err = p.Pool.Exec(ctx, `UPDATE fb_comments SET status = $2, reply = $3, decided_by = $4, decided_at = now(),
			error = $5, version = version + 1 WHERE id = $1 AND status = 'sending'`, id, status, reply, clip(by, 320), clip(errText, 500))
	}
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return ErrNotFound
	}
	return nil
}

// Dismiss implements Store.
func (p *Postgres) Dismiss(ctx context.Context, accountID, id int64, version int, by string) error {
	tag, err := p.Pool.Exec(ctx, `UPDATE fb_comments SET status = 'dismissed', decided_by = $4, decided_at = now(), version = version + 1
		WHERE account_id = $1 AND id = $2 AND status = 'waiting' AND version = $3`, accountID, id, version, clip(by, 320))
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 1 {
		return nil
	}
	return p.missing(ctx, accountID, id)
}

// Purge implements Store.
func (p *Postgres) Purge(ctx context.Context, cutoff time.Time) (int64, error) {
	tag, err := p.Pool.Exec(ctx, `DELETE FROM fb_comments WHERE received_at < $1`, cutoff)
	if err != nil {
		return 0, err
	}
	return tag.RowsAffected(), nil
}

// SaveReview implements Store.
func (p *Postgres) SaveReview(ctx context.Context, id int64, r Review) error {
	raw, err := json.Marshal(r)
	if err != nil {
		return err
	}
	tag, err := p.Pool.Exec(ctx, `UPDATE fb_comments SET review = $2, review_pass = $3 WHERE id = $1`, id, raw, r.Pass)
	if err != nil {
		return permanent(err)
	}
	if tag.RowsAffected() == 0 {
		return ErrNotFound
	}
	return nil
}

// ReviewStats implements Store.
func (p *Postgres) ReviewStats(ctx context.Context, accountID int64) (ReviewStats, error) {
	list, err := p.query(ctx, `WHERE account_id = $1 AND review IS NOT NULL AND status IN ('sent', 'dismissed')`, accountID)
	if err != nil {
		return ReviewStats{}, err
	}
	var s ReviewStats
	for _, c := range list {
		s.add(c)
	}
	return s, nil
}

// LastReplies implements Store.
func (p *Postgres) LastReplies(ctx context.Context, accountID int64, fromIDs []string) (map[string]time.Time, error) {
	out := map[string]time.Time{}
	if len(fromIDs) == 0 {
		return out, nil
	}
	rows, err := p.Pool.Query(ctx, `SELECT from_id, max(decided_at) FROM fb_comments
		WHERE account_id = $1 AND status = 'sent' AND from_id = ANY($2) AND decided_at IS NOT NULL
		GROUP BY from_id`, accountID, fromIDs)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	for rows.Next() {
		var id string
		var at time.Time
		if err := rows.Scan(&id, &at); err != nil {
			return nil, err
		}
		out[id] = at
	}
	return out, rows.Err()
}
