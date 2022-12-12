## Ansi to Html

[![](https://img.shields.io/travis/rburns/ansi-to-html.svg)](https://travis-ci.org/rburns/ansi-to-html/branches)
[![](https://img.shields.io/npm/v/ansi-to-html.svg)](https://www.npmjs.com/package/ansi-to-html)
![](https://img.shields.io/npm/dm/ansi-to-html.svg)

This was originally a port of the ansi to html converter from
[bcat](https://github.com/rtomayko/bcat/blob/master/lib/bcat/ansi.rb) to
JavaScript. It has since undergone quite a lot of modification.

It has a few additions:

* The API has been altered to accept options in the constructor, and input in `toHtml()`.
* ANSI codes for setting the foreground or background color to default are handled
* the 'erase in line' escape code (`\x1b[K`) is dropped from the output.

## Installation

```bash
npm install ansi-to-html
```

## Usage

```javascript
var Convert = require('ansi-to-html');
var convert = new Convert();

console.log(convert.toHtml('\x1b[30mblack\x1b[37mwhite'));

/*
    prints:
    <span style="color:#000">black<span style="color:#AAA">white</span></span>
*/
```

## Command line usage

When using ansi-to-html from the command line the stream option is set to `true`.
Other options can be provided. See `ansi-to-html -h` for more detail.

### Process a file

```bash
ansi-to-html the_filename
```

### From STDIN

```bash
git log | ansi-to-html
```

## Options

Options can be be passed to the constructor to customize behaviour.

**fg** `<CSS color values>`. The default foreground color used when reset color codes are encountered.

**bg** `<CSS color values>`. The default background color used when reset color codes are encountered.

**newline** `true` or `false`. Convert newline characters to `<br/>`.

**escapeXML** `true` or `false`. Generate HTML/XML entities.

**stream** `true` or `false`. Save style state across invocations of `toHtml()`.

**colors** `Object`/`Array` (with values 0 - 255 containing CSS color values). Can override specific colors or the entire ANSI palette

### Default options

```json5
{
    fg: '#FFF',
    bg: '#000',
    newline: false,
    escapeXML: false,
    stream: false
}
```

## Development

Once you have the git repository cloned, install the dependencies:

```bash
cd ansi-to-html
npm install
```

#### Lint

```bash
npm run lint
```

#### Build

```bash
npm run build
```

- Builds the `/src` files by running `babel`. 
- Saves the built files in `/lib` output directory. 
- Recommended to run `babel` in Watch mode - will re-build the project each time the files are changed.
```bash
npm run build:watch
```

#### Test

```bash
npm test
```
- Note: Runs the tests against the built files (in the `/lib` directory).
- You also run the tests in watch mode (will rerun tests when files are changed).
- Recommended to run the build in watch mode as well to re-build the project before the tests are run.

```bash
npm run test:watch
```

