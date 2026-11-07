package intake

import (
	"slices"
	"testing"
)

func TestDetect(t *testing.T) {
	cases := map[string]struct {
		text    string
		private []string
		payment []string
		contact []string
	}{
		"plain product text":       {text: "AutoCut Pro ราคา 3,900 บาท ใช้ได้ 1 เครื่อง", private: nil, payment: nil, contact: nil},
		"card number (Luhn)":       {text: "บัตร 4111 1111 1111 1111 หมดอายุ 12/28", private: []string{"card number"}},
		"not a card (Luhn fails)":  {text: "order 4111 1111 1111 1112"},
		"cvv value":                {text: "CVV: 123", private: []string{"security code"}},
		"password value":           {text: "รหัสผ่าน คือ hunter22", private: []string{"password"}},
		"policy mentions password": {text: "เราจะไม่ขอรหัสผ่านหรือ OTP จากลูกค้า"},
		"thai id alone":            {text: "เลขบัตรประชาชน 1-1017-00230-70-8", private: []string{"ID number"}},
		"promptpay by id":          {text: "พร้อมเพย์ 1101700230708 ชื่อบริษัท", payment: []string{"PromptPay"}},
		"promptpay by phone":       {text: "PromptPay: 081-234-5678", payment: []string{"PromptPay"}},
		"bank account":             {text: "โอนเข้าบัญชีกสิกร 123-4-56789-0 ชื่อ จอห์น", payment: []string{"bank account"}},
		"payment link":             {text: "ชำระที่ https://pay.example.com/checkout/abc", payment: []string{"payment link"}},
		"ordinary link":            {text: "ดูคู่มือที่ https://example.com/docs/install"},
		"phone":                    {text: "โทร 02-123-4567", contact: []string{"phone"}},
		"line id":                  {text: "แอดไลน์ @johnautocut", contact: []string{"LINE"}},
		"line link":                {text: "https://line.me/R/ti/p/@johnautocut", contact: []string{"LINE"}},
		"email":                    {text: "ติดต่อ sales@example.com", contact: []string{"email"}},
		"price is not a phone":     {text: "ราคา 12,900 บาท ส่วนลด 2,000"},
		"phone with dots":          {text: "โทร 081.234.5678", contact: []string{"phone"}},
		"bare handle":              {text: "ทักมาที่ @shop_official ได้เลย", contact: []string{"LINE"}},
		"date is not a phone":      {text: "หมดเขต 08/11/2026 เวลา 23:59"},
	}
	for name, c := range cases {
		t.Run(name, func(t *testing.T) {
			// Act
			got := Detect(c.text)

			// Assert
			if !slices.Equal(got.Private, c.private) || !slices.Equal(got.Payment, c.payment) || !slices.Equal(got.Contact, c.contact) {
				t.Fatalf("Detect(%q) = %+v, want private=%v payment=%v contact=%v", c.text, got, c.private, c.payment, c.contact)
			}
		})
	}
}

func TestDetect_HiddenSeparatorsDoNotHideNumbers(t *testing.T) {
	cases := map[string]string{
		"zero-width":     "4111\u200b1111-1111\u200b1111",
		"dots":           "4111.1111.1111.1111",
		"slashes":        "4111/1111/1111/1111",
		"no-break space": "4111\u00a01111\u00a01111\u00a01111",
		"ideographic":    "4111\u30001111\u30001111\u30001111",
		"full-width":     "４１１１ １１１１ １１１１ １１１１",
		"thai id dots":   "1.1017.00230.70.8",
		"en dash":        "4111\u20131111\u20131111\u20131111",
		"arabic digits":  "\u0664\u0661\u0661\u0661 1111 1111 1111",
		"underscores":    "4111_1111_1111_1111",
	}
	for name, text := range cases {
		t.Run(name, func(t *testing.T) {
			// Act
			got := Detect(text)

			// Assert
			if len(got.Private) == 0 {
				t.Fatalf("Detect(%q) = %+v, want private", text, got)
			}
		})
	}
}
