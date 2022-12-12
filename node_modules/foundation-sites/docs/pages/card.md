---
title: Card
description: Cards are a popular and flexible UI component.
video: 'OMwg8UsrLrM'
sass: scss/components/_card.scss
tags:
  - card
flex: true
---

## Basics

A card is just an element with a `.card` class applied. You can put any kind of content inside.
Make sure you wrap your content in a `.card-section` element in order to achieve the traditional card look.

A card container has no padding, allowing you to place full-bleed images inside. Use the `.card-divider` and `.card-section` classes to sub-divide a card.

<p>
  <a class="" data-open-video="0:32"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="https://codepen.io/ZURBFoundation/pen/oWMEpo?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<div class="card" style="width: 300px;">
  <div class="card-divider">
    This is a header
  </div>
  <img src="assets/img/generic/rectangle-1.jpg">
  <div class="card-section">
    <h4>This is a card.</h4>
    <p>It has an easy to override visual style, and is appropriately subdued.</p>
  </div>
</div>
```

<div class="alert callout">
  <p><strong>Browser Bug (IE 11 - Flexbug): </strong>On IE 11, when using the card with image, you may see a lot of whitespace under each image that happens to match the original image size. The bug can be reproduced <a href="https://codepen.io/IamManchanda/pen/MmNqEX?editors=1100">here</a> on an IE11 browser. Use <code>.card-image</code> class to wrap your image to resolve this.</p>
</div>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/aWrWQq?editors=1100" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html
<div class="card-image">
  <img src="assets/img/generic/rectangle-1.jpg">
</div>
```

---

### Card Divider

You can also include a `.card-divider` element as a title, footer or to break up content.

<p>
  <a class="" data-open-video="1:30"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/PmyPbL?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<div class="card" style="width: 300px;">
  <div class="card-divider">
    <h4>I'm featured</h4>
  </div>
  <img src="assets/img/generic/rectangle-1.jpg">
  <div class="card-section">
    <p>This card makes use of the card-divider element.</p>
  </div>
</div>
```

---

### Images

Images play nicely with cards. Simply include one outside of the `.card-section` element to span nicely to the edges. Or move the image inside the `.card-section` to have padding around the image.

<p>
  <a class="" data-open-video="2:12"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="https://codepen.io/ZURBFoundation/pen/QvBQvR?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html
<!-- image has no padding -->
<div class="card">
  <img src="assets/img/generic/rectangle-1.jpg">
  <div class="card-section">
    <p>This is a simple card with an image.</p>
  </div>
</div>

<!-- image has padding -->
<div class="card">
  <div class="card-section">
    <img src="assets/img/generic/rectangle-1.jpg">
  </div>
  <div class="card-section">
    <p>This is a simple card with an image inside a `.card-section`.</p>
  </div>
</div>
```

<div class="grid-x grid-margin-x small-up-3">
  <div class="cell">
    <div class="card">
      <img src="assets/img/generic/rectangle-1.jpg">
      <div class="card-section">
        <p>This is a simple card with an image.</p>
      </div>
    </div>
  </div>
  <div class="cell">
    <div class="card">
      <div class="card-section">
        <img src="assets/img/generic/rectangle-1.jpg">
      </div>
      <div class="card-section">
        <p>This is a simple card with an image inside a `.card-section`.</p>
      </div>
    </div>
  </div>
</div>

```html
<div class="card">
  <div class="card-section">
    <p>Images work just fine below the content too!</p>
  </div>
  <img src="assets/img/generic/rectangle-1.jpg">
</div>
```

<div class="grid-x grid-margin-x small-up-3">
  <div class="cell">
    <div class="card">
      <div class="card-section">
        <p>Images work just fine below the content too!</p>
      </div>
      <img src="assets/img/generic/rectangle-1.jpg">
    </div>
  </div>
</div>

---

## Sizing

You can either set the width of cards with custom css or add them into the Foundation grid.

<p>
  <a class="" data-open-video="0:34"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="http://codepen.io/ZURBFoundation/pen/PmabmL?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<div class="grid-container">
  <div class="grid-x grid-padding-x small-up-2 medium-up-3">
    <div class="cell">
      <div class="card">
        <img src="assets/img/generic/rectangle-1.jpg">
        <div class="card-section">
        <h4>This is a row of cards.</h4>
          <p>This row of cards is embedded in an X-Y Block Grid.</p>
        </div>
      </div>
    </div>
    <div class="cell">
      <div class="card">
        <img src="assets/img/generic/rectangle-1.jpg">
        <div class="card-section">
          <h4>This is a card.</h4>
          <p>It has an easy to override visual style, and is appropriately subdued.</p>
        </div>
      </div>
    </div>
    <div class="cell">
      <div class="card">
        <img src="assets/img/generic/rectangle-1.jpg">
        <div class="card-section">
          <h4>This is a card.</h4>
          <p>It has an easy to override visual style, and is appropriately subdued.</p>
        </div>
      </div>
    </div>
  </div>
</div>
<div class="grid-x grid-padding-x small-up-2 medium-up-3">
  <div class="cell">
    <div class="card">
      <img src="assets/img/generic/rectangle-1.jpg">
      <div class="card-section">
        <h4>This is a row of cards.</h4>
        <p>This row of cards is embedded in an Flex Block Grid.</p>
      </div>
    </div>
  </div>
  <div class="cell">
    <div class="card">
      <img src="assets/img/generic/rectangle-1.jpg">
      <div class="card-section">
        <h4>This is a card.</h4>
        <p>It has an easy to override visual style, and is appropriately subdued.</p>
      </div>
    </div>
  </div>
  <div class="cell">
    <div class="card">
      <img src="assets/img/generic/rectangle-1.jpg">
      <div class="card-section">
        <h4>This is a card.</h4>
        <p>It has an easy to override visual style, and is appropriately subdued.</p>
      </div>
    </div>
  </div>
</div>
```
