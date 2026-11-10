// Package comments turns comments on the business's Facebook Page into leads
// the owner can answer with one private Messenger reply.
//
// Meta sends each new comment to the Page `feed` webhook. ai-service stores
// it once (keyed by Meta's comment ID), an LLM scores how likely the person is
// to buy and drafts a reply, and the comment waits on /admin/comments. Nothing
// is sent until the owner presses Send. Meta allows one private reply per
// comment, within 7 days of the comment:
// https://developers.facebook.com/docs/messenger-platform/discovery/private-replies/
// Issue: DEV-Johnstocker/chatwoot#1
package comments

import (
	"context"
	"errors"
	"strings"
	"time"
)

// ReplyWindow is how long after a comment Meta accepts a private reply.
const ReplyWindow = 7 * 24 * time.Hour

// MaxScoreAttempts is how many scoring passes a comment gets.
const MaxScoreAttempts = 3

// UnscoredReason is shown when the model could not read a comment.
const UnscoredReason = "Could not be sorted automatically. Read it and decide."

// KeepFor is how long a comment is kept before it is deleted (personal data).
const KeepFor = 30 * 24 * time.Hour

// Field limits, enforced by the database too.
const (
	MaxMessageRunes = 8000 // a Facebook comment is at most 8,000 characters
	MaxReplyRunes   = 2000 // a Messenger text message is at most 2,000 characters
)

// Status is where a comment is in the queue.
type Status string

// Statuses.
const (
	StatusNew       Status = "new"       // stored, not scored yet
	StatusWaiting   Status = "waiting"   // scored as worth a reply; waits for the owner
	StatusIgnored   Status = "ignored"   // scored as not worth a reply
	StatusSending   Status = "sending"   // the owner pressed Send; the call to Meta is running
	StatusSent      Status = "sent"      // Meta accepted the private reply
	StatusDismissed Status = "dismissed" // the owner chose not to reply
	StatusFailed    Status = "failed"    // Meta refused for good (already replied, too old, deleted)
	StatusRemoved   Status = "removed"   // deleted on Facebook; kept blank so it cannot come back
)

// MaxWaitingShown caps the admin queue, so a flood of comments cannot make
// the page unusable.
const MaxWaitingShown = 100

// Intent is the scorer's reading of a comment.
type Intent string

// Intents. Lead, Question and Complaint wait for the owner; Other is ignored.
const (
	IntentLead      Intent = "lead"      // wants to buy, asks the price, asks to be messaged
	IntentQuestion  Intent = "question"  // asks something the business can answer
	IntentComplaint Intent = "complaint" // unhappy customer; reply privately, kindly
	IntentOther     Intent = "other"     // praise, tags, emoji, spam, chat between users
)

// Valid reports whether i is one of the known intents.
func (i Intent) Valid() bool {
	switch i {
	case IntentLead, IntentQuestion, IntentComplaint, IntentOther:
		return true
	}
	return false
}

// Errors.
var (
	ErrNotFound = errors.New("comment not found")
	// ErrChanged means the comment changed after the owner opened the page
	// (scored again, or someone else decided it): look again.
	ErrChanged = errors.New("the comment changed after you opened it")
	// ErrExpired means Meta no longer accepts a private reply to it.
	ErrExpired = errors.New("the 7-day reply window has passed")
	// ErrRejected means the database refused the row for good (a value it
	// cannot hold); retrying the same delivery cannot help.
	ErrRejected = errors.New("the comment could not be stored")
)

// Comment is one comment on the Page, and what happened to it.
type Comment struct {
	ID        int64
	AccountID int64
	PageID    string
	CommentID string // Meta's ID; private replies are addressed to it
	PostID    string
	ParentID  string // the comment it answers, or the post
	FromID    string // the commenter's page-scoped ID
	FromName  string
	Message   string
	CreatedAt time.Time // when the person commented (Meta's created_time)

	// PostText is the post the comment was left on, read from Graph when
	// the comment is drafted or shown; it is not stored. PostKnown says the
	// read worked (a photo post can have no text and still be known).
	PostText  string
	PostKnown bool

	Intent Intent
	Reason string // one line from the scorer, for the owner
	Draft  string // the reply the scorer suggests

	Status    Status
	Reply     string // the text that was sent
	DecidedBy string
	DecidedAt time.Time
	Error     string // the last send failure, for the owner
	Version   int
	Attempts  int     // failed scoring passes
	Review    *Review // the shadow reviewer's answer, or nil
	Received  time.Time
}

// Expired reports whether Meta's reply window has passed at now.
func (c Comment) Expired(now time.Time) bool { return now.Sub(c.CreatedAt) > ReplyWindow }

// Store keeps comments. Methods that take an account are scoped to it.
type Store interface {
	// Add stores a new comment with StatusNew. It returns false, and changes
	// nothing, when the comment ID is already stored (Meta retries and
	// replayed requests).
	Add(ctx context.Context, c Comment) (bool, error)
	// Forget records that the person deleted the comment on Facebook: the
	// row keeps only its IDs and StatusRemoved, whatever its status was, so a
	// later Add of the same comment changes nothing. c needs AccountID,
	// PageID and CommentID.
	Forget(ctx context.Context, c Comment) error
	// Unscored returns up to limit comments with StatusNew, fewest failed
	// passes first, then oldest.
	Unscored(ctx context.Context, limit int) ([]Comment, error)
	// Score records the scorer's result on a StatusNew comment and moves it
	// to StatusWaiting or StatusIgnored. It bumps Version.
	Score(ctx context.Context, id int64, intent Intent, reason, draft string) error
	// Retry records a failed scoring pass on a StatusNew comment. After
	// MaxScoreAttempts the comment waits for the owner unscored, so one
	// comment the model cannot read never holds up the others.
	Retry(ctx context.Context, id int64) error
	// Waiting returns the account's comments that wait for the owner,
	// newest first, at most MaxWaitingShown.
	Waiting(ctx context.Context, accountID int64) ([]Comment, error)
	// Recent returns up to limit decided or ignored comments, newest first.
	Recent(ctx context.Context, accountID int64, limit int) ([]Comment, error)
	// Get returns one comment.
	Get(ctx context.Context, accountID, id int64) (Comment, error)
	// Claim moves a waiting comment at this version to StatusSending, so a
	// second Send cannot run: ErrChanged if it moved on, ErrNotFound if gone.
	Claim(ctx context.Context, accountID, id int64, version int) (Comment, error)
	// Finish records the outcome of a claimed send: StatusSent, StatusFailed,
	// or StatusWaiting with errText when the owner may try again.
	Finish(ctx context.Context, id int64, status Status, reply, by, errText string) error
	// Dismiss marks a waiting comment at this version as not answered.
	Dismiss(ctx context.Context, accountID, id int64, version int, by string) error
	// SaveReview records the shadow reviewer's answer on a comment. It does
	// not change the comment's status or version.
	SaveReview(ctx context.Context, id int64, r Review) error
	// ReviewStats compares the reviewer with the owner's decisions.
	ReviewStats(ctx context.Context, accountID int64) (ReviewStats, error)
	// Purge deletes comments received before cutoff and returns how many.
	Purge(ctx context.Context, cutoff time.Time) (int64, error)
}

// ReviewStats compares the shadow reviewer with what the owner did, on
// comments the owner decided (sent or dismissed) that have a review.
type ReviewStats struct {
	Decided int // decided comments with a review
	Agreed  int
	// TooLoose: the reviewer would have sent a draft the owner dismissed or
	// changed. This is the number that must be near zero before auto-send.
	TooLoose int
	// TooStrict: the reviewer would have held a draft the owner sent unchanged.
	TooStrict int
}

// Agreement classifies one decided comment: "agreed", "too_loose" or
// "too_strict". The owner approved the draft when they sent it unchanged.
func Agreement(c Comment) string {
	approved := c.Status == StatusSent && strings.TrimSpace(c.Reply) == strings.TrimSpace(c.Draft)
	switch {
	case c.Review.Pass == approved:
		return "agreed"
	case c.Review.Pass:
		return "too_loose"
	}
	return "too_strict"
}

func (s *ReviewStats) add(c Comment) {
	if c.Review == nil || (c.Status != StatusSent && c.Status != StatusDismissed) {
		return
	}
	s.Decided++
	switch Agreement(c) {
	case "agreed":
		s.Agreed++
	case "too_loose":
		s.TooLoose++
	default:
		s.TooStrict++
	}
}
