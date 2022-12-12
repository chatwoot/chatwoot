---
title: Smooth Scroll
description: Allows internal links smooth scrolling.
js: js/foundation.smoothScroll.js
tags:
  - navigation
---

<ul class="menu align-center" data-smooth-scroll>
  <li><a href="#setup">Setup</a></li>
  <li><a href="#javascript-reference">Javascript Reference</a></li>
</ul>

<hr>

## Setup

To enable SmoothScroll on internal links, just add the attribute `data-smooth-scroll` to the parent container like our [Menu](menu.html). Please note that each section needs a unique ID.

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/jwOEEM?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html
<ul class="menu" data-smooth-scroll>
  <li><a href="#first">First Arrival</a></li>
  <li><a href="#second">Second Arrival</a></li>
  <li><a href="#third">Third Arrival</a></li>
</ul>
<div class="sections">
  <section id="first">First Section</section>
  <section id="second">Second Section</section>
  <section id="third">Third Section</section>
</div>
```

You can also setup SmoothScroll directly via individual link.

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/NgWPab?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html
<a href="#exclusive" data-smooth-scroll>Exclusive Section</a>
<section id="exclusive">The Exclusive Section</section>
```
