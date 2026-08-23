# Releasing Whisker 🐾

Automatic, best-practice SemVer release cycle. You write conventional commits;
the pipeline versions, tags, signs and publishes.

## The cycle

```
develop ──(PR/merge)──> master ──> [Release workflow]
                                     ├─ scans commits since last tag
                                     ├─ bumps config/app.yml + package.json
                                     ├─ creates annotated tag vX.Y.Z + release commit
                                     ├─ GitHub Release: notes + SHA256SUMS + GPG sig
                                     └─ docker images build via tag trigger
                                        (whisker/whisker:X.Y.Z, :latest)
```

### Version bump rules (Conventional Commits → SemVer)

| Commit message contains | Bump |
|---|---|
| `feat!:` / `fix!:` / `BREAKING CHANGE:` footer | **MAJOR** |
| `feat(scope): …` | **MINOR** |
| `fix(scope): …` / `perf: …` | **PATCH** |
| docs/chore/refactor/test only | no release |

### Manual controls

- **Force a check anytime**: Actions → *Release* → *Run workflow* (`dry_run=true` shows what would happen without tagging).
- **Hotfix**: commit `fix: …` on master; the next run cuts a patch release.

## One-time setup

1. **Docker Hub namespace** (optional): set repo variable `DOCKERHUB_NAMESPACE`
   (Settings → Secrets and variables → Actions → Variables) and add
   `DOCKERHUB_USERNAME` / `DOCKERHUB_TOKEN` secrets. Defaults to `whisker`.
2. **GPG release signing** (recommended):
   ```bash
   gpg --full-generate-key                       # RSA 4096, name: Whisker Release
   gpg --armor --export-secret-keys <KEYID>      # paste into repo secret
   ```
   - Secret `RELEASE_GPG_PRIVATE_KEY` = armored private key
   - Secret `RELEASE_GPG_PASSPHRASE` = key passphrase
   Publish the public key on the repo / keyservers so users can verify
   (`gpg --verify SHA256SUMS.txt.sig`).

## Verifying a download (end users)

```bash
sha256sum -c SHA256SUMS.txt
gpg --verify SHA256SUMS.txt.sig SHA256SUMS.txt   # when signing is enabled
```

## Desktop & Android signing (as targets land)

Like Chatwoot's mobile app, every installable build must ship signed.

| Target | Signing method | Where it plugs in |
|---|---|---|
| Android APK/AAB | Play-managed or upload keystore; expose via secrets `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` | future `android-release.yml` job runs `apksigner` after Gradle build |
| Windows installer (Tauri pet, P5) | Authenticode EV/OV cert; secrets `WINDOWS_CERT_BASE64` + `WINDOWS_CERT_PASSWORD`; Tauri `signTool` step in the release job | appended to this workflow once `apps/pet` exists |
| macOS .dmg (Tauri) | Developer ID Application cert + notarization; secrets `APPLE_CERT_BASE64`, `APPLE_ID`, `APPLE_PASSWORD`, `APPLE_TEAM_ID`; Tauri notarize API | same as above |
| Auto-updates (desktop) | Tauri updater minisign keypair; secret `TAURI_UPDATER_PRIVATE_KEY` produces `.sig` next to each artifact | same as above |

The pipeline is already wired to attach any additional artifacts dropped into
the release step — adding a platform means adding its build/sign job, nothing
else changes.

## Version single source of truth

- Backend reads `Chatwoot.config[:version]` from `config/app.yml`.
- Frontend/package identity lives in `package.json`.
- Both are written together by `scripts/ci/set_version.sh` inside the release
  commit — never bump them manually.
