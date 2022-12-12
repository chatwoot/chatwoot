---
title: Accordion
description: Accordions are elements that help you organize and navigate multiple documents in a single container. They can be used for switching between items in the container.
sass: scss/components/_accordion.scss
js: js/foundation.accordion.js
video: 'y_BX7saf65Q'
---

## Basics

The container for an accordion needs the class `.accordion`, and the attribute `data-accordion`. Note that in these examples, we use a `<ul>`, but you can use any element you want.

```html
<ul class="accordion" data-accordion></ul>
```

Inside the accordion, place a series of panes with the class `.accordion-item` and the attribute `data-accordion-item`. To mark which pane should be open by default, add the class `.is-active` to that pane.

Each pane has a **title**, an `<a>` with the class `.accordion-title`, and a **content area**, an element with the class `.accordion-content` and the attribute `data-tab-content`.

<p>
  <a class="" data-open-video="1:25"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/WjzKqa?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html
<ul class="accordion" data-accordion>
  <li class="accordion-item is-active" data-accordion-item>
    <!-- Accordion tab title -->
    <a href="#" class="accordion-title">Accordion 1</a>

    <!-- Accordion tab content: it would start in the open state due to using the `is-active` state class. -->
    <div class="accordion-content" data-tab-content>
      <p>Panel 1. Lorem ipsum dolor</p>
      <a href="#">Nowhere to Go</a>
    </div>
  </li>
  <!-- ... -->
</ul>
```

Once you put it all together, here's what you get!

<ul class="accordion" data-accordion>
  <li class="accordion-item is-active" data-accordion-item>
    <a href="#" class="accordion-title">Accordion 1</a>
    <div class="accordion-content" data-tab-content >
      <p>Panel 1. Lorem ipsum dolor</p>
      <a href="#">Nowhere to Go</a>
    </div>
  </li>
  <li class="accordion-item" data-accordion-item>
    <a href="#" class="accordion-title">Accordion 2</a>
    <div class="accordion-content" data-tab-content>
      <textarea></textarea>
      <button class="button">I do nothing!</button>
    </div>
  </li>
  <li class="accordion-item" data-accordion-item>
    <a href="#" class="accordion-title">Accordion 3</a>
    <div class="accordion-content" data-tab-content>
      Type your name!
      <input type="text"></input>
    </div>
  </li>
</ul>

---

## Advanced Options

### Multi-expand

By default, only one pane of an accordion can be open at a time. This can be changed by setting the `multiExpand` option to `true`.

<p>
  <a class="" data-open-video="5:11"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/ybEErg?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>


```html
<ul class="accordion" data-accordion data-multi-expand="true">
  <!-- ... -->
</ul>
```

<ul class="accordion" data-accordion data-multi-expand="true">
  <li class="accordion-item is-active" data-accordion-item>
    <a href="#" class="accordion-title">Accordion 1</a>
    <div class="accordion-content" data-tab-content >
      Panel 1. Lorem ipsum dolor
    </div>
  </li>
  <li class="accordion-item" data-accordion-item>
    <a href="#" class="accordion-title">Accordion 2</a>
    <div class="accordion-content" data-tab-content>
      Panel 2. Lorem ipsum dolor
    </div>
  </li>
  <li class="accordion-item" data-accordion-item>
    <a href="#" class="accordion-title">Accordion 3</a>
    <div class="accordion-content" data-tab-content>
      Panel 3. Lorem ipsum dolor
    </div>
  </li>
</ul>

---

### All Closed

By default, at least one pane in an accordion must be open. This can be changed by setting `allowAllClosed` option to `true`.

<p>
  <a class="" data-open-video="6:09"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/zwaaVp?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html
<ul class="accordion" data-accordion data-allow-all-closed="true">
  <!-- ... -->
</ul>
```

<ul class="accordion" data-accordion data-allow-all-closed="true">
  <li class="accordion-item is-active" data-accordion-item>
    <a href="#" class="accordion-title">Accordion 1</a>
    <div class="accordion-content" data-tab-content >
      Panel 1. Lorem ipsum dolor
    </div>
  </li>
  <li class="accordion-item" data-accordion-item>
    <a href="#" class="accordion-title">Accordion 2</a>
    <div class="accordion-content" data-tab-content>
      Panel 2. Lorem ipsum dolor
    </div>
  </li>
  <li class="accordion-item" data-accordion-item>
    <a href="#" class="accordion-title">Accordion 3</a>
    <div class="accordion-content" data-tab-content>
      Panel 3. Lorem ipsum dolor
    </div>
  </li>
</ul>

---

### Disabled

There may be times where you want to disable pane switching on an accordion. This can be accomplished by setting the `disabled` option.

<div class="warning callout">
  <p>The `disabled` option disables all up, down, and toggle methods of an accordion.  If you wish to manipulate a disabled accordion with <a href='#javascript-reference'>JavaScript</a>, you will need to remove the `disabled` option from the accordion.</p>
</div>

```html_example
<ul class="accordion" data-accordion disabled>
  <li class="accordion-item is-active" data-accordion-item>
    <a href="#" class="accordion-title">Accordion 1</a>
    <div class="accordion-content" data-tab-content>
      Panel 1. I'm open because I'm loaded that way, but you can't close me
    </div>
  </li>
  <li class="accordion-item" data-accordion-item>
    <a href="#" class="accordion-title">Accordion 2, you can't open me.</a>
    <div class="accordion-content" data-tab-content>
      Panel 2. Lorem ipsum dolor
    </div>
  </li>
  <li class="accordion-item" data-accordion-item>
    <a href="#" class="accordion-title">Accordion 3, you can't open me.</a>
    <div class="accordion-content" data-tab-content>
      Panel 3. Lorem ipsum dolor
    </div>
  </li>
</ul>
```
---

## Accordion and URLs

### Browser history

When the `data-deep-link` option is set to `true`, the current state of the accordion is recorded by adding a hash with the accordion panel ID to the browser URL when a accordion opens. By default, accordion *replace* the browser history (using `history.replaceState()`). Modify this behavior by using attribute `data-update-history="true"` to *append* to the browser history (using `history.pushState()`). In the latter case the browser back button will track each click that opens a accordion panel.

By using deep linking (see below), the open state of a page's tabset may be shared by copy-pasting the browser URL.

### Deep linking

Add the attribute `data-deep-link="true"` to a accordion to:
- modify the browser history when a accordion panel is clicked
- allow users to open a particular accordion panel at page load with a hash-appended URL

```html_example
<ul class="accordion" data-accordion data-deep-link="true" data-update-history="true" data-deep-link-smudge="true" data-deep-link-smudge-delay="500" id="deeplinked-accordion">
  <li class="accordion-item is-active" data-accordion-item>
    <a href="#deeplink1" class="accordion-title">Accordion 1</a>
    <div class="accordion-content" data-tab-content id="deeplink1">
      Panel 1. Lorem ipsum dolor
    </div>
  </li>
  <li class="accordion-item" data-accordion-item>
    <a href="#deeplink2" class="accordion-title">Accordion 2</a>
    <div class="accordion-content" data-tab-content id="deeplink2">
      Panel 2. Lorem ipsum dolor
    </div>
  </li>
  <li class="accordion-item" data-accordion-item>
    <a href="#deeplink3" class="accordion-title">Accordion 3</a>
    <div class="accordion-content" data-tab-content id="deeplink3">
      Panel 3. Lorem ipsum dolor
    </div>
  </li>
</ul>
```
For example, <a target="_blank" href="#deeplink3">http://example.com/#deeplink3</a> will open the third accordion panel at page load. This example will open a new browser tab and scroll you to the open accordion panel.

When linking directly to a accordion panel, it might not be obvious that the content appears within a accordion panel. An additional attribute `data-deep-link-smudge` rolls the page up slightly after deep linking (to a horizontal accordion) so that the accordion is at the top of the viewport.

```html_example
<ul class="accordion" data-deep-link="true" data-deep-link-smudge="true" data-deep-link-smudge-delay="600" data-accordion id="deeplinked-accordion-with-smudge">
```
