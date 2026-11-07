// Package cfaccess verifies the Cloudflare Access application token
// (Cf-Access-Jwt-Assertion) so the service knows who is signed in: an RS256
// JWT signed with the account's Access keys, issued by the team domain,
// for this application's AUD tag, and not expired.
package cfaccess

import (
	"context"
	"crypto"
	"crypto/rsa"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"math/big"
	"net/http"
	"slices"
	"strings"
	"sync"
	"time"
)

// Header carries the token Cloudflare adds to every request it lets through.
const Header = "Cf-Access-Jwt-Assertion"

// ErrInvalid is any token that does not verify.
var ErrInvalid = errors.New("cloudflare access token invalid")

// Verifier checks tokens for one Access application.
type Verifier struct {
	TeamDomain string // https://<team>.cloudflareaccess.com (also the issuer)
	AUD        string // the application's Audience tag
	Client     *http.Client
	Now        func() time.Time

	mu        sync.Mutex
	keys      map[string]*rsa.PublicKey
	fetched   time.Time // last successful fetch
	attempted time.Time // last fetch attempt, successful or not
	fetching  bool
}

// maxKeyAge is how long cached keys stay usable when Cloudflare cannot be
// reached.
const maxKeyAge = 24 * time.Hour

// Identity is who Access signed in.
type Identity struct {
	Email string
}

// Verify checks token and returns the signed-in email (lower case).
func (v *Verifier) Verify(ctx context.Context, token string) (Identity, error) {
	parts := strings.Split(token, ".")
	if len(parts) != 3 {
		return Identity{}, ErrInvalid
	}
	var head struct {
		Alg, Kid string
	}
	if err := decodePart(parts[0], &head); err != nil || head.Alg != "RS256" || head.Kid == "" {
		return Identity{}, ErrInvalid
	}
	key, err := v.key(ctx, head.Kid)
	if err != nil {
		return Identity{}, err
	}
	sig, err := base64.RawURLEncoding.DecodeString(parts[2])
	if err != nil {
		return Identity{}, ErrInvalid
	}
	sum := sha256.Sum256([]byte(parts[0] + "." + parts[1]))
	if rsa.VerifyPKCS1v15(key, crypto.SHA256, sum[:], sig) != nil {
		return Identity{}, ErrInvalid
	}
	var claims struct {
		Iss   string          `json:"iss"`
		Aud   json.RawMessage `json:"aud"`
		Exp   float64         `json:"exp"`
		Nbf   float64         `json:"nbf"`
		Email string          `json:"email"`
	}
	if err := decodePart(parts[1], &claims); err != nil {
		return Identity{}, ErrInvalid
	}
	now := v.now()
	skew := time.Minute
	switch {
	case strings.TrimSuffix(claims.Iss, "/") != strings.TrimSuffix(v.TeamDomain, "/"):
		return Identity{}, ErrInvalid
	case !audienceHas(claims.Aud, v.AUD):
		return Identity{}, ErrInvalid
	case claims.Exp <= 0 || claims.Exp > 1e12 || claims.Nbf < 0 || claims.Nbf > 1e12:
		return Identity{}, ErrInvalid
	case now.After(time.Unix(int64(claims.Exp), 0).Add(skew)):
		return Identity{}, ErrInvalid
	case claims.Nbf != 0 && now.Add(skew).Before(time.Unix(int64(claims.Nbf), 0)):
		return Identity{}, ErrInvalid
	case !strings.Contains(claims.Email, "@"):
		return Identity{}, ErrInvalid // a service token, not a person
	}
	email, ok := NormalizeEmail(claims.Email)
	if !ok {
		return Identity{}, ErrInvalid
	}
	return Identity{Email: email}, nil
}

// NormalizeEmail trims and lower-cases an ASCII email address. Non-ASCII
// addresses are refused: Unicode case folding can turn look-alike letters
// (the Kelvin sign, dotted capital I) into another person's address.
func NormalizeEmail(raw string) (string, bool) {
	e := strings.TrimSpace(raw)
	if e == "" || len(e) > 320 {
		return "", false
	}
	b := []byte(e)
	for i, c := range b {
		switch {
		case c > 0x7e || c < 0x21:
			return "", false
		case c >= 'A' && c <= 'Z':
			b[i] = c + ('a' - 'A')
		}
	}
	return string(b), true
}

func (v *Verifier) now() time.Time {
	if v.Now != nil {
		return v.Now()
	}
	return time.Now()
}

func decodePart(s string, out any) error {
	b, err := base64.RawURLEncoding.DecodeString(s)
	if err != nil {
		return err
	}
	return json.Unmarshal(b, out)
}

func audienceHas(raw json.RawMessage, want string) bool {
	if want == "" {
		return false
	}
	var one string
	if json.Unmarshal(raw, &one) == nil {
		return one == want
	}
	var many []string
	return json.Unmarshal(raw, &many) == nil && slices.Contains(many, want)
}

// key returns the public key for kid. The key set is fetched at most once a
// minute (success or failure) and outside the lock, so an outage or tokens
// with random kids cannot queue requests behind slow fetches.
func (v *Verifier) key(ctx context.Context, kid string) (*rsa.PublicKey, error) {
	v.mu.Lock()
	k := v.keys[kid]
	fresh := time.Since(v.fetched) < time.Hour
	canFetch := time.Since(v.attempted) >= time.Minute && !v.fetching
	if k != nil && (fresh || !canFetch) {
		usable := time.Since(v.fetched) < maxKeyAge
		v.mu.Unlock()
		if !usable {
			return nil, ErrInvalid
		}
		return k, nil
	}
	if !canFetch {
		v.mu.Unlock()
		return nil, ErrInvalid
	}
	v.fetching, v.attempted = true, time.Now()
	v.mu.Unlock()

	keys, err := v.fetch(ctx)

	v.mu.Lock()
	defer v.mu.Unlock()
	v.fetching = false
	if err != nil {
		if k := v.keys[kid]; k != nil && time.Since(v.fetched) < maxKeyAge {
			return k, nil // keep working through a brief outage
		}
		return nil, fmt.Errorf("cloudflare access keys unavailable: %w", ErrInvalid)
	}
	v.keys, v.fetched = keys, time.Now()
	if k := keys[kid]; k != nil {
		return k, nil
	}
	return nil, ErrInvalid
}

func (v *Verifier) fetch(ctx context.Context) (map[string]*rsa.PublicKey, error) {
	ctx, cancel := context.WithTimeout(ctx, 10*time.Second)
	defer cancel()
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, strings.TrimSuffix(v.TeamDomain, "/")+"/cdn-cgi/access/certs", nil)
	if err != nil {
		return nil, err
	}
	c := v.Client
	if c == nil {
		c = &http.Client{Timeout: 10 * time.Second}
	}
	res, err := c.Do(req)
	if err != nil {
		return nil, err
	}
	defer res.Body.Close()
	if res.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("status %d", res.StatusCode)
	}
	var set struct {
		Keys []struct {
			Kid, Kty, N, E string
		} `json:"keys"`
	}
	if err := json.NewDecoder(io.LimitReader(res.Body, 1<<20)).Decode(&set); err != nil {
		return nil, err
	}
	out := map[string]*rsa.PublicKey{}
	for _, k := range set.Keys {
		if k.Kty != "RSA" {
			continue
		}
		n, err1 := base64.RawURLEncoding.DecodeString(k.N)
		e, err2 := base64.RawURLEncoding.DecodeString(k.E)
		if err1 != nil || err2 != nil || len(e) == 0 || len(e) > 4 {
			continue
		}
		pub := &rsa.PublicKey{N: new(big.Int).SetBytes(n), E: int(new(big.Int).SetBytes(e).Int64())}
		if pub.N.BitLen() < 2048 {
			continue
		}
		out[k.Kid] = pub
	}
	if len(out) == 0 {
		return nil, errors.New("no RSA keys")
	}
	return out, nil
}
