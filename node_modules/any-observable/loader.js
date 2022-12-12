'use strict';
const REGISTRATION_KEY = Symbol('@@any-observable/REGISTRATION');
let registered = null;

module.exports = (global, loadImplementation) => {
	return (implementation, opts) => {
		opts = opts || {};

		// global registration unless explicitly  {global: false} in options (default true)
		const registerGlobal = opts.global !== false;

		// Load any previous global registration
		if (registerGlobal && !registered) {
			registered = global[REGISTRATION_KEY];
		}

		if (registered && implementation && registered.implementation !== implementation) {
			throw new Error(`any-observable already defined as "${registered.implementation}". You can only register an implementation before the first call to require('any-observable') and an implementation cannot be changed`);
		}

		if (!registered) {
			// Use provided implementation
			if (implementation && opts.Observable) {
				registered = {
					Observable: opts.Observable,
					implementation
				};
			} else {
				// Require implementation if implementation is specified but not provided
				registered = loadImplementation(implementation || null);
			}

			if (registerGlobal) {
				// Register preference globally in case multiple installations
				global[REGISTRATION_KEY] = registered;
			}
		}

		return registered;
	};
};
