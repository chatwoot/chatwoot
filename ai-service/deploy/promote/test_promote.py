"""Tests for promote.py (DEV-Johnstocker/chatwoot#39, refs #1).

Run: python3 -m unittest discover -s ai-service/deploy/promote
"""

import unittest

import promote

A, B, C = "a" * 40, "b" * 40, "c" * 40


class PickTest(unittest.TestCase):
    def test_picks_the_newest_commit_with_green_staging(self):
        # Arrange: newest first, as git rev-list prints them.
        candidates = [A, B, C]
        staging = {A: "failure", B: "success", C: "success"}

        # Act
        picked = promote.pick(candidates, staging.get)

        # Assert
        self.assertEqual(picked, B)

    def test_none_when_no_commit_passed_staging(self):
        self.assertIsNone(promote.pick([A, B], {A: "pending"}.get))


class RefusalTest(unittest.TestCase):
    def ok_case(self, **change):
        case = dict(sha=B, prev=A, on_develop=True, after_prev=True, staging="success", changed=["ai-service/internal/admin/home.html"])
        case.update(change)
        return promote.refusals(**case)

    def test_green_commit_after_production_is_allowed(self):
        self.assertEqual(self.ok_case(), [])

    def test_first_promote_without_production_branch_is_allowed(self):
        self.assertEqual(self.ok_case(prev=None, after_prev=False), [])

    def test_refuses_commit_without_green_staging(self):
        for state in ("failure", "pending", None):
            with self.subTest(state=state):
                reasons = self.ok_case(staging=state)
                self.assertEqual(len(reasons), 1)
                self.assertIn("staging", reasons[0])

    def test_refuses_commit_not_on_develop(self):
        self.assertIn("not on develop", " ".join(self.ok_case(on_develop=False)))

    def test_refuses_going_backwards(self):
        self.assertIn("older than production", " ".join(self.ok_case(after_prev=False)))

    def test_same_commit_as_production_is_allowed_redeploy(self):
        self.assertEqual(self.ok_case(sha=A, after_prev=False), [])

    def test_refuses_schema_change_and_names_the_file(self):
        # Arrange
        changed = ["ai-service/internal/knowledge/schema_v13.sql", "ai-service/README.md"]

        # Act
        reasons = self.ok_case(changed=changed)

        # Assert
        self.assertEqual(len(reasons), 1)
        self.assertIn("schema_v13.sql", reasons[0])
        self.assertIn("/deploy", reasons[0])

    def test_schema_guard_test_file_is_not_a_schema_change(self):
        self.assertEqual(self.ok_case(changed=["ai-service/internal/knowledge/schema_guard_test.go"]), [])

    def test_refuses_migration_code_and_compose_changes(self):
        # A Chatwoot image bump in the compose file runs Chatwoot's own migrations,
        # and postgres.go applies ours: both need the backup that /deploy takes.
        for path in ("ai-service/internal/knowledge/postgres.go", "ai-service/deploy/dokploy-compose.yml"):
            with self.subTest(path=path):
                reasons = self.ok_case(changed=[path])
                self.assertEqual(len(reasons), 1)
                self.assertIn(path, reasons[0])


class TrustedStagingTest(unittest.TestCase):
    def test_only_github_actions_bot_status_counts(self):
        # Arrange: newest first, as the statuses API lists them.
        statuses = [
            {"context": "staging", "state": "success", "creator": {"login": "someone"}},
            {"context": "staging", "state": "failure", "creator": {"login": "github-actions[bot]"}},
            {"context": "ci", "state": "success", "creator": {"login": "github-actions[bot]"}},
        ]

        # Act
        state = promote.trusted_staging_state(statuses)

        # Assert
        self.assertEqual(state, "failure")

    def test_missing_when_no_trusted_status(self):
        self.assertIsNone(promote.trusted_staging_state([{"context": "staging", "state": "success", "creator": {"login": "x"}}]))


class ShaArgumentTest(unittest.TestCase):
    def test_accepts_hex_shas_only(self):
        for good in ("b22580a26d", B):
            self.assertTrue(promote.valid_sha(good), good)
        for bad in ("", "HEAD", "develop", "b2258;rm -rf /", "zz" * 20, "abc"):
            self.assertFalse(promote.valid_sha(bad), bad)


if __name__ == "__main__":
    unittest.main()
