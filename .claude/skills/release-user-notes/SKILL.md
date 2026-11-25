---
name: release-user-notes
description: Use this skill whenever you are about to cut, edit, or backfill a GitHub release for fazer-ai/chatwoot. Generates the user-notes blocks in the three languages the product ships (en, pt-BR, es) embedded in the release body for non-technical end users. Trigger before calling `gh release create`, `gh release edit`, or any flow that touches a release body on this repo (including the `release` skill from fazer-ai-tools and any retroactive backfill of historical releases).
allowed-tools: Bash, Read, Edit, Write, Grep, Glob
---

# Release Notes (user-facing)

Every release cut from `fazer-ai/chatwoot` must embed user-notes blocks in the release body, one per language the product ships, written for non-technical end users (operators, admins, superadmins). Do not put implementation detail in these blocks.

## Required blocks (three languages, all mandatory)

The product ships in **en, pt-BR and es** (see **Fork translations** in `AGENTS.md`), so the release body carries a block for each, in this order. Use H2 headings with flags **outside** the blocks to separate the sections visually on GitHub. The fazer.ai page only renders the content **inside** the `<!-- user-notes:xx:start -->` / `<!-- user-notes:xx:end -->` markers, so the H2 headings, the flags, and any commit list above are invisible there.

```markdown
## 🇺🇸 English

<!-- user-notes:en:start -->
... markdown in english ...
<!-- user-notes:en:end -->

## 🇧🇷 Português

<!-- user-notes:pt-BR:start -->
... markdown em português ...
<!-- user-notes:pt-BR:end -->

## 🇪🇸 Español

<!-- user-notes:es:start -->
... markdown en español ...
<!-- user-notes:es:end -->
```

The three versions must be **equivalent in content**, written naturally in each language. They are **not** literal translations:
- en: "Drag conversations between columns faster."
- pt-BR: "Agora você pode arrastar conversas entre colunas mais rápido."
- es: "Ahora puedes arrastrar conversaciones entre columnas más rápido."

## Mirroring upstream releases

Downstream forks (e.g. `fazer-ai/chatwoot-pro`) that mirror a CE release must declare it with a blockquote at the top of each user-notes block, inside the markers. List all mirrored CE versions when there's more than one. CE releases never carry this marker.

```markdown
<!-- user-notes:en:start -->
> Includes changes from Chatwoot fazer.ai v4.12.0-fazer-ai.47.
...
<!-- user-notes:en:end -->

<!-- user-notes:pt-BR:start -->
> Inclui mudanças do Chatwoot fazer.ai v4.12.0-fazer-ai.47.
...
<!-- user-notes:pt-BR:end -->

<!-- user-notes:es:start -->
> Incluye cambios de Chatwoot fazer.ai v4.12.0-fazer-ai.47.
...
<!-- user-notes:es:end -->
```

## Upstream sync releases (CE)

When a CE release contains a merge with official Chatwoot (`chore/merge-upstream-X.Y.Z`), do **not** enumerate upstream features in the user-notes blocks. Only declare the sync with a blockquote at the top of each block, linking to the official upstream release notes (list every upstream version covered by the merge):

```markdown
<!-- user-notes:en:start -->
> This release includes the merge with official Chatwoot 4.14.1 and 4.14.2. See the official release notes for the full list of upstream changes: https://github.com/chatwoot/chatwoot/releases/tag/v4.14.1 and https://github.com/chatwoot/chatwoot/releases/tag/v4.14.2
...
<!-- user-notes:en:end -->

<!-- user-notes:pt-BR:start -->
> Esta release inclui o merge com o Chatwoot oficial 4.14.1 e 4.14.2. Para a lista completa de mudanças do upstream, consulte as notas oficiais: https://github.com/chatwoot/chatwoot/releases/tag/v4.14.1 e https://github.com/chatwoot/chatwoot/releases/tag/v4.14.2
...
<!-- user-notes:pt-BR:end -->

<!-- user-notes:es:start -->
> Esta versión incluye la fusión con Chatwoot oficial 4.14.1 y 4.14.2. Para ver la lista completa de cambios del upstream, consulta las notas oficiales: https://github.com/chatwoot/chatwoot/releases/tag/v4.14.1 y https://github.com/chatwoot/chatwoot/releases/tag/v4.14.2
...
<!-- user-notes:es:end -->
```

After the blockquote, list only:

- fork-specific changes shipped in the same release, and
- specific items the team explicitly asks to call out (e.g. an upstream fix that resolves a problem our users actually hit).

If nothing qualifies, the blockquote alone is a valid block body. See `v4.14.0-fazer-ai.74` for reference.

## Audience and tone

Write for an **end user, not a developer**. Readers do not read code, do not know what a PR is, and do not care about refactors.

- **Present tense, active voice.** "Agora você pode reordenar etiquetas" / "You can now reorder labels". Not "Adicionada a possibilidade de…" / "Added the ability to…".
- **Lead with benefit, not implementation.** "Carregamento mais rápido em conexões lentas" / "Faster loading on slow connections" beats "Preload de componentes de rota no módulo internal-chat".
- **Plain language.** No jargon, no internal codenames, no function/file/library/module names.
- **No PR numbers, commit hashes, `#1234` references, or links to internal issues.**
- **Group by theme**, not by PR. Use these headers (omit empty ones, but keep the same set in every locale):

| pt-BR             | en              | es                    | When to use                                          |
| ----------------- | --------------- | --------------------- | ---------------------------------------------------- |
| `### ✨ Novidades` | `### ✨ What's new` | `### ✨ Novedades`     | New user-visible features                            |
| `### ⚡ Melhorias` | `### ⚡ Improvements` | `### ⚡ Mejoras`       | Refinements to existing features (perf, UX, polish) |
| `### 🐛 Correções` | `### 🐛 Fixes`   | `### 🐛 Correcciones` | Bugs the user might have noticed                      |

## Full release body example

The release body should preserve the auto-generated `## Changes` commit list at the top and append every locale section after it:

```markdown
## Changes

- feat(internal-chat): implement internal chat system for agents (#247)
- fix(signatures): allow admins to manage inbox signatures without explicit membership (#260)

## 🇺🇸 English

<!-- user-notes:en:start -->
### ✨ What's new

- **Internal agent chat.** Your team can now message each other right inside Chatwoot, no extra tool needed.

### ⚡ Improvements

- **Faster navigation on slow connections.** Switching between conversations feels more responsive.

### 🐛 Fixes

- **Inbox signatures.** Admins can manage signatures without having to be a member of the inbox.
<!-- user-notes:en:end -->

## 🇧🇷 Português

<!-- user-notes:pt-BR:start -->
### ✨ Novidades

- **Chat interno entre agentes.** Sua equipe agora troca mensagens diretamente dentro do Chatwoot, sem precisar de outra ferramenta.

### ⚡ Melhorias

- **Navegação mais rápida em conexões lentas.** A troca entre conversas ficou mais responsiva.

### 🐛 Correções

- **Assinaturas de caixas de entrada.** Administradores conseguem gerenciar assinaturas mesmo sem participar da caixa.
<!-- user-notes:pt-BR:end -->

## 🇪🇸 Español

<!-- user-notes:es:start -->
### ✨ Novedades

- **Chat interno entre agentes.** Tu equipo ya puede enviarse mensajes dentro de Chatwoot, sin necesidad de otra herramienta.

### ⚡ Mejoras

- **Navegación más rápida en conexiones lentas.** Cambiar de conversación se siente más ágil.

### 🐛 Correcciones

- **Firmas de bandejas de entrada.** Los administradores pueden gestionar las firmas sin pertenecer a la bandeja.
<!-- user-notes:es:end -->
```

Bold the change name, then a single short sentence describing the user benefit. Keep each item to 1 or 2 lines.

If a release has nothing user-visible, write a single generic line in every locale rather than dumping a PR list:

```markdown
## 🇺🇸 English

<!-- user-notes:en:start -->
Bug fixes and internal improvements.
<!-- user-notes:en:end -->

## 🇧🇷 Português

<!-- user-notes:pt-BR:start -->
Correções de bugs e melhorias internas.
<!-- user-notes:pt-BR:end -->

## 🇪🇸 Español

<!-- user-notes:es:start -->
Correcciones de errores y mejoras internas.
<!-- user-notes:es:end -->
```

## Quality checklist (run before publishing)

Run this checklist on **every** locale block:

- [ ] The `en`, `pt-BR` and `es` blocks are all present, with the exact tag spelling shown above, in that order.
- [ ] Each section is wrapped by its `## 🇺🇸 English` / `## 🇧🇷 Português` / `## 🇪🇸 Español` H2 heading outside the markers.
- [ ] The blocks contain equivalent content (same items, same order, same themes), written naturally in each language. Not a literal translation.
- [ ] Headers use the localized header table above. Omit empty themes consistently across locales.
- [ ] Every item leads with a user benefit, not an implementation detail.
- [ ] No PR numbers, commit hashes, file paths, function names, library names, or internal module names.
- [ ] No mention of internal initiatives, customers, deals, roadmap, or anything that would not make sense to an external operator.
- [ ] Each item is understandable by someone who has never opened the codebase.
- [ ] Items are present-tense, benefit-led, 1 to 2 lines.
- [ ] Empty release: one generic line in every locale, never an empty block, never one block missing.

## Look at examples first

Before drafting, read the user-notes blocks from recent releases in this repo to match tone:

```bash
gh release list --limit 5
gh release view <tag> --json body -q .body
```

The references behind this style are **Linear**, **Stripe**, **Notion**, and **Vercel** changelogs: short, benefit-led, grouped by theme, with the user as the protagonist.

## Drafting workflow

When invoked for a release (new or backfill):

1. Read the current release body via `gh release view <tag> --json body -q .body` (or the source commits via `git log <prev-tag>..<tag> --oneline`) to understand what shipped.
2. Filter the changes through "would a non-technical operator notice or care about this?". Drop everything that fails the filter.
3. Group what survived into Novidades / Melhorias / Correções.
4. Draft the **pt-BR** block first as the source language. Write naturally, lead with benefit.
5. Draft the **en** block, then the **es** block. Equivalent content, natural in each language, not a word-for-word translation.
6. Assemble the full release body: keep the `## Changes` commit list at the top, then `## 🇺🇸 English` + the `en` block, then `## 🇧🇷 Português` + the `pt-BR` block, then `## 🇪🇸 Español` + the `es` block. The `en` section always comes first in the rendered release body.
7. Run the quality checklist on all three blocks.
8. Show the full proposed body to the user for approval **before** editing the release.
9. Only after approval, write the body to a temp file and apply it:
   - **For new releases**, first prove the tag is free, then pass the file via `gh release create <tag> --notes-file <file>`:

     ```sh
     git ls-remote --tags <remote> "<tag>"   # must be empty; a tag can exist with no release
     gh release create <tag> --target <sha> --notes-file <file>
     git fetch <remote> "refs/tags/<tag>:refs/tags/<tag>" --force
     git rev-parse "<tag>^{commit}"          # must equal <sha>
     ```

     `--target` is **silently ignored when the tag already exists** (the API documents `target_commitish` as unused then), and `gh release list` cannot warn you, because it only lists tags that already carry a release.

     A tag can be sitting there with an image already published under it, because the publish workflows also answer `workflow_dispatch`. Publishing that way is not allowed — **a published image comes from a cut release and from nothing else**, and the dispatch exists to validate the workflow with `-f push=false` — but the trap survives whoever broke the rule, so the check above runs every time.
   - **For backfills / edits**, this version of `gh` does not have a `release edit` subcommand. Use the API directly:
     ```bash
     RELEASE_ID=$(gh api repos/<owner>/<repo>/releases/tags/<tag> --jq '.id')
     gh api -X PATCH "repos/<owner>/<repo>/releases/$RELEASE_ID" -F body=@<file>
     ```
