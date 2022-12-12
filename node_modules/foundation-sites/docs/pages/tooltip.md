---
title: Tooltip
description: Tooltips? More like <em>Cooltips</em>. But really though, tooltips are nifty for displaying extended information for a term or action on a page.
video: 'PJMYScItyP4'
sass: scss/components/_tooltip.scss
js: js/foundation.tooltip.js
---


## Basic Tooltip
By default, a tooltip appears below the defined term on hover.

<p>
  <a class="" data-open-video="0:49"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="http://codepen.io/ZURBFoundation/pen/zwLxaY?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
The <span data-tooltip tabindex="1" title="Fancy word for a beetle.">scarabaeus</span> hung quite
clear of any branches, and, if allowed to fall, would have fallen at our feet.
```

---

## Tooltip Top
To get a tip-top top tooltip (lol), just add the class `.top` to the `<span>` element.

<p>
  <a class="" data-open-video="3:00"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="http://codepen.io/ZURBFoundation/pen/BRPyqx?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
The <span data-tooltip class="top" tabindex="2" title="Fancy word for a beetle.">scarabaeus</span>
hung quite clear of any branches, and, if allowed to fall, would have fallen at our feet.
```

---

## Tooltip clicking

By default, clicking on a tooltip will leave it open until you click somewhere else.  However, you can disable that by adding `data-click-open="false"`

<p>
  <a class="" data-open-video="4:12"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="http://codepen.io/ZURBFoundation/pen/XRBJvm?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
this
<span data-tooltip class="top" tabindex="2" title="You see?  I'm open!">
  tooltip will stay open
</span>
while
<span data-tooltip class="top" data-click-open="false" tabindex="2" title="I don't stay open">
  this one will only be open when hovered
</span>
```

---

## Tooltip Right and Left

You can also position the tooltips to the right and left of the word by adding the classes `.right` or `.left` to the `<span>` element.

<p>
  <a class="" data-open-video="3:00"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="primary callout">
  <p>When using Foundation in <a href="rtl.html">right-to-left</a> mode, "right" still means right, and "left" still means left.</p>
</div>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="http://codepen.io/ZURBFoundation/pen/EmpaJP?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
When he was dressed he went down the hall into the
<span data-tooltip class="right" tabindex="3" title="Aligned on the right">kitchen</span>.
The table was almost hidden beneath all Dudley's birthday presents. It looked as though
<span data-tooltip class="left" tabindex="4" title="Aligned on the left">Dudley</span>
had gotten the new computer he wanted, not to mention the second television and the racing bike.
```

---

## Explicit Positioning

<div class="callout primary">
  <p><strong>New in v6.4:</strong> Heads up! This explicit positioning model is a new feature in v6.4.</p>
</div>

Now with tooltips you can define both positions for the tip. These tooltips have a fully explicit positioning model through which you can use both `data-position` and `data-alignment` to define both positions of the box.

These dropdowns sets various positioning and alignments. Valid positions are left/right/top/bottom. Valid alignments are left/right/top/bottom/center. Left align means left sides should line up. Right align means right sides should line up. Center align means centers should line up.

#### Top and Bottom positioned

```html
<button class="button" type="button" data-tooltip tabindex="1" title="Fancy word for a beetle." data-position="bottom" data-alignment="left">
  Bottom Left
</button>

<button class="button" type="button"  data-tooltip tabindex="1" title="Fancy word for a beetle." data-position="bottom" data-alignment="center">
  Bottom Center
</button>

<button class="button" type="button" data-tooltip tabindex="1" title="Fancy word for a beetle." data-position="bottom" data-alignment="right">
  Bottom Right
</button>

<button class="button" type="button" data-tooltip tabindex="1" title="Fancy word for a beetle." data-position="top" data-alignment="left">
  Top Left
</button>

<button class="button" type="button" data-tooltip tabindex="1" title="Fancy word for a beetle." data-position="top" data-alignment="center">
  Top Center
</button>

<button class="button" type="button" data-tooltip tabindex="1" title="Fancy word for a beetle." data-position="top" data-alignment="right">
  Top Right
</button>
```

<div class="grid-x grid-margin-x small-up-1 medium-up-3">
  <div class="cell">
    <button class="button" type="button" data-tooltip tabindex="1" title="Fancy word for a beetle." data-position="bottom" data-alignment="left">
      Bottom Left
    </button>
  </div>

  <div class="cell">
    <button class="button" type="button"  data-tooltip tabindex="1" title="Fancy word for a beetle." data-position="bottom" data-alignment="center">
      Bottom Center
    </button>
  </div>

  <div class="cell">
    <button class="button" type="button" data-tooltip tabindex="1" title="Fancy word for a beetle." data-position="bottom" data-alignment="right">
      Bottom Right
    </button>
  </div>

  <div class="cell">
    <button class="button" type="button" data-tooltip tabindex="1" title="Fancy word for a beetle." data-position="top" data-alignment="left">
      Top Left
    </button>
  </div>

  <div class="cell">
    <button class="button" type="button" data-tooltip tabindex="1" title="Fancy word for a beetle." data-position="top" data-alignment="center">
      Top Center
    </button>
  </div>

  <div class="cell">
    <button class="button" type="button" data-tooltip tabindex="1" title="Fancy word for a beetle." data-position="top" data-alignment="right">
      Top Right
    </button>
  </div>
</div>

<br>

#### Left and Right Positioned

```html
<button class="button" type="button" data-tooltip tabindex="1" title="Fancy word for a beetle." data-position="right" data-alignment="top">
  Right Top
</button>

<button class="button" type="button" data-tooltip tabindex="1" title="Fancy word for a beetle." data-position="left" data-alignment="top">
  Left Top
</button>

<button class="button" type="button" data-tooltip tabindex="1" title="Fancy word for a beetle." data-position="right" data-alignment="center">
  Right Center
</button>

<button class="button" type="button" data-tooltip tabindex="1" title="Fancy word for a beetle." data-position="left" data-alignment="center">
  Left Center
</button>

<button class="button" type="button" data-tooltip tabindex="1" title="Fancy word for a beetle." data-position="right" data-alignment="bottom">
  Right Bottom
</button>

<button class="button" type="button" data-tooltip tabindex="1" title="Fancy word for a beetle." data-position="left" data-alignment="bottom">
  Left Bottom
</button>
```

<div class="grid-x grid-margin-x small-up-1 medium-up-2">
  <div class="cell">
    <button class="button" type="button" data-tooltip tabindex="1" title="Fancy word for a beetle." data-position="right" data-alignment="top">
      Right Top
    </button>
  </div>
  <div class="cell">
    <button class="button" type="button" data-tooltip tabindex="1" title="Fancy word for a beetle." data-position="left" data-alignment="top">
      Left Top
    </button>
  </div>

  <div class="cell">
    <button class="button" type="button" data-tooltip tabindex="1" title="Fancy word for a beetle." data-position="right" data-alignment="center">
      Right Center
    </button>
  </div>
  <div class="cell">
    <button class="button" type="button" data-tooltip tabindex="1" title="Fancy word for a beetle." data-position="left" data-alignment="center">
      Left Center
    </button>
  </div>

  <div class="cell">
    <button class="button" type="button" data-tooltip tabindex="1" title="Fancy word for a beetle." data-position="right" data-alignment="bottom">
      Right Bottom
    </button>
  </div>
  <div class="cell">
    <button class="button" type="button" data-tooltip tabindex="1" title="Fancy word for a beetle." data-position="left" data-alignment="bottom">
      Left Bottom
    </button>
  </div>
</div>
