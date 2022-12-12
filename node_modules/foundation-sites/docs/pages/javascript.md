---
title: JavaScript
description: Our JavaScript is easy to set up and only requires jQuery to get going.
video: 'Mf5ZZfKTe-I'
---

## Installing

You can get the Foundation JavaScript files from a ZIP download, package manager, or CDN. Check out the [Installation](installation.html) page to learn more.

Once you have the files, add links to jQuery and Foundation as `<script>` tags at the bottom of your page, just before the closing `<body>` tag.

```html
<!-- jQuery must be imported before Foundation -->
<script src="js/jquery.min.js"></script>
<!-- this will include every plugin and utility required by Foundation -->
<script src="js/foundation.min.js"></script>
```


### Import in HTML

You can import in your HTML the complete Foundation library `foundation.min.js` like above, but also each plugin individually.

```html
<!-- Example of selectively including files -->
<script src="js/jquery.min.js"></script> <!-- Required -->
<script src="js/foundation.core.min.js"></script>  <!-- Required -->
<script src="js/foundation.util.mediaQuery.min.js"></script>
<script src="js/foundation.tabs.min.js"></script>
<script src="js/foundation.accordion.min.js"></script>
```

Know that they all require `foundation.core.js` to be loaded *first*. Some plugins also require specific utility libraries that ship with Foundation&mdash;refer to a plugin's documentation to find out which plugins require what, and see the [JavaScript Utilities](javascript-utilities.html) page for more information.

<div class="callout warning">
  <p>Loading many individual files like this creates a lot of network overhead, especially for users on mobile networks. To keep your pages loading quick, we recommend using a tool like <a href="http://gruntjs.com">Grunt</a> or <a href="http://gulpjs.com">Gulp</a> to combine all of your JavaScript files into one.</p>
</div>

### Import in JavaScript

By default, Foundation is exported as [UMD modules](http://bob.yexley.net/umd-javascript-that-runs-anywhere/). This means that Foundation and its plugins can be imported and used in any JavaScript environment.

For example with [ES6](https://github.com/lukehoban/es6features#readme) (the ESM format):
```js
import Foundation from 'foundation-sites';
const $dropdown = new Foundation.Dropdown($('#mydropdown'));
// Or
import { Dropdown } from 'foundation-sites';
const $dropdown = new Dropdown($('#mydropdown'));
```

With [RequireJs](http://requirejs.org/) (the AMD format):
```js
define(['foundation'], function(Foundation) {
  var $dropdown = new Foundation.Dropdown($('#mydropdown'));
});
```

With [Node.js](https://www.safaribooksonline.com/library/view/learning-javascript-design/9781449334840/ch11s03.html) (the CommonJs format):
```js
var Foundation = require('foundation-sites');
var $dropdown = new Dropdown($('#mydropdown'));
```

#### Available formats

Foundation is provided in bundles of various module formats so you can pick the one that matches the best your needs. If you don't know these terms yet, take a look at this [10-minute introduction to module formats in JavaScript](https://www.jvandemo.com/a-10-minute-primer-to-javascript-modules-module-formats-module-loaders-and-module-bundlers/). You will find in the `dist/js` folder the following bundles:

* `foundation.js` <span class="label secondary">UMD</span> <span class="label">Default</span><br>
  Compatible with most environments and tools (AMD, CJS, ESM...). It works almost everywhere by checking the module format of your environments and then using it, which makes the bundle a little heavier.

* `foundation.cjs.js` <span class="label secondary">CommonJS</span><br>
  Dedicated to Node.js and older bundlers like Browserify or Webpack v1.

* `foundation.esm.js` <span class="label secondary">ES6 Modules</span>  (`module` in `package.json`)<br>
  Everything is transpiled to ES5 but the modules. Dedicated to modern bundlers, like Webpack 2+ or Rollup. They will automatically use this bundle and parse the ES6 modules to remove the unused code (see [tree shaking](#tree-shaking) below).

* `foundation.es6.js` <span class="label secondary">ES6</span> (`esnext` in `package.json`)<br>
  Unlike the other bundles, this bundle is not transpiled. It contains all the Foundation sources in ES6 in a single file. Use it if you want to manually transpile it for your own targets.

#### Tree Shaking

Many bundlers like Webpack, Rollup or Parcel support tree shaking. It consists of the removing the unused code parts from your codebase or your dependencies. Take a look at these articles to know how it works and how to enable it: [How To Clean Up Your JavaScript Build With Tree Shaking](https://www.engineyard.com/blog/tree-shaking), [Why Webpack 2's Tree Shaking is not as effective as you think](https://advancedweb.hu/2017/02/07/treeshaking/) and [Reduce JavaScript Payloads with Tree Shaking](https://developers.google.com/web/fundamentals/performance/optimizing-javascript/tree-shaking/).

As tree shaking is only available in ES6, we recommend to import plugins like the following:

```js
// Only Dropdown and DropdownMenu will be included in your application.
import { Dropdown, DropdownMenu } from 'foundation-sites';
```

Sadly, the "static analysis" promised by these bundlers to detect unused code in dependencies does not always work. Depending on your build environment, you may have to manually import the Foundation plugins to make it work correctly:

```js
// /!\ Don't use this if tree shaking works with standard named imports.
// Only Dropdown and DropdownMenu will be included in your application.
import { Dropdown } from 'foundation-sites/js/foundation.dropdown';
import { DropdownMenu } from 'foundation-sites/js/foundation.dropdownMenu';
```

---

## Initializing

The `.foundation()` function on the jQuery object will kick off every Foundation plugin at once.

```js
$(document).foundation();
```

You can also selectively initialize plugins by calling the `.foundation();` method on one or more elements with a plugin.

```js
$('#foo').foundation(); // initialize all plugins within the element `#foo`
$('.has-tip').foundation(); // initialize all tooltips on the page.
```

---

## Using Plugins

Plugins are attached to HTML elements using data attributes. The data attribute will match the name of the plugin. For example, adding `data-accordion` to an element creates an accordion, while adding `data-tooltip` creates a tooltip link.

```html_example
<p><span data-tooltip aria-haspopup="true" class="has-tip" tabindex="1" title="Fancy word for a beetle.">Scarabaeus</span></p>
```

<div class="callout warning">
  <p>A single element can only have one Foundation plugin on it at a time. However, most plugins can be nested inside other ones.</p>
</div>

---

## Configuring Plugins

Each plugin has a set of configuration settings that customize how it works. For example, you change how fast an [accordion](accordion.html) slides up and down, or if [tooltips](tooltip.html) should appear on touch devices.

Plugin settings can be changed globally by changing the `DEFAULTS` property on the plugin.

```js
Foundation.Accordion.defaults.slideSpeed = 500;
Foundation.Accordion.defaults.multiExpand = true;
```

An individual instance of a plugin can also have different settings. These can be set in the HTML or in JavaScript.
<div class="callout warning">
  <p>In the HTML, each setting can be defined as an individual data attribute. Note that camelCased options are converted to hyphenated words. In the below example, `multiExpand` becomes `data-multi-expand`.</p>
</div>

```html
<div data-accordion data-slide-speed="500" data-multi-expand="true"></div>
```

Data options can also be set in bulk on one attribute, `data-options`. Options are written with the format `key: value;`, with a semicolon separating each option. The above example can be written using `data-options` like so:

```html
<div data-accordion data-options="slideSpeed: 500; multiExpand: true;"></div>
```
There is one exception to this rule above, in the [Sticky](sticky.html) plugin. Because of the way you pass top and bottom anchors to that plugin, you can't include them in your `data-options` attribute. If you are using a single anchor or no declared anchor at all, you can still use `data-options`, and you can use it for all other options available.

<hr>
Setting options with JavaScript involves passing an object into the constructor function, like this:

```js
var options = {multiExpand: true, allowAllClosed: false};
var accordion = new Foundation.Accordion($('#some-accordion'), options);
```

It's worth noting that options passed to plugins via JavaScript take the highest precedence, and will overwrite any default values or options applied via the `data-some-option` tag. This is also how the `data-options="someOption:true; someOtherOption:false"` options are passed into constructor functions. So, if you were to say:
```html
<div data-accordion data-slide-speed="500" data-options="slideSpeed:250;">...</div>
```
your accordion element would have a slide speed of 250 milliseconds.

---

## Adding Plugins After Page Load

If you add new HTML to the DOM, any plugins on those elements won't be initialized by default. Re-call the `.foundation()` function to check for new plugins.

```js
$.ajax('assets/partials/kitten-carousel.html', function(data) {
  $('#kitten-carousel').html(data).foundation();
});
```

---

## Adding Content to Plugins

In previous versions of Foundation, there was a method for plugins called `reflow`, though it's inclusion on plugins wasn't universal. For Foundation 6 we've added a global `reInit` method that will remove and reapply event listeners, update the plugin's instance data for relevant information, like a new tab or content pane being added, and reset any cached data the plugin may rely on.

This method can be called on a plugin class:
```js
Foundation.reInit('tooltip');
```
an array of plugin classes:
```js
Foundation.reInit(['tooltip', 'accordion', 'reveal']);
```
or an individual element or collection of elements selected with jQuery:
```js
Foundation.reInit($('#some-plugin'));
Foundation.reInit($('.some-plugin-class'));
```

If passing strings, it is required to pass proper <strong>camelCased</strong> or <strong>kebab-cased</strong> plugin names. Passing `DropdownMenu` or `dropdown-menu` are equivalent.

---

## Programmatic Use

Plugins can be created programmatically in JavaScript. Every plugin is a class on the global `Foundation` object, with a constructor that accepts two parameters: an element to attach to, and an object of options.

```js
var $accordion = new Foundation.Accordion($('#accordion'), {
  slideSpeed: 500,
  multiExpand: true
});
```

Most plugins have a public API that allows you to manipulate it through JavaScript. Refer to a plugin's documentation to learn what functions are available. Invoking methods is easy as pie:

```js
$('#reveal').foundation('open'); //will open a Reveal modal with id `reveal`.

$('[data-tabs]').eq(0).foundation('selectTab', $('#example')); //will change the first Tabs on the page to whatever panel you choose.

$('.tooltip').foundation('_destroy'); //will destroy all Tooltips on the page.

```
You can use any jQuery selector you like, and if the selector encompasses multiple plugins, they will all have the same the chosen method invoked. You pass arguments just like you would any in other JavaScript `function(comma, delimited, so, easy)`. We did make an effort to reduce the number of public methods that require arguments, but check the plugin's page to see if it requires additional information.

If you are creating your plugins programmatically, you can, of course, invoke methods directly:

```js
var $modal = new Foundation.Reveal($('#some-modal'), options);
$modal.open();
```

<div class="callout warning">
  <p>Plugin methods prefixed with an underscore are considered part of the internal API, which means they could change, break, or disappear without warning. We recommend sticking to only the public API, which is documented on each plugin's page.</p>
</div>

---

## Events

Every plugin fires DOM events when certain functions finish. For example, you can listen for when tabs change, or an off-canvas menu opens, and create a callback to respond to it.

```js
$('[data-tabs]').on('change.zf.tabs', function() {
  console.log('Those tabs sure did change!');
});
```

Refer to each plugin's documentation to see a list of events it fires, and when they fire.

<div class="callout warning">
  <p>Starting with Foundation 6, we removed callbacks as plugin settings. All use of callbacks with plugins should be done as event listeners.</p>
</div>
