package mcp

// Tools for the business profile, the synced website pages and data files,
// and the change history. Each acts only on the token's own account. Provider
// keys, MCP tokens and connected apps are deliberately not exposed: they stay
// behind the /admin login, so a prompt-injected AI app cannot take over the bot.

import (
	"context"
	"errors"
	"fmt"
	"net/url"
	"slices"
	"strconv"
	"strings"
	"time"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/audit"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/profile"
	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/websync"
)

// Sources is the part of websync.Store the source tools use.
type Sources interface {
	List(ctx context.Context, accountID int64) ([]websync.Source, error)
	Get(ctx context.Context, accountID, id int64) (websync.Source, error)
	ClaimOne(ctx context.Context, accountID, id int64) (websync.Source, error)
	SetInterval(ctx context.Context, accountID, id int64, hours int) error
}

// Checker runs a source check now (websync.Syncer).
type Checker interface {
	Check(ctx context.Context, src websync.Source) (websync.Outcome, error)
	CheckLater(ctx context.Context, src websync.Source)
}

const maxChanges = 50

func boolean(desc string) map[string]any {
	return map[string]any{"type": "boolean", "description": desc}
}

var sourceID = map[string]any{"type": "integer", "description": "The source ID from list_sources."}

var adminTools = []tool{
	{Name: "get_profile", Title: "Read the business profile",
		Description: "The business profile the support bot follows: name, about, tone, how customers buy or reach staff, rules, and which message types it answers (voice notes, images, stickers).",
		InputSchema: obj(map[string]any{}), Annotations: map[string]any{"readOnlyHint": true}},
	{Name: "update_profile", Title: "Change the business profile", write: true,
		Description: "Change fields of the business profile. Only the fields you give change; the rest stay. " +
			"Read it with get_profile first and send the full new text of a field (this replaces it, it does not append). " +
			"The old version is kept in the change history. Use test_bot afterwards to check the bot's replies.",
		InputSchema: obj(map[string]any{
			"business_name": str("Business name (up to 120 characters)."),
			"about":         str("What the business sells or does."),
			"tone":          str("Voice, persona and language preferences."),
			"contact":       str("How customers buy, pay or reach staff."),
			"rules":         str("Do and don't rules for the bot."),
			"voice_notes":   boolean("Transcribe and answer customers' voice notes."),
			"images":        boolean("Let the bot look at photos and screenshots."),
			"stickers":      boolean("Answer stickers and likes briefly instead of handing off."),
		}),
		Annotations: map[string]any{"destructiveHint": false, "idempotentHint": true}},
	{Name: "list_sources", Title: "List website pages and data files",
		Description: "Website pages and data files (Google Sheets, CSV) the knowledge base is kept in sync with: ID, kind, address, title, status, last error, schedule in hours, rows (data files), last check and last change. Their documents have keys starting with web: or feed: and are changed by editing the source, not with upsert_document.",
		InputSchema: obj(map[string]any{}), Annotations: map[string]any{"readOnlyHint": true}},
	{Name: "sync_source", Title: "Sync a page or data file now", write: true,
		Description: "Check one website page or data file now instead of waiting for its schedule, for example after the owner edited the Google Sheet. " +
			"A web page is checked at once; a data file is checked in the background (use list_sources a minute later to see the result).",
		InputSchema: obj(map[string]any{"id": sourceID}, "id"),
		Annotations: map[string]any{"destructiveHint": false, "idempotentHint": true}},
	{Name: "set_source_schedule", Title: "Change how often a source is checked", write: true,
		Description: "Change how often a website page or data file is checked: every 1, 6, 24 (daily) or 168 (weekly) hours.",
		InputSchema: obj(map[string]any{"id": sourceID,
			"hours": map[string]any{"type": "integer", "enum": websync.Intervals, "description": "Hours between checks."}}, "id", "hours"),
		Annotations: map[string]any{"destructiveHint": false, "idempotentHint": true}},
	{Name: "list_changes", Title: "Recent changes",
		Description: "The latest changes to this account, newest first: who (a person or an AI tool), what and when. Old text is not included.",
		InputSchema: obj(map[string]any{"limit": map[string]any{"type": "integer", "minimum": 1, "maximum": maxChanges, "description": "How many changes; default 20."}}),
		Annotations: map[string]any{"readOnlyHint": true}},
}

// available reports whether the stores a tool needs are set.
func (s *Server) available(name string) bool {
	switch name {
	case "test_bot":
		return s.Tester != nil
	case "get_profile":
		return s.Profiles != nil
	case "update_profile":
		return s.Profiles != nil && s.Events != nil
	case "list_sources":
		return s.Sources != nil
	case "sync_source":
		return s.Sources != nil && s.Checker != nil
	case "set_source_schedule":
		return s.Sources != nil && s.Events != nil
	case "list_changes":
		return s.Events != nil
	}
	return true
}

// callAdminTool runs one of adminTools; ok is false for other names.
func (s *Server) callAdminTool(ctx context.Context, tok Token, name string, decode func(any) error) (out any, ok bool, err error) {
	switch name {
	case "get_profile":
		var a struct{}
		if err = decode(&a); err == nil {
			out, err = s.getProfile(ctx, tok)
		}
	case "update_profile":
		var a profileArgs
		if err = decode(&a); err == nil {
			out, err = s.updateProfile(ctx, tok, a)
		}
	case "list_sources":
		var a struct{}
		if err = decode(&a); err == nil {
			out, err = s.listSources(ctx, tok)
		}
	case "sync_source":
		var a struct {
			ID int64 `json:"id"`
		}
		if err = decode(&a); err == nil {
			out, err = s.syncSource(ctx, tok, a.ID)
		}
	case "set_source_schedule":
		var a struct {
			ID    int64 `json:"id"`
			Hours int   `json:"hours"`
		}
		if err = decode(&a); err == nil {
			out, err = s.setSchedule(ctx, tok, a.ID, a.Hours)
		}
	case "list_changes":
		var a struct {
			Limit int `json:"limit"`
		}
		if err = decode(&a); err == nil {
			out, err = s.listChanges(ctx, tok, a.Limit)
		}
	default:
		return nil, false, nil
	}
	return out, true, err
}

// actorName is how AI tool changes appear in the change history.
func actorName(tok Token) string { return tok.Name + " (AI tool)" }

// --- business profile ---

type profileView struct {
	BusinessName string `json:"business_name"`
	About        string `json:"about"`
	Tone         string `json:"tone"`
	Contact      string `json:"contact"`
	Rules        string `json:"rules"`
	VoiceNotes   bool   `json:"voice_notes"`
	Images       bool   `json:"images"`
	Stickers     bool   `json:"stickers"`
	Updated      string `json:"updated,omitempty"`
}

func (s *Server) profileView(p profile.Profile) profileView {
	v := profileView{BusinessName: p.BusinessName, About: p.About, Tone: p.Tone, Contact: p.Contact, Rules: p.Rules,
		VoiceNotes: p.Features.Voice, Images: p.Features.Images, Stickers: p.Features.Stickers}
	if !p.UpdatedAt.IsZero() {
		v.Updated = p.UpdatedAt.In(s.loc()).Format(time.DateOnly)
	}
	return v
}

func (s *Server) getProfile(ctx context.Context, tok Token) (any, error) {
	p, err := s.Profiles.Get(ctx, tok.AccountID)
	if err != nil {
		return nil, err
	}
	return s.profileView(p), nil
}

type profileArgs struct {
	BusinessName *string `json:"business_name"`
	About        *string `json:"about"`
	Tone         *string `json:"tone"`
	Contact      *string `json:"contact"`
	Rules        *string `json:"rules"`
	VoiceNotes   *bool   `json:"voice_notes"`
	Images       *bool   `json:"images"`
	Stickers     *bool   `json:"stickers"`
}

// apply sets the given fields on p and returns the names of those given.
func (a profileArgs) apply(p *profile.Profile) []string {
	var given []string
	setStr := func(name string, v *string, dst *string) {
		if v != nil {
			*dst = *v
			given = append(given, name)
		}
	}
	setBool := func(name string, v *bool, dst *bool) {
		if v != nil {
			*dst = *v
			given = append(given, name)
		}
	}
	setStr("business_name", a.BusinessName, &p.BusinessName)
	setStr("about", a.About, &p.About)
	setStr("tone", a.Tone, &p.Tone)
	setStr("contact", a.Contact, &p.Contact)
	setStr("rules", a.Rules, &p.Rules)
	setBool("voice_notes", a.VoiceNotes, &p.Features.Voice)
	setBool("images", a.Images, &p.Features.Images)
	setBool("stickers", a.Stickers, &p.Features.Stickers)
	return given
}

func (s *Server) updateProfile(ctx context.Context, tok Token, a profileArgs) (any, error) {
	cur, err := s.Profiles.Get(ctx, tok.AccountID)
	if err != nil {
		return nil, err
	}
	next := cur
	next.AccountID = tok.AccountID
	given := a.apply(&next)
	if len(given) == 0 {
		return nil, userError("give at least one field to change")
	}
	next = next.Normalize()
	if err := next.Validate(); err != nil {
		return nil, userError(err.Error())
	}
	var changed []string
	for _, f := range given {
		if profileField(cur, f) != profileField(next, f) {
			changed = append(changed, f)
		}
	}
	if len(changed) == 0 {
		return map[string]any{"result": "unchanged"}, nil
	}
	// History first: if the old version cannot be kept, nothing changes.
	if err := s.Events.Record(ctx, audit.Event{AccountID: tok.AccountID, Actor: actorName(tok), Action: "business profile saved",
		Summary: "changed " + strings.Join(changed, ", "), Before: s.profileView(cur)}); err != nil {
		return nil, fmt.Errorf("%w: %w", userError("not saved: the change history could not be stored; try again"), err)
	}
	if err := s.Profiles.Save(ctx, next); err != nil {
		return nil, err
	}
	return map[string]any{"result": "saved", "changed": changed}, nil
}

func profileField(p profile.Profile, name string) string {
	v := map[string]string{"business_name": p.BusinessName, "about": p.About, "tone": p.Tone, "contact": p.Contact, "rules": p.Rules,
		"voice_notes": strconv.FormatBool(p.Features.Voice), "images": strconv.FormatBool(p.Features.Images),
		"stickers": strconv.FormatBool(p.Features.Stickers)}
	return v[name]
}

// --- website pages and data files ---

type sourceView struct {
	ID            int64  `json:"id"`
	Kind          string `json:"kind"`
	Address       string `json:"address"`
	Title         string `json:"title,omitempty"`
	Status        string `json:"status"`
	Error         string `json:"error,omitempty"`
	ScheduleHours int    `json:"schedule_hours"`
	Rows          int    `json:"rows,omitempty"`
	Checked       string `json:"checked,omitempty"`
	Changed       string `json:"changed,omitempty"`
}

// address is host and path only: a query string can carry an access key.
func address(raw string) string {
	u, err := url.Parse(raw)
	if err != nil {
		return ""
	}
	return u.Host + u.Path
}

func (s *Server) sourceView(src websync.Source) sourceView {
	v := sourceView{ID: src.ID, Kind: src.Kind, Address: address(src.URL), Title: src.Title, Status: src.Status,
		Error: src.Error, ScheduleHours: src.IntervalHours}
	if v.Kind == "" {
		v.Kind = websync.KindPage
	}
	if src.IsFeed() {
		v.Rows = src.Items
	}
	if !src.CheckedAt.IsZero() {
		v.Checked = src.CheckedAt.In(s.loc()).Format("2006-01-02 15:04")
	}
	if !src.ChangedAt.IsZero() {
		v.Changed = src.ChangedAt.In(s.loc()).Format("2006-01-02 15:04")
	}
	return v
}

func (s *Server) listSources(ctx context.Context, tok Token) (any, error) {
	srcs, err := s.Sources.List(ctx, tok.AccountID)
	if err != nil {
		return nil, err
	}
	out := []sourceView{}
	for _, src := range srcs {
		out = append(out, s.sourceView(src))
	}
	return map[string]any{"count": len(out), "sources": out}, nil
}

var errNoSource = userError("no source with that id in this account; use list_sources")

func (s *Server) syncSource(ctx context.Context, tok Token, id int64) (any, error) {
	src, err := s.Sources.ClaimOne(ctx, tok.AccountID, id)
	switch {
	case errors.Is(err, websync.ErrBusy):
		return nil, userError("that source is already being checked; try again in a minute")
	case err != nil:
		return nil, errNoSource
	}
	if src.IsFeed() {
		s.Checker.CheckLater(ctx, src)
		return map[string]any{"result": "started", "id": src.ID, "note": "the data file is checked in the background; call list_sources in a minute"}, nil
	}
	outcome, err := s.Checker.Check(ctx, src)
	res := map[string]any{"result": string(outcome), "id": src.ID}
	if err != nil {
		res["error"] = "the page could not be read; the last version stays"
	}
	return res, nil
}

func (s *Server) setSchedule(ctx context.Context, tok Token, id int64, hours int) (any, error) {
	if !slices.Contains(websync.Intervals, hours) {
		return nil, userError("hours must be 1, 6, 24 or 168")
	}
	src, err := s.Sources.Get(ctx, tok.AccountID, id)
	if err != nil {
		return nil, errNoSource
	}
	if src.IntervalHours == hours {
		return map[string]any{"result": "unchanged", "id": id, "schedule_hours": hours}, nil
	}
	if err := s.Events.Record(ctx, audit.Event{AccountID: tok.AccountID, Actor: actorName(tok), Action: "web page schedule changed",
		Summary: fmt.Sprintf("%s: %d h", src.Title, hours), Before: map[string]any{"schedule_hours": src.IntervalHours}}); err != nil {
		return nil, fmt.Errorf("%w: %w", userError("not changed: the change history could not be stored; try again"), err)
	}
	if err := s.Sources.SetInterval(ctx, tok.AccountID, id, hours); err != nil {
		return nil, errNoSource
	}
	return map[string]any{"result": "changed", "id": id, "schedule_hours": hours}, nil
}

// --- change history ---

type changeView struct {
	At     string `json:"at"`
	Who    string `json:"who"`
	What   string `json:"what"`
	Detail string `json:"detail,omitempty"`
}

func (s *Server) listChanges(ctx context.Context, tok Token, limit int) (any, error) {
	switch {
	case limit == 0:
		limit = 20
	case limit < 1 || limit > maxChanges:
		return nil, userError(fmt.Sprintf("limit must be 1 to %d", maxChanges))
	}
	// Ask for extra rows: service-wide changes (AI providers) are dropped,
	// they are not this account's to see.
	events, err := s.Events.Recent(ctx, tok.AccountID, 2*limit)
	if err != nil {
		return nil, err
	}
	out := []changeView{}
	for _, e := range events {
		if e.Global || len(out) == limit {
			continue
		}
		out = append(out, changeView{At: e.At.In(s.loc()).Format("2006-01-02 15:04"), Who: e.Actor, What: e.Action, Detail: e.Summary})
	}
	return map[string]any{"count": len(out), "changes": out}, nil
}
