package main

import (
	"testing"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/config"
)

func TestAttachmentFetcher(t *testing.T) {
	// Arrange
	cases := []struct {
		name              string
		base, public      string
		host, pub, scheme string
		allowHTTP         bool
	}{
		{"production https", "https://chat.example.com", "", "chat.example.com", "", "", false},
		{"production same public", "https://chat.example.com", "https://chat.example.com", "chat.example.com", "", "", false},
		{"local docker", "http://rails:3000", "http://localhost:3000", "rails:3000", "localhost:3000", "http", true},
		{"staging", "http://stg-rails:3000", "https://stg.example.com", "stg-rails:3000", "stg.example.com", "http", true},
		{"docker without public url", "http://rails:3000", "", "rails:3000", "", "", true},
		{"public host on http by mistake", "http://chat.example.com", "", "chat.example.com", "", "", false},
	}
	for _, c := range cases {
		// Act
		f := attachmentFetcher(config.Config{ChatwootBaseURL: c.base, ChatwootPublicURL: c.public})

		// Assert
		if f.Host != c.host || f.PublicHost != c.pub || f.HostScheme != c.scheme || f.AllowHTTP != c.allowHTTP {
			t.Errorf("%s: got host=%q public=%q scheme=%q http=%v", c.name, f.Host, f.PublicHost, f.HostScheme, f.AllowHTTP)
		}
	}
}
