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
		// second review: mixed ranges, line breaks, look-alike characters
		"Call 08:12-123,456",
		"Call 081\n234\n5678",
		"Call 081\n\n234-5678",
		"Call ⓪⑧①-②③④-⑤⑥⑦⑧",
		"Call ⁰⁸¹²³⁴⁵⁶⁷⁸",
		"Write to pay﹫evil.example",
		"See ｗｗｗ．evil．com",
		"See evil。com",
		// third review: safe-looking pieces, bare prices, invisible characters
		"Call\n08:12\n345678",
		"Call 812,345,678",
		"Call 1,234,567",
		"Call 081\u200b234\u200b5678",
		"Call 081\u2060-\u2060234\u2060-\u20605678",
		"Call 0\u0338812345678",
		"Call 081        234        5678",
		"Our L\u200dINE is johnshop",
		"See evil\u00ad.com",
		"Call 081.......234.......5678",
		"Add our Line evilshop",
		"แอดไลน evilshop",
		"Telegram evilshop",
		"WhatsApp me",
		"IG evilshop",
		"Kasikornbank 123-4-567",
		"Price 1,290-812,345,678",
		"Our LIN\u0301E is johnshop",
		"Pay at evil\u0e48.com",
		"Pay at hxxps://evil",
		"DM @ evilshop",
		"Call 08:12, 12:34, 05:56, 07:08, 09:10",
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
		"Mon-Fri 09:00-18:00\nSat 10:00-16:00\nSun 10:00-14:00",
		"Small 1,290\nLarge 2,490\nParty 12,900",
		"Wedding package 1,250,000 บาท",
		"ร้านเปิด\u200bทุกวัน 10:00-20:00 น้ำ ไลท์ ก๋วยเตี๋ยว",
		"Open 09:00-12:00, 13:00-18:00",
		"Promo until 30/11/2026 23:59",
		"We accept PromptPay, cards and cash.",
		"ชำระผ่านพร้อมเพย์หรือโอนผ่านธนาคารได้",
		"Power bank 20,000 mAh, leather wallet, airport transfer",
		"Log in to your account to see orders.",
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

func TestAIText_PatternsSurviveNormalization(t *testing.T) {
	// Arrange: text is NFKD-normalised before matching, which splits ำ.
	patterns := []string{aiLink.String(), aiWords.String(), aiLINE.String(), aiCurrency.String()}

	for _, p := range patterns {
		// Act
		has := strings.Contains(p, "ำ")

		// Assert
		if has {
			t.Errorf("pattern %q contains ำ, which never matches after NFKD", p)
		}
	}
}
