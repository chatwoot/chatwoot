[![npm version](https://badge.fury.io/js/url-toolkit.svg)](https://badge.fury.io/js/url-toolkit)

# URL Toolkit

Lightweight library to build an absolute URL from a base URL and a relative URL, written from [the spec (RFC 1808)](https://tools.ietf.org/html/rfc1808). Initially part of [HLS.JS](https://github.com/video-dev/hls.js).

## Differences to JS `URL()`

The JS [URL()](https://developer.mozilla.org/en-US/docs/Web/API/URL/URL) function also lets you calculate a new URL from a base and relative one.

That uses the [URL Living Standard](https://url.spec.whatwg.org/) which is slightly different to [RFC 1808](https://tools.ietf.org/html/rfc1808) that this library implements.

One of the key differences is that the [URL Living Standard](https://url.spec.whatwg.org/) has the concept of a ['special url'](https://url.spec.whatwg.org/#is-special) and ['special scheme'](https://url.spec.whatwg.org/#special-scheme). For these special URL's, such as a URL with the `http` scheme, they normalise them in a way that results in `http:///example.com/something` becoming `http://example.com/something`. This library does not do that and [`parseURL()`](#parseurlurl) would give you `//` as the `netLoc` and `/example.com` as the path.

## Methods

### `buildAbsoluteURL(baseURL, relativeURL, opts={})`

Build an absolute URL from a relative and base one.

```javascript
URLToolkit.buildAbsoluteURL('http://a.com/b/cd', 'e/f/../g'); // => http://a.com/b/e/g
```

If you want to ensure that the URL is treated as a relative one you should prefix it with `./`.

```javascript
URLToolkit.buildAbsoluteURL('http://a.com/b/cd', 'a:b'); // => a:b
URLToolkit.buildAbsoluteURL('http://a.com/b/cd', './a:b'); // => http://a.com/b/a:b
```

By default the paths will not be normalized unless necessary, according to the spec. However you can ensure paths are always normalized by setting the `opts.alwaysNormalize` option to `true`.

```javascript
URLToolkit.buildAbsoluteURL('http://a.com/b/cd', '/e/f/../g'); // => http://a.com/e/f/../g
URLToolkit.buildAbsoluteURL('http://a.com/b/cd', '/e/f/../g', {
  alwaysNormalize: true,
}); // => http://a.com/e/g
```

### `normalizePath(url)`

Normalizes a path.

```javascript
URLToolkit.normalizePath('a/b/../c'); // => a/c
```

### `parseURL(url)`

Parse a URL into its separate components.

```javascript
URLToolkit.parseURL('http://a/b/c/d;p?q#f'); // =>
/* {
	scheme: 'http:',
	netLoc: '//a',
	path: '/b/c/d',
	params: ';p',
	query: '?q',
	fragment: '#f'
} */
```

### `buildURLFromParts(parts)`

Puts all the parts from `parseURL()` back together into a string.

## Example

```javascript
var URLToolkit = require('url-toolkit');
var url = URLToolkit.buildAbsoluteURL(
  'https://a.com/b/cd/e.m3u8?test=1#something',
  '../z.ts?abc=1#test'
);
console.log(url); // 'https://a.com/b/z.ts?abc=1#test'
```

## Browser

This can also be used in the browser thanks to [jsDelivr](https://github.com/jsdelivr/jsdelivr):

```html
<head>
  <script
    type="text/javascript"
    src="https://cdn.jsdelivr.net/npm/url-toolkit@2"
  ></script>
  <script type="text/javascript">
    var url = URLToolkit.buildAbsoluteURL(
      'https://a.com/b/cd/e.m3u8?test=1#something',
      '../z.ts?abc=1#test'
    );
    console.log(url); // 'https://a.com/b/z.ts?abc=1#test'
  </script>
</head>
```
