---
title: Flex Grid
description: New in Foundation 6 is a Flexbox-powered grid, which you can use instead of the traditional float grid.
sass: scss/grid/_flex-grid.scss
video: tpmQcZSPw4Q
---

<div class="callout training-callout">
  <p>Become a master of the Foundation Grids to create complex layouts faster and with less code. The new XY Grid is the newest and most powerful version. Stay up-to-date with all the new features in Foundation 6.4 and learn how to migrate to the XY Grid with our online webinar training. You’ll also learn all the useful UI components and Foundation JavaScript to really crush your projects.</p>
  <a href="http://zurb.com/university/foundation-intro" target="_blank">Get registered for an upcoming Foundation training →</a>
</div>

The flex grid works very similarly to the standard float grid, but includes a number of useful features only possible with flexbox, like horizontal and vertical alignment, automatic sizing, and easier source ordering.

---

## Browser support

The flex grid is only supported in Chrome, Firefox, Safari 6+, IE10+, iOS 7+, and Android 4.4+. Flexbox is supported in Android 2, but not reliably enough for use with this grid. ([View flexbox browser support.](http://caniuse.com/#feat=flexbox)) We recommend only using the flex grid on projects that can live with purely cutting-edge browser support.

<div class="callout warning">
  <p>In Firefox 43+, images in flex columns may overflow their container. To fix this, add a defined <code>width</code> to any images inside a flex column, or use <code>width: 100%</code> for full-bleed images.</p>
</div>

---

## Importing

<div class="docs-video-codepen-container">
  <a class="" data-open-video="2:45"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</div>

<div class="callout alert">
  **From Foundation v6.4, the Flex Grid is disabled by default**, replaced by the new [XY Grid](xy-grid.html). Unless you need to support IE 10, it is recommended to use the XY Grid.
</div>

To use the Flex Grid in Foundation v6.4+, you need to:
* In CDN link or package managers: import `foundation-flex.css` in place of `foundation.css`.
* In Sass: set `$xy-grid` to `false`.

If you're using the Sass version of Foundation, you can enable a framework-wide flexbox mode, and add exports for the flex grid and flexbox helper classes. [Learn more about enabling flexbox mode.](flexbox.html#enabling-flexbox-mode)

You can manually generate the Flex Grid with:
```scss
@import 'foundation';

// @include foundation-grid;
@include foundation-flex-classes;
@include foundation-flex-grid;
```

<div class="callout primary">
  <p>The flex grid uses the same settings variables as the float grid to adjust gutter size, column count, and so on. Refer to the <a href="grid.html#sass-variables">Sass variable reference</a> for the default grid to see how the flex grid can be customized.</p>
</div>

<div class="callout warning">
  <p>The standard grid and flex grid use some of the same classes, namely <code>.row</code> and <code>.column</code>, and don't play nice together. If you want to use both in the same project, we recommend using the Sass mixins for each grid, instead of the default CSS.</p>
</div>

---

## Basics

The structure of the flex grid is identical to that of the float grid. Rows use the class `.row`, and columns use the class `.column` (or `.columns`). Basic percentage-based sizing can also be done using the same grid classes you're used to: `.small-6`, `.medium-12`, and so on.

<p>
  <a class="" data-open-video="6:09"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="http://codepen.io/ZURBFoundation/pen/dWmVax?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<div class="row">
  <div class="columns small-6">6 columns</div>
  <div class="columns small-6">6 columns</div>
</div>
<div class="row">
  <div class="columns medium-6 large-4">12/6/4 columns</div>
  <div class="columns medium-6 large-8">12/6/8 columns</div>
</div>
```

---

## Advanced Sizing

If no sizing class is added to the column, it will simply expand to fill the leftover space. We call this an *expand behavior*.

<p>
  <a class="" data-open-video="10:29"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="http://codepen.io/ZURBFoundation/pen/XREzBv?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<div class="row">
  <div class="columns small-4">4 columns</div>
  <div class="columns">Whatever's left!</div>
</div>
```

---

Multiple expanding columns will share the leftover space equally.

<p>
  <a class="" data-open-video="11:04"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="http://codepen.io/ZURBFoundation/pen/pPLdYY?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<div class="row">
  <div class="columns small-4">4 columns</div>
  <div class="columns">Whatever's left!</div>
  <div class="columns">Whatever's left!</div>
</div>
```

---

A column can also be made to *shrink*, by adding the `.shrink` class. This means it will only take up the horizontal space its contents need.

<p>
  <a class="" data-open-video="13:34"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="http://codepen.io/ZURBFoundation/pen/aWYVgd?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<div class="row">
  <div class="columns shrink">Shrink!</div>
  <div class="columns">Expand!</div>
</div>
```

---

## Responsive Adjustments

Columns in a flex grid will not wrap if not given an explicit size&mdash;this is what allows the magical auto-sizing to work. To make columns stack on smaller screens, add the class `.small-12` manually.

To switch back to the expand behavior from a percentage or shrink behavior, use the classes `.medium-expand` or `.large-expand`. In the below example, the columns stack on small screens, and become even-width on large screens.

<div class="docs-codepen-container">
<a class="codepen-logo-link" href="http://codepen.io/ZURBFoundation/pen/vmRpBJ?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<div class="row">
  <div class="columns small-12 large-expand">One</div>
  <div class="columns small-12 large-expand">Two</div>
  <div class="columns small-12 large-expand">Three</div>
  <div class="columns small-12 large-expand">Four</div>
  <div class="columns small-12 large-expand">Five</div>
  <div class="columns small-12 large-expand">Six</div>
</div>
```

---

### Automatic Stacking

We have a few shorthand classes for the above behavior. Use the `.[size]-unstack` classes to stack all columns in the row by default, and then unstack them on a larger screen size, making each one equal-width.

<div class="docs-codepen-container">
<a class="codepen-logo-link" href="http://codepen.io/ZURBFoundation/pen/xdWpER?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<div class="row medium-unstack">
  <div class="columns">One</div>
  <div class="columns">Two</div>
  <div class="columns">Three</div>
  <div class="columns">Four</div>
  <div class="columns">Five</div>
  <div class="columns">Six</div>
</div>
```

---

## Column Alignment

Columns in a flex grid can be aligned across the horizontal or vertical axis of their parent row.

### Horizontal Alignment

Columns can be aligned the same way you would align text in a paragraph. By default, all columns align to the left (or the right in RTL), but this can be overridden with by adding the `.align-[dir]` class to the flex row.

<p>
  <a class="" data-open-video="13:32"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">

  <a class="codepen-logo-link" href="http://codepen.io/ZURBFoundation/pen/mmxpGz?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html
<div class="row">
  <div class="column small-4">Aligned to</div>
  <div class="column small-4">the left</div>
</div>
<div class="row align-right">
  <div class="column small-4">Aligned to</div>
  <div class="column small-4">the right</div>
</div>
<div class="row align-center">
  <div class="column small-4">Aligned to</div>
  <div class="column small-4">the middle</div>
</div>
<div class="row align-justify">
  <div class="column small-4">Aligned to</div>
  <div class="column small-4">the edges</div>
</div>
<div class="row align-spaced">
  <div class="column small-4">Aligned to</div>
  <div class="column small-4">the space around</div>
</div>
```

<div class="docs-code-live">
  <div class="text-center">
    <div class="row">
      <div class="column small-4">Aligned to</div>
      <div class="column small-4">the left</div>
    </div>
    <div class="row align-right">
      <div class="column small-4">Aligned to</div>
      <div class="column small-4">the right</div>
    </div>
    <div class="row align-center">
      <div class="column small-4">Aligned to</div>
      <div class="column small-4">the middle</div>
    </div>
    <div class="row align-justify">
      <div class="column small-4">Aligned to</div>
      <div class="column small-4">the edges</div>
    </div>
    <div class="row align-spaced">
      <div class="column small-4">Aligned to</div>
      <div class="column small-4">the space around</div>
    </div>
  </div>
</div>

You might be wondering what the difference between `.align-justify` and `.align-spaced` is. A justified grid (`justify-content: space-between`) evenly distributes the space *between* each column. The first and last columns pin to the edge of the grid.

A spaced grid (`justify-content: space-around`) evenly distributes the space *around* each column. This means there will always be space to the left of the first column, and to the right of the last column.

The horizontal alignment classes are shorthands for the `justify-content` CSS property. [Learn more about `justify-content`](https://developer.mozilla.org/en-US/docs/Web/CSS/justify-content).

---

### Vertical Alignment

By default, all columns in a flex grid stretch to be equal height. This behavior can be changed with another set of alignment classes. That's right, *middle alignment in CSS*!

Your options for vertical alignment are `top`, `middle`, `bottom`, and `stretch`. Note that we use the word *middle* for vertical alignment, and *center* for horizontal alignment.

Applying a vertical alignment class to the flex row will affect every column directly inside it.

<p>
  <a class="" data-open-video="13:32"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="http://codepen.io/ZURBFoundation/pen/BRrYQy?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<div class="row align-middle">
  <div class="columns">I'm in the middle!</div>
  <div class="columns">I am as well, but I have so much text I take up more space! Lorem ipsum dolor sit amet, consectetur adipisicing elit. Quis facere ducimus earum minus, inventore, ratione doloremque deserunt neque perspiciatis accusamus explicabo soluta, quod provident distinctio aliquam omnis? Labore, ullam possimus.</div>
</div>
```

```html_example
<div class="row align-top">
  <div class="columns">These columns align to the top.</div>
  <div class="columns">Lorem ipsum dolor sit amet, consectetur adipisicing elit. Voluptatum, tempora. Impedit eius officia possimus laudantium? Molestiae eaque, sapiente atque doloremque placeat! In sint, fugiat saepe sunt dolore tempore amet cupiditate.</div>
</div>
```

---

### Vertical Alignment of child columns (individually)

Similar alignment classes can also be applied to individual columns, which use the format `.align-self-*` instead of `.align-*`.

<a class="" data-open-video="13:32"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>

<div class="callout warning">
  <p>In Foundation 6.2, we introduced the <code>.align-self-&ast;</code> classes, which replace the old method of using <code>.align-&ast;</code> classes on columns. The old classes have been removed completely in Foundation 6.3.</p>
</div>


<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="http://codepen.io/ZURBFoundation/pen/pPLaPe?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<div class="row">
  <div class="column align-self-bottom">Align bottom</div>
  <div class="column align-self-middle">Align middle</div>
  <div class="column align-self-top">Align top</div>
  <div class="column">Lorem ipsum dolor sit amet, consectetur adipisicing elit. Non harum laborum cum voluptate vel, eius adipisci similique dignissimos nobis at excepturi incidunt fugit molestiae quaerat, consequuntur porro temporibus. Nisi, ex?</div>
</div>
```

---

## Collapse/Uncollapse Rows

The `.collapse` class lets you remove column gutters (padding).

There are times when you won't want each media query to be collapsed or uncollapsed. In this case, use the media query size you want and collapse or uncollapse and add that to your row element. Example shows no gutter at small media size and then adds the gutter to columns at medium.

The `.is-collapse-child` class removes negative margins from nested row under collapsed parent.

<div class="docs-codepen-container">
<a class="codepen-logo-link" href="http://codepen.io/ZURBFoundation/pen/pPLaWP?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html
<div class="row small-collapse medium-uncollapse">
  <div class="columns small-6">
    Removes gutter at small media query and adds at medium.
  </div>
  <div class="columns small-6">
    Removes gutter at small media query and adds at medium.
  </div>
</div>
```

<p class="lead">Scale the browser down to a medium size to see the difference.</p>

<div class="row medium-uncollapse large-collapse">
  <div class="columns small-6">
    <div class="callout secondary">
      <p class="show-for-small-only">On a small screen, I have gutters!</p>
      <p class="show-for-medium-only">On a medium screen, I have gutters!</p>
      <p class="show-for-large">On a large screen, I have no gutters!</p>
    </div>
  </div>
  <div class="columns small-6">
    <div class="callout secondary">
      <p class="show-for-small-only">On a small screen, I have gutters!</p>
      <p class="show-for-medium-only">On a medium screen, I have gutters!</p>
      <p class="show-for-large">On a large screen, I have no gutters!</p>
    </div>
  </div>
</div>

---

## Offsets

Offsets work identically to the float grid, by applying `margin-left` to a column.

<div class="docs-codepen-container">
<a class="codepen-logo-link" href="http://codepen.io/ZURBFoundation/pen/mmxXpb?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<div class="row">
  <div class="columns small-4 large-offset-2">Offset 2 on large</div>
  <div class="columns small-4">4 columns</div>
</div>
```

---

## Block Grids

To define column widths at the row-level, instead of the individual column level, add the class `.[size]-up-[n]` to a row, where `[n]` is the number of columns to display per row, and `[size]` is the breakpoint at which to apply the effect.

<a class="" data-open-video="27:19"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>

<div class="callout primary">
  <p>A block grid row has the property <code>align-items: stretch</code> by default, meaning the columns in each row are equal height. To change this, change the <code>align-items</code> property of the row, or use one of the <a href="flexbox.html#vertical-alignment">vertical alignment flexbox classes</a>.</p>
</div>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="http://codepen.io/ZURBFoundation/pen/PmRdOy?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<div class="row small-up-1 medium-up-2 large-up-3">
  <div class="column">1 per row on small</div>
  <div class="column">2 per row on medium</div>
  <div class="column">3 per row on large</div>
</div>
```
