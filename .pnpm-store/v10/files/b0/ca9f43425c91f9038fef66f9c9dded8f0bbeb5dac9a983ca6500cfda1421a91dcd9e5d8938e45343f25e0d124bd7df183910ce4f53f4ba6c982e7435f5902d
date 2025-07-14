'use strict';

Object.defineProperty(exports, '__esModule', {
  value: true
});

var w3cKeyname = require('w3c-keyname');

var prosemirrorState = require('prosemirror-state');

var mac = typeof navigator != "undefined" ? /Mac|iP(hone|[oa]d)/.test(navigator.platform) : false;

function normalizeKeyName(name) {
  var parts = name.split(/-(?!$)/),
      result = parts[parts.length - 1];
  if (result == "Space") result = " ";
  var alt, ctrl, shift, meta;

  for (var i = 0; i < parts.length - 1; i++) {
    var mod = parts[i];
    if (/^(cmd|meta|m)$/i.test(mod)) meta = true;else if (/^a(lt)?$/i.test(mod)) alt = true;else if (/^(c|ctrl|control)$/i.test(mod)) ctrl = true;else if (/^s(hift)?$/i.test(mod)) shift = true;else if (/^mod$/i.test(mod)) {
      if (mac) meta = true;else ctrl = true;
    } else throw new Error("Unrecognized modifier name: " + mod);
  }

  if (alt) result = "Alt-" + result;
  if (ctrl) result = "Ctrl-" + result;
  if (meta) result = "Meta-" + result;
  if (shift) result = "Shift-" + result;
  return result;
}

function normalize(map) {
  var copy = Object.create(null);

  for (var prop in map) {
    copy[normalizeKeyName(prop)] = map[prop];
  }

  return copy;
}

function modifiers(name, event) {
  var shift = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : true;
  if (event.altKey) name = "Alt-" + name;
  if (event.ctrlKey) name = "Ctrl-" + name;
  if (event.metaKey) name = "Meta-" + name;
  if (shift && event.shiftKey) name = "Shift-" + name;
  return name;
}

function keymap(bindings) {
  return new prosemirrorState.Plugin({
    props: {
      handleKeyDown: keydownHandler(bindings)
    }
  });
}

function keydownHandler(bindings) {
  var map = normalize(bindings);
  return function (view, event) {
    var name = w3cKeyname.keyName(event),
        baseName,
        direct = map[modifiers(name, event)];
    if (direct && direct(view.state, view.dispatch, view)) return true;

    if (name.length == 1 && name != " ") {
      if (event.shiftKey) {
        var noShift = map[modifiers(name, event, false)];
        if (noShift && noShift(view.state, view.dispatch, view)) return true;
      }

      if ((event.shiftKey || event.altKey || event.metaKey || name.charCodeAt(0) > 127) && (baseName = w3cKeyname.base[event.keyCode]) && baseName != name) {
        var fromCode = map[modifiers(baseName, event)];
        if (fromCode && fromCode(view.state, view.dispatch, view)) return true;
      }
    }

    return false;
  };
}

exports.keydownHandler = keydownHandler;
exports.keymap = keymap;
