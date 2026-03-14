# Common Gotchas & Solutions

## Critical Failures (Will Break Your Build)

### 1. `:root` Inside `@layer base`

❌ **WRONG:**
```css
@layer base {
  :root {
    --background: hsl(0 0% 100%);
  }
}
```

✅ **CORRECT:**
```css
:root {
  --background: hsl(0 0% 100%);
}

@layer base {
  body {
    background-color: var(--background);
  }
}
```

**Why:** Tailwind v4 strips CSS outside `@theme`/`@layer`, but `:root` must be at root level.

---

### 2. Nested `@theme` Directive

❌ **WRONG:**
```css
@theme {
  --color-primary: hsl(0 0% 0%);
}

.dark {
  @theme {
    --color-primary: hsl(0 0% 100%);
  }
}
```

✅ **CORRECT:**
```css
:root {
  --primary: hsl(0 0% 0%);
}

.dark {
  --primary: hsl(0 0% 100%);
}

@theme inline {
  --color-primary: var(--primary);
}
```

**Why:** Tailwind v4 doesn't support `@theme` inside selectors.

---

### 3. Double `hsl()` Wrapping

❌ **WRONG:**
```css
@layer base {
  body {
    background-color: hsl(var(--background));
  }
}
```

✅ **CORRECT:**
```css
@layer base {
  body {
    background-color: var(--background);  /* Already has hsl() */
  }
}
```

**Why:** Variables already contain `hsl()`, double-wrapping creates `hsl(hsl(...))`.

---

### 4. Colors in `tailwind.config.ts`

❌ **WRONG:**
```typescript
// tailwind.config.ts
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

✅ **CORRECT:**
```typescript
// Delete tailwind.config.ts entirely OR leave it empty
export default {}

// components.json
{
  "tailwind": {
    "config": ""  // ← Empty string
  }
}
```

**Why:** Tailwind v4 completely ignores `theme.extend.colors`.

---

### 5. Missing `@theme inline` Mapping

❌ **WRONG:**
```css
:root {
  --background: hsl(0 0% 100%);
}

/* No @theme inline block */
```

Result: `bg-background` class doesn't exist

✅ **CORRECT:**
```css
:root {
  --background: hsl(0 0% 100%);
}

@theme inline {
  --color-background: var(--background);
}
```

**Why:** `@theme inline` generates the utility classes.

---

## Configuration Gotchas

### 6. Wrong components.json Config

❌ **WRONG:**
```json
{
  "tailwind": {
    "config": "tailwind.config.ts"  // ← No!
  }
}
```

✅ **CORRECT:**
```json
{
  "tailwind": {
    "config": ""  // ← Empty for v4
  }
}
```

---

### 7. Using PostCSS Instead of Vite Plugin

❌ **WRONG:**
```typescript
// vite.config.ts
export default defineConfig({
  css: {
    postcss: './postcss.config.js'  // Old v3 way
  }
})
```

✅ **CORRECT:**
```typescript
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
  plugins: [react(), tailwindcss()]  // v4 way
})
```

---

### 8. Missing Path Aliases

❌ **WRONG:**
```typescript
// tsconfig.json has no paths
import { Button } from '../../components/ui/button'
```

✅ **CORRECT:**
```json
// tsconfig.app.json
{
  "compilerOptions": {
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"]
    }
  }
}
```

```typescript
import { Button } from '@/components/ui/button'
```

---

## Color System Gotchas

### 9. Using `dark:` Variants for Semantic Colors

❌ **WRONG:**
```tsx
<div className="bg-primary dark:bg-primary-dark" />
```

✅ **CORRECT:**
```tsx
<div className="bg-primary" />
```

**Why:** With proper CSS variable setup, `bg-primary` automatically responds to theme.

---

### 10. Hardcoded Color Values

❌ **WRONG:**
```tsx
<div className="bg-blue-600 dark:bg-blue-400" />
```

✅ **CORRECT:**
```tsx
<div className="bg-primary" />  {/* Or bg-info, bg-success, etc. */}
```

**Why:** Semantic tokens enable theme switching and reduce repetition.

---

## Component Gotchas

### 11. Missing `cn()` Utility

❌ **WRONG:**
```tsx
<div className={`base ${isActive && 'active'}`} />
```

✅ **CORRECT:**
```tsx
import { cn } from '@/lib/utils'
<div className={cn("base", isActive && "active")} />
```

**Why:** `cn()` properly merges and deduplicates Tailwind classes.

---

### 12. Empty String in Radix Select

❌ **WRONG:**
```tsx
<SelectItem value="">Select an option</SelectItem>
```

✅ **CORRECT:**
```tsx
<SelectItem value="placeholder">Select an option</SelectItem>
```

**Why:** Radix UI Select doesn't allow empty string values.

---

## Installation Gotchas

### 13. Wrong Tailwind Package

❌ **WRONG:**
```bash
npm install tailwindcss@^3.4.0  # v3
```

✅ **CORRECT:**
```bash
npm install tailwindcss@^4.1.0  # v4
npm install @tailwindcss/vite
```

---

### 14. Missing Dependencies

❌ **WRONG:**
```json
{
  "dependencies": {
    "tailwindcss": "^4.1.0"
    // Missing @tailwindcss/vite
  }
}
```

✅ **CORRECT:**
```json
{
  "dependencies": {
    "tailwindcss": "^4.1.0",
    "@tailwindcss/vite": "^4.1.0",
    "clsx": "^2.1.1",
    "tailwind-merge": "^3.3.1"
  },
  "devDependencies": {
    "@types/node": "^24.0.0"
  }
}
```

---

### 17. tw-animate-css Import Error (REAL-WORLD ISSUE)

❌ **WRONG:**
```bash
npm install tailwindcss-animate  # Deprecated package
```

```css
@import "tw-animate-css";  # Package doesn't exist in v4
```

✅ **CORRECT:**
```bash
# Don't install tailwindcss-animate at all
# Use native CSS animations or @tailwindcss/motion
```

**Why:**
- `tailwindcss-animate` is deprecated in Tailwind v4
- Causes import errors during build
- shadcn/ui docs may still reference it (outdated)
- The skill handles animations differently in v4

**Impact:** Build failure, requires manual CSS file cleanup

---

### 18. Duplicate @layer base After shadcn init (REAL-WORLD ISSUE)

❌ **WRONG:**
```css
/* After running shadcn init, you might have: */
@layer base {
  body {
    background-color: var(--background);
  }
}

@layer base {  /* ← Duplicate added by shadcn init */
  * {
    border-color: hsl(var(--border));
  }
}
```

✅ **CORRECT:**
```css
/* Merge into single @layer base block */
@layer base {
  * {
    border-color: var(--border);
  }

  body {
    background-color: var(--background);
    color: var(--foreground);
  }
}
```

**Why:**
- `shadcn init` adds its own `@layer base` block
- Results in duplicate layer declarations
- Can cause unexpected CSS priority issues
- Easy to miss during setup

**Prevention:**
- Check `src/index.css` immediately after running `shadcn init`
- Merge any duplicate `@layer base` blocks
- Keep only one base layer section

**Impact:** CSS priority issues, harder to debug styling problems

---

## Testing Gotchas

### 15. Not Testing Both Themes

❌ **WRONG:**
Only testing in light mode

✅ **CORRECT:**
Test in:
- Light mode
- Dark mode
- System mode
- Both initial load and toggle

---

### 16. Not Checking Contrast

❌ **WRONG:**
Colors look good but fail WCAG

✅ **CORRECT:**
- Use browser DevTools Lighthouse
- Check contrast ratios (4.5:1 minimum)
- Test with actual users

---

## Quick Diagnosis

**Symptoms → Likely Cause:**

| Symptom | Likely Cause |
|---------|-------------|
| `bg-primary` doesn't work | Missing `@theme inline` mapping |
| Colors all black/white | Double `hsl()` wrapping |
| Dark mode not switching | Missing ThemeProvider |
| Build fails | `tailwind.config.ts` exists with theme config |
| Text invisible | Wrong contrast colors |
| `@/` imports fail | Missing path aliases in tsconfig |

---

## Prevention Checklist

Before deploying:
- [ ] No `tailwind.config.ts` file (or it's empty)
- [ ] `components.json` has `"config": ""`
- [ ] All colors have `hsl()` wrapper in `:root`
- [ ] `@theme inline` maps all variables
- [ ] `@layer base` doesn't wrap `:root`
- [ ] Theme provider wraps app
- [ ] Tested in both light and dark modes
- [ ] All text has sufficient contrast
