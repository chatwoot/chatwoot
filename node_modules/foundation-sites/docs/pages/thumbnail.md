---
title: Thumbnail
description: If you're going to use an image as an anchor, we've got you covered. All you gotta do is add one class to your image and voilà!
video: 'BOtW8oacFZk'
sass: scss/components/_thumbnail.scss
---

The `.thumbnail` class can be applied directly to an `<img>` element, or an `<a>` that wraps it. Make sure the `<img>` has an `alt` attribute that describes the contents of the image.

<p>
  <a class="" data-open-video="0:30"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/EmLexY?editors=1100" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html
<img class="thumbnail" src="assets/img/thumbnail/01.jpg" alt="Photo of Uranus.">
<a href="#" class="thumbnail"><img src="assets/img/thumbnail/02.jpg" alt="Photo of Neptune."></a>
<img class="thumbnail" src="assets/img/thumbnail/03.jpg" alt="Photo of Pluto.">
```

<div class="grid-x grid-margin-x">
  <div class="cell small-4 text-center">
    <img class="thumbnail" src="assets/img/thumbnail/01.jpg" alt="Photo of Uranus.">
  </div>
  <div class="cell small-4 text-center">
    <a href="#" class="thumbnail"><img src="assets/img/thumbnail/02.jpg" alt="Photo of Neptune."></a>
  </div>
  <div class="cell small-4 text-center">
    <img class="thumbnail" src="assets/img/thumbnail/03.jpg" alt="Photo of Pluto.">
  </div>
</div>
