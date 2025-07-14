# markdown-it-sup

[![CI](https://github.com/markdown-it/markdown-it-sup/actions/workflows/ci.yml/badge.svg)](https://github.com/markdown-it/markdown-it-sup/actions/workflows/ci.yml)
[![NPM version](https://img.shields.io/npm/v/markdown-it-sup.svg?style=flat)](https://www.npmjs.org/package/markdown-it-sup)
[![Coverage Status](https://img.shields.io/coveralls/markdown-it/markdown-it-sup/master.svg?style=flat)](https://coveralls.io/r/markdown-it/markdown-it-sup?branch=master)

> Superscript (`<sup>`) tag plugin for [markdown-it](https://github.com/markdown-it/markdown-it) markdown parser.

__v1.+ requires `markdown-it` v4.+, see changelog.__

`29^th^` => `29<sup>th</sup>`

Markup is based on [pandoc](http://johnmacfarlane.net/pandoc/README.html#superscripts-and-subscripts) definition. But nested markup is currently not supported.


## Install

node.js, browser:

```bash
npm install markdown-it-sup --save
bower install markdown-it-sup --save
```

## Use

```js
var md = require('markdown-it')()
            .use(require('markdown-it-sup'));

md.render('29^th^') // => '<p>29<sup>th</sup></p>'
```

_Differences in browser._ If you load script directly into the page, without
package system, module will add itself globally as `window.markdownitSup`.


## License

[MIT](https://github.com/markdown-it/markdown-it-sup/blob/master/LICENSE)
