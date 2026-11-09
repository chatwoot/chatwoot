"""Tests for dokploy.py target selection (DEV-Johnstocker/chatwoot#37).

Run: python3 -m unittest discover -s ai-service/.claude/skills/deploy
"""

import os
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

    def test_staging_checks_cover_onboarding_and_admin(self):
        # Arrange
        config = dokploy.select_target(dict(BASE, DOKPLOY_STAGING_COMPOSE_ID="s"), "staging")

        # Act
        urls = [url for _, url, _, _ in dokploy.public_checks(config)]

        # Assert
        self.assertTrue(any(u.endswith("/installation/onboarding") for u in urls))
        self.assertIn(f"{dokploy.STAGING_ADMIN_URL}/admin", urls)


class DiskTest(unittest.TestCase):
    def test_staging_deploy_refuses_low_or_unknown_disk(self):
        for available in (None, dokploy.MIN_FREE_GB - 1):
            with self.subTest(available=available), self.assertRaises(SystemExit):
                dokploy.check_disk("staging", available)

    def test_enough_disk_or_production_passes(self):
        # Production keeps its own checks; the disk gate is for staging only.
        dokploy.check_disk("staging", dokploy.MIN_FREE_GB)
        dokploy.check_disk("production", None)


if __name__ == "__main__":
    unittest.main()


class PublicRequestTest(unittest.TestCase):
    def test_public_checks_send_a_named_user_agent(self):
        # Arrange: Cloudflare blocks the default "Python-urllib" agent on the staging host.
        url = "https://chat-staging.example.test/webhooks/chatwoot"

        # Act
        request = dokploy.public_request(url, "POST")

        # Assert
        agent = request.get_header("User-agent")
        self.assertTrue(agent and agent.startswith("chatwoot-deploy-verify/"))
        self.assertEqual(request.get_method(), "POST")
        self.assertEqual(request.data, b"{}")


class RemoteCommandTest(unittest.TestCase):
    def tearDown(self):
        os.environ.pop("DEPLOY_SSH_FORCED", None)

    def test_normal_ssh_sends_the_shell_commands(self):
        # Arrange / Act
        disk = dokploy.remote_command("free-gb", "app-x")
        containers = dokploy.remote_command("containers", "app-x")

        # Assert
        self.assertIn("df -BG", disk)
        self.assertIn("--filter name=app-x-", containers)

    def test_forced_command_key_sends_only_keywords(self):
        # Arrange: CI's key may only run the staging-ci script, which takes keywords.
        os.environ["DEPLOY_SSH_FORCED"] = "1"

        # Act / Assert
        self.assertEqual(dokploy.remote_command("free-gb", "app-x"), "free-gb")
        self.assertEqual(dokploy.remote_command("containers", "app-x"), "containers")

    def test_unknown_kind_fails(self):
        with self.assertRaises(SystemExit):
            dokploy.remote_command("rm -rf /", "app-x")


def fake_run(result=None, calls=None):
    """Stand-in for subprocess.run that records calls and returns result."""
    def run(*args, **kwargs):
        if calls is not None:
            calls.append(args)
        return result
    return run


class ContainerCheckTest(unittest.TestCase):
    def setUp(self):
        self.original = dokploy.subprocess.run

    def tearDown(self):
        dokploy.subprocess.run = self.original
        os.environ.pop("DEPLOY_NO_SSH", None)

    def test_no_ssh_skips_the_container_check_without_calling_ssh(self):
        # Arrange: the production promote job has no SSH key (DEV-Johnstocker/chatwoot#39).
        os.environ["DEPLOY_NO_SSH"] = "1"
        calls = []
        dokploy.subprocess.run = fake_run(calls=calls)

        # Act
        ok, lines = dokploy.container_check("app-x")

        # Assert
        self.assertTrue(ok)
        self.assertEqual(calls, [])
        self.assertTrue(lines and lines[0].startswith("SKIP"))

    def test_ssh_failure_fails_the_check(self):
        # Arrange
        class Result:
            returncode, stdout = 255, ""
        dokploy.subprocess.run = fake_run(Result())

        # Act
        ok, lines = dokploy.container_check("app-x")

        # Assert
        self.assertFalse(ok)
        self.assertIn("FAIL  containers: ssh failed", lines)

    def test_unhealthy_container_fails(self):
        # Arrange
        class Result:
            returncode = 0
            stdout = "app-x-rails-1\tUp 3 hours (healthy)\napp-x-sidekiq-1\tUp 2 minutes (unhealthy)\n"
        dokploy.subprocess.run = fake_run(Result())

        # Act
        ok, lines = dokploy.container_check("app-x")

        # Assert
        self.assertFalse(ok)
        self.assertIn("PASS  app-x-rails-1: Up 3 hours (healthy)", lines)
        self.assertIn("FAIL  app-x-sidekiq-1: Up 2 minutes (unhealthy)", lines)
