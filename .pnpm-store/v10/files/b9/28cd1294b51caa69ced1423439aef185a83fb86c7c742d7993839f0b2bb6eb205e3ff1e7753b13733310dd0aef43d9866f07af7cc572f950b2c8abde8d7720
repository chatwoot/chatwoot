Object.defineProperty(exports, '__esModule', { value: true });

const node = require('./node.js');
const worldwide = require('./worldwide.js');

/**
 * Returns true if we are in the browser.
 */
function isBrowser() {
  // eslint-disable-next-line no-restricted-globals
  return typeof window !== 'undefined' && (!node.isNodeEnv() || isElectronNodeRenderer());
}

// Electron renderers with nodeIntegration enabled are detected as Node.js so we specifically test for them
function isElectronNodeRenderer() {
  return (
    // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-explicit-any
    (worldwide.GLOBAL_OBJ ).process !== undefined && ((worldwide.GLOBAL_OBJ ).process ).type === 'renderer'
  );
}

exports.isBrowser = isBrowser;
//# sourceMappingURL=isBrowser.js.map
