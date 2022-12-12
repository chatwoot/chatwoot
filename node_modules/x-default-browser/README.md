# x-default-browser
 [![Build Status](https://secure.travis-ci.org/jakub-g/x-default-browser.png)](http://travis-ci.org/jakub-g/x-default-browser)

 [![Get it on npm](https://nodei.co/npm/x-default-browser.png?compact=true)](https://www.npmjs.org/package/x-default-browser)


This *cross-platform* module finds out the default browser for current user.

Tested on Windows 7 64-bit, Windows XP 32-bit, Ubuntu 14.04 64-bit (en-US locale), Mac OS X.


It requires nodejs and npm. If you don't have node, grab it at [nodejs.org](https://nodejs.org).
Node installer bundles npm (node package manager)


## How it works

* Windows:
  * checks registry value `HKCU\Software\Clients\StartMenuInternet`
* Linuxes:
  * reads the output of `xdg-mime query default x-scheme-handler/http`
* OS X:
  * delegated to [default-browser-id from Sindre Sorhus](https://github.com/sindresorhus/default-browser-id)


## Usage as a nodejs module

```sh
$ npm install x-default-browser
```

```js
var defaultBrowser = require('x-default-browser');

defaultBrowser(function (err, res) {

    // in case of error, `err` will be a string with error message; otherwise it's `null`.

    console.dir(res);
    // => {
    //  isIE: false,
    //  isFirefox: true,
    //  isChrome: false,
    //  isChromium: false,
    //  isOpera: false,
    //  isWebkit: false,
    //  identity: 'firefox.exe',
    //  commonName: 'firefox'
    // }
});
```

* `commonName` is portable, it will be `ie`, `safari`, `firefox`, `chrome`, `chromium`, `opera` or `unknown`
* `isBlink` is true for Chrome, Chromium, Opera
* `isWebkit` is true for Chrome, Chromium, Opera, Safari
* `identity` key is platform-specific.
  * On Windows, it's the prefix you can use for querying `HKLM\Software\Clients\StartMenuInternet\<prefix>`
    keys to find out details of the browser. It'll be one of `iexplore.exe`, `firefox.exe`, `google chrome`,
    `chromium.<somerandomkeyhere>`, `operastable`.
  * On Ubuntu, it will be `firefox.desktop`, `google-chrome.desktop`, `chromium-browser.desktop` or `opera.desktop`
  * On Mac OS X, it will be the bundle ID: `com.apple.Safari`, `com.google.chrome`, `com.operasoftware.Opera`, `org.mozilla.firefox` etc

## Usage from command line

```sh
$ npm install -g x-default-browser
$ x-default-browser
firefox
```

Command line version outputs the `commonName` key, i.e.  `ie`, `safari`, `firefox`, `chrome`, `chromium`, `opera` or `unknown`.


## Linux support

This module was only tested on Ubuntu. Compatibility reports and fixes for other distros are more than welcome!
Use GitHub issues or email: (jakub.g.opensource) (gmail)


## License

MIT © [Jakub Gieryluk](http://jakub-g.github.io)


## Related projects

*   [default-browser-id](https://github.com/sindresorhus/default-browser-id) (OS X)
* [win-detect-browsers](https://github.com/vweevers/win-detect-browsers) (Windows)
*   [browser-launcher2](https://github.com/benderjs/browser-launcher2) (cross-platform)
*              [opener](https://github.com/domenic/opener) (cross-platform)
*           [node-open](https://github.com/pwnall/node-open) (cross-platform)
