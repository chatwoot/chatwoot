# DOMPurify

[![npm version](https://badge.fury.io/js/dompurify.svg)](http://badge.fury.io/js/dompurify)  ![Build and Test](https://github.com/cure53/DOMPurify/workflows/Build%20and%20Test/badge.svg?branch=main)  [![Downloads](https://img.shields.io/npm/dm/dompurify.svg)](https://www.npmjs.com/package/dompurify)  [![minified size](https://badgen.net/bundlephobia/min/dompurify?color=green&label=minified)](https://cdn.jsdelivr.net/npm/dompurify/dist/purify.min.js)  [![gzip size](https://badgen.net/bundlephobia/minzip/dompurify?color=green&label=gzipped)](https://packagephobia.now.sh/result?p=dompurify)  [![dependents](https://badgen.net/github/dependents-repo/cure53/dompurify?color=green&label=dependents)](https://github.com/cure53/DOMPurify/network/dependents)

[![NPM](https://nodei.co/npm/dompurify.png)](https://nodei.co/npm/dompurify/)

DOMPurify is a DOM-only, super-fast, uber-tolerant XSS sanitizer for HTML, MathML and SVG.

It's also very simple to use and get started with. DOMPurify was [started in February 2014](https://github.com/cure53/DOMPurify/commit/a630922616927373485e0e787ab19e73e3691b2b) and, meanwhile, has reached version 2.2.7.

DOMPurify is written in JavaScript and works in all modern browsers (Safari (10+), Opera (15+), Internet Explorer (10+), Edge, Firefox and Chrome - as well as almost anything else using Blink or WebKit). It doesn't break on MSIE6 or other legacy browsers. It either uses [a fall-back](#what-about-older-browsers-like-msie8) or simply does nothing.

Our automated tests cover [15 different browsers](https://github.com/cure53/DOMPurify/blob/main/test/karma.custom-launchers.config.js#L5) right now, more to come. We also cover Node.js v14.15.1, v15.4.0, running DOMPurify on [jsdom](https://github.com/tmpvar/jsdom). Older Node.js versions are known to work as well.

DOMPurify is written by security people who have vast background in web attacks and XSS. Fear not. For more details please also read about our [Security Goals & Threat Model](https://github.com/cure53/DOMPurify/wiki/Security-Goals-&-Threat-Model). Please, read it. Like, really.

## What does it do?

DOMPurify sanitizes HTML and prevents XSS attacks. You can feed DOMPurify with string full of dirty HTML and it will return a string (unless configured otherwise) with clean HTML. DOMPurify will strip out everything that contains dangerous HTML and thereby prevent XSS attacks and other nastiness. It's also damn bloody fast. We use the technologies the browser provides and turn them into an XSS filter. The faster your browser, the faster DOMPurify will be.

## How do I use it?

It's easy. Just include DOMPurify on your website.

### Using the unminified development version

```html
<script type="text/javascript" src="src/purify.js"></script>
```

### Using the minified and tested production version (source-map available)

```html
<script type="text/javascript" src="dist/purify.min.js"></script>
```

Afterwards you can sanitize strings by executing the following code:

```js
let clean = DOMPurify.sanitize( dirty );
```

The resulting HTML can be written into a DOM element using `innerHTML` or the DOM using `document.write()`. That is fully up to you. 
Note that by default, we permit HTML, SVG **and** MathML. If you only need HTML, which might be a very common use-case, you can easily set that up as well:

```js
let clean = DOMPurify.sanitize( dirty , {USE_PROFILES: {html: true}} );
```

### Is there any foot-gun potential?

Well, please note, if you _first_ sanitize HTML and then modify it _afterwards_, you might easily **void the effects of sanitization**. If you feed the sanitized markup to another library _after_ sanitization, please be certain that the library doesn't mess around with the HTML on its own.

### Okay, makes sense, let's move on

After sanitizing your markup, you can also have a look at the property `DOMPurify.removed` and find out, what elements and attributes were thrown out. Please **do not use** this property for making any security critical decisions. This is just a little helper for curious minds.

If you're using an [AMD](https://github.com/amdjs/amdjs-api/wiki/AMD) module loader like [Require.js](http://requirejs.org/), you can load this script asynchronously as well:

```js
import DOMPurify from 'dompurify';

var clean = DOMPurify.sanitize(dirty);
```

DOMPurify also works server-side with Node.js as well as client-side via [Browserify](http://browserify.org/) or similar translators. At least Node.js 4.x or newer is required. Our support strives to follow the [Node.js release cycle](https://nodejs.org/en/about/releases/). DOMPurify intends to support any version being flagged as active. At the same time we phase out support for any version flagged as maintenance. DOMPurify might not break with all versions in maintenance immediately but stops to run tests against these older versions.

```bash
npm install dompurify
```

For JSDOM v10 or newer

```js
const createDOMPurify = require('dompurify');
const { JSDOM } = require('jsdom');

const window = new JSDOM('').window;
const DOMPurify = createDOMPurify(window);

const clean = DOMPurify.sanitize(dirty);
```

For JSDOM versions older than v10

```js
const createDOMPurify = require('dompurify');
const jsdom = require('jsdom').jsdom;

const window = jsdom('').defaultView;
const DOMPurify = createDOMPurify(window);

const clean = DOMPurify.sanitize(dirty);
```

## Is there a demo?

Of course there is a demo! [Play with DOMPurify](https://cure53.de/purify)

## What if I find a _security_ bug?

First of all, please immediately contact us via [email](mailto:mario@cure53.de) so we can work on a fix. [PGP key](https://keyserver.ubuntu.com/pks/lookup?op=vindex&search=0xC26C858090F70ADA)

Also, you probably qualify for a bug bounty! The fine folks over at [Fastmail](https://www.fastmail.com/) use DOMPurify for their services and added our library to their bug bounty scope. So, if you find a way to bypass or weaken DOMPurify, please also have a look at their website and the [bug bounty info](https://www.fastmail.com/about/bugbounty.html).

## Some purification samples please?

How does purified markup look like? Well, [the demo](https://cure53.de/purify) shows it for a big bunch of nasty elements. But let's also show some smaller examples!

```js
DOMPurify.sanitize('<img src=x onerror=alert(1)//>'); // becomes <img src="x">
DOMPurify.sanitize('<svg><g/onload=alert(2)//<p>'); // becomes <svg><g></g></svg>
DOMPurify.sanitize('<p>abc<iframe//src=jAva&Tab;script:alert(3)>def</p>'); // becomes <p>abc</p>
DOMPurify.sanitize('<math><mi//xlink:href="data:x,<script>alert(4)</script>">'); // becomes <math><mi></mi></math>
DOMPurify.sanitize('<TABLE><tr><td>HELLO</tr></TABL>'); // becomes <table><tbody><tr><td>HELLO</td></tr></tbody></table>
DOMPurify.sanitize('<UL><li><A HREF=//google.com>click</UL>'); // becomes <ul><li><a href="//google.com">click</a></li></ul>
```

## What is supported?

DOMPurify currently supports HTML5, SVG and MathML. DOMPurify per default allows CSS, HTML custom data attributes. DOMPurify also supports the Shadow DOM - and sanitizes DOM templates recursively. DOMPurify also allows you to sanitize HTML for being used with the jQuery `$()` and `elm.html()` API without any known problems.

## What about older browsers like MSIE8?

DOMPurify offers a fall-back behavior for older MSIE browsers. It uses the MSIE-only `toStaticHTML` feature to sanitize. Note however that in this fall-back mode, pretty much none of the configuration flags shown below have any effect. You need to handle that yourself.

If not even `toStaticHTML` is supported, DOMPurify does nothing at all. It simply returns exactly the string that you fed it.

DOMPurify also exposes a property called `isSupported`, which tells you whether DOMPurify will be able to do its job.

## What about DOMPurify and Trusted Types?

In version 1.0.9, support for [Trusted Types API](https://github.com/WICG/trusted-types) was added to DOMPurify.
In version 2.0.0, a config flag was added to control DOMPurify's behavior regarding this.

When `DOMPurify.sanitize` is used in an environment where the Trusted Types API is available and `RETURN_TRUSTED_TYPE` is set to `true`, it tries to return a `TrustedHTML` value instead of a string (the behavior for `RETURN_DOM`, `RETURN_DOM_FRAGMENT`, and `RETURN_DOM_IMPORT` config options does not change).

## Can I configure DOMPurify?

Yes. The included default configuration values are pretty good already - but you can of course override them. Check out the [`/demos`](https://github.com/cure53/DOMPurify/tree/main/demos) folder to see a bunch of examples on how you can [customize DOMPurify](https://github.com/cure53/DOMPurify/tree/main/demos#what-is-this).

```js
/**
 * General settings
 */

// strip {{ ... }} and <% ... %> to make output safe for template systems
// be careful please, this mode is not recommended for production usage.
// allowing template parsing in user-controlled HTML is not advised at all.
// only use this mode if there is really no alternative.
var clean = DOMPurify.sanitize(dirty, {SAFE_FOR_TEMPLATES: true});

/**
 * Control our allow-lists and block-lists
 */
// allow only <b> elements, very strict
var clean = DOMPurify.sanitize(dirty, {ALLOWED_TAGS: ['b']});

// allow only <b> and <q> with style attributes
var clean = DOMPurify.sanitize(dirty, {ALLOWED_TAGS: ['b', 'q'], ALLOWED_ATTR: ['style']});

// allow all safe HTML elements but neither SVG nor MathML
// note that the USE_PROFILES setting will override the ALLOWED_TAGS setting
// so don't use them together
var clean = DOMPurify.sanitize(dirty, {USE_PROFILES: {html: true}});

// allow all safe SVG elements and SVG Filters, no HTML or MathML
var clean = DOMPurify.sanitize(dirty, {USE_PROFILES: {svg: true, svgFilters: true}});

// allow all safe MathML elements and SVG, but no SVG Filters
var clean = DOMPurify.sanitize(dirty, {USE_PROFILES: {mathMl: true, svg: true}});

// leave all safe HTML as it is and add <style> elements to block-list
var clean = DOMPurify.sanitize(dirty, {FORBID_TAGS: ['style']});

// leave all safe HTML as it is and add style attributes to block-list
var clean = DOMPurify.sanitize(dirty, {FORBID_ATTR: ['style']});

// extend the existing array of allowed tags and add <my-tag> to allow-list
var clean = DOMPurify.sanitize(dirty, {ADD_TAGS: ['my-tag']});

// extend the existing array of allowed attributes and add my-attr to allow-list
var clean = DOMPurify.sanitize(dirty, {ADD_ATTR: ['my-attr']});

// prohibit HTML5 data attributes, leave other safe HTML as is (default is true)
var clean = DOMPurify.sanitize(dirty, {ALLOW_DATA_ATTR: false});

/**
 * Control behavior relating to URI values
 */
// extend the existing array of elements that can use Data URIs
var clean = DOMPurify.sanitize(dirty, {ADD_DATA_URI_TAGS: ['a', 'area']});

// extend the existing array of elements that are safe for URI-like values (be careful, XSS risk)
var clean = DOMPurify.sanitize(dirty, {ADD_URI_SAFE_ATTR: ['my-attr']});

/**
 * Control permitted attribute values
 */
// allow external protocol handlers in URL attributes (default is false, be careful, XSS risk)
// by default only http, https, ftp, ftps, tel, mailto, callto, cid and xmpp are allowed.
var clean = DOMPurify.sanitize(dirty, {ALLOW_UNKNOWN_PROTOCOLS: true});

// allow specific protocols handlers in URL attributes via regex (default is false, be careful, XSS risk)
// by default only http, https, ftp, ftps, tel, mailto, callto, cid and xmpp are allowed.
// Default RegExp: /^(?:(?:(?:f|ht)tps?|mailto|tel|callto|cid|xmpp):|[^a-z]|[a-z+.\-]+(?:[^a-z+.\-:]|$))/i;
var clean = DOMPurify.sanitize(dirty, {ALLOWED_URI_REGEXP: /^(?:(?:(?:f|ht)tps?|mailto|tel|callto|cid|xmpp|xxx):|[^a-z]|[a-z+.\-]+(?:[^a-z+.\-:]|$))/i;});

/**
 * Influence the return-type
 *
 * Careful, this setting has foot-gun potential! If you set RETURN_DOM or RETURN_DOM_FRAGMENT to true, don't set RETURN_DOM_IMPORT to false!
 * By default, our settings are secure - we believe - but returning a DOM *and* manually setting RETURN_DOM_IMPORT to false will give you XSS in some situations.
 */
// return a DOM HTMLBodyElement instead of an HTML string (default is false)
var clean = DOMPurify.sanitize(dirty, {RETURN_DOM: true});

// return a DOM DocumentFragment instead of an HTML string (default is false)
var clean = DOMPurify.sanitize(dirty, {RETURN_DOM_FRAGMENT: true});

// return a DOM DocumentFragment instead of an HTML string (default is false)
// also import it into the current document (default is false).
// RETURN_DOM_IMPORT must be set if you would like to append
// the returned node to the current document (default is true)
var clean = DOMPurify.sanitize(dirty, {RETURN_DOM_FRAGMENT: true, RETURN_DOM_IMPORT: true});
document.body.appendChild(clean);

// use the RETURN_TRUSTED_TYPE flag to turn on Trusted Types support if available
var clean = DOMPurify.sanitize(dirty, {RETURN_TRUSTED_TYPE: true}); // will return a TrustedHTML object instead of a string if possible

/**
 * Influence how we sanitize
 */
// return entire document including <html> tags (default is false)
var clean = DOMPurify.sanitize(dirty, {WHOLE_DOCUMENT: true});

// disable DOM Clobbering protection on output (default is true, handle with care, minor XSS risks here)
var clean = DOMPurify.sanitize(dirty, {SANITIZE_DOM: false});

// keep an element's content when the element is removed (default is true)
var clean = DOMPurify.sanitize(dirty, {KEEP_CONTENT: false});

// glue elements like style, script or others to document.body and prevent unintuitive browser behavior in several edge-cases (default is false)
var clean = DOMPurify.sanitize(dirty, {FORCE_BODY: true});

/**
 * Influence where we sanitize
 */
// use the IN_PLACE mode to sanitize a node "in place", which is much faster depending on how you use DOMPurify
var dirty = document.createElement('a');
dirty.setAttribute('href', 'javascript:alert(1)');
var clean = DOMPurify.sanitize(dirty, {IN_PLACE: true}); // see https://github.com/cure53/DOMPurify/issues/288 for more info
```

There is even [more examples here](https://github.com/cure53/DOMPurify/tree/main/demos#what-is-this), showing how you can run, customize and configure DOMPurify to fit your needs.

## Persistent Configuration

Instead of repeatedly passing the same configuration to `DOMPurify.sanitize`, you can use the `DOMPurify.setConfig` method. Your configuration will persist until your next call to `DOMPurify.setConfig`, or until you invoke `DOMPurify.clearConfig` to reset it. Remember that there is only one active configuration, which means once it is set, all extra configuration parameters passed to `DOMPurify.sanitize` are ignored.

## Hooks

DOMPurify allows you to augment its functionality by attaching one or more functions with the `DOMPurify.addHook` method to one of the following hooks:

- `beforeSanitizeElements`
- `uponSanitizeElement` (No 's' - called for every element)
- `afterSanitizeElements`
- `beforeSanitizeAttributes`
- `uponSanitizeAttribute`
- `afterSanitizeAttributes`
- `beforeSanitizeShadowDOM`
- `uponSanitizeShadowNode`
- `afterSanitizeShadowDOM`

It passes the currently processed DOM node, when needed a literal with verified node and attribute data and the DOMPurify configuration to the callback. Check out the [MentalJS hook demo](https://github.com/cure53/DOMPurify/blob/main/demos/hooks-mentaljs-demo.html) to see how the API can be used nicely.

_Example_:

```js
DOMPurify.addHook('beforeSanitizeElements', function (
  currentNode,
  hookEvent,
  config
) {
  // Do something with the current node and return it
  // You can also mutate hookEvent (i.e. set hookEvent.forceKeepAttr = true)
  return currentNode;
});
```

## Continuous Integration

We are currently using Github Actions in combination with BrowserStack. This gives us the possibility to confirm for each and every commit that all is going according to plan in all supported browsers. Check out the build logs here: https://github.com/cure53/DOMPurify/actions

You can further run local tests by executing `npm test`. The tests work fine with Node.js v0.6.2 and jsdom@8.5.0.

All relevant commits will be signed with the key `0x24BB6BF4` for additional security (since 8th of April 2016).

### Development and contributing

#### Installation (`yarn i`)

We support both `yarn` and `npm@5.2` officially while providing lock-files for either dependency manager to provide reproducible installs and builds on either or. TravisCI itself is configured to install dependencies using `yarn`. When using an older version of `npm` we can not fully ensure the versions of installed dependencies which might lead to unanticipated problems.

#### Scripts

We rely on npm run-scripts for integrating with our tooling infrastructure. We use ESLint as a pre-commit hook to ensure code consistency. Moreover, to ease formatting we use [prettier](https://github.com/prettier/prettier) while building the `/dist` assets happens through `rollup`.

These are our npm scripts:

- `npm run dev` to start building while watching sources for changes
- `npm run test` to run our test suite via jsdom and karma
  - `test:jsdom` to only run tests through jsdom
  - `test:karma` to only run tests through karma
- `npm run lint` to lint the sources using ESLint (via xo)
- `npm run format` to format our sources using prettier to ease to pass ESLint
- `npm run build` to build our distribution assets minified and unminified as a UMD module
  - `npm run build:umd` to only build an unminified UMD module
  - `npm run build:umd:min` to only build a minified UMD module

Note: all run scripts triggered via `npm run <script>` can also be started using `yarn <script>`.

There are more npm scripts but they are mainly to integrate with CI or are meant to be "private" for instance to amend build distribution files with every commit.

## Security Mailing List

We maintain a mailing list that notifies whenever a security-critical release of DOMPurify was published. This means, if someone found a bypass and we fixed it with a release (which always happens when a bypass was found) a mail will go out to that list. This usually happens within minutes or few hours after learning about a bypass. The list can be subscribed to here:

[https://lists.ruhr-uni-bochum.de/mailman/listinfo/dompurify-security](https://lists.ruhr-uni-bochum.de/mailman/listinfo/dompurify-security)

Feature releases will not be announced to this list.

## Who contributed?

Many people helped and help DOMPurify become what it is and need to be acknowledged here!

[granlem 💸](https://twitter.com/MaximeVeit), [oreoshake 💸](https://github.com/oreoshake), [dcramer 💸](https://github.com/dcramer),[tdeekens ❤️](https://github.com/tdeekens), [peernohell ❤️](https://github.com/peernohell), [neilj](https://github.com/neilj), [fhemberger](https://github.com/fhemberger), [Joris-van-der-Wel](https://github.com/Joris-van-der-Wel), [ydaniv](https://github.com/ydaniv), [terjanq](https://twitter.com/terjanq), [filedescriptor](https://github.com/filedescriptor), [ConradIrwin](https://github.com/ConradIrwin), [gibson042](https://github.com/gibson042), [choumx](https://github.com/choumx), [0xSobky](https://github.com/0xSobky), [styfle](https://github.com/styfle), [koto](https://github.com/koto), [tlau88](https://github.com/tlau88), [strugee](https://github.com/strugee), [oparoz](https://github.com/oparoz), [mathiasbynens](https://github.com/mathiasbynens), [edg2s](https://github.com/edg2s), [dnkolegov](https://github.com/dnkolegov), [dhardtke](https://github.com/dhardtke), [wirehead](https://github.com/wirehead), [thorn0](https://github.com/thorn0), [styu](https://github.com/styu), [mozfreddyb](https://github.com/mozfreddyb), [mikesamuel](https://github.com/mikesamuel), [jorangreef](https://github.com/jorangreef), [jimmyhchan](https://github.com/jimmyhchan), [jameydeorio](https://github.com/jameydeorio), [jameskraus](https://github.com/jameskraus), [hyderali](https://github.com/hyderali), [hansottowirtz](https://github.com/hansottowirtz), [hackvertor](https://github.com/hackvertor), [freddyb](https://github.com/freddyb), [flavorjones](https://github.com/flavorjones), [djfarrelly](https://github.com/djfarrelly), [devd](https://github.com/devd), [camerondunford](https://github.com/camerondunford), [buu700](https://github.com/buu700), [buildog](https://github.com/buildog), [alabiaga](https://github.com/alabiaga), [Vector919](https://github.com/Vector919), [Robbert](https://github.com/Robbert), [GreLI](https://github.com/GreLI), [FuzzySockets](https://github.com/FuzzySockets), [ArtemBernatskyy](https://github.com/ArtemBernatskyy), [@garethheyes](https://twitter.com/garethheyes), [@shafigullin](https://twitter.com/shafigullin), [@mmrupp](https://twitter.com/mmrupp), [@irsdl](https://twitter.com/irsdl),[ShikariSenpai](https://github.com/ShikariSenpai), [ansjdnakjdnajkd](https://github.com/ansjdnakjdnajkd), [@asutherland](https://twitter.com/asutherland), [@mathias](https://twitter.com/mathias), [@cgvwzq](https://twitter.com/cgvwzq), [@robbertatwork](https://twitter.com/robbertatwork), [@giutro](https://twitter.com/giutro), [@CmdEngineer_](https://twitter.com/CmdEngineer_), [@avr4mit](https://twitter.com/avr4mit) and especially [@securitymb ❤️](https://twitter.com/securitymb) & [@masatokinugawa ❤️](https://twitter.com/masatokinugawa)

## Testing powered by 
<a target="_blank" href="https://www.browserstack.com/"><img width="200" src="https://www.browserstack.com/images/layout/browserstack-logo-600x315.png"></a><br>

And last but not least, thanks to [BrowserStack Open-Source Program](https://www.browserstack.com/open-source) for supporting this project with their services for free and delivering excellent, dedicated and very professional support on top of that.
