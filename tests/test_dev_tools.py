import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

from test_scripts import REPO


class DevToolTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="dotfiles tools ")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.home = self.root / "home"
        self.home.mkdir()
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.node_bin = self.root / "fnm node/bin"
        self.node_bin.mkdir(parents=True)
        self.log = self.root / "calls.jsonl"
        self.env = {
            "PATH": str(self.bin),
            "HOME": str(self.home),
            "SHELL": "/bin/zsh",
            "TEST_LOG": str(self.log),
            "TEST_NODE_BIN": str(self.node_bin),
            "TEST_ROOT": str(self.root),
        }
        for name in ["bash", "sh", "cat", "mkdir", "dirname", "rm", "mktemp", "install"]:
            (self.bin / name).symlink_to(shutil.which(name))
        mock = self.root / "mock.py"
        mock.write_text(
            "#!" + shutil.which("python3") + "\n" + r'''
import json, os, sys
from pathlib import Path
name = Path(sys.argv[0]).name
args = sys.argv[1:]
home = Path(os.environ["HOME"])
root = Path(os.environ["TEST_ROOT"])
node_bin = Path(os.environ["TEST_NODE_BIN"])
with open(os.environ["TEST_LOG"], "a") as log:
    log.write(json.dumps([name, args, os.environ.get("SHELL")]) + "\n")

def executable(path, text="#!/bin/sh\nexit 0\n"):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)
    path.chmod(0o755)

if name == "uname":
    print(os.environ.get("TEST_OS", "Linux") if args == ["-s"] else "arm64")
elif name == "fnm":
    if args[0] == "exec":
        if not (root / "node-ready").exists():
            sys.exit(1)
        print(node_bin / "node")
    elif args[0] == "install":
        (root / "node-ready").touch()
elif name == "node":
    sys.exit(int(os.environ.get("TEST_NODE_STATUS", "0")))
elif name == "npm":
    assert args[:3] == ["install", "-g", "--prefix"], args
    assert args[3] == str(node_bin.parent), args
    package = args[4]
    tool = {"@github/copilot": "copilot"}.get(package, package)
    if tool == "corepack":
        (node_bin / tool).symlink_to(Path(__file__))
    else:
        executable(node_bin / tool)
elif name == "corepack":
    if args[0] == "install" and os.environ.get("FAIL_PNPM") == "1":
        sys.exit(17)
    if args[0] == "enable":
        executable(node_bin / "pnpm")
elif name == "uv":
    executable(home / ".local/bin/vibe")
elif name == "curl":
    url = next(arg for arg in args if arg.startswith("https://"))
    dest = Path(args[args.index("-o") + 1])
    if os.environ.get("FAIL_DOWNLOAD") in url:
        dest.write_text("touch \"$TEST_ROOT/partial-script-executed\"\n")
        sys.exit(22)
    urls = {
        "https://bun.sh/install": "bun",
        "https://claude.ai/install.sh": "claude",
        "https://chatgpt.com/codex/install.sh": "codex",
        "https://pi.dev/install.sh": "pi",
        "https://ampcode.com/install.sh": "amp",
        "https://cursor.com/install": "cursor-agent",
        "https://cli.devin.ai/install.sh": "devin",
        "https://app.factory.ai/cli": "droid",
        "https://cli.kiro.dev/install": "kiro-cli",
        "https://code.kimi.com/kimi-code/install.sh": "kimi",
        "https://opencode.ai/install": "opencode",
        "https://x.ai/cli/install.sh": "grok",
        "https://antigravity.google/cli/install.sh": "agy",
        "https://download.crew.kiro.dev/cli.sh": "kirocrew",
        "https://fx.sh/setup.sh": "fx",
        "https://dev.meta.ai/install.sh": "muse",
    }
    if "/forgecode/releases/latest/download/" in url:
        dest.write_text("#!/bin/sh\nexit 0\n")
    else:
        tool = urls[url]
        dest.write_text(
            "#!/bin/sh\n"
            "[ ! -t 0 ] && [ ! -t 1 ] || exit 19\n"
            + ("[ \"$SHELL\" = /bin/sh ] || exit 20\n" if tool in ["grok", "agy"] else "")
            + ('[ "${CODEX_NON_INTERACTIVE:-}" = 1 ] || exit 23\n' if tool == "codex" else "")
            + 'mkdir -p "$HOME/.local/bin"\n'
            + f"printf '#!/bin/sh\\nexit 0\\n' > \"$HOME/.local/bin/{tool}\"\n"
            + f'chmod +x "$HOME/.local/bin/{tool}"\n'
        )
'''
        )
        mock.chmod(0o755)
        for name in ["uname", "fnm", "uv", "curl"]:
            (self.bin / name).symlink_to(mock)
        (self.bin / "chmod").symlink_to(shutil.which("chmod"))
        for name in ["node", "npm"]:
            (self.node_bin / name).symlink_to(mock)
        # An unrelated Node/npm shim must never be used for global installs.
        for name in ["node", "npm"]:
            path = self.home / ".local/bin" / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text("#!/bin/sh\nexit 99\n")
            path.chmod(0o755)
        self.env["FAIL_DOWNLOAD"] = "no-such-url"

    def run_installer(self, *args, check=True):
        return subprocess.run(
            [str(self.bin / "bash"), str(REPO / "scripts/install-dev-tools.sh"), *args],
            env=self.env, text=True, capture_output=True, check=check,
        )

    def calls(self):
        return [json.loads(line) for line in self.log.read_text().splitlines()]

    def test_fresh_install_covers_tools_and_uses_fnm_prefix(self):
        result = self.run_installer()
        self.assertIn("Developer tools installed", result.stdout)
        calls = self.calls()
        self.assertIn(["fnm", ["install", "--lts"], "/bin/zsh"], calls)
        packages = [args[-1] for name, args, _ in calls if name == "npm"]
        self.assertEqual(packages, ["corepack", "@github/copilot", "cline", "mastracode"])
        self.assertTrue((self.home / ".local/bin/muse").exists())
        self.assertTrue((self.home / ".local/bin/forge").exists())
        self.assertIn(["uv", ["tool", "install", "--python", "3.12", "mistral-vibe"], "/bin/zsh"], calls)

    def test_codex_install_skips_launch_prompt_and_continues(self):
        self.env["CODEX_NON_INTERACTIVE"] = "0"
        result = self.run_installer()
        self.assertEqual(result.returncode, 0)
        self.assertTrue((self.home / ".local/bin/codex").exists())
        self.assertTrue((self.home / ".local/bin/muse").exists())
        self.assertIn("Developer tools installed", result.stdout)

    def test_second_run_does_not_reinstall_existing_tools(self):
        self.run_installer()
        self.log.write_text("")
        self.run_installer()
        self.assertFalse(any(name in ["curl", "npm", "uv", "corepack"] for name, _, _ in self.calls()))
        self.assertFalse(any(name == "fnm" and args[0] == "install" for name, args, _ in self.calls()))

    def test_dry_run_does_not_install_or_download(self):
        self.run_installer("--dry-run")
        self.assertTrue(all(name == "uname" for name, _, _ in self.calls()))
        self.assertFalse((self.root / "node-ready").exists())
        self.assertFalse((self.home / ".local/bin/claude").exists())

    def test_partial_download_is_never_executed(self):
        self.env["FAIL_DOWNLOAD"] = "claude.ai"
        result = self.run_installer(check=False)
        self.assertEqual(result.returncode, 22)
        self.assertNotIn("Developer tools installed", result.stdout)
        self.assertFalse((self.root / "partial-script-executed").exists())
        self.assertFalse((self.home / ".local/bin/codex").exists())
        self.assertIn("Fix the error above", result.stderr)

    def test_failed_pnpm_download_can_be_retried(self):
        self.env["FAIL_PNPM"] = "1"
        self.assertEqual(self.run_installer(check=False).returncode, 17)
        self.assertFalse((self.node_bin / "pnpm").exists())
        del self.env["FAIL_PNPM"]
        self.run_installer()
        self.assertTrue((self.node_bin / "pnpm").exists())

    def test_old_default_node_is_reported_without_changing_it(self):
        (self.root / "node-ready").touch()
        self.env["TEST_NODE_STATUS"] = "1"
        self.assertEqual(self.run_installer(check=False).returncode, 1)
        self.assertFalse(any(name in ["curl", "npm", "uv"] for name, _, _ in self.calls()))
        self.assertFalse(any(name == "fnm" and args[0] in ["install", "default"] for name, args, _ in self.calls()))

    def test_check_reports_missing_without_installing(self):
        result = self.run_installer("--check", check=False)
        self.assertEqual(result.returncode, 1)
        self.assertIn("[MISSING] claude", result.stdout)
        self.assertTrue(all(name == "uname" for name, _, _ in self.calls()))

    def test_mac_plan_selects_apple_silicon_forge(self):
        self.env["TEST_OS"] = "Darwin"
        result = self.run_installer("--dry-run")
        self.assertIn("forge-aarch64-apple-darwin", result.stdout)
