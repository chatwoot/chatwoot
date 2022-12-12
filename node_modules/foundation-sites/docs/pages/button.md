---
title: Button
description: Buttons are convenient tools when you need more traditional actions. To that end, Foundation has many easy to use button styles that you can customize or override to fit your needs.
video: iEAtuFk4-LQ
sass: scss/components/_button.scss
tags:
  - dropdown button
---

<div class="callout training-callout">
  <p>To help you get the most out of Foundation and create responsive websites and apps like us we’ve put together some unique online webinar training. Learn Foundation’s Grid, how to use and modify Foundation's UI components, Foundation’s JavaScript options and functions, and tons of tips and tricks we learned from major client projects.</p>
  <a href="http://zurb.com/university/foundation-intro" target="_blank">Learn more about Foundation training →</a>
</div>

## Basics

A basic button can be created with minimal markup. Because buttons can be used for many purposes, it's important to use the right tag.

- Use the `<a>` tag if the button is a link to another page, or a link to an anchor within a page. Generally anchors don't require JavaScript to work.
- Use the `<button>` tag if the button performs an action that changes something on the current page. `<button>` elements almost always require JavaScript to function.

<a class="" data-open-video="0:34"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
<div class="primary callout">
  <p>Add the attribute <code>type="button"</code> to <code>&lt;button&gt;</code> elements, unless the button submits a form, in which case you use <code>type="submit"</code></p>
</div>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="http://codepen.io/ZURBFoundation/pen/wdmZME?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<!-- Anchors (links) -->
<a href="about.html" class="button">Learn More</a>
<a href="#features" class="button">View All Features</a>

<!-- Buttons (actions) -->
<button type="button" class="success button">Save</button>
<button type="button" class="alert button">Delete</button>
```

---

## Sizing

Additional classes can be added to your button to change its size and shape.

<p>
  <a class="" data-open-video="3:23"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="http://codepen.io/ZURBFoundation/pen/JNLVRb?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<a class="button tiny" href="#">So Tiny</a>
<a class="button small" href="#">So Small</a>
<a class="button" href="#">So Basic</a>
<a class="button large" href="#">So Large</a>
<a class="button expanded" href="#">Such Expand</a>
<a class="button small expanded" href="#">Wow, Small Expand</a>
```

### Responsive Expanded buttons

If you are using the Sass version, you can activate these additional responsive button expand classes by changing the `$button-responsive-expanded` variable to true. (It is false by default to reduce CSS file size.)

For CSS download users, you can [get the CSS here](https://gist.github.com/rafibomb/2497ca75ceedfa3f5ccf3ba146eae295) and add it to your stylesheet.

```html_example
<a class="button small small-only-expanded" href="#">Wow, Expand only on small viewport</a>
<a class="button small medium-only-expanded" href="#">Expand only on medium viewport</a>
<a class="button small large-only-expanded" href="#">Expand only on large viewport</a>

<a class="button small medium-expanded" href="#">Wow, Expand on medium and larger</a>
<a class="button small large-expanded" href="#">Expand on large and larger</a>

<a class="button small medium-down-expanded" href="#">Expand on medium and smaller</a>
<a class="button small large-down-expanded" href="#">Expand on large and smaller</a>
```

---

## Coloring

Add color classes to give buttons additional meaning.

<p>
  <a class="" data-open-video="5:41"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>


<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/ZKjxOy?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<a class="button primary" href="#">Primary</a>
<a class="button secondary" href="#">Secondary</a>
<a class="button success" href="#">Success</a>
<a class="button alert" href="#">Alert</a>
<a class="button warning" href="#">Warning</a>
```

---

### Custom Colors

If you're using the Sass version of Foundation, you can customize the button classes by editing the `$button-palette` map in your settings file. The button palette defaults to `$foundation-palette`.

If you don't need certain colors from the default palette, simply remove them from the list.

```scss
$button-palette: map-remove($foundation-palette, (
    primary,
    secondary
)) !default;
```

Or you can add more colors to the default palette.

```scss
$button-palette: map-merge($foundation-palette, (
    purple: #bb00ff
)) !default;
```

Or you can define your own custom button palette.

```scss
$button-palette: (
    black: #000000,
    red: #ff0000,
    purple: #bb00ff
) !default;
```

---

### Text Colors

The text color for each button class is determined by either `$button-color` or `$button-color-alt`, whichever settings variable has more contrast.

<div class="primary callout">
  <p>The default settings meet WCAG 2.0 level AA contrast requirements. Be sure to [check the contrast](http://webaim.org/resources/contrastchecker/) when changing color variables. To give all buttons the same color text, set `$button-color` and `$button-color-alt` to the same value &mdash; but know that doing so may decrease accessibility.</p>
</div>

---

## Hollow Style

Add the `.hollow` class to a button to give it a hollow style. Change the `$button-fill` variable in your settings file to `hollow` to make this the default style. Changing this setting will remove the `.hollow` class from your CSS.

```html_example
<button class="hollow button" href="#">Primary</button>
<button class="hollow button secondary" href="#">Secondary</button>
<button class="hollow button success" href="#">Success</button>
<button class="hollow button alert" href="#">Alert</button>
<button class="hollow button warning" href="#">Warning</button>
<button class="hollow button" href="#" disabled>Disabled</button>
```

---

## Disabled Buttons

The `.disabled` class will give buttons a faded appearance. The class is a purely visual style, and won't actually disable a control. For `<button>` elements, you can add the `disabled` attribute to both disable and style it. If you want to disable a link, you should add the `aria-disabled` attribute to mark it as disabled for assistive technology.

<p>
  <a class="" data-open-video="8:32"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-video-codepen-container">
  <a class="codepen-logo-link" href="http://codepen.io/ZURBFoundation/pen/xdjVOp?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<a class="button disabled" href="#" aria-disabled>Disabled</a>
<button type="button" class="button primary" disabled>Disabled</button>
<button type="button" class="button secondary" disabled>Disabled</button>
<button type="button" class="button success" disabled>Disabled</button>
<button type="button" class="button alert" disabled>Disabled</button>
<button type="button" class="button warning" disabled>Disabled</button>
```

Alternatively, you can also use disabled hollow buttons.

```html_example
<a class="button hollow disabled" href="#" aria-disabled>Disabled</a>
<button type="button" class="button hollow primary" disabled>Disabled</button>
<button type="button" class="button hollow secondary" disabled>Disabled</button>
<button type="button" class="button hollow success" disabled>Disabled</button>
<button type="button" class="button hollow alert" disabled>Disabled</button>
<button type="button" class="button hollow warning" disabled>Disabled</button>
```

---

## Clear Style

Add the `.clear` class to a button to give it a clear style. Change the `$button-fill` variable in your settings file to `clear` to make this the default style. Changing this setting will remove the `.clear` class from your CSS.

<p>
  <a class="" data-open-video="7:37"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>


<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="http://codepen.io/ZURBFoundation/pen/LymNyB?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<a class="clear button" href="#">Primary</a>
<a class="clear button secondary" href="#">Secondary</a>
<a class="clear button success" href="#">Success</a>
<a class="clear button alert" href="#">Alert</a>
<a class="clear button warning" href="#">Warning</a>
<a class="clear button" href="#" disabled>Disabled</a>
```

<p>This is especially useful as a secondary action button. This way you get proper spacing and line-height. Example:</p>

<button class="button primary" href="#">Primary Action</button>
<button class="clear button" href="#">Secondary Action</button>


---

## Dropdown Arrows

Add a dropdown arrow to your button with the `.dropdown` class.

<div class="primary callout">
  <p>This doesn't add dropdown functionality automatically. To do that, you can attach our <a href="dropdown.html">Dropdown plugin</a>.</p>
</div>

<div class="docs-codepen-container">
<a class="codepen-logo-link" href="http://codepen.io/ZURBFoundation/pen/PmeNOY?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<button class="dropdown button tiny">Dropdown Button</button>
<button class="dropdown button small">Dropdown Button</button>
<button class="dropdown button">Dropdown Button</button>
<button class="dropdown button large">Dropdown Button</button>
<button class="dropdown button expanded">Dropdown Button</button>
```

---

## Accessibility

Make sure that the text of the button is descriptive. If for some reason, your button contains no readable text (for example, just a symbol or icon), add screen reader-only text to the button to clarify its purpose. The symbol or icon should be wrapped in an element with the attribute `aria-hidden="true"`, to prevent screen readers from trying to pronounce the symbol.

Use the `.show-for-sr` class to define screen reader-only text.

```html_example
<button class="button" type="button">
  <!-- Screen readers will see "close" -->
  <span class="show-for-sr">Close</span>
  <!-- Visual users will see the X, but not the "Close" text -->
  <span aria-hidden="true"><i class="fi-x"></i></span>
</button>
```
