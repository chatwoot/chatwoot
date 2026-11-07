package profile

import (
	"context"
	"errors"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// Postgres stores profiles in the business_profiles table, which the
// knowledge base migration creates (schema v2).
type Postgres struct {
	Pool *pgxpool.Pool
}

// Get returns the account's profile, or an empty one when none is saved.
func (s *Postgres) Get(ctx context.Context, accountID int64) (Profile, error) {
	p := Profile{AccountID: accountID}
	err := s.Pool.QueryRow(ctx, `SELECT business_name, about, tone, contact, rules,
		voice_enabled, images_enabled, stickers_enabled, updated_at
		FROM business_profiles WHERE account_id = $1`, accountID).
		Scan(&p.BusinessName, &p.About, &p.Tone, &p.Contact, &p.Rules,
			&p.Features.Voice, &p.Features.Images, &p.Features.Stickers, &p.UpdatedAt)
	if errors.Is(err, pgx.ErrNoRows) {
		return Profile{AccountID: accountID}, nil
	}
	return p, err
}

// Save inserts or replaces the account's profile.
func (s *Postgres) Save(ctx context.Context, p Profile) error {
	if err := p.Validate(); err != nil {
		return err
	}
	_, err := s.Pool.Exec(ctx, `INSERT INTO business_profiles
		(account_id, business_name, about, tone, contact, rules,
		 voice_enabled, images_enabled, stickers_enabled, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, now())
		ON CONFLICT (account_id) DO UPDATE SET business_name = EXCLUDED.business_name,
		about = EXCLUDED.about, tone = EXCLUDED.tone, contact = EXCLUDED.contact,
		rules = EXCLUDED.rules, voice_enabled = EXCLUDED.voice_enabled,
		images_enabled = EXCLUDED.images_enabled, stickers_enabled = EXCLUDED.stickers_enabled,
		updated_at = now()`,
		p.AccountID, p.BusinessName, p.About, p.Tone, p.Contact, p.Rules,
		p.Features.Voice, p.Features.Images, p.Features.Stickers)
	return err
}
