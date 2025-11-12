/*! markdown-it-sup 2.0.0 https://github.com/markdown-it/markdown-it-sup @license MIT */
(function(global, factory) {
  typeof exports === "object" && typeof module !== "undefined" ? module.exports = factory() : typeof define === "function" && define.amd ? define(factory) : (global = typeof globalThis !== "undefined" ? globalThis : global || self, 
  global.markdownitSup = factory());
})(this, (function() {
  "use strict";
  // Process ^superscript^
  // same as UNESCAPE_MD_RE plus a space
    const UNESCAPE_RE = /\\([ \\!"#$%&'()*+,./:;<=>?@[\]^_`{|}~-])/g;
  function superscript(state, silent) {
    const max = state.posMax;
    const start = state.pos;
    if (state.src.charCodeAt(start) !== 94 /* ^ */) {
      return false;
    }
    if (silent) {
      return false;
    }
 // don't run any pairs in validation mode
        if (start + 2 >= max) {
      return false;
    }
    state.pos = start + 1;
    let found = false;
    while (state.pos < max) {
      if (state.src.charCodeAt(state.pos) === 94 /* ^ */) {
        found = true;
        break;
      }
      state.md.inline.skipToken(state);
    }
    if (!found || start + 1 === state.pos) {
      state.pos = start;
      return false;
    }
    const content = state.src.slice(start + 1, state.pos);
    // don't allow unescaped spaces/newlines inside
        if (content.match(/(^|[^\\])(\\\\)*\s/)) {
      state.pos = start;
      return false;
    }
    // found!
        state.posMax = state.pos;
    state.pos = start + 1;
    // Earlier we checked !silent, but this implementation does not need it
        const token_so = state.push("sup_open", "sup", 1);
    token_so.markup = "^";
    const token_t = state.push("text", "", 0);
    token_t.content = content.replace(UNESCAPE_RE, "$1");
    const token_sc = state.push("sup_close", "sup", -1);
    token_sc.markup = "^";
    state.pos = state.posMax + 1;
    state.posMax = max;
    return true;
  }
  function sup_plugin(md) {
    md.inline.ruler.after("emphasis", "sup", superscript);
  }
  return sup_plugin;
}));
