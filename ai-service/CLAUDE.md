@AGENTS.md

# ai-service — Claude notes

- The repository-root `CLAUDE.md` is Chatwoot's Rails guide. It loads too when
  you work here, but `AGENTS.md` above governs everything in `ai-service/`.
- New session: read the workspace `HANDOFF.md` if it exists, then
  `ai-service.contract.md`.
- Push with the GitHub CLI credentials:
  `git -c credential.helper= -c 'credential.helper=!gh auth git-credential' push`.
- Secrets go through the masked secret box (`request_secret`), never the chat.
