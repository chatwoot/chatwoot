# Change Log

## 3.1.1

### Patch Changes

- [#2384](https://github.com/lit/lit/pull/2384) [`39b8db85`](https://github.com/lit/lit/commit/39b8db85ef8d2264a86ff6ff6559ea06b391f08f) - Fix missing decorators/query-assigned-elements.js file

## 3.1.0

### Minor Changes

- [#2327](https://github.com/lit/lit/pull/2327) [`49ecf623`](https://github.com/lit/lit/commit/49ecf6239033e9578184d46116e6b89676d091db) - Add `queryAssignedElements` decorator for a declarative API that calls `HTMLSlotElement.assignedElements()` on a specified slot. `selector` option allows filtering returned elements with a CSS selector.

### Patch Changes

- Updated dependencies [[`08e7fc56`](https://github.com/lit/lit/commit/08e7fc566894d1916dc768c0843fce962ca4d6d4), [`fcc2b3d0`](https://github.com/lit/lit/commit/fcc2b3d0054e69e6f76588ea9f440117b6d0deed), [`eb5c5d2b`](https://github.com/lit/lit/commit/eb5c5d2b2159dcd8b2321fa9a221b8d56d127a11), [`49ecf623`](https://github.com/lit/lit/commit/49ecf6239033e9578184d46116e6b89676d091db), [`26e3fb7b`](https://github.com/lit/lit/commit/26e3fb7ba1d3ef778a9862ff73374802b4b4eb2e), [`d319cf5f`](https://github.com/lit/lit/commit/d319cf5fde1c2b70185ee9a6252067ed0edaf2fc), [`1d563e83`](https://github.com/lit/lit/commit/1d563e830c02a2d1a22e1e939f1ace971b1d1ae7), [`221cb0a9`](https://github.com/lit/lit/commit/221cb0a90787631dcc867959de19febd2ebd3fd0)]:
  - @lit/reactive-element@1.1.0
  - lit-html@2.1.0

## 3.0.2

### Patch Changes

- [#2240](https://github.com/lit/lit/pull/2240) [`76ed65d7`](https://github.com/lit/lit/commit/76ed65d7e1e157d1f61dd62fe938a2fc1828c497) - Identify a `this` reference for jscompiler.

* [#2236](https://github.com/lit/lit/pull/2236) [`5fc3818a`](https://github.com/lit/lit/commit/5fc3818afa43365b90b921ea0fd8f41e970e767f) - Prevent `polyfillSupport.noPatchSupported` from implicitly being `any`.
  Deduplicate types for `DevMode`-suffixed polyfill support functions.

## 3.0.1

### Patch Changes

- [#2152](https://github.com/lit/lit/pull/2152) [`ba5e1391`](https://github.com/lit/lit/commit/ba5e139163049014e6261123ff808700352b86a8) - Replace dynamic name lookups for polyfill support functions with static names.

## 3.0.0

### Major Changes

- Most users should no longer import directly from `lit-element`, and instead prefer importing `LitElement` from the `lit` packages. The default entry point for `lit-element` remains backward-compatible and includes all decorators. However, it's recommended to use `import {LitElement} from 'lit';` and import decorators from `lit/decorators` as necessary. See the [Upgrade Guide](https://lit.dev/docs/releases/upgrade/#update-packages-and-import-paths) for more details.
- `UpdatingElement` has been moved from the `lit-element` package to the `@lit/reactive-element` package and renamed to `ReactiveElement`. See the [ReactiveElement API](https://lit.dev/docs/api/ReactiveElement/) documentation for more details. In addition, the source for `css-tag`, and all `decorators` have been moved to `@lit/reactive-element`. However, all symbols are re-exported from both `lit` and `lit-element` packages.
- The `@internalProperty` decorator has been renamed to `@state`.
- Errors that occur during the update cycle were previously squelched to allow subsequent updates to proceed normally. Now errors are re-fired asynchronously so they can be detected. Errors can be observed via an `unhandledrejection` event handler on window.
- The `lib` folder has been removed.
- Rendering of `renderRoot`/`shadowRoot`) via `createRenderRoot` and support for `static styles` has moved from `LitElement` to `ReactiveElement`.
- The `createRenderRoot` method is now called just before the first update rather than in the constructor. Element code can not assume the `renderRoot` exists before the element `hasUpdated`. This change was made for compatibility with SSR.
- `ReactiveElement`'s `initialize` method has been removed. This work is now done in the element constructor.
- The static `render` has been removed.
- For consistency, renamed `_getUpdateComplete` to `getUpdateComplete`.
- When a property declaration is `reflect: true` and its `toAttribute` function returns `undefined` the attribute is now removed where previously it was left unchanged ([#872](https://github.com/Polymer/lit-element/issues/872)).
- The dirty check in `attributeChangedCallback` has been removed. While technically breaking, in practice it should very rarely be ([#699](https://github.com/Polymer/lit-element/issues/699)).
- LitElement's `adoptStyles` method has been removed. Styling is now adopted in `createRenderRoot`. This method may be overridden to customize this behavior.
- LitElement's `static getStyles` method has been renamed to `static finalizeStyles` and now takes a list of styles the user provided and returns the styles which should be used in the element. If this method is overridden to integrate into a style management system, typically the `super` implementation should be called.
- Removed build support for TypeScript 3.4.
- Decorators are no longer exported from the `lit-element` module. Instead, import any decorators you use from `lit/decorators/*`.
- `lit-html` has been updated to 2.x.
- Support for running in older browsers has been removed from the default configuration. Import the `polyfill-support` module to support Shady DOM. Note also that Lit parts inside `<style>` elements are no longer supported. See [Polyfills](https://lit.dev/docs/tools/requirements/#polyfills) for more details.
- For simplicity, `requestUpdate` no longer returns a Promise. Instead await the `updateComplete` Promise.
- Removed `requestUpdateInternal`. The `requestUpdate` method is now identical to this method and should be used instead.
- [#2103](https://github.com/lit/lit/pull/2103) [`15a8356d`](https://github.com/lit/lit/commit/15a8356ddd59a1e80880a93acd21fadc9c24e14b) - Updates the `exports` field of `package.json` files to replace the [subpath
  folder
  mapping](https://nodejs.org/dist/latest-v16.x/docs/api/packages.html#packages_subpath_folder_mappings)
  syntax with an explicit list of all exported files.

  The `/`-suffixed syntax for subpath folder mapping originally used in these
  files is deprecated. Rather than update to the new syntax, this change replaces
  these mappings with individual entries for all exported files so that (a) users
  must import using extensions and (b) bundlers or other tools that don't resolve
  subpath folder mapping exactly as Node.js does won't break these packages'
  expectations around how they're imported.

### Minor Changes

- A public `renderOptions` class field now exists on `LitElement` and can be set/overridden to modify the options passed to `lit-html`.
- Adds `static shadowRootOptions` for customizing shadowRoot options. Rather than implementing `createRenderRoot`, this property can be set. For example, to create a closed shadowRoot using delegates focus: `static shadowRootOptions = {mode: 'closed', delegatesFocus: true}`.
- Adds development mode, which can be enabled by setting the `development` Node exports condition. See [Development and production builds](https://lit.dev/docs/tools/development/#development-and-production-builds) for more details.

### Patch Changes

- [#1964](https://github.com/lit/lit/pull/1964) [`f43b811`](https://github.com/lit/lit/commit/f43b811405be32ce6caf82e80d25cb6170eeb7dc) - Don't publish src/ to npm.
- For efficiency, the `css` function now maintains a cache and will use a cached value if available when the same style text is requested.
- Fixed reflecting a property when it is set in a setter of another property that is called because its attribute changed ([#965](https://github.com/Polymer/lit-element/issues/965)).
- Fixed exceptions when parsing attributes from JSON ([#722](https://github.com/Polymer/lit-element/issues/722)).
- Fixed issue with combining `static get properties` on an undefined superclass with `@property` on a subclasss ([#890]https://github.com/Polymer/lit-element/issues/890));

## 3.0.0-rc.4

### Patch Changes

- [#2103](https://github.com/lit/lit/pull/2103) [`15a8356d`](https://github.com/lit/lit/commit/15a8356ddd59a1e80880a93acd21fadc9c24e14b) - Updates the `exports` field of `package.json` files to replace the [subpath
  folder
  mapping](https://nodejs.org/dist/latest-v16.x/docs/api/packages.html#packages_subpath_folder_mappings)
  syntax with an explicit list of all exported files.

  The `/`-suffixed syntax for subpath folder mapping originally used in these
  files is deprecated. Rather than update to the new syntax, this change replaces
  these mappings with individual entries for all exported files so that (a) users
  must import using extensions and (b) bundlers or other tools that don't resolve
  subpath folder mapping exactly as Node.js does won't break these packages'
  expectations around how they're imported.

* [#2113](https://github.com/lit/lit/pull/2113) [`5b2f3642`](https://github.com/lit/lit/commit/5b2f3642ff91931b5b01f8bdd2ed98aba24f1047) - Dependency upgrades including TypeScript 4.4.2

- [#2072](https://github.com/lit/lit/pull/2072) [`7adfbb0c`](https://github.com/lit/lit/commit/7adfbb0cd32a7eab82551aa6c9d1434e7c4b563e) - Remove unneeded `matches` support in @queryAssignedNodes. Update styling tests to use static bindings where needed. Fix TODOs related to doc links.

* [#2119](https://github.com/lit/lit/pull/2119) [`24feb430`](https://github.com/lit/lit/commit/24feb4306ec3ddf2996c678a266a211b52f6aff2) - Added lit.dev/msg links to dev mode warnings.

- [#2075](https://github.com/lit/lit/pull/2075) [`724a9aab`](https://github.com/lit/lit/commit/724a9aabe263fb9dafee073e74de50a1aeabbe0f) - Ensures dev mode warnings do not spam by taking care to issue unique warnings only once.

* [#2073](https://github.com/lit/lit/pull/2073) [`0312f3e5`](https://github.com/lit/lit/commit/0312f3e533611eb3f4f9381594485a33ad003b74) - (Cleanup) Removed obsolete TODOs from codebase

- [#2056](https://github.com/lit/lit/pull/2056) [`e5667d66`](https://github.com/lit/lit/commit/e5667d66f4da58e74206fdef526b1c21a6e45925) - Fixed issue where `AsyncDirective`s could see `this.isConnected === true` if a LitElement performed its initial render while it was disconnected.

* [#2043](https://github.com/lit/lit/pull/2043) [`761375ac`](https://github.com/lit/lit/commit/761375ac9ef28dd0ba8a1f9363aaf5f0df725205) - Update some internal types to avoid casting `globalThis` to `any` to retrieve globals where possible.

## 3.0.0-rc.3

### Patch Changes

- [#1942](https://github.com/lit/lit/pull/1942) [`c8fe1d4`](https://github.com/lit/lit/commit/c8fe1d4c4a8b1c9acdd5331129ae3641c51d9904) - For minified class fields on classes in lit libraries, added prefix to stable properties to avoid collisions with user properties.

* [#2041](https://github.com/lit/lit/pull/2041) [`52a47c7e`](https://github.com/lit/lit/commit/52a47c7e25d71ff802083ca9b0751724efd3a4f4) - Remove some unnecessary internal type declarations.

- [#1959](https://github.com/lit/lit/pull/1959) [`6938995`](https://github.com/lit/lit/commit/69389958ab41b2ad3074fd86926ed18dc9968302) - Changed prefix used for minifying class field names on lit libraries to stay within ASCII subset, to avoid needing to explicitly set the charset for scripts in some browsers.

* [#1964](https://github.com/lit/lit/pull/1964) [`f43b811`](https://github.com/lit/lit/commit/f43b811405be32ce6caf82e80d25cb6170eeb7dc) - Don't publish src/ to npm.

- [#2016](https://github.com/lit/lit/pull/2016) [`e6dc6a7`](https://github.com/lit/lit/commit/e6dc6a708adacec6a17a884784f821c3250d7532) - Clean up internal TypeScript types

* [#1972](https://github.com/lit/lit/pull/1972) [`a791514b`](https://github.com/lit/lit/commit/a791514b426b790de2bfa4c78754fb62815e71d4) - Properties that must remain unminified are now compatible with build tools other than rollup/terser.

* Updated dependencies [[`ff0d1556`](https://github.com/lit/lit/commit/ff0d15568fe79019ebfa6b72b88ba86aac4af91b), [`5768cc60`](https://github.com/lit/lit/commit/5768cc604dc7fcb2c95165399180179d406bb257), [`69389958`](https://github.com/lit/lit/commit/69389958ab41b2ad3074fd86926ed18dc9968302), [`5fabe2b5`](https://github.com/lit/lit/commit/5fabe2b5ae4ab8fba9dc2d23a69105d32e4c0705), [`52a47c7e`](https://github.com/lit/lit/commit/52a47c7e25d71ff802083ca9b0751724efd3a4f4), [`5fabe2b5`](https://github.com/lit/lit/commit/5fabe2b5ae4ab8fba9dc2d23a69105d32e4c0705), [`5fabe2b5`](https://github.com/lit/lit/commit/5fabe2b5ae4ab8fba9dc2d23a69105d32e4c0705), [`5fabe2b5`](https://github.com/lit/lit/commit/5fabe2b5ae4ab8fba9dc2d23a69105d32e4c0705), [`f05be301`](https://github.com/lit/lit/commit/f05be301e36fce93ae887007c0bdd328e5434225), [`5fabe2b5`](https://github.com/lit/lit/commit/5fabe2b5ae4ab8fba9dc2d23a69105d32e4c0705), [`56e8efd3`](https://github.com/lit/lit/commit/56e8efd3fc654396421e7024f82f0eac9d2c4d33), [`662209c3`](https://github.com/lit/lit/commit/662209c370d2f5f58cb2f24e558125f91baeebd0), [`a791514b`](https://github.com/lit/lit/commit/a791514b426b790de2bfa4c78754fb62815e71d4), [`5fabe2b5`](https://github.com/lit/lit/commit/5fabe2b5ae4ab8fba9dc2d23a69105d32e4c0705)]:
  - lit-html@2.0.0-rc.4

---

Changes below were based on the [Keep a Changelog](http://keepachangelog.com/) format. All changes above are generated automatically by [Changesets](https://github.com/atlassian/changesets).

---

<!--
   PRs should document their user-visible changes (if any) in the
   Unreleased section, uncommenting the header as necessary.
-->

<!-- ## [x.y.z] - YYYY-MM-DD -->
<!-- ## Unreleased -->
<!-- ### Changed -->
<!-- ### Added -->
<!-- ### Removed -->
<!-- ### Fixed -->

## 3.0.0-rc.2 - 2021-05-07

### Fixed

- (Since 3.0.0-rc.1) Improves support for customizing `observedAttributes` by
  ensuring that `ReactiveElement.observedAttributes` is callable, allowing
  mixins to directly reference it ([#1835](https://github.com/lit/lit/issues/1835)).

## 3.0.0-rc.1 - 2021-04-20

### Added

- Added `defer-hydration` attribute handling to `experimental-hydrate-support`,
  which helps coordinate ordered wakeup of custom elements during hydration.

### Changed

- (Since 3.0.0-pre.4) Renamed `hydrate-support` module to `experimental-hydrate-support` to reflect its experimental nature. Experimental modules may undergo breaking changes within otherwise non-major releases.

## 3.0.0-pre.4 - 2021-03-31

### Changed

- (Since 3.0.0-pre.3) The `renderOptions` class field on `LitElement` is now public.

## [3.0.0-pre.3] - 2021-02-11

### Changed

- (Since 3.0.0-pre.2) Renamed all decorator modules to use kebab-case filename convention rather than camelCase.
- (Since 3.0.0-pre.2) Renamed `platform-support` to `polyfill-support`.
- (Since 3.0.0-pre.2) Changed a new `index.js` file as the package entrypoint to export the main export plus the decorators again. This undoes a breaking change in 3.0.0-pre.1 which moved the decorators to `decorators.js`.

  This new file is an upgrade helper: it's more backwards compatible, but immediately deprecated. It's recommended to import from `'lit-element/lit-element.js'` or the new `lit` package with `import {LitElement} from 'lit';`.

## [3.0.0-pre.2] - 2020-12-16

### Changed

- [Breaking] Update and render callbacks will only be called when the element is
  connected to the document. If an element is disconnected while an update is
  pending, or if an update is requested while the element is disconnected,
  update callbacks will be called if/when the element is re-connected.

<!-- ### Added -->
<!-- ### Removed -->
<!-- ### Fixed -->

## [3.0.0-pre.1] - 2020-09-21

### Changed

- [Breaking] `UpdatingElement` has been renamed to `ReactiveElement`.
- [Breaking] The `updating-element` package has been renamed to
  `@lit/reactive-element`.
- [Breaking] The `@internalProperty` decorator has been renamed to `@state`.
- [Breaking] Errors that occur during the update cycle were previously squelched to allow subsequent updates to proceed normally. Now errors are re-fired asynchronously so they can be detected. Errors can be observed via an `unhandledrejection` event handler on window.
- [Breaking] `UpdatingElement` has been moved to its own package. The `updating-element`, `css-tag`, and all `decorators` have moved to the `updating-element` package. For convenience, all decorators are re-exported in `LitElement` at `lit-element/decorators` and `lit-element/decorators/*`.
- [Breaking] The `lib` folder has been removed.
- [Breaking] Rendering of `renderRoot`/`shadowRoot`) via `createRenderRoot` and support for `static styles` has moved from `LitElement` to `UpdatingElement`.
- [Breaking] The `createRenderRoot` method is now called just before the first update rather than in the constructor. Element code can not assume the `renderRoot` exists before the element `hasUpdated`. This change was made for compatibility with SSR.
- [Breaking] `UpdatingElement`'s `initialize` method has been removed. This work is now done in the element constructor.
- [Breaking] The static `render` has been removed.
- [Breaking] For consistency, renamed `_getUpdateComplete` to `getUpdateComplete`.
- [Breaking] When a property declaration is `reflect: true` and its `toAttribute` function returns `undefined` the attribute is now removed where previously it was left unchanged ([#872](https://github.com/Polymer/lit-element/issues/872)).
- [Breaking] The dirty check in `attributeChangedCallback` has been removed. While technically breaking, in practice it should very rarely be ([#699](https://github.com/Polymer/lit-element/issues/699)).
- [Breaking] LitElement's `adoptStyles` method has been removed. Styling is now adopted in `createRenderRoot`. This method may be overridden to customize this behavior.
- [Breaking] LitElement's `static getStyles` method has been renamed to `static finalizeStyles` and now takes a list of styles the user provided and returns the styles which should be used in the element. If this method is overridden to integrate into a style management system, typically the `super` implementation should be called.
- [Breaking] Removed build support for TypeScript 3.4.
- [Breaking] Decorators are no longer exported from the `lit-element` module. Instead, import any decorators you use from `lit-element/decorators/*`.
- [Breaking] `lit-html` has been updated to 2.x.
- [Breaking] Support for running in older browsers has been removed from the default configuration. Import the `platform-support` module to support Shady DOM. Note also that Lit parts inside `<style>` elements are no longer supported.
- [Breaking] For simplicity, `requestUpdate` no longer returns a Promise. Instead await the `updateComplete` Promise.
- [Breaking] The type of the `css` function has been changed to `CSSResultGroup` and is now the same as `LitElement.styles`. This avoids the need to cast the `styles` property to `any` when a subclass sets `styles` to an Array and its super class set a single value (or visa versa).
- For efficiency, the `css` function now maintains a cache and will use a cached value if available when the same style text is requested.

### Added

- Console warnings added for removed API and other element problems in developer mode.
- Adds `static shadowRootOptions` for customizing shadowRoot options. Rather than implementing `createRenderRoot`, this property can be set. For example, to create a closed shadowRoot using delegates focus: `static shadowRootOptions = {mode: 'closed', delegatesFocus: true}`.
- Adds development mode, which can be enabled by setting the `development` Node exports condition. See `README.md` for more details.

### Removed

- [Breaking] Removed `requestUpdateInternal`. The `requestUpdate` method is now identical to this method and should be used instead.

### Fixed

- Fixed reflecting a property when it is set in a setter of another property that is called because its attribute changed ([#965](https://github.com/Polymer/lit-element/issues/965)).
- Fixed exceptions when parsing attributes from JSON ([#722](https://github.com/Polymer/lit-element/issues/722)).
- Fixed issue with combining `static get properties` on an undefined superclass with `@property` on a subclasss ([#890]https://github.com/Polymer/lit-element/issues/890));

## [2.4.0] - 2020-08-19

### Changed

- Set type in package.json to "module" ([#974](https://github.com/Polymer/lit-element/pull/974))

### Added

- Adds a `cache: boolean` argument to the `@query` decorator as a performance optimization for properties whose queried element is not expected to change. If cache is set to true, element DOM is queried when the property is first accessed, and the value is cached so it can be immediately returned on all subsequent property accesses. ([#1013](https://github.com/Polymer/lit-element/issues/1013))
- Adds a `selector: string` argument to the `@queryAssignedNodes` decorator as a convenience to filter the assigned nodes by the given selector ([#1016](https://github.com/Polymer/lit-element/issues/1016)).
- The `requestUpdateInternal(name, oldValue, options)` method has been added. This method is sometimes useful to call in a custom property setter to optimize performance. It is slightly more efficient than `requestUpdate` since it does not return the `updateComplete` property which can be overridden to do work.
- The protected `performUpdate()` method may now be called to syncronously "flush" a pending update, for example via a property setter. Note, performing a synchronous update only updates the element and not any potentially pending descendants in the element's local DOM ([#959](https://github.com/Polymer/lit-element/issues/959)).
- Constructible stylesheets may now be provided directly as styles, in addition to using the `css` tagged template function ([#853](https://github.com/Polymer/lit-element/issues/853)).

### Fixed

- queryAssignedNodes doesn't correctly locate default slot ([#1002](https://github.com/Polymer/lit-element/issues/1002))

## [2.3.1] - 2020-03-19

### Fixed

- Add TypeScript type declarations for older versions of TypeScript. We're currently testing back to TS 3.4. We can't commit to never breaking TypeScript builds, but we'll be supporting older versions as best we can.

## [2.3.0] - 2020-03-18

### Changed

- Added a static `getPropertyDescriptor` method to allow easier customization of property accessors. This method should return a a `PropertyDescriptor` to install on the property. If no descriptor is returned, no property accessor is created. ([#911](https://github.com/Polymer/lit-element/issues/911))
- The value returned by `render` is always rendered, even if it isn't a `TemplateResult`. ([#712](https://github.com/Polymer/lit-element/issues/712))

### Added

- Added `@queryAsync(selector)` decorator which returns a Promise that resolves to the result of querying for the given selector after the element's `updateComplete` Promise resolves ([#903](https://github.com/Polymer/lit-element/issues/903)).
- Added `enableUpdating()` to `UpdatingElement` to enable customizing when updating is enabled [#860](https://github.com/Polymer/lit-element/pull/860).
- Added `@queryAssignedNodes(slotName, flatten)` decorator to enable querying assignedNodes for a given slot [#860](https://github.com/Polymer/lit-element/pull/860).
- Added `getStyles()` to `LitElement` to allow hooks into style gathering for component sets [#866](https://github.com/Polymer/lit-element/pull/866).
- Added `@internalProperty(options)` decorator to define properties internal to an element. [#881](https://github.com/Polymer/lit-element/pull/881).

### Fixed

- Ensure `UpdatingElement` allows updates when properties are set after calling `super.update()`.
  `LitElement` renders when updates are triggered as a result of rendering ([#549](https://github.com/Polymer/lit-element/issues/549)).
- Properties annotated with the `eventOptions` decorator will now survive property renaming optimizations when used with tsickle and Closure JS Compiler.
- Moved style gathering from `finalize` to `initialize` to be more lazy, and create stylesheets on the first instance initializing [#866](https://github.com/Polymer/lit-element/pull/866).
- Fixed behavior change for components that do not implement `render()` introduced in ([#712](https://github.com/Polymer/lit-element/pull/712)) ([#917](https://github.com/Polymer/lit-element/pull/917))

## [2.2.1] - 2019-07-23

### Changed

- Elements should now override the new `_getUpdateComplete` method instead of the `updateComplete` getter, for compatibility with TypeScript ES5 output, which does not support calling a superclass getter (e.g.`super.updateComplete.then(...)`) due to [TypeScript#338](https://github.com/microsoft/TypeScript/issues/338).

### Fixed

- Fixed compatibility with Closure JS Compiler optimizations relating to static properties ([#732](https://github.com/Polymer/lit-element/issues/732)).

## [2.2.0] - 2019-06-11

### Added

- css tagged template literals now allow numbers to be used in expressions ([#488](https://github.com/Polymer/lit-element/issues/488)).

## [2.1.0] - 2019-03-21

### Changed

- `LitElement.renderRoot` is now `public readonly` instead of `protected`.

### Fixed

- Exceptions generated during update/render do not block subsequent updates ([#262](https://github.com/Polymer/lit-element/issues/262)).
- Initial update is scheduled at construction time rather than connected time ([#594](https://github.com/Polymer/lit-element/issues/594)).
- A reflecting property set immediately after a corresponding attribute
  now reflects properly ([#592](https://github.com/Polymer/lit-element/issues/592)).
- Properties annotated with the `@query` and `@queryAll` decorators will now
  survive property renaming optimizations when used with tsickle and Closure JS
  Compiler.

## [2.0.1] - 2019-02-05

### Fixed

- Use `lit-html` 1.0 ([#543](https://github.com/Polymer/lit-element/pull/543)).

## [2.0.0] - 2019-02-05

### Added

- Add `toString()` function to `CSSResult` ([#508](https://github.com/Polymer/lit-element/pull/508))
- Add a global version to `window` ([#536](https://github.com/Polymer/lit-element/pull/536))

### Changed

- [Breaking] Renamed `unsafeCss` to `unsafeCSS` for consistency with lit-html's `unsafeHTML` ([#524](https://github.com/Polymer/lit-element/pull/524))
- Remove all uses of `any` outside of tests ([#457](https://github.com/Polymer/lit-element/pull/457))

### Fixed

- A bunch of docs fixes ([#464](https://github.com/Polymer/lit-element/pull/464)), ([#458](https://github.com/Polymer/lit-element/pull/458)), ([#493](https://github.com/Polymer/lit-element/pull/493)), ([#504](https://github.com/Polymer/lit-element/pull/504)), ([#505](https://github.com/Polymer/lit-element/pull/505)), ([#501](https://github.com/Polymer/lit-element/pull/501)), ([#494](https://github.com/Polymer/lit-element/pull/494)), ([#491](https://github.com/Polymer/lit-element/pull/491)), ([#509](https://github.com/Polymer/lit-element/pull/509)), ([#513](https://github.com/Polymer/lit-element/pull/513)), ([#515](https://github.com/Polymer/lit-element/pull/515)), ([#512](https://github.com/Polymer/lit-element/pull/512)), ([#503](https://github.com/Polymer/lit-element/pull/503)), ([#460](https://github.com/Polymer/lit-element/pull/460)), ([#413](https://github.com/Polymer/lit-element/pull/413)), ([#426](https://github.com/Polymer/lit-element/pull/426)), ([#516](https://github.com/Polymer/lit-element/pull/516)), ([#537](https://github.com/Polymer/lit-element/pull/537)), ([#535](https://github.com/Polymer/lit-element/pull/535)), ([#539](https://github.com/Polymer/lit-element/pull/539)), ([#540](https://github.com/Polymer/lit-element/pull/540))
- Build on checkout ([#423](https://github.com/Polymer/lit-element/pull/423))

### Fixed

- Adds a check to ensure `CSSStyleSheet` is constructable ([#527](https://github.com/Polymer/lit-element/pull/527)).

## [2.0.0-rc.5] - 2019-01-24

### Fixed

- Fixed a bug causing duplicate styles when an array was returned from `static get styles` ([#480](https://github.com/Polymer/lit-element/issues/480)).

## [2.0.0-rc.4] - 2019-01-24

### Added

- [Maintenance] Added script to publish dev releases automatically ([#476](https://github.com/Polymer/lit-element/pull/476)).
- Adds `unsafeCss` for composing "unsafe" values into `css`. Note, `CSSResult` is no longer constructable. ([#451](https://github.com/Polymer/lit-element/issues/451) and [#471](https://github.com/Polymer/lit-element/issues/471)).

### Fixed

- Fixed a bug where we broke compatibility with closure compiler's property renaming optimizations. JSCompiler_renameProperty can't be a module export ([#465](https://github.com/Polymer/lit-element/pull/465)).
- Fixed an issue with inheriting from `styles` property when extending a superclass that is never instanced. ([#470](https://github.com/Polymer/lit-element/pull/470)).
- Fixed an issue with Closure Compiler and ([#470](https://github.com/Polymer/lit-element/pull/470)) ([#476](https://github.com/Polymer/lit-element/pull/476)).

## [2.0.0-rc.3] - 2019-01-18

### Fixed

- README: Fixed jsfiddle reference ([#435](https://github.com/Polymer/lit-element/pull/435)).
- Compile with Closure Compiler cleanly ([#436](https://github.com/Polymer/lit-element/pull/436)).
- Opt `@property` decorators out of Closure Compiler renaming ([#448](https://github.com/Polymer/lit-element/pull/448)).

### Changed

- [Breaking] Property accessors are no longer wrapped when they already exist. Instead the `noAccessor` flag should be set when a user-defined accessor exists on the prototype (and in this case, user-defined accessors must call `requestUpdate` themselves). ([#454](https://github.com/Polymer/lit-element/pull/454)).
- Class fields can now be used to define styles, e.g. `static styles = css` and `styles` correctly compose when elements are extended ([#456](https://github.com/Polymer/lit-element/pull/456)).
- Styles returned via `static styles` are automatically flattend ([#437](https://github.com/Polymer/lit-element/pull/437)).
- Replace use of for/of loops over Maps with forEach ([#455](https://github.com/Polymer/lit-element/pull/455))

## [2.0.0-rc.2] - 2019-01-11

### Fixed

- Fix references to `@polymer/lit-element` in README and docs ([#427](https://github.com/Polymer/lit-element/pull/427)).
- Fix decorator types causing compiler errors for TypeScript users. ([#431](https://github.com/Polymer/lit-element/pull/431)).

## [2.0.0-rc.1] - 2019-01-10

### Changed

- [Breaking] Changed NPM package name to `lit-element`

## [0.7.0] - 2019-01-10

### Added

- Updated decorator implementations to support TC39 decorator API proposal (supported by Babel 7.1+) in addition to the legacy decorator API (supported by older Babel and TypeScript) ([#156](https://github.com/Polymer/lit-element/issues/156)).
- Added `static get styles()` to allow defining element styling separate from `render` method.
  This takes advantage of [`adoptedStyleSheets`](https://wicg.github.io/construct-stylesheets/#using-constructed-stylesheets) when possible ([#391](https://github.com/Polymer/lit-element/issues/391)).
- Added the `performUpdate` method to allow control of update timing ([#290](https://github.com/Polymer/lit-element/issues/290)).
- Updates deferred until first connection ([#258](https://github.com/Polymer/lit-element/issues/258)).
- Export `TemplateResult` and `SVGTemplateResult` ([#415](https://github.com/Polymer/lit-element/pull/415)).

### Changed

- [Breaking] The `createRenderRoot` method has moved from `UpdatingElement` to `LitElement`. Therefore, `UpdatingElement` no longer creates a `shadowRoot` by default ([#391](https://github.com/Polymer/lit-element/issues/391)).
- [Breaking] Changes property options to add `converter`. This option works the same as the previous `type` option except that the `converter` methods now also get `type` as the second argument. This effectively changes `type` to be a hint for the `converter`. A default `converter` is used if none is provided and it now supports `Boolean`, `String`, `Number`, `Object`, and `Array` ([#264](https://github.com/Polymer/lit-element/issues/264)).
- [Breaking] Numbers and strings now become null if their reflected attribute is removed (https://github.com/Polymer/lit-element/issues/264)).
- [Breaking] Previously, when an attribute changed as a result of a reflecting property changing, the property was prevented from mutating again as can happen when a custom
  `converter` is used. Now, the oppose is also true. When a property changes as a result of an attribute changing, the attribute is prevented from mutating again (https://github.com/Polymer/lit-element/issues/264))

### Fixed

- [Breaking] User defined accessors are now wrapped to enable better composition ([#286](https://github.com/Polymer/lit-element/issues/286))
- Type for `eventOptions` decorator now properly includes `passive` and `once` options ([#325](https://github.com/Polymer/lit-element/issues/325))

## [0.6.5] - 2018-12-13

### Changed:

- Use lit-html 1.0 release candidate.

### Fixed

- Types for the `property` and `customElement` decorators updated ([#288](https://github.com/Polymer/lit-element/issues/288) and [#291](https://github.com/Polymer/lit-element/issues/291)).
- Docs updated.

## [0.6.4] - 2018-11-30

### Changed

- Update lit-html dependency to ^0.14.0 ([#324](https://github.com/Polymer/lit-element/pull/324)).

## [0.6.3] - 2018-11-08

### Changed

- Update lit-html dependency to ^0.13.0 ([#298](https://github.com/Polymer/lit-element/pull/298)).

## [0.6.2] - 2018-10-05

### Changed

- LitElement changed to a non-abstract class to be more compatible with the JavaScript mixin pattern
  ([#227](https://github.com/Polymer/lit-element/issues/227)).
- Update lit-html dependency to ^0.12.0 ([#244](https://github.com/Polymer/lit-element/pull/244)).
- Passes the component's `this` reference to lit-html as the `eventContext`, allowing unbound event listener methods ([#244](https://github.com/Polymer/lit-element/pull/244)).

### Added

- A `disconnectedCallback()` method was added to UpdatingElement ([#213](https://github.com/Polymer/lit-element/pull/213)).
- Added `@eventOptions()` decorator for setting event listener options on methods ([#244](https://github.com/Polymer/lit-element/pull/244)).

## [0.6.1] - 2018-09-17

### Fixed

- Fixes part rendering and css custom properties issues introduced with lit-html 0.11.3 by updating to 0.11.4 (https://github.com/Polymer/lit-element/issues/202).

### Removed

- Removed custom_typings for Polymer as they are no longer needed
  (https://github.com/Polymer/lit-element/issues/186).

## [0.6.0] - 2018-09-13

### Added

- Added `@query()`, `@queryAll()`, and `@customElement` decorators ([#159](https://github.com/Polymer/lit-element/pull/159))

### Changed

- Significantly changed update/render lifecycle and property API. Render lifecycle
  is now `requestUpdate`, `shouldUpdate`, `update`, `render`, `firstUpdated`
  (first time only), `updated`, `updateComplete`. Property options are now
  `{attribute, reflect, type, hasChanged}`. Properties may be defined in a
  `static get properties` or using the `@property` decorator.
  (https://github.com/Polymer/lit-element/pull/132).

### Removed

- Removed render helpers `classString` and `styleString`. Similar directives
  (`classMap` and `styleMap`) have been added to lit-html and should be used instead
  (https://github.com/Polymer/lit-element/pull/165 and
  https://github.com/Polymer/lit-html/pull/486).

### Fixed

- The `npm run checksize` command should now return the correct minified size
  (https://github.com/Polymer/lit-element/pull/153).
- The `firstUpdated` method should now always be called the first time the element
  updates, even if `shouldUpdate` initially returned `false`
  (https://github.com/Polymer/lit-element/pull/173).
