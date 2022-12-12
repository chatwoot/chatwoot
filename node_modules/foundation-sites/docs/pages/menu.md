---
title: Menu
description: Our flexible menu component makes it easy to build many common navigation patterns, all with the same markup.
video: 'CmMGPCd-fYc'
sass: scss/components/_menu.scss
tags:
  - navigation
  - side nav
  - sub nav
  - icon bar
  - top bar
flex: true
---

<div class="callout training-callout">
  <p>Navigation is one the most crucial part of your site. Be a navigation guru with our Foundation online webinar training. You’ll learn techniques for creating responsive navigations that work with any type of site. In addition to that you can learn tips and tricks and best practices for all of Foundation’s components.</p>
  <a href="http://zurb.com/university/foundation-intro" target="_blank">Find out more about Foundation training classes →</a>
</div>

The menu is a flexible, all-purpose component for navigation. It replaces Foundation 5's inline list, side nav, sub nav, and icon bar, unifying them into one component.

---

## Basic Menu

All versions of the menu are a `<ul>` filled with `<li>` elements containing links. By default, a Menu is horizontally oriented.

<p>
  <a class="" data-open-video="00:36"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/rmvXMX?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<ul class="menu">
  <li><a href="#">One</a></li>
  <li><a href="#">Two</a></li>
  <li><a href="#">Three</a></li>
  <li><a href="#">Four</a></li>
</ul>
```

---

## Item Alignment

By default, each item in the menu aligns to the left. They can also be aligned to the right with the `.align-right` class.

<a class="" data-open-video="2:02"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
<div class="warning callout">
  <p>In a <a href="rtl.html">right-to-left</a> environment, items align to the right by default, and the class <code>.align-left</code> can be used to reverse direction.</p>
</div>


<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/zwjgWv?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<ul class="menu align-right">
  <li><a href="#">One</a></li>
  <li><a href="#">Two</a></li>
  <li><a href="#">Three</a></li>
  <li><a href="#">Four</a></li>
</ul>
```

<br>

To align items in the middle, add `.align-center` to the `.menu` class.

<a class="" data-open-video="2:46"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/VbOypm?editors=1100" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<ul class="menu align-center">
  <li><a href="#">One</a></li>
  <li><a href="#">Two</a></li>
  <li><a href="#">Three</a></li>
  <li><a href="#">Four</a></li>
</ul>
```

<br>

Items can also be set to expand out and take up an even amount of space, with the `.expanded` class. Thanks to the magic of CSS, the items will automatically size themselves equally depending on how many are inside the menu.

<p>
  <a class="" data-open-video="3:34"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/bWMXQO?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<ul class="menu expanded">
  <li><a href="#">One</a></li>
  <li><a href="#">Two</a></li>
</ul>
```

<ul class="menu expanded">
  <li><a href="#0">One</a></li>
  <li><a href="#0">Two</a></li>
  <li><a href="#0">Three</a></li>
</ul>

<ul class="menu expanded">
  <li><a href="#0">One</a></li>
  <li><a href="#0">Two</a></li>
  <li><a href="#0">Three</a></li>
  <li><a href="#0">Four</a></li>
</ul>

---

## Vertical Menu

Add the `.vertical` class to a Menu to switch its orientation.

<p>
  <a class="" data-open-video="4:53"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/YVLmBY?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<ul class="vertical menu">
  <li><a href="#">One</a></li>
  <li><a href="#">Two</a></li>
  <li><a href="#">Three</a></li>
  <li><a href="#">Four</a></li>
</ul>
```

<br>

Add `align-right` class for making the vertical menu aligned to the right.

```html_example
<ul class="vertical menu align-right">
  <li><a href="#">One</a></li>
  <li><a href="#">Two</a></li>
  <li><a href="#">Three</a></li>
  <li><a href="#">Four</a></li>
</ul>
```

<br>

Add `align-center` class for making the vertical menu aligned to the center.

<div class="warning callout">
  <p>
    The above vertically left &amp; right aligned menu are supported in all types of menu's. <br>
    But `align-center` for vertical menu&rsquo;s is only available for basic menu and is not available for dropdown, accordion or a drilldown menu.
  </p>
</div>

```html_example
<ul class="vertical menu align-center">
  <li><a href="#">One</a></li>
  <li><a href="#">Two</a></li>
  <li><a href="#">Three</a></li>
  <li><a href="#">Four</a></li>
</ul>
```

---

## Simple Style

Add the `.simple` class to a Menu to remove the padding and color change. This style imitates the inline list from Foundation 5.

<p>
  <a class="" data-open-video="6:06"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/ZKogNb?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<ul class="menu simple">
  <li>One</li>
  <li><a href="#">Two</a></li>
  <li><a href="#">Three</a></li>
  <li><a href="#">Four</a></li>
</ul>
```

---

## Nested Style

Add a new menu inside the `<li>` of a Menu and add the class `.nested` to create a nested menu. The nested Menu has extra padding on the inside.

<p>
  <a class="" data-open-video="7:17"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/vmrBOr?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<ul class="vertical menu">
  <li>
    <a href="#">One</a>
    <ul class="nested vertical menu">
      <li><a href="#">One</a></li>
      <li><a href="#">Two</a></li>
      <li><a href="#">Three</a></li>
      <li><a href="#">Four</a></li>
    </ul>
  </li>
  <li><a href="#">Two</a></li>
  <li><a href="#">Three</a></li>
  <li><a href="#">Four</a></li>
</ul>
```

---

## Active State

Add the class `.is-active` to any `<li>` to create an active state. You could apply this server-side to mark the active page, or dynamically with JavaScript.

<p>
  <a class="" data-open-video="8:18"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/XRYrKp?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<ul class="menu">
  <li class="is-active"><a>Home</a></li>
  <li><a>About</a></li>
  <li><a>Nachos</a></li>
</ul>
```

---

## Text

Because the padding of the menu item is applied to the `<a>`, if you try to add an item that's text only, it will be misaligned. To get around this, add the class `.menu-text` to any `<li>` that doesn't have a link inside of it.

<p>
  <a class="" data-open-video="9:11"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/GmGRWp?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<ul class="menu">
  <li class="menu-text">Site Title</li>
  <li><a href="#">One</a></li>
  <li><a href="#">Two</a></li>
  <li><a href="#">Three</a></li>
</ul>
```

---

## Icons

Menu items can have icons. Wrap the text of the item in a `<span>`, and then add an `<img>` element before the `<span>`. If you're using the Foundation icon font, the `<img>` will be an `<i>` instead.

<p>
  <a class="" data-open-video="9:52"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/OmEJQW?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>


```html_example
<ul class="menu">
  <li><a href="#"><i class="fi-list"></i> <span>One</span></a></li>
  <li><a href="#"><i class="fi-list"></i> <span>Two</span></a></li>
  <li><a href="#"><i class="fi-list"></i> <span>Three</span></a></li>
  <li><a href="#"><i class="fi-list"></i> <span>Four</span></a></li>
</ul>
```

---

Add the class `.icons` to the parent menu container to specify that the menu contains icons. Along with this, add your choice of layout class, such as `.icon-top`.

When using any of the menu icon layout classes, ensure that the icon and the text are in the correct order. For `.icon-right` and `.icon-bottom`, the icon must come AFTER the text.

<p>
  <a class="" data-open-video="10:42"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<br>

### Icon Top
<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/EXLmxO?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<ul class="menu icons icon-top">
  <li><a href="#"><i class="fi-list"></i> <span>One</span></a></li>
  <li><a href="#"><i class="fi-list"></i> <span>Two</span></a></li>
  <li><a href="#"><i class="fi-list"></i> <span>Three</span></a></li>
  <li><a href="#"><i class="fi-list"></i> <span>Four</span></a></li>
</ul>
```

<br>

### Icon Right
<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/vZjmEE?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<ul class="menu icons icon-right">
  <li><a href="#"><span>One</span> <i class="fi-list"></i></a></li>
  <li><a href="#"><span>Two</span> <i class="fi-list"></i></a></li>
  <li><a href="#"><span>Three</span> <i class="fi-list"></i></a></li>
  <li><a href="#"><span>Four</span> <i class="fi-list"></i></a></li>
</ul>
```

<br>

### Icon Bottom
<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/vZjmOE?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<ul class="menu icons icon-bottom">
  <li><a href="#"><span>One</span> <i class="fi-list"></i></a></li>
  <li><a href="#"><span>Two</span> <i class="fi-list"></i></a></li>
  <li><a href="#"><span>Three</span> <i class="fi-list"></i></a></li>
  <li><a href="#"><span>Four</span> <i class="fi-list"></i></a></li>
</ul>
```

<br>

### Icon Left
<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/qjYmdG?editors=1100" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<ul class="menu icons icon-left">
  <li><a href="#"><i class="fi-list"></i> <span>One</span></a></li>
  <li><a href="#"><i class="fi-list"></i> <span>Two</span></a></li>
  <li><a href="#"><i class="fi-list"></i> <span>Three</span></a></li>
  <li><a href="#"><i class="fi-list"></i> <span>Four</span></a></li>
</ul>
```
---

## Sticky Navigation

See the documentation for the [Sticky](sticky.html#sticky-navigation) plugin to see how to easily make a sticky nav bar.
