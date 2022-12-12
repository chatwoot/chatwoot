'use strict';

Object.defineProperty(exports, '__esModule', { value: true });

var helperPluginUtils = require('@babel/helper-plugin-utils');
var pluginProposalOptionalChaining = require('@babel/plugin-proposal-optional-chaining');
var helperSkipTransparentExpressionWrappers = require('@babel/helper-skip-transparent-expression-wrappers');
var core = require('@babel/core');

function matchAffectedArguments(argumentNodes) {
  const spreadIndex = argumentNodes.findIndex(node => core.types.isSpreadElement(node));
  return spreadIndex >= 0 && spreadIndex !== argumentNodes.length - 1;
}

function shouldTransform(path) {
  let optionalPath = path;
  const chains = [];

  while (optionalPath.isOptionalMemberExpression() || optionalPath.isOptionalCallExpression()) {
    const {
      node
    } = optionalPath;
    chains.push(node);

    if (optionalPath.isOptionalMemberExpression()) {
      optionalPath = helperSkipTransparentExpressionWrappers.skipTransparentExprWrappers(optionalPath.get("object"));
    } else if (optionalPath.isOptionalCallExpression()) {
      optionalPath = helperSkipTransparentExpressionWrappers.skipTransparentExprWrappers(optionalPath.get("callee"));
    }
  }

  for (let i = 0; i < chains.length; i++) {
    const node = chains[i];

    if (core.types.isOptionalCallExpression(node) && matchAffectedArguments(node.arguments)) {
      if (node.optional) {
        return true;
      }

      const callee = chains[i + 1];

      if (core.types.isOptionalMemberExpression(callee, {
        optional: true
      })) {
        return true;
      }
    }
  }

  return false;
}

var index = helperPluginUtils.declare(api => {
  api.assertVersion(7);
  const noDocumentAll = api.assumption("noDocumentAll");
  const pureGetters = api.assumption("pureGetters");
  return {
    name: "bugfix-v8-spread-parameters-in-optional-chaining",
    visitor: {
      "OptionalCallExpression|OptionalMemberExpression"(path) {
        if (shouldTransform(path)) {
          pluginProposalOptionalChaining.transform(path, {
            noDocumentAll,
            pureGetters
          });
        }
      }

    }
  };
});

exports.default = index;
//# sourceMappingURL=index.js.map
