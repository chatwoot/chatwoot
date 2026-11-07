package cfaccess

import (
	"context"
	"crypto"
	"crypto/rand"
	"crypto/rsa"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"errors"
	"math/big"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"
)

type signer struct {
	key *rsa.PrivateKey
	kid string
}

func newSigner(t *testing.T, kid string) signer {
	t.Helper()
	k, err := rsa.GenerateKey(rand.Reader, 2048)
	if err != nil {
		t.Fatal(err)
	}
	return signer{k, kid}
}

func b64(v any) string {
	b, _ := json.Marshal(v)
	return base64.RawURLEncoding.EncodeToString(b)
}

func (s signer) token(t *testing.T, head, claims map[string]any) string {
	t.Helper()
	if head == nil {
		head = map[string]any{"alg": "RS256", "kid": s.kid}
	}
	in := b64(head) + "." + b64(claims)
	sum := sha256.Sum256([]byte(in))
	sig, err := rsa.SignPKCS1v15(rand.Reader, s.key, crypto.SHA256, sum[:])
	if err != nil {
		t.Fatal(err)
	}
	return in + "." + base64.RawURLEncoding.EncodeToString(sig)
}

func jwk(s signer) map[string]any {
	return map[string]any{"kid": s.kid, "kty": "RSA", "alg": "RS256", "use": "sig",
		"n": base64.RawURLEncoding.EncodeToString(s.key.N.Bytes()),
		"e": base64.RawURLEncoding.EncodeToString(big.NewInt(int64(s.key.E)).Bytes())}
}

const aud = "aud-tag-123"

func setup(t *testing.T, signers ...signer) (*Verifier, *[]signer, *int) {
	t.Helper()
	published := append([]signer(nil), signers...)
	fetches := 0
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		fetches++
		if r.URL.Path != "/cdn-cgi/access/certs" {
			http.NotFound(w, r)
			return
		}
		var keys []any
		for _, s := range published {
			keys = append(keys, jwk(s))
		}
		_ = json.NewEncoder(w).Encode(map[string]any{"keys": keys})
	}))
	t.Cleanup(srv.Close)
	return &Verifier{TeamDomain: srv.URL, AUD: aud, Client: srv.Client()}, &published, &fetches
}

func claims(v *Verifier, mod map[string]any) map[string]any {
	c := map[string]any{"iss": v.TeamDomain, "aud": []string{aud}, "email": "Somchai@Example.com",
		"exp": time.Now().Add(time.Hour).Unix(), "nbf": time.Now().Add(-time.Minute).Unix()}
	for k, val := range mod {
		if val == nil {
			delete(c, k)
		} else {
			c[k] = val
		}
	}
	return c
}

func TestVerify_ValidTokenGivesEmail(t *testing.T) {
	// Arrange
	s := newSigner(t, "k1")
	v, _, _ := setup(t, s)

	// Act
	id, err := v.Verify(context.Background(), s.token(t, nil, claims(v, nil)))

	// Assert
	if err != nil || id.Email != "somchai@example.com" {
		t.Fatalf("id=%+v err=%v", id, err)
	}
}

func TestVerify_Refusals(t *testing.T) {
	s := newSigner(t, "k1")
	other := newSigner(t, "k1") // same kid, different key: a forged signature
	v, _, _ := setup(t, s)
	cases := map[string]string{
		"wrong audience":   s.token(t, nil, claims(v, map[string]any{"aud": []string{"other-app"}})),
		"wrong issuer":     s.token(t, nil, claims(v, map[string]any{"iss": "https://evil.cloudflareaccess.com"})),
		"expired":          s.token(t, nil, claims(v, map[string]any{"exp": time.Now().Add(-2 * time.Minute).Unix()})),
		"not yet valid":    s.token(t, nil, claims(v, map[string]any{"nbf": time.Now().Add(time.Hour).Unix()})),
		"no expiry":        s.token(t, nil, claims(v, map[string]any{"exp": nil})),
		"service token":    s.token(t, nil, claims(v, map[string]any{"email": nil})),
		"forged signature": other.token(t, nil, claims(v, nil)),
		"alg none":         b64(map[string]any{"alg": "none", "kid": "k1"}) + "." + b64(claims(v, nil)) + ".",
		"alg HS256":        s.token(t, map[string]any{"alg": "HS256", "kid": "k1"}, claims(v, nil)),
		"unknown kid":      newSigner(t, "k9").token(t, nil, claims(v, nil)),
		"garbage":          "not.a.jwt",
	}
	tampered := s.token(t, nil, claims(v, nil))
	parts := strings.Split(tampered, ".")
	cases["tampered payload"] = parts[0] + "." + b64(claims(v, map[string]any{"email": "boss@example.com"})) + "." + parts[2]
	for name, tok := range cases {
		t.Run(name, func(t *testing.T) {
			// Act
			_, err := v.Verify(context.Background(), tok)

			// Assert
			if !errors.Is(err, ErrInvalid) {
				t.Fatalf("err = %v, want ErrInvalid", err)
			}
		})
	}
}

func TestVerify_KeyRotationRefetchesOncePerMinute(t *testing.T) {
	// Arrange
	old, next := newSigner(t, "old"), newSigner(t, "new")
	v, published, fetches := setup(t, old)
	if _, err := v.Verify(context.Background(), old.token(t, nil, claims(v, nil))); err != nil {
		t.Fatal(err)
	}
	*published = []signer{old, next}
	v.attempted = time.Now().Add(-2 * time.Minute) // past the refetch guard

	// Act
	id, err := v.Verify(context.Background(), next.token(t, nil, claims(v, nil)))
	_, unknown1 := v.Verify(context.Background(), newSigner(t, "x").token(t, nil, claims(v, nil)))
	_, unknown2 := v.Verify(context.Background(), newSigner(t, "y").token(t, nil, claims(v, nil)))

	// Assert
	if err != nil || id.Email == "" {
		t.Fatalf("rotated key refused: %v", err)
	}
	if !errors.Is(unknown1, ErrInvalid) || !errors.Is(unknown2, ErrInvalid) || *fetches != 2 {
		t.Fatalf("unknown kids should not refetch within a minute: fetches=%d", *fetches)
	}
}

func TestVerify_FailedFetchIsNotRetriedEveryRequest(t *testing.T) {
	// Arrange: the key server is down.
	fetches := 0
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		fetches++
		http.Error(w, "down", http.StatusBadGateway)
	}))
	defer srv.Close()
	v := &Verifier{TeamDomain: srv.URL, AUD: aud, Client: srv.Client()}
	s := newSigner(t, "k1")

	// Act
	for i := 0; i < 5; i++ {
		_, _ = v.Verify(context.Background(), s.token(t, nil, claims(v, nil)))
	}

	// Assert
	if fetches != 1 {
		t.Fatalf("fetches = %d, want 1 per minute while down", fetches)
	}
}

func TestNormalizeEmail_RefusesLookalikes(t *testing.T) {
	cases := map[string]string{"Kate@Corp.com": "kate@corp.com", " a@b.co ": "a@b.co"}
	for in, want := range cases {
		if got, ok := NormalizeEmail(in); !ok || got != want {
			t.Errorf("NormalizeEmail(%q) = %q %v", in, got, ok)
		}
	}
	for _, bad := range []string{"\u212Aate@corp.com", "\u0130nfo@corp.com", "kate@cörp.com", "a b@c.com", ""} {
		if _, ok := NormalizeEmail(bad); ok {
			t.Errorf("accepted %q", bad)
		}
	}
}

func TestVerify_NonASCIIEmailRefused(t *testing.T) {
	// Arrange
	s := newSigner(t, "k1")
	v, _, _ := setup(t, s)

	// Act
	_, err := v.Verify(context.Background(), s.token(t, nil, claims(v, map[string]any{"email": "\u212Aate@corp.com"})))

	// Assert
	if !errors.Is(err, ErrInvalid) {
		t.Fatalf("err = %v", err)
	}
}
