---
title: Equalizer
description: Equalizer makes it dead simple to give multiple items equal height.
video: KbruAemirVQ
js: js/foundation.equalizer.js
---

## Basics

To set up an Equalizer group, you need a container, which gets the attribute `data-equalizer`, and then a series of child elements, which get the attribute `data-equalizer-watch`. The child elements will all be resized to have the same height.

<p>
  <a class="" data-open-video="0:47"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="https://codepen.io/colin-marshall/pen/BryEYL?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<div class="grid-x grid-margin-x" data-equalizer data-equalize-on="medium" id="test-eq">
  <div class="cell medium-4">
    <div class="callout" data-equalizer-watch>
      <img src= "assets/img/generic/square-1.jpg">
    </div>
  </div>
  <div class="cell medium-4">
    <div class="callout" data-equalizer-watch>
      <p>Pellentesque habitant morbi tristique senectus et netus et, ante.</p>
    </div>
  </div>
  <div class="cell medium-4">
    <div class="callout" data-equalizer-watch>
      <img src= "assets/img/generic/rectangle-1.jpg">
    </div>
  </div>
</div>
```

---

## Nesting

To use one Equalizer inside another, each container needs a unique ID, assigned with the `data-equalizer` attribute. Each `data-equalizer-watch` element should then have a value that matches its parent.

In the below example, the first set of Equalizer elements have the value `foo`, while the inside elements have the value `bar`. In the live example, we've also set the `equalizeOn` option to 'medium' for the parent elements, and the child Equalizer contained in the first div equalizes on stack, and maintains equal height.

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="https://codepen.io/colin-marshall/pen/oqgOoR?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html
<div class="grid-x" data-equalizer="foo">
  <div class="cell medium-4" data-equalizer-watch="foo">
    <div class="callout" data-equalizer-watch="foo" data-equalizer="bar">
      <h3>Parent panel</h3>
      <div class="callout" data-equalizer-watch="bar"></div>
      <div class="callout" data-equalizer-watch="bar"></div>
      <div class="callout" data-equalizer-watch="bar"></div>
    </div>
  </div>
  <div class="cell medium-4">
    <div class="callout panel" data-equalizer-watch="foo"></div>
  </div>
  <div class="cell medium-4">
    <div class="callout" data-equalizer-watch="foo"></div>
  </div>
</div>
```

<div class="grid-x grid-margin-x"  data-equalize-on="medium" data-equalizer="foo">
  <div class="cell medium-4" >
    <div class="callout" data-equalizer-watch="foo" data-equalizer="bar" data-equalize-on-stack="true">
      <h3>Parent panel</h3>
      <div class="callout" data-equalizer-watch="bar">
        <p>The three callouts in this panel will equalize, even when stacked.</p>
      </div>
      <div class="callout" data-equalizer-watch="bar">
        <p>Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Vestibulum tortor quam, feugiat vitae, ultricies eget, tempor sit amet, ante.</p>
      </div>
      <div class="callout" data-equalizer-watch="bar">
        <p>Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Vestibulum tortor quam, feugiat vitae, ultricies eget, tempor sit amet, ante.</p>
      </div>
    </div>
  </div>
  <div class="cell medium-4">
    <div class="callout panel" data-equalizer-watch="foo">
      <p>Where these panels will not equalize on stack, and instead equalize on medium up.</p>
    </div>
  </div>
  <div class="cell medium-4">
    <div class="callout" data-equalizer-watch="foo">
      <p>Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Vestibulum tortor quam, feugiat vitae, ultricies eget, tempor sit amet, ante.</p>
    </div>
  </div>
</div>

---

## Equalize By Row

If you have a gallery of items that wrap multiple times, Equalizer can be configured to match each row's items in height. Works great with the block grid!

<a class="" data-open-video="4:24"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>

<div class="callout primary">
  <p><strong>Under the Hood:</strong></p>
  <p>Equalizer splits the `data-equalizer-watch` elements into groups by checking their vertical offsets, and grouping ones with the same offset into a "row".</p>
  <p>Be aware on what you set `data-equalizer-watch`, if the top position is different, Equalizer will interpret that as a new "row" and equalize accordingly.</p>
</div>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="https://codepen.io/colin-marshall/pen/MVYRBG?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html
<div class="grid-x grid-padding-x small-up-1 medium-up-2 large-up-4" data-equalizer data-equalize-by-row="true">
  <div class="cell" data-equalizer-watch></div>
  <div class="cell" data-equalizer-watch></div>
  <div class="cell" data-equalizer-watch></div>
  <!-- ... -->
</div>
```

<div class="grid-x grid-padding-x small-up-1 medium-up-2 large-up-4" data-equalizer data-equalize-by-row="true">
  <div class="cell">
    <div class="callout" data-equalizer-watch>
      <img src="https://placehold.it/180x200" class="thumbnail" alt="">
      <p>Lorem ipsum dolor sit amet<p>
    </div>
  </div>
  <div class="cell">
    <div class="callout" data-equalizer-watch>
      <p>Lorem ipsum dolor sit amet<p>
    </div>
  </div>
  <div class="cell">
    <div class="callout" data-equalizer-watch>
      <p>Lorem ipsum dolor sit amet<p>
    </div>
  </div>
  <div class="cell">
    <div class="callout" data-equalizer-watch>
      <img src="https://placehold.it/180x180" class="thumbnail" alt="">
    </div>
  </div>
  <div class="cell">
    <div class="callout" data-equalizer-watch>
      <p>Lorem ipsum dolor sit amet<p>
    </div>
  </div>
  <div class="cell">
    <div class="callout" data-equalizer-watch>
      <p>Lorem ipsum dolor sit amet<p>
    </div>
  </div>
  <div class="cell">
    <div class="callout" data-equalizer-watch>
      <img src="https://placehold.it/180x400" class="thumbnail" alt="">
    </div>
  </div>
  <div class="cell">
    <div class="callout" data-equalizer-watch>
      <img src="https://placehold.it/180x200" class="thumbnail" alt="">
      <p>Lorem ipsum dolor sit amet<p>
    </div>
  </div>
  <div class="cell">
    <div class="callout" data-equalizer-watch>
      <p>Lorem ipsum dolor sit amet<p>
    </div>
  </div>
  <div class="cell">
    <div class="callout" data-equalizer-watch>
      <p>Lorem ipsum dolor sit amet<p>
    </div>
  </div>
  <div class="cell">
    <div class="callout" data-equalizer-watch>
      <img src="https://placehold.it/180x180" class="thumbnail" alt="">
    </div>
  </div>
  <div class="cell">
    <div class="callout" data-equalizer-watch>
      <p>Lorem ipsum dolor sit amet<p>
    </div>
  </div>
  <div class="cell">
    <div class="callout" data-equalizer-watch>
      <p>Lorem ipsum dolor sit amet<p>
    </div>
  </div>
  <div class="cell">
    <div class="callout" data-equalizer-watch>
      <p>Lorem ipsum dolor sit amet<p>
    </div>
  </div>
  <div class="cell">
    <div class="callout" data-equalizer-watch>
      <p>Lorem ipsum dolor sit amet<p>
    </div>
  </div>
  <div class="cell">
    <div class="callout" data-equalizer-watch>
      <p>Lorem ipsum dolor sit amet<p>
    </div>
  </div>
  <div class="cell">
    <div class="callout" data-equalizer-watch>
      <p>Lorem ipsum dolor sit amet<p>
    </div>
  </div>
  <div class="cell">
    <div class="callout" data-equalizer-watch>
      <img src="https://placehold.it/180x400" class="thumbnail" alt="">
    </div>
  </div>
</div>
