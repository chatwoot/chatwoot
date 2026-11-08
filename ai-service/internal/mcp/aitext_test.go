package mcp

import (
	"strings"
	"testing"
)

func TestAIText_RefusesPaymentAndContactDetails(t *testing.T) {
	cases := []string{
		// links and domains, with or without a scheme
		"Pay at https://bit.ly/x",
		"Order on evil.example/pay",
		"Add us: line.me/ti/p/~johnshop",
		"See www.johnshop.co.th for details",
		// handles and email, ASCII or full-width
		"Follow @johnshop",
		"Write to pay＠evil.example",
		// LINE and payment words
		"Add LINE ID: johnshop",
		"Our LINE is johnshop",
		"แอดไลน์ johnshop",
		"Pay by PromptPay please",
		"ชำระผ่านพร้อมเพย์",
		"โอนเงินก่อนส่งของ",
		"เลขบัญชี กสิกร",
		"Please transfer to our bank account",
		"Account number below",
		// numbers written to dodge a pattern check
		"Kasikornbank 123-4-56789-0",
		"Transfer to 1234567890",
		"Call 081 - 234 - 5678",
		"Call 081,234,5678",
		"Call +44 7700 900123",
		"Call 66812345678",
		"Call O81-234-5678",
		"Call 081 22:53 456",
		"Call 0,812,253,456",
		"Card 4111 1111 1111 1111",
		"Account 1,234,567,890",
	}
	for _, in := range cases {
		t.Run(in, func(t *testing.T) {
			// Act
			err := checkAIText("rules", in)

			// Assert
			if err == nil {
				t.Fatalf("%q accepted", in)
			}
			if !strings.Contains(err.Error(), "admin page") || !strings.Contains(err.Error(), "rules") {
				t.Fatalf("error = %q", err)
			}
		})
	}
}

func TestAIText_AllowsOrdinaryShopText(t *testing.T) {
	cases := []string{
		"Open 09:00-18:00 every day except Songkran.",
		"Open 9.00 – 18.30",
		"Cake ฿1,290; set price 1,290-2,500 บาท",
		"A car costs 1,250,000 baht",
		"Since 2019. Closed 2026-04-13 to 2026-04-15.",
		"Closed 13/04/2026",
		"Model RX-100, size 42, 3 for 99 baht",
		"Friendly, short replies. Use ค่ะ.",
		"We are online every day and reply in line with our policy.",
		"Never promise a price.",
	}
	for _, in := range cases {
		t.Run(in, func(t *testing.T) {
			// Act
			err := checkAIText("about", in)

			// Assert
			if err != nil {
				t.Fatalf("%q refused: %v", in, err)
			}
		})
	}
}
