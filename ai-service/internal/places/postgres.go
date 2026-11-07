package places

import (
	"context"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// Postgres implements Store (schema v10).
type Postgres struct {
	Pool *pgxpool.Pool
}

// Record upserts one account/inbox pair. A blank name never replaces a saved one.
func (p *Postgres) Record(ctx context.Context, accountID int64, accountName string, inboxID int64, inboxName string) error {
	_, err := p.Pool.Exec(ctx, `
INSERT INTO chatwoot_inboxes (account_id, inbox_id, account_name, inbox_name, seen_at)
VALUES ($1, $2, $3, $4, now())
ON CONFLICT (account_id, inbox_id) DO UPDATE SET
    account_name = COALESCE(NULLIF(EXCLUDED.account_name, ''), chatwoot_inboxes.account_name),
    inbox_name   = COALESCE(NULLIF(EXCLUDED.inbox_name, ''), chatwoot_inboxes.inbox_name),
    seen_at      = now()`,
		accountID, inboxID, CleanName(accountName), CleanName(inboxName))
	return err
}

// Accounts lists accounts seen in webhooks plus those that already have a
// business profile or knowledge. The name is the latest Chatwoot account
// name, else the business name from the profile, else blank.
func (p *Postgres) Accounts(ctx context.Context) ([]Place, error) {
	rows, err := p.Pool.Query(ctx, `
WITH seen AS (
    SELECT DISTINCT ON (account_id) account_id, account_name
    FROM chatwoot_inboxes
    WHERE account_name <> ''
    ORDER BY account_id, seen_at DESC
), ids AS (
    SELECT account_id FROM chatwoot_inboxes
    UNION SELECT account_id FROM business_profiles
    UNION SELECT DISTINCT account_id FROM kb_documents
)
SELECT ids.account_id, COALESCE(NULLIF(seen.account_name, ''), NULLIF(bp.business_name, ''), '')
FROM ids
LEFT JOIN seen ON seen.account_id = ids.account_id
LEFT JOIN business_profiles bp ON bp.account_id = ids.account_id
ORDER BY ids.account_id
LIMIT 500`)
	if err != nil {
		return nil, err
	}
	return collect(rows)
}

// Inboxes lists the inboxes seen for one account.
func (p *Postgres) Inboxes(ctx context.Context, accountID int64) ([]Place, error) {
	rows, err := p.Pool.Query(ctx, `
SELECT inbox_id, inbox_name FROM chatwoot_inboxes
WHERE account_id = $1
ORDER BY inbox_id
LIMIT 500`, accountID)
	if err != nil {
		return nil, err
	}
	return collect(rows)
}

func collect(rows pgx.Rows) ([]Place, error) {
	return pgx.CollectRows(rows, func(row pgx.CollectableRow) (Place, error) {
		var pl Place
		err := row.Scan(&pl.ID, &pl.Name)
		pl.Name = CleanName(pl.Name)
		return pl, err
	})
}
