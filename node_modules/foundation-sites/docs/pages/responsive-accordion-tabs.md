---
title: Responsive Accordion Tabs
description: Added in 6.3.0, use the Markup of the Accordion or Tabs components to create Responsive Accordion Tabs.
video: 'FKzzaWR6j2M'
sass: 
  - scss/components/_accordion.scss
  - scss/components/_tabs.scss
js: js/foundation.responsiveAccordionTabs.js
tags:
  - tabcordion
---

## Basics

Either the <a href="accordion.html">Accordion Markup</a> or the <a href="tabs.html">Tabs Markup</a> can be used to responsively switch between the two components at different breakpoints.

The Accordion should have an id specified, but the plugin will automatically generate one if the id is omitted. 

Accordion content should also have an ID, or the # of the href should be specified, otherwise a random id will be generated

<div class="secondary callout">
  <p>The accordion/tabs values can be in any order.</p>
</div>

#### Accordion HTML Markup

<p>
  <a class="" data-open-video="0:35"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/eWKPqE?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html
<ul class="accordion" data-responsive-accordion-tabs="accordion medium-tabs large-accordion">
  <li class="accordion-item is-active" data-accordion-item>
    <a href="#" class="accordion-title">Accordion 1</a>
    <div class="accordion-content" data-tab-content>
      I would start in the open state, due to using the `is-active` state class.
    </div>
  </li>
  <!-- ... -->
</ul>
```
<div class="secondary callout">
  <p>Once you put it all together, here's what you get!<br>Scale your browser down to see the toggle happen.<br>I am an `Accordion on small and large` but I am `Tabs on medium`</p>
</div>

<ul class="accordion" data-responsive-accordion-tabs="accordion medium-tabs large-accordion">
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
      Pick a date!
      <input type="date"></input>
    </div>
  </li>
</ul>

#### Tabs HTML Markup

<p>
  <a class="" data-open-video="2:39"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/mmKQVN?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html
<ul class="tabs" data-responsive-accordion-tabs="tabs medium-accordion large-tabs" id="example-tabs">
  <li class="tabs-title is-active"><a href="#panel1" aria-selected="true">Tab 1</a></li>
  <li class="tabs-title"><a href="#panel2">Tab 2</a></li>
  <li class="tabs-title"><a href="#panel3">Tab 3</a></li>
  <li class="tabs-title"><a href="#panel4">Tab 4</a></li>
  <li class="tabs-title"><a href="#panel5">Tab 5</a></li>
  <li class="tabs-title"><a href="#panel6">Tab 6</a></li>
</ul>

<div class="tabs-content" data-tabs-content="example-tabs">
  <div class="tabs-panel is-active" id="panel1">
    <p>one</p>
    <p>Check me out! I'm a super cool Tab panel with text content!</p>
  </div>
  <div class="tabs-panel" id="panel2">
    <p>two</p>
    <img class="thumbnail" src="assets/img/generic/rectangle-7.jpg">
  </div>
  <div class="tabs-panel" id="panel3">
    <p>three</p>
    <p>Check me out! I'm a super cool Tab panel with text content!</p>
  </div>
  <div class="tabs-panel" id="panel4">
    <p>four</p>
    <img class="thumbnail" src="assets/img/generic/rectangle-2.jpg">
  </div>
  <div class="tabs-panel" id="panel5">
    <p>five</p>
    <p>Check me out! I'm a super cool Tab panel with text content!</p>
  </div>
  <div class="tabs-panel" id="panel6">
    <p>six</p>
    <img class="thumbnail" src="assets/img/generic/rectangle-8.jpg">
  </div>
</div>
```
<div class="secondary callout">
  <p>Once you put it all together, here's what you get!<br>Scale your browser down to see the toggle happen.<br>I am `Tabs on small and large` and `Accordion on medium`</p>
</div>

<ul class="tabs" data-responsive-accordion-tabs="tabs medium-accordion large-tabs" id="example-tabs">
  <li class="tabs-title is-active"><a href="#panel1" aria-selected="true">Tab 1</a></li>
  <li class="tabs-title"><a href="#panel2">Tab 2</a></li>
  <li class="tabs-title"><a href="#panel3">Tab 3</a></li>
  <li class="tabs-title"><a href="#panel4">Tab 4</a></li>
  <li class="tabs-title"><a href="#panel5">Tab 5</a></li>
  <li class="tabs-title"><a href="#panel6">Tab 6</a></li>
</ul>

<div class="tabs-content" data-tabs-content="example-tabs">
  <div class="tabs-panel is-active" id="panel1">
    <p>one</p>
    <p>Check me out! I'm a super cool Tab panel with text content!</p>
  </div>
  <div class="tabs-panel" id="panel2">
    <p>two</p>
    <img class="thumbnail" src="assets/img/generic/rectangle-7.jpg">
  </div>
  <div class="tabs-panel" id="panel3">
    <p>three</p>
    <p>Check me out! I'm a super cool Tab panel with text content!</p>
  </div>
  <div class="tabs-panel" id="panel4">
    <p>four</p>
    <img class="thumbnail" src="assets/img/generic/rectangle-2.jpg">
  </div>
  <div class="tabs-panel" id="panel5">
    <p>five</p>
    <p>Check me out! I'm a super cool Tab panel with text content!</p>
  </div>
  <div class="tabs-panel" id="panel6">
    <p>six</p>
    <img class="thumbnail" src="assets/img/generic/rectangle-8.jpg">
  </div>
</div>

<br>
<div class="success callout">The responsive behavior  can be set through the `data-responsive-accordion-tabs` option.<br> `tabs|accordion` , `medium-tabs|accordion` , `large-tabs|accordion` sets the behavior</div>

---

## Plugin Options

Plugin options can be set as individual data attributes, one combined data-options attribute, or as an object passed to the plugin's constructor. <a href="javascript.html#initializing">Learn more about how JavaScript plugins are initialized.</a><br>
<div class="primary callout">All `data-options` from <a href="accordion.html#js-options">Accordion</a> or <a href="tabs.html#js-options">Tabs</a> can be passed through.</div>
