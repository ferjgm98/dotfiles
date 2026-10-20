import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[1]


def snapshot(root):
    return {
        str(path.relative_to(root)): (
            ("link", os.readlink(path)) if path.is_symlink()
            else ("dir",) if path.is_dir()
            else ("file", path.read_bytes())
        )
        for path in root.rglob("*")
    }


class ScriptTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="dotfiles test ")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.repo = self.root / "repo"
        shutil.copytree(REPO / "scripts", self.repo / "scripts")
        for name in [
            "zsh/.zshrc", "zsh/.zsh_plugins.txt", "tmux/.tmux.conf",
            "tmux/scripts/git-status.sh",
            ".gitconfig", "starship/starship.toml", "nvim/nvim/init.lua",
        ]:
            path = self.repo / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text("repo config\n")
        self.home = self.root / "home"
        self.home.mkdir()
        self.env = {
            "PATH": os.environ["PATH"],
            "HOME": str(self.home),
            "XDG_CONFIG_HOME": str(self.home / ".config"),
            "XDG_DATA_HOME": str(self.home / ".local/share"),
            "ZDOTDIR": str(self.home),
        }

    def run_script(self, name, *args):
        return subprocess.run(
            ["bash", str(self.repo / "scripts" / name), *args],
            env=self.env, capture_output=True, text=True, check=True,
        )

    def test_link_is_repeatable(self):
        self.run_script("link.sh")
        before = snapshot(self.root)
        self.run_script("link.sh")
        self.assertEqual(before, snapshot(self.root))
        self.assertFalse((self.repo / "nvim/nvim/nvim").is_symlink())

    def test_link_preserves_files_directories_and_broken_symlinks(self):
        (self.home / ".zshrc").write_text("custom")
        (self.home / ".config/nvim").mkdir(parents=True)
        (self.home / ".config/nvim/init.lua").write_text("custom nvim")
        (self.home / ".tmux.conf").symlink_to("missing")
        self.run_script("link.sh")
        self.assertEqual(next(self.home.glob(".zshrc.bak.*")).read_text(), "custom")
        backup = next((self.home / ".config").glob("nvim.bak.*"))
        self.assertEqual((backup / "init.lua").read_text(), "custom nvim")
        self.assertEqual(os.readlink(next(self.home.glob(".tmux.conf.bak.*"))), "missing")

    def test_link_dry_run_writes_nothing(self):
        before = snapshot(self.root)
        self.run_script("link.sh", "--dry-run")
        self.run_script("link-extras.sh", "--dry-run")
        self.assertEqual(before, snapshot(self.root))

    def test_custom_config_and_shell_directories(self):
        self.env["XDG_CONFIG_HOME"] = str(self.home / "config elsewhere")
        self.env["ZDOTDIR"] = str(self.home / "shell elsewhere")
        self.run_script("link.sh")
        self.assertTrue((self.home / "config elsewhere/nvim").is_symlink())
        self.assertTrue((self.home / "shell elsewhere/.zshrc").is_symlink())
        self.run_script("capture.sh", "--force", "--no-extras")
        self.assertFalse((self.repo / "zsh/.zshrc").is_symlink())

    def test_capture_linked_repo_is_noop(self):
        self.run_script("link.sh")
        before = snapshot(self.root)
        self.run_script("capture.sh", "--force", "--delete", "--no-extras")
        self.assertEqual(before, snapshot(self.root))

    def test_capture_dry_run_writes_nothing(self):
        (self.home / ".gitignore_global").write_text("test")
        (self.home / ".config/ghostty").mkdir(parents=True)
        (self.home / ".config/ghostty/config").write_text("test")
        before = snapshot(self.root)
        self.run_script("capture.sh", "--dry-run")
        self.assertEqual(before, snapshot(self.root))

    def test_capture_requires_force_without_terminal(self):
        (self.home / ".zshrc").write_text("new shell")
        (self.home / ".config/nvim").mkdir(parents=True)
        (self.home / ".config/nvim/init.lua").write_text("new nvim")
        before = snapshot(self.repo)
        self.run_script("capture.sh", "--delete", "--no-extras")
        self.assertEqual(before, snapshot(self.repo))

    def test_capture_copies_symlink_contents(self):
        source = self.home / "shell-config"
        source.write_text("custom")
        (self.home / ".zshrc").symlink_to(source)
        self.run_script("capture.sh", "--force", "--no-extras")
        dest = self.repo / "zsh/.zshrc"
        self.assertFalse(dest.is_symlink())
        self.assertEqual(dest.read_text(), "custom")

    def test_capture_keeps_neovim_plugin_definitions(self):
        plugins = self.home / ".config/nvim/lua/plugins"
        plugins.mkdir(parents=True)
        (plugins / "test.lua").write_text("return {}")
        self.run_script("capture.sh", "--force", "--no-extras")
        self.assertEqual(
            (self.repo / "nvim/nvim/lua/plugins/test.lua").read_text(), "return {}",
        )

    def test_capture_skips_npm_credentials(self):
        (self.home / ".npmrc").write_text("//example.invalid/:_authToken=test")
        self.run_script("capture.sh", "--force")
        self.assertFalse((self.repo / "extras/home/.npmrc").exists())

    def test_capture_does_not_follow_destination_symlink(self):
        outside = self.root / "outside"
        outside.write_text("keep")
        dest = self.repo / "zsh/.zshrc"
        dest.unlink()
        dest.symlink_to(outside)
        (self.home / ".zshrc").write_text("replace")
        self.run_script("capture.sh", "--force", "--no-extras")
        self.assertEqual(outside.read_text(), "keep")

    def test_extras_respect_no_desktop(self):
        for name in ["ghostty", "hypr"]:
            (self.repo / "extras/config" / name).mkdir(parents=True)
        self.run_script("link-extras.sh", "--no-desktop")
        self.assertTrue((self.home / ".config/ghostty").is_symlink())
        self.assertFalse((self.home / ".config/hypr").exists())
        before = snapshot(self.root)
        self.run_script("link-extras.sh", "--no-desktop")
        self.assertEqual(before, snapshot(self.root))

    def test_qwen_wrapper_runs_external_command(self):
        config = (REPO / "zsh/.zshrc").read_text()
        wrapper = re.search(r"^qwen\(\) \{\n.*?^\}", config, re.M | re.S).group()
        bin_dir = self.root / "bin"
        bin_dir.mkdir()
        for name, body in [
            ("op", "printf 'test-token'"),
            ("qwen", 'printf "%s\\n" "$OPENAI_API_KEY" "$OPENAI_MODEL" "$@"'),
        ]:
            command = bin_dir / name
            command.write_text("#!/bin/sh\n" + body + "\n")
            command.chmod(0o755)
        env = dict(self.env, PATH=str(bin_dir) + ":" + self.env["PATH"])
        result = subprocess.run(
            ["zsh", "-fc", wrapper + '\nqwen "argument with spaces"'],
            env=env, capture_output=True, text=True, check=True,
        )
        self.assertEqual(
            result.stdout.splitlines(),
            ["test-token", "qwen3-coder-plus", "argument with spaces"],
        )

    def test_secrets_loader_preserves_environment_when_op_fails(self):
        config = (REPO / "zsh/.zshrc").read_text()
        loader = re.search(r"^secrets_on\(\) \{\n.*?^\}", config, re.M | re.S).group()
        bin_dir = self.root / "bin"
        bin_dir.mkdir()
        command = bin_dir / "op"
        command.write_text("#!/bin/sh\nprintf 'export TEST_VALUE=partial'\nexit 7\n")
        command.chmod(0o755)
        env = dict(self.env, PATH=str(bin_dir) + ":" + self.env["PATH"])
        result = subprocess.run(
            ["zsh", "-fc", loader + '\nTEST_VALUE=original\nsecrets_on\n'
             'result=$?\nprintf "%s %s" "$result" "$TEST_VALUE"'],
            env=env, capture_output=True, text=True, check=True,
        )
        self.assertEqual(result.stdout, "7 original")

    def test_secrets_loader_applies_successful_output(self):
        config = (REPO / "zsh/.zshrc").read_text()
        loader = re.search(r"^secrets_on\(\) \{\n.*?^\}", config, re.M | re.S).group()
        bin_dir = self.root / "bin"
        bin_dir.mkdir()
        command = bin_dir / "op"
        command.write_text("#!/bin/sh\nprintf 'export TEST_VALUE=loaded'\n")
        command.chmod(0o755)
        env = dict(self.env, PATH=str(bin_dir) + ":" + self.env["PATH"])
        result = subprocess.run(
            ["zsh", "-fc", loader + '\nsecrets_on\nprintf "%s" "$TEST_VALUE"'],
            env=env, capture_output=True, text=True, check=True,
        )
        self.assertEqual(result.stdout, "loaded")

    def test_capture_reports_skipped_external_symlinks(self):
        source = self.home / ".config/nvim"
        source.mkdir(parents=True)
        outside = self.root / "outside.lua"
        outside.write_text("external")
        (source / "settings.lua").symlink_to(outside)
        dest = self.repo / "nvim/nvim/settings.lua"
        dest.write_text("old")
        result = self.run_script("capture.sh", "--force", "--delete", "--no-extras")
        self.assertIn("settings.lua", result.stdout + result.stderr)
        self.assertIn("unsafe symlink", result.stdout + result.stderr)
        self.assertEqual(dest.read_text(), "old")

    def prepare_bootstrap(self, bob_status=0):
        bin_dir = self.root / "bin"
        bin_dir.mkdir()
        (self.home / ".tmux/plugins/tpm").mkdir(parents=True)
        commands = {
            "uname": "echo Darwin",
            "xcode-select": "exit 0",
            "brew": "exit 0",
            "bun": "exit 0",
            "pnpm": "exit 0",
            "bob": (
                'printf "%s\\n" "$*" >> "$TEST_LOG"\n'
                f"exit {bob_status}"
            ),
        }
        for name, body in commands.items():
            command = bin_dir / name
            command.write_text("#!/bin/sh\n" + body + "\n")
            command.chmod(0o755)
        # Keep an installed system Neovim from changing the fresh-machine fixture.
        for name in ["bash", "dirname", "mkdir", "date", "mv", "ln"]:
            (bin_dir / name).symlink_to(shutil.which(name))
        self.env.update(
            PATH=str(bin_dir),
            SHELL="/bin/zsh",
            TEST_LOG=str(self.root / "bob.log"),
        )

    def test_bootstrap_selects_neovim_on_fresh_mac(self):
        self.prepare_bootstrap()
        self.run_script("bootstrap-macos.sh")
        self.assertEqual((self.root / "bob.log").read_text(), "use stable\n")

    def test_bootstrap_preserves_existing_bob_neovim(self):
        self.prepare_bootstrap()
        nvim = self.home / ".local/share/bob/nvim-bin/nvim"
        nvim.parent.mkdir(parents=True)
        nvim.write_text("#!/bin/sh\nexit 0\n")
        nvim.chmod(0o755)
        self.run_script("bootstrap-macos.sh")
        self.assertFalse((self.root / "bob.log").exists())

    def test_bootstrap_stops_when_neovim_install_fails(self):
        self.prepare_bootstrap(bob_status=7)
        with self.assertRaises(subprocess.CalledProcessError) as error:
            self.run_script("bootstrap-macos.sh")
        self.assertEqual(error.exception.returncode, 7)
        self.assertNotIn("Bootstrap complete!", error.exception.stdout)

    def test_git_credentials_resolve_gh_through_path(self):
        bin_dir = self.root / "custom prefix/bin"
        bin_dir.mkdir(parents=True)
        gh = bin_dir / "gh"
        gh.write_text(
            '#!/bin/sh\nprintf "%s\\n" "$*" > "$TEST_LOG"\n'
            "printf 'username=test-user\\npassword=test-only\\n'\n"
        )
        gh.chmod(0o755)
        env = dict(
            self.env,
            PATH=str(bin_dir) + ":/usr/bin:/bin",
            TEST_LOG=str(self.root / "gh.log"),
            GIT_CONFIG_GLOBAL=str(REPO / ".gitconfig"),
            GIT_CONFIG_NOSYSTEM="1",
            GIT_TERMINAL_PROMPT="0",
        )
        for host in ["github.com", "gist.github.com"]:
            result = subprocess.run(
                ["git", "credential", "fill"],
                input=f"protocol=https\nhost={host}\n\n",
                env=env, cwd=self.root, text=True, capture_output=True, check=True,
            )
            self.assertIn("username=test-user", result.stdout)
            self.assertEqual((self.root / "gh.log").read_text(), "auth git-credential get\n")

    def test_tmux_status_handles_git_directory_with_spaces(self):
        project = self.root / "project with spaces"
        project.mkdir()
        env = dict(self.env, GIT_CONFIG_NOSYSTEM="1")
        def git(*args):
            subprocess.run(
                ["git", *args], cwd=project, env=env,
                capture_output=True, text=True, check=True,
            )
        git("init", "-b", "main")
        git("-c", "user.name=Test", "-c", "user.email=test@example.invalid",
            "commit", "--allow-empty", "-m", "Initial")
        (project / "new.txt").write_text("new")
        result = subprocess.run(
            ["bash", str(REPO / "tmux/scripts/git-status.sh"), str(project)],
            env=env, capture_output=True, text=True, check=True,
        )
        self.assertIn("main", result.stdout)
        self.assertIn("~1", result.stdout)


if __name__ == "__main__":
    unittest.main()
