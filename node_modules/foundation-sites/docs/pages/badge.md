---
title: Badge
description: The badge is a basic component that displays a number. It's useful for calling out a number of unread items.
sass: scss/components/_badge.scss
video: '_S_OO9NiWQ8'
---

## Basics

Add the `.badge` class to an element to create a badge. In the below example, we're using `<span>`, but any tag will work fine.

<p>
  <a class="" data-open-video="1:28"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/vmrPOM?editors=1100" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<span class="badge">1</span>
```

<br>

A badge will typically be describing another element on the page. To bind the two elements together, give the badge a unique ID, and reference that ID in an `aria-describedby` attribute on the main element.

```html
<h1 aria-describedby="messageCount">Unread Messages</h1>
<span class="badge" id="messageCount">1</span>
```

Finally, the content itself might need more context for users that use screen readers. You can add extra text inside the badge using the `.show-for-sr` class.

```html
<span class="badge" id="messageCount">1 <span class="show-for-sr">unread message</span></span>
```

---

## Coloring

Add color classes to give badges additional meaning.

<p>
  <a class="" data-open-video="2:05"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/MmXxWm?editors=1100" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<span class="badge primary">1</span>
<span class="badge secondary">2</span>
<span class="badge success">3</span>
<span class="badge alert">A</span>
<span class="badge warning">B</span>
```

---

### Custom Colors

If you're using the Sass version of Foundation, you can customize the badge classes by editing the `$badge-palette` map in your settings file. The badge palette defaults to `$foundation-palette`.

If you don't need certain colors from the default palette, simply remove them from the list.

```scss
$badge-palette: map-remove($foundation-palette, (
    primary,
    secondary
)) !default;
```

Or you can add more colors to the default palette.

```scss
$badge-palette: map-merge($foundation-palette, (
    purple: #bb00ff
)) !default;
```

Or you can define your own custom badge palette.

```scss
$badge-palette: (
    black: #000000,
    red: #ff0000,
    purple: #bb00ff
) !default;
```

---

### Text Colors

The text color for each badge class is determined by either `$badge-color` or `$badge-color-alt`, whichever settings variable has more contrast.

<div class="primary callout">
  <p>The default settings meet WCAG 2.0 level AA contrast requirements. Be sure to [check the contrast](https://webaim.org/resources/contrastchecker/) when changing color variables. To give all badges the same color text, set `$badge-color` and `$badge-color-alt` to the same value &mdash; but know that doing so may decrease accessibility.</p>
</div>

---

## Icons

An icon can be used in place of text. We're using the [Foundation icon font](https://zurb.com/playground/foundation-icon-fonts-3) here, but any icon fonts or image-based icons will work fine.

<p>
  <a class="" data-open-video="0:39"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/jmKJXa?editors=1100" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<span class="badge secondary"><i class="fi-share"></i></span>
<span class="badge success"><i class="fi-check"></i></span>
<span class="badge warning"><i class="fi-wrench"></i></span>
```
