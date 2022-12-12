---
title: Visibility Classes
description: Visibility classes let you show or hide elements based on screen size or device orientation. You can also use visibility classes to control which elements users see depending on their browsing environment.
video: 'j__6VmFdSnc'
sass: scss/components/_visibility.scss
tags:
  - hide
  - show
---

<div class="callout primary">
  <p>Visibility classes use `!important` to ensure they aren't overridden by more specific selectors. This framework conscientiously avoids using `!important` declarations. This is one of the few components that does.</p>
</div>

<div class="callout warning">
  <p>There are no classes to detect touchscreen devices, as both desktop and mobile browsers inconsistently report touch support. Learn more here: <a href="http://www.stucox.com/blog/you-cant-detect-a-touchscreen/">You Can't Detect a Touchscreen</a></p>
</div>

## Show by Screen Size

In this example, we use the `.show` visibility classes to show certain strings of text based on the device on which users view a page. If their browser meets the class's conditions, the element will be shown. If not, it will be hidden.

```html_example
<p>You are on a small screen or larger.</p>
<p class="show-for-medium">You are on a medium screen or larger.</p>
<p class="show-for-large">You are on a large screen or larger.</p>
```

These classes automatically hide the element on screen sizes *below* what's specified in the class. So `.show-for-medium` will hide the element on small, and show it on medium and larger.

A separate set of classes allow you to show content *only* on a certain screen size. Just add `-only` to the end of the class.

<div class="primary callout">
  <p>Don't see any text below the code sample? You must be on an *extra* large screen.</p>
</div>

```html_example
<p class="show-for-small-only">You are <em>definitely</em> on a small screen.</p>
<p class="show-for-medium-only">You are <em>definitely</em> on a medium screen.</p>
<p class="show-for-large-only">You are <em>definitely</em> on a large screen.</p>
```

---

## Hide by Screen Size

This example shows the opposite: It uses the `.hide` visibility classes to state which elements should disappear based on the device's screen size.

<div class="primary callout">
  <p>There's no <code>.hide-for-small</code> class, because that would just permanently hide the element. For that, you can use the plain old <code>.hide</code> class instead.</p>
</div>

```html_example
<p class="hide-for-medium">You are <em>not</em> on a medium screen or larger.</p>
<p class="hide-for-large">You are <em>not</em> on a large screen or larger.</p>
```

<p class="show-for-large">If you're reading this, you're on a large screen, and can't see either of the above examples.</p>

Like with `.show`, these classes also have `-only` versions.

```html_example
<p class="hide-for-small-only">You are <em>definitely not</em> on a small screen.</p>
<p class="hide-for-medium-only">You are <em>definitely not</em> on a medium screen.</p>
<p class="hide-for-large-only">You are <em>definitely not</em> on a large screen.</p>
```

### Generic Hide Classes

And if you really just need something hidden no matter what, there are classes for that as well. The `.hide` and `.invisible` classes respectively set `display: none` and `visibility: hidden` on an element. Note that both of these classes hide content from screen readers.

```html
<p class="hide">Can't touch this.</p>
<p class="invisible">Can sort of touch this.</p>
```

---

## Orientation Detection

This straightforward example shows how two strings of text determine whether or not an element is visible in different orientations. This will change on mobile devices when you rotate the device. On desktop, the orientation is almost always reported as landscape.

```html_example
<p class="show-for-landscape">You are in landscape orientation.</p>
<p class="show-for-portrait">You are in portrait orientation.</p>
```

---

## Accessibility

Adding `display: none` to an element will prevent screen readers from reading it. However, there are techniques to hide content while still making it readable by screen readers.

### Show for Screen Readers Only

To visually hide content, while still allowing assistive technology to read it, add the class show-for-sr.

```html_example
<p class="show-for-sr">This text can only be read by a screen reader.</p>
<p>There's a line of text above this one, you just can't see it.</p>
```

### Hide for Screen Readers Only

To hide text from assistive technology, while still keeping it visible, add the attribute `aria-hidden="true"`. This doesn't affect how the element looks, but screen readers will skip over it.

<div class="primary callout">
  <p>It's usually not a good idea to hide content from screen readers. <code>aria-hidden</code> is best used to mask purely visual elements of a page.</p>
</div>

```html_example
<p aria-hidden="true">This text can be seen, but won't be read by a screen reader.</p>
```

### Creating Skip Links

If your site has a lot of navigation, a screen reader will have to read through the entire navigation to get to your site's content. To remedy this, you can add a *skip link* at the very top of your page, which will send the user farther down the page, past the navigation when clicked on.

Use the class `.show-on-focus` to hide an element, except when it has focus. Adding `tabindex="-1"` to the target element makes it focusable. (Or set it to `0` if the user should be able to tab to that element as well. See also [the MDN docs on `tabindex`](https://developer.mozilla.org/en-US/docs/Web/HTML/Global_attributes/tabindex).)

```html_example
<p><a class="show-on-focus" href="#mainContent">Skip to Content</a></p>

<header id="header" role="banner">
</header>

<main id="mainContent" role="main" tabindex="0">
</main>
```
