package config

import (
	"strings"
	"testing"
)

func TestLoad_MetaCommentsOffByDefault(t *testing.T) {
	// Act
	cfg, err := Load(lookupFrom(requiredEnv()))

	// Assert
	if err != nil || cfg.CommentsEnabled() || cfg.MetaAccountID != 1 || cfg.MetaGraphVersion != "v24.0" {
		t.Fatalf("cfg %+v err %v", cfg, err)
	}
}

func TestLoad_MetaCommentsOn(t *testing.T) {
	// Arrange
	env := requiredEnv()
	env["META_APP_SECRET"] = "app-secret"
	env["META_VERIFY_TOKEN"] = "a-long-verify-token"
	env["META_PAGE_ID"] = "1234567890"
	env["META_ACCOUNT_ID"] = "2"

	// Act
	cfg, err := Load(lookupFrom(env))

	// Assert
	if err != nil || !cfg.CommentsEnabled() || cfg.MetaAccountID != 2 || cfg.MetaPageToken != "" {
		t.Fatalf("cfg err %v", err)
	}
}

func TestLoad_MetaCommentsRejectsPartialOrBadSettings(t *testing.T) {
	cases := map[string]struct {
		env  map[string]string
		want string
	}{
		"token without secret": {map[string]string{"META_PAGE_TOKEN": "x"}, "required together"},
		"page id not numeric":  {map[string]string{"META_APP_SECRET": "s", "META_VERIFY_TOKEN": "a-long-verify-token", "META_PAGE_ID": "mypage"}, "numeric"},
		"short verify token":   {map[string]string{"META_APP_SECRET": "s", "META_VERIFY_TOKEN": "short", "META_PAGE_ID": "1"}, "16 characters"},
		"bad graph version":    {map[string]string{"META_APP_SECRET": "s", "META_VERIFY_TOKEN": "a-long-verify-token", "META_PAGE_ID": "1", "META_GRAPH_VERSION": "latest"}, "v24.0"},
		"bad account":          {map[string]string{"META_ACCOUNT_ID": "0"}, "META_ACCOUNT_ID"},
	}
	for name, c := range cases {
		t.Run(name, func(t *testing.T) {
			// Arrange
			env := requiredEnv()
			for k, v := range c.env {
				env[k] = v
			}

			// Act
			_, err := Load(lookupFrom(env))

			// Assert
			if err == nil || !strings.Contains(err.Error(), c.want) {
				t.Fatalf("err %v, want %q", err, c.want)
			}
		})
	}
}

func TestLoad_CommentReviewer(t *testing.T) {
	cases := map[string]struct {
		env     map[string]string
		want    string
		wantErr string
	}{
		"default llm":     {map[string]string{}, "llm", ""},
		"off":             {map[string]string{"COMMENT_REVIEWER": "off"}, "off", ""},
		"jev with key":    {map[string]string{"COMMENT_REVIEWER": "jev", "TYPESAFE_API_KEY": "k"}, "jev", ""},
		"jev without key": {map[string]string{"COMMENT_REVIEWER": "jev"}, "", "needs TYPESAFE_API_KEY"},
		"unknown":         {map[string]string{"COMMENT_REVIEWER": "gpt"}, "", "off, llm or jev"},
	}
	for name, c := range cases {
		t.Run(name, func(t *testing.T) {
			// Arrange
			env := requiredEnv()
			for k, v := range c.env {
				env[k] = v
			}

			// Act
			cfg, err := Load(lookupFrom(env))

			// Assert
			if c.wantErr != "" {
				if err == nil || !strings.Contains(err.Error(), c.wantErr) {
					t.Fatalf("err %v", err)
				}
				return
			}
			if err != nil || cfg.CommentReviewer != c.want {
				t.Fatalf("cfg %q err %v", cfg.CommentReviewer, err)
			}
		})
	}
}
