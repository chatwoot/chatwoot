---
title: Off-canvas
description: Off-canvas panels are positioned outside of the viewport and slide in when activated. Setting up an off-canvas layout in Foundation is super easy.
video: 'RK_k__4Y4TU'
sass:
  - scss/components/_off-canvas.scss
  - scss/components/_title-bar.scss
js: js/foundation.offcanvas.js
tags:
  - navigation
  - offcanvas
  - off-canvas
  - nav
  - title bar
flex: true
---

<div class="callout training-callout">
  <p>Off-canvas layouts are common and useful for mobile and desktop layouts. Be a navigation guru with our Foundation online webinar training. You’ll learn techniques for creating responsive navigations that work with any type of site. In addition to that you can learn tips and tricks and best practices for all of Foundation’s components.</p>
  <a href="http://zurb.com/university/foundation-intro" target="_blank">Find out more about Foundation training classes →</a>
</div>

<div class="primary callout">
  <p>Good news! We've updated Off-canvas to offer more and better functionality. Another bonus is the markup is simplified. This new version applies to version 6.3+. We work hard to avoid breaking changes, so any markup updates are listed in the <a href="#migrating-from-versions-prior-to-v6-3">migration section</a> of this page.</p>
</div>

<button class="button" type="button" data-toggle="offCanvasLeft">Toggle Off-canvas</button>

Foundation's Off-canvas is a well established mobile pattern for navigation that can also be used to create a responsive sidebar. It can open from any direction, left, right, top, and bottom. There are options to allow the Off-canvas to push your page over or to overlap your page plus a few other neat tricks.

## Setup

Setting up the Off-canvas only requires two elements! To setup the Off-canvas create an off-canvas container with the class `.off-canvas` and the attribute `data-off-canvas`. This is the container that holds your Off-canvas content.

The Off-canvas container also needs a positioning class to determine which side of the viewport it opens from:

- `.position-left`
- `.position-right`
- `.position-top`
- `.position-bottom`

<p>
  <a class="" data-open-video="2:00"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

Also be sure the off-canvas panel has a unique ID so it can be targeted by the click trigger.

Example:

```html
<div class="off-canvas position-left" id="offCanvas" data-off-canvas>
  <!-- Your menu or Off-canvas content goes here -->
</div>
```

Along with the Off-canvas container, the main content of your page will be housed in its own container with the class `.off-canvas-content` and attribute `data-off-canvas-content`. This is where your page content lives.

```html
<div class="off-canvas-content" data-off-canvas-content>
  <!-- Your page content lives here -->
</div>
```

So putting it all together:

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="http://codepen.io/ZURBFoundation/pen/ZKjXvQ?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html
<body>
  <div class="off-canvas position-left" id="offCanvas" data-off-canvas>
    <!-- Your menu or Off-canvas content goes here -->
  </div>
  <div class="off-canvas-content" data-off-canvas-content>
    <!-- Your page content lives here -->
  </div>
</body>
```

### Wrapper

You can add an optional wrapper around off-canvas and the content. This hides the vertical (on top/bottom off-canvas) or horizontal (on left/right off-canvas) scrollbars the body will have.
Simply add a container with the class `.off-canvas-wrapper`.

```html
<body>
  <div class="off-canvas-wrapper">
    <div class="off-canvas position-left" id="offCanvas" data-off-canvas>
      <!-- Your menu or Off-canvas content goes here -->
    </div>
    <div class="off-canvas-content" data-off-canvas-content>
      <!-- Your page content lives here -->
    </div>
  </div>
</body>
```

### Click Triggers

To create a click trigger that opens the panel, add the attribute `data-open` or `data-toggle` to any element. That element will then open or toggle the panel when clicked on. The value of the data attribute should be the ID of the off-canvas.

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="http://codepen.io/ZURBFoundation/pen/ZKjXvQ?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<button type="button" class="button" data-toggle="offCanvas">Open Menu</button>
```

### Close Button

Foundation's Close component can be used inside the off-canvas to close it.

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="http://codepen.io/ZURBFoundation/pen/QvBQjo?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html
<button class="close-button" aria-label="Close menu" type="button" data-close>
  <span aria-hidden="true">&times;</span>
</button>
```

### Complete Example

Here's a complete example that can be pasted into the `<body>` tag of your page. It includes a close button and basic menu styles.

```html
<body>
  <div class="off-canvas position-left" id="offCanvas" data-off-canvas>

    <!-- Close button -->
    <button class="close-button" aria-label="Close menu" type="button" data-close>
      <span aria-hidden="true">&times;</span>
    </button>

    <!-- Menu -->
    <ul class="vertical menu">
      <li><a href="#">Foundation</a></li>
      <li><a href="#">Dot</a></li>
      <li><a href="#">ZURB</a></li>
      <li><a href="#">Com</a></li>
      <li><a href="#">Slash</a></li>
      <li><a href="#">Sites</a></li>
    </ul>

  </div>

  <div class="off-canvas-content" data-off-canvas-content>
    <!-- Your page content lives here -->
  </div>
</body>
```
---

## Off-canvas Position

Foundation's Off-canvas is set to `position: fixed` by default using the `.off-canvas` class. This makes the off-canvas panel sit in relation to the viewport, and is the desired behavior for most users. However you can also set an off-canvas container to `position: absolute` by using the alternative class `.off-canvas-absolute`. Also be sure to use the `.off-canvas-wrapper` when using this method.

```html_example
<button type="button" class="button" data-toggle="offCanvasLeftSplit1">Open Left</button>
<button type="button" class="button" data-toggle="offCanvasRightSplit2">Open Right</button>

<div class="grid-x grid-margin-x">
  <div class="cell small-6">
    <div class="off-canvas-wrapper">
      <div class="off-canvas-absolute position-left" id="offCanvasLeftSplit1" data-off-canvas>
        <!-- Your menu or Off-canvas content goes here -->
      </div>
      <div class="off-canvas-content" style="min-height: 300px;" data-off-canvas-content>
        <p>I have nothing to do with the off-canvas on the right!</p>
      </div>
    </div>
  </div>
  <div class="cell small-6">
    <div class="off-canvas-wrapper">
      <div class="off-canvas-absolute position-right" id="offCanvasRightSplit2" data-off-canvas>
        <!-- Your menu or Off-canvas content goes here -->
      </div>
      <div class="off-canvas-content" style="min-height: 300px;" data-off-canvas-content>
        <p>Im a unique off-canvas container all on my own!</p>
      </div>
    </div>
  </div>
</div>
```

---

## Off-canvas Directions

Foundation's Off-canvas can open from any direction, left, right, top, and bottom.

The Off-canvas container requires a positioning class to determine which side of the viewport it opens from:

- `.position-left`
- `.position-right`
- `.position-top`
- `.position-bottom`

```html_example
<button type="button" class="button" data-toggle="offCanvasLeft1">Open Left</button>
<button type="button" class="button" data-toggle="offCanvasRight1">Open Right</button>
<button type="button" class="button" data-toggle="offCanvasTop1">Open Top</button>
<button type="button" class="button" data-toggle="offCanvasBottom1">Open Bottom</button>

<div class="cell">
  <div class="off-canvas-wrapper">
    <div class="off-canvas position-left" id="offCanvasLeft1" data-off-canvas>
      <!-- Your menu or Off-canvas content goes here -->
    </div>
    <div class="off-canvas position-right" id="offCanvasRight1" data-off-canvas>
      <!-- Your menu or Off-canvas content goes here -->
    </div>
    <div class="off-canvas position-top" id="offCanvasTop1" data-off-canvas>
      <!-- Your menu or Off-canvas content goes here -->
    </div>
    <div class="off-canvas position-bottom" id="offCanvasBottom1" data-off-canvas>
      <!-- Your menu or Off-canvas content goes here -->
    </div>
    <div class="off-canvas-content" data-off-canvas-content>
      <img src="http://placehold.it/300x300" class="" height="" width="" alt="">
    </div>
  </div>
</div>
```

---

## Multiple Panels

A design can have multiple panels. Be sure that all panels come *before* the `.off-canvas-content` wrapper&mdash;this is required for the CSS to apply correctly.

<div class="primary callout">
  <p>When using Foundation in <a href="rtl.html">right-to-left</a> mode, "right" still means right, and "left" still means left.</p>
</div>

```html
<body>
  <div class="off-canvas position-left" id="offCanvasLeft" data-off-canvas></div>
  <div class="off-canvas position-right" id="offCanvasRight" data-off-canvas></div>
  <div class="off-canvas-content" data-off-canvas-content></div>
</body>
```

<button class="button" type="button" data-toggle="offCanvasLeft">Open Left Menu</button>
<button class="button" type="button" data-toggle="offCanvasRight">Open Right Menu</button>

---

## Off-canvas Transitions

You can switch the default transition of the off-canvas from pushing the page over as it open to overlapping the page by adding the `data-transition="overlap"` to the `.off-canvas`.
There are 2 available transitions: push (`data-transition="push"`) which is the default, and overlap (`data-transition="overlap"`).

<div class="primary callout">
  <p>When placing the off-canvas within the off-canvas-content container as <a href="#nested-off-canvas">Nested Off-Canvas</a>, only overlap transition is possible. If you've explicitely defined push transition it will be replaced with overlap automatically.</p>
</div>

```html
<div class="off-canvas position-left" id="offCanvasLeftOverlap" data-off-canvas data-transition="overlap">
  <!-- Your menu or Off-canvas content goes here -->
</div>
<div class="off-canvas position-right" id="offCanvasRightPush" data-off-canvas data-transition="push">
  <!-- Your menu or Off-canvas content goes here -->
</div>
```

<button type="button" class="button" data-toggle="offCanvasOverlap">Open Left with Overlap</button>
<button class="button" type="button" data-toggle="offCanvasRight">Open Right with Push</button>

<div class="off-canvas position-left is-closed" id="offCanvasOverlap" data-off-canvas data-transition="overlap">
  <ul class="vertical menu">
    <li><a href="#">Foundation</a></li>
    <li><a href="#">Dot</a></li>
    <li><a href="#">ZURB</a></li>
    <li><a href="#">Com</a></li>
    <li><a href="#">Slash</a></li>
    <li><a href="#">Sites</a></li>
  </ul>
</div>

---

## Reveal on Larger Screens

The left- and right-hand off-canvas panes can be set to be persistent on larger screens like a sidebar. Add the class `.reveal-for-medium` or `.reveal-for-large` to the off-canvas menu. These classes determine what breakpoint the off-canvas will default open.

The main content area (`.off-canvas-content`) will be padded to the left or right equal to the width of the container.

<div class="callout">
  <p>The menu will be fixed-position by default, meaning it follows you as you scroll up and down. The menu also gets its own scroll bar if it's taller than the window. To disable these features, set the <code>$offcanvas-fixed-reveal</code> variable to <code>false</code>.</p>
</div>

<div class="warning callout">
  <p>The slide in/out of the plugin still works when these classes are active. If you use this feature on a larger screen, be sure to hide any click triggers on those larger breakpoints as well. Foundation's <a href="visibility.html">visibility classes</a> can help you with that.</p>
</div>

```html
<div class="off-canvas position-left reveal-for-large" data-off-canvas>
  <!-- ... -->
</div>
```

<button type="button" class="button" data-docs-example-ofc>Toggle Reveal Class</button>

---

## Combining with Title Bar

If you need a simple bar to contain your hamburger icon/s and toggle the off-canvas, `.title-bar` is here to help. It supports left- and right-aligned sections. You can add your off-canvas toggle triggers here:

```html_example
<div class="title-bar">
  <div class="title-bar-left">
    <button class="menu-icon" type="button" data-open="offCanvasLeft"></button>
    <span class="title-bar-title">Foundation</span>
  </div>
  <div class="title-bar-right">
    <button class="menu-icon" type="button" data-open="offCanvasRight"></button>
  </div>
</div>
```
<br>

<div class="primary callout">
  <p>When using the `title-bar` with a vertical off-canvas, the title-bar icons are still either `title-bar-left` or `title-bar-right`.</p>
</div>

```html_example
<div class="title-bar">
  <div class="title-bar-left">
    <button class="menu-icon" type="button" data-open="offCanvasTop"></button>
    <span class="title-bar-title">Foundation title bar with top off-canvas</span>
  </div>
  <div class="title-bar-right">
    <button class="menu-icon" type="button" data-open="offCanvasTop"></button>
  </div>
</div>
```

---

#### Off-Canvas (Putting it all together)

For an example of off-canvas, checkout this top bar with off-canvas navigation and dropdowns for submenus building block: http://foundation.zurb.com/building-blocks/blocks/multilevel-offcanvas-menu.html

---

## In-Canvas to Off-Canvas

With this feature you can have a standard page element move off-canvas at a particular breakpoint. Use the new class <code>.in-canvas-for-[BREAKPOINT]</code> for this. This differs from the <a href="#reveal-on-larger-screens">Reveal on Larger Screens</a> feature it doesn't actually open the off-canvas for specific screen sizes but overrides the off-canvas styles so it behaves as a regular page element. This way you can place an element anywhere on the page and move it into off-canvas for e.g. small screens.

```html_example
<button type="button" class="button hide-for-large" data-toggle="inCanvasExample">
  Open in-canvas that is off-canvas now
</button>
<div class="off-canvas in-canvas-for-large position-right" id="inCanvasExample" data-off-canvas>
  <div class="callout">I'm in-canvas for medium screen size and move off-canvas for medium down.</div>
</div>
```

---

## Nested Off-Canvas

In v6.4 the off-canvas component has been heavily extended. Apart from the <a href="#in-canvas">In-Canvas</a> feature it is now possible to nest the element in the content instead of using it only as a sibling. This is handy if you want to use the same element e.g. for small screens as off-canvas and for large screens as usual page element without duplicate content.

Another improvement is the support of several off-canvas elements that share the same position e.g. two elements with `position-left`.

Advanced off-canvas users may use the new `contentId` option to bind an element to a content. This lets you place the element much more flexibly as it may be a sibling of the content, a child or none of it.<br>
<strong>Important:</strong> when using the `contentId` on a nested element you must also use the new `nested` option and tell the JavaScript it's nested!

<div class="callout warning">
  <p>Please note that it's not possible to use the push transition for a nested off-canvas element.</p>
</div>

```html_example
<button type="button" class="button" data-toggle="offCanvasNestedPush">
  Open Nested Off-Canvas Push
</button>
<button type="button" class="button" data-toggle="offCanvasNestedOverlap">
  Open Nested Off-Canvas Overlap
</button>

<p>Lorem ipsum dolor sit amet, consectetur adipisicing elit.</p>

<div class="off-canvas position-left is-closed" id="offCanvasNestedPush" data-off-canvas>
  <div class="callout">
    <p>I'm a nested off-canvas that mustn't be a sibling of the off-canvas content anymore.</p>
    <p>Since push transition is currently not possible for nested elements, I'm forced to use overlayp transition.</p>
  </div>
</div>
<div class="off-canvas position-left is-closed" data-transition="overlap" id="offCanvasNestedOverlap" data-off-canvas>
  <div class="callout">I'm a nested off-canvas that uses overlap transition and the same position as the other nested off-canvas.</div>
</div>

<p>Enim, repudiandae officia dolores temporibus soluta, ipsa saepe tempora ipsum laudantium in mollitia quidem, nisi magni provident hic architecto rem culpa beatae.</p>
```

---

## Off-canvas Sizes

In v6.4.2 the type of the off-canvas size variables has changed from number to map. This lets you define breakpoint specific sizes instead of one value for all.
The map may contain every key that is defined in `$breakpoint-classes`.

<div class="warning callout">
  Please note the sizes maps do currently not work perfectly for the reveal classes. If sizes are defined for medium and large, `.reveal-for-medium` will only consider the medium value. This is going to get fixed in a future release.
</div>

```scss
$offcanvas-sizes: (
  small: 250px,
  medium: 350px,
);
$offcanvas-vertical-sizes: (
  small: 250px,
  medium: 350px,
);
```

---

## Migrating from versions prior to v6.4

If you're upgrading from v6.3 there's nothing to do unless you haven't changed the default value of `$offcanvas-shadow`. Prior to v6.4 this variable was used for both, overlap and push off-canvas elements. Now it's only used for the overlap element whereas the push element uses two new variables:

- `$offcanvas-inner-shadow-size` which is a number (mostly px)
- `$offcanvas-inner-shadow-color` which is a color (mostly rgba)

So if you have changed the default off-canvas shadow you have to adjust the value of these variables in your settings.

---

## Migrating from versions prior to v6.3

<div class="primary callout">
  <p>`off-canvas-wrapper` and `off-canvas-wrapper-inner` are no longer needed on the new off-canvas. If you leave them in with 6.3+ off-canvas will work as expected.</p>
</div>

The default off-canvas position has changed from absolute to fixed. This will likely be the position you want since the menu is in view when opened regardless of the scroll position. You can choose the off-canvas position back to absolute using the built in classes:

- `.is-overlay-absolute`
- `.is-overlay-fixed`

Or in globally in the _settings.scss, set the <code>$offcanvas-fixed-reveal</code> variable to <code>false</code>.</p>

```html
<div class="off-canvas position-left reveal-for-large" data-off-canvas>
  <!-- ... -->
</div>
```

### Pre 6.3 Off-canvas Setup

To start, create two wrappers to house the page. These are necessary to prevent the off-canvas panels from being visible when they're not open. They also smooth out cross-browser bugs.
- The outer wrapper has the class `.off-canvas-wrapper`.
- The inner wrapper has the class `.off-canvas-wrapper-inner` and the attribute `data-off-canvas-wrapper`.

```html
<body>
  <div class="off-canvas-wrapper">
    <div class="off-canvas-wrapper-inner" data-off-canvas-wrapper></div>
  </div>
</body>
```

Inside these wrappers, create an off-canvas panel with the class `.off-canvas` and the attribute `data-off-canvas`. The panel also needs a positioning class, which can be `.position-left` or `.position-right`, and an attribute set for the position, `data-position="left"` or `data-position="right"`. Last, make sure the off-canvas panel has a unique ID so it can be targeted.

Along with the panel, the main content of your page will be housed in its own container with the class `.off-canvas-content` and attribute `data-off-canvas-content`. You will be putting your actual page content inside a class of `.off-canvas-content`.)

```html
<body>
  <div class="off-canvas-wrapper">
    <div class="off-canvas-wrapper-inner" data-off-canvas-wrapper>
      <div class="off-canvas position-left" id="offCanvas" data-off-canvas></div>
      <div class="off-canvas-content" data-off-canvas-content></div>
    </div>
  </div>
</body>
```
