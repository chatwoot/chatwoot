"""Tests for guard.py: run it the way Claude Code does (JSON on stdin)."""

import json
import os
import subprocess
import sys
import tempfile
import unittest

HOOKS = os.path.dirname(os.path.abspath(__file__))
GUARD = os.path.join(HOOKS, "guard.py")
FORK_ROOT = os.path.abspath(os.path.join(HOOKS, "..", "..", ".."))
# Built by concatenation so this file itself never contains the forbidden setting.
SAFE_FETCH_ON = "SAFE_FETCH_ALLOW_PRIVATE_NETWORK" + "=true"


def run_guard(tool, tool_input, cwd=FORK_ROOT):
    event = {"tool_name": tool, "tool_input": tool_input, "cwd": cwd}
    return subprocess.run(
        [sys.executable, GUARD],
        input=json.dumps(event),
        capture_output=True,
        text=True,
        timeout=30,
    )


def git(cwd, *args):
    subprocess.run(["git", "-C", cwd, *args], check=True, capture_output=True)


class PushTests(unittest.TestCase):
    def test_push_to_develop_is_blocked(self):
        # Arrange
        command = "git push --dry-run origin develop"
        # Act
        result = run_guard("Bash", {"command": command})
        # Assert
        self.assertEqual(result.returncode, 2)
        self.assertIn("never push to develop", result.stderr)

    def test_push_refspec_to_develop_is_blocked(self):
        result = run_guard("Bash", {"command": "git -c credential.helper= push origin HEAD:refs/heads/develop"})
        self.assertEqual(result.returncode, 2)

    def test_bare_push_while_on_develop_is_blocked(self):
        # Arrange: a throwaway repository checked out on develop
        with tempfile.TemporaryDirectory() as repo:
            git(repo, "init", "-q", "-b", "develop")
            # Act
            result = run_guard("Bash", {"command": f"cd {repo} && git push"})
        # Assert
        self.assertEqual(result.returncode, 2)
        self.assertIn("current branch is develop", result.stderr)

    def test_plain_force_is_blocked(self):
        result = run_guard("Bash", {"command": "git push -f origin feat/x"})
        self.assertEqual(result.returncode, 2)
        self.assertIn("--force", result.stderr)

    def test_feature_branch_push_with_lease_is_allowed(self):
        result = run_guard("Bash", {"command": "git push --force-with-lease -u origin feat/x"})
        self.assertEqual(result.returncode, 0, result.stderr)


class NoVerifyTests(unittest.TestCase):
    def test_commit_no_verify_is_blocked(self):
        result = run_guard("Bash", {"command": "git commit --no-verify -m wip"})
        self.assertEqual(result.returncode, 2)
        self.assertIn("--no-verify", result.stderr)

    def test_normal_commit_is_allowed(self):
        result = run_guard("Bash", {"command": "git commit -m 'docs: note'"})
        self.assertEqual(result.returncode, 0, result.stderr)


class FileRuleTests(unittest.TestCase):
    def test_edit_in_ai_service_is_allowed(self):
        path = os.path.join(FORK_ROOT, "ai-service", "README.md")
        result = run_guard("Edit", {"file_path": path, "old_string": "a", "new_string": "b"})
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_edit_to_our_workflow_is_allowed(self):
        path = os.path.join(FORK_ROOT, ".github", "workflows", "ai-service.yml")
        result = run_guard("Edit", {"file_path": path, "old_string": "a", "new_string": "b"})
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_edit_to_chatwoot_file_is_blocked(self):
        path = os.path.join(FORK_ROOT, "app", "models", "user.rb")
        result = run_guard("Edit", {"file_path": path, "old_string": "a", "new_string": "b"})
        self.assertEqual(result.returncode, 2)
        self.assertIn("app/models/user.rb is a Chatwoot file", result.stderr)

    def test_new_file_outside_ai_service_is_blocked(self):
        path = os.path.join(FORK_ROOT, "lib", "new_dir", "x.rb")
        result = run_guard("Write", {"file_path": path, "content": "x"})
        self.assertEqual(result.returncode, 2)

    def test_write_to_enterprise_is_blocked(self):
        path = os.path.join(FORK_ROOT, "enterprise", "app", "x.rb")
        result = run_guard("Write", {"file_path": path, "content": "x"})
        self.assertEqual(result.returncode, 2)
        self.assertIn("enterprise/", result.stderr)

    def test_read_of_enterprise_is_blocked(self):
        path = os.path.join(FORK_ROOT, "enterprise", "LICENSE")
        result = run_guard("Read", {"file_path": path})
        self.assertEqual(result.returncode, 2)

    def test_shell_cat_of_enterprise_is_blocked(self):
        result = run_guard("Bash", {"command": "cat enterprise/LICENSE"})
        self.assertEqual(result.returncode, 2)

    def test_shell_relative_path_into_enterprise_is_blocked(self):
        # Arrange: a session started inside ai-service/
        cwd = os.path.join(FORK_ROOT, "ai-service")
        # Act
        result = run_guard("Bash", {"command": "cat ../enterprise/LICENSE"}, cwd=cwd)
        # Assert
        self.assertEqual(result.returncode, 2)

    def test_shell_absolute_path_into_enterprise_is_blocked(self):
        path = os.path.join(FORK_ROOT, "enterprise", "LICENSE")
        result = run_guard("Bash", {"command": f"head -1 {path}"}, cwd="/tmp")
        self.assertEqual(result.returncode, 2)

    def test_text_mentioning_enterprise_is_allowed(self):
        result = run_guard("Bash", {"command": "git commit -m 'never open enterprise/'"})
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_file_outside_the_fork_is_allowed(self):
        with tempfile.TemporaryDirectory() as tmp:
            result = run_guard("Write", {"file_path": os.path.join(tmp, "notes.md"), "content": "x"})
        self.assertEqual(result.returncode, 0, result.stderr)


class SafeFetchTests(unittest.TestCase):
    def test_setting_it_in_a_file_is_blocked(self):
        path = os.path.join(FORK_ROOT, "ai-service", "deploy", "x.env")
        result = run_guard("Write", {"file_path": path, "content": SAFE_FETCH_ON + "\n"})
        self.assertEqual(result.returncode, 2)
        self.assertIn("SAFE_FETCH_ALLOW_PRIVATE_NETWORK", result.stderr)

    def test_setting_it_in_a_shell_is_blocked(self):
        result = run_guard("Bash", {"command": f"export {SAFE_FETCH_ON}"})
        self.assertEqual(result.returncode, 2)

    def test_setting_it_in_any_tool_is_blocked(self):
        result = run_guard("mcp__plugin_context-mode_context-mode__ctx_execute", {"code": f"env['{SAFE_FETCH_ON}']"})
        self.assertEqual(result.returncode, 2)

    def test_mentioning_it_unset_is_allowed(self):
        result = run_guard("Bash", {"command": "grep -n SAFE_FETCH_ALLOW_PRIVATE_NETWORK deploy/dokploy-compose.yml"})
        self.assertEqual(result.returncode, 0, result.stderr)


class BypassTests(unittest.TestCase):
    """Findings from the security review of PR #11."""

    def test_escaped_quotes_in_json_still_blocked(self):
        # Arrange: the value sits behind an escaped quote once JSON-encoded
        content = 'env:\n  "SAFE_FETCH_ALLOW_PRIVATE_NETWORK": "' + "true" + '"\n'
        path = os.path.join(FORK_ROOT, "ai-service", "deploy", "x.json")
        # Act
        result = run_guard("Write", {"file_path": path, "content": content})
        # Assert
        self.assertEqual(result.returncode, 2)

    def test_nested_edit_value_is_blocked(self):
        path = os.path.join(FORK_ROOT, "ai-service", "deploy", "x.env")
        edits = [{"old_string": "a", "new_string": SAFE_FETCH_ON}]
        result = run_guard("MultiEdit", {"file_path": path, "edits": edits})
        self.assertEqual(result.returncode, 2)

    def test_editing_the_guard_is_blocked(self):
        result = run_guard("Edit", {"file_path": GUARD, "old_string": "a", "new_string": "b"})
        self.assertEqual(result.returncode, 2)
        self.assertIn("guard", result.stderr)

    def test_editing_settings_is_blocked(self):
        path = os.path.join(FORK_ROOT, "ai-service", ".claude", "settings.json")
        result = run_guard("Write", {"file_path": path, "content": "{}"})
        self.assertEqual(result.returncode, 2)

    def test_shell_overwrite_of_guard_is_blocked(self):
        result = run_guard("Bash", {"command": "echo pass > ai-service/.claude/hooks/guard.py"})
        self.assertEqual(result.returncode, 2)

    def test_running_the_guard_tests_is_allowed(self):
        result = run_guard("Bash", {"command": "python3 -m unittest discover -s .claude/hooks"})
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_push_all_and_mirror_are_blocked(self):
        for flag in ("--all", "--mirror"):
            result = run_guard("Bash", {"command": f"git push {flag} origin"})
            self.assertEqual(result.returncode, 2, flag)

    def test_hooks_path_override_is_blocked(self):
        result = run_guard("Bash", {"command": "git -c core.hooksPath=/dev/null commit -m x"})
        self.assertEqual(result.returncode, 2)

    def test_alias_override_is_blocked(self):
        result = run_guard("Bash", {"command": "git -c alias.p='push origin develop' p"})
        self.assertEqual(result.returncode, 2)

    def test_push_inside_sh_c_is_blocked(self):
        result = run_guard("Bash", {"command": "sh -c 'git push origin develop'"})
        self.assertEqual(result.returncode, 2)

    def test_push_behind_env_is_blocked(self):
        result = run_guard("Bash", {"command": "env GIT_TRACE=1 git push origin develop"})
        self.assertEqual(result.returncode, 2)

    def test_enterprise_in_other_case_is_blocked(self):
        path = os.path.join(FORK_ROOT, "Enterprise", "LICENSE")
        result = run_guard("Read", {"file_path": path})
        self.assertEqual(result.returncode, 2)


class RobustnessTests(unittest.TestCase):
    def test_garbage_input_is_let_through(self):
        result = subprocess.run([sys.executable, GUARD], input="not json", capture_output=True, text=True)
        self.assertEqual(result.returncode, 0)


if __name__ == "__main__":
    unittest.main()
