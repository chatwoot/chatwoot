package feed

import (
	"strings"
	"testing"
)

func TestParse_JSONLInOwnersFormat(t *testing.T) {
	// Arrange
	body := `{"id": "product-001", "doc_id": "product", "category": "John Auto Cut คืออะไร", "section": "ภาพรวม", "text": "คอร์สออนไลน์", "needs_confirmation": false}
{"id": "page-002", "category": "ติดต่อ", "section": "", "text": "LINE @john", "updated": 2026}

`

	// Act
	res, err := Parse([]byte(body))

	// Assert
	if err != nil || len(res.Rows) != 2 || res.Skipped != 0 {
		t.Fatalf("res=%+v err=%v", res, err)
	}
	want := Row{ID: "product-001", FAQ: false, Title: "John Auto Cut คืออะไร: ภาพรวม", Content: "คอร์สออนไลน์"}
	if res.Rows[0] != want {
		t.Errorf("row0 = %+v, want %+v", res.Rows[0], want)
	}
	if res.Rows[1].Title != "ติดต่อ" {
		t.Errorf("row1 title = %q, want category only", res.Rows[1].Title)
	}
	if res.Format != "JSONL" {
		t.Errorf("format = %q", res.Format)
	}
}

func TestParse_CSVWithFAQAndDocRows(t *testing.T) {
	// Arrange: a Google Sheet published as CSV (BOM, mixed-case headers, quoted newline).
	body := "\xef\xbb\xbfID,Question,Answer,Title,Content\n" +
		"faq-1,ร้านเปิดกี่โมง,9:00–18:00,,\n" +
		"doc-1,,,Refund policy,\"Line one\nLine two\"\n"

	// Act
	res, err := Parse([]byte(body))

	// Assert
	if err != nil || len(res.Rows) != 2 || res.Format != "CSV" {
		t.Fatalf("res=%+v err=%v", res, err)
	}
	if res.Rows[0] != (Row{ID: "faq-1", FAQ: true, Title: "ร้านเปิดกี่โมง", Content: "9:00–18:00"}) {
		t.Errorf("faq row = %+v", res.Rows[0])
	}
	if res.Rows[1] != (Row{ID: "doc-1", Title: "Refund policy", Content: "Line one\nLine two"}) {
		t.Errorf("doc row = %+v", res.Rows[1])
	}
}

func TestParse_SkipsBadRowsAndReports(t *testing.T) {
	// Arrange
	body := "id,title,content\n" +
		",No id,text\n" + // no id
		"a 1,Spaces in id,text\n" + // id with spaces → a-1
		"a-1,Duplicate of a 1,text\n" + // duplicate after cleaning
		"b,No content,\n" +
		"c,,Only content\n" // title falls back to id

	// Act
	res, err := Parse([]byte(body))

	// Assert
	if err != nil {
		t.Fatal(err)
	}
	ids := []string{}
	for _, r := range res.Rows {
		ids = append(ids, r.ID+"="+r.Title)
	}
	if strings.Join(ids, ",") != "a-1=Spaces in id,c=c" || res.Skipped != 3 || len(res.Problems) != 3 {
		t.Errorf("rows=%v skipped=%d problems=%v", ids, res.Skipped, res.Problems)
	}
}

func TestParse_RejectsWhatIsNotAFeed(t *testing.T) {
	// Arrange
	cases := map[string]string{
		"no id column":   "title,content\nA,B\n",
		"empty":          "  \n",
		"html":           "<!doctype html><html><body>Sign in</body></html>",
		"bad json line":  `{"id":"a","text":"x"}` + "\n{not json}\n",
		"json not lines": `[{"id":"a","text":"x"}]`,
	}
	for name, body := range cases {
		// Act
		_, err := Parse([]byte(body))

		// Assert
		if err == nil {
			t.Errorf("%s: parsed, want an error", name)
		}
	}
}

func TestParse_CapsRowsAndLengths(t *testing.T) {
	// Arrange
	var b strings.Builder
	b.WriteString("id,title,content\n")
	for i := 0; i < MaxRows+5; i++ {
		b.WriteString("r" + strings.Repeat("x", i%3) + string(rune('a'+i%26)) + itoa(i) + ",T,C\n")
	}
	long := "id,title,content\nlong," + strings.Repeat("ท", 400) + ",C\n" + strings.Repeat("i", 200) + ",T,C\n"

	// Act
	many, errMany := Parse([]byte(b.String()))
	cut, errCut := Parse([]byte(long))

	// Assert
	if errMany != nil || len(many.Rows) != MaxRows || many.Skipped != 5 {
		t.Errorf("rows=%d skipped=%d err=%v, want %d and 5", len(many.Rows), many.Skipped, errMany, MaxRows)
	}
	if errCut != nil || len([]rune(cut.Rows[0].Title)) != 300 || len(cut.Rows) != 1 || cut.Skipped != 1 {
		t.Errorf("cut=%+v err=%v, want title cut to 300 and the 200-char id skipped", cut.Skipped, errCut)
	}
}

func itoa(i int) string {
	s := ""
	for {
		s = string(rune('0'+i%10)) + s
		i /= 10
		if i == 0 {
			return s
		}
	}
}

func TestHash_StableAndOrderSensitive(t *testing.T) {
	// Arrange
	a := []Row{{ID: "1", Title: "A", Content: "x"}, {ID: "2", Title: "B", Content: "y"}}
	b := []Row{{ID: "2", Title: "B", Content: "y"}, {ID: "1", Title: "A", Content: "x"}}
	c := []Row{{ID: "1", Title: "A", Content: "x!"}, {ID: "2", Title: "B", Content: "y"}}

	// Act / Assert
	if RowHash(a[0]) == RowHash(c[0]) || RowHash(a[0]) != RowHash(b[1]) {
		t.Error("row hash must follow content and ignore position")
	}
}

func TestParse_Dates(t *testing.T) {
	// Arrange
	body := "id,title,content,start_date,last_day\n" +
		"promo,Sale,20% off,2026-11-01,2026-11-30\n" +
		"open,Hours,9 to 6,,\n" +
		"bad,X,Y,1/11/2026,\n" +
		"backwards,X,Y,2026-12-01,2026-11-01\n"

	// Act
	res, err := Parse([]byte(body))

	// Assert
	if err != nil || len(res.Rows) != 2 || res.Skipped != 2 {
		t.Fatalf("res=%+v err=%v", res, err)
	}
	if res.Rows[0].StartDate != "2026-11-01" || res.Rows[0].LastDay != "2026-11-30" || res.Rows[1].LastDay != "" {
		t.Errorf("rows = %+v", res.Rows)
	}
	a, b := res.Rows[0], res.Rows[0]
	b.LastDay = "2026-12-31"
	if RowHash(a) == RowHash(b) {
		t.Error("a date change must change the row hash")
	}
}

func TestParse_DropsNULCharacters(t *testing.T) {
	// Arrange: a database text field cannot hold NUL.
	body := "id,title,content\na\x00b,Ti\x00tle,te\x00xt\n"

	// Act
	res, err := Parse([]byte(body))

	// Assert
	if err != nil || len(res.Rows) != 1 || res.Rows[0] != (Row{ID: "ab", Title: "Title", Content: "text"}) {
		t.Errorf("res=%+v err=%v", res, err)
	}
}
