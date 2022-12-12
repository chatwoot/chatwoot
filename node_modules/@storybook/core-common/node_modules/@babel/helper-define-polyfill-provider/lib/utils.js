"use strict";

exports.__esModule = true;
exports.intersection = intersection;
exports.has = has;
exports.resolveKey = resolveKey;
exports.resolveSource = resolveSource;
exports.getImportSource = getImportSource;
exports.getRequireSource = getRequireSource;
exports.createUtilsGetter = createUtilsGetter;

var _core = require("@babel/core");

function intersection(a, b) {
  const result = new Set();
  a.forEach(v => b.has(v) && result.add(v));
  return result;
}

function has(object, key) {
  return Object.prototype.hasOwnProperty.call(object, key);
}

function getType(target) {
  return Object.prototype.toString.call(target).slice(8, -1);
}

function resolveId(path) {
  if (path.isIdentifier() && !path.scope.hasBinding(path.node.name,
  /* noGlobals */
  true)) {
    return path.node.name;
  }

  const {
    deopt
  } = path.evaluate();

  if (deopt && deopt.isIdentifier()) {
    return deopt.node.name;
  }
}

function resolveKey(path, computed = false) {
  const {
    node,
    parent,
    scope
  } = path;
  if (path.isStringLiteral()) return node.value;
  const {
    name
  } = node;
  const isIdentifier = path.isIdentifier();
  if (isIdentifier && !(computed || parent.computed)) return name;

  if (computed && path.isMemberExpression() && path.get("object").isIdentifier({
    name: "Symbol"
  }) && !scope.hasBinding("Symbol",
  /* noGlobals */
  true)) {
    const sym = resolveKey(path.get("property"), path.node.computed);
    if (sym) return "Symbol." + sym;
  }

  if (!isIdentifier || scope.hasBinding(name,
  /* noGlobals */
  true)) {
    const {
      value
    } = path.evaluate();
    if (typeof value === "string") return value;
  }
}

function resolveSource(obj) {
  if (obj.isMemberExpression() && obj.get("property").isIdentifier({
    name: "prototype"
  })) {
    const id = resolveId(obj.get("object"));

    if (id) {
      return {
        id,
        placement: "prototype"
      };
    }

    return {
      id: null,
      placement: null
    };
  }

  const id = resolveId(obj);

  if (id) {
    return {
      id,
      placement: "static"
    };
  }

  const {
    value
  } = obj.evaluate();

  if (value !== undefined) {
    return {
      id: getType(value),
      placement: "prototype"
    };
  } else if (obj.isRegExpLiteral()) {
    return {
      id: "RegExp",
      placement: "prototype"
    };
  } else if (obj.isFunction()) {
    return {
      id: "Function",
      placement: "prototype"
    };
  }

  return {
    id: null,
    placement: null
  };
}

function getImportSource({
  node
}) {
  if (node.specifiers.length === 0) return node.source.value;
}

function getRequireSource({
  node
}) {
  if (!_core.types.isExpressionStatement(node)) return;
  const {
    expression
  } = node;

  const isRequire = _core.types.isCallExpression(expression) && _core.types.isIdentifier(expression.callee) && expression.callee.name === "require" && expression.arguments.length === 1 && _core.types.isStringLiteral(expression.arguments[0]);

  if (isRequire) return expression.arguments[0].value;
}

function hoist(node) {
  node._blockHoist = 3;
  return node;
}

function createUtilsGetter(cache) {
  return path => {
    const prog = path.findParent(p => p.isProgram());
    return {
      injectGlobalImport(url) {
        cache.storeAnonymous(prog, url, (isScript, source) => {
          return isScript ? _core.template.statement.ast`require(${source})` : _core.types.importDeclaration([], source);
        });
      },

      injectNamedImport(url, name, hint = name) {
        return cache.storeNamed(prog, url, name, (isScript, source, name) => {
          const id = prog.scope.generateUidIdentifier(hint);
          return {
            node: isScript ? hoist(_core.template.statement.ast`
                  var ${id} = require(${source}).${name}
                `) : _core.types.importDeclaration([_core.types.importSpecifier(id, name)], source),
            name: id.name
          };
        });
      },

      injectDefaultImport(url, hint = url) {
        return cache.storeNamed(prog, url, "default", (isScript, source) => {
          const id = prog.scope.generateUidIdentifier(hint);
          return {
            node: isScript ? hoist(_core.template.statement.ast`var ${id} = require(${source})`) : _core.types.importDeclaration([_core.types.importDefaultSpecifier(id)], source),
            name: id.name
          };
        });
      }

    };
  };
}