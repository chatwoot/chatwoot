"""Tests for pronto_check.py. Run: python3 -m unittest discover -s .claude/skills/pronto-kb-dataset/scripts"""
import datetime as dt
import os
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import pronto_check  # noqa: E402

TODAY = dt.date(2026, 11, 12)


def write(text, suffix=".csv"):
    f = tempfile.NamedTemporaryFile("w", suffix=suffix, delete=False, encoding="utf-8")
    f.write(text)
    f.close()
    return f.name


def messages(res, kind="warnings"):
    return " | ".join(x["message"] for x in res[kind])


class ThaiHeaders(unittest.TestCase):
    def test_thai_column_names_are_read_like_the_importer(self):
        # Arrange
        path = write("รหัส,คำถาม,คำตอบ\nfaq-price,ราคาเท่าไหร่,9,900 บาท\n".replace("9,900", '"9,900"'))
        # Act
        res = pronto_check.check_file(path, TODAY)
        # Assert
        self.assertEqual(res["errors"], [])
        self.assertEqual(res["faqs"], 1)
        self.assertNotIn("columns not checked", messages(res))


class ImporterLimits(unittest.TestCase):
    def test_id_over_120_characters_is_an_error(self):
        # Arrange
        path = write("id,title,content\n" + "a" * 121 + ",t,c\n")
        # Act
        res = pronto_check.check_file(path, TODAY)
        # Assert
        self.assertIn("longer than 120", messages(res, "errors"))

    def test_title_over_300_characters_is_a_warning(self):
        # Arrange
        path = write("id,title,content\nx," + "t" * 301 + ",c\n")
        # Act
        res = pronto_check.check_file(path, TODAY)
        # Assert
        self.assertIn("title is cut at 300", messages(res))

    def test_file_without_id_column_is_an_error(self):
        # Arrange
        path = write("question,answer\nq,a\n")
        # Act
        res = pronto_check.check_file(path, TODAY)
        # Assert
        self.assertIn("no id column", messages(res, "errors"))


class PromoText(unittest.TestCase):
    def test_promo_with_end_date_but_no_after_price_is_warned(self):
        # Arrange
        path = write('id,title,content\npromo,โปร,"ถึงวันที่ 30 พ.ย. 2026 ใส่คูปองเหลือ 3,900 บาท"\n')
        # Act
        res = pronto_check.check_file(path, TODAY)
        # Assert
        self.assertIn("after the promotion", messages(res))

    def test_promo_that_states_the_price_after_is_fine(self):
        # Arrange
        path = write('id,title,content\npromo,โปร,"ถึงวันที่ 30 พ.ย. 2026 เหลือ 3,900 บาท ตั้งแต่ 1 ธ.ค. 2026 ราคา 9,900 บาท"\n')
        # Act
        res = pronto_check.check_file(path, TODAY)
        # Assert
        self.assertNotIn("after the promotion", messages(res))


class Links(unittest.TestCase):
    def test_home_page_link_is_warned(self):
        # Arrange
        path = write("id,title,content\nx,t,ดูได้ที่ https://autocut.example.com/\n")
        # Act
        res = pronto_check.check_file(path, TODAY)
        # Assert
        self.assertIn("home page", messages(res))

    def test_deep_link_is_not_warned_and_is_listed(self):
        # Arrange
        path = write("id,title,content\nx,t,ดูได้ที่ https://autocut.example.com/examples\n")
        # Act
        res = pronto_check.check_file(path, TODAY)
        # Assert
        self.assertNotIn("home page", messages(res))
        self.assertEqual(res["links"], {"https://autocut.example.com/examples": ["x"]})


class PrivateData(unittest.TestCase):
    def test_thai_mobile_number_is_warned(self):
        # Arrange
        path = write("id,title,content\nx,t,โทร 089-123-4567\n")
        # Act
        res = pronto_check.check_file(path, TODAY)
        # Assert
        self.assertIn("mobile number", messages(res))

    def test_office_landline_is_not_warned(self):
        # Arrange
        path = write("id,title,content\nx,t,โทร 044-123-456\n")
        # Act
        res = pronto_check.check_file(path, TODAY)
        # Assert
        self.assertNotIn("mobile number", messages(res))


class BotInstructions(unittest.TestCase):
    def test_rows_that_instruct_the_bot_are_listed_once(self):
        # Arrange
        path = write("id,title,content\na,t,บอทไม่เสนอเรื่องนี้เอง\nb,t,ห้ามบอกจำนวนสิทธิ์\nc,t,ราคา 9900\n")
        # Act
        res = pronto_check.check_file(path, TODAY)
        # Assert
        hits = [x for x in res["warnings"] if "instruct the bot" in x["message"]]
        self.assertEqual(len(hits), 1)
        self.assertIn("a, b", hits[0]["message"])


if __name__ == "__main__":
    unittest.main()
