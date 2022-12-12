---
title: Slider
description: This handy lil slider is perfect for setting specific values within a range.
sass: scss/components/_slider.scss
js: js/foundation.slider.js
video: 'i_BTQiXBvhU'
tags:
  - range
---

## Basics

Create a slider by adding the class `.slider` and the attribute `data-slider` to a container element. You should also define both a starting and maximum value for the slider.

Inside the container are three elements:
- The handle (`.slider-handle`), which the user drags.
- The fill (`.slider-fill`), which resizes dynamically based on where the handle is.
- A hidden `<input>`, which is where the value of the slider is stored.

The `data-initial-start=""` value is where along the slider the handle starts. The `data-end=""` is the maximum value for the slider. In the below example, starting at 50 of 200 means the slider handle will start at 25% of the total.

<p>
  <a class="" data-open-video="1:00"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="https://codepen.io/ZURBFoundation/pen/MmGpWR?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<div class="slider" data-slider data-initial-start="50" data-end="200">
  <span class="slider-handle"  data-slider-handle role="slider" tabindex="1"></span>
  <span class="slider-fill" data-slider-fill></span>
  <input type="hidden">
</div>
```

---

## Vertical

To get *vertical*, just add a `.vertical` class and `data-vertical="true"` the slider.

<p>
  <a class="" data-open-video="3:24"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="https://codepen.io/ZURBFoundation/pen/eWrvRm?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<div class="slider vertical" data-slider data-initial-start="25" data-end="200" data-vertical="true">
  <span class="slider-handle" data-slider-handle role="slider" tabindex="1"></span>
  <span class="slider-fill" data-slider-fill></span>
  <input type="hidden">
</div>
```

---

## Disabled

Add the class `.disabled` to disable interaction with the slider.

<div class="docs-codepen-container">
<a class="codepen-logo-link" href="https://codepen.io/ZURBFoundation/pen/aWjqVJ?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<div class="slider disabled" data-slider data-initial-start="78">
  <span class="slider-handle" data-slider-handle role="slider" tabindex="1"></span>
  <span class="slider-fill" data-slider-fill></span>
  <input type="hidden">
</div>
```

---

## Two Handles

Two-handle sliders can be used to define a range of values, versus a single value. To make a two-handle slider, add a second handle, and a second `<input>`. This works with horizontal and vertical sliders.

You can add IDs to the `<input>`s inside the sliders to make it easier to access the values. If you don't, the plugin will add an ID to each for you.

Note that the first handle manipulates the first `<input>`, while the second handle manipulates the second `<input>`.

<p>
  <a class="" data-open-video="8:18"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="https://codepen.io/ZURBFoundation/pen/oWdwdX?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<div class="slider" data-slider data-initial-start="25" data-initial-end="75">
  <span class="slider-handle" data-slider-handle role="slider" tabindex="1"></span>
  <span class="slider-fill" data-slider-fill></span>
  <span class="slider-handle" data-slider-handle role="slider" tabindex="1"></span>
  <input type="hidden">
  <input type="hidden">
</div>
```

---

## Data Binding

Data binding allows you to connect the slider to an external `<input>` field. With data binding set up, dragging the handle will change the value inside the text field, and editing the number in the text field will move the slider in real-time.

To set it all up, create an `<input>` with an ID and add `aria-controls="id"` to the slider handle, where `id` is the ID of the `<input>`.

<p>
  <a class="" data-open-video="4:56"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="https://codepen.io/ZURBFoundation/pen/dWeRRy?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<div class="grid-x grid-margin-x">
  <div class="cell small-10">
    <div class="slider" data-slider data-initial-start="50">
      <span class="slider-handle"  data-slider-handle role="slider" tabindex="1" aria-controls="sliderOutput1"></span>
      <span class="slider-fill" data-slider-fill></span>
    </div>
  </div>
  <div class="cell small-2">
    <input type="number" id="sliderOutput1">
  </div>
</div>
```

---

Or with a step size:

```html_example
<div class="grid-x grid-margin-x">
  <div class="cell small-10">
    <div class="slider" data-slider data-initial-start="50" data-step="5">
      <span class="slider-handle"  data-slider-handle role="slider" tabindex="1" aria-controls="sliderOutput2"></span>
      <span class="slider-fill" data-slider-fill></span>
    </div>
  </div>
  <div class="cell small-2">
    <input type="number" id="sliderOutput2">
  </div>
</div>
```
---

## Native Range Slider

In Foundation 6.2, we introduced styles for `<input type="range">`, the native HTML element for range sliders. It's not supported in every browser, namely IE9 and some older mobile browsers. [View browser support for the range input type.](http://caniuse.com/#feat=input-range)

<p>
  <a class="" data-open-video="10:05"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="https://codepen.io/ZURBFoundation/pen/GmdEem?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<input type="range" min="1" max="100" step="1">
```

If you're using the Sass version of Foundation, add this line to your main Sass file:

```scss
@include foundation-range-input;
```

It's possible to use both the JavaScript slider and the native slider in the same codebase, as the CSS selectors used don't overlap. Here's what's different about the native slider:

- Less markup: just write `<input type="range">` and you're good.
- No JavaScript is needed, which guarantees it runs faster in most browsers.
- To disable the slider, add `disabled` as an attribute, instead of a class.
- No support for vertical orientation.
- No support for two handles.

---

## Non-linear value translation

Sometimes not every value is of equal importance. In the example below, the slider focusses on the higher numbers by adding a `log`-type position value function.
Alternatively there is also a `pow`-type position value function available, making the reverse possible.

The nonLinearBase-option is optional and defaults to 5.

```html_example
<div class="grid-x grid-margin-x">
  <div class="cell small-10">
    <div class="slider" data-slider data-initial-start="50" data-step="1" data-position-value-function="log" data-non-linear-base="5">
      <span class="slider-handle" data-slider-handle role="slider" tabindex="1" aria-controls="sliderOutputNonLinear"></span>
    </div>
  </div>
  <div class="cell small-2">
    <input type="number" id="sliderOutputNonLinear">
  </div>
</div>
```

## Reflow

The slider takes into account the width of the handles when calculating how to display itself. This means that if the slider is initially hidden, or hidden while the value is adjusted, the resulting visual will be slightly different because the width of the handle is indeterminate.  If this is problematic, you can use JavaScript to cause the slider to reflow at the time that you change it from being hidden.  Example:

```js
$('#my-slider').show();
$('#my-slider').foundation('_reflow');
```
