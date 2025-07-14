# Turbolinks

**Turbolinks® makes navigating your web application faster.** Get the performance benefits of a single-page application without the added complexity of a client-side JavaScript framework. Use HTML to render your views on the server side and link to pages as usual. When you follow a link, Turbolinks automatically fetches the page, swaps in its `<body>`, and merges its `<head>`, all without incurring the cost of a full page load.

![Turbolinks](https://s3.amazonaws.com/turbolinks-docs/images/turbolinks.gif)

## Features

- **Optimizes navigation automatically.** No need to annotate links or specify which parts of the page should change.
- **No server-side cooperation necessary.** Respond with full HTML pages, not partial page fragments or JSON.
- **Respects the web.** The Back and Reload buttons work just as you’d expect. Search engine-friendly by design.
- **Supports mobile apps.** Adapters for [iOS](https://github.com/turbolinks/turbolinks-ios) and [Android](https://github.com/turbolinks/turbolinks-android) let you build hybrid applications using native navigation controls.

## Supported Browsers

Turbolinks works in all modern desktop and mobile browsers. It depends on the [HTML5 History API](http://caniuse.com/#search=pushState) and [Window.requestAnimationFrame](http://caniuse.com/#search=requestAnimationFrame). In unsupported browsers, Turbolinks gracefully degrades to standard navigation.

## Installation

Include [`dist/turbolinks.js`](dist/turbolinks.js) in your application’s JavaScript bundle.

Turbolinks automatically initializes itself when loaded via a standalone `<script>` tag or a traditional concatenated JavaScript bundle. If you load Turbolinks as a CommonJS or AMD module, first require the module, then call the provided `start()` function.

### Installation Using Ruby on Rails

Your Ruby on Rails application can use the [`turbolinks` RubyGem](https://github.com/turbolinks/turbolinks-rails) to install Turbolinks. This gem contains a Rails engine which integrates seamlessly with the Rails asset pipeline.

1. Add the `turbolinks` gem, version 5, to your Gemfile: `gem 'turbolinks', '~> 5.1.0'`
2. Run `bundle install`.
3. Add `//= require turbolinks` to your JavaScript manifest file (usually found at `app/assets/javascripts/application.js`).

The gem also provides server-side support for Turbolinks redirection, which can be used without the asset pipeline.

### Installation Using npm

Your application can use the [`turbolinks` npm package](https://www.npmjs.com/package/turbolinks) to install Turbolinks as a module for build tools like [webpack](http://webpack.github.io/).

1. Add the `turbolinks` package to your application: `npm install --save turbolinks`.
2. Require and start Turbolinks in your JavaScript bundle:

    ```js
    var Turbolinks = require("turbolinks")
    Turbolinks.start()
    ```

#### Table of Contents

[Navigating with Turbolinks](#navigating-with-turbolinks)
- [Each Navigation is a Visit](#each-navigation-is-a-visit)
- [Application Visits](#application-visits)
- [Restoration Visits](#restoration-visits)
- [Canceling Visits Before They Start](#canceling-visits-before-they-start)
- [Disabling Turbolinks on Specific Links](#disabling-turbolinks-on-specific-links)

[Building Your Turbolinks Application](#building-your-turbolinks-application)
- [Working with Script Elements](#working-with-script-elements)
  - [Loading Your Application’s JavaScript Bundle](#loading-your-applications-javascript-bundle)
- [Understanding Caching](#understanding-caching)
  - [Preparing the Page to be Cached](#preparing-the-page-to-be-cached)
  - [Detecting When a Preview is Visible](#detecting-when-a-preview-is-visible)
  - [Opting Out of Caching](#opting-out-of-caching)
- [Installing JavaScript Behavior](#installing-javascript-behavior)
  - [Observing Navigation Events](#observing-navigation-events)
  - [Attaching Behavior With Stimulus](#attaching-behavior-with-stimulus)
- [Making Transformations Idempotent](#making-transformations-idempotent)
- [Persisting Elements Across Page Loads](#persisting-elements-across-page-loads)

[Advanced Usage](#advanced-usage)
- [Displaying Progress](#displaying-progress)
- [Reloading When Assets Change](#reloading-when-assets-change)
- [Ensuring Specific Pages Trigger a Full Reload](#ensuring-specific-pages-trigger-a-full-reload)
- [Setting a Root Location](#setting-a-root-location)
- [Following Redirects](#following-redirects)
- [Redirecting After a Form Submission](#redirecting-after-a-form-submission)
- [Setting Custom HTTP Headers](#setting-custom-http-headers)

[API Reference](#api-reference)
- [Turbolinks.visit](#turbolinksvisit)
- [Turbolinks.clearCache](#turbolinksclearcache)
- [Turbolinks.setProgressBarDelay](#turbolinkssetprogressbardelay)
- [Turbolinks.supported](#turbolinkssupported)
- [Full List of Events](#full-list-of-events)

[Contributing to Turbolinks](#contributing-to-turbolinks)
- [Building From Source](#building-from-source)
- [Running Tests](#running-tests)

# Navigating with Turbolinks

Turbolinks intercepts all clicks on `<a href>` links to the same domain. When you click an eligible link, Turbolinks prevents the browser from following it. Instead, Turbolinks changes the browser’s URL using the [History API](https://developer.mozilla.org/en-US/docs/Web/API/History), requests the new page using [`XMLHttpRequest`](https://developer.mozilla.org/en-US/docs/Web/API/XMLHttpRequest), and then renders the HTML response.

During rendering, Turbolinks replaces the current `<body>` element outright and merges the contents of the `<head>` element. The JavaScript `window` and `document` objects, and the HTML `<html>` element, persist from one rendering to the next.

## Each Navigation is a Visit

Turbolinks models navigation as a *visit* to a *location* (URL) with an *action*.

Visits represent the entire navigation lifecycle from click to render. That includes changing browser history, issuing the network request, restoring a copy of the page from cache, rendering the final response, and updating the scroll position.

There are two types of visit: an _application visit_, which has an action of _advance_ or _replace_, and a _restoration visit_, which has an action of _restore_.

## Application Visits

Application visits are initiated by clicking a Turbolinks-enabled link, or programmatically by calling [`Turbolinks.visit(location)`](#turbolinksvisit).

An application visit always issues a network request. When the response arrives, Turbolinks renders its HTML and completes the visit.

If possible, Turbolinks will render a preview of the page from cache immediately after the visit starts. This improves the perceived speed of frequent navigation between the same pages.

If the visit’s location includes an anchor, Turbolinks will attempt to scroll to the anchored element. Otherwise, it will scroll to the top of the page.

Application visits result in a change to the browser’s history; the visit’s _action_ determines how.

![Advance visit action](https://s3.amazonaws.com/turbolinks-docs/images/advance.svg)

The default visit action is _advance_. During an advance visit, Turbolinks pushes a new entry onto the browser’s history stack using [`history.pushState`](https://developer.mozilla.org/en-US/docs/Web/API/History/pushState).

Applications using the Turbolinks [iOS adapter](https://github.com/turbolinks/turbolinks-ios) typically handle advance visits by pushing a new view controller onto the navigation stack. Similarly, applications using the [Android adapter](https://github.com/turbolinks/turbolinks-android) typically push a new activity onto the back stack.

![Replace visit action](https://s3.amazonaws.com/turbolinks-docs/images/replace.svg)

You may wish to visit a location without pushing a new history entry onto the stack. The _replace_ visit action uses [`history.replaceState`](https://developer.mozilla.org/en-US/docs/Web/API/History/pushState) to discard the topmost history entry and replace it with the new location.

To specify that following a link should trigger a replace visit, annotate the link with `data-turbolinks-action="replace"`:

```html
<a href="/edit" data-turbolinks-action="replace">Edit</a>
```

To programmatically visit a location with the replace action, pass the `action: "replace"` option to [`Turbolinks.visit`](#turbolinksvisit):

```js
Turbolinks.visit("/edit", { action: "replace" })
```

Applications using the Turbolinks [iOS adapter](https://github.com/turbolinks/turbolinks-ios) typically handle replace visits by dismissing the topmost view controller and pushing a new view controller onto the navigation stack without animation.

## Restoration Visits

Turbolinks automatically initiates a restoration visit when you navigate with the browser’s Back or Forward buttons. Applications using the [iOS](https://github.com/turbolinks/turbolinks-ios) or [Android](https://github.com/turbolinks/turbolinks-android) adapters initiate a restoration visit when moving backward in the navigation stack.

![Restore visit action](https://s3.amazonaws.com/turbolinks-docs/images/restore.svg)

If possible, Turbolinks will render a copy of the page from cache without making a request. Otherwise, it will retrieve a fresh copy of the page over the network. See [Understanding Caching](#understanding-caching) for more details.

Turbolinks saves the scroll position of each page before navigating away and automatically returns to this saved position on restoration visits.

Restoration visits have an action of _restore_ and Turbolinks reserves them for internal use. You should not attempt to annotate links or invoke [`Turbolinks.visit`](#turbolinksvisit) with an action of `restore`.

## Canceling Visits Before They Start

Application visits can be canceled before they start, regardless of whether they were initiated by a link click or a call to [`Turbolinks.visit`](#turbolinksvisit).

Listen for the `turbolinks:before-visit` event to be notified when a visit is about to start, and use `event.data.url` (or `$event.originalEvent.data.url`, when using jQuery) to check the visit’s location. Then cancel the visit by calling `event.preventDefault()`.

Restoration visits cannot be canceled and do not fire `turbolinks:before-visit`. Turbolinks issues restoration visits in response to history navigation that has *already taken place*, typically via the browser’s Back or Forward buttons.

## Disabling Turbolinks on Specific Links

Turbolinks can be disabled on a per-link basis by annotating a link or any of its ancestors with `data-turbolinks="false"`.

```html
<a href="/" data-turbolinks="false">Disabled</a>

<div data-turbolinks="false">
  <a href="/">Disabled</a>
</div>
```

To reenable when an ancestor has opted out, use `data-turbolinks="true"`:

```html
<div data-turbolinks="false">
  <a href="/" data-turbolinks="true">Enabled</a>
</div>
```

Links with Turbolinks disabled will be handled normally by the browser.

# Building Your Turbolinks Application

Turbolinks is fast because it doesn’t reload the page when you follow a link. Instead, your application becomes a persistent, long-running process in the browser. This requires you to rethink the way you structure your JavaScript.

In particular, you can no longer depend on a full page load to reset your environment every time you navigate. The JavaScript `window` and `document` objects retain their state across page changes, and any other objects you leave in memory will stay in memory.

With awareness and a little extra care, you can design your application to gracefully handle this constraint without tightly coupling it to Turbolinks.

## Working with Script Elements

Your browser automatically loads and evaluates any `<script>` elements present on the initial page load.

When you navigate to a new page, Turbolinks looks for any `<script>` elements in the new page’s `<head>` which aren’t present on the current page. Then it appends them to the current `<head>` where they’re loaded and evaluated by the browser. You can use this to load additional JavaScript files on-demand.

Turbolinks evaluates `<script>` elements in a page’s `<body>` each time it renders the page. You can use inline body scripts to set up per-page JavaScript state or bootstrap client-side models. To install behavior, or to perform more complex operations when the page changes, avoid script elements and use the `turbolinks:load` event instead.

Annotate `<script>` elements with `data-turbolinks-eval="false"` if you do not want Turbolinks to evaluate them after rendering. Note that this annotation will not prevent your browser from evaluating scripts on the initial page load.

### Loading Your Application’s JavaScript Bundle

Always make sure to load your application’s JavaScript bundle using `<script>` elements in the `<head>` of your document. Otherwise, Turbolinks will reload the bundle with every page change.

```html
<head>
  ...
  <script src="/application-cbd3cd4.js" defer></script>
</head>
```

If you have traditionally placed application scripts at the end of `<body>` for performance reasons, consider using the [`<script defer>`](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/script#attr-defer) attribute instead. It has [widespread browser support](https://caniuse.com/#feat=script-defer) and allows you to keep your scripts in `<head>` for Turbolinks compatibility.

You should also consider configuring your asset packaging system to fingerprint each script so it has a new URL when its contents change. Then you can use the `data-turbolinks-track` attribute to force a full page reload when you deploy a new JavaScript bundle. See [Reloading When Assets Change](#reloading-when-assets-change) for information.

## Understanding Caching

Turbolinks maintains a cache of recently visited pages. This cache serves two purposes: to display pages without accessing the network during restoration visits, and to improve perceived performance by showing temporary previews during application visits.

When navigating by history (via [Restoration Visits](#restoration-visits)), Turbolinks will restore the page from cache without loading a fresh copy from the network, if possible.

Otherwise, during standard navigation (via [Application Visits](#application-visits)), Turbolinks will immediately restore the page from cache and display it as a preview while simultaneously loading a fresh copy from the network. This gives the illusion of instantaneous page loads for frequently accessed locations.

Turbolinks saves a copy of the current page to its cache just before rendering a new page. Note that Turbolinks copies the page using [`cloneNode(true)`](https://developer.mozilla.org/en-US/docs/Web/API/Node/cloneNode), which means any attached event listeners and associated data are discarded.

### Preparing the Page to be Cached

Listen for the `turbolinks:before-cache` event if you need to prepare the document before Turbolinks caches it. You can use this event to reset forms, collapse expanded UI elements, or tear down any third-party widgets so the page is ready to be displayed again.

```js
document.addEventListener("turbolinks:before-cache", function() {
  // ...
})
```

### Detecting When a Preview is Visible

Turbolinks adds a `data-turbolinks-preview` attribute to the `<html>` element when it displays a preview from cache. You can check for the presence of this attribute to selectively enable or disable behavior when a preview is visible.

```js
if (document.documentElement.hasAttribute("data-turbolinks-preview")) {
  // Turbolinks is displaying a preview
}
```

### Opting Out of Caching

You can control caching behavior on a per-page basis by including a `<meta name="turbolinks-cache-control">` element in your page’s `<head>` and declaring a caching directive.

Use the `no-preview` directive to specify that a cached version of the page should not be shown as a preview during an application visit. Pages marked no-preview will only be used for restoration visits.

To specify that a page should not be cached at all, use the `no-cache` directive. Pages marked no-cache will always be fetched over the network, including during restoration visits.

```html
<head>
  ...
  <meta name="turbolinks-cache-control" content="no-cache">
</head>
```

To completely disable caching in your application, ensure every page contains a no-cache directive.

## Installing JavaScript Behavior

You may be used to installing JavaScript behavior in response to the `window.onload`, `DOMContentLoaded`, or jQuery `ready` events. With Turbolinks, these events will fire only in response to the initial page load, not after any subsequent page changes. We compare two strategies for connecting JavaScript behavior to the DOM below.

### Observing Navigation Events

Turbolinks triggers a series of events during navigation. The most significant of these is the `turbolinks:load` event, which fires once on the initial page load, and again after every Turbolinks visit.

You can observe the `turbolinks:load` event in place of `DOMContentLoaded` to set up JavaScript behavior after every page change:

```js
document.addEventListener("turbolinks:load", function() {
  // ...
})
```

Keep in mind that your application will not always be in a pristine state when this event is fired, and you may need to clean up behavior installed for the previous page.

Also note that Turbolinks navigation may not be the only source of page updates in your application, so you may wish to move your initialization code into a separate function which you can call from `turbolinks:load` and anywhere else you may change the DOM.

When possible, avoid using the `turbolinks:load` event to add other event listeners directly to elements on the page body. Instead, consider using [event delegation](https://learn.jquery.com/events/event-delegation/) to register event listeners once on `document` or `window`.

See the [Full List of Events](#full-list-of-events) for more information.

### Attaching Behavior With Stimulus

New DOM elements can appear on the page at any time by way of Ajax request handlers, WebSocket handlers, or client-side rendering operations, and these elements often need to be initialized as if they came from a fresh page load.

You can handle all of these updates, including updates from Turbolinks page loads, in a single place with the conventions and lifecycle callbacks provided by Turbolinks’ sister framework, [Stimulus](https://github.com/stimulusjs/stimulus).

Stimulus lets you annotate your HTML with controller, action, and target attributes:

```html
<div data-controller="hello">
  <input data-target="hello.name" type="text">
  <button data-action="click->hello#greet">Greet</button>
</div>
```

Implement a compatible controller and Stimulus connects it automatically:

```js
// hello_controller.js
import { Controller } from "stimulus"

export default class extends Controller {
  greet() {
    console.log(`Hello, ${this.name}!`)
  }

  get name() {
    return this.targets.find("name").value
  }
}
```

Stimulus connects and disconnects these controllers and their associated event handlers whenever the document changes using the [MutationObserver](https://developer.mozilla.org/en-US/docs/Web/API/MutationObserver) API. As a result, it handles Turbolinks page changes the same way it handles any other type of DOM update.

See the [Stimulus repository on GitHub](https://github.com/stimulusjs/stimulus) for more information.

## Making Transformations Idempotent

Often you’ll want to perform client-side transformations to HTML received from the server. For example, you might want to use the browser’s knowledge of the user’s current time zone to group a collection of elements by date.

Suppose you have annotated a set of elements with `data-timestamp` attributes indicating the elements’ creation times in UTC. You have a JavaScript function that queries the document for all such elements, converts the timestamps to local time, and inserts date headers before each element that occurs on a new day.

Consider what happens if you’ve configured this function to run on `turbolinks:load`. When you navigate to the page, your function inserts date headers. Navigate away, and Turbolinks saves a copy of the transformed page to its cache. Now press the Back button—Turbolinks restores the page, fires `turbolinks:load` again, and your function inserts a second set of date headers.

To avoid this problem, make your transformation function _idempotent_. An idempotent transformation is safe to apply multiple times without changing the result beyond its initial application.

One technique for making a transformation idempotent is to keep track of whether you’ve already performed it by setting a `data` attribute on each processed element. When Turbolinks restores your page from cache, these attributes will still be present. Detect these attributes in your transformation function to determine which elements have already been processed.

A more robust technique is simply to detect the transformation itself. In the date grouping example above, that means checking for the presence of a date divider before inserting a new one. This approach gracefully handles newly inserted elements that weren’t processed by the original transformation.

## Persisting Elements Across Page Loads

Turbolinks allows you to mark certain elements as _permanent_. Permanent elements persist across page loads, so that any changes you make to those elements do not need to be reapplied after navigation.

Consider a Turbolinks application with a shopping cart. At the top of each page is an icon with the number of items currently in the cart. This counter is updated dynamically with JavaScript as items are added and removed.

Now imagine a user who has navigated to several pages in this application. She adds an item to her cart, then presses the Back button in her browser. Upon navigation, Turbolinks restores the previous page’s state from cache, and the cart item count erroneously changes from 1 to 0.

You can avoid this problem by marking the counter element as permanent. Designate permanent elements by giving them an HTML `id` and annotating them with `data-turbolinks-permanent`.

```html
<div id="cart-counter" data-turbolinks-permanent>1 item</div>
```

Before each render, Turbolinks matches all permanent elements by `id` and transfers them from the original page to the new page, preserving their data and event listeners.

# Advanced Usage

## Displaying Progress

During Turbolinks navigation, the browser will not display its native progress indicator. Turbolinks installs a CSS-based progress bar to provide feedback while issuing a request.

The progress bar is enabled by default. It appears automatically for any page that takes longer than 500ms to load. (You can change this delay with the [`Turbolinks.setProgressBarDelay`](#turbolinkssetprogressbardelay) method.)

The progress bar is a `<div>` element with the class name `turbolinks-progress-bar`. Its default styles appear first in the document and can be overridden by rules that come later.

For example, the following CSS will result in a thick green progress bar:

```css
.turbolinks-progress-bar {
  height: 5px;
  background-color: green;
}
```

To disable the progress bar entirely, set its `visibility` style to `hidden`:

```css
.turbolinks-progress-bar {
  visibility: hidden;
}
```

## Reloading When Assets Change

Turbolinks can track the URLs of asset elements in `<head>` from one page to the next and automatically issue a full reload if they change. This ensures that users always have the latest versions of your application’s scripts and styles.

Annotate asset elements with `data-turbolinks-track="reload"` and include a version identifier in your asset URLs. The identifier could be a number, a last-modified timestamp, or better, a digest of the asset’s contents, as in the following example.

```html
<head>
  ...
  <link rel="stylesheet" href="/application-258e88d.css" data-turbolinks-track="reload">
  <script src="/application-cbd3cd4.js" data-turbolinks-track="reload"></script>
</head>
```

## Ensuring Specific Pages Trigger a Full Reload

You can ensure visits to a certain page will always trigger a full reload by including a `<meta name="turbolinks-visit-control">` element in the page’s `<head>`.

```html
<head>
  ...
  <meta name="turbolinks-visit-control" content="reload">
</head>
```

This setting may be useful as a workaround for third-party JavaScript libraries that don’t interact well with Turbolinks page changes.

## Setting a Root Location

By default, Turbolinks only loads URLs with the same origin—i.e. the same protocol, domain name, and port—as the current document. A visit to any other URL falls back to a full page load.

In some cases, you may want to further scope Turbolinks to a path on the same origin. For example, if your Turbolinks application lives at `/app`, and the non-Turbolinks help site lives at `/help`, links from the app to the help site shouldn’t use Turbolinks.

Include a `<meta name="turbolinks-root">` element in your pages’ `<head>` to scope Turbolinks to a particular root location. Turbolinks will only load same-origin URLs that are prefixed with this path.

```html
<head>
  ...
  <meta name="turbolinks-root" content="/app">
</head>
```

## Following Redirects

When you visit location `/one` and the server redirects you to location `/two`, you expect the browser’s address bar to display the redirected URL.

However, Turbolinks makes requests using `XMLHttpRequest`, which transparently follows redirects. There’s no way for Turbolinks to tell whether a request resulted in a redirect without additional cooperation from the server.

To work around this problem, send the `Turbolinks-Location` header in response to a visit that was redirected, and Turbolinks will replace the browser’s topmost history entry with the value you provide.

The Turbolinks Rails engine sets `Turbolinks-Location` automatically when using `redirect_to` in response to a Turbolinks visit.

## Redirecting After a Form Submission

Submitting an HTML form to the server and redirecting in response is a common pattern in web applications. Standard form submission is similar to navigation, resulting in a full page load. Using Turbolinks you can improve the performance of form submission without complicating your server-side code.

Instead of submitting forms normally, submit them with XHR. In response to an XHR submit on the server, return JavaScript that performs a [`Turbolinks.visit`](#turbolinksvisit) to be evaluated by the browser.

If form submission results in a state change on the server that affects cached pages, consider clearing Turbolinks’ cache with [`Turbolinks.clearCache()`](#turbolinksclearcache).

The Turbolinks Rails engine performs this optimization automatically for non-GET XHR requests that redirect with the `redirect_to` helper.

## Setting Custom HTTP Headers

You can observe the `turbolinks:request-start` event to set custom headers on Turbolinks requests. Access the request’s XMLHttpRequest object via `event.data.xhr`, then call the [`setRequestHeader`](https://developer.mozilla.org/en-US/docs/Web/API/XMLHttpRequest) method as many times as you wish.

For example, you might want to include a request ID with every Turbolinks link click and programmatic visit.

```javascript
document.addEventListener("turbolinks:request-start", function(event) {
  var xhr = event.data.xhr
  xhr.setRequestHeader("X-Request-Id", "123...")
})
```

# API Reference

## Turbolinks.visit

Usage:
```js
Turbolinks.visit(location)
Turbolinks.visit(location, { action: action })
```

Performs an [Application Visit](#application-visits) to the given _location_ (a string containing a URL or path) with the specified _action_ (a string, either `"advance"` or `"replace"`).

If _location_ is a cross-origin URL, or falls outside of the specified root (see [Setting a Root Location](#setting-a-root-location)), or if the value of [`Turbolinks.supported`](#turbolinkssupported) is `false`, Turbolinks performs a full page load by setting `window.location`.

If _action_ is unspecified, Turbolinks assumes a value of `"advance"`.

Before performing the visit, Turbolinks fires a `turbolinks:before-visit` event on `document`. Your application can listen for this event and cancel the visit with `event.preventDefault()` (see [Canceling Visits Before They Start](#canceling-visits-before-they-start)).

## Turbolinks.clearCache

Usage:
```js
Turbolinks.clearCache()
```

Removes all entries from the Turbolinks page cache. Call this when state has changed on the server that may affect cached pages.

## Turbolinks.setProgressBarDelay

Usage:
```js
Turbolinks.setProgressBarDelay(delayInMilliseconds)
```

Sets the delay after which the [progress bar](#displaying-progress) will appear during navigation, in milliseconds. The progress bar appears after 500ms by default.

Note that this method has no effect when used with the iOS or Android adapters.

## Turbolinks.supported

Usage:
```js
if (Turbolinks.supported) {
  // ...
}
```

Detects whether Turbolinks is supported in the current browser (see [Supported Browsers](#supported-browsers)).

## Full List of Events

Turbolinks emits events that allow you to track the navigation lifecycle and respond to page loading. Except where noted, Turbolinks fires events on the `document` object.

* `turbolinks:click` fires when you click a Turbolinks-enabled link. The clicked element is the event target. Access the requested location with `event.data.url`. Cancel this event to let the click fall through to the browser as normal navigation.

* `turbolinks:before-visit` fires before visiting a location, except when navigating by history. Access the requested location with `event.data.url`. Cancel this event to prevent navigation.

* `turbolinks:visit` fires immediately after a visit starts.

* `turbolinks:request-start` fires before Turbolinks issues a network request to fetch the page. Access the XMLHttpRequest object with `event.data.xhr`.

* `turbolinks:request-end` fires after the network request completes. Access the XMLHttpRequest object with `event.data.xhr`.

* `turbolinks:before-cache` fires before Turbolinks saves the current page to cache.

* `turbolinks:before-render` fires before rendering the page. Access the new `<body>` element with `event.data.newBody`.

* `turbolinks:render` fires after Turbolinks renders the page. This event fires twice during an application visit to a cached location: once after rendering the cached version, and again after rendering the fresh version.

* `turbolinks:load` fires once after the initial page load, and again after every Turbolinks visit. Access visit timing metrics with the `event.data.timing` object.

# Contributing to Turbolinks

Turbolinks is open-source software, freely distributable under the terms of an [MIT-style license](LICENSE). The [source code is hosted on GitHub](https://github.com/turbolinks/turbolinks).
Development is sponsored by [Basecamp](https://basecamp.com/).

We welcome contributions in the form of bug reports, pull requests, or thoughtful discussions in the [GitHub issue tracker](https://github.com/turbolinks/turbolinks/issues).

Please note that this project is released with a [Contributor Code of Conduct](CONDUCT.md). By participating in this project you agree to abide by its terms.

## Building From Source

Turbolinks is written in [CoffeeScript](https://github.com/jashkenas/coffee-script) and compiled to JavaScript with [Blade](https://github.com/javan/blade). To build from source you’ll need a recent version of Ruby. From the root of your Turbolinks directory, issue the following commands to build the distributable files in `dist/`:

```
$ gem install bundler
$ bundle install
$ bin/blade build
```

## Running Tests

The Turbolinks test suite is written in [TypeScript](https://www.typescriptlang.org) with the [Intern testing library](https://theintern.io).

To run the tests, first make sure you have the [Yarn package manager](https://yarnpkg.com) installed. Follow the instructions for _Building From Source_ above, then run the following commands:

```
$ cd test
$ yarn install
$ yarn test
```

If you are testing changes to the Turbolinks source, remember to run `bin/blade build` before each test run.

---

© 2018 Basecamp, LLC.
