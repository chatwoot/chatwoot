package comments

import (
	"context"
	"errors"
	"strings"
	"time"
	"unicode/utf8"
)

// Queue errors.
var (
	ErrEmptyReply  = errors.New("the reply is empty")
	ErrLongReply   = errors.New("the reply is longer than 2,000 characters")
	ErrSendingOff  = errors.New("sending is off: META_PAGE_TOKEN is not set")
	ErrSendRefused = errors.New("meta refused the reply")
	// ErrNotRecorded means Meta accepted the reply but saving that failed;
	// the comment stays "sending" in the history. Never send it again.
	ErrNotRecorded = errors.New("the reply was sent but could not be recorded")
)

// Sender sends one private reply.
type Sender interface {
	SendPrivateReply(ctx context.Context, commentID, text string) error
}

// Queue is what /admin/comments uses: it lists waiting comments and sends or
// dismisses them for the owner.
type Queue struct {
	Store  Store
	Sender Sender // nil: the queue fills, but Send is refused
	Now    func() time.Time
	// Posts reads the post each waiting comment was left on, for the page;
	// nil shows the comments without it.
	Posts PostReader
	// PostBudget bounds all post reads of one page load (default 5 s), so a
	// slow Graph cannot hang the page; posts not read in time are not shown.
	PostBudget time.Duration
}

func (q *Queue) now() time.Time {
	if q.Now != nil {
		return q.Now()
	}
	return time.Now()
}

// CanSend reports whether a Page token is set.
func (q *Queue) CanSend() bool { return q.Sender != nil }

// Waiting lists the account's comments that wait for the owner.
func (q *Queue) Waiting(ctx context.Context, accountID int64) ([]Comment, error) {
	list, err := q.Store.Waiting(ctx, accountID)
	if err != nil || q.Posts == nil {
		return list, err
	}
	// One read per post per page load, all within one budget; a failed or
	// late read just shows no post.
	budget := q.PostBudget
	if budget <= 0 {
		budget = 5 * time.Second
	}
	pctx, cancel := context.WithTimeout(ctx, budget)
	defer cancel()
	read := map[string]Post{}
	failed := map[string]bool{}
	for i, c := range list {
		if c.PostID == "" || failed[c.PostID] {
			continue
		}
		p, ok := read[c.PostID]
		if !ok {
			if pctx.Err() != nil {
				break
			}
			got, err := q.Posts.Post(pctx, c.PostID)
			if err != nil {
				failed[c.PostID] = true
				continue
			}
			p, read[c.PostID] = got, got
		}
		list[i].PostText, list[i].PostKnown = p.Text, true
	}
	return list, nil
}

// Recent lists recently decided or ignored comments.
func (q *Queue) Recent(ctx context.Context, accountID int64, limit int) ([]Comment, error) {
	return q.Store.Recent(ctx, accountID, limit)
}

// Send sends text as the private reply to a waiting comment the owner saw at
// version. The comment is claimed first, so two clicks send once. When Meta
// refuses for good the comment is marked failed; otherwise it waits again
// with the error, so the owner can retry.
func (q *Queue) Send(ctx context.Context, accountID, id int64, version int, text, by string) error {
	text = strings.TrimSpace(strings.ReplaceAll(noNUL(text), "\r\n", "\n")) // browsers submit \r\n
	switch {
	case text == "":
		return ErrEmptyReply
	case utf8.RuneCountInString(text) > MaxReplyRunes:
		return ErrLongReply
	case q.Sender == nil:
		return ErrSendingOff
	}
	c, err := q.Store.Get(ctx, accountID, id)
	if err != nil {
		return err
	}
	if c.Expired(q.now()) {
		return ErrExpired
	}
	c, err = q.Store.Claim(ctx, accountID, id, version)
	if err != nil {
		return err
	}
	// The send and its record must finish even if the owner closes the page.
	ctx = context.WithoutCancel(ctx)
	sendErr := q.Sender.SendPrivateReply(ctx, c.CommentID, text)
	var refused *SendError
	switch {
	case sendErr == nil:
		if err := q.Store.Finish(ctx, id, StatusSent, text, by, ""); err != nil {
			return errors.Join(ErrNotRecorded, err)
		}
		return nil
	case errors.As(sendErr, &refused) && refused.Permanent:
		if err := q.Store.Finish(ctx, id, StatusFailed, text, by, refused.Error()); err != nil {
			return err
		}
		return errors.Join(ErrSendRefused, sendErr)
	default:
		if err := q.Store.Finish(ctx, id, StatusWaiting, "", by, clip(sendErr.Error(), 300)); err != nil {
			return err
		}
		return sendErr
	}
}

// ReviewStats compares the shadow reviewer with the owner's decisions.
func (q *Queue) ReviewStats(ctx context.Context, accountID int64) (ReviewStats, error) {
	return q.Store.ReviewStats(ctx, accountID)
}

// Dismiss marks a waiting comment as not answered.
func (q *Queue) Dismiss(ctx context.Context, accountID, id int64, version int, by string) error {
	return q.Store.Dismiss(ctx, accountID, id, version, by)
}
