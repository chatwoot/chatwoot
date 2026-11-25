<div align="center">

<picture>
  <source media="(prefers-color-scheme: dark)" srcset=".github/brand/logo-dark.png">
  <source media="(prefers-color-scheme: light)" srcset=".github/brand/logo-light.png">
  <img src=".github/brand/logo-light.png" alt="fazer.ai" width="200">
</picture>

<h1>Chatwoot fazer.ai</h1>

<p>Official Chatwoot, with the features needed to serve customers in Brazil.</p>
<p>WhatsApp customer support on your server, with an open-source edition and a Pro option.</p>

[Português (Brasil)](README.md) · **English**

[![Release](https://img.shields.io/github/v/release/fazer-ai/chatwoot)](https://github.com/fazer-ai/chatwoot/releases)
[![Downloads](https://img.shields.io/endpoint?url=https%3A%2F%2Ffazer.ai%2Fapi%2Fbadges%2Fchatwoot-downloads)](https://github.com/fazer-ai/chatwoot/pkgs/container/chatwoot)

</div>

## About

Chatwoot fazer.ai is a fork of official Chatwoot, maintained by fazer.ai (FAZER.AI LTDA). Chatwoot Inc. develops the original product and is a separate company.

The fork follows official Chatwoot releases and adds features for teams that set up and operate WhatsApp customer support. You can use the open-source edition for free or subscribe to Chatwoot fazer.ai Pro to add the sales Kanban.

## What fazer.ai adds

### WhatsApp

- Connect by scanning a QR code with your phone, without a paid third-party API, or through the official API with WhatsApp Business app coexistence.
- fazer.ai's own QR code provider, “WhatsApp (native)”, in beta. Runs on your installation's server without a third-party service, using an [open-source Go connector](https://github.com/fazer-ai/whatsapp-connector) maintained by fazer.ai.
- Change an inbox's connection method without losing its history.
- Import your phone's message history when connecting.
- WhatsApp groups.
- Reactions and quoted replies, plus message editing and deletion.
- Typing and audio recording indicators.
- Voice notes are sent as voice notes instead of audio files.
- Contact profile photos retrieved from WhatsApp.

### Internal team chat

Agents communicate within the support platform, through public or private channels and direct messages.

- Threads and reactions, with conversation mentions.
- Paste or drag files to attach them, with support for message drafts.
- Native notifications and a mobile layout.

The Pro edition provides the full internal chat.

### Conversations and messages

- Scheduled messages, including recurring messages or WhatsApp templates. You can hold a scheduled message if the customer replies first.
- Edit sent messages while retaining their content history.
- Pin conversations or mark them as unread.
- Keep a conversation assigned to the agent who claimed it.
- Per-inbox signatures.
- Personal or shared custom filters, including filters for contacts or conversations missing a custom attribute.

### Automations and integrations

- Triggers for edited messages and conversations idle for a set period.
- Observer bots receive everything that happens in an inbox without replying or taking over conversations. They can classify or review customer support while the team or another bot responds.
- Per-inbox webhooks, with incoming or outgoing message events and retries on failure.
- n8n node: [`@fazer-ai/n8n-nodes-chatwoot`](https://www.npmjs.com/package/@fazer-ai/n8n-nodes-chatwoot).
- [fazer.ai agents](https://fazer.ai/agents): AI agents that handle conversations through either edition of Chatwoot, with [source code on GitHub](https://github.com/fazer-ai/agents).

### Operations

- Interface in Portuguese or the account's language, along with transactional emails and activity messages.
- White labeling with your own name and logo, plus brand colors and branded emails. See [CUSTOM_BRANDING.md](CUSTOM_BRANDING.md).
- Email delivery through Resend and storage through S3-compatible services, such as R2 or MinIO.
- Bulk email imports through IMAP.
- Reports sortable by any column, with cross-tabulated views across agents, inboxes, and teams.

See changes for each version in the [release notes](https://fazer.ai/chatwoot-release-notes) or [GitHub releases](https://github.com/fazer-ai/chatwoot/releases).

## Editions

| | Chatwoot fazer.ai | Chatwoot fazer.ai Pro |
| --- | --- | --- |
| Core features | Official Chatwoot with fazer.ai additions | Everything in the open-source edition |
| Sales Kanban | No | Pipelines and deals with monetary values, products, tasks, automations, and pipeline reports |
| Internal chat | Up to 2 private channels, search within the last 90 days, no polls | Full internal chat, without these limits and with polls |
| License | Free, MIT outside `enterprise/` | fazer.ai's own license for Pro code, in a separate repository |
| Docker image | Public: `ghcr.io/fazer-ai/chatwoot` | Private, available with a subscription |

Explore the [Pro Kanban](https://fazer.ai/kanban) and activate your license at [app.fazer.ai](https://app.fazer.ai). A Chatwoot fazer.ai Pro license is included at no extra charge with a Pro subscription to the [Comunidade Lucas Moreira](https://www.lucasmoreira.ai).

A Chatwoot fazer.ai Pro license covers one installation (one domain), with no user limit, and applies to all accounts within that installation. You can serve your own clients through accounts in your installation, including giving them access to the dashboard. Each separate installation needs its own license; see the [terms of use](https://fazer.ai/termos-kanban).

### Chatwoot Enterprise

fazer.ai licenses do not include Chatwoot Enterprise features. SSO and Captain, along with audit logs and custom roles, are licensed by Chatwoot Inc.

To use these features with the fork, purchase a license from Chatwoot Inc. and set `CW_EDITION=ee` on the web and Sidekiq services of the `ghcr.io/fazer-ai/chatwoot` image. The variable does not replace the license.

With `CW_EDITION=ee`, the container downloads at boot the `enterprise/` directory from the official Chatwoot tag that matches the image version, checks its contents against the hash pinned at build time, and keeps a copy in `storage/.cw-enterprise`. The first boot of each version needs access to `codeload.github.com`, and later boots use the stored copy. If the download or the check fails, the container does not start and the log says why; the tuning variables are described in `docker/entrypoints/helpers/enterprise.sh`.

With `CW_EDITION=ee`, the Enterprise code runs exactly as Chatwoot Inc. publishes it for that version, without any modifications or patches from the fork. The fork's super admin “Branding” page is only available without Enterprise; with Enterprise enabled, branding follows its own rules: customization is a premium feature, and the community plan resets the branding keys to their defaults. See [CUSTOM_BRANDING.md](CUSTOM_BRANDING.md) for details.

This applies to the Docker image. In an installation run from source, the checkout's `enterprise/` directory is loaded whenever it exists, with or without `CW_EDITION`; to run the Community edition, remove the directory.

## Install

### With the fazer.ai agents installer

The shortest path is the [fazer.ai agents installer](https://fazer.ai/agents). A coding agent guides the installation of Chatwoot fazer.ai and the AI agent, together with the supporting services, on a VPS.

### Chatwoot only, with Docker

Use the public `ghcr.io/fazer-ai/chatwoot:latest` image. If you have an existing installation, back up the database before replacing the official image and follow the migration steps below.

The repository includes [docker-compose.coolify.yaml](docker-compose.coolify.yaml) and a [Coolify deployment guide](docker/README-coolify-deploy.md), written in Portuguese.

Fork-specific environment variables are documented in [.env.example](.env.example). The public image provides the `latest` tag and a tag for each release.

### WhatsApp (native)

The connector comes with the Chatwoot fazer.ai image and runs in the Sidekiq container, on by default for every account. It uses the same Redis and creates its own database on the same PostgreSQL server on first start. To turn it off, set:

```bash
WHATSAPP_CONNECTOR_ENABLED=false
```

To run the connector as a separate service in your stack, set `WHATSAPP_CONNECTOR_EMBEDDED=false`. The [connector README](https://github.com/fazer-ai/whatsapp-connector/blob/main/README-en.md#install-with-chatwoot-fazerai) covers both modes step by step, with docker-compose examples and inbox migration.

> [!WARNING]
> If you already run the connector separately, set `WHATSAPP_CONNECTOR_EMBEDDED=false` before updating the image. Otherwise, a second connector starts and competes for the same sessions.

## Update and migrate from official Chatwoot

### Update

1. Back up the database before changing the image.
2. Pull the new image and restart the services from the panel where Chatwoot runs.

To pin a version, use its release tag instead of `latest`.

`-ee` tags are no longer published; existing installations using them keep running but stay on the last published version without updates. To keep receiving updates, switch to `ghcr.io/fazer-ai/chatwoot`, using `latest` or a version tag without `-ee`, and set `CW_EDITION=ee` on web and Sidekiq. With this setting, the first boot of each version downloads the Enterprise code from the official Chatwoot tag and takes a few extra seconds: it needs outbound access to GitHub and a persistent `/app/storage` volume shared by web and Sidekiq, already provided by the example Compose configurations and the installer. If you use the standard image without Enterprise, nothing changes; see [Chatwoot Enterprise](#chatwoot-enterprise) for details.

### Migrate from official Chatwoot

1. Choose a fork version equal to or newer than your installed version.
2. Back up the database before changing the image.
3. Replace the official image with `ghcr.io/fazer-ai/chatwoot`, using your chosen tag, then restart the services.

Your database and attachments are preserved, along with your settings.

## Support and community

- Installation and usage questions: [Comunidade Lucas Moreira Q&A](https://www.lucasmoreira.ai/c/perguntas-e-respostas).
- Bugs and feature requests: [GitHub issues](https://github.com/fazer-ai/chatwoot/issues).
- Videos in Portuguese: [Lucas Moreira's channel](https://youtube.com/@eulucassmoreira).
- API documentation, including Kanban: [docs-chatwoot.fazer.ai](https://docs-chatwoot.fazer.ai).

## License

The original Chatwoot is copyright (c) 2017-2026 Chatwoot Inc. and uses the MIT license, except for content in `enterprise/`. That directory follows the terms in [enterprise/LICENSE](enterprise/LICENSE).

Modifications and additions in this fork are copyright (c) 2025-2026 FAZER.AI LTDA. They follow the same terms as the code they extend, with the MIT license applying outside `enterprise/`. Third-party components retain their respective licenses.

When redistributing the software or substantial portions of it, keep both copyright notices and the permission notice. This requirement also applies to copies of individual files.

See [NOTICE](NOTICE) and [LICENSE](LICENSE) for the full terms.

## Links

- [Chatwoot fazer.ai](https://fazer.ai/chatwoot)
- [fazer.ai licenses](https://app.fazer.ai)
- [Official Chatwoot](https://www.chatwoot.com)
- [Official Chatwoot source code](https://github.com/chatwoot/chatwoot)

Maintained by fazer.ai.
