---
title: Motion UI
description: A Sass library for creating flexible UI transitions and animations.
library:
  github: https://github.com/zurb/motion-ui
  docs: https://github.com/zurb/motion-ui/tree/master/docs
---

Motion UI is a standalone library that powers the transition effects used in a number of Foundation components, including [Toggler](toggler.html), [Reveal](reveal.html), and [Orbit](orbit.html).

<div class="text-center">
  <button type="button" class="button" data-toggle="motion-header-example">Animate!</button>
  <div data-toggler data-animate="fade-in fade-out" id="motion-header-example" style="display: none;">
    <img src="/assets/img/generic/rectangle-7.jpg" style="width: 100%;">
  </div>
</div>


---

## Installing

**Motion UI is already included in both [starter projects](starter-projects.html).** If you want to add it to an existing project, follow these steps.

First, install the library with npm or Bower.

```bash
npm install motion-ui --save-dev
  bower install motion-ui --save-dev
```

Next, add the path `[modules_folder]/motion-ui/src` to your Sass compiler's import path list. Here's what you would add in Compass, via `config.rb`:

```ruby
add_import_path 'node_modules/motion-ui/src'
```

Here's how it works using gulp-sass:

```js
gulp.src('./src/scss/app.scss')
  .pipe(sass({
    includePaths: ['node_modules/motion-ui/src']
  }));
```

Finally, import the library into your Sass file and include the mixins.

```scss
@import 'motion-ui'
@include motion-ui-transitions;
@include motion-ui-animations;
```

Or, another way to start using Motion UI is through a CDN.

```html
<!-- Insert this within your head tag and after foundation.css -->
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/motion-ui@1.2.3/dist/motion-ui.min.css" />

```

---

## Usage in Components

Various Foundation components provide options for to use Motion UI animations when changing state. Here are the options for each plugin that support Motion UI:
- [Orbit](orbit.html): `data-animate`
- [Reveal](reveal.html): `data-animation-in`, `data-animation-out`
- [Toggler](toggler.html): `data-animate`
- [Responsive Toggler](responsive-navigation.html): `data-animate`

For example, here are two instances of Toggler&mdash;one using fade classes (`.fade-in` and `.fade-out`), and one using slide classes (`.slide-in-down` and `.slide-out-up`). See all available classes in [build-in transitions](#built-in-transitions) below.

```html
<div data-toggler data-animate="fade-in fade-out" class="callout secondary">
  <p>This panel fades.</p>
</div>

<div data-toggler data-animate="slide-in-down slide-out-up" class="callout secondary">
  <p>This panel slides.</p>
</div>
```

<button type="button" class="button" data-toggle="motion-example-1">Fade</button><button type="button" class="button" data-toggle="motion-example-2">Slide</button>
<div class="grid-x grid-margin-x">
  <div class="cell small-6">
    <div data-toggler data-animate="fade-in fade-out" class="callout secondary ease" id="motion-example-1">
      <p>This panel <strong>fades</strong>.</p>
    </div>
  </div>
  <div class="cell small-6">
    <div data-toggler data-animate="slide-in-down slide-out-up" class="callout secondary ease" id="motion-example-2">
      <p>This panel <strong>slides</strong>.</p>
    </div>
  </div>
</div>

---

## Built-in Transitions

Motion UI includes more than two dozen built-in transition classes. They can be enabled by adding this line to your Sass file, after you've imported the library:

```scss
@include motion-ui-transitions;
```

<div>
  <select name="docs-transitions" class="docs-transitions">
    <optgroup label="Slide">
      <option value="slide-in-down">slide-in-down</option>
      <option value="slide-in-left">slide-in-left</option>
      <option value="slide-in-up">slide-in-up</option>
      <option value="slide-in-right">slide-in-right</option>
      <option value="slide-out-down">slide-out-down</option>
      <option value="slide-out-left">slide-out-left</option>
      <option value="slide-out-up">slide-out-up</option>
      <option value="slide-out-right">slide-out-right</option>
    </optgroup>
    <optgroup label="Fade">
      <option value="fade-in">fade-in</option>
      <option value="fade-out">fade-out</option>
    </optgroup>
    <optgroup label="Hinge">
      <option value="hinge-in-from-top">hinge-in-from-top</option>
      <option value="hinge-in-from-right">hinge-in-from-right</option>
      <option value="hinge-in-from-bottom">hinge-in-from-bottom</option>
      <option value="hinge-in-from-left">hinge-in-from-left</option>
      <option value="hinge-in-from-middle-x">hinge-in-from-middle-x</option>
      <option value="hinge-in-from-middle-y">hinge-in-from-middle-y</option>
      <option value="hinge-out-from-top">hinge-out-from-top</option>
      <option value="hinge-out-from-right">hinge-out-from-right</option>
      <option value="hinge-out-from-bottom">hinge-out-from-bottom</option>
      <option value="hinge-out-from-left">hinge-out-from-left</option>
      <option value="hinge-out-from-middle-x">hinge-out-from-middle-x</option>
      <option value="hinge-out-from-middle-y">hinge-out-from-middle-y</option>
    </optgroup>
    <optgroup label="Scale">
      <option value="scale-in-up">scale-in-up</option>
      <option value="scale-in-down">scale-in-down</option>
      <option value="scale-out-up">scale-out-up</option>
      <option value="scale-out-down">scale-out-down</option>
    </optgroup>
    <optgroup label="Spin">
      <option value="spin-in">spin-in</option>
      <option value="spin-out">spin-out</option>
      <option value="spin-in-ccw">spin-in-ccw</option>
      <option value="spin-out-ccw">spin-out-ccw</option>
    </optgroup>
  </select>
  <img src="assets/img/generic/voyager.jpg" class="docs-transition-demo">
</div>

---

## Custom Transitions

Custom transition classes can be made using Motion UI's mixin library. Here's an example of a custom hinge. **Refer to [Motion UI's transition documentation](https://github.com/zurb/motion-ui/blob/master/docs/transitions.md) to learn more.**

```scss
@include mui-hinge(
  $state: in,
  $from: top,
  $turn-origin: from-back,
  $duration: 0.5s,
  $timing: easeInOut
);
```

---

## Animation

You can use the same five transition effects to create CSS animations as well. The library also allows you to create series effects, with animations on multiple elements happening in a queue. **Refer to [Motion UI's animation documentation](https://github.com/zurb/motion-ui/blob/master/docs/animations.md) to learn more.**

<button type="button" class="button" data-docs-example-series>Play Animation</button>
<div class="grid-x grid-margin-x" id="series-example">
  <div class="cell small-4">
    <img class="thumbnail" src= "assets/img/generic/square-1.jpg" id="series-example-1">
  </div>
  <div class="cell small-4">
    <img class="thumbnail" src= "assets/img/generic/square-2.jpg" id="series-example-2">
  </div>
  <div class="cell small-4">
    <img class="thumbnail" src= "assets/img/generic/square-3.jpg" id="series-example-3">
  </div>
</div>

---

## JavaScript Reference

Motion UI includes a tiny JavaScript utility that will work anywhere as long as jQuery is loaded. However, Foundation 6 includes a customized version of this code that is included in `js/foundation.util.motion.js`. If you are using the Foundation version of this utility, and you wish to animate your own elements, trigger it this way:

```js
var elem = $('#elem-to-animate');

Foundation.Motion.animateIn(elem, animationClass [, callback]);
Foundation.Motion.animateOut(elem, animationClass [, callback]);
```

The callback is optional in this case, and will fire when the animation is complete.
<div class="callout primary">
  <p>Please note that the duration/animation speed for Motion UI animations are controlled via Sass mixin variables. The JavaScript handles the addition and removal of classes and event listener/callback firing only.
  <br>
  If you are individually including your `<script>` tags, make sure you are including the `js/foundation.util.motion.js` path.
  </p>
</div>
