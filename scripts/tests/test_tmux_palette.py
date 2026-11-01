import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
import unittest


PALETTE = Path(__file__).resolve().parents[1] / "tmux-palette2"

MOCK = """#!/usr/bin/env python3
import json
import os
from pathlib import Path
import sys

root = Path(os.environ["PALETTE_TEST"])
tool = Path(sys.argv[0]).name
entry = {"tool": tool, "args": sys.argv[1:]}
if tool == "fzf":
    entry["input"] = sys.stdin.read()
with (root / "calls").open("a") as log:
    log.write(json.dumps(entry) + "\\n")
if tool == "fzf":
    step_file = root / "step"
    step = int(step_file.read_text()) if step_file.exists() else 0
    step_file.write_text(str(step + 1))
    response = json.loads((root / "responses").read_text())[step]
    sys.stdout.write(response.get("output", ""))
    sys.exit(response.get("status", 0))
if sys.argv[1] == "show-option":
    cache = root / "commands-cache"
    if cache.exists():
        sys.stdout.write(cache.read_text())
    sys.exit(0)
if sys.argv[1] == "set-option":
    (root / "commands-cache").write_text(sys.argv[-1])
    sys.exit(0)
if os.environ.get("FAIL_PROVIDER") == sys.argv[1]:
    print("tmux provider failed", file=sys.stderr)
    sys.exit(1)
if sys.argv[1] == "display-message":
    print(os.environ["PALETTE_FILES_ROOT"])
    sys.exit(0)
rows = {
    "list-windows": "  work:1 editor\\twindow:$1:@2\\n",
    "list-sessions": "  work\\tsession:$1\\n",
    "list-panes": "  work:1.1 shell\\tpane:$1:@2.%3\\n",
}
sys.stdout.write(rows.get(sys.argv[1], ""))
"""


class PaletteTests(unittest.TestCase):
    def run_palette(self, responses, fail_provider="", args=(), command_rows=None,
                    launches=1, command_rows_after_first=None):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for name in ("fzf", "tmux"):
                executable = root / name
                executable.write_text(MOCK)
                executable.chmod(0o755)
            files_root = root / "files"
            files_root.mkdir()
            (files_root / "example.txt").write_text("example\n")
            (files_root / "with space.txt").write_text("example\n")
            (root / "responses").write_text(
                json.dumps(responses)
                .replace("SPACE_PATH", str(files_root / "with space.txt"))
                .replace("PLACEHOLDER", str(files_root / "example.txt")))
            commands_file = root / "commands.tsv"
            if command_rows is not None:
                commands_file.write_text(command_rows)
            env = dict(os.environ, PATH=f"{root}:{os.environ['PATH']}",
                       TMUX="test", TMUX_PANE="%1", PALETTE_TEST=directory,
                       PALETTE_FILES_ROOT=str(files_root),
                       FAIL_PROVIDER=fail_provider)
            if command_rows is not None:
                env["TMUX_PALETTE_COMMANDS_FILE"] = str(commands_file)
            for launch in range(launches):
                if launch == 1 and command_rows_after_first is not None:
                    commands_file.write_text(command_rows_after_first)
                result = subprocess.run(
                    ["bash", str(PALETTE), *args], env=env, text=True,
                    capture_output=True, timeout=10,
                )
            calls = [json.loads(line) for line in
                     (root / "calls").read_text().splitlines()]
            return result, calls

    def test_commands_are_lazy_and_cancel_is_success(self):
        result, calls = self.run_palette([{"status": 130}])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual([call["args"][0] for call in calls if call["tool"] == "tmux"],
                         ["show-option", "set-option"])
        screen = next(call for call in calls if call["tool"] == "fzf")
        self.assertIn("New window", screen["input"])
        header = next(arg for arg in screen["args"] if arg.startswith("--header="))
        self.assertIn("\x1b[1m Commands ", header)
        self.assertEqual(header.count("\x1b[48;2;125;211;168m"), 1)
        self.assertNotIn("\n", header)
        self.assertNotIn("Left/Right", header)

    def test_tabs_cache_queries_refresh_and_wrap(self):
        result, calls = self.run_palette([
            {"output": "split\nright\n"},
            {"output": "editor\nleft\n"},
            {"output": "split\nright\n"},
            {"output": "editor\nctrl-r\n"},
            {"output": "editor\nright\n"},
            {"output": "\nright\n"},
            {"output": "\nright\n"},
            {"output": "split\nright\n"},
            {"status": 130},
        ])
        self.assertEqual(result.returncode, 0, result.stderr)
        providers = [call["args"][0] for call in calls
                     if call["tool"] == "tmux"
                     and call["args"][0] not in ("show-option", "set-option")]
        self.assertEqual(providers, [
            "list-windows", "list-windows", "list-sessions", "list-panes", "display-message",
        ])
        screens = [call for call in calls if call["tool"] == "fzf"]
        self.assertIn("--query=split", screens[2]["args"])
        self.assertIn("--query=editor", screens[3]["args"])
        self.assertIn("--query=editor", screens[4]["args"])
        self.assertIn("--query=", screens[7]["args"])
        self.assertIn("--query=split", screens[8]["args"])
        headers = [next(arg for arg in screen["args"] if arg.startswith("--header="))
                   for screen in screens]
        self.assertIn("\x1b[1m Commands ", headers[8])
        self.assertEqual(len({len(re.sub(r"\x1b\[[0-9;]*m", "", header))
                              for header in headers}), 1)

    def test_selecting_targets_and_existing_commands(self):
        cases = [
            (0, "new-window", [["new-window"]]),
            (0, "switch-tree", [["choose-tree", "-Z"]]),
            (1, "window:$1:@2", [
                ["switch-client", "-t", "$1"],
                ["select-window", "-t", "$1:@2"],
            ]),
            (2, "session:$1", [["switch-client", "-t", "$1"]]),
            (3, "pane:$1:@2.%3", [
                ["switch-client", "-t", "$1"],
                ["select-window", "-t", "$1:@2.%3"],
                ["select-pane", "-t", "$1:@2.%3"],
            ]),
        ]
        for tab, target, expected in cases:
            with self.subTest(target=target):
                result, calls = self.run_palette(
                    [{"output": "\nright\n"}] * tab +
                    [{"output": f"\n\n  selected\t{target}\n"}]
                )
                self.assertEqual(result.returncode, 0, result.stderr)
                actions = [call["args"] for call in calls
                           if call["tool"] == "tmux"
                           and not call["args"][0].startswith("list-")
                           and call["args"][0] not in ("show-option", "set-option")]
                self.assertEqual(actions, expected)

    def test_provider_failure_is_reported(self):
        result, _ = self.run_palette(
            [{"output": "\nright\n"}], fail_provider="list-windows",
        )
        self.assertEqual(result.returncode, 1)
        self.assertIn("tmux provider failed", result.stderr)
        self.assertIn("Failed to load Windows tab", result.stderr)

    def test_fzf_failure_is_not_treated_as_cancel(self):
        result, _ = self.run_palette([{"status": 2}])
        self.assertEqual(result.returncode, 2)
        self.assertIn("fzf failed", result.stderr)

    def test_empty_tab_can_still_switch(self):
        result, calls = self.run_palette([
            {"output": "\nright\n", "status": 1},
            {"status": 130},
        ])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(any(call["args"][0] == "list-windows"
                            for call in calls))

    def test_files_shortcut_inserts_path_at_current_cursor(self):
        result, calls = self.run_palette(
            [{"output": "\n\n  example.txt\tfile:PLACEHOLDER\n"}],
            args=("--files",),
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        search = next(call for call in calls if call["tool"] == "fzf")
        self.assertIn("example.txt", search["input"])
        self.assertTrue(any("\x1b[1m Files " in arg for arg in search["args"]))
        self.assertEqual(calls[-1]["args"],
                         ["send-keys", "-t", "%1", "-l", "--", "example.txt"])

    def test_inserted_file_path_is_shell_quoted(self):
        result, calls = self.run_palette(
            [{"output": "\n\n  with space.txt\tfile:SPACE_PATH\n"}],
            args=("--files",),
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(calls[-1]["args"],
                         ["send-keys", "-t", "%1", "-l", "--", r"with\ space.txt"])

    def test_custom_snippet_is_searchable_and_inserted_without_running(self):
        result, calls = self.run_palette(
            [{"output": "\n\n  Docker images\tsnippet:2\tDOCKER\tList images by size\tdocker images | sort\n"}],
            command_rows="# name\nDocker images\tDOCKER\tList images by size\tdocker images | sort\n",
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        search = next(call for call in calls if call["tool"] == "fzf")
        self.assertIn("Docker images", search["input"])
        self.assertIn("List images by size", search["input"])
        self.assertIn("\tsnippet:2\tDOCKER\tList images by size\tdocker images | sort", search["input"])
        self.assertTrue(any("{2} {3} {4} {5}" in arg for arg in search["args"]))
        self.assertEqual(calls[-1]["args"],
                         ["send-keys", "-t", "%1", "-l", "--", "docker images | sort"])

    def test_commands_cache_survives_reopen_until_refresh(self):
        result, calls = self.run_palette(
            [{"status": 130}, {"status": 130},
             {"output": "\nctrl-r\n"}, {"status": 130}],
            command_rows="Original\tSYSTEM\tOld description\techo old\n",
            command_rows_after_first="Updated\tSYSTEM\tNew description\techo new\n",
            launches=3,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        screens = [call["input"] for call in calls if call["tool"] == "fzf"]
        self.assertEqual(len(screens), 4)
        self.assertTrue(all("Original" in screen and "Updated" not in screen
                            for screen in screens[:3]))
        self.assertIn("Updated", screens[3])
        self.assertNotIn("Original", screens[3])
        self.assertEqual(sum(call["args"][0] == "set-option" for call in calls
                             if call["tool"] == "tmux"), 2)

    def test_snippet_preview_uses_cached_fields(self):
        result = subprocess.run(
            ["bash", str(PALETTE), "--preview", "snippet:2", "DOCKER",
             "List images by size", "docker images | sort"],
            env=dict(os.environ, TMUX_PALETTE_COMMANDS_FILE="/nonexistent/commands.tsv"),
            text=True, capture_output=True, timeout=10,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("List images by size", result.stdout)
        self.assertIn("\x1b[1;38;5;114mdocker images | sort\x1b[0m", result.stdout)


if __name__ == "__main__":
    unittest.main()
