---
title: Interchange
description: Interchange uses media queries to dynamically load responsive content that is appropriate for the user's device.
js: js/foundation.interchange.js
video: '1Nr12_1rUpo'

---

## Use with Images

Bandwidth is precious on mobile networks, so it helps to serve users on smaller screens a smaller image. Using Interchange, you can serve up specific images for users depending on their screen size. CSS media queries are used to determine what size the user's device is, and which image should be served.

In the below example, we have three different sizes of image: one for small screens, one for medium, and one for large. Use the below format to set up a responsive image. The image will change automatically as the browser resizes.

<p>
  <a class="" data-open-video="0:50"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="https://codepen.io/ZURBFoundation/pen/JNZQGB?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html
<img data-interchange="[assets/img/interchange/small.jpg, small], [assets/img/interchange/medium.jpg, medium], [assets/img/interchange/large.jpg, large]">
```

<img data-interchange="[assets/img/interchange/small.jpg, small], [assets/img/interchange/medium.jpg, medium], [assets/img/interchange/large.jpg, large]">

The image set is a comma-separated list of items with this format:

```
[image_path, media_query]
```

`image_path` can be a relative or absolute path. `media_query` can be any CSS media query, or a Foundation breakpoint&mdash;see [Named Media Queries](#named-media-queries) below.

<div class="callout primary">
  <p>Interchange evaluates rules in order, and the last rule to match will be used. For this reason, you should order your rules from smallest screen to largest screen.</p>
</div>

---

## Use with HTML

Interchange can also swap in and out entire chunks of HTML. This allows you to load in mobile-friendly components on small screens, or more advanced versions on large screens.

In the below example, we've applied `data-interchange` to a `<div>` instead of an `<img>` element, and the paths are to HTML files instead of images.

```html
<div data-interchange="[assets/partials/interchange-default.html, small], [assets/partials/interchange-medium.html, medium], [assets/partials/interchange-large.html, large]"></div>
```

<div id="docs-example-interchange" data-interchange="[assets/partials/interchange-default.html, small], [assets/partials/interchange-medium.html, medium], [assets/partials/interchange-large.html, large]"></div>

---

## Use with Background Images

When using Interchange on a non-`<img>` element, you can pass in an image path instead of an HTML path, and the element's `background-image` property will be set to the path of the matching rule.

```html
<div data-interchange="[assets/img/interchange/small.jpg, small], [assets/img/interchange/medium.jpg, medium], [assets/img/interchange/large.jpg, large]"></div>
```

---

## Named Media Queries

Interchange supports named queries as shorthands for full CSS media queries. Any breakpoint defined in the `$breakpoints` variable in your Sass will work, along with a few other keywords. [Learn more about changing the default breakpoints.](media-queries.html)

Query Name | Media Query
-----------|------------
small      | `screen and (min-width: 0em)`
medium     | `only screen and (min-width: 40em)`
large      | `only screen and (min-width: 64em)`
xlarge     | `only screen and (min-width: 75em)`
xxlarge    | `only screen and (min-width: 90em)`
portrait   | `screen and (orientation: portrait)`
landscape  | `screen and (orientation: landscape)`
retina     | `only screen and (-webkit-min-device-pixel-ratio: 2), only screen and (min--moz-device-pixel-ratio: 2), only screen and (-o-min-device-pixel-ratio: 2/1), only screen and (min-device-pixel-ratio: 2), only screen and (min-resolution: 192dpi), only screen and (min-resolution: 2dppx)`

To add your own named media queries, add them as properties to `Foundation.Interchange.SPECIAL_QUERIES`.

```js
Foundation.Interchange.SPECIAL_QUERIES['square'] = 'screen and (aspect-ratio: 1/1)';
```

---

## Programmatic Use

When using Interchange programmatically, you need to pass in your ruleset in the `options` object, as well as the *container* element, *not* the content elements, like so:

```js
var $photoFrame = $('#some-container');
var interchange = new Foundation.Interchange($photoFrame, {
  rules: [
    "[path/to/default.jpg, small]", 
    "[path/to/medium.jpg, medium]",
    "[path/to/large.jpg, large]"
  ]
 });
```
