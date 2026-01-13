# Avante.nvim Claude Max OAuth Fix

This document describes the issues and fixes required to use Claude Max subscription with avante.nvim via OAuth authentication.

## Background

PR [#2909](https://github.com/yetone/avante.nvim/pull/2909) added support for Claude Code Subscriptions (Claude Pro/Max) using OAuth/PKCE authentication. However, several issues prevent it from working out of the box.

## Solution

Use the forked repository with all fixes applied: [ghosert/avante.nvim](https://github.com/ghosert/avante.nvim)

In `~/.config/nvim/init.lua`, configure lazy.nvim to use the fork:
```lua
{
  'ghosert/avante.nvim',
  build = vim.fn.has 'win32' ~= 0 and 'powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false'
    or 'make',
  ...
}
```

## Prerequisites

### Sync Release Tags for Pre-built Binaries
**Error**: `cargo: command not found` during `:Lazy sync`

**Cause**: The fork doesn't have the same release tags as upstream, so the build script can't find pre-built binaries and falls back to building from source (which requires Rust).

**Fix**: Sync tags from upstream to your fork:
```bash
cd ~/tmp/avante.nvim

# Add upstream remote (if not already added)
git remote add upstream https://github.com/yetone/avante.nvim.git

# Fetch all tags from upstream
git fetch upstream --tags

# Push all tags to your fork (ghosert/avante.nvim)
git push origin --tags
```

Then run `:Lazy sync` in Neovim again.

### Install OpenSSL Development Libraries
**Error**: `Failed to generate PKCE verifier: please install openssl`

**Cause**: The PKCE implementation uses FFI bindings to load `libcrypto` (OpenSSL's shared library). Having the `openssl` CLI installed is not enough.

**Fix**:
```bash
sudo apt-get install libssl-dev
```

### Missing Native Libraries (macOS only so far)
**Error**: `Make sure to build avante (missing avante_templates)` when opening avante panel

**Cause**: The build script writes a `.tag` file to mark the version as "built" before/during downloading pre-built binaries. If the download is interrupted (network glitch, etc.), the `.tag` file exists but the actual `.dylib` files are missing. Next time the build runs, it sees the tag matches the latest release and skips downloading.

**Fix**:
```vim
:Lazy build avante.nvim
```

If that doesn't work (because the stale tag still exists), first delete the tag file:
```bash
rm ~/.local/share/nvim/lazy/avante.nvim/build/.tag
```

Then run `:Lazy build avante.nvim` again in Neovim.

## Issues Fixed in Fork

### Issue 1: OAuth URL Not Displayed in Terminal
**Error**: OAuth URL not shown when running in a terminal environment without a browser.

**Cause**: The code only shows the URL if `vim.ui.open` fails, but in terminal environments it may "succeed" without actually opening anything.

**Fix**: Always display the OAuth URL and copy to clipboard.

### Issue 2: API Request Failed with 400 Error
**Error**: `This credential is only authorized for use with Claude Code and cannot be used for other API requests.`

**Cause**: Anthropic validates OAuth requests to ensure they match Claude Code's request signature. Multiple factors contribute:

1. **Missing `?beta=true` query parameter**
2. **Wrong User-Agent header**
3. **Incorrect beta headers** (includes `fine-grained-tool-streaming` which is incompatible)
4. **Tool names trigger detection** (e.g., `bash`, `grep` match Claude Code's tool names)

**Fixes applied** (based on [opencode-anthropic-auth PR #10](https://github.com/anomalyco/opencode-anthropic-auth/pull/10) and [PR #11](https://github.com/anomalyco/opencode-anthropic-auth/pull/11)):

- Add `?beta=true` to API URL
- Set User-Agent header to `claude-cli/2.1.2 (external, cli)`
- Remove `fine-grained-tool-streaming` from beta headers
- Prefix tool names with `av_` to bypass Anthropic's tool name validation

## Configuration

In `~/.config/nvim/lua/avante/config.lua`, set:
```lua
claude = {
  endpoint = 'https://api.anthropic.com',
  model = 'claude-opus-4-5-20251101',  -- or other Claude models
  auth_type = 'max',  -- Enable Claude Max subscription via OAuth
  timeout = 30000,
  ...
}
```

## Token Storage

OAuth tokens are stored at:
```
~/.local/share/nvim/avante/claude-auth.json
```

To re-authenticate, delete this file and restart neovim.

## Authentication Flow

1. Start neovim and trigger avante (`<leader>va`)
2. OAuth URL is shown in a notification (check `:messages` if missed)
3. Open the URL in a browser and authenticate with your Claude Max account
4. After authentication, you'll be redirected to a page showing a code and state
5. Enter the code in the "Enter Auth Key" prompt in format: `code#state`

## Important Notes

1. **Terms of Service**: The revert PR [#2913](https://github.com/yetone/avante.nvim/pull/2913) mentions "Anthropic is not keen to allow people to do this." Use at your own discretion.

2. **Token Expiry**: Tokens are automatically refreshed. If authentication fails, delete `~/.local/share/nvim/avante/claude-auth.json` and re-authenticate.

3. **Model Compatibility**: Tested with `claude-opus-4-5-20251101` and `claude-sonnet-4-5-20250929`.

## References

- [ghosert/avante.nvim](https://github.com/ghosert/avante.nvim) - Forked repo with OAuth fixes
- [avante.nvim PR #2909](https://github.com/yetone/avante.nvim/pull/2909) - Claude Code Subscriptions support
- [avante.nvim PR #2913](https://github.com/yetone/avante.nvim/pull/2913) - Revert PR (still open)
- [opencode-anthropic-auth PR #10](https://github.com/anomalyco/opencode-anthropic-auth/pull/10) - Tool name prefixing
- [opencode-anthropic-auth PR #11](https://github.com/anomalyco/opencode-anthropic-auth/pull/11) - Request shape alignment
