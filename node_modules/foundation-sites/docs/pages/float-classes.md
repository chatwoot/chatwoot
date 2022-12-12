---
title: Float Classes
description: Foundation includes a handful of helpful float classes to add common positioning behaviors to elements.
video: 'VEzXdMmqhAY'
---

## Float Left/Right

You can change the float behavior of an element by adding the `.float-left` or `.float-right` classes to an element. To clear floats, add the class `.clearfix` to the parent element.

<div class="callout primary">
  <p>Float Left/Right classes use `!important` to ensure they aren't overridden by more specific selectors. This framework conscientiously avoids using `!important` declarations. This is one of the few components that does.</p>
</div>

<div class="callout warning">
  <p>Float classes don't flip direction in a <a href="rtl.html">right-to-left</a> environment&mdash;<code>left</code> always means left, and <code>right</code> always means right.</p>
</div>

```html_example
<div class="callout clearfix">
  <a class="button float-left">Left</a>
  <a class="button float-right">Right</a>
</div>
```

---

## Float Center

Okay, it's not *really* a float, but you can add the `.float-center` class to an element to engage the automatic margin centering trick. Note that this will only work on elements with an absolute width, which means not a percentage or `auto` width.

```html_example
<img src="assets/img/generic/voyager.jpg" class="float-center">
```
