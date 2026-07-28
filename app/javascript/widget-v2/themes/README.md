# Widget styling kit

The live chat widget (v2) is themeable end to end. Everything visual is a
**design token**, so a brand can match the widget to its own identity without
touching the widget's code.

`standard` is the only bundled theme and is the default.

## Customising for a brand

Pass tokens in your embed snippet:

```js
window.chatwootSettings = {
  widgetVersion: 'v2',
  theme: {
    primary: '#0F766E',
    radius: '4px',
    fontSizeRoot: '15px',
    font: 'Söhne',
    fontUrl: 'https://example.com/fonts/sohne.css',
  },
};
```

Change tokens at runtime — no reload. Values merge into the current theme, so
a single token can be changed on its own:

```js
window.$chatwoot.setTheme({ primary: '#7C3AED' });
window.$chatwoot.setTheme({ material: 'frosted' });
window.$chatwoot.setTheme({ material: '' }); // back to solid
```

An empty value resets a token to its default.

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
| `darkMode` | `light` \| `dark` \| `auto` | Colour scheme the host asks for |
| `colorScheme` | `light` \| `dark` | Pins the scheme, ignoring `darkMode` |

## Light and dark

By default the widget follows `darkMode` — the host's setting, or the
visitor's OS preference under `auto` — and the tokens you set apply to both
schemes.

A theme built around one palette should say so with `colorScheme`. Spotify's
ground is near-black by design, so it pins `colorScheme: 'dark'` and stays
dark on a light host page; without it, a light host would leave the theme's
white ink on a light surface.

To support both schemes from one theme, put the differences in `light` and
`dark` blocks. They are applied last, over everything else:

```js
const acme = {
  primary: '#2464EC',
  radius: '8px',
  dark: {
    background: '#0B0B0F',
    solid: '#15151C',
    border: '#26262F',
    text: '#F5F5F7',
    primary: '#6E9BFF',
  },
};
```

## Bundling a named theme

If a look should be reusable rather than pasted into every embed, register a
token bundle in `themes/index.js` — it then becomes available as
`theme: '<name>'`:

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

export const THEMES = { standard, midnight };
```

A named theme can still be overridden per site:
`theme: { name: 'midnight', primary: '#B3261E' }`.

### Rules worth following

- **Change tokens, not components.** If a look needs a component edit, it
  probably needs a new token instead — that keeps every theme working.
- **Start from `fontSizeRoot`.** It moves density and scale together and does
  more for a theme's character than any colour.
- **Keep contrast.** Text tokens must stay legible on their surfaces; the
  widget is support UI before it is decoration.
- **The `frosted` material's legibility depends on the host page.** Over busy
  imagery it will get muddy — prefer it on calm backgrounds.
- **Dark palettes need the full colour set.** Setting only `background` leaves
  text and borders on their light defaults; set `solid`, `surface`, `muted`,
  `border`, `hairline`, `text`, `textMuted` and `textFaint` together.
- **A one-palette theme should pin `colorScheme`.** Otherwise the host or the
  visitor's OS can flip the scheme underneath it and break contrast.
- **Host-supplied values are sanitised.** Values containing `;`, `{}`,
  `@import`, `javascript:` or `url()` are rejected, and `fontUrl` must be
  https.
- **Accessibility settings win.** `prefers-reduced-transparency` falls back to
  opaque surfaces and `prefers-reduced-motion` disables animation, regardless
  of the theme.
