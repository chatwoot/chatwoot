import { isNodeEnv } from './node.js';
import { GLOBAL_OBJ } from './worldwide.js';

/**
 * Returns true if we are in the browser.
 */
function isBrowser() {
  // eslint-disable-next-line no-restricted-globals
  return typeof window !== 'undefined' && (!isNodeEnv() || isElectronNodeRenderer());
}

// Electron renderers with nodeIntegration enabled are detected as Node.js so we specifically test for them
function isElectronNodeRenderer() {
  return (
    // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-explicit-any
    (GLOBAL_OBJ ).process !== undefined && ((GLOBAL_OBJ ).process ).type === 'renderer'
  );
}

export { isBrowser };
//# sourceMappingURL=isBrowser.js.map
