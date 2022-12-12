"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = transpileNamespace;

var _core = require("@babel/core");

function transpileNamespace(path, t, allowNamespaces) {
  if (path.node.declare || path.node.id.type === "StringLiteral") {
    path.remove();
    return;
  }

  if (!allowNamespaces) {
    throw path.hub.file.buildCodeFrameError(path.node.id, "Namespace not marked type-only declare." + " Non-declarative namespaces are only supported experimentally in Babel." + " To enable and review caveats see:" + " https://babeljs.io/docs/en/babel-plugin-transform-typescript");
  }

  const name = path.node.id.name;
  const value = handleNested(path, t, t.cloneDeep(path.node));
  const bound = path.scope.hasOwnBinding(name);

  if (path.parent.type === "ExportNamedDeclaration") {
    if (!bound) {
      path.parentPath.insertAfter(value);
      path.replaceWith(getDeclaration(t, name));
      path.scope.registerDeclaration(path.parentPath);
    } else {
      path.parentPath.replaceWith(value);
    }
  } else if (bound) {
    path.replaceWith(value);
  } else {
    path.scope.registerDeclaration(path.replaceWithMultiple([getDeclaration(t, name), value])[0]);
  }
}

function getDeclaration(t, name) {
  return t.variableDeclaration("let", [t.variableDeclarator(t.identifier(name))]);
}

function getMemberExpression(t, name, itemName) {
  return t.memberExpression(t.identifier(name), t.identifier(itemName));
}

function handleVariableDeclaration(node, name, hub) {
  if (node.kind !== "const") {
    throw hub.file.buildCodeFrameError(node, "Namespaces exporting non-const are not supported by Babel." + " Change to const or see:" + " https://babeljs.io/docs/en/babel-plugin-transform-typescript");
  }

  const {
    declarations
  } = node;

  if (declarations.every(declarator => _core.types.isIdentifier(declarator.id))) {
    for (const declarator of node.declarations) {
      declarator.init = _core.types.assignmentExpression("=", getMemberExpression(_core.types, name, declarator.id.name), declarator.init);
    }

    return [node];
  }

  const bindingIdentifiers = _core.types.getBindingIdentifiers(node);

  const assignments = [];

  for (const idName in bindingIdentifiers) {
    assignments.push(_core.types.assignmentExpression("=", getMemberExpression(_core.types, name, idName), _core.types.cloneNode(bindingIdentifiers[idName])));
  }

  return [node, _core.types.expressionStatement(_core.types.sequenceExpression(assignments))];
}

function handleNested(path, t, node, parentExport) {
  const names = new Set();
  const realName = node.id;
  const name = path.scope.generateUid(realName.name);
  const namespaceTopLevel = node.body.body;

  for (let i = 0; i < namespaceTopLevel.length; i++) {
    const subNode = namespaceTopLevel[i];

    switch (subNode.type) {
      case "TSModuleDeclaration":
        {
          const transformed = handleNested(path, t, subNode);
          const moduleName = subNode.id.name;

          if (names.has(moduleName)) {
            namespaceTopLevel[i] = transformed;
          } else {
            names.add(moduleName);
            namespaceTopLevel.splice(i++, 1, getDeclaration(t, moduleName), transformed);
          }

          continue;
        }

      case "TSEnumDeclaration":
      case "FunctionDeclaration":
      case "ClassDeclaration":
        names.add(subNode.id.name);
        continue;

      case "VariableDeclaration":
        {
          for (const name in t.getBindingIdentifiers(subNode)) {
            names.add(name);
          }

          continue;
        }

      default:
        continue;

      case "ExportNamedDeclaration":
    }

    switch (subNode.declaration.type) {
      case "TSEnumDeclaration":
      case "FunctionDeclaration":
      case "ClassDeclaration":
        {
          const itemName = subNode.declaration.id.name;
          names.add(itemName);
          namespaceTopLevel.splice(i++, 1, subNode.declaration, t.expressionStatement(t.assignmentExpression("=", getMemberExpression(t, name, itemName), t.identifier(itemName))));
          break;
        }

      case "VariableDeclaration":
        {
          const nodes = handleVariableDeclaration(subNode.declaration, name, path.hub);
          namespaceTopLevel.splice(i, nodes.length, ...nodes);
          i += nodes.length - 1;
          break;
        }

      case "TSModuleDeclaration":
        {
          const transformed = handleNested(path, t, subNode.declaration, t.identifier(name));
          const moduleName = subNode.declaration.id.name;

          if (names.has(moduleName)) {
            namespaceTopLevel[i] = transformed;
          } else {
            names.add(moduleName);
            namespaceTopLevel.splice(i++, 1, getDeclaration(t, moduleName), transformed);
          }
        }
    }
  }

  let fallthroughValue = t.objectExpression([]);

  if (parentExport) {
    const memberExpr = t.memberExpression(parentExport, realName);
    fallthroughValue = _core.template.expression.ast`
      ${t.cloneNode(memberExpr)} ||
        (${t.cloneNode(memberExpr)} = ${fallthroughValue})
    `;
  }

  return _core.template.statement.ast`
    (function (${t.identifier(name)}) {
      ${namespaceTopLevel}
    })(${realName} || (${t.cloneNode(realName)} = ${fallthroughValue}));
  `;
}