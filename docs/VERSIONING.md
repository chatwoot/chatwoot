# Versionado InboxHub (fork PaluHub)

Este repo es un fork de Chatwoot. Hay **dos números de versión** y no se mezclan.

| Capa | Dónde vive | Ejemplo | Qué significa |
|------|------------|---------|----------------|
| **Upstream Chatwoot** | `package.json` → `"version"` | `4.17.0` | Base OSS / sync con Chatwoot |
| **InboxHub (PaluHub)** | [`PALUHUB_VERSION`](../PALUHUB_VERSION) + tags git | `1.0.0` | Releases del fork (features/fixes propios) |

## Semver del fork (`PALUHUB_VERSION`)

Formato: `MAJOR.MINOR.PATCH`

- **MAJOR** — cambios incompatibles de producto o migraciones destructivas / breaking API del fork.
- **MINOR** — features nuevas compatibles (Tasks, assign team RR, UI nueva).
- **PATCH** — fixes y pulido sin contrato nuevo.

Empezamos en **`1.0.0`** con Internal Tasks + UX + team auto-assign.

## Tags git

Solo tags del fork (no pisar tags upstream de Chatwoot):

```text
inboxhub-v1.0.0
inboxhub-v1.0.1
inboxhub-v1.1.0
```

Crear en el commit de `develop` que se despliega a prod:

```powershell
git checkout develop
git pull
git tag -a inboxhub-v1.0.0 -m "InboxHub 1.0.0 — Internal Tasks and UX"
git push origin inboxhub-v1.0.0
```

Imagen GHCR típica: `ghcr.io/.../chatwoot:develop-<SHA>` anclada al SHA del tag.

## Changelog

Cada release documenta cambios en [`CHANGELOG_PALUHUB.md`](CHANGELOG_PALUHUB.md).  
Checklist de deploy / migraciones: [`RELEASE_INBOXHUB_*.md`](RELEASE_INBOXHUB_1.0.0.md).

## Flujo de release (resumen)

1. Feature branch → PR a `develop`.
2. Bump `PALUHUB_VERSION` + entrada en changelog (mismo PR o commit de release).
3. Merge a `develop`.
4. Tag `inboxhub-vX.Y.Z` en ese merge.
5. Deploy Dokploy (imagen nueva) + `db:migrate` si hay migraciones.
6. Smoke según el RELEASE doc.

## Qué no hacer

- No subir `package.json` version solo por features del fork (eso es Chatwoot).
- No usar tags `v4.x` para releases PaluHub (reservado / confuso con upstream).
- No desplegar a prod sin anotar el SHA y el tag en el ticket / changelog.
