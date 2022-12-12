'use strict';

Object.defineProperty(exports, '__esModule', {
  value: true
});
exports.default = void 0;

function _template() {
  const data = require('@babel/template');

  _template = function () {
    return data;
  };

  return data;
}

function _types() {
  const data = require('@babel/types');

  _types = function () {
    return data;
  };

  return data;
}

/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 */
const JEST_GLOBAL_NAME = 'jest';
const JEST_GLOBALS_MODULE_NAME = '@jest/globals';
const JEST_GLOBALS_MODULE_JEST_EXPORT_NAME = 'jest';
const hoistedVariables = new WeakSet(); // We allow `jest`, `expect`, `require`, all default Node.js globals and all
// ES2015 built-ins to be used inside of a `jest.mock` factory.
// We also allow variables prefixed with `mock` as an escape-hatch.

const ALLOWED_IDENTIFIERS = new Set(
  [
    'Array',
    'ArrayBuffer',
    'Boolean',
    'BigInt',
    'DataView',
    'Date',
    'Error',
    'EvalError',
    'Float32Array',
    'Float64Array',
    'Function',
    'Generator',
    'GeneratorFunction',
    'Infinity',
    'Int16Array',
    'Int32Array',
    'Int8Array',
    'InternalError',
    'Intl',
    'JSON',
    'Map',
    'Math',
    'NaN',
    'Number',
    'Object',
    'Promise',
    'Proxy',
    'RangeError',
    'ReferenceError',
    'Reflect',
    'RegExp',
    'Set',
    'String',
    'Symbol',
    'SyntaxError',
    'TypeError',
    'URIError',
    'Uint16Array',
    'Uint32Array',
    'Uint8Array',
    'Uint8ClampedArray',
    'WeakMap',
    'WeakSet',
    'arguments',
    'console',
    'expect',
    'isNaN',
    'jest',
    'parseFloat',
    'parseInt',
    'require',
    'undefined',
    ...Object.getOwnPropertyNames(global)
  ].sort()
);
const IDVisitor = {
  ReferencedIdentifier(path, {ids}) {
    ids.add(path);
  },

  blacklist: ['TypeAnnotation', 'TSTypeAnnotation', 'TSTypeReference']
};
const FUNCTIONS = Object.create(null);

FUNCTIONS.mock = args => {
  if (args.length === 1) {
    return args[0].isStringLiteral() || args[0].isLiteral();
  } else if (args.length === 2 || args.length === 3) {
    const moduleFactory = args[1];

    if (!moduleFactory.isFunction()) {
      throw moduleFactory.buildCodeFrameError(
        'The second argument of `jest.mock` must be an inline function.\n',
        TypeError
      );
    }

    const ids = new Set();
    const parentScope = moduleFactory.parentPath.scope; // @ts-expect-error: ReferencedIdentifier and blacklist are not known on visitors

    moduleFactory.traverse(IDVisitor, {
      ids
    });

    for (const id of ids) {
      const {name} = id.node;
      let found = false;
      let scope = id.scope;

      while (scope !== parentScope) {
        if (scope.bindings[name]) {
          found = true;
          break;
        }

        scope = scope.parent;
      }

      if (!found) {
        let isAllowedIdentifier =
          (scope.hasGlobal(name) && ALLOWED_IDENTIFIERS.has(name)) ||
          /^mock/i.test(name) || // Allow istanbul's coverage variable to pass.
          /^(?:__)?cov/.test(name);

        if (!isAllowedIdentifier) {
          const binding = scope.bindings[name];

          if (
            binding === null || binding === void 0
              ? void 0
              : binding.path.isVariableDeclarator()
          ) {
            const {node} = binding.path;
            const initNode = node.init;

            if (initNode && binding.constant && scope.isPure(initNode, true)) {
              hoistedVariables.add(node);
              isAllowedIdentifier = true;
            }
          }
        }

        if (!isAllowedIdentifier) {
          throw id.buildCodeFrameError(
            'The module factory of `jest.mock()` is not allowed to ' +
              'reference any out-of-scope variables.\n' +
              'Invalid variable access: ' +
              name +
              '\n' +
              'Allowed objects: ' +
              Array.from(ALLOWED_IDENTIFIERS).join(', ') +
              '.\n' +
              'Note: This is a precaution to guard against uninitialized mock ' +
              'variables. If it is ensured that the mock is required lazily, ' +
              'variable names prefixed with `mock` (case insensitive) are permitted.\n',
            ReferenceError
          );
        }
      }
    }

    return true;
  }

  return false;
};

FUNCTIONS.unmock = args => args.length === 1 && args[0].isStringLiteral();

FUNCTIONS.deepUnmock = args => args.length === 1 && args[0].isStringLiteral();

FUNCTIONS.disableAutomock = FUNCTIONS.enableAutomock = args =>
  args.length === 0;

const createJestObjectGetter = (0, _template().statement)`
function GETTER_NAME() {
  const { JEST_GLOBALS_MODULE_JEST_EXPORT_NAME } = require("JEST_GLOBALS_MODULE_NAME");
  GETTER_NAME = () => JEST_GLOBALS_MODULE_JEST_EXPORT_NAME;
  return JEST_GLOBALS_MODULE_JEST_EXPORT_NAME;
}
`;

const isJestObject = expression => {
  // global
  if (
    expression.isIdentifier() &&
    expression.node.name === JEST_GLOBAL_NAME &&
    !expression.scope.hasBinding(JEST_GLOBAL_NAME)
  ) {
    return true;
  } // import { jest } from '@jest/globals'

  if (
    expression.referencesImport(
      JEST_GLOBALS_MODULE_NAME,
      JEST_GLOBALS_MODULE_JEST_EXPORT_NAME
    )
  ) {
    return true;
  } // import * as JestGlobals from '@jest/globals'

  if (
    expression.isMemberExpression() &&
    !expression.node.computed &&
    expression.get('object').referencesImport(JEST_GLOBALS_MODULE_NAME, '*') &&
    expression.node.property.type === 'Identifier' &&
    expression.node.property.name === JEST_GLOBALS_MODULE_JEST_EXPORT_NAME
  ) {
    return true;
  }

  return false;
};

const extractJestObjExprIfHoistable = expr => {
  var _FUNCTIONS$propertyNa;

  if (!expr.isCallExpression()) {
    return null;
  }

  const callee = expr.get('callee');
  const args = expr.get('arguments');

  if (!callee.isMemberExpression() || callee.node.computed) {
    return null;
  }

  const object = callee.get('object');
  const property = callee.get('property');
  const propertyName = property.node.name;
  const jestObjExpr = isJestObject(object)
    ? object // The Jest object could be returned from another call since the functions are all chainable.
    : extractJestObjExprIfHoistable(object);

  if (!jestObjExpr) {
    return null;
  } // Important: Call the function check last
  // It might throw an error to display to the user,
  // which should only happen if we're already sure it's a call on the Jest object.

  const functionLooksHoistable =
    (_FUNCTIONS$propertyNa = FUNCTIONS[propertyName]) === null ||
    _FUNCTIONS$propertyNa === void 0
      ? void 0
      : _FUNCTIONS$propertyNa.call(FUNCTIONS, args);
  return functionLooksHoistable ? jestObjExpr : null;
};
/* eslint-disable sort-keys */

var _default = () => ({
  pre({path: program}) {
    this.declareJestObjGetterIdentifier = () => {
      if (this.jestObjGetterIdentifier) {
        return this.jestObjGetterIdentifier;
      }

      this.jestObjGetterIdentifier = program.scope.generateUidIdentifier(
        'getJestObj'
      );
      program.unshiftContainer('body', [
        createJestObjectGetter({
          GETTER_NAME: this.jestObjGetterIdentifier.name,
          JEST_GLOBALS_MODULE_JEST_EXPORT_NAME,
          JEST_GLOBALS_MODULE_NAME
        })
      ]);
      return this.jestObjGetterIdentifier;
    };
  },

  visitor: {
    ExpressionStatement(exprStmt) {
      const jestObjExpr = extractJestObjExprIfHoistable(
        exprStmt.get('expression')
      );

      if (jestObjExpr) {
        jestObjExpr.replaceWith(
          (0, _types().callExpression)(
            this.declareJestObjGetterIdentifier(),
            []
          )
        );
      }
    }
  },

  // in `post` to make sure we come after an import transform and can unshift above the `require`s
  post({path: program}) {
    const self = this;
    visitBlock(program);
    program.traverse({
      BlockStatement: visitBlock
    });

    function visitBlock(block) {
      // use a temporary empty statement instead of the real first statement, which may itself be hoisted
      const [varsHoistPoint, callsHoistPoint] = block.unshiftContainer('body', [
        (0, _types().emptyStatement)(),
        (0, _types().emptyStatement)()
      ]);
      block.traverse({
        CallExpression: visitCallExpr,
        VariableDeclarator: visitVariableDeclarator,
        // do not traverse into nested blocks, or we'll hoist calls in there out to this block
        // @ts-expect-error blacklist is not known
        blacklist: ['BlockStatement']
      });
      callsHoistPoint.remove();
      varsHoistPoint.remove();

      function visitCallExpr(callExpr) {
        var _self$jestObjGetterId;

        const {
          node: {callee}
        } = callExpr;

        if (
          (0, _types().isIdentifier)(callee) &&
          callee.name ===
            ((_self$jestObjGetterId = self.jestObjGetterIdentifier) === null ||
            _self$jestObjGetterId === void 0
              ? void 0
              : _self$jestObjGetterId.name)
        ) {
          const mockStmt = callExpr.getStatementParent();

          if (mockStmt) {
            const mockStmtParent = mockStmt.parentPath;

            if (mockStmtParent.isBlock()) {
              const mockStmtNode = mockStmt.node;
              mockStmt.remove();
              callsHoistPoint.insertBefore(mockStmtNode);
            }
          }
        }
      }

      function visitVariableDeclarator(varDecl) {
        if (hoistedVariables.has(varDecl.node)) {
          // should be assert function, but it's not. So let's cast below
          varDecl.parentPath.assertVariableDeclaration();
          const {kind, declarations} = varDecl.parent;

          if (declarations.length === 1) {
            varDecl.parentPath.remove();
          } else {
            varDecl.remove();
          }

          varsHoistPoint.insertBefore(
            (0, _types().variableDeclaration)(kind, [varDecl.node])
          );
        }
      }
    }
  }
});
/* eslint-enable */

exports.default = _default;
