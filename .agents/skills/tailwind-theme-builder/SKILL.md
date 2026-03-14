---
name: tailwind-theme-builder
description: >
  Set up Tailwind v4 with shadcn/ui themed UI. Workflow: install dependencies,
  configure CSS variables with @theme inline, set up dark mode, verify.
  Use when initialising React projects with Tailwind v4, setting up shadcn/ui theming,
  or fixing colors not working, tw-animate-css errors, @theme inline dark mode conflicts,
  @apply breaking, v3 migration issues.
---

# Tailwind Theme Builder

Set up a fully themed Tailwind v4 + shadcn/ui project with dark mode. Produces configured CSS, theme provider, and working component library.

## Workflow

### Step 1: Install Dependencies

```bash
pnpm add tailwindcss @tailwindcss/vite
pnpm add -D @types/node tw-animate-css
pnpm dlx shadcn@latest init

# Delete v3 config if it exists
rm -f tailwind.config.ts
```

### Step 2: Configure Vite

Copy `assets/vite.config.ts` or add the Tailwind plugin:

```typescript
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'
import path from 'path'

export default defineConfig({
  plugins: [react(), tailwindcss()],
  resolve: { alias: { '@': path.resolve(__dirname, './src') } }
})
```

### Step 3: Four-Step CSS Architecture (Mandatory)

This exact order is required. Skipping steps breaks the theme.

**src/index.css:**

```css
@import "tailwindcss";
@import "tw-animate-css";

/* 1. Define CSS variables at root (NOT inside @layer base) */
:root {
  --background: hsl(0 0% 100%);
  --foreground: hsl(222.2 84% 4.9%);
  --primary: hsl(221.2 83.2% 53.3%);
  --primary-foreground: hsl(210 40% 98%);
  /* ... all semantic tokens */
}

.dark {
  --background: hsl(222.2 84% 4.9%);
  --foreground: hsl(210 40% 98%);
  --primary: hsl(217.2 91.2% 59.8%);
  --primary-foreground: hsl(222.2 47.4% 11.2%);
}

/* 2. Map variables to Tailwind utilities */
@theme inline {
  --color-background: var(--background);
  --color-foreground: var(--foreground);
  --color-primary: var(--primary);
  --color-primary-foreground: var(--primary-foreground);
}

/* 3. Apply base styles (NO hsl() wrapper here) */
@layer base {
  body {
    background-color: var(--background);
    color: var(--foreground);
  }
}
```

**Result:** `bg-background`, `text-primary` etc. work automatically. Dark mode switches via `.dark` class — no `dark:` variants needed for semantic colours.

### Step 4: Set Up Dark Mode

Copy `assets/theme-provider.tsx` to your components directory, then wrap your app:

```typescript
import { ThemeProvider } from '@/components/theme-provider'

ReactDOM.createRoot(document.getElementById('root')!).render(
  <ThemeProvider defaultTheme="dark" storageKey="vite-ui-theme">
    <App />
  </ThemeProvider>
)
```

Add a theme toggle:
```bash
pnpm dlx shadcn@latest add dropdown-menu
```

See `references/dark-mode.md` for the ModeToggle component.

### Step 5: Configure components.json

```json
{
  "tailwind": {
    "config": "",
    "css": "src/index.css",
    "baseColor": "slate",
    "cssVariables": true
  }
}
```

`"config": ""` is critical — v4 doesn't use tailwind.config.ts.

---

## Critical Rules

**Always:**
- Wrap colours with `hsl()` in `:root`/`.dark`
- Use `@theme inline` to map all CSS variables
- Use `@tailwindcss/vite` plugin (NOT PostCSS)
- Delete `tailwind.config.ts` if it exists

**Never:**
- Put `:root`/`.dark` inside `@layer base`
- Use `.dark { @theme { } }` (v4 doesn't support nested @theme)
- Double-wrap: `hsl(var(--background))`
- Use `@apply` with `@layer base` classes (use `@utility` instead)

---

## Common Errors

| Symptom | Cause | Fix |
|---------|-------|-----|
| `bg-primary` doesn't work | Missing `@theme inline` | Add `@theme inline` block |
| Colours all black/white | Double `hsl()` wrapping | Use `var(--colour)` not `hsl(var(--colour))` |
| Dark mode not switching | Missing ThemeProvider | Wrap app in `<ThemeProvider>` |
| Build fails | `tailwind.config.ts` exists | Delete the file |
| Animation errors | Using `tailwindcss-animate` | Install `tw-animate-css` instead |
| `@apply` fails on custom class | v4 breaking change | Use `@utility` instead of `@layer components` |

See `references/common-gotchas.md` for detailed error explanations with sources.

---

## Asset Files

Copy from `assets/` directory:
- `index.css` — Complete CSS with all colour variables
- `components.json` — shadcn/ui v4 config
- `vite.config.ts` — Vite + Tailwind plugin
- `theme-provider.tsx` — Dark mode provider
- `utils.ts` — `cn()` utility

## Reference Files

- `references/common-gotchas.md` — 8 documented errors with GitHub sources
- `references/dark-mode.md` — Complete dark mode implementation
- `references/architecture.md` — Deep dive into 4-step pattern
- `references/migration-guide.md` — v3 to v4 migration
