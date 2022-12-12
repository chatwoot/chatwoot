# Change Log

## 1.1.1

### Patch Changes

- [#2384](https://github.com/lit/lit/pull/2384) [`39b8db85`](https://github.com/lit/lit/commit/39b8db85ef8d2264a86ff6ff6559ea06b391f08f) - Fix missing decorators/query-assigned-elements.js file

## 1.1.0

### Minor Changes

- [#2327](https://github.com/lit/lit/pull/2327) [`49ecf623`](https://github.com/lit/lit/commit/49ecf6239033e9578184d46116e6b89676d091db) - Add `queryAssignedElements` decorator for a declarative API that calls `HTMLSlotElement.assignedElements()` on a specified slot. `selector` option allows filtering returned elements with a CSS selector.

### Patch Changes

- [#2360](https://github.com/lit/lit/pull/2360) [`08e7fc56`](https://github.com/lit/lit/commit/08e7fc566894d1916dc768c0843fce962ca4d6d4) - Update `@queryAssignedNodes` and `@queryAssignedElements` documentation for better lit.dev API generation.

* [#2267](https://github.com/lit/lit/pull/2267) [`eb5c5d2b`](https://github.com/lit/lit/commit/eb5c5d2b2159dcd8b2321fa9a221b8d56d127a11) - Make `willUpdate` lifecycle hook protected

- [#2338](https://github.com/lit/lit/pull/2338) [`26e3fb7b`](https://github.com/lit/lit/commit/26e3fb7ba1d3ef778a9862ff73374802b4b4eb2e) - Deprecate `@queryAssignedNodes` API in preference for the new options object API which
  mirrors the `@queryAssignedElements` API. Update the documentation for both
  `@queryAssignedNodes` and `@queryAssignedElements` to better document the expected
  return type annotation.

## 1.0.2

### Patch Changes

- [#2146](https://github.com/lit/lit/pull/2146) [`8bb33c88`](https://github.com/lit/lit/commit/8bb33c882bf5a9a215efac9dd9dd8665285a417d) - Work around a Chrome bug with trusted types: https://crbug.com/993268

* [#2236](https://github.com/lit/lit/pull/2236) [`5fc3818a`](https://github.com/lit/lit/commit/5fc3818afa43365b90b921ea0fd8f41e970e767f) - Prevent `polyfillSupport.noPatchSupported` from implicitly being `any`.
  Deduplicate types for `DevMode`-suffixed polyfill support functions.

- [#2160](https://github.com/lit/lit/pull/2160) [`90a8c123`](https://github.com/lit/lit/commit/90a8c12348a49f51e37964f69abba0ff75f4922d) - Prevents the dev-mode error about shadowed properties from being thrown in
  certain cases where the property intentionally has no generated descriptor.

## 1.0.1

### Patch Changes

- [#2152](https://github.com/lit/lit/pull/2152) [`ba5e1391`](https://github.com/lit/lit/commit/ba5e139163049014e6261123ff808700352b86a8) - Replace dynamic name lookups for polyfill support functions with static names.

## 1.0.0

### Major Changes

- `@lit/reactive-element` is a new package that factors out the base class that provides the reactive update lifecycle based on property/attribute changes to `LitElement` (what was previously called `UpdatingElement`) into a separate package. `LitElement` now extends `ReactiveElement` to add `lit-html` rendering via the `render()` callback. See [ReactiveElement API](https://lit.dev/docs/api/ReactiveElement/) for more details.
- `UpdatingElement` has been renamed to `ReactiveElement`.
- The `updating-element` package has been renamed to `@lit/reactive-element`.
- The `@internalProperty` decorator has been renamed to `@state`.
- For consistency, renamed `_getUpdateComplete` to `getUpdateComplete`.
- When a property declaration is `reflect: true` and its `toAttribute` function returns `undefined` the attribute is now removed where previously it was left unchanged ([#872](https://github.com/Polymer/lit-element/issues/872)).
- Errors that occur during the update cycle were previously squelched to allow subsequent updates to proceed normally. Now errors are re-fired asynchronously so they can be detected. Errors can be observed via an `unhandledrejection` event handler on window.
- ReactiveElement's `renderRoot` is now created when the element's `connectedCallback` is initially run.
- Removed `requestUpdateInternal`. The `requestUpdate` method is now identical to this method and should be used instead.
- The `initialize` method has been removed. This work is now done in the element constructor.

### Minor Changes

- Adds `static addInitializer` for adding a function which is called with the element instance when is created. This can be used, for example, to create decorators which hook into element lifecycle by creating a reactive controller ([#1663](https://github.com/Polymer/lit-html/issues/1663)).
- Added ability to add a controller to an element. A controller can implement callbacks that tie into element lifecycle, including `hostConnected`, `hostDisconnected`, `hostUpdate`, and `hostUpdated`. To ensure it has access to the element lifecycle, a controller should be added in the element's constructor. To add a controller to the element, call `addController(controller)`.
- Added `removeController(controller)` which can be used to remove a controller from a `ReactiveElement`.
- Added `willUpdate(changedProperties)` lifecycle method to UpdatingElement. This is called before the `update` method and can be used to compute derived state needed for updating. This method is intended to be called during server side rendering and should not manipulate element DOM.

## 1.0.0-rc.4

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

* [#2097](https://github.com/lit/lit/pull/2097) [`2b8dd1c7`](https://github.com/lit/lit/commit/2b8dd1c7d687a8613bd97eb68a2dfd9197cde4fa) - Adds `scheduleUpdate()` to control update timing. This should be implemented instead of `performUpdate()`; however, existing overrides of `performUpdate()` will continue to work.

- [#1980](https://github.com/lit/lit/pull/1980) [`018f6520`](https://github.com/lit/lit/commit/018f65205ba256e15410f17a69f958607c222a38) - fix queryAssignedNodes returning null if slot is not found

* [#2113](https://github.com/lit/lit/pull/2113) [`5b2f3642`](https://github.com/lit/lit/commit/5b2f3642ff91931b5b01f8bdd2ed98aba24f1047) - Dependency upgrades including TypeScript 4.4.2

- [#2072](https://github.com/lit/lit/pull/2072) [`7adfbb0c`](https://github.com/lit/lit/commit/7adfbb0cd32a7eab82551aa6c9d1434e7c4b563e) - Remove unneeded `matches` support in @queryAssignedNodes. Update styling tests to use static bindings where needed. Fix TODOs related to doc links.

* [#2119](https://github.com/lit/lit/pull/2119) [`24feb430`](https://github.com/lit/lit/commit/24feb4306ec3ddf2996c678a266a211b52f6aff2) - Added lit.dev/msg links to dev mode warnings.

- [#2112](https://github.com/lit/lit/pull/2112) [`61fc9452`](https://github.com/lit/lit/commit/61fc9452b40140bbd864317d868a3a663538ebdd) - Throws rather than warns in dev mode when an element has a class field that shadows a reactive property. The element is in a broken state in this case.

* [#2075](https://github.com/lit/lit/pull/2075) [`724a9aab`](https://github.com/lit/lit/commit/724a9aabe263fb9dafee073e74de50a1aeabbe0f) - Ensures dev mode warnings do not spam by taking care to issue unique warnings only once.

- [#2073](https://github.com/lit/lit/pull/2073) [`0312f3e5`](https://github.com/lit/lit/commit/0312f3e533611eb3f4f9381594485a33ad003b74) - (Cleanup) Removed obsolete TODOs from codebase

* [#2065](https://github.com/lit/lit/pull/2065) [`8b6e2415`](https://github.com/lit/lit/commit/8b6e2415e57df644189a5aac311f58949a1d0971) - Fixes #2062. To match Lit1 behavior, the @query decorator returns null (rather than undefined) if a decorated property is accessed before first update. Likewise, a @queryAll decorated property returns [] rather than undefined.

- [#2043](https://github.com/lit/lit/pull/2043) [`761375ac`](https://github.com/lit/lit/commit/761375ac9ef28dd0ba8a1f9363aaf5f0df725205) - Update some internal types to avoid casting `globalThis` to `any` to retrieve globals where possible.

## 1.0.0-rc.3

### Patch Changes

- [#2002](https://github.com/lit/lit/pull/2002) [`ff0d1556`](https://github.com/lit/lit/commit/ff0d15568fe79019ebfa6b72b88ba86aac4af91b) - Fixes polyfill-support styling issues: styling should be fully applied by firstUpdated/update time; late added styles are now retained (matching Lit1 behavior)

* [#2030](https://github.com/lit/lit/pull/2030) [`34280cb0`](https://github.com/lit/lit/commit/34280cb0c6ac1dc14ce5cc900f36b4326b0a1d98) - Remove unnecessary attribute:false assignment in @state decorator

- [#2034](https://github.com/lit/lit/pull/2034) [`5768cc60`](https://github.com/lit/lit/commit/5768cc604dc7fcb2c95165399180179d406bb257) - Reverts the change in Lit 2 to pause ReactiveElement's update cycle while the element is disconnected. The update cycle for elements will now run while disconnected as in Lit 1, however AsyncDirectives must now check the `this.isConnected` flag during `update` to ensure that e.g. subscriptions that could lead to memory leaks are not made when AsyncDirectives update while disconnected.

* [#1918](https://github.com/lit/lit/pull/1918) [`72877fd`](https://github.com/lit/lit/commit/72877fd1de43ccdd579778d5df407e960cb64b03) - Changed the caching strategy used in CSSResults returned from the css tag to cache the stylesheet rather than individual CSSResults.

- [#1942](https://github.com/lit/lit/pull/1942) [`c8fe1d4`](https://github.com/lit/lit/commit/c8fe1d4c4a8b1c9acdd5331129ae3641c51d9904) - For minified class fields on classes in lit libraries, added prefix to stable properties to avoid collisions with user properties.

* [#2041](https://github.com/lit/lit/pull/2041) [`52a47c7e`](https://github.com/lit/lit/commit/52a47c7e25d71ff802083ca9b0751724efd3a4f4) - Remove some unnecessary internal type declarations.

- [#1917](https://github.com/lit/lit/pull/1917) [`550a218`](https://github.com/lit/lit/commit/550a2186eaeffef9d2d87025de09bdd2bb9c82ac) - Use a brand property instead of instanceof to identify CSSResults to make the checks compatible with multiple copies of the @lit/reactive-element package.

* [#1959](https://github.com/lit/lit/pull/1959) [`6938995`](https://github.com/lit/lit/commit/69389958ab41b2ad3074fd86926ed18dc9968302) - Changed prefix used for minifying class field names on lit libraries to stay within ASCII subset, to avoid needing to explicitly set the charset for scripts in some browsers.

- [#1964](https://github.com/lit/lit/pull/1964) [`f43b811`](https://github.com/lit/lit/commit/f43b811405be32ce6caf82e80d25cb6170eeb7dc) - Don't publish src/ to npm.

* [#1943](https://github.com/lit/lit/pull/1943) [`39ad574`](https://github.com/lit/lit/commit/39ad574e2a386627ec30a4be19ae6a003e3a4766) - Add support for private custom element constructors in @customElement().

- [#2016](https://github.com/lit/lit/pull/2016) [`e6dc6a7`](https://github.com/lit/lit/commit/e6dc6a708adacec6a17a884784f821c3250d7532) - Clean up internal TypeScript types

* [#1972](https://github.com/lit/lit/pull/1972) [`a791514b`](https://github.com/lit/lit/commit/a791514b426b790de2bfa4c78754fb62815e71d4) - Properties that must remain unminified are now compatible with build tools other than rollup/terser.

- [#2050](https://github.com/lit/lit/pull/2050) [`8758e06`](https://github.com/lit/lit/commit/8758e06c7a142332fd4c3334d8806b3b51c7f249) - Fix syntax highlighting in some documentation examples

- (Since 1.0.0-rc.2) Reverted change of the `css` tag's return to CSSResultGroup, which was a breaking change. The `css` tag again returns a `CSSResult` object.
- (Since 1.0.0-rc.2) Remove the `CSSResultFlatArray` type alias in `css-tag.ts`.

---

Changes below were based on the [Keep a Changelog](http://keepachangelog.com/) format. All changes above are generated automatically by [Changesets](https://github.com/atlassian/changesets).

---

## 1.0.0-rc.2 - 2021-05-07

### Changed

- (Since 1.0.0-rc.1) [Breaking] Change the type name `Warnings` to `WarningKind` [#1854](https://github.com/Polymer/lit-html/issues/1854).

## 1.0.0-rc.1 - 2021-04-20

### Fixed

- (Since 1.0.0-pre.3) A controller's `hostConnected` is called only once if an element is upgraded to a custom element [#1731](https://github.com/Polymer/lit-html/issues/1731).

## 1.0.0-pre.3 - 2021-03-31

### Fixed

- (Since 1.0.0-pre.2) The `createRenderRoot` method is now called only once [#1679](https://github.com/Polymer/lit-html/issues/1679).

## [1.0.0-pre.2] - 2021-02-11

### Added

- (Since 1.0.0-pre.1) Adds `static addInitializer` for adding a function which is called with the element instance when is created. This can be used, for example, to create decorators which hook into element lifecycle by creating a reactive controller ([#1663](https://github.com/Polymer/lit-html/issues/1663)).
- (Since 1.0.0-pre.1) Added `removeController(controller)` which can be used to remove a controller from a `ReactiveElement`.

### Changed

- (Since 1.0.0-pre.1) A controller's `hostUpdated` method is now called before the host's `firstUpdated` method ([#1650](https://github.com/Polymer/lit-html/issues/1650)).
- (Since 1.0.0-pre.1) Fixed `@query` decorator when cache flag is used and code is compiled with Babel ([#1591](https://github.com/Polymer/lit-html/pull/1591)).

- (Since 1.0.0-pre.1) Renamed all decorator modules to use kebab-case filename convention rather than camelCase.
- (Since 1.0.0-pre.1) `ReactiveController` callbacks all now begin with `host`, for example `hostConnected`, `hostDisconnected`, `hostUpdate`, `hostUpdated`.
- (Since 1.0.0-pre.1) If a `Controller` is added after a host element is connected, its `connected` will be called.
- (Since 1.0.0-pre.1) Removed `willUpdate` from `ReactiveController`.
- (Since 1.0.0-pre.1) Renamed `Controller`'s `dis/connectedCallback` methods.
- (Since 1.0.0-pre.1) Renamed `Controller` to `ReactiveController`.
- Made JSCompiler_renameProperty block scoped so that it's inlined in the Terser prod build. Closure should compile from the development build, or after a custom TypeScript compilation.

## [1.0.0-pre.1] - 2020-12-16

### Changed

- [Breaking] (since 3.0.0-pre1) `UpdatingElement` has been renamed to `ReactiveElement`.
- [Breaking] (since 3.0.0-pre1) The `updating-element` package has been renamed to `@lit/reactive-element`.
- [Breaking] (since 3.0.0-pre1) The `@internalProperty` decorator has been renamed to `@state`.
- [Breaking] For consistency, renamed `_getUpdateComplete` to `getUpdateComplete`.
- [Breaking] When a property declaration is `reflect: true` and its `toAttribute` function returns `undefined` the attribute is now removed where previously it was left unchanged ([#872](https://github.com/Polymer/lit-element/issues/872)).
- Errors that occur during the update cycle were previously squelched to allow subsequent updates to proceed normally. Now errors are re-fired asynchronously so they can be detected. Errors can be observed via an `unhandledrejection` event handler on window.

- UpdatingElement's `renderRoot` is now created when the element's `connectedCallback` is initially run.

- [Breaking] Update callbacks will only be called when the element is connected
  to the document. If an element is disconnected while an update is pending, or
  if an update is requested while the element is disconnected, update callbacks
  will be called if/when the element is re-connected.

### Added

- Console warnings added for removed API and other element problems in developer mode. Some warnings are errors and are always issued while others are optional. Optional warnings can be configured per class via `MyElement.enable/disableWarning`. Making changes in update warns by default and can be toggled via `MyElement.disableWarning('change-in-update)`; migration warnings are off by default and can be toggled via `MyElement.enableWarning('migration')`.

- Added ability to add a controller to an element. A controller can implement callbacks that tie into element lifecycle, including `connectedCallback`, `disconnectedCallback`, `willUpdate`, `update`, and `updated`. To ensure it has access to the element lifecycle, a controller should be added in the element's constructor. To add a controller to the element, call `addController(controller)`.

- Added `willUpdate(changedProperties)` lifecycle method to UpdatingElement. This is called before the `update` method and can be used to compute derived state needed for updating. This method is intended to be called during server side rendering and should not manipulate element DOM.

- UpdatingElement moved from `lit-element` package to `updating-element` package.

### Removed

- [Breaking] Removed `requestUpdateInternal`. The `requestUpdate` method is now identical to this method and should be used instead.
- [Breaking] The `initialize` method has been removed. This work is now done in the element constructor.

### Fixed

- Fixes an issue with `queryAssignedNodes` when applying a selector on a slot that included text nodes on older browsers not supporting Element.matches [#1088](https://github.com/Polymer/lit-element/issues/1088).
