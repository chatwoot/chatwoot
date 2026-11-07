package oauth

import (
	"crypto"
	"crypto/rand"
	"crypto/rsa"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"math/big"
	"net/http"
	"net/http/httptest"
	"net/url"
	"testing"
	"time"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/cfaccess"
)

// The real verifier against an https key server, end to end through the
// approval endpoint: a genuinely signed Access token approves; the same
// token for another application does not.
func TestAccess_RealVerifierEndToEnd(t *testing.T) {
	// Arrange
	key, err := rsa.GenerateKey(rand.Reader, 2048)
	if err != nil {
		t.Fatal(err)
	}
	jwks := httptest.NewTLSServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		_ = json.NewEncoder(w).Encode(map[string]any{"keys": []any{map[string]any{"kid": "k1", "kty": "RSA",
			"n": base64.RawURLEncoding.EncodeToString(key.N.Bytes()),
			"e": base64.RawURLEncoding.EncodeToString(big.NewInt(int64(key.E)).Bytes())}}})
	}))
	defer jwks.Close()
	sign := func(aud string) string {
		enc := func(v any) string { b, _ := json.Marshal(v); return base64.RawURLEncoding.EncodeToString(b) }
		in := enc(map[string]any{"alg": "RS256", "kid": "k1"}) + "." + enc(map[string]any{"iss": jwks.URL, "aud": []string{aud},
			"email": "somchai@example.com", "exp": time.Now().Add(time.Hour).Unix()})
		sum := sha256.Sum256([]byte(in))
		sig, _ := rsa.SignPKCS1v15(rand.Reader, key, crypto.SHA256, sum[:])
		return in + "." + base64.RawURLEncoding.EncodeToString(sig)
	}
	e := newEnv()
	e.srv.Access = &cfaccess.Verifier{TeamDomain: jwks.URL, AUD: "approval-app", Client: jwks.Client()}
	e.store.team = []Member{{Email: "somchai@example.com", AccountID: 1, CanWrite: true}}
	client := e.register(t, redirect)

	// Act
	ok := e.approveAs(sign("approval-app"), authForm(client, map[string]string{"password": ""}))
	other := e.approveAs(sign("some-other-app"), authForm(client, map[string]string{"password": ""}))

	// Assert
	if loc, _ := url.Parse(ok.Header().Get("Location")); ok.Code != http.StatusSeeOther || loc.Query().Get("code") == "" {
		t.Fatalf("valid sign-in: code=%d body=%s", ok.Code, ok.Body)
	}
	if other.Code != http.StatusForbidden {
		t.Fatalf("token for another Access app: code=%d", other.Code)
	}
}
