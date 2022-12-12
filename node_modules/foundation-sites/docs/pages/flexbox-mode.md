---
title: Flexbox Mode
description: For browsers with cutting-edge support, some of Foundation's key components can be converted to flexbox.
video: 'KxafSdyTCIg'
sass:
  - scss/components/_flex.scss
  - scss/util/_flex.scss
---

## Flexbox Mode

Foundation components use a combination of floats, vertical alignment, table cells, and various other CSS hacks to get layouts looking right. These days though, there's a better way... if you are happy with the below browser support!

Enabling **flexbox mode** replaces those hacks with flexbox properties, streamlining how layouts are made, and making sizing and alignment of elements much easier.

Flexbox mode is only supported in these browsers:

- The latest Chrome and Firefox
- Safari 6+
- IE/Edge 10+
- iOS 7+
- Android 4.4+

---

## Enabling Flexbox Mode

If you're using the CSS version of Foundation, you can generate a <a href="https://foundation.zurb.com/sites/download">custom download of Foundation</a> with flexbox mode enabled. If you're using the Sass version of Foundation, you can enable flexbox mode two ways:

If you use the `foundation-everything()` mixin in your main Sass file, pass in the parameter `true` to enable flexbox mode.

```scss
@include foundation-everything(true);
```

If you included each component manually (like our starter projects do), open your settings file (basic template: scss/_settings.scss, ZURB template: src/assets/scss/_settings.scss) and set `$global-flexbox` to `true`, and remove the `@include` for the float grid and replace it with the one for the flex grid, along with the helper classes (basic template: scss/app.scss, ZURB template: src/assets/scss/app.scss):

```scss
$global-flexbox: true;

// @include foundation-grid;
@include foundation-flex-grid;
@include foundation-flex-classes;
```

---

## Supported Components

Besides the flex grid, these components have flexbox modes:

- [Button group](button-group.html)
- [Input group - (Forms)](forms.html#inline-labels-and-buttons)
- [Menu](menu.html)
- [Top bar](top-bar.html)
- [Media object](media-object.html)
- [Title bar](off-canvas.html#title-bar)
- [Card](card.html)

In general, all of the components work exactly the same. However, a few of them require slight changes to CSS classes used to work properly. Refer to the documentation for each to find out what's different.
