# vue-letter

Vue.js port of [react-letter](https://github.com/mat-sz/react-letter).

Available in [NPM](https://npmjs.com/package/vue-letter), can be installed with `yarn add vue-letter` or `npm install vue-letter`.

## Usage

```html
<template>
  <div id="app">
    <Letter html="<script>test</script> hello <h1>world</h1>" />
  </div>
</template>

<script>
  import Letter from 'vue-letter';

  export default {
    name: 'App',
    components: {
      Letter,
    },
  };
</script>
```

## Attributes

All [react-letter](https://github.com/mat-sz/react-letter) properties are supported.

| Attribute                | Type                       | Description                                                                                                  | Default                       |
| ------------------------ | -------------------------- | ------------------------------------------------------------------------------------------------------------ | ----------------------------- |
| className                | String                     | Class name of the wrapper div.                                                                               | `undefined`                   |
| html                     | String                     | Unsanitized e-mail HTML contents.                                                                            |                               |
| text                     | String                     | Unsanitized e-mail text contents (fallback if html is not set or empty).                                     |                               |
| useIframe                | Boolean                    | Should the HTML be wrapped in an iframe.                                                                     | `false`                       |
| iframeTitle              | String                     | Iframe title, usually set to subject of the message.                                                         |                               |
| rewriteExternalResources | Function(string) => string | The result of this function will be used to rewrite the URLs for url(...) in CSS and src attributes in HTML. |                               |
| rewriteExternalLinks     | Function(string) => string | The result of this function will be used to rewrite the URLs for href attributes in HTML.                    |                               |
| allowedSchemas           | String[]                   | List of allowed URL schemas.                                                                                 | `['http', 'https', 'mailto']` |
| preserveCssPriority      | Boolean                    | Preserves CSS priority (!important).                                                                         | `true`                        |
