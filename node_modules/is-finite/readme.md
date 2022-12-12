# is-finite [![Build Status](https://travis-ci.org/sindresorhus/is-finite.svg?branch=master)](https://travis-ci.org/sindresorhus/is-finite)

> ES2015 [`Number.isFinite()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/isFinite) [ponyfill](https://ponyfill.com)

## Install

```
$ npm install is-finite
```

## Usage

```js
var numIsFinite = require('is-finite');

numIsFinite(4);
//=> true

numIsFinite(Infinity);
//=> false
```

---

<div align="center">
	<b>
		<a href="https://tidelift.com/subscription/pkg/npm-is-finite?utm_source=npm-is-finite&utm_medium=referral&utm_campaign=readme">Get professional support for this package with a Tidelift subscription</a>
	</b>
	<br>
	<sub>
		Tidelift helps make open source sustainable for maintainers while giving companies<br>assurances about security, maintenance, and licensing for their dependencies.
	</sub>
</div>
