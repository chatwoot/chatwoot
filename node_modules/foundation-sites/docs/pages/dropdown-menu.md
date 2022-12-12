---
title: Dropdown Menu
description: Change a basic Menu into an expandable dropdown menu with the Dropdown Menu plugin.
video: 'KfnRuKBKrbw'
sass: scss/components/_dropdown-menu.scss
js: js/foundation.dropdownMenu.js
---

## Horizontal

Dropdown menus build on the [Menu](menu.html) component's syntax. Add the class `.dropdown` and the attribute `data-dropdown-menu` to the menu container to set up the dropdown.

```html
<ul class="dropdown menu" data-dropdown-menu>
  <li><a href="#">Item 1</a></li>
  <li><a href="#">Item 2</a></li>
  <li><a href="#">Item 3</a></li>
  <li><a href="#">Item 4</a></li>
</ul>
```

To create dropdown menus, nest a new `<ul>` inside an `<li>`. You can nest further to create more levels of dropdowns.

<a class="" data-open-video="0:53"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>

<div class="primary callout">
  <p>Note that the <code>&lt;ul&gt;</code> goes <em>after</em> the <code>&lt;a&gt;</code>, and not inside of it.</p>
</div>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/XRYWPO?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html
<ul class="dropdown menu" data-dropdown-menu>
  <li>
    <a href="#">Item 1</a>
    <ul class="menu">
      <li><a href="#">Item 1A</a></li>
      <!-- ... -->
    </ul>
  </li>
  <li><a href="#">Item 2</a></li>
  <li><a href="#">Item 3</a></li>
  <li><a href="#">Item 4</a></li>
</ul>
```

<ul class="dropdown menu" data-dropdown-menu>
  <li>
    <a href="#Item-1">Item 1</a>
    <ul class="menu">
      <li><a href="#Item-1A">Item 1A</a></li>
      <li>
        <a href="#Item-1B">Item 1B</a>
        <ul class="menu">
          <li><a href="#Item-1Bi">Item 1B i</a></li>
          <li><a href="#Item-1Bii">Item 1B ii</a></li>
          <li>
            <a href="#Item-1Biii">Item 1B iii</a>
            <ul class="menu">
              <li><a href="#Item-1Biiialpha">Item 1B iii alpha</a></li>
              <li><a href="#Item-1Biiiomega">Item 1B iii omega</a></li>
            </ul>
          </li>
          <li>
            <a href="#Item-1Biv">Item 1B iv</a>
            <ul class="menu">
              <li><a href="#Item-1Bivalpha">Item 1B iv alpha</a></li>
            </ul>
          </li>
        </ul>
      </li>
      <li><a href="#Item-1C">Item 1C</a></li>
    </ul>
  </li>
  <li>
    <a href="#Item-2">Item 2</a>
    <ul class="menu">
      <li><a href="#Item-2A">Item 2A</a></li>
      <li><a href="#Item-2B">Item 2B</a></li>
    </ul>
  </li>
  <li><a href="#Item-3">Item 3</a></li>
  <li><a href="#Item-4">Item 4</a></li>
</ul>

---

## Vertical

Add the `.vertical` class to the top-level menu to make it vertical. Sub-menus are automatically vertical, regardless of the orientation of the top-level menu.

<div class="primary callout">
  <p>Menus are block-level elements, which means they stretch to fill the width of their container. To make the below example less goofy, we've hard-coded a <code>max-width</code> on the menu.</p>
</div>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/LyrYaE?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html
<ul class="vertical dropdown menu" data-dropdown-menu style="max-width: 250px;">
  <li>
    <a href="#">Item 1</a>
    <ul class="vertical menu nested">
      <li><a href="#">Item 1A</a></li>
      <!-- ... -->
    </ul>
  </li>
  <li><a href="#">Item 2</a></li>
  <li><a href="#">Item 3</a></li>
  <li><a href="#">Item 4</a></li>
  <!-- ... -->
</ul>
```

<ul class="vertical dropdown menu" data-dropdown-menu style="max-width: 250px;">
  <li>
    <a href="#Item-1">Item 1</a>
    <ul class="vertical menu nested">
      <li><a href="#Item-1A">Item 1A</a></li>
      <li>
        <a href="#Item-1B">Item 1B</a>
        <ul class="vertical menu nested">
          <li><a href="#Item-1Bi">Item 1B i</a></li>
          <li><a href="#Item-1Bii">Item 1B ii</a></li>
          <li>
            <a href="#Item-1Biii">Item 1B iii</a>
            <ul class="vertical menu nested">
              <li><a href="#Item-1Biiialpha">Item 1B iii alpha</a></li>
              <li><a href="#Item-1Biiiomega">Item 1B iii omega</a></li>
            </ul>
          </li>
          <li>
            <a href="#Item-1Biv">Item 1B iv</a>
            <ul class="vertical menu nested">
              <li><a href="#Item-1Bivalpha">Item 1B iv alpha</a></li>
            </ul>
          </li>
        </ul>
      </li>
      <li><a href="#Item-1C">Item 1C</a></li>
    </ul>
  </li>
  <li>
    <a href="#Item-2">Item 2</a>
    <ul class="vertical menu nested">
      <li><a href="#Item-2A">Item 2A</a></li>
      <li><a href="#Item-2B">Item 2B</a></li>
    </ul>
  </li>
  <li><a href="#Item-3">Item 3</a></li>
  <li><a href="#Item-4">Item 4</a></li>
</ul>

---

## Sticky Navigation

See the documentation for the [Sticky](sticky.html#sticky-navigation) plugin to see how to easily make a sticky nav bar.

---

### Preventing FOUC

Before the JavaScript on your page loads, the dropdown menus will not have arrows. However, once the JavaScript file has loaded, the arrows will appear causing a [flash of unstyled content](https://en.wikipedia.org/wiki/Flash_of_unstyled_content). You can prevent this by adding the `.is-dropdown-submenu-parent` class manually.

```html
<ul class="dropdown menu" data-dropdown-menu>
  <li class="is-dropdown-submenu-parent">
    <a href="#">Item 1</a>
    <ul class="menu">
      <li><a href="#">Item 1A</a></li>
      <!-- ... -->
    </ul>
  </li>
  <li><a href="#">Item 2</a></li>
  <li><a href="#">Item 3</a></li>
  <li><a href="#">Item 4</a></li>
</ul>
```
