---
title: Responsive Navigation
description: Our three Menu patterns form like Voltron into one responsive Menu plugin, which allows you to switch between patterns at different screen sizes.
video: 'dmKun75_9oc'
js:
  - js/foundation.responsiveMenu.js
  - js/foundation.responsiveToggle.js
---

## Responsive Menu

The Menu has some responsive CSS classes built in, which allow you to re-orient a menu on different screen sizes.

<p>
  <a class="" data-open-video="0:58"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/qmYKgJ?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<ul class="vertical medium-horizontal menu">
  <li><a href="#0"><i class="fi-list"></i> <span>One</span></a></li>
  <li><a href="#0"><i class="fi-list"></i> <span>Two</span></a></li>
  <li><a href="#0"><i class="fi-list"></i> <span>Three</span></a></li>
  <li><a href="#0"><i class="fi-list"></i> <span>Four</span></a></li>
</ul>
```

---

The Menu can be augmented with one of three different plugins&mdash;dropdown menu, drilldown menu, or accordion menu. However, these patterns tend to work best on specific screen sizes.

With our responsive Menu plugin, you can apply a default pattern to a Menu, and then change that pattern on other screen sizes.

Some Menu Combination (but not limited) to are

- [Drilldown Dropdown Menu](#drilldown-dropdown-menu)
- [Accordion Dropdown Menu](#accordion-dropdown-menu)
- [Drilldown Accordion Menu](#drilldown-accordion-menu)

#### Drilldown Dropdown Menu

A drilldown menu works well on mobile, but on larger screens, you may want to convert that same menu into a dropdown. Here's an example that does just that:

<p>
  <a class="" data-open-video="2:35"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/jmKPdM?editors=1010" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<ul class="vertical medium-horizontal menu" data-responsive-menu="drilldown medium-dropdown">
  <li>
    <a href="#">Item 1</a>
    <ul class="vertical menu">
      <li>
        <a href="#">Item 1A</a>
        <ul class="vertical menu">
          <li><a href="#">Item 1A</a></li>
          <li><a href="#">Item 1B</a></li>
          <li><a href="#">Item 1C</a></li>
          <li><a href="#">Item 1D</a></li>
          <li><a href="#">Item 1E</a></li>
        </ul>
      </li>
      <li><a href="#">Item 1B</a></li>
    </ul>
  </li>
  <li>
    <a href="#">Item 2</a>
    <ul class="vertical menu">
      <li><a href="#">Item 2A</a></li>
      <li><a href="#">Item 2B</a></li>
    </ul>
  </li>
  <li>
    <a href="#">Item 3</a>
    <ul class="vertical menu">
      <li><a href="#">Item 3A</a></li>
      <li><a href="#">Item 3B</a></li>
    </ul>
  </li>
</ul>
```

<br>
<div class="alert callout">
  <p>
    <strong>Bug(v6.3.1):</strong> There is a bug within <strong>drilldown-dropdown menu</strong> combo. If you set up a responsive menu with drilldown on small, then dropdown for medium up, and resize to small and then back to medium the dropdowns will not work. The bug can be reproduced <a href="http://codepen.io/IamManchanda/pen/mmGOgG?editors=1000">here</a> <br>
    <strong>Good News:</strong> The Bug will be fixed with the upcoming foundation release. If you are specifically using <strong>v6.3.1</strong>, we recommend to use this below patch to fix this.
  </p>
</div>

```javascript
// Patch for a Bug in v6.3.1
$(window).on('changed.zf.mediaquery', function() {
  $('.is-dropdown-submenu.invisible').removeClass('invisible');
});
```

#### Accordion Dropdown Menu

Same like drilldowns, an accordion menu works well on mobile, but on larger screens, you may want to convert that same menu into a dropdown. Here's an example for the same:

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/LyXBQz?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<ul class="vertical medium-horizontal menu" data-responsive-menu="accordion medium-dropdown">
  <li>
    <a href="#">Item 1</a>
    <ul class="vertical menu">
      <li>
        <a href="#">Item 1A</a>
        <ul class="vertical menu">
          <li><a href="#">Item 1A</a></li>
          <li><a href="#">Item 1B</a></li>
          <li><a href="#">Item 1C</a></li>
          <li><a href="#">Item 1D</a></li>
          <li><a href="#">Item 1E</a></li>
        </ul>
      </li>
      <li><a href="#">Item 1B</a></li>
    </ul>
  </li>
  <li>
    <a href="#">Item 2</a>
    <ul class="vertical menu">
      <li><a href="#">Item 2A</a></li>
      <li><a href="#">Item 2B</a></li>
    </ul>
  </li>
  <li>
    <a href="#">Item 3</a>
    <ul class="vertical menu">
      <li><a href="#">Item 3A</a></li>
      <li><a href="#">Item 3B</a></li>
    </ul>
  </li>
</ul>
```

<br>

#### Drilldown Accordion Menu

Just like foundation docs itself (see left sidenav), an accordion menu is great for a sidenav of a website on desktop, but for mobile, You might need Drilldown menu.

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/bWQjQP?editors=1010" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<ul class="vertical menu" data-responsive-menu="drilldown medium-accordion" style="max-width: 250px;">
  <li>
    <a href="#">Item 1</a>
    <ul class="vertical menu">
      <li>
        <a href="#">Item 1A</a>
        <ul class="vertical menu">
          <li><a href="#">Item 1A</a></li>
          <li><a href="#">Item 1B</a></li>
          <li><a href="#">Item 1C</a></li>
          <li><a href="#">Item 1D</a></li>
          <li><a href="#">Item 1E</a></li>
        </ul>
      </li>
      <li><a href="#">Item 1B</a></li>
    </ul>
  </li>
  <li>
    <a href="#">Item 2</a>
    <ul class="vertical menu">
      <li><a href="#">Item 2A</a></li>
      <li><a href="#">Item 2B</a></li>
    </ul>
  </li>
  <li>
    <a href="#">Item 3</a>
    <ul class="vertical menu">
      <li><a href="#">Item 3A</a></li>
      <li><a href="#">Item 3B</a></li>
    </ul>
  </li>
</ul>
```

---

## Responsive Toggle

In Foundation 5, the top bar combined this menu toggling concept into one plugin. We now have a separate, optional component you can use in tandem with the responsive plugin. It's called the title bar, and it allows you to quickly setup a menu toggle on mobile. The title bar hides itself on larger screens.

To set it up, first give your menu a unique ID. (You don't even need to use Menu! Any element will work.) Next, add a title bar with the class `.title-bar` and the attribute `data-responsive-toggle`. The value of `data-responsive-toggle` should be the ID of the menu you're toggling. Lastly, add `data-toggle` to the element that will trigger the toggle. The value of `data-toggle` should also be the ID of the menu you're toggling.

By default, the title bar will be visible on small screens, and the Menu hides. At the medium breakpoint, the title bar disappears, and the menu is always visible. This breakpoint can be changed with the `data-hide-for` attribute in HTML, or the `hideFor` setting in JavaScript.

<a class="" data-open-video="5:05"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>

<div class="primary callout show-for-medium">
  <p>Scale your browser down to see the toggle happen.</p>
</div>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/LymroM?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<div class="title-bar" data-responsive-toggle="example-menu" data-hide-for="medium">
  <button class="menu-icon" type="button" data-toggle="example-menu"></button>
  <div class="title-bar-title">Menu</div>
</div>

<div class="top-bar" id="example-menu">
  <div class="top-bar-left">
    <ul class="dropdown menu" data-dropdown-menu>
      <li class="menu-text">Site Title</li>
      <li>
        <a href="#">One</a>
        <ul class="menu vertical">
          <li><a href="#">One</a></li>
          <li><a href="#">Two</a></li>
          <li><a href="#">Three</a></li>
        </ul>
      </li>
      <li><a href="#">Two</a></li>
      <li><a href="#">Three</a></li>
    </ul>
  </div>
  <div class="top-bar-right">
    <ul class="menu">
      <li><input type="search" placeholder="Search"></li>
      <li><button type="button" class="button">Search</button></li>
    </ul>
  </div>
</div>
```

---

## Responsive Toggle with animation

To use animations from the Motion UI library, include the <code>data-animate="someAnimationIn someAnimationOut"</code> attribute.


<div class="primary callout show-for-medium">
  <p>Scale your browser down to see the toggle happen.</p>
</div>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/KmepBg?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<div class="title-bar" data-responsive-toggle="example-animated-menu" data-hide-for="medium">
  <button class="menu-icon" type="button" data-toggle></button>
  <div class="title-bar-title">Menu</div>
</div>

<div class="top-bar" id="example-animated-menu" data-animate="hinge-in-from-top spin-out">
  <div class="top-bar-left">
    <ul class="dropdown menu" data-dropdown-menu>
      <li class="menu-text">Site Title</li>
      <li>
        <a href="#">One</a>
        <ul class="menu vertical">
          <li><a href="#">One</a></li>
          <li><a href="#">Two</a></li>
          <li><a href="#">Three</a></li>
        </ul>
      </li>
      <li><a href="#">Two</a></li>
      <li><a href="#">Three</a></li>
    </ul>
  </div>
</div>
```

---

### Preventing FOUC

Before the JavaScript on your page loads, you'll be able to see both the mobile and desktop element at once for a brief second. This is known as a [flash of unstyled content](https://en.wikipedia.org/wiki/Flash_of_unstyled_content). There's not an easy way for the framework to handle this for you, but you can add some extra CSS to account for it.

If we reference the above example, `.title-bar` is our mobile element and `.top-bar` is our desktop element. So before the JavaScript loads, we want only the right element for that screen size to be visible.

```css
.no-js .top-bar {
  display: none;
}

@media screen and (min-width: 40em) {
  .no-js .top-bar {
    display: block;
  }

  .no-js .title-bar {
    display: none;
  }
}
```

If you're using Sass, you can write it like this:

```scss
.no-js {
  @include breakpoint(small only) {
    .top-bar {
      display: none;
    }
  }

  @include breakpoint(medium) {
    .title-bar {
      display: none;
    }
  }
}
```
