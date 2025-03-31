# @lit-labs/ssr-dom-shim

## Overview

This package provides minimal implementations of `Element`, `HTMLElement`,
`CustomElementRegistry`, and `customElements`, designed to be used when Server
Side Rendering (SSR) web components from Node, including Lit components.

## Usage

### Usage from Lit

Lit itself automatically imports these shims when running in Node, so Lit users
should typically not need to directly depend on or import from this package.

See the [lit.dev SSR docs](https://lit.dev/docs/ssr/overview/) for general
information about server-side rendering with Lit.

### Usage in other contexts

Other libraries or frameworks who wish to support SSR are welcome to also depend
on these shims. (This package is planned to eventually move to
`@webcomponents/ssr-dom-shim` to better reflect this use case). There are two
main patterns for providing access to these shims to users:

1. Assigning shims to `globalThis`, ensuring that assignment occurs before
   user-code runs.

2. Importing shims directly from the module that provides your base class, using
   the `node` [export
   condition](https://nodejs.org/api/packages.html#conditional-exports) to
   ensure this only happens when running in Node, and not in the browser.

Lit takes approach #2 for all of the shims except for `customElements`, so that
users who have imported `lit` are able to call `customElements.define` in their
components from Node.

### Exports

The main module exports the following values. Note that no globals are set by
this module.

- [`Element`](https://developer.mozilla.org/en-US/docs/Web/API/Element)
  - [`attachShadow`](https://developer.mozilla.org/en-US/docs/Web/API/Element/attachShadow)
  - [`shadowRoot`](https://developer.mozilla.org/en-US/docs/Web/API/Element/shadowRoot)
  - [`attributes`](https://developer.mozilla.org/en-US/docs/Web/API/Element/attributes)
  - [`hasAttribute`](https://developer.mozilla.org/en-US/docs/Web/API/Element/hasAttribute)
  - [`getAttribute`](https://developer.mozilla.org/en-US/docs/Web/API/Element/getAttribute)
  - [`setAttribute`](https://developer.mozilla.org/en-US/docs/Web/API/Element/setAttribute)
  - [`removeAttribute`](https://developer.mozilla.org/en-US/docs/Web/API/Element/removeAttribute)
- [`HTMLElement`](https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement)
  - (Inherits from Element)
- [`CustomElementRegistry`](https://developer.mozilla.org/en-US/docs/Web/API/CustomElementRegistry)
- [`customElements`](https://developer.mozilla.org/en-US/docs/Web/API/Window/customElements)

## Contributing

Please see [CONTRIBUTING.md](../../../CONTRIBUTING.md).
