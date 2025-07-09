'use strict';




var _staticRequire = require('../core/staticRequire');var _staticRequire2 = _interopRequireDefault(_staticRequire);
var _docsUrl = require('../docsUrl');var _docsUrl2 = _interopRequireDefault(_docsUrl);

var _debug = require('debug');var _debug2 = _interopRequireDefault(_debug);function _interopRequireDefault(obj) {return obj && obj.__esModule ? obj : { 'default': obj };}
var log = (0, _debug2['default'])('eslint-plugin-import:rules:newline-after-import');

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
  }var

  body = scope.block.body;
  if (body && body.type === 'BlockStatement') {
    return body.body;
  }

  return body;
}

function findNodeIndexInScopeBody(body, nodeToFind) {
  return body.findIndex(function (node) {return containsNodeOrEqual(node, nodeToFind);});
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

function isExportNameClass(node) {

  return node.type === 'ExportNamedDeclaration' && node.declaration && node.declaration.type === 'ClassDeclaration';
}

module.exports = {
  meta: {
    type: 'layout',
    docs: {
      category: 'Style guide',
      description: 'Enforce a newline after import statements.',
      url: (0, _docsUrl2['default'])('newline-after-import') },

    fixable: 'whitespace',
    schema: [
    {
      type: 'object',
      properties: {
        count: {
          type: 'integer',
          minimum: 1 },

        exactCount: { type: 'boolean' },
        considerComments: { type: 'boolean' } },

      additionalProperties: false }] },



  create: function () {function create(context) {
      var level = 0;
      var requireCalls = [];
      var options = Object.assign({
        count: 1,
        exactCount: false,
        considerComments: false },
      context.options[0]);


      function checkForNewLine(node, nextNode, type) {
        if (isExportDefaultClass(nextNode) || isExportNameClass(nextNode)) {
          var classNode = nextNode.declaration;

          if (isClassWithDecorator(classNode)) {
            nextNode = classNode.decorators[0];
          }
        } else if (isClassWithDecorator(nextNode)) {
          nextNode = nextNode.decorators[0];
        }

        var lineDifference = getLineDifference(node, nextNode);
        var EXPECTED_LINE_DIFFERENCE = options.count + 1;

        if (
        lineDifference < EXPECTED_LINE_DIFFERENCE ||
        options.exactCount && lineDifference !== EXPECTED_LINE_DIFFERENCE)
        {
          var column = node.loc.start.column;

          if (node.loc.start.line !== node.loc.end.line) {
            column = 0;
          }

          context.report({
            loc: {
              line: node.loc.end.line,
              column: column },

            message: 'Expected ' + String(options.count) + ' empty line' + (options.count > 1 ? 's' : '') + ' after ' + String(type) + ' statement not followed by another ' + String(type) + '.',
            fix: options.exactCount && EXPECTED_LINE_DIFFERENCE < lineDifference ? undefined : function (fixer) {return fixer.insertTextAfter(
              node,
              '\n'.repeat(EXPECTED_LINE_DIFFERENCE - lineDifference));} });


        }
      }

      function commentAfterImport(node, nextComment, type) {
        var lineDifference = getLineDifference(node, nextComment);
        var EXPECTED_LINE_DIFFERENCE = options.count + 1;

        if (lineDifference < EXPECTED_LINE_DIFFERENCE) {
          var column = node.loc.start.column;

          if (node.loc.start.line !== node.loc.end.line) {
            column = 0;
          }

          context.report({
            loc: {
              line: node.loc.end.line,
              column: column },

            message: 'Expected ' + String(options.count) + ' empty line' + (options.count > 1 ? 's' : '') + ' after ' + String(type) + ' statement not followed by another ' + String(type) + '.',
            fix: options.exactCount && EXPECTED_LINE_DIFFERENCE < lineDifference ? undefined : function (fixer) {return fixer.insertTextAfter(
              node,
              '\n'.repeat(EXPECTED_LINE_DIFFERENCE - lineDifference));} });


        }
      }

      function incrementLevel() {
        level++;
      }
      function decrementLevel() {
        level--;
      }

      function checkImport(node) {var
        parent = node.parent;

        if (!parent || !parent.body) {
          return;
        }

        var nodePosition = parent.body.indexOf(node);
        var nextNode = parent.body[nodePosition + 1];
        var endLine = node.loc.end.line;
        var nextComment = void 0;

        if (typeof parent.comments !== 'undefined' && options.considerComments) {
          nextComment = parent.comments.find(function (o) {return o.loc.start.line >= endLine && o.loc.start.line <= endLine + options.count + 1;});
        }

        // skip "export import"s
        if (node.type === 'TSImportEqualsDeclaration' && node.isExport) {
          return;
        }

        if (nextComment && typeof nextComment !== 'undefined') {
          commentAfterImport(node, nextComment, 'import');
        } else if (nextNode && nextNode.type !== 'ImportDeclaration' && (nextNode.type !== 'TSImportEqualsDeclaration' || nextNode.isExport)) {
          checkForNewLine(node, nextNode, 'import');
        }
      }

      return {
        ImportDeclaration: checkImport,
        TSImportEqualsDeclaration: checkImport,
        CallExpression: function () {function CallExpression(node) {
            if ((0, _staticRequire2['default'])(node) && level === 0) {
              requireCalls.push(node);
            }
          }return CallExpression;}(),
        'Program:exit': function () {function ProgramExit() {
            log('exit processing for', context.getPhysicalFilename ? context.getPhysicalFilename() : context.getFilename());
            var scopeBody = getScopeBody(context.getScope());
            log('got scope:', scopeBody);

            requireCalls.forEach(function (node, index) {
              var nodePosition = findNodeIndexInScopeBody(scopeBody, node);
              log('node position in scope:', nodePosition);

              var statementWithRequireCall = scopeBody[nodePosition];
              var nextStatement = scopeBody[nodePosition + 1];
              var nextRequireCall = requireCalls[index + 1];

              if (nextRequireCall && containsNodeOrEqual(statementWithRequireCall, nextRequireCall)) {
                return;
              }

              if (
              nextStatement && (
              !nextRequireCall ||
              !containsNodeOrEqual(nextStatement, nextRequireCall)))

              {
                var nextComment = void 0;
                if (typeof statementWithRequireCall.parent.comments !== 'undefined' && options.considerComments) {
                  var endLine = node.loc.end.line;
                  nextComment = statementWithRequireCall.parent.comments.find(function (o) {return o.loc.start.line >= endLine && o.loc.start.line <= endLine + options.count + 1;});
                }

                if (nextComment && typeof nextComment !== 'undefined') {

                  commentAfterImport(statementWithRequireCall, nextComment, 'require');
                } else {
                  checkForNewLine(statementWithRequireCall, nextStatement, 'require');
                }
              }
            });
          }return ProgramExit;}(),
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

    }return create;}() };
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIi4uLy4uL3NyYy9ydWxlcy9uZXdsaW5lLWFmdGVyLWltcG9ydC5qcyJdLCJuYW1lcyI6WyJsb2ciLCJjb250YWluc05vZGVPckVxdWFsIiwib3V0ZXJOb2RlIiwiaW5uZXJOb2RlIiwicmFuZ2UiLCJnZXRTY29wZUJvZHkiLCJzY29wZSIsImJsb2NrIiwidHlwZSIsImJvZHkiLCJmaW5kTm9kZUluZGV4SW5TY29wZUJvZHkiLCJub2RlVG9GaW5kIiwiZmluZEluZGV4Iiwibm9kZSIsImdldExpbmVEaWZmZXJlbmNlIiwibmV4dE5vZGUiLCJsb2MiLCJzdGFydCIsImxpbmUiLCJlbmQiLCJpc0NsYXNzV2l0aERlY29yYXRvciIsImRlY29yYXRvcnMiLCJsZW5ndGgiLCJpc0V4cG9ydERlZmF1bHRDbGFzcyIsImRlY2xhcmF0aW9uIiwiaXNFeHBvcnROYW1lQ2xhc3MiLCJtb2R1bGUiLCJleHBvcnRzIiwibWV0YSIsImRvY3MiLCJjYXRlZ29yeSIsImRlc2NyaXB0aW9uIiwidXJsIiwiZml4YWJsZSIsInNjaGVtYSIsInByb3BlcnRpZXMiLCJjb3VudCIsIm1pbmltdW0iLCJleGFjdENvdW50IiwiY29uc2lkZXJDb21tZW50cyIsImFkZGl0aW9uYWxQcm9wZXJ0aWVzIiwiY3JlYXRlIiwiY29udGV4dCIsImxldmVsIiwicmVxdWlyZUNhbGxzIiwib3B0aW9ucyIsImNoZWNrRm9yTmV3TGluZSIsImNsYXNzTm9kZSIsImxpbmVEaWZmZXJlbmNlIiwiRVhQRUNURURfTElORV9ESUZGRVJFTkNFIiwiY29sdW1uIiwicmVwb3J0IiwibWVzc2FnZSIsImZpeCIsInVuZGVmaW5lZCIsImZpeGVyIiwiaW5zZXJ0VGV4dEFmdGVyIiwicmVwZWF0IiwiY29tbWVudEFmdGVySW1wb3J0IiwibmV4dENvbW1lbnQiLCJpbmNyZW1lbnRMZXZlbCIsImRlY3JlbWVudExldmVsIiwiY2hlY2tJbXBvcnQiLCJwYXJlbnQiLCJub2RlUG9zaXRpb24iLCJpbmRleE9mIiwiZW5kTGluZSIsImNvbW1lbnRzIiwiZmluZCIsIm8iLCJpc0V4cG9ydCIsIkltcG9ydERlY2xhcmF0aW9uIiwiVFNJbXBvcnRFcXVhbHNEZWNsYXJhdGlvbiIsIkNhbGxFeHByZXNzaW9uIiwicHVzaCIsImdldFBoeXNpY2FsRmlsZW5hbWUiLCJnZXRGaWxlbmFtZSIsInNjb3BlQm9keSIsImdldFNjb3BlIiwiZm9yRWFjaCIsImluZGV4Iiwic3RhdGVtZW50V2l0aFJlcXVpcmVDYWxsIiwibmV4dFN0YXRlbWVudCIsIm5leHRSZXF1aXJlQ2FsbCIsIkZ1bmN0aW9uRGVjbGFyYXRpb24iLCJGdW5jdGlvbkV4cHJlc3Npb24iLCJBcnJvd0Z1bmN0aW9uRXhwcmVzc2lvbiIsIkJsb2NrU3RhdGVtZW50IiwiT2JqZWN0RXhwcmVzc2lvbiIsIkRlY29yYXRvciJdLCJtYXBwaW5ncyI6Ijs7Ozs7QUFLQSxzRDtBQUNBLHFDOztBQUVBLDhCO0FBQ0EsSUFBTUEsTUFBTSx3QkFBTSxpREFBTixDQUFaOztBQUVBO0FBQ0E7QUFDQTtBQWJBOzs7R0FlQSxTQUFTQyxtQkFBVCxDQUE2QkMsU0FBN0IsRUFBd0NDLFNBQXhDLEVBQW1ELENBQ2pELE9BQU9ELFVBQVVFLEtBQVYsQ0FBZ0IsQ0FBaEIsS0FBc0JELFVBQVVDLEtBQVYsQ0FBZ0IsQ0FBaEIsQ0FBdEIsSUFBNENGLFVBQVVFLEtBQVYsQ0FBZ0IsQ0FBaEIsS0FBc0JELFVBQVVDLEtBQVYsQ0FBZ0IsQ0FBaEIsQ0FBekUsQ0FDRDs7QUFFRCxTQUFTQyxZQUFULENBQXNCQyxLQUF0QixFQUE2QjtBQUMzQixNQUFJQSxNQUFNQyxLQUFOLENBQVlDLElBQVosS0FBcUIsaUJBQXpCLEVBQTRDO0FBQzFDUixRQUFJLHNDQUFKO0FBQ0EsV0FBTyxJQUFQO0FBQ0QsR0FKMEI7O0FBTW5CUyxNQU5tQixHQU1WSCxNQUFNQyxLQU5JLENBTW5CRSxJQU5tQjtBQU8zQixNQUFJQSxRQUFRQSxLQUFLRCxJQUFMLEtBQWMsZ0JBQTFCLEVBQTRDO0FBQzFDLFdBQU9DLEtBQUtBLElBQVo7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QUFDTGIsa0NBQWdCbUMsd0JBQWhCLEVBQTBDQyxhQUExQyxFQUF5RCxTQUF6RDtBQUNEO0FBQ0Y7QUFDRixhQS9CRDtBQWdDRCxXQTdDSTtBQThDTEUsNkJBQXFCeEIsY0E5Q2hCO0FBK0NMeUIsNEJBQW9CekIsY0EvQ2Y7QUFnREwwQixpQ0FBeUIxQixjQWhEcEI7QUFpREwyQix3QkFBZ0IzQixjQWpEWDtBQWtETDRCLDBCQUFrQjVCLGNBbERiO0FBbURMNkIsbUJBQVc3QixjQW5ETjtBQW9ETCxvQ0FBNEJDLGNBcER2QjtBQXFETCxtQ0FBMkJBLGNBckR0QjtBQXNETCx3Q0FBZ0NBLGNBdEQzQjtBQXVETCwrQkFBdUJBLGNBdkRsQjtBQXdETCxpQ0FBeUJBLGNBeERwQjtBQXlETCwwQkFBa0JBLGNBekRiLEVBQVA7O0FBMkRELEtBL0xjLG1CQUFqQiIsImZpbGUiOiJuZXdsaW5lLWFmdGVyLWltcG9ydC5qcyIsInNvdXJjZXNDb250ZW50IjpbIi8qKlxuICogQGZpbGVvdmVydmlldyBSdWxlIHRvIGVuZm9yY2UgbmV3IGxpbmUgYWZ0ZXIgaW1wb3J0IG5vdCBmb2xsb3dlZCBieSBhbm90aGVyIGltcG9ydC5cbiAqIEBhdXRob3IgUmFkZWsgQmVua2VsXG4gKi9cblxuaW1wb3J0IGlzU3RhdGljUmVxdWlyZSBmcm9tICcuLi9jb3JlL3N0YXRpY1JlcXVpcmUnO1xuaW1wb3J0IGRvY3NVcmwgZnJvbSAnLi4vZG9jc1VybCc7XG5cbmltcG9ydCBkZWJ1ZyBmcm9tICdkZWJ1Zyc7XG5jb25zdCBsb2cgPSBkZWJ1ZygnZXNsaW50LXBsdWdpbi1pbXBvcnQ6cnVsZXM6bmV3bGluZS1hZnRlci1pbXBvcnQnKTtcblxuLy8tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS1cbi8vIFJ1bGUgRGVmaW5pdGlvblxuLy8tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS1cblxuZnVuY3Rpb24gY29udGFpbnNOb2RlT3JFcXVhbChvdXRlck5vZGUsIGlubmVyTm9kZSkge1xuICByZXR1cm4gb3V0ZXJOb2RlLnJhbmdlWzBdIDw9IGlubmVyTm9kZS5yYW5nZVswXSAmJiBvdXRlck5vZGUucmFuZ2VbMV0gPj0gaW5uZXJOb2RlLnJhbmdlWzFdO1xufVxuXG5mdW5jdGlvbiBnZXRTY29wZUJvZHkoc2NvcGUpIHtcbiAgaWYgKHNjb3BlLmJsb2NrLnR5cGUgPT09ICdTd2l0Y2hTdGF0ZW1lbnQnKSB7XG4gICAgbG9nKCdTd2l0Y2hTdGF0ZW1lbnQgc2NvcGVzIG5vdCBzdXBwb3J0ZWQnKTtcbiAgICByZXR1cm4gbnVsbDtcbiAgfVxuXG4gIGNvbnN0IHsgYm9keSB9ID0gc2NvcGUuYmxvY2s7XG4gIGlmIChib2R5ICYmIGJvZHkudHlwZSA9PT0gJ0Jsb2NrU3RhdGVtZW50Jykge1xuICAgIHJldHVybiBib2R5LmJvZHk7XG4gIH1cblxuICByZXR1cm4gYm9keTtcbn1cblxuZnVuY3Rpb24gZmluZE5vZGVJbmRleEluU2NvcGVCb2R5KGJvZHksIG5vZGVUb0ZpbmQpIHtcbiAgcmV0dXJuIGJvZHkuZmluZEluZGV4KChub2RlKSA9PiBjb250YWluc05vZGVPckVxdWFsKG5vZGUsIG5vZGVUb0ZpbmQpKTtcbn1cblxuZnVuY3Rpb24gZ2V0TGluZURpZmZlcmVuY2Uobm9kZSwgbmV4dE5vZGUpIHtcbiAgcmV0dXJuIG5leHROb2RlLmxvYy5zdGFydC5saW5lIC0gbm9kZS5sb2MuZW5kLmxpbmU7XG59XG5cbmZ1bmN0aW9uIGlzQ2xhc3NXaXRoRGVjb3JhdG9yKG5vZGUpIHtcbiAgcmV0dXJuIG5vZGUudHlwZSA9PT0gJ0NsYXNzRGVjbGFyYXRpb24nICYmIG5vZGUuZGVjb3JhdG9ycyAmJiBub2RlLmRlY29yYXRvcnMubGVuZ3RoO1xufVxuXG5mdW5jdGlvbiBpc0V4cG9ydERlZmF1bHRDbGFzcyhub2RlKSB7XG4gIHJldHVybiBub2RlLnR5cGUgPT09ICdFeHBvcnREZWZhdWx0RGVjbGFyYXRpb24nICYmIG5vZGUuZGVjbGFyYXRpb24udHlwZSA9PT0gJ0NsYXNzRGVjbGFyYXRpb24nO1xufVxuXG5mdW5jdGlvbiBpc0V4cG9ydE5hbWVDbGFzcyhub2RlKSB7XG5cbiAgcmV0dXJuIG5vZGUudHlwZSA9PT0gJ0V4cG9ydE5hbWVkRGVjbGFyYXRpb24nICYmIG5vZGUuZGVjbGFyYXRpb24gJiYgbm9kZS5kZWNsYXJhdGlvbi50eXBlID09PSAnQ2xhc3NEZWNsYXJhdGlvbic7XG59XG5cbm1vZHVsZS5leHBvcnRzID0ge1xuICBtZXRhOiB7XG4gICAgdHlwZTogJ2xheW91dCcsXG4gICAgZG9jczoge1xuICAgICAgY2F0ZWdvcnk6ICdTdHlsZSBndWlkZScsXG4gICAgICBkZXNjcmlwdGlvbjogJ0VuZm9yY2UgYSBuZXdsaW5lIGFmdGVyIGltcG9ydCBzdGF0ZW1lbnRzLicsXG4gICAgICB1cmw6IGRvY3NVcmwoJ25ld2xpbmUtYWZ0ZXItaW1wb3J0JyksXG4gICAgfSxcbiAgICBmaXhhYmxlOiAnd2hpdGVzcGFjZScsXG4gICAgc2NoZW1hOiBbXG4gICAgICB7XG4gICAgICAgIHR5cGU6ICdvYmplY3QnLFxuICAgICAgICBwcm9wZXJ0aWVzOiB7XG4gICAgICAgICAgY291bnQ6IHtcbiAgICAgICAgICAgIHR5cGU6ICdpbnRlZ2VyJyxcbiAgICAgICAgICAgIG1pbmltdW06IDEsXG4gICAgICAgICAgfSxcbiAgICAgICAgICBleGFjdENvdW50OiB7IHR5cGU6ICdib29sZWFuJyB9LFxuICAgICAgICAgIGNvbnNpZGVyQ29tbWVudHM6IHsgdHlwZTogJ2Jvb2xlYW4nIH0sXG4gICAgICAgIH0sXG4gICAgICAgIGFkZGl0aW9uYWxQcm9wZXJ0aWVzOiBmYWxzZSxcbiAgICAgIH0sXG4gICAgXSxcbiAgfSxcbiAgY3JlYXRlKGNvbnRleHQpIHtcbiAgICBsZXQgbGV2ZWwgPSAwO1xuICAgIGNvbnN0IHJlcXVpcmVDYWxscyA9IFtdO1xuICAgIGNvbnN0IG9wdGlvbnMgPSB7XG4gICAgICBjb3VudDogMSxcbiAgICAgIGV4YWN0Q291bnQ6IGZhbHNlLFxuICAgICAgY29uc2lkZXJDb21tZW50czogZmFsc2UsXG4gICAgICAuLi5jb250ZXh0Lm9wdGlvbnNbMF0sXG4gICAgfTtcblxuICAgIGZ1bmN0aW9uIGNoZWNrRm9yTmV3TGluZShub2RlLCBuZXh0Tm9kZSwgdHlwZSkge1xuICAgICAgaWYgKGlzRXhwb3J0RGVmYXVsdENsYXNzKG5leHROb2RlKSB8fCBpc0V4cG9ydE5hbWVDbGFzcyhuZXh0Tm9kZSkpIHtcbiAgICAgICAgY29uc3QgY2xhc3NOb2RlID0gbmV4dE5vZGUuZGVjbGFyYXRpb247XG5cbiAgICAgICAgaWYgKGlzQ2xhc3NXaXRoRGVjb3JhdG9yKGNsYXNzTm9kZSkpIHtcbiAgICAgICAgICBuZXh0Tm9kZSA9IGNsYXNzTm9kZS5kZWNvcmF0b3JzWzBdO1xuICAgICAgICB9XG4gICAgICB9IGVsc2UgaWYgKGlzQ2xhc3NXaXRoRGVjb3JhdG9yKG5leHROb2RlKSkge1xuICAgICAgICBuZXh0Tm9kZSA9IG5leHROb2RlLmRlY29yYXRvcnNbMF07XG4gICAgICB9XG5cbiAgICAgIGNvbnN0IGxpbmVEaWZmZXJlbmNlID0gZ2V0TGluZURpZmZlcmVuY2Uobm9kZSwgbmV4dE5vZGUpO1xuICAgICAgY29uc3QgRVhQRUNURURfTElORV9ESUZGRVJFTkNFID0gb3B0aW9ucy5jb3VudCArIDE7XG5cbiAgICAgIGlmIChcbiAgICAgICAgbGluZURpZmZlcmVuY2UgPCBFWFBFQ1RFRF9MSU5FX0RJRkZFUkVOQ0VcbiAgICAgICAgfHwgb3B0aW9ucy5leGFjdENvdW50ICYmIGxpbmVEaWZmZXJlbmNlICE9PSBFWFBFQ1RFRF9MSU5FX0RJRkZFUkVOQ0VcbiAgICAgICkge1xuICAgICAgICBsZXQgY29sdW1uID0gbm9kZS5sb2Muc3RhcnQuY29sdW1uO1xuXG4gICAgICAgIGlmIChub2RlLmxvYy5zdGFydC5saW5lICE9PSBub2RlLmxvYy5lbmQubGluZSkge1xuICAgICAgICAgIGNvbHVtbiA9IDA7XG4gICAgICAgIH1cblxuICAgICAgICBjb250ZXh0LnJlcG9ydCh7XG4gICAgICAgICAgbG9jOiB7XG4gICAgICAgICAgICBsaW5lOiBub2RlLmxvYy5lbmQubGluZSxcbiAgICAgICAgICAgIGNvbHVtbixcbiAgICAgICAgICB9LFxuICAgICAgICAgIG1lc3NhZ2U6IGBFeHBlY3RlZCAke29wdGlvbnMuY291bnR9IGVtcHR5IGxpbmUke29wdGlvbnMuY291bnQgPiAxID8gJ3MnIDogJyd9IGFmdGVyICR7dHlwZX0gc3RhdGVtZW50IG5vdCBmb2xsb3dlZCBieSBhbm90aGVyICR7dHlwZX0uYCxcbiAgICAgICAgICBmaXg6IG9wdGlvbnMuZXhhY3RDb3VudCAmJiBFWFBFQ1RFRF9MSU5FX0RJRkZFUkVOQ0UgPCBsaW5lRGlmZmVyZW5jZSA/IHVuZGVmaW5lZCA6IChmaXhlcikgPT4gZml4ZXIuaW5zZXJ0VGV4dEFmdGVyKFxuICAgICAgICAgICAgbm9kZSxcbiAgICAgICAgICAgICdcXG4nLnJlcGVhdChFWFBFQ1RFRF9MSU5FX0RJRkZFUkVOQ0UgLSBsaW5lRGlmZmVyZW5jZSksXG4gICAgICAgICAgKSxcbiAgICAgICAgfSk7XG4gICAgICB9XG4gICAgfVxuXG4gICAgZnVuY3Rpb24gY29tbWVudEFmdGVySW1wb3J0KG5vZGUsIG5leHRDb21tZW50LCB0eXBlKSB7XG4gICAgICBjb25zdCBsaW5lRGlmZmVyZW5jZSA9IGdldExpbmVEaWZmZXJlbmNlKG5vZGUsIG5leHRDb21tZW50KTtcbiAgICAgIGNvbnN0IEVYUEVDVEVEX0xJTkVfRElGRkVSRU5DRSA9IG9wdGlvbnMuY291bnQgKyAxO1xuXG4gICAgICBpZiAobGluZURpZmZlcmVuY2UgPCBFWFBFQ1RFRF9MSU5FX0RJRkZFUkVOQ0UpIHtcbiAgICAgICAgbGV0IGNvbHVtbiA9IG5vZGUubG9jLnN0YXJ0LmNvbHVtbjtcblxuICAgICAgICBpZiAobm9kZS5sb2Muc3RhcnQubGluZSAhPT0gbm9kZS5sb2MuZW5kLmxpbmUpIHtcbiAgICAgICAgICBjb2x1bW4gPSAwO1xuICAgICAgICB9XG5cbiAgICAgICAgY29udGV4dC5yZXBvcnQoe1xuICAgICAgICAgIGxvYzoge1xuICAgICAgICAgICAgbGluZTogbm9kZS5sb2MuZW5kLmxpbmUsXG4gICAgICAgICAgICBjb2x1bW4sXG4gICAgICAgICAgfSxcbiAgICAgICAgICBtZXNzYWdlOiBgRXhwZWN0ZWQgJHtvcHRpb25zLmNvdW50fSBlbXB0eSBsaW5lJHtvcHRpb25zLmNvdW50ID4gMSA/ICdzJyA6ICcnfSBhZnRlciAke3R5cGV9IHN0YXRlbWVudCBub3QgZm9sbG93ZWQgYnkgYW5vdGhlciAke3R5cGV9LmAsXG4gICAgICAgICAgZml4OiBvcHRpb25zLmV4YWN0Q291bnQgJiYgRVhQRUNURURfTElORV9ESUZGRVJFTkNFIDwgbGluZURpZmZlcmVuY2UgPyB1bmRlZmluZWQgOiAoZml4ZXIpID0+IGZpeGVyLmluc2VydFRleHRBZnRlcihcbiAgICAgICAgICAgIG5vZGUsXG4gICAgICAgICAgICAnXFxuJy5yZXBlYXQoRVhQRUNURURfTElORV9ESUZGRVJFTkNFIC0gbGluZURpZmZlcmVuY2UpLFxuICAgICAgICAgICksXG4gICAgICAgIH0pO1xuICAgICAgfVxuICAgIH1cblxuICAgIGZ1bmN0aW9uIGluY3JlbWVudExldmVsKCkge1xuICAgICAgbGV2ZWwrKztcbiAgICB9XG4gICAgZnVuY3Rpb24gZGVjcmVtZW50TGV2ZWwoKSB7XG4gICAgICBsZXZlbC0tO1xuICAgIH1cblxuICAgIGZ1bmN0aW9uIGNoZWNrSW1wb3J0KG5vZGUpIHtcbiAgICAgIGNvbnN0IHsgcGFyZW50IH0gPSBub2RlO1xuXG4gICAgICBpZiAoIXBhcmVudCB8fCAhcGFyZW50LmJvZHkpIHtcbiAgICAgICAgcmV0dXJuO1xuICAgICAgfVxuXG4gICAgICBjb25zdCBub2RlUG9zaXRpb24gPSBwYXJlbnQuYm9keS5pbmRleE9mKG5vZGUpO1xuICAgICAgY29uc3QgbmV4dE5vZGUgPSBwYXJlbnQuYm9keVtub2RlUG9zaXRpb24gKyAxXTtcbiAgICAgIGNvbnN0IGVuZExpbmUgPSBub2RlLmxvYy5lbmQubGluZTtcbiAgICAgIGxldCBuZXh0Q29tbWVudDtcblxuICAgICAgaWYgKHR5cGVvZiBwYXJlbnQuY29tbWVudHMgIT09ICd1bmRlZmluZWQnICYmIG9wdGlvbnMuY29uc2lkZXJDb21tZW50cykge1xuICAgICAgICBuZXh0Q29tbWVudCA9IHBhcmVudC5jb21tZW50cy5maW5kKChvKSA9PiBvLmxvYy5zdGFydC5saW5lID49IGVuZExpbmUgJiYgby5sb2Muc3RhcnQubGluZSA8PSBlbmRMaW5lICsgb3B0aW9ucy5jb3VudCArIDEpO1xuICAgICAgfVxuXG4gICAgICAvLyBza2lwIFwiZXhwb3J0IGltcG9ydFwic1xuICAgICAgaWYgKG5vZGUudHlwZSA9PT0gJ1RTSW1wb3J0RXF1YWxzRGVjbGFyYXRpb24nICYmIG5vZGUuaXNFeHBvcnQpIHtcbiAgICAgICAgcmV0dXJuO1xuICAgICAgfVxuXG4gICAgICBpZiAobmV4dENvbW1lbnQgJiYgdHlwZW9mIG5leHRDb21tZW50ICE9PSAndW5kZWZpbmVkJykge1xuICAgICAgICBjb21tZW50QWZ0ZXJJbXBvcnQobm9kZSwgbmV4dENvbW1lbnQsICdpbXBvcnQnKTtcbiAgICAgIH0gZWxzZSBpZiAobmV4dE5vZGUgJiYgbmV4dE5vZGUudHlwZSAhPT0gJ0ltcG9ydERlY2xhcmF0aW9uJyAmJiAobmV4dE5vZGUudHlwZSAhPT0gJ1RTSW1wb3J0RXF1YWxzRGVjbGFyYXRpb24nIHx8IG5leHROb2RlLmlzRXhwb3J0KSkge1xuICAgICAgICBjaGVja0Zvck5ld0xpbmUobm9kZSwgbmV4dE5vZGUsICdpbXBvcnQnKTtcbiAgICAgIH1cbiAgICB9XG5cbiAgICByZXR1cm4ge1xuICAgICAgSW1wb3J0RGVjbGFyYXRpb246IGNoZWNrSW1wb3J0LFxuICAgICAgVFNJbXBvcnRFcXVhbHNEZWNsYXJhdGlvbjogY2hlY2tJbXBvcnQsXG4gICAgICBDYWxsRXhwcmVzc2lvbihub2RlKSB7XG4gICAgICAgIGlmIChpc1N0YXRpY1JlcXVpcmUobm9kZSkgJiYgbGV2ZWwgPT09IDApIHtcbiAgICAgICAgICByZXF1aXJlQ2FsbHMucHVzaChub2RlKTtcbiAgICAgICAgfVxuICAgICAgfSxcbiAgICAgICdQcm9ncmFtOmV4aXQnKCkge1xuICAgICAgICBsb2coJ2V4aXQgcHJvY2Vzc2luZyBmb3InLCBjb250ZXh0LmdldFBoeXNpY2FsRmlsZW5hbWUgPyBjb250ZXh0LmdldFBoeXNpY2FsRmlsZW5hbWUoKSA6IGNvbnRleHQuZ2V0RmlsZW5hbWUoKSk7XG4gICAgICAgIGNvbnN0IHNjb3BlQm9keSA9IGdldFNjb3BlQm9keShjb250ZXh0LmdldFNjb3BlKCkpO1xuICAgICAgICBsb2coJ2dvdCBzY29wZTonLCBzY29wZUJvZHkpO1xuXG4gICAgICAgIHJlcXVpcmVDYWxscy5mb3JFYWNoKChub2RlLCBpbmRleCkgPT4ge1xuICAgICAgICAgIGNvbnN0IG5vZGVQb3NpdGlvbiA9IGZpbmROb2RlSW5kZXhJblNjb3BlQm9keShzY29wZUJvZHksIG5vZGUpO1xuICAgICAgICAgIGxvZygnbm9kZSBwb3NpdGlvbiBpbiBzY29wZTonLCBub2RlUG9zaXRpb24pO1xuXG4gICAgICAgICAgY29uc3Qgc3RhdGVtZW50V2l0aFJlcXVpcmVDYWxsID0gc2NvcGVCb2R5W25vZGVQb3NpdGlvbl07XG4gICAgICAgICAgY29uc3QgbmV4dFN0YXRlbWVudCA9IHNjb3BlQm9keVtub2RlUG9zaXRpb24gKyAxXTtcbiAgICAgICAgICBjb25zdCBuZXh0UmVxdWlyZUNhbGwgPSByZXF1aXJlQ2FsbHNbaW5kZXggKyAxXTtcblxuICAgICAgICAgIGlmIChuZXh0UmVxdWlyZUNhbGwgJiYgY29udGFpbnNOb2RlT3JFcXVhbChzdGF0ZW1lbnRXaXRoUmVxdWlyZUNhbGwsIG5leHRSZXF1aXJlQ2FsbCkpIHtcbiAgICAgICAgICAgIHJldHVybjtcbiAgICAgICAgICB9XG5cbiAgICAgICAgICBpZiAoXG4gICAgICAgICAgICBuZXh0U3RhdGVtZW50ICYmIChcbiAgICAgICAgICAgICAgIW5leHRSZXF1aXJlQ2FsbFxuICAgICAgICAgICAgICB8fCAhY29udGFpbnNOb2RlT3JFcXVhbChuZXh0U3RhdGVtZW50LCBuZXh0UmVxdWlyZUNhbGwpXG4gICAgICAgICAgICApXG4gICAgICAgICAgKSB7XG4gICAgICAgICAgICBsZXQgbmV4dENvbW1lbnQ7XG4gICAgICAgICAgICBpZiAodHlwZW9mIHN0YXRlbWVudFdpdGhSZXF1aXJlQ2FsbC5wYXJlbnQuY29tbWVudHMgIT09ICd1bmRlZmluZWQnICYmIG9wdGlvbnMuY29uc2lkZXJDb21tZW50cykge1xuICAgICAgICAgICAgICBjb25zdCBlbmRMaW5lID0gbm9kZS5sb2MuZW5kLmxpbmU7XG4gICAgICAgICAgICAgIG5leHRDb21tZW50ID0gc3RhdGVtZW50V2l0aFJlcXVpcmVDYWxsLnBhcmVudC5jb21tZW50cy5maW5kKChvKSA9PiBvLmxvYy5zdGFydC5saW5lID49IGVuZExpbmUgJiYgby5sb2Muc3RhcnQubGluZSA8PSBlbmRMaW5lICsgb3B0aW9ucy5jb3VudCArIDEpO1xuICAgICAgICAgICAgfVxuXG4gICAgICAgICAgICBpZiAobmV4dENvbW1lbnQgJiYgdHlwZW9mIG5leHRDb21tZW50ICE9PSAndW5kZWZpbmVkJykge1xuXG4gICAgICAgICAgICAgIGNvbW1lbnRBZnRlckltcG9ydChzdGF0ZW1lbnRXaXRoUmVxdWlyZUNhbGwsIG5leHRDb21tZW50LCAncmVxdWlyZScpO1xuICAgICAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICAgICAgY2hlY2tGb3JOZXdMaW5lKHN0YXRlbWVudFdpdGhSZXF1aXJlQ2FsbCwgbmV4dFN0YXRlbWVudCwgJ3JlcXVpcmUnKTtcbiAgICAgICAgICAgIH1cbiAgICAgICAgICB9XG4gICAgICAgIH0pO1xuICAgICAgfSxcbiAgICAgIEZ1bmN0aW9uRGVjbGFyYXRpb246IGluY3JlbWVudExldmVsLFxuICAgICAgRnVuY3Rpb25FeHByZXNzaW9uOiBpbmNyZW1lbnRMZXZlbCxcbiAgICAgIEFycm93RnVuY3Rpb25FeHByZXNzaW9uOiBpbmNyZW1lbnRMZXZlbCxcbiAgICAgIEJsb2NrU3RhdGVtZW50OiBpbmNyZW1lbnRMZXZlbCxcbiAgICAgIE9iamVjdEV4cHJlc3Npb246IGluY3JlbWVudExldmVsLFxuICAgICAgRGVjb3JhdG9yOiBpbmNyZW1lbnRMZXZlbCxcbiAgICAgICdGdW5jdGlvbkRlY2xhcmF0aW9uOmV4aXQnOiBkZWNyZW1lbnRMZXZlbCxcbiAgICAgICdGdW5jdGlvbkV4cHJlc3Npb246ZXhpdCc6IGRlY3JlbWVudExldmVsLFxuICAgICAgJ0Fycm93RnVuY3Rpb25FeHByZXNzaW9uOmV4aXQnOiBkZWNyZW1lbnRMZXZlbCxcbiAgICAgICdCbG9ja1N0YXRlbWVudDpleGl0JzogZGVjcmVtZW50TGV2ZWwsXG4gICAgICAnT2JqZWN0RXhwcmVzc2lvbjpleGl0JzogZGVjcmVtZW50TGV2ZWwsXG4gICAgICAnRGVjb3JhdG9yOmV4aXQnOiBkZWNyZW1lbnRMZXZlbCxcbiAgICB9O1xuICB9LFxufTtcbiJdfQ==