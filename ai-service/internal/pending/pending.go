// Package pending keeps AI-app edits that wait for the owner's approval.
//
// An AI app connected over MCP may propose a change to the business profile
// or a knowledge document. The change reaches customers only after the owner
// approves it on /admin, so a prompt-injected app cannot change what
// customers are told on its own. Issue: DEV-Johnstocker/chatwoot#60 (refs #1)
package pending

import (
	"context"
	"encoding/json"
	"errors"
	"time"
)

// Kind is what a change edits.
type Kind string

// Kinds.
const (
	KindProfile  Kind = "profile"  // business profile fields
	KindDocument Kind = "document" // one knowledge document, by key
)

// ProfileTarget is the Target of every profile change: one per account.
const ProfileTarget = "profile"

// MaxPerAccount caps waiting changes per account, so an app cannot flood the
// owner's list. Updating a target that is already waiting does not count.
const MaxPerAccount = 50

// Errors.
var (
	ErrFull     = errors.New("too many changes are waiting for approval")
	ErrNotFound = errors.New("change not found")
	// ErrChanged means the app changed the proposal after the owner looked
	// at it; the owner must look again.
	ErrChanged = errors.New("the change was updated after you opened it")
)

// Change is one waiting edit.
type Change struct {
	ID        int64
	AccountID int64
	Kind      Kind
	// Target is ProfileTarget, or the document key.
	Target string
	// Proposed is the edit as JSON: profile fields that change, or the
	// document as the app sent it.
	Proposed json.RawMessage
	Actor    string // the AI app's name
	TokenID  int64
	Version  int
	At       time.Time
}

// Store keeps waiting changes. Every method is scoped to one account.
type Store interface {
	// Propose adds a change, or updates the one already waiting for the same
	// target: profile fields merge (newer wins per field), a document is
	// replaced. Either way Version goes up. It returns the change's id.
	Propose(ctx context.Context, c Change) (int64, error)
	// List returns the account's waiting changes, oldest first.
	List(ctx context.Context, accountID int64) ([]Change, error)
	// Get returns one waiting change.
	Get(ctx context.Context, accountID, id int64) (Change, error)
	// Remove deletes the change if it still has this version: ErrChanged if
	// the app updated it since, ErrNotFound if it is gone.
	Remove(ctx context.Context, accountID, id int64, version int) error
	// Count is how many changes wait for the account.
	Count(ctx context.Context, accountID int64) (int, error)
}
