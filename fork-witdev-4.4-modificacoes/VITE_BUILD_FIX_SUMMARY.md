# Vite Build Fix - RichCards.vue

## Problem

The Docker build was failing with a Vite/Vue parsing error:

```
Error parsing JavaScript expression: import.meta may appear only with 'sourceType: "module"'
... RichCards.vue:153:20
@load="() => import.meta.env.MODE !== 'production' && console.log('[RichCards] Image loaded successfully:', item.media_url || item.mediaUrl)"
```

**Root Cause**: `import.meta` cannot be used directly in Vue templates - it can only be used in the `<script>` section.

## Solution Applied

### 1. Moved `import.meta` to Script Section

**Before (❌ Broken):**
```vue
<script setup>
// ... other code

function trackMetric(name, labels) {
  if (import.meta.env.MODE !== 'production') {
    console.log(`[RichCards] ${name}:`, labels);
  }
}
</script>

<template>
  <img 
    @load="() => import.meta.env.MODE !== 'production' && console.log('[RichCards] Image loaded successfully:', item.media_url || item.mediaUrl)"
  />
</template>
```

**After (✅ Fixed):**
```vue
<script setup>
// Define development mode flag once in script
const isDev = import.meta.env.MODE !== 'production';

function trackMetric(name, labels) {
  if (isDev) {
    console.log(`[RichCards] ${name}:`, labels);
  }
}

// Handle image loading success
const handleImageLoad = (src) => {
  if (isDev) {
    console.log('[RichCards] Image loaded successfully:', src);
  }
};
</script>

<template>
  <img 
    @load="handleImageLoad(item.media_url || item.mediaUrl)"
  />
</template>
```

### 2. Updated All Development Mode Checks

Replaced all instances of `import.meta.env.MODE !== 'production'` with the `isDev` constant:

- ✅ `trackMetric()` function
- ✅ `handleImageError()` function  
- ✅ `handleImageLoad()` function (new)
- ✅ `onMounted()` lifecycle hook
- ✅ `onErrorCaptured()` error handler

### 3. Created Proper Event Handler

Instead of inline template logic, created a dedicated `handleImageLoad()` method that:
- Accepts the image source as a parameter
- Uses the `isDev` flag for conditional logging
- Maintains the same debugging functionality

## Files Modified

- **`app/javascript/dashboard/components-next/message/bubbles/RichCards.vue`**
  - Added `const isDev = import.meta.env.MODE !== 'production';`
  - Created `handleImageLoad(src)` method
  - Updated all development mode checks to use `isDev`
  - Fixed template `@load` handler to use method instead of inline `import.meta`

## Result

- ✅ **Build Error Fixed**: Vite can now parse the Vue component correctly
- ✅ **Functionality Preserved**: All debugging and logging behavior remains identical
- ✅ **Performance Improved**: `import.meta.env.MODE` is evaluated once instead of multiple times
- ✅ **Code Quality**: Cleaner separation between script logic and template

## Testing

The fix can be verified by:

1. **Build Success**: Docker build should complete without Vite errors
2. **Runtime Behavior**: Development logging should work exactly as before
3. **Image Loading**: `handleImageLoad()` should log successful image loads in development mode

## Technical Notes

- **Vue/Vite Limitation**: `import.meta` expressions are only valid in module scope (script), not in template expressions
- **Performance Benefit**: Evaluating `import.meta.env.MODE` once at component initialization is more efficient than multiple evaluations
- **Maintainability**: Centralized development mode flag makes it easier to modify debugging behavior