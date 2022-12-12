"use strict";

exports.__esModule = true;
exports.callMethod = callMethod;
exports.isCoreJSSource = isCoreJSSource;
exports.coreJSModule = coreJSModule;
exports.coreJSPureHelper = coreJSPureHelper;

var _core = require("@babel/core");

var _entries = _interopRequireDefault(require("core-js-compat/entries"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function callMethod(path, id) {
  const {
    object
  } = path.node;
  let context1, context2;

  if (_core.types.isIdentifier(object)) {
    context1 = object;
    context2 = _core.types.cloneNode(object);
  } else {
    context1 = path.scope.generateDeclaredUidIdentifier("context");
    context2 = _core.types.assignmentExpression("=", _core.types.cloneNode(context1), object);
  }

  path.replaceWith(_core.types.memberExpression(_core.types.callExpression(id, [context2]), _core.types.identifier("call")));
  path.parentPath.unshiftContainer("arguments", context1);
}

function isCoreJSSource(source) {
  if (typeof source === "string") {
    source = source.replace(/\\/g, "/").replace(/(\/(index)?)?(\.js)?$/i, "").toLowerCase();
  }

  return hasOwnProperty.call(_entries.default, source) && _entries.default[source];
}

function coreJSModule(name) {
  return `core-js/modules/${name}.js`;
}

function coreJSPureHelper(name, useBabelRuntime, ext) {
  return useBabelRuntime ? `${useBabelRuntime}/core-js/${name}${ext}` : `core-js-pure/features/${name}.js`;
}