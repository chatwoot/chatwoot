---
title: The Grid
description: Create powerful multi-device layouts quickly and easily with the default 12-column, nestable Foundation grid. If you're familiar with grid systems, you'll feel right at home. If not, you'll learn quickly.
video: k1zizfK2xbQ
sass:
  - scss/grid/*.scss
  - '!scss/grid/_flex-grid.scss'
tags:
  - block grid
---

<div class="callout training-callout">
  <p>Become a master of the Foundation Grids to create complex layouts faster and with less code. The new XY Grid is the newest and most powerful version. Stay up-to-date with all the new features in Foundation 6.4 and learn how to migrate to the XY Grid with our online webinar training. You’ll also learn all the useful UI components and Foundation JavaScript to really crush your projects.</p>
  <a href="http://zurb.com/university/foundation-intro" target="_blank">Get registered for an upcoming Foundation training →</a>
</div>


## Importing

<div class="callout alert">
  **From Foundation v6.4, the Float Grid is disabled by default**, replaced by the new [XY Grid](xy-grid.html). Unless you need to support IE 10, it is recommended to use the XY Grid.
</div>

To use the Float Grid in Foundation v6.4+, you need to:
* In CDN link or package managers: import `foundation-float.css` in place of `foundation.css`.
* In Sass: set both `$xy-grid` and `$global-flexbox` to `false`.


## Basics

Start by adding an element with a class of `.row`. This will create a horizontal block to contain vertical columns. Then add elements with a `.column` class within that row. Specify the widths of each column with the `.small-#`, `.medium-#`, and `.large-#` classes.

**Foundation is mobile-first.** Code for small screens first, and larger devices will inherit those styles. Customize for larger screens as necessary.

<p>
  <a class="" data-open-video="1:07"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="callout primary">
  <p>By default `.column` has an alias `.columns` (see the <a href="#sass-reference">`$grid-column-alias` option</a>) &mdash;the only difference is grammar.</p>
  <p>Disabling the alias can reduce the Foundation CSS file size from 3 to 5%. It is recommended if the alias is not used.</p>
</div>

<div class="docs-codepen-container">
<a class="codepen-logo-link" href="http://codepen.io/ZURBFoundation/pen/ZKrdZz?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html
<div class="row">
  <div class="columns small-2 large-4"><!-- ... --></div>
  <div class="columns small-4 large-4"><!-- ... --></div>
  <div class="columns small-6 large-4"><!-- ... --></div>
</div>
<div class="row">
  <div class="columns large-3"><!-- ... --></div>
  <div class="columns large-6"><!-- ... --></div>
  <div class="columns large-3"><!-- ... --></div>
</div>
<div class="row">
  <div class="columns small-6 large-2"><!-- ... --></div>
  <div class="columns small-6 large-8"><!-- ... --></div>
  <div class="columns small-12 large-2"><!-- ... --></div>
</div>
<div class="row">
  <div class="columns small-3"><!-- ... --></div>
  <div class="columns small-9"><!-- ... --></div>
</div>
<div class="row">
  <div class="columns large-4"><!-- ... --></div>
  <div class="columns large-8"><!-- ... --></div>
</div>
<div class="row">
  <div class="columns small-6 large-5"><!-- ... --></div>
  <div class="columns small-6 large-7"><!-- ... --></div>
</div>
<div class="row">
  <div class="columns large-6"><!-- ... --></div>
  <div class="columns large-6"><!-- ... --></div>
</div>
```

<div class="row display">
  <div class="columns small-2 large-4"><span class="hide-for-large">2</span><span class="show-for-large">4</span></div>
  <div class="columns small-4 large-4">4</div>
  <div class="columns small-6 large-4"><span class="hide-for-large">6</span><span class="show-for-large">4</span></div>
</div>
<div class="row display">
  <div class="columns large-3"><span class="hide-for-large">full</span><span class="show-for-large">3</span></div>
  <div class="columns large-6"><span class="hide-for-large">full</span><span class="show-for-large">6</span></div>
  <div class="columns large-3"><span class="hide-for-large">full</span><span class="show-for-large">3</span></div>
</div>
<div class="row display">
  <div class="columns small-6 large-2"><span class="hide-for-large">6</span><span class="show-for-large">2</span></div>
  <div class="columns small-6 large-8"><span class="hide-for-large">6</span><span class="show-for-large">8</span></div>
  <div class="columns small-12 large-2"><span class="hide-for-large">full</span><span class="show-for-large">2</span></div>
</div>
<div class="row display">
  <div class="columns small-3">3</div>
  <div class="columns small-9">9</div>
</div>
<div class="row display">
  <div class="columns large-4"><span class="hide-for-large">full</span><span class="show-for-large">4</span></div>
  <div class="columns large-8"><span class="hide-for-large">full</span><span class="show-for-large">8</span></div>
</div>
<div class="row display">
  <div class="columns small-6 large-5"><span class="hide-for-large">6</span><span class="show-for-large">5</span></div>
  <div class="columns small-6 large-7"><span class="hide-for-large">6</span><span class="show-for-large">7</span></div>
</div>
<div class="row display">
  <div class="columns large-6"><span class="hide-for-large">full</span><span class="show-for-large">6</span></div>
  <div class="columns large-6"><span class="hide-for-large">full</span><span class="show-for-large">6</span></div>
</div>

---

### Small Grids

Small grids expand to large screens easier than large grids cram into small screens.

<p>
<a class="" data-open-video="9:14"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
<a class="codepen-logo-link" href="http://codepen.io/ZURBFoundation/pen/oWEKXw?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html
<div class="row">
  <div class="columns small-2">2</div>
  <div class="columns small-10">10</div>
</div>
<div class="row">
  <div class="columns small-3">3</div>
  <div class="columns small-9">9</div>
</div>
```

<div class="row display">
  <div class="columns small-2">2</div>
  <div class="columns small-10">10</div>
</div>
<div class="row display">
  <div class="columns small-3">3</div>
  <div class="columns small-9">9</div>
</div>

---

### Medium Grid

Medium sized screens will inherit styles from small, unless you specify a different layout using the medium grid classes.

<p>
  <a class="" data-open-video="11:44"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="http://codepen.io/ZURBFoundation/pen/vmdoxj?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html
<div class="row">
  <div class="columns medium-2">2</div>
  <div class="columns medium-10">10</div>
</div>
<div class="row">
  <div class="columns medium-3">3</div>
  <div class="columns medium-9">9</div>
</div>
```

<div class="row display">
  <div class="columns medium-2">2</div>
  <div class="columns medium-10">10</div>
</div>
<div class="row display">
  <div class="columns medium-3">3</div>
  <div class="columns medium-9">9</div>
</div>

---

## Advanced

### Combined Column/Row

If you have just a single column, you can save some markup by combining the `.row` and `.column` classes together on the same element. You can still nest more grids inside this container like usual.

<div class="callout warning">
  <p>Column rows can use sizing classes like <code>.small-8</code>, but only when used as a top-level container&mdash;not when nested inside another row.</p>
</div>

<div class="docs-codepen-container">
<a class="codepen-logo-link" href="http://codepen.io/ZURBFoundation/pen/ZKrgop?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html
<div class="column row">
  Row column
</div>
```

<div class="column row display">
  Row column
</div>

---

### Fluid Row

Normally, a row is always 1200 pixels wide. Make a row completely fluid by adding the `.expanded` class.

<p>
  <a class="" data-open-video="14:51"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="http://codepen.io/ZURBFoundation/pen/rmJXZy?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html
<div class="expanded row">
</div>
```

---

### Nesting

You can nest the grids indefinitely, though at a certain point it will get absurd.

<p>
  <a class="" data-open-video="26:29"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="http://codepen.io/ZURBFoundation/pen/zwRgbE?editors=1100" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html
<div class="row">
  <div class="columns small-8">8
    <div class="row">
      <div class="columns small-8">8 Nested
        <div class="row">
          <div class="columns small-8">8 Nested Again</div>
          <div class="columns small-4">4</div>
        </div>
      </div>
      <div class="columns small-4">4</div>
    </div>
  </div>
  <div class="columns small-4">4</div>
</div>
```

<div class="row display">
  <div class="columns small-8">8
    <div class="row">
      <div class="columns small-8">8 Nested
        <div class="row">
          <div class="columns small-8">8 Nested Again</div>
          <div class="columns small-4">4</div>
        </div>
      </div>
      <div class="columns small-4">4</div>
    </div>
  </div>
  <div class="columns small-4">4</div>
</div>

---

### Offsets

Move blocks up to 11 columns to the right by using classes like `.large-offset-1` and `.small-offset-3`.

<p>
  <a class="" data-open-video="16:12"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs--codepen-container">
  <a class="codepen-logo-link" href="http://codepen.io/ZURBFoundation/pen/YVaKyg?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html
<div class="row">
  <div class="columns large-1">1</div>
  <div class="columns large-11">11</div>
</div>
<div class="row">
  <div class="columns large-1">1</div>
  <div class="columns large-10 large-offset-1">10, offset 1</div>
</div>
<div class="row">
  <div class="columns large-1">1</div>
  <div class="columns large-9 large-offset-2">9, offset 2</div>
</div>
<div class="row">
  <div class="columns large-1">1</div>
  <div class="columns large-8 large-offset-3">8, offset 3</div>
</div>
```

<div class="row display">
  <div class="columns large-1">1</div>
  <div class="columns large-11">11</div>
</div>
<div class="row display">
  <div class="columns large-1">1</div>
  <div class="columns large-10 large-offset-1">10, offset 1</div>
</div>
<div class="row display">
  <div class="columns large-1">1</div>
  <div class="columns large-9 large-offset-2">9, offset 2</div>
</div>
<div class="row display">
  <div class="columns large-1">1</div>
  <div class="columns large-8 large-offset-3">8, offset 3</div>
</div>

---

### Incomplete Rows

In order to work around browsers' different rounding behaviors, Foundation will float the last column in a row to the right so the edge aligns. If your row doesn't have a count that adds up to 12 columns, you can tag the last column with a class of `.end` in order to override that behavior. Alternatively, you can set the `$grid-column-align-edge` variable to `false` to turn off this behavior entirely.

<div class="docs-codepen-container">
<a class="codepen-logo-link" href="http://codepen.io/ZURBFoundation/pen/dWmbpa?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html
<div class="row">
  <div class="columns medium-3">3</div>
  <div class="columns medium-3">3</div>
  <div class="columns medium-3">3</div>
</div>
<div class="row">
  <div class="columns medium-3">3</div>
  <div class="columns medium-3">3</div>
  <div class="columns medium-3 end">3 end</div>
</div>
```

<div class="row display-end">
  <div class="columns medium-3">3</div>
  <div class="columns medium-3">3</div>
  <div class="columns medium-3">3</div>
</div>
<div class="row display-end">
  <div class="columns medium-3">3</div>
  <div class="columns medium-3">3</div>
  <div class="columns medium-3 end">3 end</div>
</div>

---

### Gutters

#### Responsive Gutters

The grid *gutter*&mdash;the space between two columns in a row, and the space between the edge of a grid and the edge of the page&mdash;is responsive, and becomes wider on larger screens.

Breakpoint | Gutter Size
-----------|------------
`small`    | 20px
`medium`   | 30px

If you're using the Sass version of Foundation, you can change these defaults by editing the `$grid-column-gutter` variable map:

```scss
$grid-column-gutter: (
  small: 20px,
  medium: 30px,
);
```

To add more gutter definitions, add new lines to the map. The breakpoint names used here must match a breakpoint name in your project's `$breakpoints` map.

#### Static Gutters

If you prefer using one gutter size for every breakpoint, just use a single number for the `$grid-column-gutter` variable:

```scss
$grid-column-gutter: 30px;
```

You can also explicitly set the gutter size for a particular grid row by adding the `.gutter-[size]` class. This is useful when your using responsive gutters but specific components need static gutters.

```html
<div class="row gutter-small">
  <div class="columns">This grid always has small gutters</div>
</div>
```

---

### Collapse/Uncollapse Rows

The `.collapse` class lets you remove column gutters (padding).

There are times when you won't want each media query to be collapsed or uncollapsed. In this case, use the media query size you want and collapse or uncollapse and add that to your row element. Example shows no gutter at small media size and then adds the gutter to columns at medium.

<div class="docs-codepen-container">
<a class="codepen-logo-link" href="http://codepen.io/ZURBFoundation/pen/xdWKqa?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html
<div class="row medium-uncollapse large-collapse">
  <div class="columns small-6">
    Removes gutter at large media query
  </div>
  <div class="columns small-6">
    Removes gutter at large media query
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

### Centered Columns

Center your columns by adding a class of `.small-centered` to your column. Large will inherit small centering by default, but you can also center solely on large by applying a `.large-centered` class. To uncenter on large screens, use `.large-uncentered`.

<p>
  <a class="" data-open-video="23:16"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="http://codepen.io/ZURBFoundation/pen/zwWOpL?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html
<div class="row">
  <div class="columns small-3 small-centered">3 centered</div>
</div>
<div class="row">
  <div class="columns small-6 large-centered">6 centered</div>
</div>
<div class="row">
  <div class="columns small-9 small-centered large-uncentered">9 centered</div>
</div>
<div class="row">
  <div class="columns small-11 small-centered">11 centered</div>
</div>
```

<div class="row display">
  <div class="columns small-3 small-centered">3 centered</div>
</div>
<div class="row display">
  <div class="columns small-6 large-centered">6 centered, large</div>
</div>
<div class="row display">
  <div class="columns small-9 small-centered large-uncentered">9 centered small</div>
</div>
<div class="row display">
  <div class="columns small-11 small-centered">11 centered</div>
</div>

---

### Source Ordering

Using these source ordering classes, you can shift columns around between our breakpoints. This means if you place sub-navigation below main content on small displays, you have the option to position the sub-navigation on either the left or right of the page for large displays. Prefix push/pull with the size of the device you want to apply the styles to. `.medium-push-#`, `.large-push-#` is the syntax you'll use. Use the number 0 instead to reset a push/pull, such as `.medium-push-0` or `.large-pull-0`.

<p>
  <a class="" data-open-video="19:28"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="http://codepen.io/ZURBFoundation/pen/QvmLmv?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html
<div class="row">
  <div class="columns small-10 small-push-2">10</div>
  <div class="columns small-2 small-pull-10">2, last</div>
</div>
<div class="row">
  <div class="columns large-9 large-push-3">9</div>
  <div class="columns large-3 large-pull-9">3, last</div>
</div>
<div class="row">
  <div class="columns large-8 large-push-4">8</div>
  <div class="columns large-4 large-pull-8">4, last</div>
</div>
<div class="row">
  <div class="columns small-5 small-push-7 medium-7 medium-push-5">7</div>
  <div class="columns small-7 small-pull-5 medium-5 medium-pull-7">5, last</div>
</div>
<div class="row">
  <div class="columns medium-6 medium-push-6">6</div>
  <div class="columns medium-6 medium-pull-6">6, last</div>
</div>
```

<div class="row display">
  <div class="columns small-10 small-push-2">10</div>
  <div class="columns small-2 small-pull-10">2, last</div>
</div>
<div class="row display">
  <div class="columns large-9 large-push-3">9</div>
  <div class="columns large-3 large-pull-9">3, last</div>
</div>
<div class="row display">
  <div class="columns large-8 large-push-4">8</div>
  <div class="columns large-4 large-pull-8">4, last</div>
</div>
<div class="row display">
  <div class="columns small-5 small-push-7 medium-7 medium-push-5">7</div>
  <div class="columns small-7 small-pull-5 medium-5 medium-pull-7">5, last</div>
</div>
<div class="row display">
  <div class="columns medium-6 medium-push-6">6</div>
  <div class="columns medium-6 medium-pull-6">6, last</div>
</div>

---

### Block Grids

Block grids are a shorthand way to create equally-sized columns. Add a class of the format `.[size]-up-[n]` to change the number of columns within the row. By default, the max number of columns you can use with block grid are 8. Adding the `.column-block` class to columns will apply a bottom margin equal to the width of gutters.

<p>
  <a class="" data-open-video="30:07"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="http://codepen.io/ZURBFoundation/pen/eWMOjK?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<div class="row small-up-2 medium-up-3 large-up-4">
  <div class="column column-block">
    <img src="https://placehold.it/600x600" class="thumbnail" alt="">
  </div>
  <div class="column column-block">
    <img src="https://placehold.it/600x600" class="thumbnail" alt="">
  </div>
  <div class="column column-block">
    <img src="https://placehold.it/600x600" class="thumbnail" alt="">
  </div>
  <div class="column column-block">
    <img src="https://placehold.it/600x600" class="thumbnail" alt="">
  </div>
  <div class="column column-block">
    <img src="https://placehold.it/600x600" class="thumbnail" alt="">
  </div>
  <div class="column column-block">
    <img src="https://placehold.it/600x600" class="thumbnail" alt="">
  </div>
</div>
```

---

## Building Semantically

Our grid CSS is generated with a powerful set of Sass mixins, which you can use in your own code to build a semantic grid.

### Rows

Use the `grid-row()` mixin to create a row.

```scss
.container {
  @include grid-row;
}
```

---

### Columns

Use the `grid-column()` mixin to create a column. There are a number of ways to define the width of the column.

```scss
.main-content {
  // Use the full column count (100%)
  @include grid-column;

  // Use a column count (33%);
  @include grid-column(4);

  // Use a percentage (15%)
  @include grid-column(15%);

  // Use a custom fraction (20%)
  @include grid-column(1 of 5);
}
```

The grid column calculator can also be accessed as a function. This gives you the percentage value, without any of the grid column CSS.

```scss
.main-content {
  width: grid-column(1 of 7);
}
```

To center a column semantically. Use ´grid-column-position(center);´.

```scss
.centered-column {
  @include grid-column-position(center);
}
```

---

### Multiple Grids

By default, all grids use the number of columns set by the `$grid-column-count` variable. However, this can be selectively overridden within an instance of a row.

In this example, the grid is 16 columns instead of the normal 12. Any references to column math inside the mixin will use the new column count.

```scss
.container {
  @include grid-row(16) {
    .main-content {
      // 11/16 = 68.75%
      @include grid-column(11);
    }

    .sidebar {
      // 5/16 = 31.25%
      @include grid-column(5);
    }
  }
}
```

You can also temporarily change the grid context without outputting any row CSS, by using the `grid-context()` mixin.

```scss
@include grid-context(7) {
  .sidebar {
    @include grid-column(4);
  }
}
```

Every other grid feature, from sizing to offsets to source ordering, can also be accessed with a mixin. Pair them with the `breakpoint()` mixin to make your grid responsive.

Refer to the Sass documentation below to learn how each mixin works.

```scss
.main-content {
  // The mixins have shorthands, too!
  @include grid-col;

  @include breakpoint(medium) {
    // Changes size only
    @include grid-col-size(8);

    // Changes position only
    @include grid-col-pos(4);
  }
}
```

### Custom Block Grid

Use the `grid-layout()` mixin to create your own block grid.
By default the mixin takes 3 parameters:
- Number of columns
- The child element selector
  - An optional padding value

The padding value can be set to `$grid-column-gutter` to use the values from that map.
This will then generate different paddings at different breakpoints. Alternatively supply a numeric value (without a unit type) to output a static rem value.

Here's an example:

```scss
.gallery {
  @include grid-layout(3, '.gallery-item', $grid-column-gutter);
}
```
That outputs this CSS:

```
.gallery > .gallery-item {
  width: 33.33333%;
  float: left;
  padding-left: 0.625rem;
  padding-right: 0.625rem;
}

@media screen and (min-width: 40em) {
  .gallery > .gallery-item {
    padding-left: 0.9375rem;
    padding-right: 0.9375rem;
  }
}

.gallery > .gallery-item:nth-of-type(1n) {
  clear: none;
}

.gallery > .gallery-item:nth-of-type(3n+1) {
  clear: both;
}

.gallery > .gallery-item:last-child {
  float: left;
}
```

---
