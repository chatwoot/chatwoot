"""Tests for dokploy.py target selection (DEV-Johnstocker/chatwoot#37).

Run: python3 -m unittest discover -s ai-service/.claude/skills/deploy
"""

import unittest

import dokploy

BASE = {"DOKPLOY_URL": "https://dokploy.invalid", "DOKPLOY_API_KEY": "k", "DOKPLOY_COMPOSE_ID": "prod-id"}


class TargetTest(unittest.TestCase):
    def test_production_is_the_default(self):
        # Arrange / Act
        target, command = dokploy.parse_args(["status"])
        config = dokploy.select_target(BASE, target)

        # Assert
        self.assertEqual((target, command), ("production", "status"))
        self.assertEqual(config["DOKPLOY_COMPOSE_ID"], "prod-id")
        self.assertNotIn("TARGET", config)

    def test_staging_uses_its_own_compose_and_url(self):
        # Arrange
        values = dict(BASE, DOKPLOY_STAGING_COMPOSE_ID="staging-id")

        # Act
        target, command = dokploy.parse_args(["--target", "staging", "deploy"])
        config = dokploy.select_target(values, target)

        # Assert
        self.assertEqual(command, "deploy")
        self.assertEqual(config["DOKPLOY_COMPOSE_ID"], "staging-id")
        self.assertEqual(config["PUBLIC_URL"], dokploy.STAGING_URL)
        self.assertEqual(values["DOKPLOY_COMPOSE_ID"], "prod-id", "the loaded values must not change")

    def test_staging_refuses_the_production_compose(self):
        # Arrange
        values = dict(BASE, DOKPLOY_STAGING_COMPOSE_ID="prod-id")

        # Act / Assert
        with self.assertRaises(SystemExit):
            dokploy.select_target(values, "staging")

    def test_staging_without_its_compose_id_fails(self):
        with self.assertRaises(SystemExit):
            dokploy.select_target(BASE, "staging")

    def test_unknown_target_or_command_fails(self):
        for argv in (["--target", "prod2", "status"], ["--target", "staging"], ["ship"], []):
            with self.subTest(argv=argv), self.assertRaises(SystemExit):
                target, _ = dokploy.parse_args(argv)
                dokploy.select_target(dict(BASE, DOKPLOY_STAGING_COMPOSE_ID="s"), target)

    def test_staging_checks_expect_access_and_signed_webhook(self):
        # Arrange
        config = dokploy.select_target(dict(BASE, DOKPLOY_STAGING_COMPOSE_ID="s"), "staging")

        # Act
        checks = {name: want for name, _, _, want in dokploy.public_checks(config)}

        # Assert
        self.assertEqual(checks["POST /webhooks/chatwoot unsigned"], {401})
        self.assertTrue(any("Access" in name for name in checks))


if __name__ == "__main__":
    unittest.main()
