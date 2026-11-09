"""Tests for build_values.py. Run: python3 -m unittest test_build_values (from this folder). Refs #1."""
import base64
import io
import unittest
from contextlib import redirect_stderr

import build_values

SITE = "https://chat.example.com"
EXPECTED_KEYS = {
    "INSTALLATION_NAME", "BRAND_NAME", "LOGO", "LOGO_DARK", "LOGO_THUMBNAIL",
    "BRAND_URL", "WIDGET_BRAND_URL", "DASHBOARD_SCRIPTS", "DISPLAY_MANIFEST",
}


class BuildValuesTest(unittest.TestCase):
    def test_builds_every_setting_marked_present(self):
        # Arrange / Act
        values = build_values.build(SITE)

        # Assert
        self.assertEqual(set(values), EXPECTED_KEYS)
        self.assertTrue(all(entry["present"] for entry in values.values()))

    def test_logos_are_svg_data_uris_of_the_files(self):
        # Arrange
        expected = base64.b64encode((build_values.HERE / "logo.svg").read_bytes()).decode()

        # Act
        values = build_values.build(SITE)

        # Assert
        self.assertEqual(values["LOGO"]["value"], "data:image/svg+xml;base64," + expected)
        for key in ("LOGO_DARK", "LOGO_THUMBNAIL"):
            self.assertTrue(values[key]["value"].startswith("data:image/svg+xml;base64,"))

    def test_brand_links_name_and_manifest(self):
        # Arrange / Act
        values = build_values.build(SITE)

        # Assert
        self.assertEqual(values["BRAND_URL"]["value"], SITE)
        self.assertEqual(values["WIDGET_BRAND_URL"]["value"], SITE)
        self.assertEqual(values["INSTALLATION_NAME"]["value"], "Pronto")
        self.assertIs(values["DISPLAY_MANIFEST"]["value"], False)

    def test_dashboard_script_is_the_hide_paid_features_file(self):
        # Arrange
        script = (build_values.HERE / "hide-paid-features.html").read_text()

        # Act
        values = build_values.build(SITE)

        # Assert
        self.assertEqual(values["DASHBOARD_SCRIPTS"]["value"], script)
        self.assertIn("settings\\/(sla|security|custom-roles)", script)

    def test_rejects_missing_or_non_https_url(self):
        # Arrange
        bad_args = [["build_values.py"], ["build_values.py", "http://chat.example.com"]]

        for argv in bad_args:
            # Act / Assert
            with self.subTest(argv=argv), redirect_stderr(io.StringIO()):
                with self.assertRaises(SystemExit) as caught:
                    build_values.main(argv)
                self.assertIn("usage", str(caught.exception.code))


if __name__ == "__main__":
    unittest.main()
