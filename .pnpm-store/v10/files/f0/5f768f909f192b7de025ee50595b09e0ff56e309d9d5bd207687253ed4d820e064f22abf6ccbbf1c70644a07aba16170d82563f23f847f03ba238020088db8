<img src="./logo.svg" alt="Lit" width="300" height="141">

### Simple. Fast. Web Components.

[![Build Status](https://github.com/lit/lit/actions/workflows/tests.yml/badge.svg)](https://github.com/lit/lit/actions/workflows/tests.yml)
[![Published on npm](https://img.shields.io/npm/v/lit.svg?logo=npm)](https://www.npmjs.com/package/lit)
[![Join our Slack](https://img.shields.io/badge/slack-join%20chat-4a154b.svg?logo=slack)](https://lit.dev/slack-invite/)
[![Mentioned in Awesome Lit](https://awesome.re/mentioned-badge.svg)](https://github.com/web-padawan/awesome-lit)

Lit is a simple library for building fast, lightweight web components.

At Lit's core is a boilerplate-killing component base class that provides reactive state, scoped styles, and a declarative template system that's tiny, fast and expressive.

## Documentation

See the full documentation for Lit at [lit.dev](https://lit.dev)

## About this release

This is a stable release of Lit 2.0. If upgrading from previous versions of `lit-element` or `lit-html`, please see the [Upgrade Guide](https://lit.dev/docs/releases/upgrade/) for a step-by-step guide on upgrading.

## Overview

Lit provides developers with just the right tools to build fast web components:

- A fast declarative HTML template system
- Reactive property declarations
- A customizable reactive update lifecycle
- Easy to use scoped CSS styling

Lit builds on top of standard web components, and makes them easier to write:

```ts
import {LitElement, html, css} from 'lit';
import {customElement, property} from 'lit/decorators.js';

// Registers the element
@customElement('my-element')
export class MyElement extends LitElement {
  // Styles are applied to the shadow root and scoped to this element
  static styles = css`
    span {
      color: green;
    }
  `;

  // Creates a reactive property that triggers rendering
  @property()
  mood = 'great';

  // Render the component's DOM by returning a Lit template
  render() {
    return html`Web Components are <span>${this.mood}</span>!`;
  }
}
```

Once you've defined your component, you can use it anywhere you use HTML:

```html
<my-element mood="awesome"></my-element>
```

## Contributing

Please see [CONTRIBUTING.md](../../CONTRIBUTING.md).
