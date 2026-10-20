"""Offline integration check using existing Antidote and plugin checkouts."""

import os
from pathlib import Path
import subprocess
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[1]
SOURCES = ("ANTIDOTE_TEST_SOURCE", "ANTIDOTE_TEST_CACHE", "EZ_COMPINIT_TEST_DIR")


@unittest.skipUnless(all(os.environ.get(name) for name in SOURCES),
                     "Set Antidote test paths to run the offline plugin integration check")
class CompletionTests(unittest.TestCase):
    def test_plugin_completions_and_aliases_on_cold_and_cached_startup(self):
        with tempfile.TemporaryDirectory(prefix="completion test ") as directory:
            home = Path(directory)
            plugins = []
            for line in (REPO / "zsh/.zsh_plugins.txt").read_text().splitlines():
                if not line.strip() or line.startswith("#"):
                    continue
                repo, *options = line.split()
                path = (
                    Path(os.environ["EZ_COMPINIT_TEST_DIR"])
                    if repo == "mattmc3/ez-compinit"
                    else Path(os.environ["ANTIDOTE_TEST_CACHE"]) / repo
                )
                self.assertTrue(path.is_dir(), f"Missing plugin checkout: {path}")
                plugins.append(str(path) + " " + " ".join(options))
            (home / ".zsh_plugins.txt").write_text("\n".join(plugins) + "\n")
            config = (REPO / "zsh/.zshrc").read_text()
            start = config.index("# Completion paths")
            end = config.index("# Keep emacs keybindings", start)
            script = (
                'source "$ANTIDOTE_TEST_SOURCE"\n'
                + config[start:end]
                + '\nprint -r -- "tsc=${_comps[tsc]:-missing}"\n'
                + 'print -r -- "ggp=${_comps[ggp]:-missing}"\n'
            )
            env = {
                "HOME": str(home), "ZDOTDIR": str(home),
                "XDG_CACHE_HOME": str(home / ".cache"),
                "ANTIDOTE_HOME": str(home / "antidote"),
                "ANTIDOTE_TEST_SOURCE": os.environ["ANTIDOTE_TEST_SOURCE"],
                "ZSH": str(Path(os.environ["ANTIDOTE_TEST_CACHE"]) / "ohmyzsh/ohmyzsh"),
                "PATH": "/usr/bin:/bin", "TERM": "xterm-256color",
            }
            for _ in range(2):
                result = subprocess.run(
                    ["zsh", "-fc", script], env=env, cwd=home,
                    capture_output=True, text=True, timeout=30, check=True,
                )
                self.assertIn("tsc=_tsc", result.stdout)
                self.assertIn("ggp=_git", result.stdout)
                self.assertNotIn("command not found: compdef", result.stderr)
