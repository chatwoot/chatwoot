import "core-js/modules/es.array.reduce.js";
import deprecate from 'util-deprecate';
import dedent from 'ts-dedent';
import { deepDiff, DEEPLY_EQUAL } from './args';
import { getValuesFromArgTypes } from './csf/getValuesFromArgTypes';
const setUndeclaredWarning = deprecate(() => {}, dedent`
    Setting a global value that is undeclared (i.e. not in the user's initial set of globals
    or globalTypes) is deprecated and will have no effect in 7.0.
  `);
export class GlobalsStore {
  constructor() {
    this.allowedGlobalNames = void 0;
    this.initialGlobals = void 0;
    this.globals = {};
  }

  set({
    globals = {},
    globalTypes = {}
  }) {
    const delta = this.initialGlobals && deepDiff(this.initialGlobals, this.globals);
    this.allowedGlobalNames = new Set([...Object.keys(globals), ...Object.keys(globalTypes)]);
    const defaultGlobals = getValuesFromArgTypes(globalTypes);
    this.initialGlobals = Object.assign({}, defaultGlobals, globals);
    this.globals = this.initialGlobals;

    if (delta && delta !== DEEPLY_EQUAL) {
      this.updateFromPersisted(delta);
    }
  }

  filterAllowedGlobals(globals) {
    return Object.entries(globals).reduce((acc, [key, value]) => {
      if (this.allowedGlobalNames.has(key)) acc[key] = value;
      return acc;
    }, {});
  }

  updateFromPersisted(persisted) {
    const allowedUrlGlobals = this.filterAllowedGlobals(persisted); // Note that unlike args, we do not have the same type information for globals to allow us
    // to type check them here, so we just set them naively

    this.globals = Object.assign({}, this.globals, allowedUrlGlobals);
  }

  get() {
    return this.globals;
  }

  update(newGlobals) {
    Object.keys(newGlobals).forEach(key => {
      if (!this.allowedGlobalNames.has(key)) {
        setUndeclaredWarning();
      }
    });
    this.globals = Object.assign({}, this.globals, newGlobals);
  }

}