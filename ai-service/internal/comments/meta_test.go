package comments

import (
	"strings"
	"testing"
	"time"
)

const (
	testSecret = "app-secret-123"
	testPage   = "1111"
)

func feedBody(verb, from string) []byte {
	return []byte(`{"object":"page","entry":[{"id":"1111","time":1767225600,"changes":[{"field":"feed","value":{
		"item":"comment","verb":"` + verb + `","comment_id":"2222_3333","post_id":"1111_2222","parent_id":"1111_2222",
		"message":"สนใจค่ะ ราคาเท่าไหร่","created_time":1767225600,"from":{"id":"` + from + `","name":"Somchai"}}}]}]}`)
}

func TestVerifySignature_AcceptsMetaSignature(t *testing.T) {
	// Arrange
	body := feedBody("add", "9999")

	// Act
	err := VerifySignature(testSecret, Sign(testSecret, body), body)

	// Assert
	if err != nil {
		t.Fatalf("err = %v", err)
	}
}

func TestVerifySignature_RejectsBadInput(t *testing.T) {
	body := feedBody("add", "9999")
	cases := map[string]struct {
		header string
		body   []byte
		want   error
	}{
		"missing":       {"", body, ErrMissingSignature},
		"wrong secret":  {Sign("other-secret", body), body, ErrBadSignature},
		"tampered body": {Sign(testSecret, body), append([]byte(nil), append(body, ' ')...), ErrBadSignature},
		"sha1 prefix":   {"sha1=" + Sign(testSecret, body)[7:], body, ErrBadSignature},
		"not hex":       {"sha256=zz", body, ErrBadSignature},
	}
	for name, c := range cases {
		t.Run(name, func(t *testing.T) {
			// Act
			err := VerifySignature(testSecret, c.header, c.body)

			// Assert
			if err != c.want {
				t.Fatalf("err = %v, want %v", err, c.want)
			}
		})
	}
}

func TestHandshake(t *testing.T) {
	cases := map[string]struct {
		verify, mode, token, challenge string
		ok                             bool
	}{
		"valid":               {"tok", "subscribe", "tok", "1158201444", true},
		"wrong token":         {"tok", "subscribe", "nope", "1158201444", false},
		"wrong mode":          {"tok", "unsubscribe", "tok", "1158201444", false},
		"no token configured": {"", "subscribe", "", "1158201444", false},
		"html challenge":      {"tok", "subscribe", "tok", "<script>alert(1)</script>", false},
		"empty challenge":     {"tok", "subscribe", "tok", "", false},
	}
	for name, c := range cases {
		t.Run(name, func(t *testing.T) {
			// Act
			got, ok := Handshake(c.verify, c.mode, c.token, c.challenge)

			// Assert
			if ok != c.ok || (ok && got != c.challenge) {
				t.Fatalf("got %q %v", got, ok)
			}
		})
	}
}

func TestParse_NewCommentByAPerson(t *testing.T) {
	// Act
	got, err := Parse(feedBody("add", "9999"), testPage)

	// Assert
	if err != nil || len(got) != 1 {
		t.Fatalf("got %+v err %v", got, err)
	}
	c := got[0].Comment
	if got[0].Verb != "add" || c.CommentID != "2222_3333" || c.PostID != "1111_2222" || c.FromID != "9999" ||
		c.FromName != "Somchai" || c.Message != "สนใจค่ะ ราคาเท่าไหร่" || !c.CreatedAt.Equal(time.Unix(1767225600, 0)) {
		t.Fatalf("comment = %+v", c)
	}
}

func TestParse_SkipsWhatIsNotALead(t *testing.T) {
	cases := map[string]struct {
		body   []byte
		pageID string
	}{
		"page's own comment": {feedBody("add", testPage), testPage},
		"edited comment":     {feedBody("edited", "9999"), testPage},
		"other page":         {feedBody("add", "9999"), "5555"},
		"not a page object":  {[]byte(`{"object":"user","entry":[]}`), testPage},
		"a like":             {[]byte(`{"object":"page","entry":[{"id":"1111","changes":[{"field":"feed","value":{"item":"reaction","verb":"add"}}]}]}`), testPage},
	}
	for name, c := range cases {
		t.Run(name, func(t *testing.T) {
			// Act
			got, err := Parse(c.body, c.pageID)

			// Assert
			if err != nil || len(got) != 0 {
				t.Fatalf("got %+v err %v", got, err)
			}
		})
	}
}

func TestParse_DeletedComment(t *testing.T) {
	// Act
	got, err := Parse(feedBody("remove", "9999"), testPage)

	// Assert
	if err != nil || len(got) != 1 || got[0].Verb != "remove" || got[0].Comment.CommentID != "2222_3333" {
		t.Fatalf("got %+v err %v", got, err)
	}
}

func TestParse_RejectsInvalidJSON(t *testing.T) {
	// Act
	_, err := Parse([]byte(`{"object":`), testPage)

	// Assert
	if err == nil {
		t.Fatal("want an error")
	}
}

func TestParse_ClipsLongText(t *testing.T) {
	// Arrange
	long := make([]rune, MaxMessageRunes+50)
	for i := range long {
		long[i] = 'ก'
	}
	body := []byte(`{"object":"page","entry":[{"id":"1111","changes":[{"field":"feed","value":{"item":"comment","verb":"add",
		"comment_id":"c1","message":"` + string(long) + `","created_time":1767225600,"from":{"id":"9"}}}]}]}`)

	// Act
	got, err := Parse(body, testPage)

	// Assert
	if err != nil || len(got) != 1 || len([]rune(got[0].Comment.Message)) != MaxMessageRunes {
		t.Fatalf("err %v", err)
	}
}

func TestParse_SkipsIDsTheTableCannotHoldAndDropsNUL(t *testing.T) {
	// Arrange
	long := strings.Repeat("9", 129)
	oversized := []byte(`{"object":"page","entry":[{"id":"1111","changes":[{"field":"feed","value":{"item":"comment","verb":"add",
		"comment_id":"` + long + `","message":"hi","created_time":1767225600,"from":{"id":"9"}}}]}]}`)
	withNUL := []byte(`{"object":"page","entry":[{"id":"1111","changes":[{"field":"feed","value":{"item":"comment","verb":"add",
		"comment_id":"c1","message":"สน\u0000ใจ","created_time":1767225600,"from":{"id":"9","name":"A\u0000B"}}}]}]}`)

	// Act
	skipped, err1 := Parse(oversized, testPage)
	cleaned, err2 := Parse(withNUL, testPage)

	// Assert
	if err1 != nil || len(skipped) != 0 {
		t.Fatalf("oversized: %+v %v", skipped, err1)
	}
	if err2 != nil || len(cleaned) != 1 || cleaned[0].Comment.Message != "สนใจ" || cleaned[0].Comment.FromName != "AB" {
		t.Fatalf("nul: %+v %v", cleaned, err2)
	}
}
