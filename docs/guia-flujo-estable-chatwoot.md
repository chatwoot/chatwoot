# Guía de Flujo **Estable‑First** con Tags (Chatwoot fork)

> **Objetivo**: Mantener tu fork (`desarrollando-asistentes/chatwoot`) basado en **releases estables** (tags `vX.Y.Z`) del upstream (`chatwoot/chatwoot`), con una rama de trabajo `overlay/main` y ramas espejo `base/<tag>` y `base/master`.

## Tabla de contenido
1. [Conceptos clave](#conceptos-clave)
2. [Setup desde cero](#setup-desde-cero)
3. [Cómo fijar la base a un **tag** (espejo `base/vX.Y.Z`)](#cómo-fijar-la-base-a-un-tag-espejo-basevx-yz)
4. [Crear o recrear `overlay/main` desde el tag](#crear-o-recrear-overlaymain-desde-el-tag)
5. [Cómo **hacer rebase** de un tag (actualizar overlay)](#cómo-hacer-rebase-de-un-tag-actualizar-overlay)
6. [Alternativa: merge sin reescribir historia](#alternativa-merge-sin-reescribir-historia)
7. [Comprobaciones de **correctitud de tags** (que salen del lugar correcto)](#comprobaciones-de-correctitud-de-tags-que-salen-del-lugar-correcto)
8. [Cómo **resolver conflictos** (rebase/merge)](#cómo-resolver-conflictos-rebasemerge)
9. [Flujo de actualización cuando sale un **nuevo release**](#flujo-de-actualización-cuando-sale-un-nuevo-release)
10. [Backups y recuperación](#backups-y-recuperación)
11. [Aliases útiles (1‑click)](#aliases-útiles-1click)
12. [Errores comunes y soluciones rápidas](#errores-comunes-y-soluciones-rápidas)
13. [Buenas prácticas de estabilidad](#buenas-prácticas-de-estabilidad)

---

## Conceptos clave

- **origin**: tu fork (`https://github.com/desarrollando-asistentes/chatwoot.git`).
- **upstream**: repo oficial (`https://github.com/chatwoot/chatwoot.git`).  
  *Nunca pushes a upstream.*
- **base/master**: espejo de `upstream/master` (estable).
- **base/vX.Y.Z**: espejo exacto de un **tag de release** (más estable aún).
- **overlay/main**: rama de trabajo donde vives tú (tus cambios).

> Regla de oro: *`base/*` nunca lleva commits propios.* Solo se resetea a upstream o a un tag y se empuja al fork.

---

## Setup desde cero

```bash
# 0) Clonar tu fork y enlazar upstream
git clone https://github.com/desarrollando-asistentes/chatwoot.git
cd chatwoot
git remote add upstream https://github.com/chatwoot/chatwoot.git
git remote set-url --push upstream DISABLED    # evita pushes accidentales

# 1) Configs útiles
git config pull.rebase true
git config rebase.autoStash true
git config --global rerere.enabled true        # recuerda resoluciones de conflictos

# 2) Trae todo (incluye tags)
git fetch upstream --prune --tags
git fetch origin  --prune --tags
```

> **MINGW/WSL**: Los comandos funcionan igual en bash.

---

## Cómo fijar la base a un **tag** (espejo `base/vX.Y.Z`)

1) **Detectar** el último tag (elige una forma):

```bash
# Por versión semántica (recomendado)
LATEST=$(git for-each-ref --sort=-v:refname --format='%(refname:short)' refs/tags/v* | head -n1)
echo "$LATEST"    # ej: v4.6.0

# Alternativa por fecha de commit etiquetado
# LATEST=$(git describe --tags --abbrev=0 $(git rev-list --tags --max-count=1))
```

2) **Crear/actualizar** el espejo del tag en tu fork (**commit** real del tag):

```bash
git checkout -B "base/$LATEST" "$LATEST^{commit}"
git push origin "base/$LATEST" --force-with-lease
```

3) (Opcional) Espejo de `master` por referencia:

```bash
git checkout -B base/master upstream/master
git push origin base/master --force-with-lease
```

---

## Crear o recrear `overlay/main` desde el tag

> Úsalo si quieres empezar limpio o si borraste `overlay/main`.

```bash
git checkout -B overlay/main "base/$LATEST"
git push -u origin overlay/main
```

**Verificación:**

```bash
# base/<tag> debe apuntar EXACTO al commit del tag
test "$(git rev-parse "base/$LATEST")" = "$(git rev-parse "$LATEST^{commit}")" \
  && echo "✅ base/$LATEST == $LATEST (commit)" || echo "❌ base/$LATEST no coincide"

# overlay/main debe DESCENDER del tag
git merge-base --is-ancestor "$LATEST^{commit}" overlay/main \
  && echo "✅ overlay/main desciende de $LATEST" \
  || echo "❌ overlay/main NO está basada en $LATEST"
```

---

## Cómo **hacer rebase** de un tag (actualizar overlay)

> Cuando sale un nuevo tag y quieres llevar tu `overlay/main` encima de esa base estable.

```bash
# 1) Obtener el nuevo tag
git fetch upstream --prune --tags
NEW=$(git for-each-ref --sort=-v:refname --format='%(refname:short)' refs/tags/v* | head -n1)
echo "Nuevo tag: $NEW"

# 2) Crear/actualizar espejo del nuevo tag
git checkout -B "base/$NEW" "$NEW^{commit}"
git push origin "base/$NEW" --force-with-lease

# 3) Rebase limpio (recom.) o con merges
git checkout overlay/main
git rebase "base/$NEW"                  # lineal y limpio
# Si tu overlay usa merges y quieres preservarlos:
# git rebase --rebase-merges "base/$NEW"

# 4) Publicar si reescribiste historia
git push origin overlay/main --force-with-lease
```

> Si no quieres reescribir historia, usa **merge** (ver siguiente sección).

---

## Alternativa: merge sin reescribir historia

```bash
git checkout overlay/main
git merge --no-ff "base/$NEW"
# Resuelve conflictos, pruebas...
git push origin overlay/main
```

**Pros/Contras**  
- *Rebase*: historial lineal y claro (ideal para forks). Requiere `--force-with-lease`.  
- *Merge*: no reescribe historia (más “safe”), pero historial con commits de merge.

---

## Comprobaciones de **correctitud de tags** (que salen del lugar correcto)

A veces `origin` también tiene tags, pero **tu verdad** debe venir de **`upstream`**.

```bash
# 1) Asegura que traes tags del upstream
git fetch upstream --prune --tags

# 2) Descubre el último tag *del upstream* (no de origin)
LATEST=$(git ls-remote --tags upstream 'v*' \
  | awk '{print $2}' \
  | sed 's|refs/tags/||; s|\^{}||' \
  | sort -V | tail -n1)
echo "Último tag upstream: $LATEST"

# 3) Verifica que tu branch base coincide con el *commit* del tag
test "$(git rev-parse "base/$LATEST")" = "$(git rev-parse "refs/tags/$LATEST^{commit}")" \
  && echo "✅ base/$LATEST == tags/$LATEST (commit)" \
  || echo "❌ base/$LATEST NO coincide con tags/$LATEST (commit)"
```

> **`^{commit}`**: si el tag es **anotado**, `refs/tags/<tag>` apunta a un **objeto tag** (no al commit). `^{commit}` “pela” el tag hasta el commit real para comparar **commit vs commit**.

---

## Cómo **resolver conflictos** (rebase/merge)

### A. Preparación
- Deja encendido `rerere` (recuerda resoluciones repetidas): `git config --global rerere.enabled true`.
- Ten a mano un mergetool (VS Code, Meld, KDiff3) o resuelve en texto.

### B. Durante el **rebase**
1. Lanza rebase (ver secciones anteriores).  
2. Si aparece conflicto:
   ```bash
   git status                         # ve archivos en conflicto
   # Edita archivos, conserva cambios esperados.
   git add <archivos-resueltos>
   git rebase --continue
   # Si te equivocaste y quieres comenzar de nuevo este paso:
   # git rebase --abort
   ```
3. Repite hasta terminar.  
4. Corre pruebas / linter.  
5. Publica: `git push --force-with-lease` (solo si rebaseaste).

### C. Durante el **merge**
1. `git merge --no-ff base/<tag>`  
2. Resolver conflictos igual que arriba (`git status`, editar, `git add`).  
3. Finalizar: `git commit` del merge, pruebas, y `git push` (sin `--force`).

### D. Tips para menos conflictos
- Evita cambios masivos de formateo mezclados con lógica.  
- Agrupa cambios por ámbito (scopes).  
- Rebase/merge con frecuencia (pequeñas diferencias => menos conflictos).  
- De ser posible, encapsula personalizaciones (branding, textos) para no chocar con core.

---

## Flujo de actualización cuando sale un **nuevo release**

```bash
git fetch upstream --prune --tags
NEW=$(git for-each-ref --sort=-v:refname --format='%(refname:short)' refs/tags/v* | head -n1)

# Crear/actualizar espejo
git checkout -B "base/$NEW" "$NEW^{commit}"
git push origin "base/$NEW" --force-with-lease

# Llevar tu overlay a la nueva base
git checkout overlay/main
git rebase "base/$NEW" && git push origin overlay/main --force-with-lease
# (o merge --no-ff y push sin force)
```

---

## Backups y recuperación

Antes de operaciones grandes (recrear overlay, saltar de v3→v4, etc.):

```bash
BK="overlay/backup-$(date +%Y%m%d-%H%M)"
git branch "$BK" overlay/main
git push origin "$BK"   # recomendado
```

**Cherry-pick** de commits antiguos:

```bash
# Ver tus commits vs la base
git log --oneline "base/$LATEST"..overlay/main

# Recuperar uno puntual
git checkout overlay/main
git cherry-pick <SHA1>
git push
```

**Reflog** (salvavidas si moviste punteros):
```bash
git reflog
# Identifica el commit al que quieres volver y:
git reset --hard <SHA>
```

---

## Aliases útiles (1‑click)

**Ver si estás en la base estable:**
```bash
git config alias.is-stable '!f(){ \
  set -e; \
  git fetch upstream --prune --tags >/dev/null; \
  LATEST=$(git for-each-ref --sort=-v:refname --format="%(refname:short)" refs/tags/v* | head -n1); \
  echo "🪪 Último tag upstream: $LATEST"; \
  if git rev-parse "base/$LATEST" >/dev/null 2>&1; then \
    if [ "$(git rev-parse base/$LATEST)" = "$(git rev-parse "refs/tags/$LATEST^{commit}")" ]; then \
      echo "✅ base/$LATEST coincide con el commit del tag"; \
    else \
      echo "❌ base/$LATEST NO coincide con el commit del tag"; \
    fi; \
  else \
    echo "❌ no existe branch base/$LATEST"; \
  fi; \
  if git merge-base --is-ancestor "refs/tags/$LATEST^{commit}" overlay/main; then \
    echo "✅ overlay/main desciende de $LATEST"; \
  else \
    echo "❌ overlay/main NO está basada en $LATEST"; \
  fi; \
}; f'
```

**Actualizarte al último tag y rebasar `overlay/main`:**
```bash
git config alias.ud-tag '!f(){ \
  set -e; \
  git fetch upstream --prune --tags; \
  git fetch origin  --prune --tags; \
  TAG="${1:-$(git for-each-ref --sort=-v:refname --format="%(refname:short)" refs/tags/v* | head -n1)}"; \
  test -n "$TAG" || { echo "❌ No hay TAG (v*)."; exit 1; }; \
  echo "Usando TAG: $TAG"; \
  git checkout -B "base/$TAG" "$TAG^{commit}"; \
  git push origin "base/$TAG" --force-with-lease; \
  git checkout overlay/main; \
  git rebase "base/$TAG"; \
  echo "✅ overlay/main rebasada sobre base/$TAG"; \
}; f'
```

---

## Errores comunes y soluciones rápidas

- **`fatal: 'refs/tags/^{commit}' is not a commit ...`**  
  → `$TAG` está **vacío**. Asegúrate de definirlo (y de haber hecho `git fetch upstream --tags`).  
  ```bash
  git fetch upstream --tags
  TAG=$(git for-each-ref --sort=-v:refname --format='%(refname:short)' refs/tags/v* | head -n1)
  test -n "$TAG" && echo "$TAG"
  git checkout -B "base/$TAG" "$TAG^{commit}"
  ```

- **Comparación contra tag falla (da ❌)**  
  → Estabas comparando contra el **objeto tag**. Usa `^{commit}` para comparar **commit vs commit**.

- **Push rechazado tras rebase**  
  → Usa `--force-with-lease` (no `--force` a secas) en `overlay/main` para evitar pisar trabajo ajeno.

- **Conflictos repetitivos**  
  → Activa `rerere` para que Git recuerde tus resoluciones en futuras actualizaciones.

---

## Buenas prácticas de estabilidad

- Trabaja sobre `overlay/main` basada en `base/<tag>` (o `base/master` si necesitas estabilidad sin fijar versión).  
- No hagas commits en `base/*`; trata esos branches como espejos.  
- Lee notas de release antes de subir de **minor/major** (puede haber migraciones).  
- Ejecuta tests/CI tras cada rebase/merge.  
- Evita cambios de formateo masivos mezclados con lógica.  
- Si hay equipo, protege ramas en GitHub (`base/*` y `overlay/main`).

---

> **Listo.** Con esta guía puedes: fijar base a un tag, crear o recrear `overlay/main`, verificar que tu base viene del **upstream correcto**, y manejar conflictos con seguridad.


---

## Actualización y mantenimiento **local** (solo en tu máquina)

> Si **todo** lo haces localmente (sin staging/prod), usa siempre el entorno **development** (por defecto). **No** necesitas `RAILS_ENV=production`.

### A) Al ponerte en el **último tag** (solo Git)

```bash
# Trae tags del upstream y detecta el último v*
git fetch upstream --prune --tags
NEW=$(git for-each-ref --sort=-v:refname --format='%(refname:short)' refs/tags/v* | head -n1)
echo "Nuevo tag: $NEW"

# Crea/actualiza el espejo exacto del tag en tu fork
git checkout -B "base/$NEW" "$NEW^{commit}"
git push origin "base/$NEW" --force-with-lease

# Rebasea o mergea tu rama de trabajo local
git checkout overlay/main
git rebase "base/$NEW"
# (o) git rebase --rebase-merges "base/$NEW"   # si tu overlay usa merges
# (o) git merge --no-ff "base/$NEW"            # si NO quieres reescribir historia

# Publica solo si reescribiste historia
git push origin overlay/main --force-with-lease
# (si hiciste merge, git push normal)
```

### B) Después del update (entorno **development**)

```bash
# Asegúrate de estar en development
bin/rails r 'puts Rails.env'      # debe imprimir: development

# Dependencias de Ruby y JS
bundle install
yarn install   # o npm/pnpm según el repo

# Migraciones de BD (Rails aplica todas las pendientes en orden)
bin/rails db:migrate

# (Opcional) Si el proyecto lo requiere
# bin/rails db:seed

# Levanta servicios locales
# 1) Servidor Rails
bin/rails s
# 2) Jobs (Sidekiq), si aplica
bundle exec sidekiq
# 3) Dev server de JS (si hay, p.ej. vite/webpack)
yarn dev
```

> En **development** normalmente **no** precompilas assets (`assets:precompile`). Eso es para staging/prod.  
> Asegúrate de tener **PostgreSQL** y **Redis** corriendo localmente (si la app los usa).

### C) Checks rápidos locales

```bash
# Confirmar que overlay/main está basado en tu tag base
git merge-base --is-ancestor "$NEW^{commit}" overlay/main \
  && echo "✅ overlay/main desciende de $NEW" \
  || echo "❌ overlay/main NO está basada en $NEW"

# Ver migraciones pendientes
bin/rails db:abort_if_pending_migrations || true
```

### D) Troubleshooting local habitual

- **`PG::UndefinedTable` / `relation does not exist`** → corre `bin/rails db:migrate`.  
- **`PendingMigrationError`** → igual, `bin/rails db:migrate`.  
- **Errores de paquetes JS** → `yarn install` (o limpia caché `yarn cache clean && yarn install`).  
- **Errores de gems nativas** (extensiones C) → revisa toolchain (msys2/WSL), `bundle install` otra vez.  
- **`ECONNREFUSED Redis`** → inicia Redis local.  
- **El dev server de JS no recompila** → asegúrate de ejecutar `yarn dev` (o el script equivalente del repo).

### E) Alias útil para update local (solo Git)

```bash
git config alias.ud-local '!f(){ \
  set -e; \
  git fetch upstream --prune --tags; \
  git fetch origin  --prune --tags; \
  TAG="${1:-$(git for-each-ref --sort=-v:refname --format="%(refname:short)" refs/tags/v* | head -n1)}"; \
  test -n "$TAG" || { echo "❌ No hay TAG (v*)."; exit 1; }; \
  echo "Usando TAG: $TAG"; \
  git checkout -B "base/$TAG" "$TAG^{commit}"; \
  git push origin "base/$TAG" --force-with-lease; \
  git checkout overlay/main; \
  git rebase "base/$TAG"; \
  echo "✅ overlay/main rebasada sobre base/$TAG (local)"; \
}; f'
```

> Luego corre **`bundle install`**, **`yarn install`** y **`bin/rails db:migrate`** en *development*.

