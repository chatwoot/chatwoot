---
title: Magellan
description: Magellan allows you to create navigation that tracks the active section of a page your user is in. Pair it with our Sticky plugin to create a fixed navigation element.
video: 'eT-WWX74SY0'
js: js/foundation.magellan.js
tags:
  - navigation
---

## Setup

You can use Magellan with any navigation element, like our [Menu](menu.html) or your own custom component. Just add the attribute `data-magellan` to the container, and links to specific sections of your page. Each section needs a unique ID.

<p>
  <a class="" data-open-video="0:42"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/MmGEXo?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html
<!-- Add a Menu -->
<ul class="menu expanded" data-magellan>
  <li><a href="#first">First Arrival</a></li>
  <li><a href="#second">Second Arrival</a></li>
  <li><a href="#third">Third Arrival</a></li>
</ul>

<!-- Add content where magellan will be linked -->
<div class="sections">
  <section id="first" data-magellan-target="first">First Section</section>
  <section id="second" data-magellan-target="second">Second Section</section>
  <section id="third" data-magellan-target="third">Third Section</section>
</div>
```

---

## Sticky Navigation

You can use Magellan with our Sticky plugin to create a persistent navigation header or sidebar.

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="https://codepen.io/ZURBFoundation/pen/gWKLqV?editors=1100" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html 
<!-- Add a Sticky Menu -->
<div data-sticky-container>
  <div class="top-bar" data-sticky data-margin-top="0" id="example-menu">
    <div class="top-bar-left">
      <ul class="menu">
        <li class="menu-text">Site Title</li>
      </ul>
    </div>
    <div class="top-bar-right">
      <ul class="menu" data-magellan>
        <li><a href="#first">One</a></li>
        <li><a href="#second">Two</a></li>
        <li><a href="#third">Three</a></li>
      </ul>
    </div>
  </div>
</div>

<!-- Add content where magellan will be linked -->
<div class="sections">
  <section id="first" data-magellan-target="first">First Section</section>
  <section id="second" data-magellan-target="second">Second Section</section>
  <section id="third" data-magellan-target="third">Third Section</section>
</div>
```

This below example is a simplified version of the table of contents on the right side of this page.

```html
<div class="cell large-3">
  <nav class="sticky-container" data-sticky-container>
    <div class="sticky" data-sticky data-anchor="exampleId" data-sticky-on="large">
      <ul class="vertical menu" data-magellan>
        <li><a href="#first">First Arrival</a></li>
        <li><a href="#second">Second Arrival</a></li>
        <li><a href="#third">Third Arrival</a></li>
      </ul>
    </div>
  </nav>
</div>
```

