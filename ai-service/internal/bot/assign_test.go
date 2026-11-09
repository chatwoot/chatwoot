package bot

import (
	"context"
	"errors"
	"strings"
	"testing"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/chatwoot"
)

func TestPickAssignee(t *testing.T) {
	// Arrange
	staff := []chatwoot.Staff{{ID: 1, Online: true}, {ID: 2, Online: true}, {ID: 3, Online: false}, {ID: 4, Online: true}}
	open := map[int64]int{1: 5, 2: 1, 3: 0, 4: 3}
	cases := []struct {
		name    string
		current int64
		want    int64
	}{
		{"least busy online member", 0, 2},
		{"keeps the current assignee while online", 4, 4},
		{"current assignee offline: least busy instead", 3, 2},
	}
	for _, c := range cases {
		// Act
		got := pickAssignee(staff, open, c.current)

		// Assert
		if got != c.want {
			t.Errorf("%s: got %d, want %d", c.name, got, c.want)
		}
	}
	if got := pickAssignee([]chatwoot.Staff{{ID: 3, Online: false}}, open, 0); got != 0 {
		t.Errorf("nobody online must give 0, got %d", got)
	}
}

func TestPickAssigneeSpreadsTies(t *testing.T) {
	// Arrange
	staff := []chatwoot.Staff{{ID: 1, Online: true}, {ID: 2, Online: true}}
	open := map[int64]int{1: 2, 2: 2}
	seen := map[int64]bool{}

	// Act
	for i := 0; i < 200; i++ {
		seen[pickAssignee(staff, open, 0)] = true
	}

	// Assert
	if !seen[1] || !seen[2] {
		t.Errorf("tied staff must both get chats, saw %v", seen)
	}
}

// staffBook is a fake directory: inbox members, open counts and assignee.
type staffBook struct {
	staff    []chatwoot.Staff
	open     map[int64]int
	assignee int64
	err      error
}

func (s *staffBook) InboxStaff(context.Context, int64, int64) ([]chatwoot.Staff, error) {
	return s.staff, s.err
}
func (s *staffBook) OpenCount(_ context.Context, _, user int64) (int, error) {
	return s.open[user], nil
}
func (s *staffBook) Assignee(context.Context, int64, int64) (int64, error) { return s.assignee, nil }

// routingChatwoot records labels and assignments too.
type routingChatwoot struct{ *fakeChatwoot }

func (r routingChatwoot) Assign(_ context.Context, _, _, user int64) error {
	return r.record("assign:" + string(rune('0'+user)))
}
func (r routingChatwoot) AddLabel(_ context.Context, _, _ int64, label string) error {
	return r.record("label:" + label)
}

func TestHandoffLabelsAndAssignsTheLeastBusyBeforeOpening(t *testing.T) {
	// Arrange
	cw := &fakeChatwoot{}
	b, _ := newBot(cw, &fakeLLM{})
	b.opts.Chatwoot = routingChatwoot{cw}
	b.opts.Staff = &staffBook{staff: []chatwoot.Staff{{ID: 1, Online: true}, {ID: 2, Online: true}}, open: map[int64]int{1: 4, 2: 1}}

	job := customerMsg("human please")
	job.Event.Inbox.ID = 2

	// Act
	b.Process(context.Background(), job)

	// Assert: assigned before the chat opens, so Chatwoot's turn-taking does not override it.
	got := cw.joined()
	if !strings.Contains(got, "label:bot-handoff | assign:2 | handoff") {
		t.Fatalf("got %s, want label, then the least busy assigned, then open", got)
	}
}

func TestHandoffStillOpensWhenTheLookupFails(t *testing.T) {
	// Arrange
	cw := &fakeChatwoot{}
	b, _ := newBot(cw, &fakeLLM{})
	b.opts.Chatwoot = routingChatwoot{cw}
	b.opts.Staff = &staffBook{err: errors.New("chatwoot down")}
	job := customerMsg("human please")
	job.Event.Inbox.ID = 2

	// Act
	b.Process(context.Background(), job)

	// Assert
	got := cw.joined()
	if strings.Contains(got, "assign:") || !strings.HasSuffix(got, "handoff") {
		t.Errorf("got %s, want no assignment and the chat still opened (Chatwoot's own assignment takes over)", got)
	}
}

func TestStaffReplyIsNotLabelledOrReassigned(t *testing.T) {
	// Arrange
	cw := &fakeChatwoot{}
	b, _ := newBot(cw, &fakeLLM{})
	b.opts.Chatwoot = routingChatwoot{cw}
	b.opts.Staff = &staffBook{staff: []chatwoot.Staff{{ID: 1, Online: true}}, open: map[int64]int{}}

	// Act
	b.Process(context.Background(), staffReply("pending", "", false))

	// Assert
	if got := cw.joined(); strings.Contains(got, "label:") || strings.Contains(got, "assign:") {
		t.Errorf("an admin already answering keeps the chat; got %s", got)
	}
}

func TestPickAssigneeNeverPicksExcludedUsers(t *testing.T) {
	// Arrange: the AI Reader account must never get chats, even if it shows online.
	staff := []chatwoot.Staff{{ID: 1, Online: true, Reader: true}, {ID: 2, Online: true}}
	open := map[int64]int{1: 0, 2: 9}

	// Act
	got := pickAssignee(staff, open, 0)

	// Assert
	if got != 2 {
		t.Errorf("got %d, want 2 (the reader account is never assigned)", got)
	}
}
