# Widget styling kit

The live chat widget (v2) is themeable end to end. A **theme** is a named
bundle of design tokens. `standard` is the default; everything else is
expressed purely as overrides of it.

## Choosing a theme

Pass a theme name in your embed snippet:

```js
window.chatwootSettings = {
  widgetVersion: 'v2',
  theme: 'editorial',
};
```

Adopt a theme but override part of it:

```js
window.chatwootSettings = {
  widgetVersion: 'v2',
  theme: { name: 'editorial', primary: '#B3261E', radius: '8px' },
};
```

Build your own from the defaults by passing only tokens:

```js
window.chatwootSettings = {
  widgetVersion: 'v2',
  theme: { primary: '#0F766E', radius: '4px', fontSizeRoot: '15px' },
};
```

Switch at runtime — no reload:

```js
window.$chatwoot.setTheme('tetris');
window.$chatwoot.setTheme({ primary: '#7C3AED' }); // merges into the current theme
```

## Bundled themes

| Name | Look |
| --- | --- |
| `standard` | The default. Neutral surfaces, 14px radius, Inter. |
| `frosted` | Translucent chrome that picks up the page behind the widget. |
| `tetris` | Blocky arcade: pixel type, square corners, thick borders, hard shadows. |
| `editorial` | Publishing: serif, warm cream, generous spacing, no shadows. |

## Token reference

Every token is optional. Omitted tokens keep their `standard` value.

### Colour

| Token | Default | Controls |
| --- | --- | --- |
| `primary` | `#2781F6` | Accent for buttons, links, active states |
| `primaryForeground` | auto | Text on primary. Computed from `primary`'s luminance unless set |
| `background` | white | The panel canvas |
| `solid` | white | Card and chrome surfaces |
| `surface` | light grey | Hover and inset surfaces |
| `muted` | light grey | Icon wells, agent bubbles |
| `border` | light grey | Card and control borders |
| `text` / `textMuted` | near-black / grey | Primary and secondary text |
| `bubbleVisitorBg` / `bubbleVisitorText` | primary / white | The visitor's messages |
| `bubbleAgentBg` / `bubbleAgentText` | muted / text | Agent and AI messages |
| `canvasImage` | `none` | A CSS background image behind the whole panel |

### Geometry

| Token | Default | Controls |
| --- | --- | --- |
| `radius` | `14px` | Card radius |
| `buttonRadius` | `radius − 6px` | Buttons, inputs, active tab |
| `borderWidth` | `1px` | Card and control borders |
| `bubbleRadius` | `18px` | Message bubbles |
| `bubbleTailRadius` | `6px` | The bubble's "tail" corner |
| `avatarRadius` | `9999px` | Avatar shape — set `0px` for square |
| `shadowCard` | whisper | Card elevation. `none` for flat, offsets for hard shadows |

### Layout and chrome

| Token | Default | Controls |
| --- | --- | --- |
| `fontSizeRoot` | `16px` | **The density lever.** Type and spacing are rem-based, so this rescales the whole interface |
| `rowPaddingX` / `rowPaddingY` | `1rem` | List row padding |
| `cardGap` | `1rem` | Space between cards on Home |
| `headerHeight` | `4rem` | Screen header |
| `tabHeight` | `3rem` | Tab bar items |
| `iconSize` | `1.125rem` | Chrome icons |
| `ringWidth` | `3px` | Focus ring thickness |

### Typography

| Token | Default | Controls |
| --- | --- | --- |
| `font` | Inter | Font family. Falls back to Inter |
| `fontUrl` | – | An **https** stylesheet URL for the font, loaded inside the widget |
| `fontWeightStrong` | `620` | Headings and titles |
| `trackingDisplay` | `-0.025em` | Heading letter-spacing |
| `overlineTransform` | `uppercase` | Section labels — `none` for sentence case |
| `transitionDuration` | `150ms` | Interaction motion. `0ms` disables |

### Material

| Token | Values | Controls |
| --- | --- | --- |
| `material` | `frosted` | Makes chrome translucent so the host page shows through |
| `darkMode` | `light` \| `dark` \| `auto` | Colour scheme |

## Authoring a theme

Add a token bundle to `themes/index.js` and register it in `THEMES`:

```js
const midnight = {
  primary: '#8B5CF6',
  background: '#0B0B0F',
  solid: '#15151C',
  border: '#26262F',
  text: '#F5F5F7',
  radius: '10px',
  shadowCard: 'none',
};

export const THEMES = { standard, frosted, tetris, editorial, midnight };
```

### Rules worth following

- **Change tokens, not components.** If a look needs a component edit, it
  probably needs a new token instead — that keeps every theme working.
- **Start from `fontSizeRoot`.** It moves density and scale together and does
  more for a theme's character than any colour.
- **Keep contrast.** Text tokens must stay legible on their surfaces; the
  widget is support UI before it is decoration.
- **`frosted` legibility depends on the host page.** Over busy imagery it will
  get muddy — prefer it on calm backgrounds.
- **Host-supplied values are sanitised.** Values containing `;`, `{}`,
  `@import`, `javascript:` or `url()` are rejected, and `fontUrl` must be
  https.
- **Accessibility settings win.** `prefers-reduced-transparency` falls back to
  opaque surfaces and `prefers-reduced-motion` disables animation, regardless
  of the theme.
