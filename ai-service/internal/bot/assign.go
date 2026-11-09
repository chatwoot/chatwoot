package bot

import (
	"context"
	"log/slog"
	"math/rand/v2"
	"time"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/chatwoot"
)

// HandoffLabel marks every chat the bot passed to staff, so they can filter it.
const HandoffLabel = "bot-handoff"

// StaffDirectory answers who can take a chat and how busy they are
// (chatwoot.Reader, with the AI Reader agent's token).
type StaffDirectory interface {
	InboxStaff(ctx context.Context, accountID, inboxID int64) ([]chatwoot.Staff, error)
	OpenCount(ctx context.Context, accountID, userID int64) (int, error)
	Assignee(ctx context.Context, accountID, conversationID int64) (int64, error)
}

// Assigner gives a chat to a staff member (chatwoot.Client).
type Assigner interface {
	Assign(ctx context.Context, accountID, conversationID, userID int64) error
}

// Labeler adds a label to a chat (chatwoot.Client).
type Labeler interface {
	AddLabel(ctx context.Context, accountID, conversationID int64, label string) error
}

// pickAssignee keeps the current assignee while they are online (a returning
// customer stays with the same person); otherwise it picks the online member
// with the fewest open chats, a random one among ties. 0 means nobody online.
func pickAssignee(staff []chatwoot.Staff, open map[int64]int, current int64) int64 {
	var best []int64
	least := -1
	for _, s := range staff {
		if !s.Online || s.Reader {
			continue
		}
		if s.ID == current {
			return current
		}
		switch n := open[s.ID]; {
		case least < 0 || n < least:
			least, best = n, []int64{s.ID}
		case n == least:
			best = append(best, s.ID)
		}
	}
	if len(best) == 0 {
		return 0
	}
	return best[rand.IntN(len(best))]
}

// route labels a handed-off chat and assigns it to the least busy online
// staff member before it opens, so Chatwoot's own turn-taking (which only
// fills empty assignees) does not override it. Every step is best effort:
// when one fails, Chatwoot's own assignment still runs when the chat opens.
func (b *Bot) route(ctx context.Context, log *slog.Logger, acct, inbox, conv int64) {
	if l, ok := b.opts.Chatwoot.(Labeler); ok {
		if err := l.AddLabel(ctx, acct, conv, HandoffLabel); err != nil {
			log.Warn("handoff label failed", "error", err)
		}
	}
	a, ok := b.opts.Chatwoot.(Assigner)
	if !ok || b.opts.Staff == nil || inbox == 0 {
		return
	}
	ctx, cancel := context.WithTimeout(ctx, 10*time.Second)
	defer cancel()
	who, err := b.leastBusy(ctx, acct, inbox, conv)
	if err != nil {
		log.Warn("workload lookup failed, chatwoot assigns instead", "error", err)
		return
	}
	if who == 0 {
		log.Info("no staff online, chat waits unassigned")
		return
	}
	if err := a.Assign(ctx, acct, conv, who); err != nil {
		log.Warn("assignment failed, chatwoot assigns instead", "error", err)
		return
	}
	log.Info("chat assigned by workload", "assignee_id", who)
}

func (b *Bot) leastBusy(ctx context.Context, acct, inbox, conv int64) (int64, error) {
	staff, err := b.opts.Staff.InboxStaff(ctx, acct, inbox)
	if err != nil {
		return 0, err
	}
	current, err := b.opts.Staff.Assignee(ctx, acct, conv)
	if err != nil {
		return 0, err
	}
	open := map[int64]int{}
	for _, s := range staff {
		if !s.Online || s.ID == current {
			continue
		}
		n, err := b.opts.Staff.OpenCount(ctx, acct, s.ID)
		if err != nil {
			return 0, err
		}
		open[s.ID] = n
	}
	return pickAssignee(staff, open, current), nil
}
