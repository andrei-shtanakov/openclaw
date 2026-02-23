# Extension README Standardization — Design

## Goal

Add lightweight READMEs to all 20 extensions that lack them, following a consistent template. The Mintlify docs site already covers end-user setup in depth — these READMEs serve as in-repo signposts for contributors browsing the source.

## Template (channel extension)

```markdown
# <Extension Name> (OpenClaw plugin)

<One-line description.>

Docs: https://docs.openclaw.ai/channels/<name>

## Enable

\`\`\`bash
openclaw plugins enable <name>
\`\`\`

## Config

Minimal config in `openclaw.json`:

\`\`\`json5
{
channels: {
<name>: {
enabled: true,
// key config fields...
}
}
}
\`\`\`

See [full documentation](https://docs.openclaw.ai/channels/<name>) for all options.
```

Non-channel extensions use `plugins.entries.<name>` config path.

## Extensions to cover

### Channel extensions (15)

discord, slack, telegram, signal, whatsapp, imessage, irc, line, matrix, mattermost, feishu, googlechat, msteams, nextcloud-talk, synology-chat

### Non-channel extensions (5)

memory-core, memory-lancedb, diagnostics-otel, shared, thread-ownership

## Config extraction sources

1. `openclaw.plugin.json` configSchema (if has `properties`)
2. `docs/channels/<name>.md` (config section)
3. Source code (`channel.ts` config type) as fallback

## Existing READMEs

Leave as-is: voice-call, twitch, bluebubbles, llm-task, lobster, tlon, zalo, zalouser, nostr, and the 4 auth providers with experimental warnings.

## Commit strategy

One commit: `docs: add standard READMEs to 20 extensions`

## Verification

Run `pnpm docs:check-links` after to catch broken links.
