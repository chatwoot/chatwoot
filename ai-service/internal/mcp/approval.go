package mcp

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/audit"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/pending"
)

// AI-app edits to what customers are told wait for the owner (#60): the
// write tools store a proposal, and Approve applies it with the same checks
// and history as before. A prompt-injected app can suggest a change but
// cannot make one.

// propose stores an edit for the owner's approval and tells the app so.
func (s *Server) propose(ctx context.Context, tok Token, kind pending.Kind, target string, edit any, changed []string) (any, error) {
	raw, err := json.Marshal(edit)
	if err != nil {
		return nil, err
	}
	id, err := s.Pending.Propose(ctx, pending.Change{AccountID: tok.AccountID, Kind: kind, Target: target,
		Proposed: raw, Actor: tok.Name, TokenID: tok.ID})
	if errors.Is(err, pending.ErrFull) {
		return nil, userError(fmt.Sprintf("not saved: %d changes already wait for the owner's approval; ask them to review those first", pending.MaxPerAccount))
	}
	if err != nil {
		return nil, err
	}
	out := map[string]any{"result": "waiting for approval", "id": id,
		"note": "The owner approves or rejects this on the admin page; until then customers see the current version. " +
			"Sending another change to the same target updates this one."}
	if changed != nil {
		out["changed"] = changed
	}
	return out, nil
}

// Approve applies a waiting change of the account, if it still has the
// version the owner saw, and removes it. approver is who approved (shown in
// the history).
func (s *Server) Approve(ctx context.Context, accountID, id int64, version int, approver string) error {
	c, err := s.Pending.Get(ctx, accountID, id)
	if err != nil {
		return err
	}
	if c.Version != version {
		return pending.ErrChanged
	}
	tok := Token{ID: c.TokenID, AccountID: accountID, Name: c.Actor}
	switch c.Kind {
	case pending.KindProfile:
		err = s.applyProfile(ctx, tok, c.Proposed, approver)
	case pending.KindDocument:
		err = s.applyDocument(ctx, tok, c.Proposed)
	default:
		err = fmt.Errorf("unknown change kind %q", c.Kind)
	}
	if err != nil {
		return err
	}
	// Applied; a newer proposal that arrived meanwhile stays waiting.
	if err := s.Pending.Remove(ctx, accountID, id, version); err != nil && !errors.Is(err, pending.ErrChanged) {
		return err
	}
	if c.Kind == pending.KindDocument {
		s.record(ctx, audit.Event{AccountID: accountID, Actor: approver, Action: "AI change approved",
			Summary: c.Actor + ": knowledge " + c.Target})
	}
	return nil
}

// Reject drops a waiting change of the account and records what it was.
func (s *Server) Reject(ctx context.Context, accountID, id int64, version int, approver string) error {
	c, err := s.Pending.Get(ctx, accountID, id)
	if err != nil {
		return err
	}
	if err := s.Pending.Remove(ctx, accountID, id, version); err != nil {
		return err
	}
	what := "business profile"
	if c.Kind == pending.KindDocument {
		what = "knowledge " + c.Target
	}
	s.record(ctx, audit.Event{AccountID: accountID, Actor: approver, Action: "AI change rejected",
		Summary: c.Actor + ": " + what, Before: c.Proposed})
	return nil
}

// record adds an owner decision to the change history; a failure is logged,
// not returned, because the decision itself already took effect.
func (s *Server) record(ctx context.Context, e audit.Event) {
	if s.Events == nil {
		return
	}
	if err := s.Events.Record(ctx, e); err != nil {
		s.Logger.Error("approval not recorded", "account_id", e.AccountID, "error", err)
	}
}
