package admin

import (
	"context"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/places"
)

// Places lists known accounts and inboxes (places.Postgres).
type Places interface {
	Accounts(ctx context.Context) ([]places.Place, error)
	Inboxes(ctx context.Context, accountID int64) ([]places.Place, error)
}

// option is one entry of an account or inbox dropdown.
type option struct {
	Value    string
	Label    string
	Selected bool
}

// pickers loads the dropdown lists once per page render. Without a store,
// or when it fails, the lists hold only the current value, so the page still
// works.
type pickers struct {
	ctx      context.Context
	h        *Handler
	accounts []places.Place
	loaded   bool
	inboxes  map[int64][]places.Place
}

func (h *Handler) newPickers(r *http.Request) *pickers {
	return &pickers{ctx: r.Context(), h: h, inboxes: map[int64][]places.Place{}}
}

// accountOptions lists known accounts with current selected; current is
// added when it is not known yet.
func (p *pickers) accountOptions(current int64) []option {
	if !p.loaded {
		p.loaded = true
		if p.h.Places != nil {
			ctx, cancel := context.WithTimeout(p.ctx, 3*time.Second)
			list, err := p.h.Places.Accounts(ctx)
			cancel()
			if err != nil {
				p.h.Logger.Warn("list accounts failed", "error", err)
			}
			p.accounts = list
		}
	}
	return options(p.accounts, strconv.FormatInt(current, 10), "Account")
}

// inboxOptions lists the account's known inboxes; current ("" = all) is
// selected, and added when it is a valid ID not seen yet.
func (p *pickers) inboxOptions(account int64, current string) []option {
	list, ok := p.inboxes[account]
	if !ok && p.h.Places != nil {
		ctx, cancel := context.WithTimeout(p.ctx, 3*time.Second)
		var err error
		list, err = p.h.Places.Inboxes(ctx, account)
		cancel()
		if err != nil {
			p.h.Logger.Warn("list inboxes failed", "account_id", account, "error", err)
		}
		p.inboxes[account] = list
	}
	return options(list, strings.TrimSpace(current), "Inbox")
}

func options(list []places.Place, current, noun string) []option {
	out := make([]option, 0, len(list)+1)
	found := false
	for _, pl := range list {
		v := strconv.FormatInt(pl.ID, 10)
		sel := v == current
		found = found || sel
		out = append(out, option{Value: v, Label: label(pl, noun), Selected: sel})
	}
	if n, err := strconv.ParseInt(current, 10, 64); err == nil && n > 0 && !found {
		out = append(out, option{Value: current, Label: label(places.Place{ID: n}, noun), Selected: true})
	}
	return out
}

// label is "Name (#3)", or "Inbox 3" when the name is not known.
func label(pl places.Place, noun string) string {
	id := strconv.FormatInt(pl.ID, 10)
	if pl.Name == "" {
		return noun + " " + id
	}
	return pl.Name + " (#" + id + ")"
}
