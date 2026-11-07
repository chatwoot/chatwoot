package bot

import (
	"bytes"
	"context"
	"log/slog"
	"strings"
	"sync"
	"testing"
)

type attrChatwoot struct {
	fakeChatwoot
	mu    sync.Mutex
	attrs []map[string]string
}

func (a *attrChatwoot) SetConversationAttributes(_ context.Context, _, _ int64, attrs map[string]string) error {
	a.mu.Lock()
	defer a.mu.Unlock()
	a.attrs = append(a.attrs, attrs)
	return nil
}

func TestCustomerEmail(t *testing.T) {
	cases := map[string]string{
		"gmail":           "ใช้เมลนี้ครับ John.Doe@Gmail.com",
		"two, last wins":  "old a@x.co new b@gmail.com",
		"none":            "ยังไม่ได้สมัครครับ",
		"not an email":    "แอดไลน์ @johnstocker",
		"trailing period": "เมล me@example.com.",
	}
	want := map[string]string{"gmail": "john.doe@gmail.com", "two, last wins": "b@gmail.com", "none": "", "not an email": "", "trailing period": "me@example.com"}
	for name, text := range cases {
		t.Run(name, func(t *testing.T) {
			// Act
			got := customerEmail(text)

			// Assert
			if got != want[name] {
				t.Fatalf("customerEmail(%q) = %q, want %q", text, got, want[name])
			}
		})
	}
}

func TestProcess_SavesCustomerEmailWithoutLoggingIt(t *testing.T) {
	// Arrange
	cw, l := &attrChatwoot{}, &fakeLLM{reply: "ขอบคุณครับ"}
	b, _ := newBot(&cw.fakeChatwoot, l)
	var logs bytes.Buffer
	b.opts.Chatwoot, b.opts.Logger = cw, slog.New(slog.NewJSONHandler(&logs, nil))

	// Act
	b.Process(context.Background(), customerMsg("สมัครด้วย buyer@gmail.com ครับ"))
	b.Process(context.Background(), customerMsg("ซื้อแล้วครับ"))

	// Assert
	if len(cw.attrs) != 1 || cw.attrs[0]["customer_email"] != "buyer@gmail.com" {
		t.Fatalf("attrs = %v", cw.attrs)
	}
	if strings.Contains(logs.String(), "buyer@") || !strings.Contains(logs.String(), "customer email saved") {
		t.Fatalf("logs: %s", logs.String())
	}
	if !strings.Contains(cw.joined(), "msg:ขอบคุณครับ") {
		t.Fatalf("bot did not reply: %s", cw.joined())
	}
}

func TestProcess_EmailWithoutAttributeSupportStillReplies(t *testing.T) {
	// Arrange
	cw, l := &fakeChatwoot{}, &fakeLLM{reply: "ok"}
	b, _ := newBot(cw, l)

	// Act
	b.Process(context.Background(), customerMsg("buyer@gmail.com"))

	// Assert
	if !strings.Contains(cw.joined(), "msg:ok") {
		t.Fatalf("calls: %s", cw.joined())
	}
}
