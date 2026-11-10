package comments

import (
	"context"
	"errors"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/knowledge"
	"github.com/jackc/pgx/v5/pgxpool"
)

func openDB(t *testing.T) *Postgres {
	t.Helper()
	dsn := os.Getenv("TEST_DATABASE_URL")
	if dsn == "" {
		t.Skip("TEST_DATABASE_URL not set")
	}
	ctx := context.Background()
	pool, err := pgxpool.New(ctx, dsn)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(pool.Close)
	if _, err := pool.Exec(ctx, "DROP TABLE IF EXISTS kb_chunks, kb_documents, business_profiles, kb_audit, mcp_tokens, oauth_codes, oauth_grants, oauth_clients, team_members, admin_events, web_sources, chatwoot_inboxes, ai_pending_changes, fb_comments, kb_schema_version"); err != nil {
		t.Fatal(err)
	}
	if err := (&knowledge.Postgres{Pool: pool}).Migrate(ctx); err != nil {
		t.Fatal(err)
	}
	return &Postgres{Pool: pool}
}

// each runs a test against Memory and Postgres (when TEST_DATABASE_URL is
// set), so both keep the same rules.
func each(t *testing.T, test func(t *testing.T, db Store)) {
	t.Run("memory", func(t *testing.T) { test(t, &Memory{}) })
	t.Run("postgres", func(t *testing.T) { test(t, openDB(t)) })
}

func sample(acct int64, commentID string) Comment {
	return Comment{AccountID: acct, PageID: testPage, CommentID: commentID, PostID: "1111_2222", ParentID: "1111_2222",
		FromID: "9999", FromName: "Somchai", Message: "สนใจค่ะ", CreatedAt: time.Now().Add(-time.Hour).Truncate(time.Second)}
}

func TestStore_AddIsOncePerComment(t *testing.T) {
	each(t, func(t *testing.T, db Store) {
		// Arrange
		ctx := context.Background()

		// Act
		first, err1 := db.Add(ctx, sample(1, "c1"))
		again, err2 := db.Add(ctx, sample(1, "c1"))
		list, err3 := db.Unscored(ctx, 10)

		// Assert
		if err1 != nil || err2 != nil || err3 != nil || !first || again || len(list) != 1 {
			t.Fatalf("first %v again %v list %d errs %v %v %v", first, again, len(list), err1, err2, err3)
		}
		c := list[0]
		if c.Status != StatusNew || c.Version != 1 || c.Message != "สนใจค่ะ" || c.FromName != "Somchai" || c.Intent != "" {
			t.Fatalf("row %+v", c)
		}
	})
}

func TestStore_ScoreMovesToWaitingOrIgnored(t *testing.T) {
	each(t, func(t *testing.T, db Store) {
		// Arrange
		ctx := context.Background()
		_, _ = db.Add(ctx, sample(1, "lead"))
		_, _ = db.Add(ctx, sample(1, "noise"))
		list, _ := db.Unscored(ctx, 10)

		// Act
		err1 := db.Score(ctx, list[0].ID, IntentLead, "asks the price", "ส่งรายละเอียดให้ทางแชทนะคะ")
		err2 := db.Score(ctx, list[1].ID, IntentOther, "emoji", "")
		again := db.Score(ctx, list[0].ID, IntentOther, "x", "")

		// Assert
		waiting, _ := db.Waiting(ctx, 1)
		recent, _ := db.Recent(ctx, 1, 10)
		if err1 != nil || err2 != nil || !errors.Is(again, ErrNotFound) {
			t.Fatalf("errs %v %v %v", err1, err2, again)
		}
		if len(waiting) != 1 || waiting[0].Draft != "ส่งรายละเอียดให้ทางแชทนะคะ" || waiting[0].Version != 2 || waiting[0].Intent != IntentLead {
			t.Fatalf("waiting %+v", waiting)
		}
		if len(recent) != 1 || recent[0].Status != StatusIgnored {
			t.Fatalf("recent %+v", recent)
		}
	})
}

func scored(t *testing.T, db Store, acct int64, id string) Comment {
	t.Helper()
	ctx := context.Background()
	if _, err := db.Add(ctx, sample(acct, id)); err != nil {
		t.Fatal(err)
	}
	list, _ := db.Unscored(ctx, 10)
	for _, c := range list {
		if c.CommentID == id {
			if err := db.Score(ctx, c.ID, IntentLead, "r", "d"); err != nil {
				t.Fatal(err)
			}
			got, _ := db.Get(ctx, acct, c.ID)
			return got
		}
	}
	t.Fatal("not stored")
	return Comment{}
}

func TestStore_ClaimOnlyOnceAndOnlyAtTheSeenVersion(t *testing.T) {
	each(t, func(t *testing.T, db Store) {
		// Arrange
		ctx := context.Background()
		c := scored(t, db, 1, "c1")

		// Act
		_, stale := db.Claim(ctx, 1, c.ID, c.Version+1)
		_, otherAcct := db.Claim(ctx, 2, c.ID, c.Version)
		claimed, err := db.Claim(ctx, 1, c.ID, c.Version)
		_, twice := db.Claim(ctx, 1, c.ID, c.Version)

		// Assert
		if !errors.Is(stale, ErrChanged) || !errors.Is(otherAcct, ErrNotFound) || err != nil || !errors.Is(twice, ErrChanged) {
			t.Fatalf("stale %v other %v err %v twice %v", stale, otherAcct, err, twice)
		}
		if claimed.Status != StatusSending || claimed.CommentID != "c1" {
			t.Fatalf("claimed %+v", claimed)
		}
	})
}

func TestStore_FinishRecordsTheOutcome(t *testing.T) {
	each(t, func(t *testing.T, db Store) {
		// Arrange
		ctx := context.Background()
		sent, retry := scored(t, db, 1, "sent"), scored(t, db, 1, "retry")
		_, _ = db.Claim(ctx, 1, sent.ID, sent.Version)
		_, _ = db.Claim(ctx, 1, retry.ID, retry.Version)

		// Act
		err1 := db.Finish(ctx, sent.ID, StatusSent, "Hello", "owner@example.com", "")
		err2 := db.Finish(ctx, retry.ID, StatusWaiting, "", "owner@example.com", "timeout")
		notClaimed := db.Finish(ctx, sent.ID, StatusSent, "Again", "x", "")

		// Assert
		s, _ := db.Get(ctx, 1, sent.ID)
		r, _ := db.Get(ctx, 1, retry.ID)
		if err1 != nil || err2 != nil || !errors.Is(notClaimed, ErrNotFound) {
			t.Fatalf("errs %v %v %v", err1, err2, notClaimed)
		}
		if s.Status != StatusSent || s.Reply != "Hello" || s.DecidedBy != "owner@example.com" || s.DecidedAt.IsZero() {
			t.Fatalf("sent %+v", s)
		}
		if r.Status != StatusWaiting || r.Error != "timeout" || r.Reply != "" || r.Version != retry.Version+2 {
			t.Fatalf("retry %+v", r)
		}
	})
}

func TestStore_DismissAndAccountScope(t *testing.T) {
	each(t, func(t *testing.T, db Store) {
		// Arrange
		ctx := context.Background()
		mine, theirs := scored(t, db, 1, "mine"), scored(t, db, 2, "theirs")

		// Act
		crossed := db.Dismiss(ctx, 1, theirs.ID, theirs.Version, "owner")
		err := db.Dismiss(ctx, 1, mine.ID, mine.Version, "owner")

		// Assert
		w1, _ := db.Waiting(ctx, 1)
		w2, _ := db.Waiting(ctx, 2)
		if !errors.Is(crossed, ErrNotFound) || err != nil || len(w1) != 0 || len(w2) != 1 {
			t.Fatalf("crossed %v err %v w1 %d w2 %d", crossed, err, len(w1), len(w2))
		}
	})
}

func TestStore_ForgetBlanksAnyCommentAndBlocksItsReturn(t *testing.T) {
	each(t, func(t *testing.T, db Store) {
		// Arrange
		ctx := context.Background()
		waiting, sent := scored(t, db, 1, "waiting"), scored(t, db, 1, "sent")
		_, _ = db.Claim(ctx, 1, sent.ID, sent.Version)
		_ = db.Finish(ctx, sent.ID, StatusSent, "Hi", "owner", "")

		// Act
		err1 := db.Forget(ctx, Comment{AccountID: 1, PageID: testPage, CommentID: "waiting"})
		err2 := db.Forget(ctx, Comment{AccountID: 1, PageID: testPage, CommentID: "sent"})
		err3 := db.Forget(ctx, Comment{AccountID: 1, PageID: testPage, CommentID: "never-seen"})
		readded, addErr := db.Add(ctx, sample(1, "waiting"))
		lateAdd, lateErr := db.Add(ctx, sample(1, "never-seen"))

		// Assert
		w, _ := db.Get(ctx, 1, waiting.ID)
		st, _ := db.Get(ctx, 1, sent.ID)
		queue, _ := db.Waiting(ctx, 1)
		history, _ := db.Recent(ctx, 1, 10)
		unscored, _ := db.Unscored(ctx, 10)
		if err1 != nil || err2 != nil || err3 != nil || addErr != nil || lateErr != nil || readded || lateAdd {
			t.Fatalf("errs %v %v %v %v %v readded %v late %v", err1, err2, err3, addErr, lateErr, readded, lateAdd)
		}
		for _, c := range []Comment{w, st} {
			if c.Status != StatusRemoved || c.Message != "" || c.FromName != "" || c.Draft != "" || c.Reply != "" {
				t.Fatalf("not blanked: %+v", c)
			}
		}
		if len(queue) != 0 || len(history) != 0 || len(unscored) != 0 {
			t.Fatalf("removed comments still listed: %d %d %d", len(queue), len(history), len(unscored))
		}
	})
}

func TestStore_PurgeDeletesOldRows(t *testing.T) {
	each(t, func(t *testing.T, db Store) {
		// Arrange
		ctx := context.Background()
		_, _ = db.Add(ctx, sample(1, "c1"))

		// Act
		kept, err1 := db.Purge(ctx, time.Now().Add(-time.Hour))
		gone, err2 := db.Purge(ctx, time.Now().Add(time.Hour))

		// Assert
		left, _ := db.Unscored(ctx, 10)
		if err1 != nil || err2 != nil || kept != 0 || gone != 1 || len(left) != 0 {
			t.Fatalf("kept %d gone %d left %d errs %v %v", kept, gone, len(left), err1, err2)
		}
	})
}

func TestStore_RetryMovesToTheOwnerAfterMaxAttempts(t *testing.T) {
	each(t, func(t *testing.T, db Store) {
		// Arrange
		ctx := context.Background()
		_, _ = db.Add(ctx, sample(1, "hard"))
		_, _ = db.Add(ctx, sample(1, "easy"))
		list, _ := db.Unscored(ctx, 10)
		hard := list[0]

		// Act
		err1 := db.Retry(ctx, hard.ID)
		order, _ := db.Unscored(ctx, 10)
		for range MaxScoreAttempts - 1 {
			_ = db.Retry(ctx, hard.ID)
		}
		after := db.Retry(ctx, hard.ID)

		// Assert
		got, _ := db.Get(ctx, 1, hard.ID)
		if err1 != nil || order[0].CommentID != "easy" || !errors.Is(after, ErrNotFound) {
			t.Fatalf("err %v order %v after %v", err1, order[0].CommentID, after)
		}
		if got.Status != StatusWaiting || got.Reason != UnscoredReason || got.Attempts != MaxScoreAttempts || got.Version != 2 {
			t.Fatalf("row %+v", got)
		}
	})
}

// The longest values the code can write must fit the table's limits, in
// Thai (several bytes per character).
func TestStore_LongestValuesFit(t *testing.T) {
	each(t, func(t *testing.T, db Store) {
		// Arrange
		ctx := context.Background()
		c := sample(1, strings.Repeat("9", 128))
		c.Message = strings.Repeat("ก", MaxMessageRunes)
		c.FromName = strings.Repeat("ข", 256)
		c.FromID = strings.Repeat("1", 64)

		// Act
		added, err := db.Add(ctx, c)
		list, _ := db.Unscored(ctx, 1)
		scoreErr := db.Score(ctx, list[0].ID, IntentLead, strings.Repeat("ค", 500), strings.Repeat("ง", MaxReplyRunes))
		_, claimErr := db.Claim(ctx, 1, list[0].ID, 2)
		finishErr := db.Finish(ctx, list[0].ID, StatusFailed, strings.Repeat("จ", MaxReplyRunes), strings.Repeat("e", 320), strings.Repeat("x", 500))

		// Assert
		if err != nil || !added || scoreErr != nil || claimErr != nil || finishErr != nil {
			t.Fatalf("add %v %v score %v claim %v finish %v", added, err, scoreErr, claimErr, finishErr)
		}
	})
}

func TestStore_SaveReviewAndStats(t *testing.T) {
	each(t, func(t *testing.T, db Store) {
		// Arrange
		ctx := context.Background()
		sent, dismissed := scored(t, db, 1, "sent"), scored(t, db, 1, "dismissed")
		r := goodReview()
		r.Pass, r.Reason, r.Model = true, "all checks passed", "m"

		// Act
		err1 := db.SaveReview(ctx, sent.ID, r)
		err2 := db.SaveReview(ctx, dismissed.ID, r)
		missing := db.SaveReview(ctx, 999999, r)
		_, _ = db.Claim(ctx, 1, sent.ID, sent.Version)
		_ = db.Finish(ctx, sent.ID, StatusSent, sent.Draft, "owner", "")
		_ = db.Dismiss(ctx, 1, dismissed.ID, dismissed.Version, "owner")
		stats, statsErr := db.ReviewStats(ctx, 1)
		other, _ := db.ReviewStats(ctx, 2)

		// Assert
		got, _ := db.Get(ctx, 1, sent.ID)
		if err1 != nil || err2 != nil || !errors.Is(missing, ErrNotFound) || statsErr != nil {
			t.Fatalf("errs %v %v %v %v", err1, err2, missing, statsErr)
		}
		if got.Review == nil || !got.Review.Pass || got.Review.Checks[CheckToneFits] != 0.9 || got.Version != sent.Version+2 {
			t.Fatalf("review %+v version %d", got.Review, got.Version)
		}
		if stats != (ReviewStats{Decided: 2, Agreed: 1, TooLoose: 1}) || other.Decided != 0 {
			t.Fatalf("stats %+v other %+v", stats, other)
		}
	})
}
