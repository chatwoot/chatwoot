# Tailwind v4 + shadcn/ui Theming Architecture

## The Four-Step Pattern

Tailwind v4 requires a specific architecture for CSS variable-based theming. This pattern is **mandatory** - skipping or modifying steps will break your theme.

### Step 1: Define CSS Variables at Root Level

```css
:root {
  --background: hsl(0 0% 100%);
  --foreground: hsl(222.2 84% 4.9%);
  /* ... more colors */
}

.dark {
  --background: hsl(222.2 84% 4.9%);
  --foreground: hsl(210 40% 98%);
  /* ... dark mode colors */
}
```

**Critical Rules:**
- ✅ Define at root level (NOT inside `@layer base`)
- ✅ Use `hsl()` wrapper on all color values
- ✅ Use `.dark` for dark mode overrides (NOT `.dark { @theme { } }`)
- ❌ Never put `:root` or `.dark` inside `@layer base`

### Step 2: Map Variables to Tailwind Utilities

```css
@theme inline {
  --color-background: var(--background);
  --color-foreground: var(--foreground);
  /* ... map all CSS variables */
}
```

**Why This Is Required:**
- Tailwind v4 doesn't read `tailwind.config.ts` for colors
- `@theme inline` generates utility classes (`bg-background`, `text-foreground`)
- Without this, utilities like `bg-primary` won't exist

### Step 3: Apply Base Styles

```css
@layer base {
  body {
    background-color: var(--background);  /* NO hsl() wrapper here */
    color: var(--foreground);
  }
}
```

**Critical Rules:**
- ✅ Reference variables directly: `var(--background)`
- ❌ Never double-wrap: `hsl(var(--background))` (already has hsl)

### Step 4: Result - Automatic Dark Mode

With this architecture:
- `<div className="bg-background text-foreground">` works automatically
- No `dark:` variants needed in components
- Theme switches via `.dark` class on `<html>`
- Single source of truth for all colors

---

## Why This Architecture Works

### Color Variable Flow

```
CSS Variable Definition → @theme inline Mapping → Tailwind Utility Class
--background           → --color-background     → bg-background
(with hsl() wrapper)     (references variable)    (generated class)
```

### Dark Mode Switching

```
ThemeProvider toggles `.dark` class on <html>
  ↓
CSS variables update automatically (.dark overrides)
  ↓
Tailwind utilities reference updated variables
  ↓
UI updates without re-render
```

---

## Common Mistakes

### ❌ Mistake 1: Variables Inside @layer base

```css
/* WRONG */
@layer base {
  :root {
    --background: hsl(0 0% 100%);
  }
}
```

**Why It Fails:** Tailwind v4 strips CSS outside `@theme`/`@layer`, but `:root` must be at root level to persist.

### ❌ Mistake 2: Using .dark { @theme { } }

```css
/* WRONG */
@theme {
  --color-primary: hsl(0 0% 0%);
}

.dark {
  @theme {
    --color-primary: hsl(0 0% 100%);
  }
}
```

**Why It Fails:** Tailwind v4 doesn't support nested `@theme` directives.

### ❌ Mistake 3: Double hsl() Wrapping

```css
/* WRONG */
@layer base {
  body {
    background-color: hsl(var(--background));
  }
}
```

**Why It Fails:** `--background` already contains `hsl()`, results in `hsl(hsl(...))`.

### ❌ Mistake 4: Config-Based Colors

```typescript
// WRONG (tailwind.config.ts)
export default {
  theme: {
    extend: {
      colors: {
        primary: 'hsl(var(--primary))'
      }
    }
  }
}
```

**Why It Fails:** Tailwind v4 completely ignores `theme.extend.colors` in config files.

---

## Best Practices

### 1. Semantic Color Names

Use semantic names, not color values:
```css
--primary      /* ✅ Semantic */
--blue-500     /* ❌ Not semantic */
```

### 2. Foreground Pairing

Every background color needs a foreground:
```css
--primary: hsl(...);
--primary-foreground: hsl(...);
```

### 3. WCAG Contrast Ratios

Ensure proper contrast:
- Normal text: 4.5:1 minimum
- Large text: 3:1 minimum
- UI components: 3:1 minimum

### 4. Chart Colors

Charts need separate variables (don't use hsl wrapper in components):
```css
:root {
  --chart-1: hsl(12 76% 61%);
}

@theme inline {
  --color-chart-1: var(--chart-1);
}
```

Use in components:
```tsx
<div style={{ backgroundColor: 'var(--chart-1)' }} />
```

---

## Official Documentation

- shadcn/ui Tailwind v4 Guide: https://ui.shadcn.com/docs/tailwind-v4
- Tailwind v4 Docs: https://tailwindcss.com/docs
- shadcn/ui Theming: https://ui.shadcn.com/docs/theming
