import json
import os
from pathlib import Path
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
if os.environ.get("FAIL_PROVIDER") == sys.argv[1]:
    print("tmux provider failed", file=sys.stderr)
    sys.exit(1)
rows = {
    "list-windows": "  work:1 editor\\twindow:$1:@2\\n",
    "list-sessions": "  work\\tsession:$1\\n",
    "list-panes": "  work:1.1 shell\\tpane:$1:@2.%3\\n",
}
sys.stdout.write(rows.get(sys.argv[1], ""))
"""


class PaletteTests(unittest.TestCase):
    def run_palette(self, responses, fail_provider=""):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for name in ("fzf", "tmux"):
                executable = root / name
                executable.write_text(MOCK)
                executable.chmod(0o755)
            (root / "responses").write_text(json.dumps(responses))
            env = dict(os.environ, PATH=f"{root}:{os.environ['PATH']}",
                       TMUX="test", PALETTE_TEST=directory,
                       FAIL_PROVIDER=fail_provider)
            result = subprocess.run(
                ["bash", str(PALETTE)], env=env, text=True,
                capture_output=True, timeout=10,
            )
            calls = [json.loads(line) for line in
                     (root / "calls").read_text().splitlines()]
            return result, calls

    def test_commands_are_lazy_and_cancel_is_success(self):
        result, calls = self.run_palette([{"status": 130}])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual([call["tool"] for call in calls], ["fzf"])
        self.assertIn("New window", calls[0]["input"])
        self.assertTrue(any(arg.startswith("--header=  [ Commands ]")
                            for arg in calls[0]["args"]))

    def test_tabs_cache_queries_refresh_and_wrap(self):
        result, calls = self.run_palette([
            {"output": "split\nright\n"},
            {"output": "editor\nleft\n"},
            {"output": "split\nright\n"},
            {"output": "editor\nctrl-r\n"},
            {"output": "editor\nright\n"},
            {"output": "\nright\n"},
            {"output": "\nright\n"},
            {"output": "split\nleft\n"},
            {"status": 130},
        ])
        self.assertEqual(result.returncode, 0, result.stderr)
        providers = [call["args"][0] for call in calls
                     if call["tool"] == "tmux"]
        self.assertEqual(providers, [
            "list-windows", "list-windows", "list-sessions", "list-panes",
        ])
        screens = [call for call in calls if call["tool"] == "fzf"]
        self.assertIn("--query=split", screens[2]["args"])
        self.assertIn("--query=editor", screens[3]["args"])
        self.assertIn("--query=editor", screens[4]["args"])
        self.assertIn("--query=split", screens[7]["args"])
        self.assertTrue(any("[ Panes ]" in arg for arg in screens[8]["args"]))

    def test_selecting_targets_and_existing_commands(self):
        cases = [
            (0, "new-window", [["new-window"]]),
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
                           and not call["args"][0].startswith("list-")]
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


if __name__ == "__main__":
    unittest.main()
