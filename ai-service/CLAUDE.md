@AGENTS.md

# ai-service — Claude notes

- The repository-root `CLAUDE.md` is Chatwoot's Rails guide. It loads too when
  you work here, but `AGENTS.md` above governs everything in `ai-service/`.
- New session: read the issue #1 checklist, `docs/decisions.md`, then
  `ai-service.contract.md`. For production work, `deploy/README.md`.
- Push with the GitHub CLI credentials:
  `git -c credential.helper= -c 'credential.helper=!gh auth git-credential' push`.
- Secrets go through the masked secret box (`request_secret`), never the chat.
