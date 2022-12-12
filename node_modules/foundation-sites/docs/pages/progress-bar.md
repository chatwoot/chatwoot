---
title: Progress Bar
description: Show your progress. A simple way to add progress bars to your layouts. You only need two HTML elements to make them and they're easy to customize.
video: gMLSHzlshpM
sass:
  - scss/components/_progress-bar.scss
  - scss/forms/_progress.scss
  - scss/forms/_meter.scss
---

## Basics

A progress bar has two elements: the container `.progress`, and the meter `.progress-meter`. The `role` and `aria-` attributes in the code example clarify the status of the bar:

- `aria-valuemin`: Minimum value.
- `aria-valuemax`: Maximum value.
- `aria-valuenow`: Current value.

If the value of the progress bar is not numeric, also add the attribute `aria-valuetext`, which should include a human-readable version of the bar's value.

<p>
  <a class="" data-open-video="0:39"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="http://codepen.io/ZURBFoundation/pen/PmBqPB?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<div class="progress" role="progressbar" tabindex="0" aria-valuenow="0" aria-valuemin="0" aria-valuemax="100">
  <div class="progress-meter"></div>
</div>
```

Add a `width` CSS property to the inner meter to fill the progress bar.

```html_example
<div class="progress" role="progressbar" tabindex="0" aria-valuenow="50" aria-valuemin="0" aria-valuetext="50 percent" aria-valuemax="100">
  <div class="progress-meter" style="width: 50%"></div>
</div>
```

---

## Colors

A progress bar can be styled with the `.secondary`, `.success`, `.warning`, and `.alert` colors.

<p>
  <a class="" data-open-video="3:22"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="http://codepen.io/ZURBFoundation/pen/mmjJPL?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<div class="secondary progress" role="progressbar" tabindex="0" aria-valuenow="25" aria-valuemin="0" aria-valuetext="25 percent" aria-valuemax="100">
  <div class="progress-meter" style="width: 25%"></div>
</div>

<div class="success progress">
  <div class="progress-meter" style="width: 50%"></div>
</div>

<div class="warning progress">
  <div class="progress-meter" style="width: 50%"></div>
</div>

<div class="alert progress">
  <div class="progress-meter" style="width: 75%"></div>
</div>
```

---

## With Text

You can add text inside the meter of a progress bar. Make sure the text you use in the meter is also used in the `aria-valuetext` attribute.

<p>
  <a class="" data-open-video="5:00"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="http://codepen.io/ZURBFoundation/pen/NjBqRm?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<div class="progress" role="progressbar" tabindex="0" aria-valuenow="25" aria-valuemin="0" aria-valuetext="25 percent" aria-valuemax="100">
  <span class="progress-meter" style="width: 25%">
    <p class="progress-meter-text">25%</p>
  </span>
</div>
```

---

## Native Progress

As an alternative to our custom progress bar style, you can also opt to use the native `<progress>` element. It provides a more succinct way to create progress bars, but it's not supported in IE9, and some other older browsers. [View `<progress>` element support.](http://caniuse.com/#feat=progress)

```html_example
<progress max="100" value="75"></progress>
```

If you're using the Sass version of Foundation, add this line to your main Sass file to export the `<progress>` CSS:

```scss
@include foundation-progress-element;
```

The `<progress>` element can be styled with the same coloring classes: `.secondary`, `.success`, `.warning`, and `.alert`.

```html_example
<progress class="secondary" max="100" value="75"></progress>
<progress class="success" max="100" value="75"></progress>
<progress class="warning" max="100" value="75"></progress>
<progress class="alert" max="100" value="75"></progress>
```

---

## Native Meter

For the *extra* adventurous developers out there, we also provide styles for the `<meter>` element. What's the difference? `<progress>` represents a value that changes over time, like storage capacity. `<meter>` represents a value that fluctuates around some optimum value. It also has *no* support in Internet Explorer, Mobile Safari, or Android 2. [View `<meter>` element support.](http://caniuse.com/#search=meter)

If you're using the Sass version of Foundation, add this line to your main Sass file to export the `<meter>` CSS:

```scss
@include foundation-meter-element;
```

The meter automatically colors itself based on the current values, and the defined low, medium, and high ranges. [Learn more about the mechanics of `<meter>` values.](https://developer.mozilla.org/en-US/docs/Web/Guide/HTML/Forms/The_native_form_widgets#Meters_and_progress_bars)

```html_example
<meter value="30" min="0" low="33" high="66" optimum="100" max="100"></meter>
<meter value="50" min="0" low="33" high="66" optimum="100" max="100"></meter>
<meter value="100" min="0" low="33" high="66" optimum="100" max="100"></meter>
```
