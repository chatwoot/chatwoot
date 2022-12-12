---
title: Reveal
description: Modal dialogs, or pop-up windows, are handy for prototyping and production. Foundation includes Reveal, our jQuery modal plugin, to make this easy for you.
sass: scss/components/_reveal.scss
js: js/foundation.reveal.js
video: vnT3bp07iHI
mui: true
tags:
  - modal
---


<div class="callout training-callout">
  <p>We hope you’re loving these free documentation videos! If you’d like to really accelerate your learning and master the world of front-end development, our Foundation online webinar training is the answer.</p>
  <a href="http://zurb.com/university/courses" target="_blank">See the upcoming Foundation trainings →</a>
</div>

## Basics

A modal is just an empty container, so you can put any kind of content inside it, from text to forms to video to an entire grid.

<div class="callout primary">
  <p>Please note that we removed the option for AJAX loaded modals in Foundation 6. We did make it very easy to implement on your own though, check out a sample in the <span><a href="#advanced-options">Advanced</a></span> section.</p>
</div>

To create a modal, add the class `.reveal`, the attribute `data-reveal`, and a unique ID to a container.

<p>
  <a class="" data-open-video="0:36"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/RVyBPw?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<div class="reveal" id="exampleModal1" data-reveal>
  <h1>Awesome. I Have It.</h1>
  <p class="lead">Your couch. It is mine.</p>
  <p>I'm a cool paragraph that lives inside of an even cooler modal. Wins!</p>
  <button class="close-button" data-close aria-label="Close modal" type="button">
    <span aria-hidden="true">&times;</span>
  </button>
</div>
```

You'll also need a way to open the modal. Add the attribute `data-open` to any element. The value of `data-open` should be the ID of the modal.

```html_example
<p><button class="button" data-open="exampleModal1">Click me for a modal</button></p>
```

You'll also need a way to *close* the modal from inside. By default, modals will close if clicked outside of, or if the <kbd>esc</kbd> key is pressed. However, you'll generally also want to add your own click trigger. Add the attribute `data-close` to any element within the modal to add one.

You can use our handy [close button](close-button.html) styles to do this:

```html
<button class="close-button" data-close aria-label="Close modal" type="button">
  <span aria-hidden="true">&times;</span>
</button>
```

---

## Sizing

On small screens, a modal is always 100% of the width of the screen. On medium-sized screens and larger, the width changes to 600px (see the `$reveal-width` setting).

The size of a modal can be changed with these sizing classes, which are added to the modal container:

- `.tiny`: 30% wide
- `.small`: 50% wide
- `.large`: 90% wide
- `.full`: 100% width *and* height, defaults the `escClose` option to true, as well as creates a close button.

<p>
  <a class="" data-open-video="3:38"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/eWKQer?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html
<div class="tiny reveal" id="exampleModal" data-reveal>
  <!-- ... -->
</div>
```

<p><button class="button" data-toggle="exampleModal5" aria-controls="exampleModal5">Click me for a tiny modal</button></p>

<div class="tiny reveal" id="exampleModal5" data-reveal>
  <p>OH I'M SO TIIINY</p>
  <button class="close-button" data-close aria-label="Close reveal" type="button">
    <span aria-hidden="true">&times;</span>
  </button>
</div>

<p><button class="button" data-toggle="exampleModal6">Click me for a small modal</button></p>

<div class="small reveal" id="exampleModal6" data-reveal>
  <p>I may be small, but I've got a big heart!</p>
  <button class="close-button" data-close aria-label="Close reveal" type="button">
    <span aria-hidden="true">&times;</span>
  </button>
</div>

<p><button class="button" data-toggle="exampleModal7">Click me for a large modal</button></p>

<div class="large reveal" id="exampleModal7" data-reveal>
  <p>I'm big, like bear!</p>
  <button class="close-button" data-close aria-label="Close reveal" type="button">
    <span aria-hidden="true">&times;</span>
  </button>
</div>

---

## Nested Modal

It's possible for modals to open other modals. Create a second modal with a unique ID, and then add a click trigger with `data-open` inside the first modal.

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/PmaxBz?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<p><button class="button" data-open="exampleModal2">Click me for a modal</button></p>

<!-- This is the first modal -->
<div class="reveal" id="exampleModal2" data-reveal>
  <h1>Awesome!</h1>
  <p class="lead">I have another modal inside of me!</p>
  <button class="button" data-open="exampleModal3">Click me for another modal!</button>
  <button class="close-button" data-close aria-label="Close reveal" type="button">
    <span aria-hidden="true">&times;</span>
  </button>
</div>

<!-- This is the nested modal -->
<div class="reveal" id="exampleModal3" data-reveal>
  <h2>ANOTHER MODAL!!!</h2>
  <button class="close-button" data-close aria-label="Close reveal" type="button">
    <span aria-hidden="true">&times;</span>
  </button>
</div>
```

---

## Full-screen

A full-screen modal is 100% of the width *and* height of the window. Add the `.full` class to make it go.

<p>
  <a class="" data-open-video="4:58"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/mmKQQV?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<p><button class="button" data-toggle="exampleModal8">Click me for a full-screen modal</button></p>

<div class="full reveal" id="exampleModal8" data-reveal>
  <p>OH I'M SO FUUUUL</p>
  <img src="https://placekitten.com/1920/1280" alt="Introspective Cage">
  <button class="close-button" data-close aria-label="Close reveal" type="button">
    <span aria-hidden="true">&times;</span>
  </button>
</div>
```

## Advanced Options

### No Overlay

To remove the overlay, add the attribute `data-overlay="false"` to the modal.

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/vmrQwL?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<p><button class="button" data-toggle="exampleModal9">Click me for an overlay-lacking modal</button></p>

<div class="reveal" id="exampleModal9" data-reveal data-overlay="false">
  <p>I feel so free!</p>
  <button class="close-button" data-close aria-label="Close reveal" type="button">
    <span aria-hidden="true">&times;</span>
  </button>
</div>
```

---

### Animations

To use animations from the Motion UI library, include the <code>data-animation-in="someAnimationIn"</code> and <code>data-animation-out="someAnimationOut"</code> attributes. If you want to adjust the speed or timing, include it the attributes like <code>data-animation-in="someAnimationIn fast"</code>.

<p>
  <a class="" data-open-video="5:40"><img src="{{root}}assets/img/icons/watch-video-icon.svg" class="video-icon" height="30" width="30" alt=""> Watch this part in video</a>
</p>

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/ZKRVeP?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<p><button class="button" data-toggle="animatedModal10">Click me for a modal</button></p>

<div class="reveal" id="animatedModal10" data-reveal data-close-on-click="true" data-animation-in="spin-in" data-animation-out="spin-out">
  <h1>Whoa, I'm dizzy!</h1>
  <p class="lead">There are many options for animating modals, check out the Motion UI library to see them all</p>
  <button class="close-button" data-close aria-label="Close reveal" type="button">
    <span aria-hidden="true">&times;</span>
  </button>
</div>
```

---

### AJAX

To use AJAX to load your modal content, use the code snippet below.

```js
var $modal = $('#modal');

$.ajax('/url')
  .done(function(resp){
    $modal.html(resp).foundation('open');
});
```


---

## Accessibility

Modals by default are accessible through the use of various ARIA attributes.  To make a modal even more accessible, designate a label to the modal by adding `aria-labelledby="exampleModalHeader11"` to the container and `id="exampleModalHeader11"` to the element you want to designate as the label.

<div class="docs-codepen-container">
  <a class="codepen-logo-link" href="https://codepen.io/IamManchanda/pen/RVJEBZ?editors=1000" target="_blank"><img src="{{root}}assets/img/logos/edit-in-browser.svg" class="" height="" width="" alt="edit on codepen button"></a>
</div>

```html_example
<p><button class="button" data-open="exampleModal11">Click me for a modal</button></p>

<div class="reveal" id="exampleModal11" aria-labelledby="exampleModalHeader11" data-reveal>
  <h1 id="exampleModalHeader11">Label for the Modal!</h1>
  <p class="lead">I am even more accessible than the other modals.</p>
  <button class="close-button" data-close aria-label="Close Accessible Modal" type="button">
    <span aria-hidden="true">&times;</span>
  </button>
</div>
```
