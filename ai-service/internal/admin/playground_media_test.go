package admin

import (
	"bytes"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/bot"
)

type testFile struct {
	name string
	data []byte
}

// mpost builds a multipart test-chat post, as the page's form sends it.
func mpost(t *testing.T, fields map[string]string, files ...testFile) *http.Request {
	t.Helper()
	var body bytes.Buffer
	mw := multipart.NewWriter(&body)
	for k, v := range fields {
		if err := mw.WriteField(k, v); err != nil {
			t.Fatal(err)
		}
	}
	for _, f := range files {
		fw, err := mw.CreateFormFile("files", f.name)
		if err != nil {
			t.Fatal(err)
		}
		if _, err := fw.Write(f.data); err != nil {
			t.Fatal(err)
		}
	}
	if err := mw.Close(); err != nil {
		t.Fatal(err)
	}
	r := httptest.NewRequest(http.MethodPost, "/admin/test", &body)
	r.Header.Set("Content-Type", mw.FormDataContentType())
	r.Header.Set("Sec-Fetch-Site", "same-origin")
	r.SetBasicAuth(Username, pw)
	return r
}

var ogg = []byte("OggS\x00\x02voice")

func TestTestMedia_VoiceNoteReachesBotAndShowsTranscript(t *testing.T) {
	// Arrange
	e := setup(t, nil)
	ft := &fakeTester{out: bot.Preview{Reply: "ผ่อนได้ 10 เดือนค่ะ", Media: "voice", Transcript: "ผ่อนได้ไหมคะ",
		Input: "[Voice message, transcribed] ผ่อนได้ไหมคะ"}}
	e.h.Tester = ft

	// Act: a voice note with no typed text.
	rec := e.do(mpost(t, map[string]string{"account": "1"}, testFile{"voice.ogg", ogg}))

	// Assert
	body := rec.Body.String()
	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d\n%s", rec.Code, body)
	}
	if len(ft.uploads) != 1 || ft.uploads[0].Name != "voice.ogg" || !bytes.Equal(ft.uploads[0].Data, ogg) {
		t.Fatalf("tester uploads = %+v", ft.uploads)
	}
	for _, want := range []string{"ผ่อนได้ไหมคะ", "Voice note", "voice.ogg",
		`name="text" value="[Voice message, transcribed] ผ่อนได้ไหมคะ"`} {
		if !strings.Contains(body, want) {
			t.Errorf("page missing %q", want)
		}
	}
}

func TestTestMedia_AttachmentHandoffExplained(t *testing.T) {
	// Arrange
	e := setup(t, nil)
	e.h.Tester = &fakeTester{out: bot.Preview{Reply: "thanks for the file", Handoff: true, Reason: bot.ReasonAttachment,
		Input: "[The customer attached 1 file: file]"}}

	// Act
	rec := e.do(mpost(t, map[string]string{"account": "1"}, testFile{"menu.pdf", []byte("%PDF-1.7")}))

	// Assert
	body := rec.Body.String()
	if !strings.Contains(body, "Passes to staff") || !strings.Contains(body, "Business profile") {
		t.Fatalf("attachment handoff not explained:\n%s", body)
	}
}

func TestTestMedia_EmptyFilePartIsIgnored(t *testing.T) {
	// Arrange: browsers send an empty part when no file is chosen.
	e := setup(t, nil)
	ft := &fakeTester{out: bot.Preview{Reply: "3,900 บาทค่ะ"}}
	e.h.Tester = ft

	// Act
	rec := e.do(mpost(t, map[string]string{"account": "1", "message": "ราคา"}, testFile{"", nil}))

	// Assert
	if rec.Code != http.StatusOK || ft.uploads != nil || ft.got[len(ft.got)-1].Content != "ราคา" {
		t.Fatalf("status = %d, uploads = %+v, turns = %+v", rec.Code, ft.uploads, ft.got)
	}
}

func TestTestMedia_RejectsBadUploads(t *testing.T) {
	five := []testFile{{"1.png", ogg}, {"2.png", ogg}, {"3.png", ogg}, {"4.png", ogg}, {"5.png", ogg}}
	cases := map[string]struct {
		files []testFile
		code  int
	}{
		"no message and no file": {nil, http.StatusUnprocessableEntity},
		"too many files":         {five, http.StatusUnprocessableEntity},
		"one file over 10 MB":    {[]testFile{{"big.ogg", make([]byte, maxTestFileBytes+1)}}, http.StatusUnprocessableEntity},
		"body over the limit":    {[]testFile{{"a.ogg", make([]byte, maxTestFileBytes)}, {"b.ogg", make([]byte, maxTestFileBytes)}, {"c.ogg", make([]byte, maxTestFileBytes)}, {"d.ogg", make([]byte, maxTestFileBytes)}}, http.StatusRequestEntityTooLarge},
	}
	for name, tc := range cases {
		t.Run(name, func(t *testing.T) {
			// Arrange
			e := setup(t, nil)
			ft := &fakeTester{}
			e.h.Tester = ft

			// Act
			rec := e.do(mpost(t, map[string]string{"account": "1"}, tc.files...))

			// Assert
			if rec.Code != tc.code || ft.got != nil {
				t.Fatalf("status = %d, want %d; tester called = %v", rec.Code, tc.code, ft.got != nil)
			}
		})
	}
}

func TestTestMedia_CrossSiteUploadRejected(t *testing.T) {
	// Arrange
	e := setup(t, nil)
	ft := &fakeTester{}
	e.h.Tester = ft
	r := mpost(t, map[string]string{"account": "1"}, testFile{"voice.ogg", ogg})
	r.Header.Set("Sec-Fetch-Site", "cross-site")

	// Act
	rec := e.do(r)

	// Assert
	if rec.Code != http.StatusForbidden || ft.got != nil {
		t.Fatalf("status = %d, tester called = %v", rec.Code, ft.got != nil)
	}
}

func TestTestMedia_NoKnowledgeSectionWithoutModel(t *testing.T) {
	// Arrange: a handoff before any model call.
	e := setup(t, nil)
	e.h.Tester = &fakeTester{out: bot.Preview{Reply: "thanks", Handoff: true, Reason: bot.ReasonAttachment}}

	// Act
	rec := e.do(mpost(t, map[string]string{"account": "1"}, testFile{"menu.pdf", []byte("%PDF-1.7")}))

	// Assert
	if strings.Contains(rec.Body.String(), "Knowledge used") {
		t.Error("page shows knowledge for a reply no model wrote")
	}
}

func TestTestMedia_RejectsOversizedTextFields(t *testing.T) {
	// Arrange: more history text than the plain form allows.
	e := setup(t, nil)
	ft := &fakeTester{}
	e.h.Tester = ft
	r := mpost(t, map[string]string{"account": "1", "message": "hi", "text": strings.Repeat("ก", maxTestFormBytes)})

	// Act
	rec := e.do(r)

	// Assert
	if rec.Code != http.StatusRequestEntityTooLarge || ft.got != nil {
		t.Fatalf("status = %d, tester called = %v", rec.Code, ft.got != nil)
	}
}

func TestTestMedia_UploadNeedsAuth(t *testing.T) {
	// Arrange
	e := setup(t, nil)
	ft := &fakeTester{}
	e.h.Tester = ft
	noAuth := mpost(t, map[string]string{"account": "1"}, testFile{"voice.ogg", ogg})
	noAuth.Header.Del("Authorization")
	wrong := mpost(t, map[string]string{"account": "1"}, testFile{"voice.ogg", ogg})
	wrong.SetBasicAuth(Username, "wrong-password")

	// Act
	a, w := e.do(noAuth), e.do(wrong)

	// Assert
	if a.Code != http.StatusUnauthorized || w.Code != http.StatusUnauthorized || ft.got != nil {
		t.Fatalf("no auth = %d, wrong password = %d, tester called = %v", a.Code, w.Code, ft.got != nil)
	}
}

func TestTestMedia_MalformedMultipartShowsPlainError(t *testing.T) {
	// Arrange: a multipart header with a body that ends early.
	e := setup(t, nil)
	ft := &fakeTester{}
	e.h.Tester = ft
	r := httptest.NewRequest(http.MethodPost, "/admin/test", strings.NewReader("--x\r\nContent-Disposition: form-data; name=\"message\"\r\n\r\nhi"))
	r.Header.Set("Content-Type", "multipart/form-data; boundary=x")
	r.Header.Set("Sec-Fetch-Site", "same-origin")
	r.SetBasicAuth(Username, pw)

	// Act
	rec := e.do(r)

	// Assert
	if ft.got != nil || strings.Contains(rec.Body.String(), "multipart:") {
		t.Fatalf("status = %d, tester called = %v, body shows Go's error", rec.Code, ft.got != nil)
	}
}
