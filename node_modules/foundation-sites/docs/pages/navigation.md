---
title: Navigation
description: Foundation is bundled with many simple navigation patterns, which can be combined to form more complex, robust responsive navigation solutions.
---

## Basics: Menu

The Menu is an all-purpose navigation component. It can be aligned horizontally or vertically, can be nested, and supports icons. [Learn more about the Menu.](menu.html)

All menus use the `ul > li > a` pattern. The markup is a little strict, but this makes it easy to attach a navigation plugin to any menu, as you'll see below.

Here's a basic Menu.

```html_example
<ul class="menu">
  <li><a href="#">Item One</a></li>
  <li><a href="#">Item Two</a></li>
  <li><a href="#">Item Three</a></li>
</ul>
```

---

To nest menus, add a new `<ul>` inside of an `<li>`, *after* the `<a>` inside.

```html
<ul class="menu">
  <li>
    <a href="#">Item One</a>
    <ul class="menu">
      <li><a href="#">Item One-one</a></li>
    </ul>
  </li>
  <li><a href="#">Item Two</a></li>
  <li><a href="#">Item Three</a></li>
</ul>
```

---

## Top Bar

Top bar is a simple wrapper around these menu patterns. It supports a left-hand and right-hand section, which collapse on top of each other on small screens. [Learn more about the top bar.](top-bar.html)

<div class="top-bar">
  <div class="top-bar-left">
    <ul class="dropdown menu" data-dropdown-menu>
      <li class="menu-text">Site Title</li>
      <li><a href="#0">One</a></li>
      <li><a href="#0">Two</a></li>
      <li><a href="#0">Three</a></li>
    </ul>
  </div>
  <div class="top-bar-right">
    <ul class="menu">
      <li><input type="search" placeholder="Search"></li>
      <li><button type="button" class="button">Search</button></li>
    </ul>
  </div>
</div>

---

## Menu Plugins

The basic Menu can be enhanced with one of three **Menu plugins**. All three use the exact same markup to create a different style of multi-tier navigation.

### Dropdown Menu

The dropdown menu plugin (`data-dropdown-menu`) converts a nested menu into a series of dropdown menus. The nested menus can be opened through hover, click, or keyboard. [Learn more about the dropdown menu.](dropdown-menu.html)

<ul class="dropdown menu" data-dropdown-menu>
  <li class="has-submenu">
    <a>Item 1</a>
    <ul class="submenu menu" data-submenu>
      <li><a href="#0">Item 1A Loooong</a></li>
      <li class="has-submenu">
        <a href="#0"> Item 1 sub</a>
        <ul class="submenu menu" data-submenu>
          <li><a href="#0">Item 1 subA</a></li>
          <li><a href="#0">Item 1 subB</a></li>
          <li class="has-submenu">
            <a href="#"> Item 1 sub</a>
            <ul class="submenu menu" data-submenu>
              <li><a href="#0">Item 1 subA</a></li>
              <li><a href="#0">Item 1 subB</a></li>
            </ul>
          </li>
          <li class="has-submenu">
            <a href="#0">Item 1 sub</a>
            <ul class="submenu menu" data-submenu>
              <li><a href="#0">Item 1 subA</a></li>
              <li><a href="#0">Item 1 subB</a></li>
            </ul>
          </li>

        </ul>
      </li>
      <li><a href="#0">Item 1B</a></li>
    </ul>
  </li>
  <li class="has-submenu">
    <a href="#0">Item 2</a>
    <ul class="submenu menu" data-submenu>
      <li><a href="#0">Item 2A</a></li>
      <li><a href="#0">Item 2B</a></li>
    </ul>
  </li>
  <li class="has-submenu">
    <a href="#0">Item 3</a>
    <ul class="submenu menu" data-submenu>
      <li><a href="#0">Item 3A</a></li>
      <li><a href="#0">Item 3B</a></li>
    </ul>
  </li>
  <li><a href="#0">Item 4</a></li>
</ul>

---

### Drilldown Menu

The drilldown menu plugin (`data-drilldown`) converts a nested menu into a series of sliding menus. Clicking an item slides the next level menu into view. [Learn more about the drilldown menu.](drilldown-menu.html)

<ul class="vertical menu" data-drilldown style="width: 300px;" id="m1">
  <li class="has-submenu">
    <a href="#">Item 1</a>
    <ul class="vertical menu" data-submenu id="m2">
      <li class="has-submenu">
        <a href="#">Item 1A</a>
        <ul class="vertical menu" data-submenu id="m3">
          <li><a href="#0">Item 1Aa</a></li>
          <li><a href="#0">Item 1Ba</a></li>
          <li><a href="#0">Item 1Ca</a></li>
          <li><a href="#0">Item 1Da</a></li>
          <li><a href="#0">Item 1Ea</a></li>
        </ul>
      </li>
      <li><a href="#0">Item 1B</a></li>
      <li><a href="#0">Item 1C</a></li>
      <li><a href="#0">Item 1D</a></li>
      <li><a href="#0">Item 1E</a></li>
    </ul>
  </li>
  <li class="has-submenu">
    <a href="#">Item 2</a>
    <ul class="vertical menu" data-submenu>
      <li><a href="#0">Item 2A</a></li>
      <li><a href="#0">Item 2B</a></li>
      <li><a href="#0">Item 2C</a></li>
      <li><a href="#0">Item 2D</a></li>
      <li><a href="#0">Item 2E</a></li>
    </ul>
  </li>
  <li class="has-submenu">
    <a href="#">Item 3</a>
    <ul class="vertical menu" data-submenu>
      <li><a href="#0">Item 3A</a></li>
      <li><a href="#0">Item 3B</a></li>
      <li><a href="#0">Item 3C</a></li>
      <li><a href="#0">Item 3D</a></li>
      <li><a href="#0">Item 3E</a></li>
    </ul>
  </li>
  <li><a href="#"> Item 4</a></li>
</ul>

---

### Accordion Menu

The accordion menu plugin (`data-accordion-menu`) converts a nested menu into a series of collapsed accordions. Clicking an item slides down the nested menu. [Learn more about the accordion menu.](accordion-menu.html)

<div class="vertical menu" data-accordion-menu>
  <li class="has-submenu">
    <a href="#">Item 1</a>
    <ul class="menu vertical nested is-active" data-submenu>
      <li class="has-submenu">
        <a href="#">Item 1A</a>
        <ul class="menu vertical nested" data-submenu>
          <li><a href="#0">Item 1Ai</a></li>
          <li><a href="#0">Item 1Aii</a></li>
          <li><a href="#0">Item 1Aiii</a></li>
        </ul>
      </li>
      <li><a href="#0">Item 1B</a></li>
      <li><a href="#0">Item 1C</a></li>
    </ul>
  </li>
  <li class="has-submenu">
    <a href="#">Item 2</a>
    <ul class="menu vertical nested" data-submenu>
      <li><a href="#0">Item 2A</a></li>
      <li><a href="#0">Item 2B</a></li>
    </ul>
  </li>
  <li><a href="#0">Item 3</a></li>
</div>

---

## Responsive Navigation

Each of the above three patterns has a use in a specific context. But some patterns only work at certain screen sizes. For example, dropdown menus don't work as well on smaller screens, but the same navigation items might work better as a drilldown or an accordion menu at that screen size.

Our responsive menu plugin (`data-responsive-menu`) allows you to take a Menu, and assign different navigation patterns to it at different screen sizes. In the below example, a drilldown menu changes to a dropdown menu at larger screen sizes. [Learn more about the responsive Menu plugin.](responsive-navigation.html#responsive-menu)

<ul class="vertical menu" data-responsive-menu="drilldown medium-dropdown" style="width: 300px;">
  <li class="has-submenu">
    <a href="#0">Item 1</a>
    <ul class="vertical submenu menu" data-submenu id="m2">
      <li class="has-submenu">
        <a href="#0">Item 1A</a>
        <ul class="vertical submenu menu" data-submenu id="m3">
          <li><a href="#0">Item 1A</a></li>
          <li><a href="#0">Item 1B</a></li>
          <li><a href="#0">Item 1C</a></li>
          <li><a href="#0">Item 1D</a></li>
          <li><a href="#0">Item 1E</a></li>
        </ul>
      </li>
      <li><a href="#0">Item 1B</a></li>
    </ul>
  </li>
  <li class="has-submenu">
    <a href="#0">Item 2</a>
    <ul class="vertical submenu menu" data-submenu>
      <li><a href="#0">Item 2A</a></li>
      <li><a href="#0">Item 2B</a></li>
    </ul>
  </li>
  <li class="has-submenu">
    <a href="#0">Item 3</a>
    <ul class="vertical submenu menu" data-submenu>
      <li><a href="#0">Item 3A</a></li>
      <li><a href="#0">Item 3B</a></li>
    </ul>
  </li>
</ul>

---

In other situations, you may wish to always display a menu on a larger screen, but hide that same menu behind a click toggle on smaller screens. You can do this with the responsive toggle plugin (`data-responsive-toggle`). This plugin works with any container, not just a menu. [Learn more about the responsive toggle plugin.](responsive-navigation.html#responsive-toggle)

To see the below example in action, scale your browser down. The top bar will be replaced by a smaller title bar. Clicking the icon inside the title bar reveals the top bar.

<div class="title-bar" data-responsive-toggle="example-menu" data-hide-for="medium">
  <button class="menu-icon" type="button" data-toggle></button>
  <div class="title-bar-title">Menu</div>
</div>

<div class="top-bar" id="example-menu">
  <div class="top-bar-left">
    <ul class="dropdown menu" data-dropdown-menu>
      <li class="menu-text">Site Title</li>
      <li class="has-submenu">
        <a href="#0">One</a>
        <ul class="submenu menu vertical" data-submenu>
          <li><a href="#0">One</a></li>
          <li><a href="#0">Two</a></li>
          <li><a href="#0">Three</a></li>
        </ul>
      </li>
      <li><a href="#0">Two</a></li>
      <li><a href="#0">Three</a></li>
    </ul>
  </div>
  <div class="top-bar-right">
    <ul class="menu">
      <li><input type="search" placeholder="Search"></li>
      <li><button type="button" class="button">Search</button></li>
    </ul>
  </div>
</div>

---

## Sticky Navigation

See the documentation for the [Sticky](sticky.html#sticky-navigation) plugin to see how to easily make a sticky nav bar.
