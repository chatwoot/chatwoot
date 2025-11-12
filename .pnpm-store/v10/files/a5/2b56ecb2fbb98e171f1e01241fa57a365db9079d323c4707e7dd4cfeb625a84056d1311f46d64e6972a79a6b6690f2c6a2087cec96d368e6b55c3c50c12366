<h1 align="center">lettersanitizer</h1>

<p align="center">
DOM-based HTML email sanitizer for in-browser email rendering.
</p>

<p align="center">
<img alt="workflow" src="https://img.shields.io/github/actions/workflow/status/mat-sz/lettersanitizer/node.js.yml?branch=main">
<a href="https://npmjs.com/package/lettersanitizer">
<img alt="npm" src="https://img.shields.io/npm/v/lettersanitizer">
<img alt="npm" src="https://img.shields.io/npm/dw/lettersanitizer">
<img alt="NPM" src="https://img.shields.io/npm/l/lettersanitizer">
</a>
</p>

Used in [react-letter](https://github.com/mat-sz/react-letter) and [vue-letter](https://github.com/mat-sz/vue-letter).

## Installation

**lettersanitizer** is available on [npm](https://www.npmjs.com/package/lettersanitizer), you can install it with either npm or yarn:

```sh
npm install lettersanitizer
# or:
yarn install lettersanitizer
```

## Example usage

```ts
import { sanitize } from 'lettersanitizer';

sanitize('<b>test</b><script>test</script>', '', { id: 'test' });
// <div id="test"><b>test</b></div>
```

### sanitize function

**lettersanitizer** exposes a `sanitize` function that uses DOMParser to sanitize the HTML content of messages and returns HTML text.

`text` is used for fallback text in case of no HTML source being available. Plain text in that case is processed into safe HTML output.

```ts
interface SanitizerOptions {
  id?: string;
  dropAllHtmlTags?: boolean;
  rewriteExternalResources?: (url: string) => string;
  rewriteExternalLinks?: (url: string) => string;
  allowedSchemas?: string[];
  preserveCssPriority?: boolean;
  noWrapper?: boolean;
}

function sanitize(html: string, text?: string, options?: SanitizerOptions);
```
