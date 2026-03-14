# Migration Guide: Hardcoded Colors → CSS Variables

## Overview

This guide helps you migrate from hardcoded Tailwind colors (`bg-blue-600`) to semantic CSS variables (`bg-primary`).

**Benefits:**
- Automatic dark mode support
- Consistent color usage
- Single source of truth
- Easy theme customization
- Better accessibility

---

## Semantic Color Mapping

| Hardcoded Color | CSS Variable | Use Case |
|----------------|--------------|----------|
| `bg-red-*` / `text-red-*` | `bg-destructive` / `text-destructive` | Critical issues, errors, delete actions |
| `bg-green-*` / `text-green-*` | `bg-success` / `text-success` | Success states, positive metrics |
| `bg-yellow-*` / `text-yellow-*` | `bg-warning` / `text-warning` | Warnings, moderate issues |
| `bg-blue-*` / `text-blue-*` | `bg-info` or `bg-primary` | Info boxes, primary actions |
| `bg-gray-*` / `text-gray-*` | `bg-muted` / `text-muted-foreground` | Backgrounds, secondary text |
| `bg-purple-*` | `bg-info` | Remove - use blue instead |
| `bg-orange-*` | `bg-warning` | Remove - use yellow instead |
| `bg-emerald-*` | `bg-success` | Remove - use green instead |

---

## Migration Patterns

### Pattern 1: Solid Backgrounds

❌ **Before:**
```tsx
<div className="bg-blue-50 dark:bg-blue-950/20 text-blue-700 dark:text-blue-300">
```

✅ **After:**
```tsx
<div className="bg-info/10 text-info">
```

**Note:** `/10` creates 10% opacity

---

### Pattern 2: Borders

❌ **Before:**
```tsx
<div className="border-2 border-green-200 dark:border-green-800">
```

✅ **After:**
```tsx
<div className="border-2 border-success/30">
```

---

### Pattern 3: Text Colors

❌ **Before:**
```tsx
<span className="text-red-600 dark:text-red-400">
```

✅ **After:**
```tsx
<span className="text-destructive">
```

---

### Pattern 4: Icons

❌ **Before:**
```tsx
<AlertCircle className="text-yellow-500" />
```

✅ **After:**
```tsx
<AlertCircle className="text-warning" />
```

---

### Pattern 5: Gradients

❌ **Before:**
```tsx
<div className="bg-gradient-to-r from-green-50 to-emerald-50 dark:from-green-950/20 dark:to-emerald-950/20">
```

✅ **After:**
```tsx
<div className="bg-gradient-to-r from-success/10 to-success/20">
```

---

## Step-by-Step Migration

### Step 1: Add Semantic Colors to CSS

```css
/* src/index.css */
:root {
  /* Add these if not already present */
  --destructive: hsl(0 84.2% 60.2%);
  --destructive-foreground: hsl(210 40% 98%);
  --success: hsl(142.1 76.2% 36.3%);
  --success-foreground: hsl(210 40% 98%);
  --warning: hsl(38 92% 50%);
  --warning-foreground: hsl(222.2 47.4% 11.2%);
  --info: hsl(221.2 83.2% 53.3%);
  --info-foreground: hsl(210 40% 98%);
}

.dark {
  --destructive: hsl(0 62.8% 30.6%);
  --destructive-foreground: hsl(210 40% 98%);
  --success: hsl(142.1 70.6% 45.3%);
  --success-foreground: hsl(222.2 47.4% 11.2%);
  --warning: hsl(38 92% 55%);
  --warning-foreground: hsl(222.2 47.4% 11.2%);
  --info: hsl(217.2 91.2% 59.8%);
  --info-foreground: hsl(222.2 47.4% 11.2%);
}

@theme inline {
  --color-destructive: var(--destructive);
  --color-destructive-foreground: var(--destructive-foreground);
  --color-success: var(--success);
  --color-success-foreground: var(--success-foreground);
  --color-warning: var(--warning);
  --color-warning-foreground: var(--warning-foreground);
  --color-info: var(--info);
  --color-info-foreground: var(--info-foreground);
}
```

### Step 2: Find Hardcoded Colors

```bash
# Search for background colors
grep -r "bg-\(red\|yellow\|blue\|green\|purple\|orange\|pink\|emerald\)-[0-9]" src/

# Search for text colors
grep -r "text-\(red\|yellow\|blue\|green\|purple\|orange\|pink\|emerald\)-[0-9]" src/

# Search for border colors
grep -r "border-\(red\|yellow\|blue\|green\|purple\|orange\|pink\|emerald\)-[0-9]" src/
```

### Step 3: Replace Component by Component

Start with high-impact components:
1. Buttons
2. Badges
3. Alert boxes
4. Status indicators
5. Cards

### Step 4: Test Both Themes

After each component:
- [ ] Check light mode appearance
- [ ] Check dark mode appearance
- [ ] Verify text contrast
- [ ] Test hover/active states

---

## Example: Badge Component

❌ **Before:**
```tsx
const severityConfig = {
  critical: {
    color: 'text-red-500',
    bg: 'bg-red-500/10',
    border: 'border-red-500/20',
  },
  warning: {
    color: 'text-yellow-500',
    bg: 'bg-yellow-500/10',
    border: 'border-yellow-500/20',
  },
  info: {
    color: 'text-blue-500',
    bg: 'bg-blue-500/10',
    border: 'border-blue-500/20',
  }
}
```

✅ **After:**
```tsx
const severityConfig = {
  critical: {
    color: 'text-destructive',
    bg: 'bg-destructive/10',
    border: 'border-destructive/20',
  },
  warning: {
    color: 'text-warning',
    bg: 'bg-warning/10',
    border: 'border-warning/20',
  },
  info: {
    color: 'text-info',
    bg: 'bg-info/10',
    border: 'border-info/20',
  }
}
```

---

## Testing Checklist

After migration:
- [ ] All severity levels (critical/warning/info) visually distinct
- [ ] Text has proper contrast in both light and dark modes
- [ ] No hardcoded color classes remain
- [ ] Hover states work correctly
- [ ] Gradients render smoothly
- [ ] Icons are visible and colored correctly
- [ ] Borders are visible
- [ ] No visual regressions

---

## Verification Commands

```bash
# Should return 0 results when migration complete
grep -r "text-red-[0-9]" src/components/
grep -r "bg-blue-[0-9]" src/components/
grep -r "border-green-[0-9]" src/components/

# Verify semantic colors are used
grep -r "bg-destructive" src/components/
grep -r "text-success" src/components/
```

---

## Performance Impact

**Before:** Every component has `dark:` variants
```tsx
<div className="bg-blue-50 dark:bg-blue-950/20 text-blue-700 dark:text-blue-300 border-blue-200 dark:border-blue-800">
```

**After:** Single class, CSS handles switching
```tsx
<div className="bg-info/10 text-info border-info/30">
```

**Result:**
- 60% fewer CSS classes in markup
- Smaller HTML payload
- Faster rendering
- Easier to maintain

---

## Common Pitfalls

### 1. Forgetting to Map in @theme inline

Variables defined in `:root` but not mapped → utilities don't exist

### 2. Wrong Opacity Syntax

❌ `bg-success-10` (doesn't work)
✅ `bg-success/10` (correct)

### 3. Mixing Approaches

Don't mix hardcoded and semantic in same component - choose one approach.

### 4. Not Testing Dark Mode

Always test both themes during migration.

---

## Rollback Plan

If migration causes issues:

1. Keep original components in git history
2. Use feature flags to toggle new theme
3. Test with subset of users first
4. Have monitoring for visual regressions

---

## Further Customization

After migration, you can easily:
- Add new semantic colors
- Create theme variants (high contrast, etc.)
- Support multiple brand themes
- Implement user-selectable color schemes

All by editing CSS variables - no component changes needed!
