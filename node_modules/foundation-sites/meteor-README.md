# [Foundation for Sites](http://foundation.zurb.com) (v6.5.3)

Foundation is the most advanced responsive front-end framework in the world. Quickly go from prototype to production, building sites or apps that work on any kind of device with Foundation. Includes layout constructs, like a fully customizable, responsive grid, commonly used JavaScript plugins, and full A11Y support.

## Usage in Meteor

- [Scss guide](meteor-README.md/#scss-guide)
- [JavaScript guide](meteor-README.md/#javascript-guide)


## Scss Guide

### 1. Add the package

```
meteor add zurb:foundation-sites
```

### 2. In your main .scss file (in your app):

Import foundation:

```
@import '{zurb:foundation-sites}/scss/foundation';
```

Each component has an export mixin which prints out the CSS for that component. If you're cool with having everything, you just need one line of code:

```
@include foundation-everything;
```

Or you can comment out the components you don't need:

```
@import 'foundation';

// Global styles
@include foundation-global-styles;
@include foundation-forms;
@include foundation-typography;

// Grids (choose one)
@include foundation-xy-grid-classes;
// @include foundation-grid;
// @include foundation-flex-grid;

// Generic components
@include foundation-button;
@include foundation-button-group;
@include foundation-close-button;
@include foundation-label;
@include foundation-progress-bar;
@include foundation-slider;
@include foundation-switch;
@include foundation-table;
// Basic components
@include foundation-badge;
@include foundation-breadcrumbs;
@include foundation-callout;
@include foundation-card;
@include foundation-dropdown;
@include foundation-pagination;
@include foundation-tooltip;

// Containers
@include foundation-accordion;
@include foundation-media-object;
@include foundation-orbit;
@include foundation-responsive-embed;
@include foundation-tabs;
@include foundation-thumbnail;
// Menu-based containers
@include foundation-menu;
@include foundation-menu-icon;
@include foundation-accordion-menu;
@include foundation-drilldown-menu;
@include foundation-dropdown-menu;

// Layout components
@include foundation-off-canvas;
@include foundation-reveal;
@include foundation-sticky;
@include foundation-title-bar;
@include foundation-top-bar;

// Helpers
@include foundation-float-classes;
// @include foundation-flex-classes;
@include foundation-visibility-classes;
// @include foundation-prototype-classes;
```

Note: For now there is a Motion-UI library added in the package (css, js files). It is needed for some Foundation plugins. Maybe in the future it will be separated package.

### 3. Overwrite Foundation settings

If you want you can copy `_settings.scss` file into your project. You can change settings and import it in your main .scss file (in your app):

```
@import 'settings'; // example when the _settings.scss file is in the same folder as your main .scss file
@import '{zurb:foundation-sites}/scss/foundation';

@include foundation-everything; // or individual ones

```

**Important:** In the _settings.scss (the copied one in your app) you need to replace `@import 'util/util'` with `@import '{zurb:foundation-sites}/scss/util/util'`

## JavaScript Guide

You can use `$(document).foundation()` when you want to initialize some plugins in one Meteor Template. You could do something like:

```
Template.main.onRendered(function () {
  $(document).foundation();
});
```

**But in Meteor it is better to have more control over it. So, you could use Foundation plugins API.**

Let's take a look at the example with the Reveal plugin.


#### HTML part

```html
<body>
  {{> myReveal}}
</body>
```

```html
<template name="myReveal">
  <p><a data-open="myReveal">Click me for a modal</a></p>

  <div class="reveal" id="myReveal">
    <h1>Awesome. I Have It.</h1>
    <p class="lead">Your couch. It is mine.</p>
    <p>I'm a cool paragraph that lives inside of an even cooler modal. Wins!</p>
    <button class="close-button" data-close aria-label="Close reveal" type="button">
      <span aria-hidden="true">&times;</span>
    </button>
  </div>
</template>
```

#### JavaScript part

```javascript
Template.myReveal.onRendered(function () {
  this.myRevealInstance = new Foundation.Reveal($('#myReveal'));
});

Template.myReveal.onDestroyed(function () {
  let reveal = this.myRevealInstance;
  if (reveal) {
    reveal.destroy();
  }
});
```

As you can see it is better to create small templates for plugins and initiate the plugins separately in the `onRendered` lifecycle hook. You should also remember to destroy the plugin using `onDestroyed`lifecycle hook on its template.

You will find more info about particular plugins on its docs page here: [http://foundation.zurb.com/sites/docs/](http://foundation.zurb.com/sites/docs/)

#### Known problems

1. **Conflicts with Meteor events**.
Solution: Try to always wrap Foundation's DOM nodes into another ones in your Meteor templates. This applies only to nodes on which are initialized Foundation's JS plugins and which are the first nodes in the Meteor templates with attached custom Meteor events. For more details read the last comments here: [#7248](https://github.com/zurb/foundation-sites/issues/7248)
