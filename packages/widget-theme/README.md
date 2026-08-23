# @whisker/widget-theme 🐾

Theme system for the Whisker web widget — isolated from upstream code.

## Layout

```
theme.schema.json   JSON schema for a theme file
themes/*.json       8 default themes (paw-blob, cat, owl, fox, ghost, robot-box, heart, star)
icons/*.svg         8 default launcher glyphs (white, tinted at runtime)
src/icons.js        glyph registry
src/motions.js      launcher motion presets (bounce/tada/wiggle/hop) as injected keyframes
src/index.js        applyWidgetTheme() / loadTheme() / startRecurringMotion()
demo/index.html     demo page — 3 themes from one SDK build
```

A copy of `themes/*.json` is served from `public/widget-themes/` for runtime fetches.

## Usage

Embed the widget as usual and pass a theme via `chatwootSettings.theme`
(inline object, theme id string resolved from `/widget-themes/<id>.json`, or any URL):

```html
<script>
  window.chatwootSettings = {
    // ...normal settings...
    theme: 'fox',                       // or an object, or "https://…/my-theme.json"
  };
</script>
```

The SDK applies it after the launcher bubble mounts:

- `colors.primary` → bubble background (falls back to inbox `widgetColor`)
- `icon` → launcher glyph (default ids or custom URL/data-URI)
- `motion.launcher` → `none | bounce | tada | wiggle | hop`
- `sound.pack` → reserved for widget-side notification tone selection
- `petMode` → reserved for P5 (mascot mode)

## Notes

- The package is bundled into `sdk.js` via the `widgetTheme` vite alias.
- No upstream behavior changes when no theme is provided.
- Schema validation: `theme.schema.json` (draft-07).
