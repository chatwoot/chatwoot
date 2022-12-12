---
title: Flexbox Utilities
description: Flexbox utility classes and mixins to make working with flexbox easier.
video: 'KxafSdyTCIg'
sass:
  - scss/xy-grid/*.scss
  - scss/components/_flex.scss
  - scss/util/_flex.scss
---

## Flexbox Utilities

Flexbox makes horizontal and vertical alignment painless, through the CSS properties [`align-items`](https://developer.mozilla.org/en-US/docs/Web/CSS/align-items), [`align-self`](https://developer.mozilla.org/en-US/docs/Web/CSS/align-self), and [`justify-content`](https://developer.mozilla.org/en-US/docs/Web/CSS/justify-content). Foundation includes a handful of classes for these properties, which work with any flexbox-enabled component.

To understand how these classes work, you need to understand the parent-child relationship created with flexbox. An element with `display: flex` is a *flex parent*, and can horizontally or vertically align its children. All immediate children of the flex parent are *flex children*. A flex child can vertically align itself.

<div class="alert callout">
  <p>In the below examples we are using [XY Grid](xy-grid.html) classes instead of [Legacy Flex Grid's](flex-grid.html) <code>row</code> and <code>column</code>. These examples will work for <code>row</code> and <code>column</code> but then again the Legacy Flex Grid will be deprecated from Foundation 7 so we recommend to use XY Grid.</p>
</div>

Here's a basic example: when using the grid, a `grid-x` or `grid-y` is a flex parent, and a `cell` is a flex child. Use `grid-margin-x` or `grid-padding-x` for adding [gutters](xy-grid.html#gutters)

```html_example
<div class="grid-x grid-padding-x">
  <div class="cell small-4">Cell 1</div>
  <div class="cell small-4">Cell 2</div>
  <div class="cell small-4">Cell 3</div>
</div>
```

---

### Horizontal Alignment

Horizontal alignment classes are applied to flex parents. Left alignment is the default, but you can use one of these classes to change this:

- `.align-right`
- `.align-center`
- `.align-justify`
- `.align-spaced`

<div class="docs-codepen-container">
<a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/mwqGLm?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<div class="grid-x grid-padding-x"> <!-- Aligned to the left -->
  <div class="cell small-4">Aligned to</div>
  <div class="cell small-4">the left</div>
</div>
<div class="grid-x grid-padding-x align-right"> <!-- Aligned to the right -->
  <div class="cell small-4">Aligned to</div>
  <div class="cell small-4">the right</div>
</div>
<div class="grid-x grid-padding-x align-center"> <!-- Aligned to the center -->
  <div class="cell small-4">Aligned to</div>
  <div class="cell small-4">the center</div>
</div>
<div class="grid-x grid-padding-x align-justify"> <!-- Aligned to the edges -->
  <div class="cell small-4">Aligned to</div>
  <div class="cell small-4">the edges</div>
</div>
<div class="grid-x grid-padding-x align-spaced"> <!-- Aligned to the space around -->
  <div class="cell small-4">Aligned to</div>
  <div class="cell small-4">the space around</div>
</div>
```

You might be wondering what the difference between `.align-justify` and `.align-spaced` is. A justified grid (`justify-content: space-between`) evenly distributes the space *between* each column. The first and last columns pin to the edge of the grid.

A spaced grid (`justify-content: space-around`) evenly distributes the space *around* each column. This means there will always be space to the left of the first column, and to the right of the last column.

The horizontal alignment classes are shorthands for the `justify-content` CSS property. [Learn more about `justify-content`](https://developer.mozilla.org/en-US/docs/Web/CSS/justify-content).

---

### Vertical Alignment

Vertical alignment can be applied to a flex parent&mdash;which will align all the children automatically&mdash;or to a flex child, which will align only that element.

Stretch alignment is the default. To set parent alignment, use these classes:

- `.align-top`
- `.align-middle`
- `.align-bottom`
- `.align-stretch`

<div class="primary callout">
  <p>Note that with vertical alignment, we use the term "middle" for the midpoint, while with horizontal alignment, we use the term "center". As we can't have two CSS classes with the same name, thus we are using different terms.</p>
</div>

<div class="docs-codepen-container">
<a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/LLOgYx?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<div class="grid-x grid-padding-x align-top">
  <div class="cell small-4">I'm at the top (default)</div>
  <div class="cell small-4">Lorem ipsum dolor sit amet, consectetur adipisicing elit. Voluptatum, tempora. Impedit eius officia possimus laudantium? Molestiae eaque, sapiente atque doloremque placeat! In sint, fugiat saepe sunt dolore tempore amet cupiditate.</div>
</div>
```

<div class="docs-codepen-container">
<a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/vZWVOW?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<div class="grid-x grid-padding-x align-middle">
  <div class="cell small-4">I'm in the middle</div>
  <div class="cell small-4">Lorem ipsum dolor sit amet, consectetur adipisicing elit. Voluptatum, tempora. Impedit eius officia possimus laudantium? Molestiae eaque, sapiente atque doloremque placeat! In sint, fugiat saepe sunt dolore tempore amet cupiditate.</div>
</div>
```

<div class="docs-codepen-container">
<a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/awVRvZ?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<div class="grid-x grid-padding-x align-bottom">
  <div class="cell small-4">I'm at the bottom</div>
  <div class="cell small-4">Lorem ipsum dolor sit amet, consectetur adipisicing elit. Voluptatum, tempora. Impedit eius officia possimus laudantium? Molestiae eaque, sapiente atque doloremque placeat! In sint, fugiat saepe sunt dolore tempore amet cupiditate.</div>
</div>
```

<div class="docs-codepen-container">
<a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/wePYKY?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<div class="grid-x grid-padding-x align-stretch">
  <div class="cell small-4">These cells have the same height</div>
  <div class="cell small-4">Lorem ipsum dolor sit amet, consectetur adipisicing elit. Voluptatum, tempora. Impedit eius officia possimus laudantium? Molestiae eaque, sapiente atque doloremque placeat! In sint, fugiat saepe sunt dolore tempore amet cupiditate.</div>
</div>
```

---

To align an individual child, use the below classes. They use the same alignment terms as the parent-level classes, but the classes start with `.align-self-` instead of `.align-`.

- `.align-self-top`
- `.align-self-middle`
- `.align-self-bottom`
- `.align-self-stretch`

<div class="docs-codepen-container">
<a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/NgwOxe?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<div class="grid-x grid-padding-x">
    <div class="cell small-3 align-self-bottom"><div class="demo">Align bottom</div></div>
    <div class="cell small-3 align-self-middle"><div class="demo">Align middle</div></div>
    <div class="cell small-3 align-self-stretch"><div class="demo">Align stretch</div></div>
    <div class="cell small-3 align-self-top"><div class="demo">Align top. Lorem ipsum dolor sit amet, consectetur adipisicing elit. Non harum laborum cum voluptate vel, eius adipisci similique dignissimos nobis at excepturi incidunt fugit molestiae quaerat, consequuntur porro temporibus. Nisi, ex?</div></div>
  </div>
```

---

### Central Alignment

Central alignment can be applied to a flex parent, which will centrally align all children horizontally and vertically automatically. To set this to your layout, simply use the class: `.align-center-middle`.

<div class="primary callout">
  <p>We are using `.text-center` class just for demo purposes here.</p>
</div>

<div class="docs-codepen-container">
<a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/vZWVXp?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<div class="grid-x grid-padding-x align-center-middle text-center" style="height: 200px;">
  <div class="cell small-4">I am in the center-middle</div>
  <div class="cell small-4">I am also centrally located</div>
</div>
```

---

## Vanilla Flexbox Helper Classes

Foundation also includes some helper classes for quickly applying flex
container & direction attributes to elements.

To make something a flex container, simply apply
- `.flex-container`

And to change its flex direction from row to column you can use the helper classes:

- `.flex-dir-row` (default)
- `.flex-dir-row-reverse`
- `.flex-dir-column`
- `.flex-dir-column-reverse`

For children, there are 3 quick helper classes to apply the flex property. These control how the containers take up space relative to their siblings:

- `.flex-child-auto` (auto size flex child)
- `.flex-child-grow` (flex child that will grow to take up all possible space)
- `.flex-child-shrink` (flex child that will shrink to minimum possible space)

<div class="docs-codepen-container">
<a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/bRYmRZ?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<div class="grid-x grid-padding-x">
  <div class="cell small-4 flex-container flex-dir-column">
    <div class="callout primary flex-child-auto">Auto</div>
    <div class="callout primary flex-child-auto">Auto</div>
    <div class="callout primary flex-child-shrink">Shrink</div>
  </div>
  <div class="cell small-4">
  </div>
  <div class="cell small-4 align-self-top">Align top. Lorem ipsum dolor sit amet, consectetur adipisicing elit. Non harum laborum cum voluptate vel, eius adipisci similique dignissimos nobis at excepturi incidunt fugit molestiae quaerat, consequuntur porro temporibus. Nisi, ex?Align top. Lorem ipsum dolor sit amet, consectetur adipisicing elit. Non harum laborum cum voluptate vel, eius adipisci similique dignissimos nobis at excepturi incidunt fugit molestiae quaerat, consequuntur porro temporibus. Nisi, ex?Align top. Lorem ipsum dolor sit amet, consectetur adipisicing elit. Non harum laborum cum voluptate vel, eius adipisci similique dignissimos nobis at excepturi incidunt fugit molestiae quaerat, consequuntur porro temporibus. Nisi, ex?</div>
</div>
```

### Responsive Classes 

All of these helper classes come in responsive varieties, prefixed with all of your named breakpoints.

These vanilla flexbox helper classes also have an optional mobile first responsive classes so that setting a class will apply to the small breakpoint and large unless overridden by a class for a larger breakpoint.. Example: `class="flex-child-shrink large-flex-child-auto"` will be shrink on the small and medium breakpoints and then auto on large. 

These optional responsive classes can be disabled by setting `$flexbox-responsive-breakpoints` to `false`. See [here](#sass-variables)

<div class="docs-codepen-container">
<a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/yXPRjY?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<div class="grid-x grid-padding-x">
  <div class="cell small-12 flex-container flex-dir-column large-flex-dir-row">
    <div class="callout primary flex-child-auto">Auto</div>
    <div class="callout primary flex-child-auto">Auto</div>
    <div class="callout primary flex-child-shrink large-flex-child-auto">Auto on Large</div>
  </div>
  <div class="cell small-12 align-self-top">Align top. Lorem ipsum dolor sit amet, consectetur adipisicing elit. Non harum laborum cum voluptate vel, eius adipisci similique dignissimos nobis at excepturi incidunt fugit molestiae quaerat, consequuntur porro temporibus. Nisi, ex?Align top. Lorem ipsum dolor sit amet, consectetur adipisicing elit. Non harum laborum cum voluptate vel, eius adipisci similique dignissimos nobis at excepturi incidunt fugit molestiae quaerat, consequuntur porro temporibus. Nisi, ex?Align top. Lorem ipsum dolor sit amet, consectetur adipisicing elit. Non harum laborum cum voluptate vel, eius adipisci similique dignissimos nobis at excepturi incidunt fugit molestiae quaerat, consequuntur porro temporibus. Nisi, ex?</div>
</div>
```

---

## Source Ordering

Flexbox supports source ordering, making it easy to rearrange columns on different screen sizes without weird relative positioning tricks.

The CSS property is easy enough to remember.

```scss
.element {
  order: 1;
}
```

Columns within a row will be sorted by their `order` property. Lower numbers are placed first. If multiple columns have the same number, they're sorted in the order they appear in the HTML.

We have a set of classes that make it easy to setup source ordering in your HTML. They also come in responsive flavors, allowing you to reorder a grid on different screen sizes.

<p>
  <a class="" data-open-video="27:19"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
<a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/ZyaqNL?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<div class="grid-x grid-padding-x">
  <div class="cell small-6 small-order-2 medium-order-1">
    This column will come second on small, and first on medium and larger.
  </div>
  <div class="cell small-6 small-order-1 medium-order-2">
    This column will come first on small, and second on medium and larger.
  </div>
</div>
```

---

## Helper Mixins

If you're using the Sass version of Foundation, you can access the above helpers as mixins as well.

For parent-level alignment, use `flex-align()`. You can pass in a horizontal alignment (`$x`), vertical alignment (`$y`), or both.

```scss
.container {
  @include flex-align($x: center, $y: stretch);
}
```

For child-level alignment, use `flex-align-self()`. You can pass in any vertical alignment.

```scss
.sidebar {
  @include flex-align-self(bottom);
}
```

Interested in building your own flexbox-ey component? Use the `flex()` mixin to get started.

```scss
.flexish-thang {
  @include flex;
  @include flex-align(center, middle);
}
```
