---
title: Global Styles
description: Our global CSS includes helpful resets to ensure consistent styling across browsers.
video: 'nEgHk2wmMjU'
sass: scss/_global.scss
---

## Font Sizing

The default font size is set to 100% of the browser style sheet, usually 16 pixels. This ensures compatibility with browser-based text zoom or user-set defaults. If you're using the Sass version of Foundation, edit the `$global-font-size` variable to change the base font size. This can be a percentage value, or a pixel value.

---

## Colors

Foundation has an accessible default color palette. The primary color is used for interactive elements, such as links and buttons. The secondary, success, warning, and alert colors are used to give more context to UI elements and actions.

<div class="grid-x grid-margin-x small-up-1 medium-up-3 large-up-5">
  <div class="cell">
    <div class="docs-color-block">
      <div class="docs-color-block-primary"></div>
      <p>Primary</p>
    </div>
  </div>
  <div class="cell">
    <div class="docs-color-block">
      <div class="docs-color-block-secondary"></div>
      <p>Secondary</p>
    </div>
  </div>
  <div class="cell">
    <div class="docs-color-block">
      <div class="docs-color-block-success"></div>
      <p>Success</p>
    </div>
  </div>
  <div class="cell">
    <div class="docs-color-block">
      <div class="docs-color-block-warning"></div>
      <p>Warning</p>
    </div>
  </div>
  <div class="cell">
    <div class="docs-color-block">
      <div class="docs-color-block-alert"></div>
      <p>Alert</p>
    </div>
  </div>
  <div class="cell">
    <div class="docs-color-block">
      <div class="docs-color-block-white"></div>
      <p>White</p>
    </div>
  </div>
  <div class="cell">
    <div class="docs-color-block">
      <div class="docs-color-block-light-gray"></div>
      <p>Light Gray</p>
    </div>
  </div>
  <div class="cell">
    <div class="docs-color-block">
      <div class="docs-color-block-medium-gray"></div>
      <p>Medium Gray</p>
    </div>
  </div>
  <div class="cell">
    <div class="docs-color-block">
      <div class="docs-color-block-dark-gray"></div>
      <p>Dark Gray</p>
    </div>
  </div>
  <div class="cell">
    <div class="docs-color-block">
      <div class="docs-color-block-black"></div>
      <p>Black</p>
    </div>
  </div>
</div>

---

### Changing the Color Palette

If you're using the Sass version of Foundation, you can easily change the color palette by editing the variables in your settings file.

The semantic colors (primary, secondary, success, warning, and alert) can be changed in the `$foundation-palette` map. The keys in this map are referenced by various settings to style components and output alternate class names.

```scss
$foundation-palette: (
  primary: #1779ba,
  secondary: #767676,
  success: #3adb76,
  warning: #ffae00,
  alert: #cc4b37,
);
```

<div class="warning callout">
  <p>If you remove a default key from `$foundation-palette`, be sure to edit any variables in your settings file that reference that color.</p>
</div>

The named colors (white, light gray, medium gray, dark gray, and black) can be changed in their respective variables

```scss
$light-gray: #e6e6e6;
$medium-gray: #cacaca;
$dark-gray: #8a8a8a;
$black: #0a0a0a;
$white: #fefefe;
```

The line `@include add-foundation-colors;` in your settings file allows you to use the following Sass variables to reference *default colors* from the palette:

- `$primary-color`
- `$secondary-color`
- `$success-color`
- `$warning-color`
- `$alert-color`

You can also use Foundation's `get-color()` function to reference *any color* from the palette. This function gives you access to custom colors you've added to the palette.

```scss
// Create a variable for my custom color.
$custom-color: get-color(custom);
```
