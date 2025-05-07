# Chatwoot UI Components Usage Guide

This document explains how to use the Chatwoot UI components library, which can be used both as Web Components (Custom Elements) and as Vue components.

## Installation

```bash
npm install @chatwoot/ui
# or
yarn add @chatwoot/ui
# or
pnpm add @chatwoot/ui
```

## Usage

### As Web Components (Custom Elements)

Web Components can be used in any HTML page or application, regardless of the framework.

```html
<!-- Include the built JS file -->
<script src="https://unpkg.com/@chatwoot/ui/dist/ui.js"></script>

<!-- Use the custom element anywhere in your HTML -->
<chat-button label="Click me"></chat-button>
```

When the script loads, it automatically registers all custom elements with the browser, making them immediately available for use.

#### Accessing the Store in Web Components

The components have access to a global store instance. When using Web Components, the store is available through `window.__CHATWOOT_STORE__`.

You can interact with the store from your JavaScript:

```javascript
// Access the store
const store = window.__CHATWOOT_STORE__;

// Check store state
console.log(store.state.someData);

// Dispatch actions
store.dispatch('someAction', { data: 'example' });
```
