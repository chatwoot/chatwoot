'use strict';




var _staticRequire = require('../core/staticRequire');var _staticRequire2 = _interopRequireDefault(_staticRequire);
var _docsUrl = require('../docsUrl');var _docsUrl2 = _interopRequireDefault(_docsUrl);

var _debug = require('debug');var _debug2 = _interopRequireDefault(_debug);function _interopRequireDefault(obj) {return obj && obj.__esModule ? obj : { default: obj };}
const log = (0, _debug2.default)('eslint-plugin-import:rules:newline-after-import');

//------------------------------------------------------------------------------
// Rule Definition
//------------------------------------------------------------------------------
/**
 * @fileoverview Rule to enforce new line after import not followed by another import.
 * @author Radek Benkel
 */function containsNodeOrEqual(outerNode, innerNode) {return outerNode.range[0] <= innerNode.range[0] && outerNode.range[1] >= innerNode.range[1];}

function getScopeBody(scope) {
  if (scope.block.type === 'SwitchStatement') {
    log('SwitchStatement scopes not supported');
    return null;
  }const

  body = scope.block.body;
  if (body && body.type === 'BlockStatement') {
    return body.body;
  }

  return body;
}

function findNodeIndexInScopeBody(body, nodeToFind) {
  return body.findIndex(node => containsNodeOrEqual(node, nodeToFind));
}

function getLineDifference(node, nextNode) {
  return nextNode.loc.start.line - node.loc.end.line;
}

function isClassWithDecorator(node) {
  return node.type === 'ClassDeclaration' && node.decorators && node.decorators.length;
}

function isExportDefaultClass(node) {
  return node.type === 'ExportDefaultDeclaration' && node.declaration.type === 'ClassDeclaration';
}

module.exports = {
  meta: {
    type: 'layout',
    docs: {
      url: (0, _docsUrl2.default)('newline-after-import') },

    fixable: 'whitespace',
    schema: [
    {
      'type': 'object',
      'properties': {
        'count': {
          'type': 'integer',
          'minimum': 1 } },


      'additionalProperties': false }] },



  create: function (context) {
    let level = 0;
    const requireCalls = [];

    function checkForNewLine(node, nextNode, type) {
      if (isExportDefaultClass(nextNode)) {
        let classNode = nextNode.declaration;

        if (isClassWithDecorator(classNode)) {
          nextNode = classNode.decorators[0];
        }
      } else if (isClassWithDecorator(nextNode)) {
        nextNode = nextNode.decorators[0];
      }

      const options = context.options[0] || { count: 1 };
      const lineDifference = getLineDifference(node, nextNode);
      const EXPECTED_LINE_DIFFERENCE = options.count + 1;

      if (lineDifference < EXPECTED_LINE_DIFFERENCE) {
        let column = node.loc.start.column;

        if (node.loc.start.line !== node.loc.end.line) {
          column = 0;
        }

        context.report({
          loc: {
            line: node.loc.end.line,
            column },

          message: `Expected ${options.count} empty line${options.count > 1 ? 's' : ''} \
after ${type} statement not followed by another ${type}.`,
          fix: fixer => fixer.insertTextAfter(
          node,
          '\n'.repeat(EXPECTED_LINE_DIFFERENCE - lineDifference)) });


      }
    }

    function incrementLevel() {
      level++;
    }
    function decrementLevel() {
      level--;
    }

    function checkImport(node) {const
      parent = node.parent;
      const nodePosition = parent.body.indexOf(node);
      const nextNode = parent.body[nodePosition + 1];

      // skip "export import"s
      if (node.type === 'TSImportEqualsDeclaration' && node.isExport) {
        return;
      }

      if (nextNode && nextNode.type !== 'ImportDeclaration' && (nextNode.type !== 'TSImportEqualsDeclaration' || nextNode.isExport)) {
        checkForNewLine(node, nextNode, 'import');
      }
    }

    return {
      ImportDeclaration: checkImport,
      TSImportEqualsDeclaration: checkImport,
      CallExpression: function (node) {
        if ((0, _staticRequire2.default)(node) && level === 0) {
          requireCalls.push(node);
        }
      },
      'Program:exit': function () {
        log('exit processing for', context.getFilename());
        const scopeBody = getScopeBody(context.getScope());
        log('got scope:', scopeBody);

        requireCalls.forEach(function (node, index) {
          const nodePosition = findNodeIndexInScopeBody(scopeBody, node);
          log('node position in scope:', nodePosition);

          const statementWithRequireCall = scopeBody[nodePosition];
          const nextStatement = scopeBody[nodePosition + 1];
          const nextRequireCall = requireCalls[index + 1];

          if (nextRequireCall && containsNodeOrEqual(statementWithRequireCall, nextRequireCall)) {
            return;
          }

          if (nextStatement && (
          !nextRequireCall || !containsNodeOrEqual(nextStatement, nextRequireCall))) {

            checkForNewLine(statementWithRequireCall, nextStatement, 'require');
          }
        });
      },
      FunctionDeclaration: incrementLevel,
      FunctionExpression: incrementLevel,
      ArrowFunctionExpression: incrementLevel,
      BlockStatement: incrementLevel,
      ObjectExpression: incrementLevel,
      Decorator: incrementLevel,
      'FunctionDeclaration:exit': decrementLevel,
      'FunctionExpression:exit': decrementLevel,
      'ArrowFunctionExpression:exit': decrementLevel,
      'BlockStatement:exit': decrementLevel,
      'ObjectExpression:exit': decrementLevel,
      'Decorator:exit': decrementLevel };

  } };
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIi4uLy4uL3NyYy9ydWxlcy9uZXdsaW5lLWFmdGVyLWltcG9ydC5qcyJdLCJuYW1lcyI6WyJsb2ciLCJjb250YWluc05vZGVPckVxdWFsIiwib3V0ZXJOb2RlIiwiaW5uZXJOb2RlIiwicmFuZ2UiLCJnZXRTY29wZUJvZHkiLCJzY29wZSIsImJsb2NrIiwidHlwZSIsImJvZHkiLCJmaW5kTm9kZUluZGV4SW5TY29wZUJvZHkiLCJub2RlVG9GaW5kIiwiZmluZEluZGV4Iiwibm9kZSIsImdldExpbmVEaWZmZXJlbmNlIiwibmV4dE5vZGUiLCJsb2MiLCJzdGFydCIsImxpbmUiLCJlbmQiLCJpc0NsYXNzV2l0aERlY29yYXRvciIsImRlY29yYXRvcnMiLCJsZW5ndGgiLCJpc0V4cG9ydERlZmF1bHRDbGFzcyIsImRlY2xhcmF0aW9uIiwibW9kdWxlIiwiZXhwb3J0cyIsIm1ldGEiLCJkb2NzIiwidXJsIiwiZml4YWJsZSIsInNjaGVtYSIsImNyZWF0ZSIsImNvbnRleHQiLCJsZXZlbCIsInJlcXVpcmVDYWxscyIsImNoZWNrRm9yTmV3TGluZSIsImNsYXNzTm9kZSIsIm9wdGlvbnMiLCJjb3VudCIsImxpbmVEaWZmZXJlbmNlIiwiRVhQRUNURURfTElORV9ESUZGRVJFTkNFIiwiY29sdW1uIiwicmVwb3J0IiwibWVzc2FnZSIsImZpeCIsImZpeGVyIiwiaW5zZXJ0VGV4dEFmdGVyIiwicmVwZWF0IiwiaW5jcmVtZW50TGV2ZWwiLCJkZWNyZW1lbnRMZXZlbCIsImNoZWNrSW1wb3J0IiwicGFyZW50Iiwibm9kZVBvc2l0aW9uIiwiaW5kZXhPZiIsImlzRXhwb3J0IiwiSW1wb3J0RGVjbGFyYXRpb24iLCJUU0ltcG9ydEVxdWFsc0RlY2xhcmF0aW9uIiwiQ2FsbEV4cHJlc3Npb24iLCJwdXNoIiwiZ2V0RmlsZW5hbWUiLCJzY29wZUJvZHkiLCJnZXRTY29wZSIsImZvckVhY2giLCJpbmRleCIsInN0YXRlbWVudFdpdGhSZXF1aXJlQ2FsbCIsIm5leHRTdGF0ZW1lbnQiLCJuZXh0UmVxdWlyZUNhbGwiLCJGdW5jdGlvbkRlY2xhcmF0aW9uIiwiRnVuY3Rpb25FeHByZXNzaW9uIiwiQXJyb3dGdW5jdGlvbkV4cHJlc3Npb24iLCJCbG9ja1N0YXRlbWVudCIsIk9iamVjdEV4cHJlc3Npb24iLCJEZWNvcmF0b3IiXSwibWFwcGluZ3MiOiI7Ozs7O0FBS0Esc0Q7QUFDQSxxQzs7QUFFQSw4QjtBQUNBLE1BQU1BLE1BQU0scUJBQU0saURBQU4sQ0FBWjs7QUFFQTtBQUNBO0FBQ0E7QUFiQTs7O0dBZUEsU0FBU0MsbUJBQVQsQ0FBNkJDLFNBQTdCLEVBQXdDQyxTQUF4QyxFQUFtRCxDQUMvQyxPQUFPRCxVQUFVRSxLQUFWLENBQWdCLENBQWhCLEtBQXNCRCxVQUFVQyxLQUFWLENBQWdCLENBQWhCLENBQXRCLElBQTRDRixVQUFVRSxLQUFWLENBQWdCLENBQWhCLEtBQXNCRCxVQUFVQyxLQUFWLENBQWdCLENBQWhCLENBQXpFLENBQ0g7O0FBRUQsU0FBU0MsWUFBVCxDQUFzQkMsS0FBdEIsRUFBNkI7QUFDekIsTUFBSUEsTUFBTUMsS0FBTixDQUFZQyxJQUFaLEtBQXFCLGlCQUF6QixFQUE0QztBQUMxQ1IsUUFBSSxzQ0FBSjtBQUNBLFdBQU8sSUFBUDtBQUNELEdBSndCOztBQU1qQlMsTUFOaUIsR0FNUkgsTUFBTUMsS0FORSxDQU1qQkUsSUFOaUI7QUFPekIsTUFBSUEsUUFBUUEsS0FBS0QsSUFBTCxLQUFjLGdCQUExQixFQUE0QztBQUN4QyxXQUFPQyxLQUFLQSxJQUFaO0FBQ0g7O0FBRUQsU0FBT0EsSUFBUDtBQUNIOztBQUVELFNBQVNDLHdCQUFULENBQWtDRCxJQUFsQyxFQUF3Q0UsVUFBeEMsRUFBb0Q7QUFDaEQsU0FBT0YsS0FBS0csU0FBTCxDQUFnQkMsSUFBRCxJQUFVWixvQkFBb0JZLElBQXBCLEVBQTBCRixVQUExQixDQUF6QixDQUFQO0FBQ0g7O0FBRUQsU0FBU0csaUJBQVQsQ0FBMkJELElBQTNCLEVBQWlDRSxRQUFqQyxFQUEyQztBQUN6QyxTQUFPQSxT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QUFDQSxnQkFBTWMsa0JBQWtCaEMsYUFBYTZCLFFBQVEsQ0FBckIsQ0FBeEI7O0FBRUEsY0FBSUcsbUJBQW1CbEUsb0JBQW9CZ0Usd0JBQXBCLEVBQThDRSxlQUE5QyxDQUF2QixFQUF1RjtBQUNyRjtBQUNEOztBQUVELGNBQUlEO0FBQ0EsV0FBQ0MsZUFBRCxJQUFvQixDQUFDbEUsb0JBQW9CaUUsYUFBcEIsRUFBbUNDLGVBQW5DLENBRHJCLENBQUosRUFDK0U7O0FBRTdFL0IsNEJBQWdCNkIsd0JBQWhCLEVBQTBDQyxhQUExQyxFQUF5RCxTQUF6RDtBQUNEO0FBQ0YsU0FqQkQ7QUFrQkQsT0EvQkk7QUFnQ0xFLDJCQUFxQm5CLGNBaENoQjtBQWlDTG9CLDBCQUFvQnBCLGNBakNmO0FBa0NMcUIsK0JBQXlCckIsY0FsQ3BCO0FBbUNMc0Isc0JBQWdCdEIsY0FuQ1g7QUFvQ0x1Qix3QkFBa0J2QixjQXBDYjtBQXFDTHdCLGlCQUFXeEIsY0FyQ047QUFzQ0wsa0NBQTRCQyxjQXRDdkI7QUF1Q0wsaUNBQTJCQSxjQXZDdEI7QUF3Q0wsc0NBQWdDQSxjQXhDM0I7QUF5Q0wsNkJBQXVCQSxjQXpDbEI7QUEwQ0wsK0JBQXlCQSxjQTFDcEI7QUEyQ0wsd0JBQWtCQSxjQTNDYixFQUFQOztBQTZDRCxHQWhJYyxFQUFqQiIsImZpbGUiOiJuZXdsaW5lLWFmdGVyLWltcG9ydC5qcyIsInNvdXJjZXNDb250ZW50IjpbIi8qKlxuICogQGZpbGVvdmVydmlldyBSdWxlIHRvIGVuZm9yY2UgbmV3IGxpbmUgYWZ0ZXIgaW1wb3J0IG5vdCBmb2xsb3dlZCBieSBhbm90aGVyIGltcG9ydC5cbiAqIEBhdXRob3IgUmFkZWsgQmVua2VsXG4gKi9cblxuaW1wb3J0IGlzU3RhdGljUmVxdWlyZSBmcm9tICcuLi9jb3JlL3N0YXRpY1JlcXVpcmUnXG5pbXBvcnQgZG9jc1VybCBmcm9tICcuLi9kb2NzVXJsJ1xuXG5pbXBvcnQgZGVidWcgZnJvbSAnZGVidWcnXG5jb25zdCBsb2cgPSBkZWJ1ZygnZXNsaW50LXBsdWdpbi1pbXBvcnQ6cnVsZXM6bmV3bGluZS1hZnRlci1pbXBvcnQnKVxuXG4vLy0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLVxuLy8gUnVsZSBEZWZpbml0aW9uXG4vLy0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLVxuXG5mdW5jdGlvbiBjb250YWluc05vZGVPckVxdWFsKG91dGVyTm9kZSwgaW5uZXJOb2RlKSB7XG4gICAgcmV0dXJuIG91dGVyTm9kZS5yYW5nZVswXSA8PSBpbm5lck5vZGUucmFuZ2VbMF0gJiYgb3V0ZXJOb2RlLnJhbmdlWzFdID49IGlubmVyTm9kZS5yYW5nZVsxXVxufVxuXG5mdW5jdGlvbiBnZXRTY29wZUJvZHkoc2NvcGUpIHtcbiAgICBpZiAoc2NvcGUuYmxvY2sudHlwZSA9PT0gJ1N3aXRjaFN0YXRlbWVudCcpIHtcbiAgICAgIGxvZygnU3dpdGNoU3RhdGVtZW50IHNjb3BlcyBub3Qgc3VwcG9ydGVkJylcbiAgICAgIHJldHVybiBudWxsXG4gICAgfVxuXG4gICAgY29uc3QgeyBib2R5IH0gPSBzY29wZS5ibG9ja1xuICAgIGlmIChib2R5ICYmIGJvZHkudHlwZSA9PT0gJ0Jsb2NrU3RhdGVtZW50Jykge1xuICAgICAgICByZXR1cm4gYm9keS5ib2R5XG4gICAgfVxuXG4gICAgcmV0dXJuIGJvZHlcbn1cblxuZnVuY3Rpb24gZmluZE5vZGVJbmRleEluU2NvcGVCb2R5KGJvZHksIG5vZGVUb0ZpbmQpIHtcbiAgICByZXR1cm4gYm9keS5maW5kSW5kZXgoKG5vZGUpID0+IGNvbnRhaW5zTm9kZU9yRXF1YWwobm9kZSwgbm9kZVRvRmluZCkpXG59XG5cbmZ1bmN0aW9uIGdldExpbmVEaWZmZXJlbmNlKG5vZGUsIG5leHROb2RlKSB7XG4gIHJldHVybiBuZXh0Tm9kZS5sb2Muc3RhcnQubGluZSAtIG5vZGUubG9jLmVuZC5saW5lXG59XG5cbmZ1bmN0aW9uIGlzQ2xhc3NXaXRoRGVjb3JhdG9yKG5vZGUpIHtcbiAgcmV0dXJuIG5vZGUudHlwZSA9PT0gJ0NsYXNzRGVjbGFyYXRpb24nICYmIG5vZGUuZGVjb3JhdG9ycyAmJiBub2RlLmRlY29yYXRvcnMubGVuZ3RoXG59XG5cbmZ1bmN0aW9uIGlzRXhwb3J0RGVmYXVsdENsYXNzKG5vZGUpIHtcbiAgcmV0dXJuIG5vZGUudHlwZSA9PT0gJ0V4cG9ydERlZmF1bHREZWNsYXJhdGlvbicgJiYgbm9kZS5kZWNsYXJhdGlvbi50eXBlID09PSAnQ2xhc3NEZWNsYXJhdGlvbidcbn1cblxubW9kdWxlLmV4cG9ydHMgPSB7XG4gIG1ldGE6IHtcbiAgICB0eXBlOiAnbGF5b3V0JyxcbiAgICBkb2NzOiB7XG4gICAgICB1cmw6IGRvY3NVcmwoJ25ld2xpbmUtYWZ0ZXItaW1wb3J0JyksXG4gICAgfSxcbiAgICBmaXhhYmxlOiAnd2hpdGVzcGFjZScsXG4gICAgc2NoZW1hOiBbXG4gICAgICB7XG4gICAgICAgICd0eXBlJzogJ29iamVjdCcsXG4gICAgICAgICdwcm9wZXJ0aWVzJzoge1xuICAgICAgICAgICdjb3VudCc6IHtcbiAgICAgICAgICAgICd0eXBlJzogJ2ludGVnZXInLFxuICAgICAgICAgICAgJ21pbmltdW0nOiAxLFxuICAgICAgICAgIH0sXG4gICAgICAgIH0sXG4gICAgICAgICdhZGRpdGlvbmFsUHJvcGVydGllcyc6IGZhbHNlLFxuICAgICAgfSxcbiAgICBdLFxuICB9LFxuICBjcmVhdGU6IGZ1bmN0aW9uIChjb250ZXh0KSB7XG4gICAgbGV0IGxldmVsID0gMFxuICAgIGNvbnN0IHJlcXVpcmVDYWxscyA9IFtdXG5cbiAgICBmdW5jdGlvbiBjaGVja0Zvck5ld0xpbmUobm9kZSwgbmV4dE5vZGUsIHR5cGUpIHtcbiAgICAgIGlmIChpc0V4cG9ydERlZmF1bHRDbGFzcyhuZXh0Tm9kZSkpIHtcbiAgICAgICAgbGV0IGNsYXNzTm9kZSA9IG5leHROb2RlLmRlY2xhcmF0aW9uXG5cbiAgICAgICAgaWYgKGlzQ2xhc3NXaXRoRGVjb3JhdG9yKGNsYXNzTm9kZSkpIHtcbiAgICAgICAgICBuZXh0Tm9kZSA9IGNsYXNzTm9kZS5kZWNvcmF0b3JzWzBdXG4gICAgICAgIH1cbiAgICAgIH0gZWxzZSBpZiAoaXNDbGFzc1dpdGhEZWNvcmF0b3IobmV4dE5vZGUpKSB7XG4gICAgICAgIG5leHROb2RlID0gbmV4dE5vZGUuZGVjb3JhdG9yc1swXVxuICAgICAgfVxuXG4gICAgICBjb25zdCBvcHRpb25zID0gY29udGV4dC5vcHRpb25zWzBdIHx8IHsgY291bnQ6IDEgfVxuICAgICAgY29uc3QgbGluZURpZmZlcmVuY2UgPSBnZXRMaW5lRGlmZmVyZW5jZShub2RlLCBuZXh0Tm9kZSlcbiAgICAgIGNvbnN0IEVYUEVDVEVEX0xJTkVfRElGRkVSRU5DRSA9IG9wdGlvbnMuY291bnQgKyAxXG5cbiAgICAgIGlmIChsaW5lRGlmZmVyZW5jZSA8IEVYUEVDVEVEX0xJTkVfRElGRkVSRU5DRSkge1xuICAgICAgICBsZXQgY29sdW1uID0gbm9kZS5sb2Muc3RhcnQuY29sdW1uXG5cbiAgICAgICAgaWYgKG5vZGUubG9jLnN0YXJ0LmxpbmUgIT09IG5vZGUubG9jLmVuZC5saW5lKSB7XG4gICAgICAgICAgY29sdW1uID0gMFxuICAgICAgICB9XG5cbiAgICAgICAgY29udGV4dC5yZXBvcnQoe1xuICAgICAgICAgIGxvYzoge1xuICAgICAgICAgICAgbGluZTogbm9kZS5sb2MuZW5kLmxpbmUsXG4gICAgICAgICAgICBjb2x1bW4sXG4gICAgICAgICAgfSxcbiAgICAgICAgICBtZXNzYWdlOiBgRXhwZWN0ZWQgJHtvcHRpb25zLmNvdW50fSBlbXB0eSBsaW5lJHtvcHRpb25zLmNvdW50ID4gMSA/ICdzJyA6ICcnfSBcXFxuYWZ0ZXIgJHt0eXBlfSBzdGF0ZW1lbnQgbm90IGZvbGxvd2VkIGJ5IGFub3RoZXIgJHt0eXBlfS5gLFxuICAgICAgICAgIGZpeDogZml4ZXIgPT4gZml4ZXIuaW5zZXJ0VGV4dEFmdGVyKFxuICAgICAgICAgICAgbm9kZSxcbiAgICAgICAgICAgICdcXG4nLnJlcGVhdChFWFBFQ1RFRF9MSU5FX0RJRkZFUkVOQ0UgLSBsaW5lRGlmZmVyZW5jZSlcbiAgICAgICAgICApLFxuICAgICAgICB9KVxuICAgICAgfVxuICAgIH1cblxuICAgIGZ1bmN0aW9uIGluY3JlbWVudExldmVsKCkge1xuICAgICAgbGV2ZWwrK1xuICAgIH1cbiAgICBmdW5jdGlvbiBkZWNyZW1lbnRMZXZlbCgpIHtcbiAgICAgIGxldmVsLS1cbiAgICB9XG5cbiAgICBmdW5jdGlvbiBjaGVja0ltcG9ydChub2RlKSB7XG4gICAgICAgIGNvbnN0IHsgcGFyZW50IH0gPSBub2RlXG4gICAgICAgIGNvbnN0IG5vZGVQb3NpdGlvbiA9IHBhcmVudC5ib2R5LmluZGV4T2Yobm9kZSlcbiAgICAgICAgY29uc3QgbmV4dE5vZGUgPSBwYXJlbnQuYm9keVtub2RlUG9zaXRpb24gKyAxXVxuICAgICAgICBcbiAgICAgICAgLy8gc2tpcCBcImV4cG9ydCBpbXBvcnRcInNcbiAgICAgICAgaWYgKG5vZGUudHlwZSA9PT0gJ1RTSW1wb3J0RXF1YWxzRGVjbGFyYXRpb24nICYmIG5vZGUuaXNFeHBvcnQpIHtcbiAgICAgICAgICByZXR1cm5cbiAgICAgICAgfVxuXG4gICAgICAgIGlmIChuZXh0Tm9kZSAmJiBuZXh0Tm9kZS50eXBlICE9PSAnSW1wb3J0RGVjbGFyYXRpb24nICYmIChuZXh0Tm9kZS50eXBlICE9PSAnVFNJbXBvcnRFcXVhbHNEZWNsYXJhdGlvbicgfHwgbmV4dE5vZGUuaXNFeHBvcnQpKSB7XG4gICAgICAgICAgY2hlY2tGb3JOZXdMaW5lKG5vZGUsIG5leHROb2RlLCAnaW1wb3J0JylcbiAgICAgICAgfVxuICAgIH1cblxuICAgIHJldHVybiB7XG4gICAgICBJbXBvcnREZWNsYXJhdGlvbjogY2hlY2tJbXBvcnQsXG4gICAgICBUU0ltcG9ydEVxdWFsc0RlY2xhcmF0aW9uOiBjaGVja0ltcG9ydCxcbiAgICAgIENhbGxFeHByZXNzaW9uOiBmdW5jdGlvbihub2RlKSB7XG4gICAgICAgIGlmIChpc1N0YXRpY1JlcXVpcmUobm9kZSkgJiYgbGV2ZWwgPT09IDApIHtcbiAgICAgICAgICByZXF1aXJlQ2FsbHMucHVzaChub2RlKVxuICAgICAgICB9XG4gICAgICB9LFxuICAgICAgJ1Byb2dyYW06ZXhpdCc6IGZ1bmN0aW9uICgpIHtcbiAgICAgICAgbG9nKCdleGl0IHByb2Nlc3NpbmcgZm9yJywgY29udGV4dC5nZXRGaWxlbmFtZSgpKVxuICAgICAgICBjb25zdCBzY29wZUJvZHkgPSBnZXRTY29wZUJvZHkoY29udGV4dC5nZXRTY29wZSgpKVxuICAgICAgICBsb2coJ2dvdCBzY29wZTonLCBzY29wZUJvZHkpXG5cbiAgICAgICAgcmVxdWlyZUNhbGxzLmZvckVhY2goZnVuY3Rpb24gKG5vZGUsIGluZGV4KSB7XG4gICAgICAgICAgY29uc3Qgbm9kZVBvc2l0aW9uID0gZmluZE5vZGVJbmRleEluU2NvcGVCb2R5KHNjb3BlQm9keSwgbm9kZSlcbiAgICAgICAgICBsb2coJ25vZGUgcG9zaXRpb24gaW4gc2NvcGU6Jywgbm9kZVBvc2l0aW9uKVxuXG4gICAgICAgICAgY29uc3Qgc3RhdGVtZW50V2l0aFJlcXVpcmVDYWxsID0gc2NvcGVCb2R5W25vZGVQb3NpdGlvbl1cbiAgICAgICAgICBjb25zdCBuZXh0U3RhdGVtZW50ID0gc2NvcGVCb2R5W25vZGVQb3NpdGlvbiArIDFdXG4gICAgICAgICAgY29uc3QgbmV4dFJlcXVpcmVDYWxsID0gcmVxdWlyZUNhbGxzW2luZGV4ICsgMV1cblxuICAgICAgICAgIGlmIChuZXh0UmVxdWlyZUNhbGwgJiYgY29udGFpbnNOb2RlT3JFcXVhbChzdGF0ZW1lbnRXaXRoUmVxdWlyZUNhbGwsIG5leHRSZXF1aXJlQ2FsbCkpIHtcbiAgICAgICAgICAgIHJldHVyblxuICAgICAgICAgIH1cblxuICAgICAgICAgIGlmIChuZXh0U3RhdGVtZW50ICYmXG4gICAgICAgICAgICAgKCFuZXh0UmVxdWlyZUNhbGwgfHwgIWNvbnRhaW5zTm9kZU9yRXF1YWwobmV4dFN0YXRlbWVudCwgbmV4dFJlcXVpcmVDYWxsKSkpIHtcblxuICAgICAgICAgICAgY2hlY2tGb3JOZXdMaW5lKHN0YXRlbWVudFdpdGhSZXF1aXJlQ2FsbCwgbmV4dFN0YXRlbWVudCwgJ3JlcXVpcmUnKVxuICAgICAgICAgIH1cbiAgICAgICAgfSlcbiAgICAgIH0sXG4gICAgICBGdW5jdGlvbkRlY2xhcmF0aW9uOiBpbmNyZW1lbnRMZXZlbCxcbiAgICAgIEZ1bmN0aW9uRXhwcmVzc2lvbjogaW5jcmVtZW50TGV2ZWwsXG4gICAgICBBcnJvd0Z1bmN0aW9uRXhwcmVzc2lvbjogaW5jcmVtZW50TGV2ZWwsXG4gICAgICBCbG9ja1N0YXRlbWVudDogaW5jcmVtZW50TGV2ZWwsXG4gICAgICBPYmplY3RFeHByZXNzaW9uOiBpbmNyZW1lbnRMZXZlbCxcbiAgICAgIERlY29yYXRvcjogaW5jcmVtZW50TGV2ZWwsXG4gICAgICAnRnVuY3Rpb25EZWNsYXJhdGlvbjpleGl0JzogZGVjcmVtZW50TGV2ZWwsXG4gICAgICAnRnVuY3Rpb25FeHByZXNzaW9uOmV4aXQnOiBkZWNyZW1lbnRMZXZlbCxcbiAgICAgICdBcnJvd0Z1bmN0aW9uRXhwcmVzc2lvbjpleGl0JzogZGVjcmVtZW50TGV2ZWwsXG4gICAgICAnQmxvY2tTdGF0ZW1lbnQ6ZXhpdCc6IGRlY3JlbWVudExldmVsLFxuICAgICAgJ09iamVjdEV4cHJlc3Npb246ZXhpdCc6IGRlY3JlbWVudExldmVsLFxuICAgICAgJ0RlY29yYXRvcjpleGl0JzogZGVjcmVtZW50TGV2ZWwsXG4gICAgfVxuICB9LFxufVxuIl19