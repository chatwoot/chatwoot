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
	return q.Store.Waiting(ctx, accountID)
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
	text = strings.TrimSpace(noNUL(text))
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
