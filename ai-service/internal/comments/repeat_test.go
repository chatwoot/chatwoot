package comments

import (
	"context"
	"testing"
	"time"
)

// A person who comments "สนใจ" three times showed up as three cards, and
// nothing said they had already been sent a private reply.

func sendTo(t *testing.T, db Store, acct int64, commentID, fromID string) {
	t.Helper()
	ctx := context.Background()
	c := sample(acct, commentID)
	c.FromID = fromID
	if _, err := db.Add(ctx, c); err != nil {
		t.Fatal(err)
	}
	list, _ := db.Unscored(ctx, 50)
	for _, u := range list {
		if u.CommentID != commentID {
			continue
		}
		_ = db.Score(ctx, u.ID, IntentLead, "r", "d")
		got, _ := db.Get(ctx, acct, u.ID)
		if _, err := db.Claim(ctx, acct, u.ID, got.Version); err != nil {
			t.Fatal(err)
		}
		if err := db.Finish(ctx, u.ID, StatusSent, "hello", "owner", ""); err != nil {
			t.Fatal(err)
		}
	}
}

func TestStore_LastRepliesFindsPeopleAlreadyAnswered(t *testing.T) {
	each(t, func(t *testing.T, db Store) {
		// Arrange
		ctx := context.Background()
		sendTo(t, db, 1, "sent-a", "person-a")
		sendTo(t, db, 2, "other-account", "person-b") // another account must not count

		// Act
		got, err := db.LastReplies(ctx, 1, []string{"person-a", "person-b", "person-c"})

		// Assert
		if err != nil || len(got) != 1 || got["person-a"].IsZero() {
			t.Fatalf("got %v %v", got, err)
		}
		if d := time.Since(got["person-a"]); d < 0 || d > time.Minute {
			t.Fatalf("reply time %v", got["person-a"])
		}
	})
}

// The person deletes the comment we answered; the reply still happened, so the
// next comment from them must still warn the owner. A dismissed comment that
// is later deleted was never answered and must not count.
func TestStore_LastRepliesSurvivesTheCommentBeingDeleted(t *testing.T) {
	each(t, func(t *testing.T, db Store) {
		// Arrange
		ctx := context.Background()
		sendTo(t, db, 1, "answered", "person-a")
		dismissed := sample(1, "dismissed")
		dismissed.FromID = "person-b"
		_, _ = db.Add(ctx, dismissed)
		list, _ := db.Unscored(ctx, 50)
		for _, u := range list {
			if u.CommentID == "dismissed" {
				_ = db.Score(ctx, u.ID, IntentLead, "r", "d")
				got, _ := db.Get(ctx, 1, u.ID)
				if err := db.Dismiss(ctx, 1, u.ID, got.Version, "owner"); err != nil {
					t.Fatal(err)
				}
			}
		}
		before, _ := db.LastReplies(ctx, 1, []string{"person-a"})

		// Act
		for _, id := range []string{"answered", "dismissed"} {
			if err := db.Forget(ctx, sample(1, id)); err != nil {
				t.Fatal(err)
			}
		}
		got, err := db.LastReplies(ctx, 1, []string{"person-a", "person-b"})

		// Assert
		if err != nil || len(got) != 1 || !got["person-a"].Equal(before["person-a"]) {
			t.Fatalf("got %v %v, before %v", got, err, before)
		}
	})
}

// A reply sent by the previous release (during a rolling deploy, or after a
// code rollback) sets status and decided_at but not replied_at; it must
// still count.
func TestPostgres_LastRepliesCountsRepliesWithoutRepliedAt(t *testing.T) {
	// Arrange
	db := openDB(t)
	ctx := context.Background()
	sendTo(t, db, 1, "old-binary", "person-a")
	if _, err := db.Pool.Exec(ctx, "UPDATE fb_comments SET replied_at = NULL WHERE comment_id = 'old-binary'"); err != nil {
		t.Fatal(err)
	}

	// Act
	got, err := db.LastReplies(ctx, 1, []string{"person-a"})

	// Assert
	if err != nil || got["person-a"].IsZero() {
		t.Fatalf("got %v %v", got, err)
	}
}

func TestQueue_WaitingMarksRepeatsAndPeopleAlreadyAnswered(t *testing.T) {
	// Arrange
	ctx := context.Background()
	store := &Memory{}
	sendTo(t, store, 1, "earlier", "person-a")
	for _, c := range []Comment{
		{AccountID: 1, CommentID: "a1", FromID: "person-a", PostID: "1_2", Message: "สนใจ"},
		{AccountID: 1, CommentID: "a2", FromID: "person-a", PostID: "1_2", Message: "สนใจครับ"},
		{AccountID: 1, CommentID: "a3", FromID: "person-a", PostID: "1_3", Message: "ราคา?"},
		{AccountID: 1, CommentID: "b1", FromID: "person-b", PostID: "1_2", Message: "สนใจ"},
	} {
		c.CreatedAt = time.Now()
		_, _ = store.Add(ctx, c)
	}
	list, _ := store.Unscored(ctx, 50)
	for _, c := range list {
		_ = store.Score(ctx, c.ID, IntentLead, "r", "d")
	}

	// Act
	waiting, err := (&Queue{Store: store}).Waiting(ctx, 1)

	// Assert
	if err != nil || len(waiting) != 4 {
		t.Fatalf("%v %d", err, len(waiting))
	}
	by := map[string]Comment{}
	for _, c := range waiting {
		by[c.CommentID] = c
	}
	if by["a1"].MoreOnPost != 1 || by["a2"].MoreOnPost != 1 || by["a3"].MoreOnPost != 0 || by["b1"].MoreOnPost != 0 {
		t.Fatalf("repeat counts a1=%d a2=%d a3=%d b1=%d", by["a1"].MoreOnPost, by["a2"].MoreOnPost, by["a3"].MoreOnPost, by["b1"].MoreOnPost)
	}
	if by["a1"].RepliedAt.IsZero() || by["a3"].RepliedAt.IsZero() || !by["b1"].RepliedAt.IsZero() {
		t.Fatalf("already-replied marks a1=%v a3=%v b1=%v", by["a1"].RepliedAt, by["a3"].RepliedAt, by["b1"].RepliedAt)
	}
}
