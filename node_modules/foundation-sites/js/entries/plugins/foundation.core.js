// --- Foundation Core API ---
// Initialize Foundation and add some utilities to its public API for backward compatibility.
// Please note that every utility do not have to be added to the core API.
import $ from 'jquery';
import { Foundation } from '../../foundation.core';
import { Plugin } from '../../foundation.core.plugin';
import { rtl, GetYoDigits, transitionend, RegExpEscape, onLoad } from '../../foundation.core.utils';

Foundation.addToJquery($);

// Every plugin depends on plugin now, we can include that on the core for the
// script inclusion path.
Foundation.Plugin = Plugin;

// These are now separated out, but historically were a part of this module,
// and since this is here for backwards compatibility we include them in
// this entry.
Foundation.rtl = rtl;
Foundation.GetYoDigits = GetYoDigits;
Foundation.transitionend = transitionend;
Foundation.RegExpEscape = RegExpEscape;
Foundation.onLoad = onLoad;

window.Foundation = Foundation;

// --- Foundation Core exports ---
// Export "Plugin" and all core utilities, since the `foundation.core` entry plays the role of
// all core source files.

export { Foundation };
export * from '../../foundation.core.plugin';
export * from '../../foundation.core.utils';
