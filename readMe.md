# Claude Code Status Line

A custom status line for Claude Code that displays model info, token usage, and rate limits — with multiple color themes (Catppuccin, Tokyo Night, Dracula, Nord).

---

### 1. Navigate to the Claude config directory

```bash
cd ~/.claude
```

Make sure `settings.json` includes the following:

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh",
    "padding": 2
  }
}
```

### 2. Create the `statusline.sh` file

Copy `statusline.sh` from this repo into `~/.claude/statusline.sh`.

### 3. Add execute permission

```bash
chmod +x statusline.sh
```

### 4. Enjoy

Open Claude Code — the status line will appear automatically.
