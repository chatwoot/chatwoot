'use strict';var _slicedToArray = function () {function sliceIterator(arr, i) {var _arr = [];var _n = true;var _d = false;var _e = undefined;try {for (var _i = arr[Symbol.iterator](), _s; !(_n = (_s = _i.next()).done); _n = true) {_arr.push(_s.value);if (i && _arr.length === i) break;}} catch (err) {_d = true;_e = err;} finally {try {if (!_n && _i["return"]) _i["return"]();} finally {if (_d) throw _e;}}return _arr;}return function (arr, i) {if (Array.isArray(arr)) {return arr;} else if (Symbol.iterator in Object(arr)) {return sliceIterator(arr, i);} else {throw new TypeError("Invalid attempt to destructure non-iterable instance");}};}();

var _minimatch = require('minimatch');var _minimatch2 = _interopRequireDefault(_minimatch);
var _importType = require('../core/importType');var _importType2 = _interopRequireDefault(_importType);
var _staticRequire = require('../core/staticRequire');var _staticRequire2 = _interopRequireDefault(_staticRequire);
var _docsUrl = require('../docsUrl');var _docsUrl2 = _interopRequireDefault(_docsUrl);function _interopRequireDefault(obj) {return obj && obj.__esModule ? obj : { default: obj };}

const defaultGroups = ['builtin', 'external', 'parent', 'sibling', 'index'];

// REPORTING AND FIXING

function reverse(array) {
  return array.map(function (v) {
    return Object.assign({}, v, { rank: -v.rank });
  }).reverse();
}

function getTokensOrCommentsAfter(sourceCode, node, count) {
  let currentNodeOrToken = node;
  const result = [];
  for (let i = 0; i < count; i++) {
    currentNodeOrToken = sourceCode.getTokenOrCommentAfter(currentNodeOrToken);
    if (currentNodeOrToken == null) {
      break;
    }
    result.push(currentNodeOrToken);
  }
  return result;
}

function getTokensOrCommentsBefore(sourceCode, node, count) {
  let currentNodeOrToken = node;
  const result = [];
  for (let i = 0; i < count; i++) {
    currentNodeOrToken = sourceCode.getTokenOrCommentBefore(currentNodeOrToken);
    if (currentNodeOrToken == null) {
      break;
    }
    result.push(currentNodeOrToken);
  }
  return result.reverse();
}

function takeTokensAfterWhile(sourceCode, node, condition) {
  const tokens = getTokensOrCommentsAfter(sourceCode, node, 100);
  const result = [];
  for (let i = 0; i < tokens.length; i++) {
    if (condition(tokens[i])) {
      result.push(tokens[i]);
    } else
    {
      break;
    }
  }
  return result;
}

function takeTokensBeforeWhile(sourceCode, node, condition) {
  const tokens = getTokensOrCommentsBefore(sourceCode, node, 100);
  const result = [];
  for (let i = tokens.length - 1; i >= 0; i--) {
    if (condition(tokens[i])) {
      result.push(tokens[i]);
    } else
    {
      break;
    }
  }
  return result.reverse();
}

function findOutOfOrder(imported) {
  if (imported.length === 0) {
    return [];
  }
  let maxSeenRankNode = imported[0];
  return imported.filter(function (importedModule) {
    const res = importedModule.rank < maxSeenRankNode.rank;
    if (maxSeenRankNode.rank < importedModule.rank) {
      maxSeenRankNode = importedModule;
    }
    return res;
  });
}

function findRootNode(node) {
  let parent = node;
  while (parent.parent != null && parent.parent.body == null) {
    parent = parent.parent;
  }
  return parent;
}

function findEndOfLineWithComments(sourceCode, node) {
  const tokensToEndOfLine = takeTokensAfterWhile(sourceCode, node, commentOnSameLineAs(node));
  let endOfTokens = tokensToEndOfLine.length > 0 ?
  tokensToEndOfLine[tokensToEndOfLine.length - 1].range[1] :
  node.range[1];
  let result = endOfTokens;
  for (let i = endOfTokens; i < sourceCode.text.length; i++) {
    if (sourceCode.text[i] === '\n') {
      result = i + 1;
      break;
    }
    if (sourceCode.text[i] !== ' ' && sourceCode.text[i] !== '\t' && sourceCode.text[i] !== '\r') {
      break;
    }
    result = i + 1;
  }
  return result;
}

function commentOnSameLineAs(node) {
  return token => (token.type === 'Block' || token.type === 'Line') &&
  token.loc.start.line === token.loc.end.line &&
  token.loc.end.line === node.loc.end.line;
}

function findStartOfLineWithComments(sourceCode, node) {
  const tokensToEndOfLine = takeTokensBeforeWhile(sourceCode, node, commentOnSameLineAs(node));
  let startOfTokens = tokensToEndOfLine.length > 0 ? tokensToEndOfLine[0].range[0] : node.range[0];
  let result = startOfTokens;
  for (let i = startOfTokens - 1; i > 0; i--) {
    if (sourceCode.text[i] !== ' ' && sourceCode.text[i] !== '\t') {
      break;
    }
    result = i;
  }
  return result;
}

function isPlainRequireModule(node) {
  if (node.type !== 'VariableDeclaration') {
    return false;
  }
  if (node.declarations.length !== 1) {
    return false;
  }
  const decl = node.declarations[0];
  const result = decl.id && (
  decl.id.type === 'Identifier' || decl.id.type === 'ObjectPattern') &&
  decl.init != null &&
  decl.init.type === 'CallExpression' &&
  decl.init.callee != null &&
  decl.init.callee.name === 'require' &&
  decl.init.arguments != null &&
  decl.init.arguments.length === 1 &&
  decl.init.arguments[0].type === 'Literal';
  return result;
}

function isPlainImportModule(node) {
  return node.type === 'ImportDeclaration' && node.specifiers != null && node.specifiers.length > 0;
}

function isPlainImportEquals(node) {
  return node.type === 'TSImportEqualsDeclaration' && node.moduleReference.expression;
}

function canCrossNodeWhileReorder(node) {
  return isPlainRequireModule(node) || isPlainImportModule(node) || isPlainImportEquals(node);
}

function canReorderItems(firstNode, secondNode) {
  const parent = firstNode.parent;var _sort =
  [
  parent.body.indexOf(firstNode),
  parent.body.indexOf(secondNode)].
  sort(),_sort2 = _slicedToArray(_sort, 2);const firstIndex = _sort2[0],secondIndex = _sort2[1];
  const nodesBetween = parent.body.slice(firstIndex, secondIndex + 1);
  for (var nodeBetween of nodesBetween) {
    if (!canCrossNodeWhileReorder(nodeBetween)) {
      return false;
    }
  }
  return true;
}

function fixOutOfOrder(context, firstNode, secondNode, order) {
  const sourceCode = context.getSourceCode();

  const firstRoot = findRootNode(firstNode.node);
  const firstRootStart = findStartOfLineWithComments(sourceCode, firstRoot);
  const firstRootEnd = findEndOfLineWithComments(sourceCode, firstRoot);

  const secondRoot = findRootNode(secondNode.node);
  const secondRootStart = findStartOfLineWithComments(sourceCode, secondRoot);
  const secondRootEnd = findEndOfLineWithComments(sourceCode, secondRoot);
  const canFix = canReorderItems(firstRoot, secondRoot);

  let newCode = sourceCode.text.substring(secondRootStart, secondRootEnd);
  if (newCode[newCode.length - 1] !== '\n') {
    newCode = newCode + '\n';
  }

  const message = `\`${secondNode.displayName}\` import should occur ${order} import of \`${firstNode.displayName}\``;

  if (order === 'before') {
    context.report({
      node: secondNode.node,
      message: message,
      fix: canFix && (fixer =>
      fixer.replaceTextRange(
      [firstRootStart, secondRootEnd],
      newCode + sourceCode.text.substring(firstRootStart, secondRootStart))) });


  } else if (order === 'after') {
    context.report({
      node: secondNode.node,
      message: message,
      fix: canFix && (fixer =>
      fixer.replaceTextRange(
      [secondRootStart, firstRootEnd],
      sourceCode.text.substring(secondRootEnd, firstRootEnd) + newCode)) });


  }
}

function reportOutOfOrder(context, imported, outOfOrder, order) {
  outOfOrder.forEach(function (imp) {
    const found = imported.find(function hasHigherRank(importedItem) {
      return importedItem.rank > imp.rank;
    });
    fixOutOfOrder(context, found, imp, order);
  });
}

function makeOutOfOrderReport(context, imported) {
  const outOfOrder = findOutOfOrder(imported);
  if (!outOfOrder.length) {
    return;
  }
  // There are things to report. Try to minimize the number of reported errors.
  const reversedImported = reverse(imported);
  const reversedOrder = findOutOfOrder(reversedImported);
  if (reversedOrder.length < outOfOrder.length) {
    reportOutOfOrder(context, reversedImported, reversedOrder, 'after');
    return;
  }
  reportOutOfOrder(context, imported, outOfOrder, 'before');
}

function getSorter(ascending) {
  const multiplier = ascending ? 1 : -1;

  return function importsSorter(importA, importB) {
    let result;

    if (importA < importB) {
      result = -1;
    } else if (importA > importB) {
      result = 1;
    } else {
      result = 0;
    }

    return result * multiplier;
  };
}

function mutateRanksToAlphabetize(imported, alphabetizeOptions) {
  const groupedByRanks = imported.reduce(function (acc, importedItem) {
    if (!Array.isArray(acc[importedItem.rank])) {
      acc[importedItem.rank] = [];
    }
    acc[importedItem.rank].push(importedItem.value);
    return acc;
  }, {});

  const groupRanks = Object.keys(groupedByRanks);

  const sorterFn = getSorter(alphabetizeOptions.order === 'asc');
  const comparator = alphabetizeOptions.caseInsensitive ? (a, b) => sorterFn(String(a).toLowerCase(), String(b).toLowerCase()) : (a, b) => sorterFn(a, b);
  // sort imports locally within their group
  groupRanks.forEach(function (groupRank) {
    groupedByRanks[groupRank].sort(comparator);
  });

  // assign globally unique rank to each import
  let newRank = 0;
  const alphabetizedRanks = groupRanks.sort().reduce(function (acc, groupRank) {
    groupedByRanks[groupRank].forEach(function (importedItemName) {
      acc[importedItemName] = parseInt(groupRank, 10) + newRank;
      newRank += 1;
    });
    return acc;
  }, {});

  // mutate the original group-rank with alphabetized-rank
  imported.forEach(function (importedItem) {
    importedItem.rank = alphabetizedRanks[importedItem.value];
  });
}

// DETECTING

function computePathRank(ranks, pathGroups, path, maxPosition) {
  for (let i = 0, l = pathGroups.length; i < l; i++) {var _pathGroups$i =
    pathGroups[i];const pattern = _pathGroups$i.pattern,patternOptions = _pathGroups$i.patternOptions,group = _pathGroups$i.group;var _pathGroups$i$positio = _pathGroups$i.position;const position = _pathGroups$i$positio === undefined ? 1 : _pathGroups$i$positio;
    if ((0, _minimatch2.default)(path, pattern, patternOptions || { nocomment: true })) {
      return ranks[group] + position / maxPosition;
    }
  }
}

function computeRank(context, ranks, importEntry, excludedImportTypes) {
  let impType;
  let rank;
  if (importEntry.type === 'import:object') {
    impType = 'object';
  } else {
    impType = (0, _importType2.default)(importEntry.value, context);
  }
  if (!excludedImportTypes.has(impType)) {
    rank = computePathRank(ranks.groups, ranks.pathGroups, importEntry.value, ranks.maxPosition);
  }
  if (typeof rank === 'undefined') {
    rank = ranks.groups[impType];
  }
  if (importEntry.type !== 'import' && !importEntry.type.startsWith('import:')) {
    rank += 100;
  }

  return rank;
}

function registerNode(context, importEntry, ranks, imported, excludedImportTypes) {
  const rank = computeRank(context, ranks, importEntry, excludedImportTypes);
  if (rank !== -1) {
    imported.push(Object.assign({}, importEntry, { rank }));
  }
}

function isInVariableDeclarator(node) {
  return node && (
  node.type === 'VariableDeclarator' || isInVariableDeclarator(node.parent));
}

const types = ['builtin', 'external', 'internal', 'unknown', 'parent', 'sibling', 'index', 'object'];

// Creates an object with type-rank pairs.
// Example: { index: 0, sibling: 1, parent: 1, external: 1, builtin: 2, internal: 2 }
// Will throw an error if it contains a type that does not exist, or has a duplicate
function convertGroupsToRanks(groups) {
  const rankObject = groups.reduce(function (res, group, index) {
    if (typeof group === 'string') {
      group = [group];
    }
    group.forEach(function (groupItem) {
      if (types.indexOf(groupItem) === -1) {
        throw new Error('Incorrect configuration of the rule: Unknown type `' +
        JSON.stringify(groupItem) + '`');
      }
      if (res[groupItem] !== undefined) {
        throw new Error('Incorrect configuration of the rule: `' + groupItem + '` is duplicated');
      }
      res[groupItem] = index;
    });
    return res;
  }, {});

  const omittedTypes = types.filter(function (type) {
    return rankObject[type] === undefined;
  });

  return omittedTypes.reduce(function (res, type) {
    res[type] = groups.length;
    return res;
  }, rankObject);
}

function convertPathGroupsForRanks(pathGroups) {
  const after = {};
  const before = {};

  const transformed = pathGroups.map((pathGroup, index) => {const
    group = pathGroup.group,positionString = pathGroup.position;
    let position = 0;
    if (positionString === 'after') {
      if (!after[group]) {
        after[group] = 1;
      }
      position = after[group]++;
    } else if (positionString === 'before') {
      if (!before[group]) {
        before[group] = [];
      }
      before[group].push(index);
    }

    return Object.assign({}, pathGroup, { position });
  });

  let maxPosition = 1;

  Object.keys(before).forEach(group => {
    const groupLength = before[group].length;
    before[group].forEach((groupIndex, index) => {
      transformed[groupIndex].position = -1 * (groupLength - index);
    });
    maxPosition = Math.max(maxPosition, groupLength);
  });

  Object.keys(after).forEach(key => {
    const groupNextPosition = after[key];
    maxPosition = Math.max(maxPosition, groupNextPosition - 1);
  });

  return {
    pathGroups: transformed,
    maxPosition: maxPosition > 10 ? Math.pow(10, Math.ceil(Math.log10(maxPosition))) : 10 };

}

function fixNewLineAfterImport(context, previousImport) {
  const prevRoot = findRootNode(previousImport.node);
  const tokensToEndOfLine = takeTokensAfterWhile(
  context.getSourceCode(), prevRoot, commentOnSameLineAs(prevRoot));

  let endOfLine = prevRoot.range[1];
  if (tokensToEndOfLine.length > 0) {
    endOfLine = tokensToEndOfLine[tokensToEndOfLine.length - 1].range[1];
  }
  return fixer => fixer.insertTextAfterRange([prevRoot.range[0], endOfLine], '\n');
}

function removeNewLineAfterImport(context, currentImport, previousImport) {
  const sourceCode = context.getSourceCode();
  const prevRoot = findRootNode(previousImport.node);
  const currRoot = findRootNode(currentImport.node);
  const rangeToRemove = [
  findEndOfLineWithComments(sourceCode, prevRoot),
  findStartOfLineWithComments(sourceCode, currRoot)];

  if (/^\s*$/.test(sourceCode.text.substring(rangeToRemove[0], rangeToRemove[1]))) {
    return fixer => fixer.removeRange(rangeToRemove);
  }
  return undefined;
}

function makeNewlinesBetweenReport(context, imported, newlinesBetweenImports) {
  const getNumberOfEmptyLinesBetween = (currentImport, previousImport) => {
    const linesBetweenImports = context.getSourceCode().lines.slice(
    previousImport.node.loc.end.line,
    currentImport.node.loc.start.line - 1);


    return linesBetweenImports.filter(line => !line.trim().length).length;
  };
  let previousImport = imported[0];

  imported.slice(1).forEach(function (currentImport) {
    const emptyLinesBetween = getNumberOfEmptyLinesBetween(currentImport, previousImport);

    if (newlinesBetweenImports === 'always' ||
    newlinesBetweenImports === 'always-and-inside-groups') {
      if (currentImport.rank !== previousImport.rank && emptyLinesBetween === 0) {
        context.report({
          node: previousImport.node,
          message: 'There should be at least one empty line between import groups',
          fix: fixNewLineAfterImport(context, previousImport) });

      } else if (currentImport.rank === previousImport.rank &&
      emptyLinesBetween > 0 &&
      newlinesBetweenImports !== 'always-and-inside-groups') {
        context.report({
          node: previousImport.node,
          message: 'There should be no empty line within import group',
          fix: removeNewLineAfterImport(context, currentImport, previousImport) });

      }
    } else if (emptyLinesBetween > 0) {
      context.report({
        node: previousImport.node,
        message: 'There should be no empty line between import groups',
        fix: removeNewLineAfterImport(context, currentImport, previousImport) });

    }

    previousImport = currentImport;
  });
}

function getAlphabetizeConfig(options) {
  const alphabetize = options.alphabetize || {};
  const order = alphabetize.order || 'ignore';
  const caseInsensitive = alphabetize.caseInsensitive || false;

  return { order, caseInsensitive };
}

module.exports = {
  meta: {
    type: 'suggestion',
    docs: {
      url: (0, _docsUrl2.default)('order') },


    fixable: 'code',
    schema: [
    {
      type: 'object',
      properties: {
        groups: {
          type: 'array' },

        pathGroupsExcludedImportTypes: {
          type: 'array' },

        pathGroups: {
          type: 'array',
          items: {
            type: 'object',
            properties: {
              pattern: {
                type: 'string' },

              patternOptions: {
                type: 'object' },

              group: {
                type: 'string',
                enum: types },

              position: {
                type: 'string',
                enum: ['after', 'before'] } },


            required: ['pattern', 'group'] } },


        'newlines-between': {
          enum: [
          'ignore',
          'always',
          'always-and-inside-groups',
          'never'] },


        alphabetize: {
          type: 'object',
          properties: {
            caseInsensitive: {
              type: 'boolean',
              default: false },

            order: {
              enum: ['ignore', 'asc', 'desc'],
              default: 'ignore' } },


          additionalProperties: false } },


      additionalProperties: false }] },




  create: function importOrderRule(context) {
    const options = context.options[0] || {};
    const newlinesBetweenImports = options['newlines-between'] || 'ignore';
    const pathGroupsExcludedImportTypes = new Set(options['pathGroupsExcludedImportTypes'] || ['builtin', 'external', 'object']);
    const alphabetize = getAlphabetizeConfig(options);
    let ranks;

    try {var _convertPathGroupsFor =
      convertPathGroupsForRanks(options.pathGroups || []);const pathGroups = _convertPathGroupsFor.pathGroups,maxPosition = _convertPathGroupsFor.maxPosition;
      ranks = {
        groups: convertGroupsToRanks(options.groups || defaultGroups),
        pathGroups,
        maxPosition };

    } catch (error) {
      // Malformed configuration
      return {
        Program: function (node) {
          context.report(node, error.message);
        } };

    }
    let imported = [];
    let level = 0;

    function incrementLevel() {
      level++;
    }
    function decrementLevel() {
      level--;
    }

    return {
      ImportDeclaration: function handleImports(node) {
        if (node.specifiers.length) {// Ignoring unassigned imports
          const name = node.source.value;
          registerNode(
          context,
          {
            node,
            value: name,
            displayName: name,
            type: 'import' },

          ranks,
          imported,
          pathGroupsExcludedImportTypes);

        }
      },
      TSImportEqualsDeclaration: function handleImports(node) {
        let displayName;
        let value;
        let type;
        // skip "export import"s
        if (node.isExport) {
          return;
        }
        if (node.moduleReference.type === 'TSExternalModuleReference') {
          value = node.moduleReference.expression.value;
          displayName = value;
          type = 'import';
        } else {
          value = '';
          displayName = context.getSourceCode().getText(node.moduleReference);
          type = 'import:object';
        }
        registerNode(
        context,
        {
          node,
          value,
          displayName,
          type },

        ranks,
        imported,
        pathGroupsExcludedImportTypes);

      },
      CallExpression: function handleRequires(node) {
        if (level !== 0 || !(0, _staticRequire2.default)(node) || !isInVariableDeclarator(node.parent)) {
          return;
        }
        const name = node.arguments[0].value;
        registerNode(
        context,
        {
          node,
          value: name,
          displayName: name,
          type: 'require' },

        ranks,
        imported,
        pathGroupsExcludedImportTypes);

      },
      'Program:exit': function reportAndReset() {
        if (newlinesBetweenImports !== 'ignore') {
          makeNewlinesBetweenReport(context, imported, newlinesBetweenImports);
        }

        if (alphabetize.order !== 'ignore') {
          mutateRanksToAlphabetize(imported, alphabetize);
        }

        makeOutOfOrderReport(context, imported);

        imported = [];
      },
      FunctionDeclaration: incrementLevel,
      FunctionExpression: incrementLevel,
      ArrowFunctionExpression: incrementLevel,
      BlockStatement: incrementLevel,
      ObjectExpression: incrementLevel,
      'FunctionDeclaration:exit': decrementLevel,
      'FunctionExpression:exit': decrementLevel,
      'ArrowFunctionExpression:exit': decrementLevel,
      'BlockStatement:exit': decrementLevel,
      'ObjectExpression:exit': decrementLevel };

  } };
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIi4uLy4uL3NyYy9ydWxlcy9vcmRlci5qcyJdLCJuYW1lcyI6WyJkZWZhdWx0R3JvdXBzIiwicmV2ZXJzZSIsImFycmF5IiwibWFwIiwidiIsIk9iamVjdCIsImFzc2lnbiIsInJhbmsiLCJnZXRUb2tlbnNPckNvbW1lbnRzQWZ0ZXIiLCJzb3VyY2VDb2RlIiwibm9kZSIsImNvdW50IiwiY3VycmVudE5vZGVPclRva2VuIiwicmVzdWx0IiwiaSIsImdldFRva2VuT3JDb21tZW50QWZ0ZXIiLCJwdXNoIiwiZ2V0VG9rZW5zT3JDb21tZW50c0JlZm9yZSIsImdldFRva2VuT3JDb21tZW50QmVmb3JlIiwidGFrZVRva2Vuc0FmdGVyV2hpbGUiLCJjb25kaXRpb24iLCJ0b2tlbnMiLCJsZW5ndGgiLCJ0YWtlVG9rZW5zQmVmb3JlV2hpbGUiLCJmaW5kT3V0T2ZPcmRlciIsImltcG9ydGVkIiwibWF4U2VlblJhbmtOb2RlIiwiZmlsdGVyIiwiaW1wb3J0ZWRNb2R1bGUiLCJyZXMiLCJmaW5kUm9vdE5vZGUiLCJwYXJlbnQiLCJib2R5IiwiZmluZEVuZE9mTGluZVdpdGhDb21tZW50cyIsInRva2Vuc1RvRW5kT2ZMaW5lIiwiY29tbWVudE9uU2FtZUxpbmVBcyIsImVuZE9mVG9rZW5zIiwicmFuZ2UiLCJ0ZXh0IiwidG9rZW4iLCJ0eXBlIiwibG9jIiwic3RhcnQiLCJsaW5lIiwiZW5kIiwiZmluZFN0YXJ0T2ZMaW5lV2l0aENvbW1lbnRzIiwic3RhcnRPZlRva2VucyIsImlzUGxhaW5SZXF1aXJlTW9kdWxlIiwiZGVjbGFyYXRpb25zIiwiZGVjbCIsImlkIiwiaW5pdCIsImNhbGxlZSIsIm5hbWUiLCJhcmd1bWVudHMiLCJpc1BsYWluSW1wb3J0TW9kdWxlIiwic3BlY2lmaWVycyIsImlzUGxhaW5JbXBvcnRFcXVhbHMiLCJtb2R1bGVSZWZlcmVuY2UiLCJleHByZXNzaW9uIiwiY2FuQ3Jvc3NOb2RlV2hpbGVSZW9yZGVyIiwiY2FuUmVvcmRlckl0ZW1zIiwiZmlyc3ROb2RlIiwic2Vjb25kTm9kZSIsImluZGV4T2YiLCJzb3J0IiwiZmlyc3RJbmRleCIsInNlY29uZEluZGV4Iiwibm9kZXNCZXR3ZWVuIiwic2xpY2UiLCJub2RlQmV0d2VlbiIsImZpeE91dE9mT3JkZXIiLCJjb250ZXh0Iiwib3JkZXIiLCJnZXRTb3VyY2VDb2RlIiwiZmlyc3RSb290IiwiZmlyc3RSb290U3RhcnQiLCJmaXJzdFJvb3RFbmQiLCJzZWNvbmRSb290Iiwic2Vjb25kUm9vdFN0YXJ0Iiwic2Vjb25kUm9vdEVuZCIsImNhbkZpeCIsIm5ld0NvZGUiLCJzdWJzdHJpbmciLCJtZXNzYWdlIiwiZGlzcGxheU5hbWUiLCJyZXBvcnQiLCJmaXgiLCJmaXhlciIsInJlcGxhY2VUZXh0UmFuZ2UiLCJyZXBvcnRPdXRPZk9yZGVyIiwib3V0T2ZPcmRlciIsImZvckVhY2giLCJpbXAiLCJmb3VuZCIsImZpbmQiLCJoYXNIaWdoZXJSYW5rIiwiaW1wb3J0ZWRJdGVtIiwibWFrZU91dE9mT3JkZXJSZXBvcnQiLCJyZXZlcnNlZEltcG9ydGVkIiwicmV2ZXJzZWRPcmRlciIsImdldFNvcnRlciIsImFzY2VuZGluZyIsIm11bHRpcGxpZXIiLCJpbXBvcnRzU29ydGVyIiwiaW1wb3J0QSIsImltcG9ydEIiLCJtdXRhdGVSYW5rc1RvQWxwaGFiZXRpemUiLCJhbHBoYWJldGl6ZU9wdGlvbnMiLCJncm91cGVkQnlSYW5rcyIsInJlZHVjZSIsImFjYyIsIkFycmF5IiwiaXNBcnJheSIsInZhbHVlIiwiZ3JvdXBSYW5rcyIsImtleXMiLCJzb3J0ZXJGbiIsImNvbXBhcmF0b3IiLCJjYXNlSW5zZW5zaXRpdmUiLCJhIiwiYiIsIlN0cmluZyIsInRvTG93ZXJDYXNlIiwiZ3JvdXBSYW5rIiwibmV3UmFuayIsImFscGhhYmV0aXplZFJhbmtzIiwiaW1wb3J0ZWRJdGVtTmFtZSIsInBhcnNlSW50IiwiY29tcHV0ZVBhdGhSYW5rIiwicmFua3MiLCJwYXRoR3JvdXBzIiwicGF0aCIsIm1heFBvc2l0aW9uIiwibCIsInBhdHRlcm4iLCJwYXR0ZXJuT3B0aW9ucyIsImdyb3VwIiwicG9zaXRpb24iLCJub2NvbW1lbnQiLCJjb21wdXRlUmFuayIsImltcG9ydEVudHJ5IiwiZXhjbHVkZWRJbXBvcnRUeXBlcyIsImltcFR5cGUiLCJoYXMiLCJncm91cHMiLCJzdGFydHNXaXRoIiwicmVnaXN0ZXJOb2RlIiwiaXNJblZhcmlhYmxlRGVjbGFyYXRvciIsInR5cGVzIiwiY29udmVydEdyb3Vwc1RvUmFua3MiLCJyYW5rT2JqZWN0IiwiaW5kZXgiLCJncm91cEl0ZW0iLCJFcnJvciIsIkpTT04iLCJzdHJpbmdpZnkiLCJ1bmRlZmluZWQiLCJvbWl0dGVkVHlwZXMiLCJjb252ZXJ0UGF0aEdyb3Vwc0ZvclJhbmtzIiwiYWZ0ZXIiLCJiZWZvcmUiLCJ0cmFuc2Zvcm1lZCIsInBhdGhHcm91cCIsInBvc2l0aW9uU3RyaW5nIiwiZ3JvdXBMZW5ndGgiLCJncm91cEluZGV4IiwiTWF0aCIsIm1heCIsImtleSIsImdyb3VwTmV4dFBvc2l0aW9uIiwicG93IiwiY2VpbCIsImxvZzEwIiwiZml4TmV3TGluZUFmdGVySW1wb3J0IiwicHJldmlvdXNJbXBvcnQiLCJwcmV2Um9vdCIsImVuZE9mTGluZSIsImluc2VydFRleHRBZnRlclJhbmdlIiwicmVtb3ZlTmV3TGluZUFmdGVySW1wb3J0IiwiY3VycmVudEltcG9ydCIsImN1cnJSb290IiwicmFuZ2VUb1JlbW92ZSIsInRlc3QiLCJyZW1vdmVSYW5nZSIsIm1ha2VOZXdsaW5lc0JldHdlZW5SZXBvcnQiLCJuZXdsaW5lc0JldHdlZW5JbXBvcnRzIiwiZ2V0TnVtYmVyT2ZFbXB0eUxpbmVzQmV0d2VlbiIsImxpbmVzQmV0d2VlbkltcG9ydHMiLCJsaW5lcyIsInRyaW0iLCJlbXB0eUxpbmVzQmV0d2VlbiIsImdldEFscGhhYmV0aXplQ29uZmlnIiwib3B0aW9ucyIsImFscGhhYmV0aXplIiwibW9kdWxlIiwiZXhwb3J0cyIsIm1ldGEiLCJkb2NzIiwidXJsIiwiZml4YWJsZSIsInNjaGVtYSIsInByb3BlcnRpZXMiLCJwYXRoR3JvdXBzRXhjbHVkZWRJbXBvcnRUeXBlcyIsIml0ZW1zIiwiZW51bSIsInJlcXVpcmVkIiwiZGVmYXVsdCIsImFkZGl0aW9uYWxQcm9wZXJ0aWVzIiwiY3JlYXRlIiwiaW1wb3J0T3JkZXJSdWxlIiwiU2V0IiwiZXJyb3IiLCJQcm9ncmFtIiwibGV2ZWwiLCJpbmNyZW1lbnRMZXZlbCIsImRlY3JlbWVudExldmVsIiwiSW1wb3J0RGVjbGFyYXRpb24iLCJoYW5kbGVJbXBvcnRzIiwic291cmNlIiwiVFNJbXBvcnRFcXVhbHNEZWNsYXJhdGlvbiIsImlzRXhwb3J0IiwiZ2V0VGV4dCIsIkNhbGxFeHByZXNzaW9uIiwiaGFuZGxlUmVxdWlyZXMiLCJyZXBvcnRBbmRSZXNldCIsIkZ1bmN0aW9uRGVjbGFyYXRpb24iLCJGdW5jdGlvbkV4cHJlc3Npb24iLCJBcnJvd0Z1bmN0aW9uRXhwcmVzc2lvbiIsIkJsb2NrU3RhdGVtZW50IiwiT2JqZWN0RXhwcmVzc2lvbiJdLCJtYXBwaW5ncyI6IkFBQUEsYTs7QUFFQSxzQztBQUNBLGdEO0FBQ0Esc0Q7QUFDQSxxQzs7QUFFQSxNQUFNQSxnQkFBZ0IsQ0FBQyxTQUFELEVBQVksVUFBWixFQUF3QixRQUF4QixFQUFrQyxTQUFsQyxFQUE2QyxPQUE3QyxDQUF0Qjs7QUFFQTs7QUFFQSxTQUFTQyxPQUFULENBQWlCQyxLQUFqQixFQUF3QjtBQUN0QixTQUFPQSxNQUFNQyxHQUFOLENBQVUsVUFBVUMsQ0FBVixFQUFhO0FBQzVCLFdBQU9DLE9BQU9DLE1BQVAsQ0FBYyxFQUFkLEVBQWtCRixDQUFsQixFQUFxQixFQUFFRyxNQUFNLENBQUNILEVBQUVHLElBQVgsRUFBckIsQ0FBUDtBQUNELEdBRk0sRUFFSk4sT0FGSSxFQUFQO0FBR0Q7O0FBRUQsU0FBU08sd0JBQVQsQ0FBa0NDLFVBQWxDLEVBQThDQyxJQUE5QyxFQUFvREMsS0FBcEQsRUFBMkQ7QUFDekQsTUFBSUMscUJBQXFCRixJQUF6QjtBQUNBLFFBQU1HLFNBQVMsRUFB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c0NvbnRlbnQiOlsiJ3VzZSBzdHJpY3QnXG5cbmltcG9ydCBtaW5pbWF0Y2ggZnJvbSAnbWluaW1hdGNoJ1xuaW1wb3J0IGltcG9ydFR5cGUgZnJvbSAnLi4vY29yZS9pbXBvcnRUeXBlJ1xuaW1wb3J0IGlzU3RhdGljUmVxdWlyZSBmcm9tICcuLi9jb3JlL3N0YXRpY1JlcXVpcmUnXG5pbXBvcnQgZG9jc1VybCBmcm9tICcuLi9kb2NzVXJsJ1xuXG5jb25zdCBkZWZhdWx0R3JvdXBzID0gWydidWlsdGluJywgJ2V4dGVybmFsJywgJ3BhcmVudCcsICdzaWJsaW5nJywgJ2luZGV4J11cblxuLy8gUkVQT1JUSU5HIEFORCBGSVhJTkdcblxuZnVuY3Rpb24gcmV2ZXJzZShhcnJheSkge1xuICByZXR1cm4gYXJyYXkubWFwKGZ1bmN0aW9uICh2KSB7XG4gICAgcmV0dXJuIE9iamVjdC5hc3NpZ24oe30sIHYsIHsgcmFuazogLXYucmFuayB9KVxuICB9KS5yZXZlcnNlKClcbn1cblxuZnVuY3Rpb24gZ2V0VG9rZW5zT3JDb21tZW50c0FmdGVyKHNvdXJjZUNvZGUsIG5vZGUsIGNvdW50KSB7XG4gIGxldCBjdXJyZW50Tm9kZU9yVG9rZW4gPSBub2RlXG4gIGNvbnN0IHJlc3VsdCA9IFtdXG4gIGZvciAobGV0IGkgPSAwOyBpIDwgY291bnQ7IGkrKykge1xuICAgIGN1cnJlbnROb2RlT3JUb2tlbiA9IHNvdXJjZUNvZGUuZ2V0VG9rZW5PckNvbW1lbnRBZnRlcihjdXJyZW50Tm9kZU9yVG9rZW4pXG4gICAgaWYgKGN1cnJlbnROb2RlT3JUb2tlbiA9PSBudWxsKSB7XG4gICAgICBicmVha1xuICAgIH1cbiAgICByZXN1bHQucHVzaChjdXJyZW50Tm9kZU9yVG9rZW4pXG4gIH1cbiAgcmV0dXJuIHJlc3VsdFxufVxuXG5mdW5jdGlvbiBnZXRUb2tlbnNPckNvbW1lbnRzQmVmb3JlKHNvdXJjZUNvZGUsIG5vZGUsIGNvdW50KSB7XG4gIGxldCBjdXJyZW50Tm9kZU9yVG9rZW4gPSBub2RlXG4gIGNvbnN0IHJlc3VsdCA9IFtdXG4gIGZvciAobGV0IGkgPSAwOyBpIDwgY291bnQ7IGkrKykge1xuICAgIGN1cnJlbnROb2RlT3JUb2tlbiA9IHNvdXJjZUNvZGUuZ2V0VG9rZW5PckNvbW1lbnRCZWZvcmUoY3VycmVudE5vZGVPclRva2VuKVxuICAgIGlmIChjdXJyZW50Tm9kZU9yVG9rZW4gPT0gbnVsbCkge1xuICAgICAgYnJlYWtcbiAgICB9XG4gICAgcmVzdWx0LnB1c2goY3VycmVudE5vZGVPclRva2VuKVxuICB9XG4gIHJldHVybiByZXN1bHQucmV2ZXJzZSgpXG59XG5cbmZ1bmN0aW9uIHRha2VUb2tlbnNBZnRlcldoaWxlKHNvdXJjZUNvZGUsIG5vZGUsIGNvbmRpdGlvbikge1xuICBjb25zdCB0b2tlbnMgPSBnZXRUb2tlbnNPckNvbW1lbnRzQWZ0ZXIoc291cmNlQ29kZSwgbm9kZSwgMTAwKVxuICBjb25zdCByZXN1bHQgPSBbXVxuICBmb3IgKGxldCBpID0gMDsgaSA8IHRva2Vucy5sZW5ndGg7IGkrKykge1xuICAgIGlmIChjb25kaXRpb24odG9rZW5zW2ldKSkge1xuICAgICAgcmVzdWx0LnB1c2godG9rZW5zW2ldKVxuICAgIH1cbiAgICBlbHNlIHtcbiAgICAgIGJyZWFrXG4gICAgfVxuICB9XG4gIHJldHVybiByZXN1bHRcbn1cblxuZnVuY3Rpb24gdGFrZVRva2Vuc0JlZm9yZVdoaWxlKHNvdXJjZUNvZGUsIG5vZGUsIGNvbmRpdGlvbikge1xuICBjb25zdCB0b2tlbnMgPSBnZXRUb2tlbnNPckNvbW1lbnRzQmVmb3JlKHNvdXJjZUNvZGUsIG5vZGUsIDEwMClcbiAgY29uc3QgcmVzdWx0ID0gW11cbiAgZm9yIChsZXQgaSA9IHRva2Vucy5sZW5ndGggLSAxOyBpID49IDA7IGktLSkge1xuICAgIGlmIChjb25kaXRpb24odG9rZW5zW2ldKSkge1xuICAgICAgcmVzdWx0LnB1c2godG9rZW5zW2ldKVxuICAgIH1cbiAgICBlbHNlIHtcbiAgICAgIGJyZWFrXG4gICAgfVxuICB9XG4gIHJldHVybiByZXN1bHQucmV2ZXJzZSgpXG59XG5cbmZ1bmN0aW9uIGZpbmRPdXRPZk9yZGVyKGltcG9ydGVkKSB7XG4gIGlmIChpbXBvcnRlZC5sZW5ndGggPT09IDApIHtcbiAgICByZXR1cm4gW11cbiAgfVxuICBsZXQgbWF4U2VlblJhbmtOb2RlID0gaW1wb3J0ZWRbMF1cbiAgcmV0dXJuIGltcG9ydGVkLmZpbHRlcihmdW5jdGlvbiAoaW1wb3J0ZWRNb2R1bGUpIHtcbiAgICBjb25zdCByZXMgPSBpbXBvcnRlZE1vZHVsZS5yYW5rIDwgbWF4U2VlblJhbmtOb2RlLnJhbmtcbiAgICBpZiAobWF4U2VlblJhbmtOb2RlLnJhbmsgPCBpbXBvcnRlZE1vZHVsZS5yYW5rKSB7XG4gICAgICBtYXhTZWVuUmFua05vZGUgPSBpbXBvcnRlZE1vZHVsZVxuICAgIH1cbiAgICByZXR1cm4gcmVzXG4gIH0pXG59XG5cbmZ1bmN0aW9uIGZpbmRSb290Tm9kZShub2RlKSB7XG4gIGxldCBwYXJlbnQgPSBub2RlXG4gIHdoaWxlIChwYXJlbnQucGFyZW50ICE9IG51bGwgJiYgcGFyZW50LnBhcmVudC5ib2R5ID09IG51bGwpIHtcbiAgICBwYXJlbnQgPSBwYXJlbnQucGFyZW50XG4gIH1cbiAgcmV0dXJuIHBhcmVudFxufVxuXG5mdW5jdGlvbiBmaW5kRW5kT2ZMaW5lV2l0aENvbW1lbnRzKHNvdXJjZUNvZGUsIG5vZGUpIHtcbiAgY29uc3QgdG9rZW5zVG9FbmRPZkxpbmUgPSB0YWtlVG9rZW5zQWZ0ZXJXaGlsZShzb3VyY2VDb2RlLCBub2RlLCBjb21tZW50T25TYW1lTGluZUFzKG5vZGUpKVxuICBsZXQgZW5kT2ZUb2tlbnMgPSB0b2tlbnNUb0VuZE9mTGluZS5sZW5ndGggPiAwXG4gICAgPyB0b2tlbnNUb0VuZE9mTGluZVt0b2tlbnNUb0VuZE9mTGluZS5sZW5ndGggLSAxXS5yYW5nZVsxXVxuICAgIDogbm9kZS5yYW5nZVsxXVxuICBsZXQgcmVzdWx0ID0gZW5kT2ZUb2tlbnNcbiAgZm9yIChsZXQgaSA9IGVuZE9mVG9rZW5zOyBpIDwgc291cmNlQ29kZS50ZXh0Lmxlbmd0aDsgaSsrKSB7XG4gICAgaWYgKHNvdXJjZUNvZGUudGV4dFtpXSA9PT0gJ1xcbicpIHtcbiAgICAgIHJlc3VsdCA9IGkgKyAxXG4gICAgICBicmVha1xuICAgIH1cbiAgICBpZiAoc291cmNlQ29kZS50ZXh0W2ldICE9PSAnICcgJiYgc291cmNlQ29kZS50ZXh0W2ldICE9PSAnXFx0JyAmJiBzb3VyY2VDb2RlLnRleHRbaV0gIT09ICdcXHInKSB7XG4gICAgICBicmVha1xuICAgIH1cbiAgICByZXN1bHQgPSBpICsgMVxuICB9XG4gIHJldHVybiByZXN1bHRcbn1cblxuZnVuY3Rpb24gY29tbWVudE9uU2FtZUxpbmVBcyhub2RlKSB7XG4gIHJldHVybiB0b2tlbiA9PiAodG9rZW4udHlwZSA9PT0gJ0Jsb2NrJyB8fCAgdG9rZW4udHlwZSA9PT0gJ0xpbmUnKSAmJlxuICAgICAgdG9rZW4ubG9jLnN0YXJ0LmxpbmUgPT09IHRva2VuLmxvYy5lbmQubGluZSAmJlxuICAgICAgdG9rZW4ubG9jLmVuZC5saW5lID09PSBub2RlLmxvYy5lbmQubGluZVxufVxuXG5mdW5jdGlvbiBmaW5kU3RhcnRPZkxpbmVXaXRoQ29tbWVudHMoc291cmNlQ29kZSwgbm9kZSkge1xuICBjb25zdCB0b2tlbnNUb0VuZE9mTGluZSA9IHRha2VUb2tlbnNCZWZvcmVXaGlsZShzb3VyY2VDb2RlLCBub2RlLCBjb21tZW50T25TYW1lTGluZUFzKG5vZGUpKVxuICBsZXQgc3RhcnRPZlRva2VucyA9IHRva2Vuc1RvRW5kT2ZMaW5lLmxlbmd0aCA+IDAgPyB0b2tlbnNUb0VuZE9mTGluZVswXS5yYW5nZVswXSA6IG5vZGUucmFuZ2VbMF1cbiAgbGV0IHJlc3VsdCA9IHN0YXJ0T2ZUb2tlbnNcbiAgZm9yIChsZXQgaSA9IHN0YXJ0T2ZUb2tlbnMgLSAxOyBpID4gMDsgaS0tKSB7XG4gICAgaWYgKHNvdXJjZUNvZGUudGV4dFtpXSAhPT0gJyAnICYmIHNvdXJjZUNvZGUudGV4dFtpXSAhPT0gJ1xcdCcpIHtcbiAgICAgIGJyZWFrXG4gICAgfVxuICAgIHJlc3VsdCA9IGlcbiAgfVxuICByZXR1cm4gcmVzdWx0XG59XG5cbmZ1bmN0aW9uIGlzUGxhaW5SZXF1aXJlTW9kdWxlKG5vZGUpIHtcbiAgaWYgKG5vZGUudHlwZSAhPT0gJ1ZhcmlhYmxlRGVjbGFyYXRpb24nKSB7XG4gICAgcmV0dXJuIGZhbHNlXG4gIH1cbiAgaWYgKG5vZGUuZGVjbGFyYXRpb25zLmxlbmd0aCAhPT0gMSkge1xuICAgIHJldHVybiBmYWxzZVxuICB9XG4gIGNvbnN0IGRlY2wgPSBub2RlLmRlY2xhcmF0aW9uc1swXVxuICBjb25zdCByZXN1bHQgPSBkZWNsLmlkICYmXG4gICAgKGRlY2wuaWQudHlwZSA9PT0gJ0lkZW50aWZpZXInIHx8IGRlY2wuaWQudHlwZSA9PT0gJ09iamVjdFBhdHRlcm4nKSAmJlxuICAgIGRlY2wuaW5pdCAhPSBudWxsICYmXG4gICAgZGVjbC5pbml0LnR5cGUgPT09ICdDYWxsRXhwcmVzc2lvbicgJiZcbiAgICBkZWNsLmluaXQuY2FsbGVlICE9IG51bGwgJiZcbiAgICBkZWNsLmluaXQuY2FsbGVlLm5hbWUgPT09ICdyZXF1aXJlJyAmJlxuICAgIGRlY2wuaW5pdC5hcmd1bWVudHMgIT0gbnVsbCAmJlxuICAgIGRlY2wuaW5pdC5hcmd1bWVudHMubGVuZ3RoID09PSAxICYmXG4gICAgZGVjbC5pbml0LmFyZ3VtZW50c1swXS50eXBlID09PSAnTGl0ZXJhbCdcbiAgcmV0dXJuIHJlc3VsdFxufVxuXG5mdW5jdGlvbiBpc1BsYWluSW1wb3J0TW9kdWxlKG5vZGUpIHtcbiAgcmV0dXJuIG5vZGUudHlwZSA9PT0gJ0ltcG9ydERlY2xhcmF0aW9uJyAmJiBub2RlLnNwZWNpZmllcnMgIT0gbnVsbCAmJiBub2RlLnNwZWNpZmllcnMubGVuZ3RoID4gMFxufVxuXG5mdW5jdGlvbiBpc1BsYWluSW1wb3J0RXF1YWxzKG5vZGUpIHtcbiAgcmV0dXJuIG5vZGUudHlwZSA9PT0gJ1RTSW1wb3J0RXF1YWxzRGVjbGFyYXRpb24nICYmIG5vZGUubW9kdWxlUmVmZXJlbmNlLmV4cHJlc3Npb25cbn1cblxuZnVuY3Rpb24gY2FuQ3Jvc3NOb2RlV2hpbGVSZW9yZGVyKG5vZGUpIHtcbiAgcmV0dXJuIGlzUGxhaW5SZXF1aXJlTW9kdWxlKG5vZGUpIHx8IGlzUGxhaW5JbXBvcnRNb2R1bGUobm9kZSkgfHwgaXNQbGFpbkltcG9ydEVxdWFscyhub2RlKVxufVxuXG5mdW5jdGlvbiBjYW5SZW9yZGVySXRlbXMoZmlyc3ROb2RlLCBzZWNvbmROb2RlKSB7XG4gIGNvbnN0IHBhcmVudCA9IGZpcnN0Tm9kZS5wYXJlbnRcbiAgY29uc3QgW2ZpcnN0SW5kZXgsIHNlY29uZEluZGV4XSA9IFtcbiAgICBwYXJlbnQuYm9keS5pbmRleE9mKGZpcnN0Tm9kZSksXG4gICAgcGFyZW50LmJvZHkuaW5kZXhPZihzZWNvbmROb2RlKSxcbiAgXS5zb3J0KClcbiAgY29uc3Qgbm9kZXNCZXR3ZWVuID0gcGFyZW50LmJvZHkuc2xpY2UoZmlyc3RJbmRleCwgc2Vjb25kSW5kZXggKyAxKVxuICBmb3IgKHZhciBub2RlQmV0d2VlbiBvZiBub2Rlc0JldHdlZW4pIHtcbiAgICBpZiAoIWNhbkNyb3NzTm9kZVdoaWxlUmVvcmRlcihub2RlQmV0d2VlbikpIHtcbiAgICAgIHJldHVybiBmYWxzZVxuICAgIH1cbiAgfVxuICByZXR1cm4gdHJ1ZVxufVxuXG5mdW5jdGlvbiBmaXhPdXRPZk9yZGVyKGNvbnRleHQsIGZpcnN0Tm9kZSwgc2Vjb25kTm9kZSwgb3JkZXIpIHtcbiAgY29uc3Qgc291cmNlQ29kZSA9IGNvbnRleHQuZ2V0U291cmNlQ29kZSgpXG5cbiAgY29uc3QgZmlyc3RSb290ID0gZmluZFJvb3ROb2RlKGZpcnN0Tm9kZS5ub2RlKVxuICBjb25zdCBmaXJzdFJvb3RTdGFydCA9IGZpbmRTdGFydE9mTGluZVdpdGhDb21tZW50cyhzb3VyY2VDb2RlLCBmaXJzdFJvb3QpXG4gIGNvbnN0IGZpcnN0Um9vdEVuZCA9IGZpbmRFbmRPZkxpbmVXaXRoQ29tbWVudHMoc291cmNlQ29kZSwgZmlyc3RSb290KVxuXG4gIGNvbnN0IHNlY29uZFJvb3QgPSBmaW5kUm9vdE5vZGUoc2Vjb25kTm9kZS5ub2RlKVxuICBjb25zdCBzZWNvbmRSb290U3RhcnQgPSBmaW5kU3RhcnRPZkxpbmVXaXRoQ29tbWVudHMoc291cmNlQ29kZSwgc2Vjb25kUm9vdClcbiAgY29uc3Qgc2Vjb25kUm9vdEVuZCA9IGZpbmRFbmRPZkxpbmVXaXRoQ29tbWVudHMoc291cmNlQ29kZSwgc2Vjb25kUm9vdClcbiAgY29uc3QgY2FuRml4ID0gY2FuUmVvcmRlckl0ZW1zKGZpcnN0Um9vdCwgc2Vjb25kUm9vdClcblxuICBsZXQgbmV3Q29kZSA9IHNvdXJjZUNvZGUudGV4dC5zdWJzdHJpbmcoc2Vjb25kUm9vdFN0YXJ0LCBzZWNvbmRSb290RW5kKVxuICBpZiAobmV3Q29kZVtuZXdDb2RlLmxlbmd0aCAtIDFdICE9PSAnXFxuJykge1xuICAgIG5ld0NvZGUgPSBuZXdDb2RlICsgJ1xcbidcbiAgfVxuXG4gIGNvbnN0IG1lc3NhZ2UgPSBgXFxgJHtzZWNvbmROb2RlLmRpc3BsYXlOYW1lfVxcYCBpbXBvcnQgc2hvdWxkIG9jY3VyICR7b3JkZXJ9IGltcG9ydCBvZiBcXGAke2ZpcnN0Tm9kZS5kaXNwbGF5TmFtZX1cXGBgXG5cbiAgaWYgKG9yZGVyID09PSAnYmVmb3JlJykge1xuICAgIGNvbnRleHQucmVwb3J0KHtcbiAgICAgIG5vZGU6IHNlY29uZE5vZGUubm9kZSxcbiAgICAgIG1lc3NhZ2U6IG1lc3NhZ2UsXG4gICAgICBmaXg6IGNhbkZpeCAmJiAoZml4ZXIgPT5cbiAgICAgICAgZml4ZXIucmVwbGFjZVRleHRSYW5nZShcbiAgICAgICAgICBbZmlyc3RSb290U3RhcnQsIHNlY29uZFJvb3RFbmRdLFxuICAgICAgICAgIG5ld0NvZGUgKyBzb3VyY2VDb2RlLnRleHQuc3Vic3RyaW5nKGZpcnN0Um9vdFN0YXJ0LCBzZWNvbmRSb290U3RhcnQpXG4gICAgICAgICkpLFxuICAgIH0pXG4gIH0gZWxzZSBpZiAob3JkZXIgPT09ICdhZnRlcicpIHtcbiAgICBjb250ZXh0LnJlcG9ydCh7XG4gICAgICBub2RlOiBzZWNvbmROb2RlLm5vZGUsXG4gICAgICBtZXNzYWdlOiBtZXNzYWdlLFxuICAgICAgZml4OiBjYW5GaXggJiYgKGZpeGVyID0+XG4gICAgICAgIGZpeGVyLnJlcGxhY2VUZXh0UmFuZ2UoXG4gICAgICAgICAgW3NlY29uZFJvb3RTdGFydCwgZmlyc3RSb290RW5kXSxcbiAgICAgICAgICBzb3VyY2VDb2RlLnRleHQuc3Vic3RyaW5nKHNlY29uZFJvb3RFbmQsIGZpcnN0Um9vdEVuZCkgKyBuZXdDb2RlXG4gICAgICAgICkpLFxuICAgIH0pXG4gIH1cbn1cblxuZnVuY3Rpb24gcmVwb3J0T3V0T2ZPcmRlcihjb250ZXh0LCBpbXBvcnRlZCwgb3V0T2ZPcmRlciwgb3JkZXIpIHtcbiAgb3V0T2ZPcmRlci5mb3JFYWNoKGZ1bmN0aW9uIChpbXApIHtcbiAgICBjb25zdCBmb3VuZCA9IGltcG9ydGVkLmZpbmQoZnVuY3Rpb24gaGFzSGlnaGVyUmFuayhpbXBvcnRlZEl0ZW0pIHtcbiAgICAgIHJldHVybiBpbXBvcnRlZEl0ZW0ucmFuayA+IGltcC5yYW5rXG4gICAgfSlcbiAgICBmaXhPdXRPZk9yZGVyKGNvbnRleHQsIGZvdW5kLCBpbXAsIG9yZGVyKVxuICB9KVxufVxuXG5mdW5jdGlvbiBtYWtlT3V0T2ZPcmRlclJlcG9ydChjb250ZXh0LCBpbXBvcnRlZCkge1xuICBjb25zdCBvdXRPZk9yZGVyID0gZmluZE91dE9mT3JkZXIoaW1wb3J0ZWQpXG4gIGlmICghb3V0T2ZPcmRlci5sZW5ndGgpIHtcbiAgICByZXR1cm5cbiAgfVxuICAvLyBUaGVyZSBhcmUgdGhpbmdzIHRvIHJlcG9ydC4gVHJ5IHRvIG1pbmltaXplIHRoZSBudW1iZXIgb2YgcmVwb3J0ZWQgZXJyb3JzLlxuICBjb25zdCByZXZlcnNlZEltcG9ydGVkID0gcmV2ZXJzZShpbXBvcnRlZClcbiAgY29uc3QgcmV2ZXJzZWRPcmRlciA9IGZpbmRPdXRPZk9yZGVyKHJldmVyc2VkSW1wb3J0ZWQpXG4gIGlmIChyZXZlcnNlZE9yZGVyLmxlbmd0aCA8IG91dE9mT3JkZXIubGVuZ3RoKSB7XG4gICAgcmVwb3J0T3V0T2ZPcmRlcihjb250ZXh0LCByZXZlcnNlZEltcG9ydGVkLCByZXZlcnNlZE9yZGVyLCAnYWZ0ZXInKVxuICAgIHJldHVyblxuICB9XG4gIHJlcG9ydE91dE9mT3JkZXIoY29udGV4dCwgaW1wb3J0ZWQsIG91dE9mT3JkZXIsICdiZWZvcmUnKVxufVxuXG5mdW5jdGlvbiBnZXRTb3J0ZXIoYXNjZW5kaW5nKSB7XG4gIGNvbnN0IG11bHRpcGxpZXIgPSBhc2NlbmRpbmcgPyAxIDogLTFcblxuICByZXR1cm4gZnVuY3Rpb24gaW1wb3J0c1NvcnRlcihpbXBvcnRBLCBpbXBvcnRCKSB7XG4gICAgbGV0IHJlc3VsdFxuXG4gICAgaWYgKGltcG9ydEEgPCBpbXBvcnRCKSB7XG4gICAgICByZXN1bHQgPSAtMVxuICAgIH0gZWxzZSBpZiAoaW1wb3J0QSA+IGltcG9ydEIpIHtcbiAgICAgIHJlc3VsdCA9IDFcbiAgICB9IGVsc2Uge1xuICAgICAgcmVzdWx0ID0gMFxuICAgIH1cblxuICAgIHJldHVybiByZXN1bHQgKiBtdWx0aXBsaWVyXG4gIH1cbn1cblxuZnVuY3Rpb24gbXV0YXRlUmFua3NUb0FscGhhYmV0aXplKGltcG9ydGVkLCBhbHBoYWJldGl6ZU9wdGlvbnMpIHtcbiAgY29uc3QgZ3JvdXBlZEJ5UmFua3MgPSBpbXBvcnRlZC5yZWR1Y2UoZnVuY3Rpb24oYWNjLCBpbXBvcnRlZEl0ZW0pIHtcbiAgICBpZiAoIUFycmF5LmlzQXJyYXkoYWNjW2ltcG9ydGVkSXRlbS5yYW5rXSkpIHtcbiAgICAgIGFjY1tpbXBvcnRlZEl0ZW0ucmFua10gPSBbXVxuICAgIH1cbiAgICBhY2NbaW1wb3J0ZWRJdGVtLnJhbmtdLnB1c2goaW1wb3J0ZWRJdGVtLnZhbHVlKVxuICAgIHJldHVybiBhY2NcbiAgfSwge30pXG5cbiAgY29uc3QgZ3JvdXBSYW5rcyA9IE9iamVjdC5rZXlzKGdyb3VwZWRCeVJhbmtzKVxuXG4gIGNvbnN0IHNvcnRlckZuID0gZ2V0U29ydGVyKGFscGhhYmV0aXplT3B0aW9ucy5vcmRlciA9PT0gJ2FzYycpXG4gIGNvbnN0IGNvbXBhcmF0b3IgPSBhbHBoYWJldGl6ZU9wdGlvbnMuY2FzZUluc2Vuc2l0aXZlID8gKGEsIGIpID0+IHNvcnRlckZuKFN0cmluZyhhKS50b0xvd2VyQ2FzZSgpLCBTdHJpbmcoYikudG9Mb3dlckNhc2UoKSkgOiAoYSwgYikgPT4gc29ydGVyRm4oYSwgYilcbiAgLy8gc29ydCBpbXBvcnRzIGxvY2FsbHkgd2l0aGluIHRoZWlyIGdyb3VwXG4gIGdyb3VwUmFua3MuZm9yRWFjaChmdW5jdGlvbihncm91cFJhbmspIHtcbiAgICBncm91cGVkQnlSYW5rc1tncm91cFJhbmtdLnNvcnQoY29tcGFyYXRvcilcbiAgfSlcblxuICAvLyBhc3NpZ24gZ2xvYmFsbHkgdW5pcXVlIHJhbmsgdG8gZWFjaCBpbXBvcnRcbiAgbGV0IG5ld1JhbmsgPSAwXG4gIGNvbnN0IGFscGhhYmV0aXplZFJhbmtzID0gZ3JvdXBSYW5rcy5zb3J0KCkucmVkdWNlKGZ1bmN0aW9uKGFjYywgZ3JvdXBSYW5rKSB7XG4gICAgZ3JvdXBlZEJ5UmFua3NbZ3JvdXBSYW5rXS5mb3JFYWNoKGZ1bmN0aW9uKGltcG9ydGVkSXRlbU5hbWUpIHtcbiAgICAgIGFjY1tpbXBvcnRlZEl0ZW1OYW1lXSA9IHBhcnNlSW50KGdyb3VwUmFuaywgMTApICsgbmV3UmFua1xuICAgICAgbmV3UmFuayArPSAxXG4gICAgfSlcbiAgICByZXR1cm4gYWNjXG4gIH0sIHt9KVxuXG4gIC8vIG11dGF0ZSB0aGUgb3JpZ2luYWwgZ3JvdXAtcmFuayB3aXRoIGFscGhhYmV0aXplZC1yYW5rXG4gIGltcG9ydGVkLmZvckVhY2goZnVuY3Rpb24oaW1wb3J0ZWRJdGVtKSB7XG4gICAgaW1wb3J0ZWRJdGVtLnJhbmsgPSBhbHBoYWJldGl6ZWRSYW5rc1tpbXBvcnRlZEl0ZW0udmFsdWVdXG4gIH0pXG59XG5cbi8vIERFVEVDVElOR1xuXG5mdW5jdGlvbiBjb21wdXRlUGF0aFJhbmsocmFua3MsIHBhdGhHcm91cHMsIHBhdGgsIG1heFBvc2l0aW9uKSB7XG4gIGZvciAobGV0IGkgPSAwLCBsID0gcGF0aEdyb3Vwcy5sZW5ndGg7IGkgPCBsOyBpKyspIHtcbiAgICBjb25zdCB7IHBhdHRlcm4sIHBhdHRlcm5PcHRpb25zLCBncm91cCwgcG9zaXRpb24gPSAxIH0gPSBwYXRoR3JvdXBzW2ldXG4gICAgaWYgKG1pbmltYXRjaChwYXRoLCBwYXR0ZXJuLCBwYXR0ZXJuT3B0aW9ucyB8fCB7IG5vY29tbWVudDogdHJ1ZSB9KSkge1xuICAgICAgcmV0dXJuIHJhbmtzW2dyb3VwXSArIChwb3NpdGlvbiAvIG1heFBvc2l0aW9uKVxuICAgIH1cbiAgfVxufVxuXG5mdW5jdGlvbiBjb21wdXRlUmFuayhjb250ZXh0LCByYW5rcywgaW1wb3J0RW50cnksIGV4Y2x1ZGVkSW1wb3J0VHlwZXMpIHtcbiAgbGV0IGltcFR5cGVcbiAgbGV0IHJhbmtcbiAgaWYgKGltcG9ydEVudHJ5LnR5cGUgPT09ICdpbXBvcnQ6b2JqZWN0Jykge1xuICAgIGltcFR5cGUgPSAnb2JqZWN0J1xuICB9IGVsc2Uge1xuICAgIGltcFR5cGUgPSBpbXBvcnRUeXBlKGltcG9ydEVudHJ5LnZhbHVlLCBjb250ZXh0KVxuICB9XG4gIGlmICghZXhjbHVkZWRJbXBvcnRUeXBlcy5oYXMoaW1wVHlwZSkpIHtcbiAgICByYW5rID0gY29tcHV0ZVBhdGhSYW5rKHJhbmtzLmdyb3VwcywgcmFua3MucGF0aEdyb3VwcywgaW1wb3J0RW50cnkudmFsdWUsIHJhbmtzLm1heFBvc2l0aW9uKVxuICB9XG4gIGlmICh0eXBlb2YgcmFuayA9PT0gJ3VuZGVmaW5lZCcpIHtcbiAgICByYW5rID0gcmFua3MuZ3JvdXBzW2ltcFR5cGVdXG4gIH1cbiAgaWYgKGltcG9ydEVudHJ5LnR5cGUgIT09ICdpbXBvcnQnICYmICFpbXBvcnRFbnRyeS50eXBlLnN0YXJ0c1dpdGgoJ2ltcG9ydDonKSkge1xuICAgIHJhbmsgKz0gMTAwXG4gIH1cblxuICByZXR1cm4gcmFua1xufVxuXG5mdW5jdGlvbiByZWdpc3Rlck5vZGUoY29udGV4dCwgaW1wb3J0RW50cnksIHJhbmtzLCBpbXBvcnRlZCwgZXhjbHVkZWRJbXBvcnRUeXBlcykge1xuICBjb25zdCByYW5rID0gY29tcHV0ZVJhbmsoY29udGV4dCwgcmFua3MsIGltcG9ydEVudHJ5LCBleGNsdWRlZEltcG9ydFR5cGVzKVxuICBpZiAocmFuayAhPT0gLTEpIHtcbiAgICBpbXBvcnRlZC5wdXNoKE9iamVjdC5hc3NpZ24oe30sIGltcG9ydEVudHJ5LCB7IHJhbmsgfSkpXG4gIH1cbn1cblxuZnVuY3Rpb24gaXNJblZhcmlhYmxlRGVjbGFyYXRvcihub2RlKSB7XG4gIHJldHVybiBub2RlICYmXG4gICAgKG5vZGUudHlwZSA9PT0gJ1ZhcmlhYmxlRGVjbGFyYXRvcicgfHwgaXNJblZhcmlhYmxlRGVjbGFyYXRvcihub2RlLnBhcmVudCkpXG59XG5cbmNvbnN0IHR5cGVzID0gWydidWlsdGluJywgJ2V4dGVybmFsJywgJ2ludGVybmFsJywgJ3Vua25vd24nLCAncGFyZW50JywgJ3NpYmxpbmcnLCAnaW5kZXgnLCAnb2JqZWN0J11cblxuLy8gQ3JlYXRlcyBhbiBvYmplY3Qgd2l0aCB0eXBlLXJhbmsgcGFpcnMuXG4vLyBFeGFtcGxlOiB7IGluZGV4OiAwLCBzaWJsaW5nOiAxLCBwYXJlbnQ6IDEsIGV4dGVybmFsOiAxLCBidWlsdGluOiAyLCBpbnRlcm5hbDogMiB9XG4vLyBXaWxsIHRocm93IGFuIGVycm9yIGlmIGl0IGNvbnRhaW5zIGEgdHlwZSB0aGF0IGRvZXMgbm90IGV4aXN0LCBvciBoYXMgYSBkdXBsaWNhdGVcbmZ1bmN0aW9uIGNvbnZlcnRHcm91cHNUb1JhbmtzKGdyb3Vwcykge1xuICBjb25zdCByYW5rT2JqZWN0ID0gZ3JvdXBzLnJlZHVjZShmdW5jdGlvbihyZXMsIGdyb3VwLCBpbmRleCkge1xuICAgIGlmICh0eXBlb2YgZ3JvdXAgPT09ICdzdHJpbmcnKSB7XG4gICAgICBncm91cCA9IFtncm91cF1cbiAgICB9XG4gICAgZ3JvdXAuZm9yRWFjaChmdW5jdGlvbihncm91cEl0ZW0pIHtcbiAgICAgIGlmICh0eXBlcy5pbmRleE9mKGdyb3VwSXRlbSkgPT09IC0xKSB7XG4gICAgICAgIHRocm93IG5ldyBFcnJvcignSW5jb3JyZWN0IGNvbmZpZ3VyYXRpb24gb2YgdGhlIHJ1bGU6IFVua25vd24gdHlwZSBgJyArXG4gICAgICAgICAgSlNPTi5zdHJpbmdpZnkoZ3JvdXBJdGVtKSArICdgJylcbiAgICAgIH1cbiAgICAgIGlmIChyZXNbZ3JvdXBJdGVtXSAhPT0gdW5kZWZpbmVkKSB7XG4gICAgICAgIHRocm93IG5ldyBFcnJvcignSW5jb3JyZWN0IGNvbmZpZ3VyYXRpb24gb2YgdGhlIHJ1bGU6IGAnICsgZ3JvdXBJdGVtICsgJ2AgaXMgZHVwbGljYXRlZCcpXG4gICAgICB9XG4gICAgICByZXNbZ3JvdXBJdGVtXSA9IGluZGV4XG4gICAgfSlcbiAgICByZXR1cm4gcmVzXG4gIH0sIHt9KVxuXG4gIGNvbnN0IG9taXR0ZWRUeXBlcyA9IHR5cGVzLmZpbHRlcihmdW5jdGlvbih0eXBlKSB7XG4gICAgcmV0dXJuIHJhbmtPYmplY3RbdHlwZV0gPT09IHVuZGVmaW5lZFxuICB9KVxuXG4gIHJldHVybiBvbWl0dGVkVHlwZXMucmVkdWNlKGZ1bmN0aW9uKHJlcywgdHlwZSkge1xuICAgIHJlc1t0eXBlXSA9IGdyb3Vwcy5sZW5ndGhcbiAgICByZXR1cm4gcmVzXG4gIH0sIHJhbmtPYmplY3QpXG59XG5cbmZ1bmN0aW9uIGNvbnZlcnRQYXRoR3JvdXBzRm9yUmFua3MocGF0aEdyb3Vwcykge1xuICBjb25zdCBhZnRlciA9IHt9XG4gIGNvbnN0IGJlZm9yZSA9IHt9XG5cbiAgY29uc3QgdHJhbnNmb3JtZWQgPSBwYXRoR3JvdXBzLm1hcCgocGF0aEdyb3VwLCBpbmRleCkgPT4ge1xuICAgIGNvbnN0IHsgZ3JvdXAsIHBvc2l0aW9uOiBwb3NpdGlvblN0cmluZyB9ID0gcGF0aEdyb3VwXG4gICAgbGV0IHBvc2l0aW9uID0gMFxuICAgIGlmIChwb3NpdGlvblN0cmluZyA9PT0gJ2FmdGVyJykge1xuICAgICAgaWYgKCFhZnRlcltncm91cF0pIHtcbiAgICAgICAgYWZ0ZXJbZ3JvdXBdID0gMVxuICAgICAgfVxuICAgICAgcG9zaXRpb24gPSBhZnRlcltncm91cF0rK1xuICAgIH0gZWxzZSBpZiAocG9zaXRpb25TdHJpbmcgPT09ICdiZWZvcmUnKSB7XG4gICAgICBpZiAoIWJlZm9yZVtncm91cF0pIHtcbiAgICAgICAgYmVmb3JlW2dyb3VwXSA9IFtdXG4gICAgICB9XG4gICAgICBiZWZvcmVbZ3JvdXBdLnB1c2goaW5kZXgpXG4gICAgfVxuXG4gICAgcmV0dXJuIE9iamVjdC5hc3NpZ24oe30sIHBhdGhHcm91cCwgeyBwb3NpdGlvbiB9KVxuICB9KVxuXG4gIGxldCBtYXhQb3NpdGlvbiA9IDFcblxuICBPYmplY3Qua2V5cyhiZWZvcmUpLmZvckVhY2goKGdyb3VwKSA9PiB7XG4gICAgY29uc3QgZ3JvdXBMZW5ndGggPSBiZWZvcmVbZ3JvdXBdLmxlbmd0aFxuICAgIGJlZm9yZVtncm91cF0uZm9yRWFjaCgoZ3JvdXBJbmRleCwgaW5kZXgpID0+IHtcbiAgICAgIHRyYW5zZm9ybWVkW2dyb3VwSW5kZXhdLnBvc2l0aW9uID0gLTEgKiAoZ3JvdXBMZW5ndGggLSBpbmRleClcbiAgICB9KVxuICAgIG1heFBvc2l0aW9uID0gTWF0aC5tYXgobWF4UG9zaXRpb24sIGdyb3VwTGVuZ3RoKVxuICB9KVxuXG4gIE9iamVjdC5rZXlzKGFmdGVyKS5mb3JFYWNoKChrZXkpID0+IHtcbiAgICBjb25zdCBncm91cE5leHRQb3NpdGlvbiA9IGFmdGVyW2tleV1cbiAgICBtYXhQb3NpdGlvbiA9IE1hdGgubWF4KG1heFBvc2l0aW9uLCBncm91cE5leHRQb3NpdGlvbiAtIDEpXG4gIH0pXG5cbiAgcmV0dXJuIHtcbiAgICBwYXRoR3JvdXBzOiB0cmFuc2Zvcm1lZCxcbiAgICBtYXhQb3NpdGlvbjogbWF4UG9zaXRpb24gPiAxMCA/IE1hdGgucG93KDEwLCBNYXRoLmNlaWwoTWF0aC5sb2cxMChtYXhQb3NpdGlvbikpKSA6IDEwLFxuICB9XG59XG5cbmZ1bmN0aW9uIGZpeE5ld0xpbmVBZnRlckltcG9ydChjb250ZXh0LCBwcmV2aW91c0ltcG9ydCkge1xuICBjb25zdCBwcmV2Um9vdCA9IGZpbmRSb290Tm9kZShwcmV2aW91c0ltcG9ydC5ub2RlKVxuICBjb25zdCB0b2tlbnNUb0VuZE9mTGluZSA9IHRha2VUb2tlbnNBZnRlcldoaWxlKFxuICAgIGNvbnRleHQuZ2V0U291cmNlQ29kZSgpLCBwcmV2Um9vdCwgY29tbWVudE9uU2FtZUxpbmVBcyhwcmV2Um9vdCkpXG5cbiAgbGV0IGVuZE9mTGluZSA9IHByZXZSb290LnJhbmdlWzFdXG4gIGlmICh0b2tlbnNUb0VuZE9mTGluZS5sZW5ndGggPiAwKSB7XG4gICAgZW5kT2ZMaW5lID0gdG9rZW5zVG9FbmRPZkxpbmVbdG9rZW5zVG9FbmRPZkxpbmUubGVuZ3RoIC0gMV0ucmFuZ2VbMV1cbiAgfVxuICByZXR1cm4gKGZpeGVyKSA9PiBmaXhlci5pbnNlcnRUZXh0QWZ0ZXJSYW5nZShbcHJldlJvb3QucmFuZ2VbMF0sIGVuZE9mTGluZV0sICdcXG4nKVxufVxuXG5mdW5jdGlvbiByZW1vdmVOZXdMaW5lQWZ0ZXJJbXBvcnQoY29udGV4dCwgY3VycmVudEltcG9ydCwgcHJldmlvdXNJbXBvcnQpIHtcbiAgY29uc3Qgc291cmNlQ29kZSA9IGNvbnRleHQuZ2V0U291cmNlQ29kZSgpXG4gIGNvbnN0IHByZXZSb290ID0gZmluZFJvb3ROb2RlKHByZXZpb3VzSW1wb3J0Lm5vZGUpXG4gIGNvbnN0IGN1cnJSb290ID0gZmluZFJvb3ROb2RlKGN1cnJlbnRJbXBvcnQubm9kZSlcbiAgY29uc3QgcmFuZ2VUb1JlbW92ZSA9IFtcbiAgICBmaW5kRW5kT2ZMaW5lV2l0aENvbW1lbnRzKHNvdXJjZUNvZGUsIHByZXZSb290KSxcbiAgICBmaW5kU3RhcnRPZkxpbmVXaXRoQ29tbWVudHMoc291cmNlQ29kZSwgY3VyclJvb3QpLFxuICBdXG4gIGlmICgvXlxccyokLy50ZXN0KHNvdXJjZUNvZGUudGV4dC5zdWJzdHJpbmcocmFuZ2VUb1JlbW92ZVswXSwgcmFuZ2VUb1JlbW92ZVsxXSkpKSB7XG4gICAgcmV0dXJuIChmaXhlcikgPT4gZml4ZXIucmVtb3ZlUmFuZ2UocmFuZ2VUb1JlbW92ZSlcbiAgfVxuICByZXR1cm4gdW5kZWZpbmVkXG59XG5cbmZ1bmN0aW9uIG1ha2VOZXdsaW5lc0JldHdlZW5SZXBvcnQgKGNvbnRleHQsIGltcG9ydGVkLCBuZXdsaW5lc0JldHdlZW5JbXBvcnRzKSB7XG4gIGNvbnN0IGdldE51bWJlck9mRW1wdHlMaW5lc0JldHdlZW4gPSAoY3VycmVudEltcG9ydCwgcHJldmlvdXNJbXBvcnQpID0+IHtcbiAgICBjb25zdCBsaW5lc0JldHdlZW5JbXBvcnRzID0gY29udGV4dC5nZXRTb3VyY2VDb2RlKCkubGluZXMuc2xpY2UoXG4gICAgICBwcmV2aW91c0ltcG9ydC5ub2RlLmxvYy5lbmQubGluZSxcbiAgICAgIGN1cnJlbnRJbXBvcnQubm9kZS5sb2Muc3RhcnQubGluZSAtIDFcbiAgICApXG5cbiAgICByZXR1cm4gbGluZXNCZXR3ZWVuSW1wb3J0cy5maWx0ZXIoKGxpbmUpID0+ICFsaW5lLnRyaW0oKS5sZW5ndGgpLmxlbmd0aFxuICB9XG4gIGxldCBwcmV2aW91c0ltcG9ydCA9IGltcG9ydGVkWzBdXG5cbiAgaW1wb3J0ZWQuc2xpY2UoMSkuZm9yRWFjaChmdW5jdGlvbihjdXJyZW50SW1wb3J0KSB7XG4gICAgY29uc3QgZW1wdHlMaW5lc0JldHdlZW4gPSBnZXROdW1iZXJPZkVtcHR5TGluZXNCZXR3ZWVuKGN1cnJlbnRJbXBvcnQsIHByZXZpb3VzSW1wb3J0KVxuXG4gICAgaWYgKG5ld2xpbmVzQmV0d2VlbkltcG9ydHMgPT09ICdhbHdheXMnXG4gICAgICAgIHx8IG5ld2xpbmVzQmV0d2VlbkltcG9ydHMgPT09ICdhbHdheXMtYW5kLWluc2lkZS1ncm91cHMnKSB7XG4gICAgICBpZiAoY3VycmVudEltcG9ydC5yYW5rICE9PSBwcmV2aW91c0ltcG9ydC5yYW5rICYmIGVtcHR5TGluZXNCZXR3ZWVuID09PSAwKSB7XG4gICAgICAgIGNvbnRleHQucmVwb3J0KHtcbiAgICAgICAgICBub2RlOiBwcmV2aW91c0ltcG9ydC5ub2RlLFxuICAgICAgICAgIG1lc3NhZ2U6ICdUaGVyZSBzaG91bGQgYmUgYXQgbGVhc3Qgb25lIGVtcHR5IGxpbmUgYmV0d2VlbiBpbXBvcnQgZ3JvdXBzJyxcbiAgICAgICAgICBmaXg6IGZpeE5ld0xpbmVBZnRlckltcG9ydChjb250ZXh0LCBwcmV2aW91c0ltcG9ydCksXG4gICAgICAgIH0pXG4gICAgICB9IGVsc2UgaWYgKGN1cnJlbnRJbXBvcnQucmFuayA9PT0gcHJldmlvdXNJbXBvcnQucmFua1xuICAgICAgICAmJiBlbXB0eUxpbmVzQmV0d2VlbiA+IDBcbiAgICAgICAgJiYgbmV3bGluZXNCZXR3ZWVuSW1wb3J0cyAhPT0gJ2Fsd2F5cy1hbmQtaW5zaWRlLWdyb3VwcycpIHtcbiAgICAgICAgY29udGV4dC5yZXBvcnQoe1xuICAgICAgICAgIG5vZGU6IHByZXZpb3VzSW1wb3J0Lm5vZGUsXG4gICAgICAgICAgbWVzc2FnZTogJ1RoZXJlIHNob3VsZCBiZSBubyBlbXB0eSBsaW5lIHdpdGhpbiBpbXBvcnQgZ3JvdXAnLFxuICAgICAgICAgIGZpeDogcmVtb3ZlTmV3TGluZUFmdGVySW1wb3J0KGNvbnRleHQsIGN1cnJlbnRJbXBvcnQsIHByZXZpb3VzSW1wb3J0KSxcbiAgICAgICAgfSlcbiAgICAgIH1cbiAgICB9IGVsc2UgaWYgKGVtcHR5TGluZXNCZXR3ZWVuID4gMCkge1xuICAgICAgY29udGV4dC5yZXBvcnQoe1xuICAgICAgICBub2RlOiBwcmV2aW91c0ltcG9ydC5ub2RlLFxuICAgICAgICBtZXNzYWdlOiAnVGhlcmUgc2hvdWxkIGJlIG5vIGVtcHR5IGxpbmUgYmV0d2VlbiBpbXBvcnQgZ3JvdXBzJyxcbiAgICAgICAgZml4OiByZW1vdmVOZXdMaW5lQWZ0ZXJJbXBvcnQoY29udGV4dCwgY3VycmVudEltcG9ydCwgcHJldmlvdXNJbXBvcnQpLFxuICAgICAgfSlcbiAgICB9XG5cbiAgICBwcmV2aW91c0ltcG9ydCA9IGN1cnJlbnRJbXBvcnRcbiAgfSlcbn1cblxuZnVuY3Rpb24gZ2V0QWxwaGFiZXRpemVDb25maWcob3B0aW9ucykge1xuICBjb25zdCBhbHBoYWJldGl6ZSA9IG9wdGlvbnMuYWxwaGFiZXRpemUgfHwge31cbiAgY29uc3Qgb3JkZXIgPSBhbHBoYWJldGl6ZS5vcmRlciB8fCAnaWdub3JlJ1xuICBjb25zdCBjYXNlSW5zZW5zaXRpdmUgPSBhbHBoYWJldGl6ZS5jYXNlSW5zZW5zaXRpdmUgfHwgZmFsc2VcblxuICByZXR1cm4ge29yZGVyLCBjYXNlSW5zZW5zaXRpdmV9XG59XG5cbm1vZHVsZS5leHBvcnRzID0ge1xuICBtZXRhOiB7XG4gICAgdHlwZTogJ3N1Z2dlc3Rpb24nLFxuICAgIGRvY3M6IHtcbiAgICAgIHVybDogZG9jc1VybCgnb3JkZXInKSxcbiAgICB9LFxuXG4gICAgZml4YWJsZTogJ2NvZGUnLFxuICAgIHNjaGVtYTogW1xuICAgICAge1xuICAgICAgICB0eXBlOiAnb2JqZWN0JyxcbiAgICAgICAgcHJvcGVydGllczoge1xuICAgICAgICAgIGdyb3Vwczoge1xuICAgICAgICAgICAgdHlwZTogJ2FycmF5JyxcbiAgICAgICAgICB9LFxuICAgICAgICAgIHBhdGhHcm91cHNFeGNsdWRlZEltcG9ydFR5cGVzOiB7XG4gICAgICAgICAgICB0eXBlOiAnYXJyYXknLFxuICAgICAgICAgIH0sXG4gICAgICAgICAgcGF0aEdyb3Vwczoge1xuICAgICAgICAgICAgdHlwZTogJ2FycmF5JyxcbiAgICAgICAgICAgIGl0ZW1zOiB7XG4gICAgICAgICAgICAgIHR5cGU6ICdvYmplY3QnLFxuICAgICAgICAgICAgICBwcm9wZXJ0aWVzOiB7XG4gICAgICAgICAgICAgICAgcGF0dGVybjoge1xuICAgICAgICAgICAgICAgICAgdHlwZTogJ3N0cmluZycsXG4gICAgICAgICAgICAgICAgfSxcbiAgICAgICAgICAgICAgICBwYXR0ZXJuT3B0aW9uczoge1xuICAgICAgICAgICAgICAgICAgdHlwZTogJ29iamVjdCcsXG4gICAgICAgICAgICAgICAgfSxcbiAgICAgICAgICAgICAgICBncm91cDoge1xuICAgICAgICAgICAgICAgICAgdHlwZTogJ3N0cmluZycsXG4gICAgICAgICAgICAgICAgICBlbnVtOiB0eXBlcyxcbiAgICAgICAgICAgICAgICB9LFxuICAgICAgICAgICAgICAgIHBvc2l0aW9uOiB7XG4gICAgICAgICAgICAgICAgICB0eXBlOiAnc3RyaW5nJyxcbiAgICAgICAgICAgICAgICAgIGVudW06IFsnYWZ0ZXInLCAnYmVmb3JlJ10sXG4gICAgICAgICAgICAgICAgfSxcbiAgICAgICAgICAgICAgfSxcbiAgICAgICAgICAgICAgcmVxdWlyZWQ6IFsncGF0dGVybicsICdncm91cCddLFxuICAgICAgICAgICAgfSxcbiAgICAgICAgICB9LFxuICAgICAgICAgICduZXdsaW5lcy1iZXR3ZWVuJzoge1xuICAgICAgICAgICAgZW51bTogW1xuICAgICAgICAgICAgICAnaWdub3JlJyxcbiAgICAgICAgICAgICAgJ2Fsd2F5cycsXG4gICAgICAgICAgICAgICdhbHdheXMtYW5kLWluc2lkZS1ncm91cHMnLFxuICAgICAgICAgICAgICAnbmV2ZXInLFxuICAgICAgICAgICAgXSxcbiAgICAgICAgICB9LFxuICAgICAgICAgIGFscGhhYmV0aXplOiB7XG4gICAgICAgICAgICB0eXBlOiAnb2JqZWN0JyxcbiAgICAgICAgICAgIHByb3BlcnRpZXM6IHtcbiAgICAgICAgICAgICAgY2FzZUluc2Vuc2l0aXZlOiB7XG4gICAgICAgICAgICAgICAgdHlwZTogJ2Jvb2xlYW4nLFxuICAgICAgICAgICAgICAgIGRlZmF1bHQ6IGZhbHNlLFxuICAgICAgICAgICAgICB9LFxuICAgICAgICAgICAgICBvcmRlcjoge1xuICAgICAgICAgICAgICAgIGVudW06IFsnaWdub3JlJywgJ2FzYycsICdkZXNjJ10sXG4gICAgICAgICAgICAgICAgZGVmYXVsdDogJ2lnbm9yZScsXG4gICAgICAgICAgICAgIH0sXG4gICAgICAgICAgICB9LFxuICAgICAgICAgICAgYWRkaXRpb25hbFByb3BlcnRpZXM6IGZhbHNlLFxuICAgICAgICAgIH0sXG4gICAgICAgIH0sXG4gICAgICAgIGFkZGl0aW9uYWxQcm9wZXJ0aWVzOiBmYWxzZSxcbiAgICAgIH0sXG4gICAgXSxcbiAgfSxcblxuICBjcmVhdGU6IGZ1bmN0aW9uIGltcG9ydE9yZGVyUnVsZSAoY29udGV4dCkge1xuICAgIGNvbnN0IG9wdGlvbnMgPSBjb250ZXh0Lm9wdGlvbnNbMF0gfHwge31cbiAgICBjb25zdCBuZXdsaW5lc0JldHdlZW5JbXBvcnRzID0gb3B0aW9uc1snbmV3bGluZXMtYmV0d2VlbiddIHx8ICdpZ25vcmUnXG4gICAgY29uc3QgcGF0aEdyb3Vwc0V4Y2x1ZGVkSW1wb3J0VHlwZXMgPSBuZXcgU2V0KG9wdGlvbnNbJ3BhdGhHcm91cHNFeGNsdWRlZEltcG9ydFR5cGVzJ10gfHwgWydidWlsdGluJywgJ2V4dGVybmFsJywgJ29iamVjdCddKVxuICAgIGNvbnN0IGFscGhhYmV0aXplID0gZ2V0QWxwaGFiZXRpemVDb25maWcob3B0aW9ucylcbiAgICBsZXQgcmFua3NcblxuICAgIHRyeSB7XG4gICAgICBjb25zdCB7IHBhdGhHcm91cHMsIG1heFBvc2l0aW9uIH0gPSBjb252ZXJ0UGF0aEdyb3Vwc0ZvclJhbmtzKG9wdGlvbnMucGF0aEdyb3VwcyB8fCBbXSlcbiAgICAgIHJhbmtzID0ge1xuICAgICAgICBncm91cHM6IGNvbnZlcnRHcm91cHNUb1JhbmtzKG9wdGlvbnMuZ3JvdXBzIHx8IGRlZmF1bHRHcm91cHMpLFxuICAgICAgICBwYXRoR3JvdXBzLFxuICAgICAgICBtYXhQb3NpdGlvbixcbiAgICAgIH1cbiAgICB9IGNhdGNoIChlcnJvcikge1xuICAgICAgLy8gTWFsZm9ybWVkIGNvbmZpZ3VyYXRpb25cbiAgICAgIHJldHVybiB7XG4gICAgICAgIFByb2dyYW06IGZ1bmN0aW9uKG5vZGUpIHtcbiAgICAgICAgICBjb250ZXh0LnJlcG9ydChub2RlLCBlcnJvci5tZXNzYWdlKVxuICAgICAgICB9LFxuICAgICAgfVxuICAgIH1cbiAgICBsZXQgaW1wb3J0ZWQgPSBbXVxuICAgIGxldCBsZXZlbCA9IDBcblxuICAgIGZ1bmN0aW9uIGluY3JlbWVudExldmVsKCkge1xuICAgICAgbGV2ZWwrK1xuICAgIH1cbiAgICBmdW5jdGlvbiBkZWNyZW1lbnRMZXZlbCgpIHtcbiAgICAgIGxldmVsLS1cbiAgICB9XG5cbiAgICByZXR1cm4ge1xuICAgICAgSW1wb3J0RGVjbGFyYXRpb246IGZ1bmN0aW9uIGhhbmRsZUltcG9ydHMobm9kZSkge1xuICAgICAgICBpZiAobm9kZS5zcGVjaWZpZXJzLmxlbmd0aCkgeyAvLyBJZ25vcmluZyB1bmFzc2lnbmVkIGltcG9ydHNcbiAgICAgICAgICBjb25zdCBuYW1lID0gbm9kZS5zb3VyY2UudmFsdWVcbiAgICAgICAgICByZWdpc3Rlck5vZGUoXG4gICAgICAgICAgICBjb250ZXh0LFxuICAgICAgICAgICAge1xuICAgICAgICAgICAgICBub2RlLFxuICAgICAgICAgICAgICB2YWx1ZTogbmFtZSxcbiAgICAgICAgICAgICAgZGlzcGxheU5hbWU6IG5hbWUsXG4gICAgICAgICAgICAgIHR5cGU6ICdpbXBvcnQnLFxuICAgICAgICAgICAgfSxcbiAgICAgICAgICAgIHJhbmtzLFxuICAgICAgICAgICAgaW1wb3J0ZWQsXG4gICAgICAgICAgICBwYXRoR3JvdXBzRXhjbHVkZWRJbXBvcnRUeXBlc1xuICAgICAgICAgIClcbiAgICAgICAgfVxuICAgICAgfSxcbiAgICAgIFRTSW1wb3J0RXF1YWxzRGVjbGFyYXRpb246IGZ1bmN0aW9uIGhhbmRsZUltcG9ydHMobm9kZSkge1xuICAgICAgICBsZXQgZGlzcGxheU5hbWVcbiAgICAgICAgbGV0IHZhbHVlXG4gICAgICAgIGxldCB0eXBlXG4gICAgICAgIC8vIHNraXAgXCJleHBvcnQgaW1wb3J0XCJzXG4gICAgICAgIGlmIChub2RlLmlzRXhwb3J0KSB7XG4gICAgICAgICAgcmV0dXJuXG4gICAgICAgIH1cbiAgICAgICAgaWYgKG5vZGUubW9kdWxlUmVmZXJlbmNlLnR5cGUgPT09ICdUU0V4dGVybmFsTW9kdWxlUmVmZXJlbmNlJykge1xuICAgICAgICAgIHZhbHVlID0gbm9kZS5tb2R1bGVSZWZlcmVuY2UuZXhwcmVzc2lvbi52YWx1ZVxuICAgICAgICAgIGRpc3BsYXlOYW1lID0gdmFsdWVcbiAgICAgICAgICB0eXBlID0gJ2ltcG9ydCdcbiAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICB2YWx1ZSA9ICcnXG4gICAgICAgICAgZGlzcGxheU5hbWUgPSBjb250ZXh0LmdldFNvdXJjZUNvZGUoKS5nZXRUZXh0KG5vZGUubW9kdWxlUmVmZXJlbmNlKVxuICAgICAgICAgIHR5cGUgPSAnaW1wb3J0Om9iamVjdCdcbiAgICAgICAgfVxuICAgICAgICByZWdpc3Rlck5vZGUoXG4gICAgICAgICAgY29udGV4dCxcbiAgICAgICAgICB7XG4gICAgICAgICAgICBub2RlLFxuICAgICAgICAgICAgdmFsdWUsXG4gICAgICAgICAgICBkaXNwbGF5TmFtZSxcbiAgICAgICAgICAgIHR5cGUsXG4gICAgICAgICAgfSxcbiAgICAgICAgICByYW5rcyxcbiAgICAgICAgICBpbXBvcnRlZCxcbiAgICAgICAgICBwYXRoR3JvdXBzRXhjbHVkZWRJbXBvcnRUeXBlc1xuICAgICAgICApXG4gICAgICB9LFxuICAgICAgQ2FsbEV4cHJlc3Npb246IGZ1bmN0aW9uIGhhbmRsZVJlcXVpcmVzKG5vZGUpIHtcbiAgICAgICAgaWYgKGxldmVsICE9PSAwIHx8ICFpc1N0YXRpY1JlcXVpcmUobm9kZSkgfHwgIWlzSW5WYXJpYWJsZURlY2xhcmF0b3Iobm9kZS5wYXJlbnQpKSB7XG4gICAgICAgICAgcmV0dXJuXG4gICAgICAgIH1cbiAgICAgICAgY29uc3QgbmFtZSA9IG5vZGUuYXJndW1lbnRzWzBdLnZhbHVlXG4gICAgICAgIHJlZ2lzdGVyTm9kZShcbiAgICAgICAgICBjb250ZXh0LFxuICAgICAgICAgIHtcbiAgICAgICAgICAgIG5vZGUsXG4gICAgICAgICAgICB2YWx1ZTogbmFtZSxcbiAgICAgICAgICAgIGRpc3BsYXlOYW1lOiBuYW1lLFxuICAgICAgICAgICAgdHlwZTogJ3JlcXVpcmUnLFxuICAgICAgICAgIH0sXG4gICAgICAgICAgcmFua3MsXG4gICAgICAgICAgaW1wb3J0ZWQsXG4gICAgICAgICAgcGF0aEdyb3Vwc0V4Y2x1ZGVkSW1wb3J0VHlwZXNcbiAgICAgICAgKVxuICAgICAgfSxcbiAgICAgICdQcm9ncmFtOmV4aXQnOiBmdW5jdGlvbiByZXBvcnRBbmRSZXNldCgpIHtcbiAgICAgICAgaWYgKG5ld2xpbmVzQmV0d2VlbkltcG9ydHMgIT09ICdpZ25vcmUnKSB7XG4gICAgICAgICAgbWFrZU5ld2xpbmVzQmV0d2VlblJlcG9ydChjb250ZXh0LCBpbXBvcnRlZCwgbmV3bGluZXNCZXR3ZWVuSW1wb3J0cylcbiAgICAgICAgfVxuXG4gICAgICAgIGlmIChhbHBoYWJldGl6ZS5vcmRlciAhPT0gJ2lnbm9yZScpIHtcbiAgICAgICAgICBtdXRhdGVSYW5rc1RvQWxwaGFiZXRpemUoaW1wb3J0ZWQsIGFscGhhYmV0aXplKVxuICAgICAgICB9XG5cbiAgICAgICAgbWFrZU91dE9mT3JkZXJSZXBvcnQoY29udGV4dCwgaW1wb3J0ZWQpXG5cbiAgICAgICAgaW1wb3J0ZWQgPSBbXVxuICAgICAgfSxcbiAgICAgIEZ1bmN0aW9uRGVjbGFyYXRpb246IGluY3JlbWVudExldmVsLFxuICAgICAgRnVuY3Rpb25FeHByZXNzaW9uOiBpbmNyZW1lbnRMZXZlbCxcbiAgICAgIEFycm93RnVuY3Rpb25FeHByZXNzaW9uOiBpbmNyZW1lbnRMZXZlbCxcbiAgICAgIEJsb2NrU3RhdGVtZW50OiBpbmNyZW1lbnRMZXZlbCxcbiAgICAgIE9iamVjdEV4cHJlc3Npb246IGluY3JlbWVudExldmVsLFxuICAgICAgJ0Z1bmN0aW9uRGVjbGFyYXRpb246ZXhpdCc6IGRlY3JlbWVudExldmVsLFxuICAgICAgJ0Z1bmN0aW9uRXhwcmVzc2lvbjpleGl0JzogZGVjcmVtZW50TGV2ZWwsXG4gICAgICAnQXJyb3dGdW5jdGlvbkV4cHJlc3Npb246ZXhpdCc6IGRlY3JlbWVudExldmVsLFxuICAgICAgJ0Jsb2NrU3RhdGVtZW50OmV4aXQnOiBkZWNyZW1lbnRMZXZlbCxcbiAgICAgICdPYmplY3RFeHByZXNzaW9uOmV4aXQnOiBkZWNyZW1lbnRMZXZlbCxcbiAgICB9XG4gIH0sXG59XG4iXX0=