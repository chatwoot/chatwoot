package admin

import (
	"context"
	"errors"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/places"
)

type fakePlaces struct {
	accounts []places.Place
	inboxes  map[int64][]places.Place
	err      error
	calls    int
}

func (f *fakePlaces) Accounts(context.Context) ([]places.Place, error) {
	f.calls++
	return f.accounts, f.err
}

func (f *fakePlaces) Inboxes(_ context.Context, a int64) ([]places.Place, error) {
	f.calls++
	return f.inboxes[a], f.err
}

func pickerFor(p Places) *pickers {
	h := &Handler{Places: p, Logger: slog.New(slog.NewJSONHandler(io.Discard, nil))}
	return h.newPickers(httptest.NewRequest("GET", "/admin", nil))
}

func TestAccountOptions_KnownAndCurrent(t *testing.T) {
	// Arrange
	f := &fakePlaces{accounts: []places.Place{{ID: 1, Name: "Acme"}, {ID: 2}}}
	p := pickerFor(f)

	// Act
	known := p.accountOptions(2)
	unknown := p.accountOptions(7)

	// Assert
	want := []option{{"1", "Acme (#1)", false}, {"2", "Account 2", true}}
	if len(known) != 2 || known[0] != want[0] || known[1] != want[1] {
		t.Errorf("known = %+v, want %+v", known, want)
	}
	if len(unknown) != 3 || unknown[2] != (option{"7", "Account 7", true}) {
		t.Errorf("unknown current not added: %+v", unknown)
	}
	if f.calls != 1 {
		t.Errorf("store calls = %d, want 1 (loaded once per page)", f.calls)
	}
}

func TestInboxOptions_AllUnknownAndInvalid(t *testing.T) {
	// Arrange
	f := &fakePlaces{inboxes: map[int64][]places.Place{1: {{ID: 3, Name: "Website"}, {ID: 4, Name: "LINE"}}}}
	p := pickerFor(f)

	// Act
	all := p.inboxOptions(1, "")
	chosen := p.inboxOptions(1, "4")
	unseen := p.inboxOptions(1, "9")
	invalid := p.inboxOptions(1, "abc")
	other := p.inboxOptions(2, "")

	// Assert
	if len(all) != 2 || all[0].Selected || all[1].Selected {
		t.Errorf("all = %+v, want two unselected", all)
	}
	if !chosen[1].Selected || chosen[1].Label != "LINE (#4)" {
		t.Errorf("chosen = %+v", chosen)
	}
	if len(unseen) != 3 || unseen[2] != (option{"9", "Inbox 9", true}) {
		t.Errorf("unseen = %+v", unseen)
	}
	if len(invalid) != 2 {
		t.Errorf("invalid current added: %+v", invalid)
	}
	if len(other) != 0 {
		t.Errorf("account 2 = %+v, want none", other)
	}
	if f.calls != 2 {
		t.Errorf("store calls = %d, want 2 (one per account)", f.calls)
	}
}

func TestPickers_StoreErrorOrNilKeepsCurrent(t *testing.T) {
	// Arrange
	failing := pickerFor(&fakePlaces{err: errors.New("db down")})
	none := pickerFor(nil)

	// Act
	a := failing.accountOptions(1)
	b := none.accountOptions(3)
	c := none.inboxOptions(3, "5")

	// Assert
	if len(a) != 1 || !a[0].Selected || len(b) != 1 || b[0].Value != "3" || len(c) != 1 || c[0].Value != "5" {
		t.Errorf("a=%+v b=%+v c=%+v, want only the current value", a, b, c)
	}
}

func TestTestPage_ShowsAccountAndInboxDropdowns(t *testing.T) {
	// Arrange
	e := setup(t, nil)
	e.h.Tester = &fakeTester{}
	e.h.Places = &fakePlaces{
		accounts: []places.Place{{ID: 1, Name: "Johnstocker AI Studio"}, {ID: 2, Name: "Acme <b>"}},
		inboxes:  map[int64][]places.Place{2: {{ID: 5, Name: "LINE OA"}}},
	}
	r := httptest.NewRequest(http.MethodGet, "/admin/test?account=2&inbox=5", nil)
	r.SetBasicAuth(Username, pw)

	// Act
	rec := e.do(r)

	// Assert
	body := rec.Body.String()
	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d", rec.Code)
	}
	for _, want := range []string{
		`<select id="account" name="account">`,
		`<option value="1">Johnstocker AI Studio (#1)</option>`,
		`<option value="2" selected>Acme &lt;b&gt; (#2)</option>`,
		`<select id="inbox" name="inbox" aria-describedby="inbox-hint">`,
		`<option value="5" selected>LINE OA (#5)</option>`,
		`id="account-other"`,
	} {
		if !strings.Contains(body, want) {
			t.Errorf("page missing %q", want)
		}
	}
}
