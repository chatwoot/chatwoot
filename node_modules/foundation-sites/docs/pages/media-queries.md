---
title: Media Queries
description: CSS media queries allow us to adjust the display and orientation of content at different screen sizes.
video: gqqi2cqlST8
sass: scss/util/_breakpoint.scss
js: js/foundation.util.mediaQuery.js
tags:
  - breakpoints
---

<div class="callout training-callout">
  <p>Build better websites and apps, code cleaner, and become a better front-end developer with Foundation training. We're running two online webinar training sessions this month where we break down how to get the most out of Foundation and leap ahead skillwise.</p>
  <a href="http://zurb.com/university/courses" target="_blank"> Get registered →</a>
</div>

## Default Media Queries

Foundation for Sites has three core breakpoints:

- **Small:** any screen.
- **Medium:** any screen 640 pixels or wider.
- **Large:** any screen 1024 pixels or wider.

Many components can be modified at different screen sizes using special *breakpoint classes*. The grid is the most obvious example. In the code below, the left-hand column is six columns wide on small screens, hence `.small-6`. On medium-sized screens, the class `.medium-4` overrides the small style, changing the column to be four wide.

```html
<div class="grid-x grid-margin-x">
  <div class="cell small-6 medium-4"></div>
  <div class="cell small-6 medium-8"></div>
</div>
```

If you're using the CSS version of Foundation, use these media queries to imitate the three core breakpoints:

```css
/* Small only */
@media screen and (max-width: 39.9375em) {}

/* Medium and up */
@media screen and (min-width: 40em) {}

/* Medium only */
@media screen and (min-width: 40em) and (max-width: 63.9375em) {}

/* Large and up */
@media screen and (min-width: 64em) {}

/* Large only */
@media screen and (min-width: 64em) and (max-width: 74.9375em) {}
```

---

## Upgrading from Foundation 5

In Foundation 5, breakpoints were accessed using a series of Sass variables named `$small-up`, `$small-only`, `$medium-only`, and so on. In Foundation 6, this method of writing media queries has been replaced with a dedicated [breakpoint mixin](#the-breakpoint-mixin), described below. **The legacy variables will be removed in Foundation 6.3.**

To upgrade your existing media queries, replace rulesets like this:

```scss
@media #{$medium-only} {
}
```

With this:

```scss
@include breakpoint(medium only) {
}
```

---

## Changing the Breakpoints

If you're using the Sass version of Foundation, the default breakpoints can be changed. The names of the breakpoints, and their widths, are stored in a `$breakpoints` variable in the settings file.

```scss
$breakpoints: (
  small: 0px,
  medium: 640px,
  large: 1024px,
  xlarge: 1200px,
  xxlarge: 1440px,
);
```

<div class="primary callout">
  <p>Even though the above values are in pixels, they're converted to ems at the end for use in media queries.</p>
</div>

Changing the widths of any of the breakpoints is as easy as changing the pixel values in this map. Note that here there are two extra breakpoints: `xlarge` and `xxlarge`. We don't use these for any components, and also don't output any CSS classes that use them by default.

You can change that by modifying the `$breakpoint-classes` variable in your settings file. This is a list of breakpoint names. Adding or removing names from the list will change the CSS class output. It looks like this by default:

```scss
$breakpoint-classes: (small medium large);
```

For example, to get `.xlarge` classes in your CSS, for use in the grid, Menu, and more, just add it to the end of the list:

```scss
$breakpoint-classes: (small medium large xlarge);
```

---

## Sass

### The Breakpoint Mixin

Our `breakpoint()` mixin makes it easy to write media queries. You can use the named breakpoints, or a custom pixel, rem, or em value.

To use the mixin, call it with `@include`, and then include the CSS content you want inside the curly braces.

```scss
.element {
  // Only affects medium screens and larger
  @include breakpoint(medium) {
    // All CSS in here goes inside the media query
  }
}
```

The behavior of the media query can be changed by adding the keyword `down` or `only` after the breakpoint value, separated by a space.

```scss
.element {
  // Only affects medium screens and smaller
  @include breakpoint(medium down) { }
  // Only affects medium screens, not small or large
  @include breakpoint(medium only) { }
}
```

It's also possible to pass in custom values. You can enter a pixel, rem, or em value&mdash;all values are converted to em at the end.

```scss
.element {
  // Converted to 20em
  @include breakpoint(320px) { }
  // Unitless values are assumed to be pixels
  @include breakpoint(320) { }
  // Converted to 40em
  @include breakpoint(40rem) { }
}
```

Lastly, there are three special media queries that are not width-based: `portrait`, `landscape`, and `retina`. Using these keywords with the `breakpoint()` mixin will output a media query for device orientation or pixel density, rather than screen width.

```scss
.element {
  @include breakpoint(landscape) {
    // CSS for landscape-oriented devices only
  }
  @include breakpoint(retina) {
    // CSS for high-resolution displays only
  }
}
```

---

### Breakpoint Function

The functionality of the `breakpoint()` mixin comes from an internal function, also called `breakpoint()`. If you want to write your own media queries, you can use the `breakpoint()` function to access the logic of the mixin directly.

```scss
@media screen and #{breakpoint(medium)} {
  // Medium and up styles
}
```

This can be used to combine multiple media queries together.

```scss
@media screen and #{breakpoint(medium)} and #{breakpoint(xlarge down)} {
  // Medium to extra large styles
}
```

---

## JavaScript

### Working with Media Queries

The Foundation JavaScript includes a set of helper functions for working with media queries. They're all on the `Foundation.MediaQuery` object.

<div class="callout warning">
  The MediaQuery utility uses the Sass breakpoint settings and requires the Foundation CSS to be imported. For Sass users, you need to include either `foundation-everything()` or `foundation-global-styles()`.
</div>

Get the name of the current breakpoint with `MediaQuery.current`.

```js
Foundation.MediaQuery.current // => 'small', 'medium', etc.
```

To see if the screen is currently a certain breakpoint or larger, use `MediaQuery.atLeast`.

```js
if (Foundation.MediaQuery.atLeast('medium')) {
  // True if medium or large
  // False if small
}
```

To see if the screen is currently a certain breakpoint, use `MediaQuery.is`.

```js
if (Foundation.MediaQuery.is('small only')) {
  // True if small
  // False if medium or large
}
```

To get the media query of a breakpoint, use `MediaQuery.get`.

```js
Foundation.MediaQuery.get('medium') // => only screen and (min-width: 640px)
```

---

### Watching for Breakpoint Changes

The media query helper broadcasts an event on the window every time the breakpoint changes. We use this internally with plugins like Interchange to detect a shift in breakpoint. You can also subscribe to the event yourself.

```js
$(window).on('changed.zf.mediaquery', function(event, newSize, oldSize) {
  // newSize is the name of the now-current breakpoint, oldSize is the previous breakpoint
});
```
