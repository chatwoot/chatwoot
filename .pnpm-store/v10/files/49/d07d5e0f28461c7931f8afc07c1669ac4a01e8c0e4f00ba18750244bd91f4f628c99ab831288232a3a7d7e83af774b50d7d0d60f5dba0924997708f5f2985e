<div align="center">
    <img src="media/logo.svg" width="150" height="150">
    <h1>eslint-plugin-html</h1>
    <a href="https://www.npmjs.com/package/eslint-plugin-html"><img alt="NPM version" src="https://img.shields.io/npm/v/eslint-plugin-html.svg"></a>
    <a href="https://github.com/BenoitZugmeyer/eslint-plugin-html/actions?query=workflow%3ATests"><img alt="Tests Status" src="https://img.shields.io/github/workflow/status/BenoitZugmeyer/eslint-plugin-html/Tests"></a>
    <p>A <a href="http://eslint.org">ESLint</a> plugin to lint and fix inline scripts contained in HTML files.</p>
</div>

- [Usage](#usage)
- [Disabling ESLint](#disabling-eslint)
- [Linting HTML](#linting-html)
- [Multiple scripts tags in a HTML file](#multiple-scripts-tags-in-a-html-file)
  - [History](#history)
- [XML support](#xml-support)
- [Settings](#settings)
  - [`html/html-extensions`](#htmlhtml-extensions)
  - [`html/xml-extensions`](#htmlxml-extensions)
  - [`html/indent`](#htmlindent)
  - [`html/report-bad-indent`](#htmlreport-bad-indent)
  - [`html/javascript-tag-names`](#htmljavascript-tag-names)
  - [`html/javascript-mime-types`](#htmljavascript-mime-types)
- [Troubleshooting](#troubleshooting)
  - [No file linted when running `eslint` on a directory](#no-file-linted-when-running-eslint-on-a-directory)
  - [Linting templates (or PHP)](#linting-templates-or-php)
  - [Linting VUE files](#linting-vue-files)
- [Migration from older versions](#migration-from-older-versions)
  - [To v4](#to-v4)
  - [To v3](#to-v3)
- [Credits](#credits)

## Usage

Simply install via `npm install --save-dev eslint-plugin-html` and add the plugin to your ESLint
configuration. See
[ESLint documentation](http://eslint.org/docs/user-guide/configuring#configuring-plugins).

Example:

```javascript
{
    "plugins": [
        "html"
    ]
}
```

## Disabling ESLint

To temporarily disable ESLint, use the `<!-- eslint-disable -->` HTML comment. Re-enable it with
`<!-- eslint enable -->`. Example:

```html
<!-- eslint-disable -->
<script>
  var foo = 1
</script>
<!-- eslint-enable -->
```

To disable ESLint for the next script tag only, use the `<!-- eslint-disable-next-script -->` HTML
comment. Example:

```html
<!-- eslint-disable-next-script -->
<script>
  var foo = 1
</script>
```

Disabled script tags are completely ignored: their content will not be parsed as JavaScript. You can
use this to disable script tags containing template syntax.

## Linting HTML

This plugin focuses on applying ESLint rules on inline scripts contained in HTML. It does not
provide any rule related to HTML. For that, you can use other plugins like
[`@eslint-html`](https://yeonjuan.github.io/html-eslint/) or
[@angular-eslint](https://github.com/angular-eslint/angular-eslint). `eslint-plugin-html` is
compatible with those plugins and can be used along them.

## Multiple scripts tags in a HTML file

When linting a HTML with multiple script tags, this plugin tries to emulate the browser behavior by
sharing the global scope between scripts by default. This behavior doesn't apply to "module"
scripts (ie: `<script type="module">` and most transpiled code), where [each script tag gets its own
top-level scope](http://exploringjs.com/es6/ch_modules.html#_modules).

ESLint has already [an
option](https://eslint.org/docs/user-guide/configuring#specifying-parser-options) to tell the parser
if the script are modules. `eslint-plugin-html` will use this option as well to know if the scopes
should be shared (the default) or not. To change this, just set it in your ESLint configuration:

```
{
  "parserOptions": {
    "sourceType": "module"
  }
}
```

To illustrate this behavior, consider this HTML extract:

```html
<script>
  var foo = 1
</script>

<script>
  alert(foo)
</script>
```

This is perfectly valid by default, and the ESLint rules `no-unused-vars` and `no-undef` shouldn't
complain. But if those scripts are considerated as ES modules, `no-unused-vars` should report an
error in the first script, and `no-undef` should report an error in the second script.

### History

In `eslint-plugin-html` v1 and v2, script code were concatenated and linted in a single pass, so
the scope were always shared. This caused [some issues](MIGRATION_TO_V3.md), so in v3 all scripts
were linted separately, and scopes were never shared. In v4, the plugin still lint scripts
separately, but makes sure global variables are declared and used correctly in the non-module case.

## XML support

This plugin parses HTML and XML markup slightly differently, mainly when considering `CDATA`
sections:

- in XML, any data inside a `CDATA` section will be considered as raw text (not XML) and the `CDATA`
  delimiter will be droped ;
- in HTML, there is no such thing for `<script>` tags: the `CDATA` delimiter is considered as normal
  text and thus, part of the script.

## Settings

> Note: all settings can be written either as `"html/key": value` or in a nested object `"html": { "key": value }`

### `html/html-extensions`

By default, this plugin will only consider files ending with those extensions as HTML: `.erb`,
`.handlebars`, `.hbs`, `.htm`, `.html`, `.mustache`, `.nunjucks`, `.php`, `.tag`, `.twig`, `.we`.
You can set your own list of HTML extensions by using this setting. Example:

```javascript
{
    "plugins": [ "html" ],
    "settings": {
        "html/html-extensions": [".html", ".we"],  // consider .html and .we files as HTML
    }
}
```

### `html/xml-extensions`

By default, this plugin will only consider files ending with those extensions as XML: `.xhtml`,
`.xml`. You can set your own list of XML extensions by using this setting. Example:

```javascript
{
    "plugins": [ "html" ],
    "settings": {
        "html/xml-extensions": [".html"],  // consider .html files as XML
    }
}
```

### `html/indent`

By default, the code between `<script>` tags is dedented according to the first non-empty line. The
setting `html/indent` allows to ensure that every script tags follow an uniform indentation. Like
the `indent` rule, you can pass a number of spaces, or `"tab"` to indent with one tab. Prefix this
value with a `+` to be relative to the `<script>` tag indentation. Example:

```javascript
{
    "plugins": [ "html" ],
    "settings": {
        "html/indent": "0",   // code should start at the beginning of the line (no initial indentation).
        "html/indent": "+2",  // indentation is the <script> indentation plus two spaces.
        "html/indent": "tab", // indentation is one tab at the beginning of the line.
    }
}
```

### `html/report-bad-indent`

By default, this plugin won't warn if it encounters a problematic indentation (ex: a line is under
indented). If you want to make sure the indentation is correct, use the `html/report-bad-indent` in
conjunction with the `indent` rule. Pass `"warn"` or `1` to display warnings, `"error"` or `2` to
display errors. Example:

```javascript
{
    "plugins": [ "html" ],
    "settings": {
        "html/report-bad-indent": "error",
    }
}
```

### `html/javascript-tag-names`

By default, the code between `<script>` tags is considered as JavaScript. You can customize which
tags should be considered JavaScript by providing one or multiple tag names.

Example:

```javascript
{
    "plugins": [ "html" ],
    "settings": {
        "html/javascript-tag-names": ["script", "customscript"],
    }
}
```

### `html/javascript-mime-types`

By default, the code between `<script>` tags is considered as JavaScript code only if there is no
`type` attribute or if its value matches the pattern
`(application|text)/(x-)?(javascript|babel|ecmascript-6)` or `module` (case insensitive). You can
customize the types that should be considered as JavaScript by providing one or multiple MIME types.
If a MIME type starts with a `/`, it will be considered as a regular expression. Example:

```javascript
{
    "plugins": [ "html" ],
    "settings": {
        "html/javascript-mime-types": ["text/javascript", "text/jsx"],  // also use script tags with a "text/jsx" type attribute
        "html/javascript-mime-types": "/^text\\/(javascript|jsx)$/",    // same thing
    }
}
```

## Troubleshooting

### No file linted when running `eslint` on a directory

By default, when executing the `eslint` command on a directory, only `.js` files will be linted. You
will have to specify extra extensions with the `--ext` option. Example: `eslint --ext .html,.js src`
will lint both `.html` and `.js` files in the `src` directory. See [ESLint
documentation](http://eslint.org/docs/user-guide/command-line-interface#ext).

### Linting templates (or PHP)

`eslint-plugin-html` won't evaluate or remove your template markup. If you have template markup in
your script tags, the resulting script may not be valid JavaScript, so `ESLint` will fail to parse
it. Here are some workarounds:

- You can use [HTML comments to disable ESLint](#disabling-eslint) for specific script tags.

- For PHP, you can use
  [`eslint-plugin-php-markup`](https://github.com/tengattack/eslint-plugin-php-markup) to lint php
  files, it use a same way to process php markup like `eslint-plugin-html`.

- Another possible hacky workaround to make sure the code is valid JavaScript is to put your
  template markup inside a comment. When the template is rendered, the generated JS code must start
  with a new line, so it will be written below the comment. PHP example:

```html
<script>
  var mydata
  // <?= "\n mydata = " . json_encode($var) . ";" ?>
  console.log(mydata)
</script>
```

### Linting VUE files

Initially, [`eslint-plugin-vue`](https://github.com/vuejs/eslint-plugin-vue) was using
`eslint-plugin-html` to lint code inside script tags. Since v3, `eslint-plugin-vue` is using its
own parser, so it is _incompatible_ with `eslint-plugin-html`. You should use `eslint-plugin-vue`
exclusively and remove `eslint-plugin-html` from your dependencies if you still have it.

## Migration from older versions

### To v4

`eslint-plugin-html` v4 requires at least ESLint v4.7. This is because a lot of internal changes
occured in ESLint v4.7, including a [new API to support autofixing in
preprocessors](https://eslint.org/docs/developer-guide/working-with-plugins#processors-in-plugins).
If you are still using an older version of ESLint, please consider upgrading, or keep using
`eslint-plugin-html` v3.

The big feature (and breaking change) in `eslint-plugin-html` v4 is the ability to choose how [scopes
are shared between script tags in the same HTML file](#multiple-scripts-tags-in-a-html-file).

### To v3

If you are considering upgrading to v3, please read [this guide](MIGRATION_TO_V3.md).

## Credits

A big thank you to [@kuceb](https://github.com/kuceb) for the logo image!
