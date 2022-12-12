---
title: Sass
description: Foundation is written in Sass, which allows us to make the codebase customizable and flexible.
video: mYiyunVQdMY
---

<div class="callout training-callout">
  <p>Get trained up on Foundation's Sass with our online webinar training. Sass allows you to write dramatically more efficient code. We'll go over things like how to install and start compiling Sass, nesting mixins and functions, and writing fully semantic CSS using Foundation mixins for insanely maintainable code.</p>
  <a href="http://zurb.com/university/advanced-foundation-training" target="_blank">Reserve your spot →</a>
</div>

<div class="primary callout">
  <p>Not familiar with Sass? The [official tutorial](http://sass-lang.com/guide) on sass-lang.com is a great place to start.</p>
</div>

## Compatibility

<img src="assets/img/logos/sass-logo.svg" alt="Sass logo" class="float-right" style="width: 150px; height: 150px; margin-left: 1rem;">

**Foundation for Sites can be compiled with Ruby Sass and libsass.** We tend to stick to the latest versions of both compilers when possible. Our documentation and starter project are compiled with [node-sass](https://github.com/sass/node-sass), a Node port of libsass. We recommend these versions of either compiler:

- Ruby Sass **3.4+**
- node-sass **3.4.2+** (libsass **3.3.2**)

### Autoprefixer Required

We don't include vendor prefixes in our Sass files&mdash;instead, we let [Autoprefixer](https://github.com/postcss/autoprefixer) handle it for us. Our build process uses [gulp-autoprefixer](https://github.com/sindresorhus/gulp-autoprefixer), but there are [other versions](https://github.com/postcss/autoprefixer#usage) that work with Grunt, Rails, Brunch, and more.

To get the proper browser support, use these Autoprefixer settings:

```js
autoprefixer({
  browsers: ['last 2 versions', 'ie >= 9', 'android >= 4.4', 'ios >= 7']
});
```

---

## Loading the Framework

If you're using the CLI to create a project, the Sass compilation process is already set up for you. If not, you can compile our Sass files yourself, or drop in a pre-built CSS file.

To get started, first install the framework files using Bower or npm.

```bash
npm install foundation-sites --save
bower install foundation-sites --save
```

### Compiling Manually

Next, add the framework files as an import path. How you do this depends on your build process, but the path is the same regardless: `packages_folder/foundation-sites/scss`

Here's an example using grunt-contrib-sass:

```js
grunt.initConfig({
  sass: {
    dist: {
      options: {
        loadPath: ['node_modules/foundation-sites/scss']
      }
    }
  }
});
```

If you're using Compass, open your project's `config.rb` and add the import path there:

```ruby
add_import_path "node_modules/foundation-sites/scss"
```

Finally, add an `@import` statement to the top of your primary Sass file. Refer to [Adjusting CSS Output](#adjusting-css-output) below to learn how to control the CSS output of the framework.

```scss
@import 'foundation';
```

You're also going to want a settings file for your project, which will allow you to modify the default styles of Foundation. **[Download the latest settings file here](https://raw.githubusercontent.com/zurb/foundation-sites/master/scss/settings/_settings.scss)**, add it to your project as `_settings.scss`, then import it *before* Foundation itself. 

<div class="callout">
The settings file needs to import `util/util` from Foundation. Please ensure that the Foundation folder is included in Sass or change `@import util/util` for it to points to the full path of the file. For example, NPM users may need to change the import to `node_modules/foundation-sites/scss/util/util`.
</div>

```scss
@import 'settings';
@import 'foundation';
```

### Using Compiled CSS

The Foundation for Sites npm and Bower packages include pre-compiled CSS files, in minified (compressed) and unminified flavors. If you're interested in editing the framework CSS directly, use the unminified file. For production, use the minified version.

```html
<link rel="stylesheet" href="node_modules/foundation-sites/dist/css/foundation-sites.css">

<link rel="stylesheet" href="node_modules/foundation-sites/dist/css/foundation-sites.min.css">
```

---

## Adjusting CSS Output

Foundation outputs many classes for its various components. These help developers get up and running quickly. However, when you move to production, you may wish to build your grid semantically, replace our pre-built classes with your own, or remove components entirely.

Each component has an **export mixin** which prints out the CSS for that component. If you're cool with having everything, you just need one line of code:

```scss
@include foundation-everything;
```

Our [starter projects](starter-projects.html) include the full list of imports, making it easy to comment out the components you don't need. A full list is also included below.

```scss
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

---

## The Settings File

All Foundation projects include a settings file, named `_settings.scss`. If you're using the CLI to create a Foundation for Sites project, you can find the settings file under scss/ (basic template) or src/assets/scss/ (ZURB template). If you're installing the framework standalone using Bower or npm, there's a settings file included in those packages, which you can move into your own Sass files to work with.

Every component includes a set of variables that modify core structural or visual styles. If there's something you can't customize with a variable, you can just write your own CSS to add it.

<div class="callout warning">
  <p>Once you've set up a new project, your settings file can't be automatically updated when new versions change, add, or remove variables. Keep tabs on new <a href="https://github.com/zurb/foundation/releases">Foundation releases</a> so you know when things change.</p>
</div>

Here's an example set of settings variables. These change the default styling of [buttons](button.html):

```scss
// Default padding for button.
$button-padding: 0.85em 1em !default;

// Default margin for button.
$button-margin: 0 $global-padding $global-padding 0 !default;

// Default fill for button. Is either solid or hollow.
$button-fill: solid !default;

// Default background color for button.
$button-background: $primary-color !default;

// Default hover background color for button.
$button-background-hover: scale-color($button-background, $lightness: -15%) !default;

// Default font color for button.
$button-font-color: #fff !default;

// Default alternative font color for button.
$button-font-color-alt: #000 !default;

// Default radius for button.
$button-radius: 0 !default;

// Default sizes for button.
$button-sizes: (
  tiny: 0.7,
  small: 0.8,
  medium: 1,
  large: 1.3,
) !default;

// Default font size for button.
$button-font-size: 0.9rem !default;

// Default opacity for a disabled button.
$button-opacity-disabled: 0.25 !default;
```
