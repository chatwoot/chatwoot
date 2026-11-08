package bot

import "testing"

func TestPlainChat(t *testing.T) {
	cases := map[string]struct{ in, want string }{
		"bold":            {"ใส่คูปอง **JOHNAUTOCUT99** ครับ", "ใส่คูปอง JOHNAUTOCUT99 ครับ"},
		"underscore bold": {"ใช้ __โค้ดนี้__", "ใช้ โค้ดนี้"},
		"markdown link":   {"สมัครที่ [หน้าคอร์ส](https://example.com/c/1) ครับ", "สมัครที่ หน้าคอร์ส https://example.com/c/1 ครับ"},
		"link as its url": {"[https://example.com/c/1](https://example.com/c/1)", "https://example.com/c/1"},
		"heading":         {"### ราคา\n3,900 บาท", "ราคา\n3,900 บาท"},
		"arabic question": {"ทำคลิปแนวไหนครับ؟", "ทำคลิปแนวไหนครับ?"},
		"handoff marker":  {"เดี๋ยวแอดมินตอบครับ\n[[HANDOFF]]", "เดี๋ยวแอดมินตอบครับ\n[[HANDOFF]]"},
		"plain untouched": {"ราคา 3,900 - จ่ายครั้งเดียว * เงื่อนไข", "ราคา 3,900 - จ่ายครั้งเดียว * เงื่อนไข"},
		"hashtag kept":    {"#JohnAutoCut ครับ", "#JohnAutoCut ครับ"},
	}
	for name, tc := range cases {
		t.Run(name, func(t *testing.T) {
			// Act
			got := plainChat(tc.in)

			// Assert
			if got != tc.want {
				t.Errorf("plainChat(%q) = %q, want %q", tc.in, got, tc.want)
			}
		})
	}
}
