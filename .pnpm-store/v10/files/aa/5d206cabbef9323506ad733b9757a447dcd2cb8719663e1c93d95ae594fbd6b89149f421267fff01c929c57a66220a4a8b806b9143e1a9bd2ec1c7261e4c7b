# `<mwc-icon>` [![Published on npm](https://img.shields.io/npm/v/@material/mwc-icon.svg)](https://www.npmjs.com/package/@material/mwc-icon)
> IMPORTANT: The Material Web Components are a work in progress and subject to
> major changes until 1.0 release.

Icon displays an icon with a chosen name from the [Material Icons](https://material.io/resources/icons/) font, or from any
font that supports *ligatures*.

[Material Design Guidelines: System icons](https://material.io/design/iconography/system-icons.html)

[Demo](https://material-components.github.io/material-web/demos/icon/)

## Installation

```sh
npm install @material/mwc-icon
```

> NOTE: The Material Web Components are distributed as ES2017 JavaScript
> Modules, and use the Custom Elements API. They are compatible with all modern
> browsers including Chrome, Firefox, Safari, Edge, and IE11, but an additional
> tooling step is required to resolve *bare module specifiers*, as well as
> transpilation and polyfills for IE11. See
> [here](https://github.com/material-components/material-components-web-components#quick-start)
> for detailed instructions.

## Example usage

### Basic

<img src="https://raw.githubusercontent.com/material-components/material-components-web-components/1f19804bea995fc84ab35feb67668d9874ff10f9/packages/icon/images/shopping_cart.png" width="32px" height="32px">

```html
<link href="https://fonts.googleapis.com/css?family=Material+Icons&display=block" rel="stylesheet">

<mwc-icon>shopping_cart</mwc-icon>

<script type="module">
  import '@material/mwc-icon';
</script>
```

### As a link

<img src="https://raw.githubusercontent.com/material-components/material-components-web-components/1f19804bea995fc84ab35feb67668d9874ff10f9/packages/icon/images/arrow_back.png" width="32px" height="32px">

```html
<a href="index.html">
  <mwc-icon>arrow_back</mwc-icon>
</a>
```

### Styled

<img src="https://raw.githubusercontent.com/material-components/material-components-web-components/1f19804bea995fc84ab35feb67668d9874ff10f9/packages/icon/images/accessible_forward.png" width="64px" height="64px">

```html
<style>
  .fancy {
    color: #03a9f4;
    --mdc-icon-size: 64px;
  }
</style>

<mwc-icon class="fancy">accessible_forward</mwc-icon>
```

## Fonts

Most users should include the following in their application HTML when using
icons:

```html
<link href="https://fonts.googleapis.com/css?family=Material+Icons&display=block" rel="stylesheet">
```

This loads the *Material Icons* font, which is required to render icons, and is
*not* loaded automatically. If you see plain text instead of an icon, then the
most likely cause is that the Material Icons font is not loaded.

To see all icons that are available in the Material Icons font, see
[Material Icons](https://material.io/resources/icons/).

For technical details about the Material Icons font, see the
[Material Icons Developer Guide](https://google.github.io/material-design-icons/).


## API

### Slots

Name      | Description
--------- | -----------
*default* | The name of the icon to display (e.g. `shopping_cart`). See [Material Icons](https://material.io/resources/icons/) for an index of all available icons.


### Properties/Attributes

*None*

### Methods

*None*

### Events

*None*

### CSS Custom Properties

Name              | Default          | Description
----------------- | ---------------- | -----------
`--mdc-icon-font` | [`Material Icons`](https://material.io/resources/icons/) | Font that supports *ligatures* and determines which icons are available (see [fonts](#fonts) above).
`--mdc-icon-size` | `24px`           | Size of the icon.
