'use strict';var _slicedToArray = function () {function sliceIterator(arr, i) {var _arr = [];var _n = true;var _d = false;var _e = undefined;try {for (var _i = arr[Symbol.iterator](), _s; !(_n = (_s = _i.next()).done); _n = true) {_arr.push(_s.value);if (i && _arr.length === i) break;}} catch (err) {_d = true;_e = err;} finally {try {if (!_n && _i["return"]) _i["return"]();} finally {if (_d) throw _e;}}return _arr;}return function (arr, i) {if (Array.isArray(arr)) {return arr;} else if (Symbol.iterator in Object(arr)) {return sliceIterator(arr, i);} else {throw new TypeError("Invalid attempt to destructure non-iterable instance");}};}();

var _minimatch = require('minimatch');var _minimatch2 = _interopRequireDefault(_minimatch);
var _arrayIncludes = require('array-includes');var _arrayIncludes2 = _interopRequireDefault(_arrayIncludes);
var _object = require('object.groupby');var _object2 = _interopRequireDefault(_object);

var _importType = require('../core/importType');var _importType2 = _interopRequireDefault(_importType);
var _staticRequire = require('../core/staticRequire');var _staticRequire2 = _interopRequireDefault(_staticRequire);
var _docsUrl = require('../docsUrl');var _docsUrl2 = _interopRequireDefault(_docsUrl);function _interopRequireDefault(obj) {return obj && obj.__esModule ? obj : { 'default': obj };}

var defaultGroups = ['builtin', 'external', 'parent', 'sibling', 'index'];

// REPORTING AND FIXING

function reverse(array) {
  return array.map(function (v) {
    return Object.assign({}, v, { rank: -v.rank });
  }).reverse();
}

function getTokensOrCommentsAfter(sourceCode, node, count) {
  var currentNodeOrToken = node;
  var result = [];
  for (var i = 0; i < count; i++) {
    currentNodeOrToken = sourceCode.getTokenOrCommentAfter(currentNodeOrToken);
    if (currentNodeOrToken == null) {
      break;
    }
    result.push(currentNodeOrToken);
  }
  return result;
}

function getTokensOrCommentsBefore(sourceCode, node, count) {
  var currentNodeOrToken = node;
  var result = [];
  for (var i = 0; i < count; i++) {
    currentNodeOrToken = sourceCode.getTokenOrCommentBefore(currentNodeOrToken);
    if (currentNodeOrToken == null) {
      break;
    }
    result.push(currentNodeOrToken);
  }
  return result.reverse();
}

function takeTokensAfterWhile(sourceCode, node, condition) {
  var tokens = getTokensOrCommentsAfter(sourceCode, node, 100);
  var result = [];
  for (var i = 0; i < tokens.length; i++) {
    if (condition(tokens[i])) {
      result.push(tokens[i]);
    } else {
      break;
    }
  }
  return result;
}

function takeTokensBeforeWhile(sourceCode, node, condition) {
  var tokens = getTokensOrCommentsBefore(sourceCode, node, 100);
  var result = [];
  for (var i = tokens.length - 1; i >= 0; i--) {
    if (condition(tokens[i])) {
      result.push(tokens[i]);
    } else {
      break;
    }
  }
  return result.reverse();
}

function findOutOfOrder(imported) {
  if (imported.length === 0) {
    return [];
  }
  var maxSeenRankNode = imported[0];
  return imported.filter(function (importedModule) {
    var res = importedModule.rank < maxSeenRankNode.rank;
    if (maxSeenRankNode.rank < importedModule.rank) {
      maxSeenRankNode = importedModule;
    }
    return res;
  });
}

function findRootNode(node) {
  var parent = node;
  while (parent.parent != null && parent.parent.body == null) {
    parent = parent.parent;
  }
  return parent;
}

function commentOnSameLineAs(node) {
  return function (token) {return (token.type === 'Block' || token.type === 'Line') &&
    token.loc.start.line === token.loc.end.line &&
    token.loc.end.line === node.loc.end.line;};
}

function findEndOfLineWithComments(sourceCode, node) {
  var tokensToEndOfLine = takeTokensAfterWhile(sourceCode, node, commentOnSameLineAs(node));
  var endOfTokens = tokensToEndOfLine.length > 0 ?
  tokensToEndOfLine[tokensToEndOfLine.length - 1].range[1] :
  node.range[1];
  var result = endOfTokens;
  for (var i = endOfTokens; i < sourceCode.text.length; i++) {
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

function findStartOfLineWithComments(sourceCode, node) {
  var tokensToEndOfLine = takeTokensBeforeWhile(sourceCode, node, commentOnSameLineAs(node));
  var startOfTokens = tokensToEndOfLine.length > 0 ? tokensToEndOfLine[0].range[0] : node.range[0];
  var result = startOfTokens;
  for (var i = startOfTokens - 1; i > 0; i--) {
    if (sourceCode.text[i] !== ' ' && sourceCode.text[i] !== '\t') {
      break;
    }
    result = i;
  }
  return result;
}

function isRequireExpression(expr) {
  return expr != null &&
  expr.type === 'CallExpression' &&
  expr.callee != null &&
  expr.callee.name === 'require' &&
  expr.arguments != null &&
  expr.arguments.length === 1 &&
  expr.arguments[0].type === 'Literal';
}

function isSupportedRequireModule(node) {
  if (node.type !== 'VariableDeclaration') {
    return false;
  }
  if (node.declarations.length !== 1) {
    return false;
  }
  var decl = node.declarations[0];
  var isPlainRequire = decl.id && (
  decl.id.type === 'Identifier' || decl.id.type === 'ObjectPattern') &&
  isRequireExpression(decl.init);
  var isRequireWithMemberExpression = decl.id && (
  decl.id.type === 'Identifier' || decl.id.type === 'ObjectPattern') &&
  decl.init != null &&
  decl.init.type === 'CallExpression' &&
  decl.init.callee != null &&
  decl.init.callee.type === 'MemberExpression' &&
  isRequireExpression(decl.init.callee.object);
  return isPlainRequire || isRequireWithMemberExpression;
}

function isPlainImportModule(node) {
  return node.type === 'ImportDeclaration' && node.specifiers != null && node.specifiers.length > 0;
}

function isPlainImportEquals(node) {
  return node.type === 'TSImportEqualsDeclaration' && node.moduleReference.expression;
}

function canCrossNodeWhileReorder(node) {
  return isSupportedRequireModule(node) || isPlainImportModule(node) || isPlainImportEquals(node);
}

function canReorderItems(firstNode, secondNode) {
  var parent = firstNode.parent;var _sort =
  [
  parent.body.indexOf(firstNode),
  parent.body.indexOf(secondNode)].
  sort(),_sort2 = _slicedToArray(_sort, 2),firstIndex = _sort2[0],secondIndex = _sort2[1];
  var nodesBetween = parent.body.slice(firstIndex, secondIndex + 1);var _iteratorNormalCompletion = true;var _didIteratorError = false;var _iteratorError = undefined;try {
    for (var _iterator = nodesBetween[Symbol.iterator](), _step; !(_iteratorNormalCompletion = (_step = _iterator.next()).done); _iteratorNormalCompletion = true) {var nodeBetween = _step.value;
      if (!canCrossNodeWhileReorder(nodeBetween)) {
        return false;
      }
    }} catch (err) {_didIteratorError = true;_iteratorError = err;} finally {try {if (!_iteratorNormalCompletion && _iterator['return']) {_iterator['return']();}} finally {if (_didIteratorError) {throw _iteratorError;}}}
  return true;
}

function makeImportDescription(node) {
  if (node.node.importKind === 'type') {
    return 'type import';
  }
  if (node.node.importKind === 'typeof') {
    return 'typeof import';
  }
  return 'import';
}

function fixOutOfOrder(context, firstNode, secondNode, order) {
  var sourceCode = context.getSourceCode();

  var firstRoot = findRootNode(firstNode.node);
  var firstRootStart = findStartOfLineWithComments(sourceCode, firstRoot);
  var firstRootEnd = findEndOfLineWithComments(sourceCode, firstRoot);

  var secondRoot = findRootNode(secondNode.node);
  var secondRootStart = findStartOfLineWithComments(sourceCode, secondRoot);
  var secondRootEnd = findEndOfLineWithComments(sourceCode, secondRoot);
  var canFix = canReorderItems(firstRoot, secondRoot);

  var newCode = sourceCode.text.substring(secondRootStart, secondRootEnd);
  if (newCode[newCode.length - 1] !== '\n') {
    newCode = String(newCode) + '\n';
  }

  var firstImport = String(makeImportDescription(firstNode)) + ' of `' + String(firstNode.displayName) + '`';
  var secondImport = '`' + String(secondNode.displayName) + '` ' + String(makeImportDescription(secondNode));
  var message = secondImport + ' should occur ' + String(order) + ' ' + firstImport;

  if (order === 'before') {
    context.report({
      node: secondNode.node,
      message: message,
      fix: canFix && function (fixer) {return fixer.replaceTextRange(
        [firstRootStart, secondRootEnd],
        newCode + sourceCode.text.substring(firstRootStart, secondRootStart));} });


  } else if (order === 'after') {
    context.report({
      node: secondNode.node,
      message: message,
      fix: canFix && function (fixer) {return fixer.replaceTextRange(
        [secondRootStart, firstRootEnd],
        sourceCode.text.substring(secondRootEnd, firstRootEnd) + newCode);} });


  }
}

function reportOutOfOrder(context, imported, outOfOrder, order) {
  outOfOrder.forEach(function (imp) {
    var found = imported.find(function () {function hasHigherRank(importedItem) {
        return importedItem.rank > imp.rank;
      }return hasHigherRank;}());
    fixOutOfOrder(context, found, imp, order);
  });
}

function makeOutOfOrderReport(context, imported) {
  var outOfOrder = findOutOfOrder(imported);
  if (!outOfOrder.length) {
    return;
  }

  // There are things to report. Try to minimize the number of reported errors.
  var reversedImported = reverse(imported);
  var reversedOrder = findOutOfOrder(reversedImported);
  if (reversedOrder.length < outOfOrder.length) {
    reportOutOfOrder(context, reversedImported, reversedOrder, 'after');
    return;
  }
  reportOutOfOrder(context, imported, outOfOrder, 'before');
}

var compareString = function compareString(a, b) {
  if (a < b) {
    return -1;
  }
  if (a > b) {
    return 1;
  }
  return 0;
};

/** Some parsers (languages without types) don't provide ImportKind */
var DEAFULT_IMPORT_KIND = 'value';
var getNormalizedValue = function getNormalizedValue(node, toLowerCase) {
  var value = node.value;
  return toLowerCase ? String(value).toLowerCase() : value;
};

function getSorter(alphabetizeOptions) {
  var multiplier = alphabetizeOptions.order === 'asc' ? 1 : -1;
  var orderImportKind = alphabetizeOptions.orderImportKind;
  var multiplierImportKind = orderImportKind !== 'ignore' && (
  alphabetizeOptions.orderImportKind === 'asc' ? 1 : -1);

  return function () {function importsSorter(nodeA, nodeB) {
      var importA = getNormalizedValue(nodeA, alphabetizeOptions.caseInsensitive);
      var importB = getNormalizedValue(nodeB, alphabetizeOptions.caseInsensitive);
      var result = 0;

      if (!(0, _arrayIncludes2['default'])(importA, '/') && !(0, _arrayIncludes2['default'])(importB, '/')) {
        result = compareString(importA, importB);
      } else {
        var A = importA.split('/');
        var B = importB.split('/');
        var a = A.length;
        var b = B.length;

        for (var i = 0; i < Math.min(a, b); i++) {
          // Skip comparing the first path segment, if they are relative segments for both imports
          if (i === 0 && (A[i] === '.' || A[i] === '..') && (B[i] === '.' || B[i] === '..')) {
            // If one is sibling and the other parent import, no need to compare at all, since the paths belong in different groups
            if (A[i] !== B[i]) {break;}
            continue;
          }
          result = compareString(A[i], B[i]);
          if (result) {break;}
        }

        if (!result && a !== b) {
          result = a < b ? -1 : 1;
        }
      }

      result = result * multiplier;

      // In case the paths are equal (result === 0), sort them by importKind
      if (!result && multiplierImportKind) {
        result = multiplierImportKind * compareString(
        nodeA.node.importKind || DEAFULT_IMPORT_KIND,
        nodeB.node.importKind || DEAFULT_IMPORT_KIND);

      }

      return result;
    }return importsSorter;}();
}

function mutateRanksToAlphabetize(imported, alphabetizeOptions) {
  var groupedByRanks = (0, _object2['default'])(imported, function (item) {return item.rank;});

  var sorterFn = getSorter(alphabetizeOptions);

  // sort group keys so that they can be iterated on in order
  var groupRanks = Object.keys(groupedByRanks).sort(function (a, b) {
    return a - b;
  });

  // sort imports locally within their group
  groupRanks.forEach(function (groupRank) {
    groupedByRanks[groupRank].sort(sorterFn);
  });

  // assign globally unique rank to each import
  var newRank = 0;
  var alphabetizedRanks = groupRanks.reduce(function (acc, groupRank) {
    groupedByRanks[groupRank].forEach(function (importedItem) {
      acc[String(importedItem.value) + '|' + String(importedItem.node.importKind)] = parseInt(groupRank, 10) + newRank;
      newRank += 1;
    });
    return acc;
  }, {});

  // mutate the original group-rank with alphabetized-rank
  imported.forEach(function (importedItem) {
    importedItem.rank = alphabetizedRanks[String(importedItem.value) + '|' + String(importedItem.node.importKind)];
  });
}

// DETECTING

function computePathRank(ranks, pathGroups, path, maxPosition) {
  for (var i = 0, l = pathGroups.length; i < l; i++) {var _pathGroups$i =
    pathGroups[i],pattern = _pathGroups$i.pattern,patternOptions = _pathGroups$i.patternOptions,group = _pathGroups$i.group,_pathGroups$i$positio = _pathGroups$i.position,position = _pathGroups$i$positio === undefined ? 1 : _pathGroups$i$positio;
    if ((0, _minimatch2['default'])(path, pattern, patternOptions || { nocomment: true })) {
      return ranks[group] + position / maxPosition;
    }
  }
}

function computeRank(context, ranks, importEntry, excludedImportTypes) {
  var impType = void 0;
  var rank = void 0;
  if (importEntry.type === 'import:object') {
    impType = 'object';
  } else if (importEntry.node.importKind === 'type' && ranks.omittedTypes.indexOf('type') === -1) {
    impType = 'type';
  } else {
    impType = (0, _importType2['default'])(importEntry.value, context);
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
  var rank = computeRank(context, ranks, importEntry, excludedImportTypes);
  if (rank !== -1) {
    imported.push(Object.assign({}, importEntry, { rank: rank }));
  }
}

function getRequireBlock(node) {
  var n = node;
  // Handle cases like `const baz = require('foo').bar.baz`
  // and `const foo = require('foo')()`
  while (
  n.parent.type === 'MemberExpression' && n.parent.object === n ||
  n.parent.type === 'CallExpression' && n.parent.callee === n)
  {
    n = n.parent;
  }
  if (
  n.parent.type === 'VariableDeclarator' &&
  n.parent.parent.type === 'VariableDeclaration' &&
  n.parent.parent.parent.type === 'Program')
  {
    return n.parent.parent.parent;
  }
}

var types = ['builtin', 'external', 'internal', 'unknown', 'parent', 'sibling', 'index', 'object', 'type'];

// Creates an object with type-rank pairs.
// Example: { index: 0, sibling: 1, parent: 1, external: 1, builtin: 2, internal: 2 }
// Will throw an error if it contains a type that does not exist, or has a duplicate
function convertGroupsToRanks(groups) {
  var rankObject = groups.reduce(function (res, group, index) {
    [].concat(group).forEach(function (groupItem) {
      if (types.indexOf(groupItem) === -1) {
        throw new Error('Incorrect configuration of the rule: Unknown type `' + String(JSON.stringify(groupItem)) + '`');
      }
      if (res[groupItem] !== undefined) {
        throw new Error('Incorrect configuration of the rule: `' + String(groupItem) + '` is duplicated');
      }
      res[groupItem] = index * 2;
    });
    return res;
  }, {});

  var omittedTypes = types.filter(function (type) {
    return typeof rankObject[type] === 'undefined';
  });

  var ranks = omittedTypes.reduce(function (res, type) {
    res[type] = groups.length * 2;
    return res;
  }, rankObject);

  return { groups: ranks, omittedTypes: omittedTypes };
}

function convertPathGroupsForRanks(pathGroups) {
  var after = {};
  var before = {};

  var transformed = pathGroups.map(function (pathGroup, index) {var
    group = pathGroup.group,positionString = pathGroup.position;
    var position = 0;
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

    return Object.assign({}, pathGroup, { position: position });
  });

  var maxPosition = 1;

  Object.keys(before).forEach(function (group) {
    var groupLength = before[group].length;
    before[group].forEach(function (groupIndex, index) {
      transformed[groupIndex].position = -1 * (groupLength - index);
    });
    maxPosition = Math.max(maxPosition, groupLength);
  });

  Object.keys(after).forEach(function (key) {
    var groupNextPosition = after[key];
    maxPosition = Math.max(maxPosition, groupNextPosition - 1);
  });

  return {
    pathGroups: transformed,
    maxPosition: maxPosition > 10 ? Math.pow(10, Math.ceil(Math.log10(maxPosition))) : 10 };

}

function fixNewLineAfterImport(context, previousImport) {
  var prevRoot = findRootNode(previousImport.node);
  var tokensToEndOfLine = takeTokensAfterWhile(
  context.getSourceCode(), prevRoot, commentOnSameLineAs(prevRoot));

  var endOfLine = prevRoot.range[1];
  if (tokensToEndOfLine.length > 0) {
    endOfLine = tokensToEndOfLine[tokensToEndOfLine.length - 1].range[1];
  }
  return function (fixer) {return fixer.insertTextAfterRange([prevRoot.range[0], endOfLine], '\n');};
}

function removeNewLineAfterImport(context, currentImport, previousImport) {
  var sourceCode = context.getSourceCode();
  var prevRoot = findRootNode(previousImport.node);
  var currRoot = findRootNode(currentImport.node);
  var rangeToRemove = [
  findEndOfLineWithComments(sourceCode, prevRoot),
  findStartOfLineWithComments(sourceCode, currRoot)];

  if (/^\s*$/.test(sourceCode.text.substring(rangeToRemove[0], rangeToRemove[1]))) {
    return function (fixer) {return fixer.removeRange(rangeToRemove);};
  }
  return undefined;
}

function makeNewlinesBetweenReport(context, imported, newlinesBetweenImports, distinctGroup) {
  var getNumberOfEmptyLinesBetween = function getNumberOfEmptyLinesBetween(currentImport, previousImport) {
    var linesBetweenImports = context.getSourceCode().lines.slice(
    previousImport.node.loc.end.line,
    currentImport.node.loc.start.line - 1);


    return linesBetweenImports.filter(function (line) {return !line.trim().length;}).length;
  };
  var getIsStartOfDistinctGroup = function getIsStartOfDistinctGroup(currentImport, previousImport) {return currentImport.rank - 1 >= previousImport.rank;};
  var previousImport = imported[0];

  imported.slice(1).forEach(function (currentImport) {
    var emptyLinesBetween = getNumberOfEmptyLinesBetween(currentImport, previousImport);
    var isStartOfDistinctGroup = getIsStartOfDistinctGroup(currentImport, previousImport);

    if (newlinesBetweenImports === 'always' ||
    newlinesBetweenImports === 'always-and-inside-groups') {
      if (currentImport.rank !== previousImport.rank && emptyLinesBetween === 0) {
        if (distinctGroup || !distinctGroup && isStartOfDistinctGroup) {
          context.report({
            node: previousImport.node,
            message: 'There should be at least one empty line between import groups',
            fix: fixNewLineAfterImport(context, previousImport) });

        }
      } else if (emptyLinesBetween > 0 &&
      newlinesBetweenImports !== 'always-and-inside-groups') {
        if (distinctGroup && currentImport.rank === previousImport.rank || !distinctGroup && !isStartOfDistinctGroup) {
          context.report({
            node: previousImport.node,
            message: 'There should be no empty line within import group',
            fix: removeNewLineAfterImport(context, currentImport, previousImport) });

        }
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
  var alphabetize = options.alphabetize || {};
  var order = alphabetize.order || 'ignore';
  var orderImportKind = alphabetize.orderImportKind || 'ignore';
  var caseInsensitive = alphabetize.caseInsensitive || false;

  return { order: order, orderImportKind: orderImportKind, caseInsensitive: caseInsensitive };
}

// TODO, semver-major: Change the default of "distinctGroup" from true to false
var defaultDistinctGroup = true;

module.exports = {
  meta: {
    type: 'suggestion',
    docs: {
      category: 'Style guide',
      description: 'Enforce a convention in module import order.',
      url: (0, _docsUrl2['default'])('order') },


    fixable: 'code',
    schema: [
    {
      type: 'object',
      properties: {
        groups: {
          type: 'array' },

        pathGroupsExcludedImportTypes: {
          type: 'array' },

        distinctGroup: {
          type: 'boolean',
          'default': defaultDistinctGroup },

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
                'enum': types },

              position: {
                type: 'string',
                'enum': ['after', 'before'] } },


            additionalProperties: false,
            required: ['pattern', 'group'] } },


        'newlines-between': {
          'enum': [
          'ignore',
          'always',
          'always-and-inside-groups',
          'never'] },


        alphabetize: {
          type: 'object',
          properties: {
            caseInsensitive: {
              type: 'boolean',
              'default': false },

            order: {
              'enum': ['ignore', 'asc', 'desc'],
              'default': 'ignore' },

            orderImportKind: {
              'enum': ['ignore', 'asc', 'desc'],
              'default': 'ignore' } },


          additionalProperties: false },

        warnOnUnassignedImports: {
          type: 'boolean',
          'default': false } },


      additionalProperties: false }] },




  create: function () {function importOrderRule(context) {
      var options = context.options[0] || {};
      var newlinesBetweenImports = options['newlines-between'] || 'ignore';
      var pathGroupsExcludedImportTypes = new Set(options.pathGroupsExcludedImportTypes || ['builtin', 'external', 'object']);
      var alphabetize = getAlphabetizeConfig(options);
      var distinctGroup = options.distinctGroup == null ? defaultDistinctGroup : !!options.distinctGroup;
      var ranks = void 0;

      try {var _convertPathGroupsFor =
        convertPathGroupsForRanks(options.pathGroups || []),pathGroups = _convertPathGroupsFor.pathGroups,maxPosition = _convertPathGroupsFor.maxPosition;var _convertGroupsToRanks =
        convertGroupsToRanks(options.groups || defaultGroups),groups = _convertGroupsToRanks.groups,omittedTypes = _convertGroupsToRanks.omittedTypes;
        ranks = {
          groups: groups,
          omittedTypes: omittedTypes,
          pathGroups: pathGroups,
          maxPosition: maxPosition };

      } catch (error) {
        // Malformed configuration
        return {
          Program: function () {function Program(node) {
              context.report(node, error.message);
            }return Program;}() };

      }
      var importMap = new Map();

      function getBlockImports(node) {
        if (!importMap.has(node)) {
          importMap.set(node, []);
        }
        return importMap.get(node);
      }

      return {
        ImportDeclaration: function () {function handleImports(node) {
            // Ignoring unassigned imports unless warnOnUnassignedImports is set
            if (node.specifiers.length || options.warnOnUnassignedImports) {
              var name = node.source.value;
              registerNode(
              context,
              {
                node: node,
                value: name,
                displayName: name,
                type: 'import' },

              ranks,
              getBlockImports(node.parent),
              pathGroupsExcludedImportTypes);

            }
          }return handleImports;}(),
        TSImportEqualsDeclaration: function () {function handleImports(node) {
            var displayName = void 0;
            var value = void 0;
            var type = void 0;
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
              node: node,
              value: value,
              displayName: displayName,
              type: type },

            ranks,
            getBlockImports(node.parent),
            pathGroupsExcludedImportTypes);

          }return handleImports;}(),
        CallExpression: function () {function handleRequires(node) {
            if (!(0, _staticRequire2['default'])(node)) {
              return;
            }
            var block = getRequireBlock(node);
            if (!block) {
              return;
            }
            var name = node.arguments[0].value;
            registerNode(
            context,
            {
              node: node,
              value: name,
              displayName: name,
              type: 'require' },

            ranks,
            getBlockImports(block),
            pathGroupsExcludedImportTypes);

          }return handleRequires;}(),
        'Program:exit': function () {function reportAndReset() {
            importMap.forEach(function (imported) {
              if (newlinesBetweenImports !== 'ignore') {
                makeNewlinesBetweenReport(context, imported, newlinesBetweenImports, distinctGroup);
              }

              if (alphabetize.order !== 'ignore') {
                mutateRanksToAlphabetize(imported, alphabetize);
              }

              makeOutOfOrderReport(context, imported);
            });

            importMap.clear();
          }return reportAndReset;}() };

    }return importOrderRule;}() };
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIi4uLy4uL3NyYy9ydWxlcy9vcmRlci5qcyJdLCJuYW1lcyI6WyJkZWZhdWx0R3JvdXBzIiwicmV2ZXJzZSIsImFycmF5IiwibWFwIiwidiIsInJhbmsiLCJnZXRUb2tlbnNPckNvbW1lbnRzQWZ0ZXIiLCJzb3VyY2VDb2RlIiwibm9kZSIsImNvdW50IiwiY3VycmVudE5vZGVPclRva2VuIiwicmVzdWx0IiwiaSIsImdldFRva2VuT3JDb21tZW50QWZ0ZXIiLCJwdXNoIiwiZ2V0VG9rZW5zT3JDb21tZW50c0JlZm9yZSIsImdldFRva2VuT3JDb21tZW50QmVmb3JlIiwidGFrZVRva2Vuc0FmdGVyV2hpbGUiLCJjb25kaXRpb24iLCJ0b2tlbnMiLCJsZW5ndGgiLCJ0YWtlVG9rZW5zQmVmb3JlV2hpbGUiLCJmaW5kT3V0T2ZPcmRlciIsImltcG9ydGVkIiwibWF4U2VlblJhbmtOb2RlIiwiZmlsdGVyIiwiaW1wb3J0ZWRNb2R1bGUiLCJyZXMiLCJmaW5kUm9vdE5vZGUiLCJwYXJlbnQiLCJib2R5IiwiY29tbWVudE9uU2FtZUxpbmVBcyIsInRva2VuIiwidHlwZSIsImxvYyIsInN0YXJ0IiwibGluZSIsImVuZCIsImZpbmRFbmRPZkxpbmVXaXRoQ29tbWVudHMiLCJ0b2tlbnNUb0VuZE9mTGluZSIsImVuZE9mVG9rZW5zIiwicmFuZ2UiLCJ0ZXh0IiwiZmluZFN0YXJ0T2ZMaW5lV2l0aENvbW1lbnRzIiwic3RhcnRPZlRva2VucyIsImlzUmVxdWlyZUV4cHJlc3Npb24iLCJleHByIiwiY2FsbGVlIiwibmFtZSIsImFyZ3VtZW50cyIsImlzU3VwcG9ydGVkUmVxdWlyZU1vZHVsZSIsImRlY2xhcmF0aW9ucyIsImRlY2wiLCJpc1BsYWluUmVxdWlyZSIsImlkIiwiaW5pdCIsImlzUmVxdWlyZVdpdGhNZW1iZXJFeHByZXNzaW9uIiwib2JqZWN0IiwiaXNQbGFpbkltcG9ydE1vZHVsZSIsInNwZWNpZmllcnMiLCJpc1BsYWluSW1wb3J0RXF1YWxzIiwibW9kdWxlUmVmZXJlbmNlIiwiZXhwcmVzc2lvbiIsImNhbkNyb3NzTm9kZVdoaWxlUmVvcmRlciIsImNhblJlb3JkZXJJdGVtcyIsImZpcnN0Tm9kZSIsInNlY29uZE5vZGUiLCJpbmRleE9mIiwic29ydCIsImZpcnN0SW5kZXgiLCJzZWNvbmRJbmRleCIsIm5vZGVzQmV0d2VlbiIsInNsaWNlIiwibm9kZUJldHdlZW4iLCJtYWtlSW1wb3J0RGVzY3JpcHRpb24iLCJpbXBvcnRLaW5kIiwiZml4T3V0T2ZPcmRlciIsImNvbnRleHQiLCJvcmRlciIsImdldFNvdXJjZUNvZGUiLCJmaXJzdFJvb3QiLCJmaXJzdFJvb3RTdGFydCIsImZpcnN0Um9vdEVuZCIsInNlY29uZFJvb3QiLCJzZWNvbmRSb290U3RhcnQiLCJzZWNvbmRSb290RW5kIiwiY2FuRml4IiwibmV3Q29kZSIsInN1YnN0cmluZyIsImZpcnN0SW1wb3J0IiwiZGlzcGxheU5hbWUiLCJzZWNvbmRJbXBvcnQiLCJtZXNzYWdlIiwicmVwb3J0IiwiZml4IiwiZml4ZXIiLCJyZXBsYWNlVGV4dFJhbmdlIiwicmVwb3J0T3V0T2ZPcmRlciIsIm91dE9mT3JkZXIiLCJmb3JFYWNoIiwiaW1wIiwiZm91bmQiLCJmaW5kIiwiaGFzSGlnaGVyUmFuayIsImltcG9ydGVkSXRlbSIsIm1ha2VPdXRPZk9yZGVyUmVwb3J0IiwicmV2ZXJzZWRJbXBvcnRlZCIsInJldmVyc2VkT3JkZXIiLCJjb21wYXJlU3RyaW5nIiwiYSIsImIiLCJERUFGVUxUX0lNUE9SVF9LSU5EIiwiZ2V0Tm9ybWFsaXplZFZhbHVlIiwidG9Mb3dlckNhc2UiLCJ2YWx1ZSIsIlN0cmluZyIsImdldFNvcnRlciIsImFscGhhYmV0aXplT3B0aW9ucyIsIm11bHRpcGxpZXIiLCJvcmRlckltcG9ydEtpbmQiLCJtdWx0aXBsaWVySW1wb3J0S2luZCIsImltcG9ydHNTb3J0ZXIiLCJub2RlQSIsIm5vZGVCIiwiaW1wb3J0QSIsImNhc2VJbnNlbnNpdGl2ZSIsImltcG9ydEIiLCJBIiwic3BsaXQiLCJCIiwiTWF0aCIsIm1pbiIsIm11dGF0ZVJhbmtzVG9BbHBoYWJldGl6ZSIsImdyb3VwZWRCeVJhbmtzIiwiaXRlbSIsInNvcnRlckZuIiwiZ3JvdXBSYW5rcyIsIk9iamVjdCIsImtleXMiLCJncm91cFJhbmsiLCJuZXdSYW5rIiwiYWxwaGFiZXRpemVkUmFua3MiLCJyZWR1Y2UiLCJhY2MiLCJwYXJzZUludCIsImNvbXB1dGVQYXRoUmFuayIsInJhbmtzIiwicGF0aEdyb3VwcyIsInBhdGgiLCJtYXhQb3NpdGlvbiIsImwiLCJwYXR0ZXJuIiwicGF0dGVybk9wdGlvbnMiLCJncm91cCIsInBvc2l0aW9uIiwibm9jb21tZW50IiwiY29tcHV0ZVJhbmsiLCJpbXBvcnRFbnRyeSIsImV4Y2x1ZGVkSW1wb3J0VHlwZXMiLCJpbXBUeXBlIiwib21pdHRlZFR5cGVzIiwiaGFzIiwiZ3JvdXBzIiwic3RhcnRzV2l0aCIsInJlZ2lzdGVyTm9kZSIsImdldFJlcXVpcmVCbG9jayIsIm4iLCJ0eXBlcyIsImNvbnZlcnRHcm91cHNUb1JhbmtzIiwicmFua09iamVjdCIsImluZGV4IiwiY29uY2F0IiwiZ3JvdXBJdGVtIiwiRXJyb3IiLCJKU09OIiwic3RyaW5naWZ5IiwidW5kZWZpbmVkIiwiY29udmVydFBhdGhHcm91cHNGb3JSYW5rcyIsImFmdGVyIiwiYmVmb3JlIiwidHJhbnNmb3JtZWQiLCJwYXRoR3JvdXAiLCJwb3NpdGlvblN0cmluZyIsImdyb3VwTGVuZ3RoIiwiZ3JvdXBJbmRleCIsIm1heCIsImtleSIsImdyb3VwTmV4dFBvc2l0aW9uIiwicG93IiwiY2VpbCIsImxvZzEwIiwiZml4TmV3TGluZUFmdGVySW1wb3J0IiwicHJldmlvdXNJbXBvcnQiLCJwcmV2Um9vdCIsImVuZE9mTGluZSIsImluc2VydFRleHRBZnRlclJhbmdlIiwicmVtb3ZlTmV3TGluZUFmdGVySW1wb3J0IiwiY3VycmVudEltcG9ydCIsImN1cnJSb290IiwicmFuZ2VUb1JlbW92ZSIsInRlc3QiLCJyZW1vdmVSYW5nZSIsIm1ha2VOZXdsaW5lc0JldHdlZW5SZXBvcnQiLCJuZXdsaW5lc0JldHdlZW5JbXBvcnRzIiwiZGlzdGluY3RHcm91cCIsImdldE51bWJlck9mRW1wdHlMaW5lc0JldHdlZW4iLCJsaW5lc0JldHdlZW5JbXBvcnRzIiwibGluZXMiLCJ0cmltIiwiZ2V0SXNTdGFydE9mRGlzdGluY3RHcm91cCIsImVtcHR5TGluZXNCZXR3ZWVuIiwiaXNTdGFydE9mRGlzdGluY3RHcm91cCIsImdldEFscGhhYmV0aXplQ29uZmlnIiwib3B0aW9ucyIsImFscGhhYmV0aXplIiwiZGVmYXVsdERpc3RpbmN0R3JvdXAiLCJtb2R1bGUiLCJleHBvcnRzIiwibWV0YSIsImRvY3MiLCJjYXRlZ29yeSIsImRlc2NyaXB0aW9uIiwidXJsIiwiZml4YWJsZSIsInNjaGVtYSIsInByb3BlcnRpZXMiLCJwYXRoR3JvdXBzRXhjbHVkZWRJbXBvcnRUeXBlcyIsIml0ZW1zIiwiYWRkaXRpb25hbFByb3BlcnRpZXMiLCJyZXF1aXJlZCIsIndhcm5PblVuYXNzaWduZWRJbXBvcnRzIiwiY3JlYXRlIiwiaW1wb3J0T3JkZXJSdWxlIiwiU2V0IiwiZXJyb3IiLCJQcm9ncmFtIiwiaW1wb3J0TWFwIiwiTWFwIiwiZ2V0QmxvY2tJbXBvcnRzIiwic2V0IiwiZ2V0IiwiSW1wb3J0RGVjbGFyYXRpb24iLCJoYW5kbGVJbXBvcnRzIiwic291cmNlIiwiVFNJbXBvcnRFcXVhbHNEZWNsYXJhdGlvbiIsImlzRXhwb3J0IiwiZ2V0VGV4dCIsIkNhbGxFeHByZXNzaW9uIiwiaGFuZGxlUmVxdWlyZXMiLCJibG9jayIsInJlcG9ydEFuZFJlc2V0IiwiY2xlYXIiXSwibWFwcGluZ3MiOiJBQUFBLGE7O0FBRUEsc0M7QUFDQSwrQztBQUNBLHdDOztBQUVBLGdEO0FBQ0Esc0Q7QUFDQSxxQzs7QUFFQSxJQUFNQSxnQkFBZ0IsQ0FBQyxTQUFELEVBQVksVUFBWixFQUF3QixRQUF4QixFQUFrQyxTQUFsQyxFQUE2QyxPQUE3QyxDQUF0Qjs7QUFFQTs7QUFFQSxTQUFTQyxPQUFULENBQWlCQyxLQUFqQixFQUF3QjtBQUN0QixTQUFPQSxNQUFNQyxHQUFOLENBQVUsVUFBVUMsQ0FBVixFQUFhO0FBQzVCLDZCQUFZQSxDQUFaLElBQWVDLE1BQU0sQ0FBQ0QsRUFBRUMsSUFBeEI7QUFDRCxHQUZNLEVBRUpKLE9BRkksRUFBUDtBQUdEOztBQUVELFNBQVNLLHdCQUFULENBQWtDQyxVQUFsQyxFQUE4Q0MsSUFBOUMsRUFBb0RDLEtBQXBELEVBQTJEO0FBQ3pELE1BQUlDLHFCQUFxQkYsSUFBekI7QUFDQSxNQUFNRyxTQUFTLEVBQWY7QUFDQSxPQUFLLElBQUlDLElBQUksQ0FBYixFQUFnQkEsSUFBSUgsS0FBcEIsRUFBMkJHLEdBQTNCLEVBQWdDO0FBQzlCRix5QkFBcUJILFdBQVdNLHNCQUFYLENBQWtDSCxrQkFBbEMsQ0FBckI7QUFDQSxRQUFJQSxzQkFBc0IsSUFBMUIsRUFBZ0M7QUFDOUI7QUFDRDtBQUNEQyxXQUFPRyxJQUFQLENBQVlKLGtCQUFaO0FBQ0Q7QUFDRCxTQUFPQyxNQUFQO0FBQ0Q7O0FBRUQsU0FBU0kseUJBQVQsQ0FBbUNSLFVBQW5DLEVBQStDQyxJQUEvQyxFQUFxREMsS0FBckQsRUFBNEQ7QUFDMUQsTUFBSUMscUJBQXFCRixJQUF6QjtBQUNBLE1BQU1HLFNBQVMsRUFBZjtBQUNBLE9BQUssSUFBSUMsSUFBSSxDQUFiLEVBQWdCQSxJQUFJSCxLQUFwQixFQUEyQkcsR0FBM0IsRUFBZ0M7QUFDOUJGLHlCQUFxQkgsV0FBV1MsdUJBQVgsQ0FBbUNOLGtCQUFuQyxDQUFyQjtBQUNBLFFBQUlBLHNCQUFzQixJQUExQixFQUFnQztBQUM5QjtBQUNEO0FBQ0RDLFdBQU9HLElBQVAsQ0FBWUosa0JBQVo7QUFDRDtBQUNELFNBQU9DLE9BQU9WLE9BQVAsRUFBUDtBQUNEOztBQUVELFNBQVNnQixvQkFBVCxDQUE4QlYsVUFBOUIsRUFBMENDLElBQTFDLEVBQWdEVSxTQUFoRCxFQUEyRDtBQUN6RCxNQUFNQyxTQUFTYix5QkFBeUJDLFVBQXpCLEVBQXFDQyxJQUFyQyxFQUEyQyxHQUEzQyxDQUFmO0FBQ0EsTUFBTUcsU0FBUyxFQUFmO0FBQ0EsT0FBSyxJQUFJQyxJQUFJLENBQWIsRUFBZ0JBLElBQUlPLE9BQU9DLE1BQTNCLEVBQW1DUixHQUFuQyxFQUF3QztBQUN0QyxRQUFJTSxVQUFVQyxPQUFPUCxDQUFQLENBQVYsQ0FBSixFQUEwQjtBQUN4QkQsYUFBT0csSUFBUCxDQUFZSyxPQUFPUCxDQUFQLENBQVo7QUFDRCxLQUZELE1BRU87QUFDTDtBQUNEO0FBQ0Y7QUFDRCxTQUFPRCxNQUFQO0FBQ0Q7O0FBRUQsU0FBU1UscUJBQVQsQ0FBK0JkLFVBQS9CLEVBQTJDQyxJQUEzQyxFQUFpRFUsU0FBakQsRUFBNEQ7QUFDMUQsTUFBTUMsU0FBU0osMEJBQTBCUixVQUExQixFQUFzQ0MsSUFBdEMsRUFBNEMsR0FBNUMsQ0FBZjtBQUNBLE1BQU1HLFNBQVMsRUFBZjtBQUNBLE9BQUssSUFBSUMsSUFBSU8sT0FBT0MsTUFBUCxHQUFnQixDQUE3QixFQUFnQ1IsS0FBSyxDQUFyQyxFQUF3Q0EsR0FBeEMsRUFBNkM7QUFDM0MsUUFBSU0sVUFBVUMsT0FBT1AsQ0FBUCxDQUFWLENBQUosRUFBMEI7QUFDeEJELGFBQU9HLElBQVAsQ0FBWUssT0FBT1AsQ0FBUCxDQUFaO0FBQ0QsS0FGRCxNQUVPO0FBQ0w7QUFDRDtBQUNGO0FBQ0QsU0FBT0QsT0FBT1YsT0FBUCxFQUFQO0FBQ0Q7O0FBRUQsU0FBU3FCLGNBQVQsQ0FBd0JDLFFBQXhCLEVBQWtDO0FBQ2hDLE1BQUlBLFNBQVNILE1BQVQsS0FBb0IsQ0FBeEIsRUFBMkI7QUFDekIsV0FBTyxFQUFQO0FBQ0Q7QUFDRCxNQUFJSSxrQkFBa0JELFNBQVMsQ0FBVCxDQUF0QjtBQUNBLFNBQU9BLFNBQVNFLE1BQVQsQ0FBZ0IsVUFBVUMsY0FBVixFQUEwQjtBQUMvQyxRQUFNQyxNQUFNRCxlQUFlckIsSUFBZixHQUFzQm1CLGdCQUFnQm5CLElBQWxEO0FBQ0EsUUFBSW1CLGdCQUFnQm5CLElBQWhCLEdBQXVCcUIsZUFBZXJCLElBQTFDLEVBQWdEO0FBQzlDbUIsd0JBQWtCRSxjQUFsQjtBQUNEO0FBQ0QsV0FBT0MsR0FBUDtBQUNELEdBTk0sQ0FBUDtBQU9EOztBQUVELFNBQVNDLFlBQVQsQ0FBc0JwQixJQUF0QixFQUE0QjtBQUMxQixNQUFJcUIsU0FBU3JCLElBQWI7QUFDQSxTQUFPcUIsT0FBT0EsTUFBUCxJQUFpQixJQUFqQixJQUF5QkEsT0FBT0EsTUFBUCxDQUFjQyxJQUFkLElBQXNCLElBQXRELEVBQTREO0FBQzFERCxhQUFTQSxPQUFPQSxNQUFoQjtBQUNEO0FBQ0QsU0FBT0EsTUFBUDtBQUNEOztBQUVELFNBQVNFLG1CQUFULENBQTZCdkIsSUFBN0IsRUFBbUM7QUFDakMsU0FBTyxVQUFDd0IsS0FBRCxVQUFXLENBQUNBLE1BQU1DLElBQU4sS0FBZSxPQUFmLElBQTJCRCxNQUFNQyxJQUFOLEtBQWUsTUFBM0M7QUFDWEQsVUFBTUUsR0FBTixDQUFVQyxLQUFWLENBQWdCQyxJQUFoQixLQUF5QkosTUFBTUUsR0FBTixDQUFVRyxHQUFWLENBQWNELElBRDVCO0FBRVhKLFVBQU1FLEdBQU4sQ0FBVUcsR0FBVixDQUFjRCxJQUFkLEtBQXVCNUIsS0FBSzBCLEdBQUwsQ0FBU0csR0FBVCxDQUFhRCxJQUZwQyxFQUFQO0FBR0Q7O0FBRUQsU0FBU0UseUJBQVQsQ0FBbUMvQixVQUFuQyxFQUErQ0MsSUFBL0MsRUFBcUQ7QUFDbkQsTUFBTStCLG9CQUFvQnRCLHFCQUFxQlYsVUFBckIsRUFBaUNDLElBQWpDLEVBQXVDdUIsb0JBQW9CdkIsSUFBcEIsQ0FBdkMsQ0FBMUI7QUFDQSxNQUFNZ0MsY0FBY0Qsa0JBQWtCbkIsTUFBbEIsR0FBMkIsQ0FBM0I7QUFDaEJtQixvQkFBa0JBLGtCQUFrQm5CLE1BQWxCLEdBQTJCLENBQTdDLEVBQWdEcUIsS0FBaEQsQ0FBc0QsQ0FBdEQsQ0FEZ0I7QUFFaEJqQyxPQUFLaUMsS0FBTCxDQUFXLENBQVgsQ0FGSjtBQUdBLE1BQUk5QixTQUFTNkIsV0FBYjtBQUNBLE9BQUssSUFBSTVCLElBQUk0QixXQUFiLEVBQTBCNUIsSUFBSUwsV0FBV21DLElBQVgsQ0FBZ0J0QixNQUE5QyxFQUFzRFIsR0FBdEQsRUFBMkQ7QUFDekQsUUFBSUwsV0FBV21DLElBQVgsQ0FBZ0I5QixDQUFoQixNQUF1QixJQUEzQixFQUFpQztBQUMvQkQsZUFBU0MsSUFBSSxDQUFiO0FBQ0E7QUFDRDtBQUNELFFBQUlMLFdBQVdtQyxJQUFYLENBQWdCOUIsQ0FBaEIsTUFBdUIsR0FBdkIsSUFBOEJMLFdBQVdtQyxJQUFYLENBQWdCOUIsQ0FBaEIsTUFBdUIsSUFBckQsSUFBNkRMLFdBQVdtQyxJQUFYLENBQWdCOUIsQ0FBaEIsTUFBdUIsSUFBeEYsRUFBOEY7QUFDNUY7QUFDRDtBQUNERCxhQUFTQyxJQUFJLENBQWI7QUFDRDtBQUNELFNBQU9ELE1BQVA7QUFDRDs7QUFFRCxTQUFTZ0MsMkJBQVQsQ0FBcUNwQyxVQUFyQyxFQUFpREMsSUFBakQsRUFBdUQ7QUFDckQsTUFBTStCLG9CQUFvQmxCLHNCQUFzQmQsVUFBdEIsRUFBa0NDLElBQWxDLEVBQXdDdUIsb0JBQW9CdkIsSUFBcEIsQ0FBeEMsQ0FBMUI7QUFDQSxNQUFNb0MsZ0JBQWdCTCxrQkFBa0JuQixNQUFsQixHQUEyQixDQUEzQixHQUErQm1CLGtCQUFrQixDQUFsQixFQUFxQkUsS0FBckIsQ0FBMkIsQ0FBM0IsQ0FBL0IsR0FBK0RqQyxLQUFLaUMsS0FBTCxDQUFXLENBQVgsQ0FBckY7QUFDQSxNQUFJOUIsU0FBU2lDLGFBQWI7QUFDQSxPQUFLLElBQUloQyxJQUFJZ0MsZ0JBQWdCLENBQTdCLEVBQWdDaEMsSUFBSSxDQUFwQyxFQUF1Q0EsR0FBdkMsRUFBNEM7QUFDMUMsUUFBSUwsV0FBV21DLElBQVgsQ0FBZ0I5QixDQUFoQixNQUF1QixHQUF2QixJQUE4QkwsV0FBV21DLElBQVgsQ0FBZ0I5QixDQUFoQixNQUF1QixJQUF6RCxFQUErRDtBQUM3RDtBQUNEO0FBQ0RELGFBQVNDLENBQVQ7QUFDRDtBQUNELFNBQU9ELE1BQVA7QUFDRDs7QUFFRCxTQUFTa0MsbUJBQVQsQ0FBNkJDLElBQTdCLEVBQW1DO0FBQ2pDLFNBQU9BLFFBQVEsSUFBUjtBQUNGQSxPQUFLYixJQUFMLEtBQWMsZ0JBRFo7QUFFRmEsT0FBS0MsTUFBTCxJQUFlLElBRmI7QUFHRkQsT0FBS0MsTUFBTCxDQUFZQyxJQUFaLEtBQXFCLFNBSG5CO0FBSUZGLE9BQUtHLFNBQUwsSUFBa0IsSUFKaEI7QUFLRkgsT0FBS0csU0FBTCxDQUFlN0IsTUFBZixLQUEwQixDQUx4QjtBQU1GMEIsT0FBS0csU0FBTCxDQUFlLENBQWYsRUFBa0JoQixJQUFsQixLQUEyQixTQU5oQztBQU9EOztBQUVELFNBQVNpQix3QkFBVCxDQUFrQzFDLElBQWxDLEVBQXdDO0FBQ3RDLE1BQUlBLEtBQUt5QixJQUFMLEtBQWMscUJBQWxCLEVBQXlDO0FBQ3ZDLFdBQU8sS0FBUDtBQUNEO0FBQ0QsTUFBSXpCLEtBQUsyQyxZQUFMLENBQWtCL0IsTUFBbEIsS0FBNkIsQ0FBakMsRUFBb0M7QUFDbEMsV0FBTyxLQUFQO0FBQ0Q7QUFDRCxNQUFNZ0MsT0FBTzVDLEtBQUsyQyxZQUFMLENBQWtCLENBQWxCLENBQWI7QUFDQSxNQUFNRSxpQkFBaUJELEtBQUtFLEVBQUw7QUFDakJGLE9BQUtFLEVBQUwsQ0FBUXJCLElBQVIsS0FBaUIsWUFBakIsSUFBaUNtQixLQUFLRSxFQUFMLENBQVFyQixJQUFSLEtBQWlCLGVBRGpDO0FBRWxCWSxzQkFBb0JPLEtBQUtHLElBQXpCLENBRkw7QUFHQSxNQUFNQyxnQ0FBZ0NKLEtBQUtFLEVBQUw7QUFDaENGLE9BQUtFLEVBQUwsQ0FBUXJCLElBQVIsS0FBaUIsWUFBakIsSUFBaUNtQixLQUFLRSxFQUFMLENBQVFyQixJQUFSLEtBQWlCLGVBRGxCO0FBRWpDbUIsT0FBS0csSUFBTCxJQUFhLElBRm9CO0FBR2pDSCxPQUFLRyxJQUFMLENBQVV0QixJQUFWLEtBQW1CLGdCQUhjO0FBSWpDbUIsT0FBS0csSUFBTCxDQUFVUixNQUFWLElBQW9CLElBSmE7QUFLakNLLE9BQUtHLElBQUwsQ0FBVVIsTUFBVixDQUFpQmQsSUFBakIsS0FBMEIsa0JBTE87QUFNakNZLHNCQUFvQk8sS0FBS0csSUFBTCxDQUFVUixNQUFWLENBQWlCVSxNQUFyQyxDQU5MO0FBT0EsU0FBT0osa0JBQWtCRyw2QkFBekI7QUFDRDs7QUFFRCxTQUFTRSxtQkFBVCxDQUE2QmxELElBQTdCLEVBQW1DO0FBQ2pDLFNBQU9BLEtBQUt5QixJQUFMLEtBQWMsbUJBQWQsSUFBcUN6QixLQUFLbUQsVUFBTCxJQUFtQixJQUF4RCxJQUFnRW5ELEtBQUttRCxVQUFMLENBQWdCdkMsTUFBaEIsR0FBeUIsQ0FBaEc7QUFDRDs7QUFFRCxTQUFTd0MsbUJBQVQsQ0FBNkJwRCxJQUE3QixFQUFtQztBQUNqQyxTQUFPQSxLQUFLeUIsSUFBTCxLQUFjLDJCQUFkLElBQTZDekIsS0FBS3FELGVBQUwsQ0FBcUJDLFVBQXpFO0FBQ0Q7O0FBRUQsU0FBU0Msd0JBQVQsQ0FBa0N2RCxJQUFsQyxFQUF3QztBQUN0QyxTQUFPMEMseUJBQXlCMUMsSUFBekIsS0FBa0NrRCxvQkFBb0JsRCxJQUFwQixDQUFsQyxJQUErRG9ELG9CQUFvQnBELElBQXBCLENBQXRFO0FBQ0Q7O0FBRUQsU0FBU3dELGVBQVQsQ0FBeUJDLFNBQXpCLEVBQW9DQyxVQUFwQyxFQUFnRDtBQUM5QyxNQUFNckMsU0FBU29DLFVBQVVwQyxNQUF6QixDQUQ4QztBQUVaO0FBQ2hDQSxTQUFPQyxJQUFQLENBQVlxQyxPQUFaLENBQW9CRixTQUFwQixDQURnQztBQUVoQ3BDLFNBQU9DLElBQVAsQ0FBWXFDLE9BQVosQ0FBb0JELFVBQXBCLENBRmdDO0FBR2hDRSxNQUhnQyxFQUZZLG1DQUV2Q0MsVUFGdUMsYUFFM0JDLFdBRjJCO0FBTTlDLE1BQU1DLGVBQWUxQyxPQUFPQyxJQUFQLENBQVkwQyxLQUFaLENBQWtCSCxVQUFsQixFQUE4QkMsY0FBYyxDQUE1QyxDQUFyQixDQU44QztBQU85Qyx5QkFBMEJDLFlBQTFCLDhIQUF3QyxLQUE3QkUsV0FBNkI7QUFDdEMsVUFBSSxDQUFDVix5QkFBeUJVLFdBQXpCLENBQUwsRUFBNEM7QUFDMUMsZUFBTyxLQUFQO0FBQ0Q7QUFDRixLQVg2QztBQVk5QyxTQUFPLElBQVA7QUFDRDs7QUFFRCxTQUFTQyxxQkFBVCxDQUErQmxFLElBQS9CLEVBQXFDO0FBQ25DLE1BQUlBLEtBQUtBLElBQUwsQ0FBVW1FLFVBQVYsS0FBeUIsTUFBN0IsRUFBcUM7QUFDbkMsV0FBTyxhQUFQO0FBQ0Q7QUFDRCxNQUFJbkUsS0FBS0EsSUFBTCxDQUFVbUUsVUFBVixLQUF5QixRQUE3QixFQUF1QztBQUNyQyxXQUFPLGVBQVA7QUFDRDtBQUNELFNBQU8sUUFBUDtBQUNEOztBQUVELFNBQVNDLGFBQVQsQ0FBdUJDLE9BQXZCLEVBQWdDWixTQUFoQyxFQUEyQ0MsVUFBM0MsRUFBdURZLEtBQXZELEVBQThEO0FBQzVELE1BQU12RSxhQUFhc0UsUUFBUUUsYUFBUixFQUFuQjs7QUFFQSxNQUFNQyxZQUFZcEQsYUFBYXFDLFVBQVV6RCxJQUF2QixDQUFsQjtBQUNBLE1BQU15RSxpQkFBaUJ0Qyw0QkFBNEJwQyxVQUE1QixFQUF3Q3lFLFNBQXhDLENBQXZCO0FBQ0EsTUFBTUUsZUFBZTVDLDBCQUEwQi9CLFVBQTFCLEVBQXNDeUUsU0FBdEMsQ0FBckI7O0FBRUEsTUFBTUcsYUFBYXZELGFBQWFzQyxXQUFXMUQsSUFBeEIsQ0FBbkI7QUFDQSxNQUFNNEUsa0JBQWtCekMsNEJBQTRCcEMsVUFBNUIsRUFBd0M0RSxVQUF4QyxDQUF4QjtBQUNBLE1BQU1FLGdCQUFnQi9DLDBCQUEwQi9CLFVBQTFCLEVBQXNDNEUsVUFBdEMsQ0FBdEI7QUFDQSxNQUFNRyxTQUFTdEIsZ0JBQWdCZ0IsU0FBaEIsRUFBMkJHLFVBQTNCLENBQWY7O0FBRUEsTUFBSUksVUFBVWhGLFdBQVdtQyxJQUFYLENBQWdCOEMsU0FBaEIsQ0FBMEJKLGVBQTFCLEVBQTJDQyxhQUEzQyxDQUFkO0FBQ0EsTUFBSUUsUUFBUUEsUUFBUW5FLE1BQVIsR0FBaUIsQ0FBekIsTUFBZ0MsSUFBcEMsRUFBMEM7QUFDeENtRSxxQkFBYUEsT0FBYjtBQUNEOztBQUVELE1BQU1FLHFCQUFpQmYsc0JBQXNCVCxTQUF0QixDQUFqQixxQkFBMERBLFVBQVV5QixXQUFwRSxPQUFOO0FBQ0EsTUFBTUMsNEJBQW9CekIsV0FBV3dCLFdBQS9CLGtCQUFnRGhCLHNCQUFzQlIsVUFBdEIsQ0FBaEQsQ0FBTjtBQUNBLE1BQU0wQixVQUFhRCxZQUFiLDZCQUEwQ2IsS0FBMUMsVUFBbURXLFdBQXpEOztBQUVBLE1BQUlYLFVBQVUsUUFBZCxFQUF3QjtBQUN0QkQsWUFBUWdCLE1BQVIsQ0FBZTtBQUNickYsWUFBTTBELFdBQVcxRCxJQURKO0FBRWJvRixzQkFGYTtBQUdiRSxXQUFLUixVQUFXLFVBQUNTLEtBQUQsVUFBV0EsTUFBTUMsZ0JBQU47QUFDekIsU0FBQ2YsY0FBRCxFQUFpQkksYUFBakIsQ0FEeUI7QUFFekJFLGtCQUFVaEYsV0FBV21DLElBQVgsQ0FBZ0I4QyxTQUFoQixDQUEwQlAsY0FBMUIsRUFBMENHLGVBQTFDLENBRmUsQ0FBWCxFQUhILEVBQWY7OztBQVFELEdBVEQsTUFTTyxJQUFJTixVQUFVLE9BQWQsRUFBdUI7QUFDNUJELFlBQVFnQixNQUFSLENBQWU7QUFDYnJGLFlBQU0wRCxXQUFXMUQsSUFESjtBQUVib0Ysc0JBRmE7QUFHYkUsV0FBS1IsVUFBVyxVQUFDUyxLQUFELFVBQVdBLE1BQU1DLGdCQUFOO0FBQ3pCLFNBQUNaLGVBQUQsRUFBa0JGLFlBQWxCLENBRHlCO0FBRXpCM0UsbUJBQVdtQyxJQUFYLENBQWdCOEMsU0FBaEIsQ0FBMEJILGFBQTFCLEVBQXlDSCxZQUF6QyxJQUF5REssT0FGaEMsQ0FBWCxFQUhILEVBQWY7OztBQVFEO0FBQ0Y7O0FBRUQsU0FBU1UsZ0JBQVQsQ0FBMEJwQixPQUExQixFQUFtQ3RELFFBQW5DLEVBQTZDMkUsVUFBN0MsRUFBeURwQixLQUF6RCxFQUFnRTtBQUM5RG9CLGFBQVdDLE9BQVgsQ0FBbUIsVUFBVUMsR0FBVixFQUFlO0FBQ2hDLFFBQU1DLFFBQVE5RSxTQUFTK0UsSUFBVCxjQUFjLFNBQVNDLGFBQVQsQ0FBdUJDLFlBQXZCLEVBQXFDO0FBQy9ELGVBQU9BLGFBQWFuRyxJQUFiLEdBQW9CK0YsSUFBSS9GLElBQS9CO0FBQ0QsT0FGYSxPQUF1QmtHLGFBQXZCLEtBQWQ7QUFHQTNCLGtCQUFjQyxPQUFkLEVBQXVCd0IsS0FBdkIsRUFBOEJELEdBQTlCLEVBQW1DdEIsS0FBbkM7QUFDRCxHQUxEO0FBTUQ7O0FBRUQsU0FBUzJCLG9CQUFULENBQThCNUIsT0FBOUIsRUFBdUN0RCxRQUF2QyxFQUFpRDtBQUMvQyxNQUFNMkUsYUFBYTVFLGVBQWVDLFFBQWYsQ0FBbkI7QUFDQSxNQUFJLENBQUMyRSxXQUFXOUUsTUFBaEIsRUFBd0I7QUFDdEI7QUFDRDs7QUFFRDtBQUNBLE1BQU1zRixtQkFBbUJ6RyxRQUFRc0IsUUFBUixDQUF6QjtBQUNBLE1BQU1vRixnQkFBZ0JyRixlQUFlb0YsZ0JBQWYsQ0FBdEI7QUFDQSxNQUFJQyxjQUFjdkYsTUFBZCxHQUF1QjhFLFdBQVc5RSxNQUF0QyxFQUE4QztBQUM1QzZFLHFCQUFpQnBCLE9BQWpCLEVBQTBCNkIsZ0JBQTFCLEVBQTRDQyxhQUE1QyxFQUEyRCxPQUEzRDtBQUNBO0FBQ0Q7QUFDRFYsbUJBQWlCcEIsT0FBakIsRUFBMEJ0RCxRQUExQixFQUFvQzJFLFVBQXBDLEVBQWdELFFBQWhEO0FBQ0Q7O0FBRUQsSUFBTVUsZ0JBQWdCLFNBQWhCQSxhQUFnQixDQUFDQyxDQUFELEVBQUlDLENBQUosRUFBVTtBQUM5QixNQUFJRCxJQUFJQyxDQUFSLEVBQVc7QUFDVCxXQUFPLENBQUMsQ0FBUjtBQUNEO0FBQ0QsTUFBSUQsSUFBSUMsQ0FBUixFQUFXO0FBQ1QsV0FBTyxDQUFQO0FBQ0Q7QUFDRCxTQUFPLENBQVA7QUFDRCxDQVJEOztBQVVBO0FBQ0EsSUFBTUMsc0JBQXNCLE9BQTVCO0FBQ0EsSUFBTUMscUJBQXFCLFNBQXJCQSxrQkFBcUIsQ0FBQ3hHLElBQUQsRUFBT3lHLFdBQVAsRUFBdUI7QUFDaEQsTUFBTUMsUUFBUTFHLEtBQUswRyxLQUFuQjtBQUNBLFNBQU9ELGNBQWNFLE9BQU9ELEtBQVAsRUFBY0QsV0FBZCxFQUFkLEdBQTRDQyxLQUFuRDtBQUNELENBSEQ7O0FBS0EsU0FBU0UsU0FBVCxDQUFtQkMsa0JBQW5CLEVBQXVDO0FBQ3JDLE1BQU1DLGFBQWFELG1CQUFtQnZDLEtBQW5CLEtBQTZCLEtBQTdCLEdBQXFDLENBQXJDLEdBQXlDLENBQUMsQ0FBN0Q7QUFDQSxNQUFNeUMsa0JBQWtCRixtQkFBbUJFLGVBQTNDO0FBQ0EsTUFBTUMsdUJBQXVCRCxvQkFBb0IsUUFBcEI7QUFDdkJGLHFCQUFtQkUsZUFBbkIsS0FBdUMsS0FBdkMsR0FBK0MsQ0FBL0MsR0FBbUQsQ0FBQyxDQUQ3QixDQUE3Qjs7QUFHQSxzQkFBTyxTQUFTRSxhQUFULENBQXVCQyxLQUF2QixFQUE4QkMsS0FBOUIsRUFBcUM7QUFDMUMsVUFBTUMsVUFBVVosbUJBQW1CVSxLQUFuQixFQUEwQkwsbUJBQW1CUSxlQUE3QyxDQUFoQjtBQUNBLFVBQU1DLFVBQVVkLG1CQUFtQlcsS0FBbkIsRUFBMEJOLG1CQUFtQlEsZUFBN0MsQ0FBaEI7QUFDQSxVQUFJbEgsU0FBUyxDQUFiOztBQUVBLFVBQUksQ0FBQyxnQ0FBU2lILE9BQVQsRUFBa0IsR0FBbEIsQ0FBRCxJQUEyQixDQUFDLGdDQUFTRSxPQUFULEVBQWtCLEdBQWxCLENBQWhDLEVBQXdEO0FBQ3REbkgsaUJBQVNpRyxjQUFjZ0IsT0FBZCxFQUF1QkUsT0FBdkIsQ0FBVDtBQUNELE9BRkQsTUFFTztBQUNMLFlBQU1DLElBQUlILFFBQVFJLEtBQVIsQ0FBYyxHQUFkLENBQVY7QUFDQSxZQUFNQyxJQUFJSCxRQUFRRSxLQUFSLENBQWMsR0FBZCxDQUFWO0FBQ0EsWUFBTW5CLElBQUlrQixFQUFFM0csTUFBWjtBQUNBLFlBQU0wRixJQUFJbUIsRUFBRTdHLE1BQVo7O0FBRUEsYUFBSyxJQUFJUixJQUFJLENBQWIsRUFBZ0JBLElBQUlzSCxLQUFLQyxHQUFMLENBQVN0QixDQUFULEVBQVlDLENBQVosQ0FBcEIsRUFBb0NsRyxHQUFwQyxFQUF5QztBQUN2QztBQUNBLGNBQUlBLE1BQU0sQ0FBTixJQUFZLENBQUNtSCxFQUFFbkgsQ0FBRixNQUFTLEdBQVQsSUFBZ0JtSCxFQUFFbkgsQ0FBRixNQUFTLElBQTFCLE1BQW9DcUgsRUFBRXJILENBQUYsTUFBUyxHQUFULElBQWdCcUgsRUFBRXJILENBQUYsTUFBUyxJQUE3RCxDQUFoQixFQUFxRjtBQUNuRjtBQUNBLGdCQUFJbUgsRUFBRW5ILENBQUYsTUFBU3FILEVBQUVySCxDQUFGLENBQWIsRUFBbUIsQ0FBRSxNQUFRO0FBQzdCO0FBQ0Q7QUFDREQsbUJBQVNpRyxjQUFjbUIsRUFBRW5ILENBQUYsQ0FBZCxFQUFvQnFILEVBQUVySCxDQUFGLENBQXBCLENBQVQ7QUFDQSxjQUFJRCxNQUFKLEVBQVksQ0FBRSxNQUFRO0FBQ3ZCOztBQUVELFlBQUksQ0FBQ0EsTUFBRCxJQUFXa0csTUFBTUMsQ0FBckIsRUFBd0I7QUFDdEJuRyxtQkFBU2tHLElBQUlDLENBQUosR0FBUSxDQUFDLENBQVQsR0FBYSxDQUF0QjtBQUNEO0FBQ0Y7O0FBRURuRyxlQUFTQSxTQUFTMkcsVUFBbEI7O0FBRUE7QUFDQSxVQUFJLENBQUMzRyxNQUFELElBQVc2RyxvQkFBZixFQUFxQztBQUNuQzdHLGlCQUFTNkcsdUJBQXVCWjtBQUM5QmMsY0FBTWxILElBQU4sQ0FBV21FLFVBQVgsSUFBeUJvQyxtQkFESztBQUU5QlksY0FBTW5ILElBQU4sQ0FBV21FLFVBQVgsSUFBeUJvQyxtQkFGSyxDQUFoQzs7QUFJRDs7QUFFRCxhQUFPcEcsTUFBUDtBQUNELEtBeENELE9BQWdCOEcsYUFBaEI7QUF5Q0Q7O0FBRUQsU0FBU1csd0JBQVQsQ0FBa0M3RyxRQUFsQyxFQUE0QzhGLGtCQUE1QyxFQUFnRTtBQUM5RCxNQUFNZ0IsaUJBQWlCLHlCQUFROUcsUUFBUixFQUFrQixVQUFDK0csSUFBRCxVQUFVQSxLQUFLakksSUFBZixFQUFsQixDQUF2Qjs7QUFFQSxNQUFNa0ksV0FBV25CLFVBQVVDLGtCQUFWLENBQWpCOztBQUVBO0FBQ0EsTUFBTW1CLGFBQWFDLE9BQU9DLElBQVAsQ0FBWUwsY0FBWixFQUE0QmpFLElBQTVCLENBQWlDLFVBQVV5QyxDQUFWLEVBQWFDLENBQWIsRUFBZ0I7QUFDbEUsV0FBT0QsSUFBSUMsQ0FBWDtBQUNELEdBRmtCLENBQW5COztBQUlBO0FBQ0EwQixhQUFXckMsT0FBWCxDQUFtQixVQUFVd0MsU0FBVixFQUFxQjtBQUN0Q04sbUJBQWVNLFNBQWYsRUFBMEJ2RSxJQUExQixDQUErQm1FLFFBQS9CO0FBQ0QsR0FGRDs7QUFJQTtBQUNBLE1BQUlLLFVBQVUsQ0FBZDtBQUNBLE1BQU1DLG9CQUFvQkwsV0FBV00sTUFBWCxDQUFrQixVQUFVQyxHQUFWLEVBQWVKLFNBQWYsRUFBMEI7QUFDcEVOLG1CQUFlTSxTQUFmLEVBQTBCeEMsT0FBMUIsQ0FBa0MsVUFBVUssWUFBVixFQUF3QjtBQUN4RHVDLGlCQUFPdkMsYUFBYVUsS0FBcEIsaUJBQTZCVixhQUFhaEcsSUFBYixDQUFrQm1FLFVBQS9DLEtBQStEcUUsU0FBU0wsU0FBVCxFQUFvQixFQUFwQixJQUEwQkMsT0FBekY7QUFDQUEsaUJBQVcsQ0FBWDtBQUNELEtBSEQ7QUFJQSxXQUFPRyxHQUFQO0FBQ0QsR0FOeUIsRUFNdkIsRUFOdUIsQ0FBMUI7O0FBUUE7QUFDQXhILFdBQVM0RSxPQUFULENBQWlCLFVBQVVLLFlBQVYsRUFBd0I7QUFDdkNBLGlCQUFhbkcsSUFBYixHQUFvQndJLHlCQUFxQnJDLGFBQWFVLEtBQWxDLGlCQUEyQ1YsYUFBYWhHLElBQWIsQ0FBa0JtRSxVQUE3RCxFQUFwQjtBQUNELEdBRkQ7QUFHRDs7QUFFRDs7QUFFQSxTQUFTc0UsZUFBVCxDQUF5QkMsS0FBekIsRUFBZ0NDLFVBQWhDLEVBQTRDQyxJQUE1QyxFQUFrREMsV0FBbEQsRUFBK0Q7QUFDN0QsT0FBSyxJQUFJekksSUFBSSxDQUFSLEVBQVcwSSxJQUFJSCxXQUFXL0gsTUFBL0IsRUFBdUNSLElBQUkwSSxDQUEzQyxFQUE4QzFJLEdBQTlDLEVBQW1EO0FBQ1F1SSxlQUFXdkksQ0FBWCxDQURSLENBQ3pDMkksT0FEeUMsaUJBQ3pDQSxPQUR5QyxDQUNoQ0MsY0FEZ0MsaUJBQ2hDQSxjQURnQyxDQUNoQkMsS0FEZ0IsaUJBQ2hCQSxLQURnQix1Q0FDVEMsUUFEUyxDQUNUQSxRQURTLHlDQUNFLENBREY7QUFFakQsUUFBSSw0QkFBVU4sSUFBVixFQUFnQkcsT0FBaEIsRUFBeUJDLGtCQUFrQixFQUFFRyxXQUFXLElBQWIsRUFBM0MsQ0FBSixFQUFxRTtBQUNuRSxhQUFPVCxNQUFNTyxLQUFOLElBQWVDLFdBQVdMLFdBQWpDO0FBQ0Q7QUFDRjtBQUNGOztBQUVELFNBQVNPLFdBQVQsQ0FBcUIvRSxPQUFyQixFQUE4QnFFLEtBQTlCLEVBQXFDVyxXQUFyQyxFQUFrREMsbUJBQWxELEVBQXVFO0FBQ3JFLE1BQUlDLGdCQUFKO0FBQ0EsTUFBSTFKLGFBQUo7QUFDQSxNQUFJd0osWUFBWTVILElBQVosS0FBcUIsZUFBekIsRUFBMEM7QUFDeEM4SCxjQUFVLFFBQVY7QUFDRCxHQUZELE1BRU8sSUFBSUYsWUFBWXJKLElBQVosQ0FBaUJtRSxVQUFqQixLQUFnQyxNQUFoQyxJQUEwQ3VFLE1BQU1jLFlBQU4sQ0FBbUI3RixPQUFuQixDQUEyQixNQUEzQixNQUF1QyxDQUFDLENBQXRGLEVBQXlGO0FBQzlGNEYsY0FBVSxNQUFWO0FBQ0QsR0FGTSxNQUVBO0FBQ0xBLGNBQVUsNkJBQVdGLFlBQVkzQyxLQUF2QixFQUE4QnJDLE9BQTlCLENBQVY7QUFDRDtBQUNELE1BQUksQ0FBQ2lGLG9CQUFvQkcsR0FBcEIsQ0FBd0JGLE9BQXhCLENBQUwsRUFBdUM7QUFDckMxSixXQUFPNEksZ0JBQWdCQyxNQUFNZ0IsTUFBdEIsRUFBOEJoQixNQUFNQyxVQUFwQyxFQUFnRFUsWUFBWTNDLEtBQTVELEVBQW1FZ0MsTUFBTUcsV0FBekUsQ0FBUDtBQUNEO0FBQ0QsTUFBSSxPQUFPaEosSUFBUCxLQUFnQixXQUFwQixFQUFpQztBQUMvQkEsV0FBTzZJLE1BQU1nQixNQUFOLENBQWFILE9BQWIsQ0FBUDtBQUNEO0FBQ0QsTUFBSUYsWUFBWTVILElBQVosS0FBcUIsUUFBckIsSUFBaUMsQ0FBQzRILFlBQVk1SCxJQUFaLENBQWlCa0ksVUFBakIsQ0FBNEIsU0FBNUIsQ0FBdEMsRUFBOEU7QUFDNUU5SixZQUFRLEdBQVI7QUFDRDs7QUFFRCxTQUFPQSxJQUFQO0FBQ0Q7O0FBRUQsU0FBUytKLFlBQVQsQ0FBc0J2RixPQUF0QixFQUErQmdGLFdBQS9CLEVBQTRDWCxLQUE1QyxFQUFtRDNILFFBQW5ELEVBQTZEdUksbUJBQTdELEVBQWtGO0FBQ2hGLE1BQU16SixPQUFPdUosWUFBWS9FLE9BQVosRUFBcUJxRSxLQUFyQixFQUE0QlcsV0FBNUIsRUFBeUNDLG1CQUF6QyxDQUFiO0FBQ0EsTUFBSXpKLFNBQVMsQ0FBQyxDQUFkLEVBQWlCO0FBQ2ZrQixhQUFTVCxJQUFULG1CQUFtQitJLFdBQW5CLElBQWdDeEosVUFBaEM7QUFDRDtBQUNGOztBQUVELFNBQVNnSyxlQUFULENBQXlCN0osSUFBekIsRUFBK0I7QUFDN0IsTUFBSThKLElBQUk5SixJQUFSO0FBQ0E7QUFDQTtBQUNBO0FBQ0U4SixJQUFFekksTUFBRixDQUFTSSxJQUFULEtBQWtCLGtCQUFsQixJQUF3Q3FJLEVBQUV6SSxNQUFGLENBQVM0QixNQUFULEtBQW9CNkcsQ0FBNUQ7QUFDR0EsSUFBRXpJLE1BQUYsQ0FBU0ksSUFBVCxLQUFrQixnQkFBbEIsSUFBc0NxSSxFQUFFekksTUFBRixDQUFTa0IsTUFBVCxLQUFvQnVILENBRi9EO0FBR0U7QUFDQUEsUUFBSUEsRUFBRXpJLE1BQU47QUFDRDtBQUNEO0FBQ0V5SSxJQUFFekksTUFBRixDQUFTSSxJQUFULEtBQWtCLG9CQUFsQjtBQUNHcUksSUFBRXpJLE1BQUYsQ0FBU0EsTUFBVCxDQUFnQkksSUFBaEIsS0FBeUIscUJBRDVCO0FBRUdxSSxJQUFFekksTUFBRixDQUFTQSxNQUFULENBQWdCQSxNQUFoQixDQUF1QkksSUFBdkIsS0FBZ0MsU0FIckM7QUFJRTtBQUNBLFdBQU9xSSxFQUFFekksTUFBRixDQUFTQSxNQUFULENBQWdCQSxNQUF2QjtBQUNEO0FBQ0Y7O0FBRUQsSUFBTTBJLFFBQVEsQ0FBQyxTQUFELEVBQVksVUFBWixFQUF3QixVQUF4QixFQUFvQyxTQUFwQyxFQUErQyxRQUEvQyxFQUF5RCxTQUF6RCxFQUFvRSxPQUFwRSxFQUE2RSxRQUE3RSxFQUF1RixNQUF2RixDQUFkOztBQUVBO0FBQ0E7QUFDQTtBQUNBLFNBQVNDLG9CQUFULENBQThCTixNQUE5QixFQUFzQztBQUNwQyxNQUFNTyxhQUFhUCxPQUFPcEIsTUFBUCxDQUFjLFVBQVVuSCxHQUFWLEVBQWU4SCxLQUFmLEVBQXNCaUIsS0FBdEIsRUFBNkI7QUFDNUQsT0FBR0MsTUFBSCxDQUFVbEIsS0FBVixFQUFpQnRELE9BQWpCLENBQXlCLFVBQVV5RSxTQUFWLEVBQXFCO0FBQzVDLFVBQUlMLE1BQU1wRyxPQUFOLENBQWN5RyxTQUFkLE1BQTZCLENBQUMsQ0FBbEMsRUFBcUM7QUFDbkMsY0FBTSxJQUFJQyxLQUFKLGdFQUFpRUMsS0FBS0MsU0FBTCxDQUFlSCxTQUFmLENBQWpFLFFBQU47QUFDRDtBQUNELFVBQUlqSixJQUFJaUosU0FBSixNQUFtQkksU0FBdkIsRUFBa0M7QUFDaEMsY0FBTSxJQUFJSCxLQUFKLG1EQUFvREQsU0FBcEQsc0JBQU47QUFDRDtBQUNEakosVUFBSWlKLFNBQUosSUFBaUJGLFFBQVEsQ0FBekI7QUFDRCxLQVJEO0FBU0EsV0FBTy9JLEdBQVA7QUFDRCxHQVhrQixFQVdoQixFQVhnQixDQUFuQjs7QUFhQSxNQUFNcUksZUFBZU8sTUFBTTlJLE1BQU4sQ0FBYSxVQUFVUSxJQUFWLEVBQWdCO0FBQ2hELFdBQU8sT0FBT3dJLFdBQVd4SSxJQUFYLENBQVAsS0FBNEIsV0FBbkM7QUFDRCxHQUZvQixDQUFyQjs7QUFJQSxNQUFNaUgsUUFBUWMsYUFBYWxCLE1BQWIsQ0FBb0IsVUFBVW5ILEdBQVYsRUFBZU0sSUFBZixFQUFxQjtBQUNyRE4sUUFBSU0sSUFBSixJQUFZaUksT0FBTzlJLE1BQVAsR0FBZ0IsQ0FBNUI7QUFDQSxXQUFPTyxHQUFQO0FBQ0QsR0FIYSxFQUdYOEksVUFIVyxDQUFkOztBQUtBLFNBQU8sRUFBRVAsUUFBUWhCLEtBQVYsRUFBaUJjLDBCQUFqQixFQUFQO0FBQ0Q7O0FBRUQsU0FBU2lCLHlCQUFULENBQW1DOUIsVUFBbkMsRUFBK0M7QUFDN0MsTUFBTStCLFFBQVEsRUFBZDtBQUNBLE1BQU1DLFNBQVMsRUFBZjs7QUFFQSxNQUFNQyxjQUFjakMsV0FBV2hKLEdBQVgsQ0FBZSxVQUFDa0wsU0FBRCxFQUFZWCxLQUFaLEVBQXNCO0FBQy9DakIsU0FEK0MsR0FDWDRCLFNBRFcsQ0FDL0M1QixLQUQrQyxDQUM5QjZCLGNBRDhCLEdBQ1hELFNBRFcsQ0FDeEMzQixRQUR3QztBQUV2RCxRQUFJQSxXQUFXLENBQWY7QUFDQSxRQUFJNEIsbUJBQW1CLE9BQXZCLEVBQWdDO0FBQzlCLFVBQUksQ0FBQ0osTUFBTXpCLEtBQU4sQ0FBTCxFQUFtQjtBQUNqQnlCLGNBQU16QixLQUFOLElBQWUsQ0FBZjtBQUNEO0FBQ0RDLGlCQUFXd0IsTUFBTXpCLEtBQU4sR0FBWDtBQUNELEtBTEQsTUFLTyxJQUFJNkIsbUJBQW1CLFFBQXZCLEVBQWlDO0FBQ3RDLFVBQUksQ0FBQ0gsT0FBTzFCLEtBQVAsQ0FBTCxFQUFvQjtBQUNsQjBCLGVBQU8xQixLQUFQLElBQWdCLEVBQWhCO0FBQ0Q7QUFDRDBCLGFBQU8xQixLQUFQLEVBQWMzSSxJQUFkLENBQW1CNEosS0FBbkI7QUFDRDs7QUFFRCw2QkFBWVcsU0FBWixJQUF1QjNCLGtCQUF2QjtBQUNELEdBaEJtQixDQUFwQjs7QUFrQkEsTUFBSUwsY0FBYyxDQUFsQjs7QUFFQVosU0FBT0MsSUFBUCxDQUFZeUMsTUFBWixFQUFvQmhGLE9BQXBCLENBQTRCLFVBQUNzRCxLQUFELEVBQVc7QUFDckMsUUFBTThCLGNBQWNKLE9BQU8xQixLQUFQLEVBQWNySSxNQUFsQztBQUNBK0osV0FBTzFCLEtBQVAsRUFBY3RELE9BQWQsQ0FBc0IsVUFBQ3FGLFVBQUQsRUFBYWQsS0FBYixFQUF1QjtBQUMzQ1Usa0JBQVlJLFVBQVosRUFBd0I5QixRQUF4QixHQUFtQyxDQUFDLENBQUQsSUFBTTZCLGNBQWNiLEtBQXBCLENBQW5DO0FBQ0QsS0FGRDtBQUdBckIsa0JBQWNuQixLQUFLdUQsR0FBTCxDQUFTcEMsV0FBVCxFQUFzQmtDLFdBQXRCLENBQWQ7QUFDRCxHQU5EOztBQVFBOUMsU0FBT0MsSUFBUCxDQUFZd0MsS0FBWixFQUFtQi9FLE9BQW5CLENBQTJCLFVBQUN1RixHQUFELEVBQVM7QUFDbEMsUUFBTUMsb0JBQW9CVCxNQUFNUSxHQUFOLENBQTFCO0FBQ0FyQyxrQkFBY25CLEtBQUt1RCxHQUFMLENBQVNwQyxXQUFULEVBQXNCc0Msb0JBQW9CLENBQTFDLENBQWQ7QUFDRCxHQUhEOztBQUtBLFNBQU87QUFDTHhDLGdCQUFZaUMsV0FEUDtBQUVML0IsaUJBQWFBLGNBQWMsRUFBZCxHQUFtQm5CLEtBQUswRCxHQUFMLENBQVMsRUFBVCxFQUFhMUQsS0FBSzJELElBQUwsQ0FBVTNELEtBQUs0RCxLQUFMLENBQVd6QyxXQUFYLENBQVYsQ0FBYixDQUFuQixHQUFzRSxFQUY5RSxFQUFQOztBQUlEOztBQUVELFNBQVMwQyxxQkFBVCxDQUErQmxILE9BQS9CLEVBQXdDbUgsY0FBeEMsRUFBd0Q7QUFDdEQsTUFBTUMsV0FBV3JLLGFBQWFvSyxlQUFleEwsSUFBNUIsQ0FBakI7QUFDQSxNQUFNK0Isb0JBQW9CdEI7QUFDeEI0RCxVQUFRRSxhQUFSLEVBRHdCLEVBQ0NrSCxRQURELEVBQ1dsSyxvQkFBb0JrSyxRQUFwQixDQURYLENBQTFCOztBQUdBLE1BQUlDLFlBQVlELFNBQVN4SixLQUFULENBQWUsQ0FBZixDQUFoQjtBQUNBLE1BQUlGLGtCQUFrQm5CLE1BQWxCLEdBQTJCLENBQS9CLEVBQWtDO0FBQ2hDOEssZ0JBQVkzSixrQkFBa0JBLGtCQUFrQm5CLE1BQWxCLEdBQTJCLENBQTdDLEVBQWdEcUIsS0FBaEQsQ0FBc0QsQ0FBdEQsQ0FBWjtBQUNEO0FBQ0QsU0FBTyxVQUFDc0QsS0FBRCxVQUFXQSxNQUFNb0csb0JBQU4sQ0FBMkIsQ0FBQ0YsU0FBU3hKLEtBQVQsQ0FBZSxDQUFmLENBQUQsRUFBb0J5SixTQUFwQixDQUEzQixFQUEyRCxJQUEzRCxDQUFYLEVBQVA7QUFDRDs7QUFFRCxTQUFTRSx3QkFBVCxDQUFrQ3ZILE9BQWxDLEVBQTJDd0gsYUFBM0MsRUFBMERMLGNBQTFELEVBQTBFO0FBQ3hFLE1BQU16TCxhQUFhc0UsUUFBUUUsYUFBUixFQUFuQjtBQUNBLE1BQU1rSCxXQUFXckssYUFBYW9LLGVBQWV4TCxJQUE1QixDQUFqQjtBQUNBLE1BQU04TCxXQUFXMUssYUFBYXlLLGNBQWM3TCxJQUEzQixDQUFqQjtBQUNBLE1BQU0rTCxnQkFBZ0I7QUFDcEJqSyw0QkFBMEIvQixVQUExQixFQUFzQzBMLFFBQXRDLENBRG9CO0FBRXBCdEosOEJBQTRCcEMsVUFBNUIsRUFBd0MrTCxRQUF4QyxDQUZvQixDQUF0Qjs7QUFJQSxNQUFLLE9BQUQsQ0FBVUUsSUFBVixDQUFlak0sV0FBV21DLElBQVgsQ0FBZ0I4QyxTQUFoQixDQUEwQitHLGNBQWMsQ0FBZCxDQUExQixFQUE0Q0EsY0FBYyxDQUFkLENBQTVDLENBQWYsQ0FBSixFQUFtRjtBQUNqRixXQUFPLFVBQUN4RyxLQUFELFVBQVdBLE1BQU0wRyxXQUFOLENBQWtCRixhQUFsQixDQUFYLEVBQVA7QUFDRDtBQUNELFNBQU92QixTQUFQO0FBQ0Q7O0FBRUQsU0FBUzBCLHlCQUFULENBQW1DN0gsT0FBbkMsRUFBNEN0RCxRQUE1QyxFQUFzRG9MLHNCQUF0RCxFQUE4RUMsYUFBOUUsRUFBNkY7QUFDM0YsTUFBTUMsK0JBQStCLFNBQS9CQSw0QkFBK0IsQ0FBQ1IsYUFBRCxFQUFnQkwsY0FBaEIsRUFBbUM7QUFDdEUsUUFBTWMsc0JBQXNCakksUUFBUUUsYUFBUixHQUF3QmdJLEtBQXhCLENBQThCdkksS0FBOUI7QUFDMUJ3SCxtQkFBZXhMLElBQWYsQ0FBb0IwQixHQUFwQixDQUF3QkcsR0FBeEIsQ0FBNEJELElBREY7QUFFMUJpSyxrQkFBYzdMLElBQWQsQ0FBbUIwQixHQUFuQixDQUF1QkMsS0FBdkIsQ0FBNkJDLElBQTdCLEdBQW9DLENBRlYsQ0FBNUI7OztBQUtBLFdBQU8wSyxvQkFBb0JyTCxNQUFwQixDQUEyQixVQUFDVyxJQUFELFVBQVUsQ0FBQ0EsS0FBSzRLLElBQUwsR0FBWTVMLE1BQXZCLEVBQTNCLEVBQTBEQSxNQUFqRTtBQUNELEdBUEQ7QUFRQSxNQUFNNkwsNEJBQTRCLFNBQTVCQSx5QkFBNEIsQ0FBQ1osYUFBRCxFQUFnQkwsY0FBaEIsVUFBbUNLLGNBQWNoTSxJQUFkLEdBQXFCLENBQXJCLElBQTBCMkwsZUFBZTNMLElBQTVFLEVBQWxDO0FBQ0EsTUFBSTJMLGlCQUFpQnpLLFNBQVMsQ0FBVCxDQUFyQjs7QUFFQUEsV0FBU2lELEtBQVQsQ0FBZSxDQUFmLEVBQWtCMkIsT0FBbEIsQ0FBMEIsVUFBVWtHLGFBQVYsRUFBeUI7QUFDakQsUUFBTWEsb0JBQW9CTCw2QkFBNkJSLGFBQTdCLEVBQTRDTCxjQUE1QyxDQUExQjtBQUNBLFFBQU1tQix5QkFBeUJGLDBCQUEwQlosYUFBMUIsRUFBeUNMLGNBQXpDLENBQS9COztBQUVBLFFBQUlXLDJCQUEyQixRQUEzQjtBQUNHQSwrQkFBMkIsMEJBRGxDLEVBQzhEO0FBQzVELFVBQUlOLGNBQWNoTSxJQUFkLEtBQXVCMkwsZUFBZTNMLElBQXRDLElBQThDNk0sc0JBQXNCLENBQXhFLEVBQTJFO0FBQ3pFLFlBQUlOLGlCQUFpQixDQUFDQSxhQUFELElBQWtCTyxzQkFBdkMsRUFBK0Q7QUFDN0R0SSxrQkFBUWdCLE1BQVIsQ0FBZTtBQUNickYsa0JBQU13TCxlQUFleEwsSUFEUjtBQUVib0YscUJBQVMsK0RBRkk7QUFHYkUsaUJBQUtpRyxzQkFBc0JsSCxPQUF0QixFQUErQm1ILGNBQS9CLENBSFEsRUFBZjs7QUFLRDtBQUNGLE9BUkQsTUFRTyxJQUFJa0Isb0JBQW9CLENBQXBCO0FBQ05QLGlDQUEyQiwwQkFEekIsRUFDcUQ7QUFDMUQsWUFBSUMsaUJBQWlCUCxjQUFjaE0sSUFBZCxLQUF1QjJMLGVBQWUzTCxJQUF2RCxJQUErRCxDQUFDdU0sYUFBRCxJQUFrQixDQUFDTyxzQkFBdEYsRUFBOEc7QUFDNUd0SSxrQkFBUWdCLE1BQVIsQ0FBZTtBQUNickYsa0JBQU13TCxlQUFleEwsSUFEUjtBQUVib0YscUJBQVMsbURBRkk7QUFHYkUsaUJBQUtzRyx5QkFBeUJ2SCxPQUF6QixFQUFrQ3dILGFBQWxDLEVBQWlETCxjQUFqRCxDQUhRLEVBQWY7O0FBS0Q7QUFDRjtBQUNGLEtBcEJELE1Bb0JPLElBQUlrQixvQkFBb0IsQ0FBeEIsRUFBMkI7QUFDaENySSxjQUFRZ0IsTUFBUixDQUFlO0FBQ2JyRixjQUFNd0wsZUFBZXhMLElBRFI7QUFFYm9GLGlCQUFTLHFEQUZJO0FBR2JFLGFBQUtzRyx5QkFBeUJ2SCxPQUF6QixFQUFrQ3dILGFBQWxDLEVBQWlETCxjQUFqRCxDQUhRLEVBQWY7O0FBS0Q7O0FBRURBLHFCQUFpQkssYUFBakI7QUFDRCxHQWpDRDtBQWtDRDs7QUFFRCxTQUFTZSxvQkFBVCxDQUE4QkMsT0FBOUIsRUFBdUM7QUFDckMsTUFBTUMsY0FBY0QsUUFBUUMsV0FBUixJQUF1QixFQUEzQztBQUNBLE1BQU14SSxRQUFRd0ksWUFBWXhJLEtBQVosSUFBcUIsUUFBbkM7QUFDQSxNQUFNeUMsa0JBQWtCK0YsWUFBWS9GLGVBQVosSUFBK0IsUUFBdkQ7QUFDQSxNQUFNTSxrQkFBa0J5RixZQUFZekYsZUFBWixJQUErQixLQUF2RDs7QUFFQSxTQUFPLEVBQUUvQyxZQUFGLEVBQVN5QyxnQ0FBVCxFQUEwQk0sZ0NBQTFCLEVBQVA7QUFDRDs7QUFFRDtBQUNBLElBQU0wRix1QkFBdUIsSUFBN0I7O0FBRUFDLE9BQU9DLE9BQVAsR0FBaUI7QUFDZkMsUUFBTTtBQUNKekwsVUFBTSxZQURGO0FBRUowTCxVQUFNO0FBQ0pDLGdCQUFVLGFBRE47QUFFSkMsbUJBQWEsOENBRlQ7QUFHSkMsV0FBSywwQkFBUSxPQUFSLENBSEQsRUFGRjs7O0FBUUpDLGFBQVMsTUFSTDtBQVNKQyxZQUFRO0FBQ047QUFDRS9MLFlBQU0sUUFEUjtBQUVFZ00sa0JBQVk7QUFDVi9ELGdCQUFRO0FBQ05qSSxnQkFBTSxPQURBLEVBREU7O0FBSVZpTSx1Q0FBK0I7QUFDN0JqTSxnQkFBTSxPQUR1QixFQUpyQjs7QUFPVjJLLHVCQUFlO0FBQ2IzSyxnQkFBTSxTQURPO0FBRWIscUJBQVNzTCxvQkFGSSxFQVBMOztBQVdWcEUsb0JBQVk7QUFDVmxILGdCQUFNLE9BREk7QUFFVmtNLGlCQUFPO0FBQ0xsTSxrQkFBTSxRQUREO0FBRUxnTSx3QkFBWTtBQUNWMUUsdUJBQVM7QUFDUHRILHNCQUFNLFFBREMsRUFEQzs7QUFJVnVILDhCQUFnQjtBQUNkdkgsc0JBQU0sUUFEUSxFQUpOOztBQU9Wd0gscUJBQU87QUFDTHhILHNCQUFNLFFBREQ7QUFFTCx3QkFBTXNJLEtBRkQsRUFQRzs7QUFXVmIsd0JBQVU7QUFDUnpILHNCQUFNLFFBREU7QUFFUix3QkFBTSxDQUFDLE9BQUQsRUFBVSxRQUFWLENBRkUsRUFYQSxFQUZQOzs7QUFrQkxtTSxrQ0FBc0IsS0FsQmpCO0FBbUJMQyxzQkFBVSxDQUFDLFNBQUQsRUFBWSxPQUFaLENBbkJMLEVBRkcsRUFYRjs7O0FBbUNWLDRCQUFvQjtBQUNsQixrQkFBTTtBQUNKLGtCQURJO0FBRUosa0JBRkk7QUFHSixvQ0FISTtBQUlKLGlCQUpJLENBRFksRUFuQ1Y7OztBQTJDVmYscUJBQWE7QUFDWHJMLGdCQUFNLFFBREs7QUFFWGdNLHNCQUFZO0FBQ1ZwRyw2QkFBaUI7QUFDZjVGLG9CQUFNLFNBRFM7QUFFZix5QkFBUyxLQUZNLEVBRFA7O0FBS1Y2QyxtQkFBTztBQUNMLHNCQUFNLENBQUMsUUFBRCxFQUFXLEtBQVgsRUFBa0IsTUFBbEIsQ0FERDtBQUVMLHlCQUFTLFFBRkosRUFMRzs7QUFTVnlDLDZCQUFpQjtBQUNmLHNCQUFNLENBQUMsUUFBRCxFQUFXLEtBQVgsRUFBa0IsTUFBbEIsQ0FEUztBQUVmLHlCQUFTLFFBRk0sRUFUUCxFQUZEOzs7QUFnQlg2RyxnQ0FBc0IsS0FoQlgsRUEzQ0g7O0FBNkRWRSxpQ0FBeUI7QUFDdkJyTSxnQkFBTSxTQURpQjtBQUV2QixxQkFBUyxLQUZjLEVBN0RmLEVBRmQ7OztBQW9FRW1NLDRCQUFzQixLQXBFeEIsRUFETSxDQVRKLEVBRFM7Ozs7O0FBb0ZmRyx1QkFBUSxTQUFTQyxlQUFULENBQXlCM0osT0FBekIsRUFBa0M7QUFDeEMsVUFBTXdJLFVBQVV4SSxRQUFRd0ksT0FBUixDQUFnQixDQUFoQixLQUFzQixFQUF0QztBQUNBLFVBQU1WLHlCQUF5QlUsUUFBUSxrQkFBUixLQUErQixRQUE5RDtBQUNBLFVBQU1hLGdDQUFnQyxJQUFJTyxHQUFKLENBQVFwQixRQUFRYSw2QkFBUixJQUF5QyxDQUFDLFNBQUQsRUFBWSxVQUFaLEVBQXdCLFFBQXhCLENBQWpELENBQXRDO0FBQ0EsVUFBTVosY0FBY0YscUJBQXFCQyxPQUFyQixDQUFwQjtBQUNBLFVBQU1ULGdCQUFnQlMsUUFBUVQsYUFBUixJQUF5QixJQUF6QixHQUFnQ1csb0JBQWhDLEdBQXVELENBQUMsQ0FBQ0YsUUFBUVQsYUFBdkY7QUFDQSxVQUFJMUQsY0FBSjs7QUFFQSxVQUFJO0FBQ2tDK0Isa0NBQTBCb0MsUUFBUWxFLFVBQVIsSUFBc0IsRUFBaEQsQ0FEbEMsQ0FDTUEsVUFETix5QkFDTUEsVUFETixDQUNrQkUsV0FEbEIseUJBQ2tCQSxXQURsQjtBQUUrQm1CLDZCQUFxQjZDLFFBQVFuRCxNQUFSLElBQWtCbEssYUFBdkMsQ0FGL0IsQ0FFTWtLLE1BRk4seUJBRU1BLE1BRk4sQ0FFY0YsWUFGZCx5QkFFY0EsWUFGZDtBQUdGZCxnQkFBUTtBQUNOZ0Isd0JBRE07QUFFTkYsb0NBRk07QUFHTmIsZ0NBSE07QUFJTkUsa0NBSk0sRUFBUjs7QUFNRCxPQVRELENBU0UsT0FBT3FGLEtBQVAsRUFBYztBQUNkO0FBQ0EsZUFBTztBQUNMQyxpQkFESyxnQ0FDR25PLElBREgsRUFDUztBQUNacUUsc0JBQVFnQixNQUFSLENBQWVyRixJQUFmLEVBQXFCa08sTUFBTTlJLE9BQTNCO0FBQ0QsYUFISSxvQkFBUDs7QUFLRDtBQUNELFVBQU1nSixZQUFZLElBQUlDLEdBQUosRUFBbEI7O0FBRUEsZUFBU0MsZUFBVCxDQUF5QnRPLElBQXpCLEVBQStCO0FBQzdCLFlBQUksQ0FBQ29PLFVBQVUzRSxHQUFWLENBQWN6SixJQUFkLENBQUwsRUFBMEI7QUFDeEJvTyxvQkFBVUcsR0FBVixDQUFjdk8sSUFBZCxFQUFvQixFQUFwQjtBQUNEO0FBQ0QsZUFBT29PLFVBQVVJLEdBQVYsQ0FBY3hPLElBQWQsQ0FBUDtBQUNEOztBQUVELGFBQU87QUFDTHlPLHdDQUFtQixTQUFTQyxhQUFULENBQXVCMU8sSUFBdkIsRUFBNkI7QUFDOUM7QUFDQSxnQkFBSUEsS0FBS21ELFVBQUwsQ0FBZ0J2QyxNQUFoQixJQUEwQmlNLFFBQVFpQix1QkFBdEMsRUFBK0Q7QUFDN0Qsa0JBQU10TCxPQUFPeEMsS0FBSzJPLE1BQUwsQ0FBWWpJLEtBQXpCO0FBQ0FrRDtBQUNFdkYscUJBREY7QUFFRTtBQUNFckUsMEJBREY7QUFFRTBHLHVCQUFPbEUsSUFGVDtBQUdFMEMsNkJBQWExQyxJQUhmO0FBSUVmLHNCQUFNLFFBSlIsRUFGRjs7QUFRRWlILG1CQVJGO0FBU0U0Riw4QkFBZ0J0TyxLQUFLcUIsTUFBckIsQ0FURjtBQVVFcU0sMkNBVkY7O0FBWUQ7QUFDRixXQWpCRCxPQUE0QmdCLGFBQTVCLElBREs7QUFtQkxFLGdEQUEyQixTQUFTRixhQUFULENBQXVCMU8sSUFBdkIsRUFBNkI7QUFDdEQsZ0JBQUlrRixvQkFBSjtBQUNBLGdCQUFJd0IsY0FBSjtBQUNBLGdCQUFJakYsYUFBSjtBQUNBO0FBQ0EsZ0JBQUl6QixLQUFLNk8sUUFBVCxFQUFtQjtBQUNqQjtBQUNEO0FBQ0QsZ0JBQUk3TyxLQUFLcUQsZUFBTCxDQUFxQjVCLElBQXJCLEtBQThCLDJCQUFsQyxFQUErRDtBQUM3RGlGLHNCQUFRMUcsS0FBS3FELGVBQUwsQ0FBcUJDLFVBQXJCLENBQWdDb0QsS0FBeEM7QUFDQXhCLDRCQUFjd0IsS0FBZDtBQUNBakYscUJBQU8sUUFBUDtBQUNELGFBSkQsTUFJTztBQUNMaUYsc0JBQVEsRUFBUjtBQUNBeEIsNEJBQWNiLFFBQVFFLGFBQVIsR0FBd0J1SyxPQUF4QixDQUFnQzlPLEtBQUtxRCxlQUFyQyxDQUFkO0FBQ0E1QixxQkFBTyxlQUFQO0FBQ0Q7QUFDRG1JO0FBQ0V2RixtQkFERjtBQUVFO0FBQ0VyRSx3QkFERjtBQUVFMEcsMEJBRkY7QUFHRXhCLHNDQUhGO0FBSUV6RCx3QkFKRixFQUZGOztBQVFFaUgsaUJBUkY7QUFTRTRGLDRCQUFnQnRPLEtBQUtxQixNQUFyQixDQVRGO0FBVUVxTSx5Q0FWRjs7QUFZRCxXQTdCRCxPQUFvQ2dCLGFBQXBDLElBbkJLO0FBaURMSyxxQ0FBZ0IsU0FBU0MsY0FBVCxDQUF3QmhQLElBQXhCLEVBQThCO0FBQzVDLGdCQUFJLENBQUMsZ0NBQWdCQSxJQUFoQixDQUFMLEVBQTRCO0FBQzFCO0FBQ0Q7QUFDRCxnQkFBTWlQLFFBQVFwRixnQkFBZ0I3SixJQUFoQixDQUFkO0FBQ0EsZ0JBQUksQ0FBQ2lQLEtBQUwsRUFBWTtBQUNWO0FBQ0Q7QUFDRCxnQkFBTXpNLE9BQU94QyxLQUFLeUMsU0FBTCxDQUFlLENBQWYsRUFBa0JpRSxLQUEvQjtBQUNBa0Q7QUFDRXZGLG1CQURGO0FBRUU7QUFDRXJFLHdCQURGO0FBRUUwRyxxQkFBT2xFLElBRlQ7QUFHRTBDLDJCQUFhMUMsSUFIZjtBQUlFZixvQkFBTSxTQUpSLEVBRkY7O0FBUUVpSCxpQkFSRjtBQVNFNEYsNEJBQWdCVyxLQUFoQixDQVRGO0FBVUV2Qix5Q0FWRjs7QUFZRCxXQXJCRCxPQUF5QnNCLGNBQXpCLElBakRLO0FBdUVMLHFDQUFnQixTQUFTRSxjQUFULEdBQTBCO0FBQ3hDZCxzQkFBVXpJLE9BQVYsQ0FBa0IsVUFBQzVFLFFBQUQsRUFBYztBQUM5QixrQkFBSW9MLDJCQUEyQixRQUEvQixFQUF5QztBQUN2Q0QsMENBQTBCN0gsT0FBMUIsRUFBbUN0RCxRQUFuQyxFQUE2Q29MLHNCQUE3QyxFQUFxRUMsYUFBckU7QUFDRDs7QUFFRCxrQkFBSVUsWUFBWXhJLEtBQVosS0FBc0IsUUFBMUIsRUFBb0M7QUFDbENzRCx5Q0FBeUI3RyxRQUF6QixFQUFtQytMLFdBQW5DO0FBQ0Q7O0FBRUQ3RyxtQ0FBcUI1QixPQUFyQixFQUE4QnRELFFBQTlCO0FBQ0QsYUFWRDs7QUFZQXFOLHNCQUFVZSxLQUFWO0FBQ0QsV0FkRCxPQUF5QkQsY0FBekIsSUF2RUssRUFBUDs7QUF1RkQsS0F6SEQsT0FBaUJsQixlQUFqQixJQXBGZSxFQUFqQiIsImZpbGUiOiJvcmRlci5qcyIsInNvdXJjZXNDb250ZW50IjpbIid1c2Ugc3RyaWN0JztcblxuaW1wb3J0IG1pbmltYXRjaCBmcm9tICdtaW5pbWF0Y2gnO1xuaW1wb3J0IGluY2x1ZGVzIGZyb20gJ2FycmF5LWluY2x1ZGVzJztcbmltcG9ydCBncm91cEJ5IGZyb20gJ29iamVjdC5ncm91cGJ5JztcblxuaW1wb3J0IGltcG9ydFR5cGUgZnJvbSAnLi4vY29yZS9pbXBvcnRUeXBlJztcbmltcG9ydCBpc1N0YXRpY1JlcXVpcmUgZnJvbSAnLi4vY29yZS9zdGF0aWNSZXF1aXJlJztcbmltcG9ydCBkb2NzVXJsIGZyb20gJy4uL2RvY3NVcmwnO1xuXG5jb25zdCBkZWZhdWx0R3JvdXBzID0gWydidWlsdGluJywgJ2V4dGVybmFsJywgJ3BhcmVudCcsICdzaWJsaW5nJywgJ2luZGV4J107XG5cbi8vIFJFUE9SVElORyBBTkQgRklYSU5HXG5cbmZ1bmN0aW9uIHJldmVyc2UoYXJyYXkpIHtcbiAgcmV0dXJuIGFycmF5Lm1hcChmdW5jdGlvbiAodikge1xuICAgIHJldHVybiB7IC4uLnYsIHJhbms6IC12LnJhbmsgfTtcbiAgfSkucmV2ZXJzZSgpO1xufVxuXG5mdW5jdGlvbiBnZXRUb2tlbnNPckNvbW1lbnRzQWZ0ZXIoc291cmNlQ29kZSwgbm9kZSwgY291bnQpIHtcbiAgbGV0IGN1cnJlbnROb2RlT3JUb2tlbiA9IG5vZGU7XG4gIGNvbnN0IHJlc3VsdCA9IFtdO1xuICBmb3IgKGxldCBpID0gMDsgaSA8IGNvdW50OyBpKyspIHtcbiAgICBjdXJyZW50Tm9kZU9yVG9rZW4gPSBzb3VyY2VDb2RlLmdldFRva2VuT3JDb21tZW50QWZ0ZXIoY3VycmVudE5vZGVPclRva2VuKTtcbiAgICBpZiAoY3VycmVudE5vZGVPclRva2VuID09IG51bGwpIHtcbiAgICAgIGJyZWFrO1xuICAgIH1cbiAgICByZXN1bHQucHVzaChjdXJyZW50Tm9kZU9yVG9rZW4pO1xuICB9XG4gIHJldHVybiByZXN1bHQ7XG59XG5cbmZ1bmN0aW9uIGdldFRva2Vuc09yQ29tbWVudHNCZWZvcmUoc291cmNlQ29kZSwgbm9kZSwgY291bnQpIHtcbiAgbGV0IGN1cnJlbnROb2RlT3JUb2tlbiA9IG5vZGU7XG4gIGNvbnN0IHJlc3VsdCA9IFtdO1xuICBmb3IgKGxldCBpID0gMDsgaSA8IGNvdW50OyBpKyspIHtcbiAgICBjdXJyZW50Tm9kZU9yVG9rZW4gPSBzb3VyY2VDb2RlLmdldFRva2VuT3JDb21tZW50QmVmb3JlKGN1cnJlbnROb2RlT3JUb2tlbik7XG4gICAgaWYgKGN1cnJlbnROb2RlT3JUb2tlbiA9PSBudWxsKSB7XG4gICAgICBicmVhaztcbiAgICB9XG4gICAgcmVzdWx0LnB1c2goY3VycmVudE5vZGVPclRva2VuKTtcbiAgfVxuICByZXR1cm4gcmVzdWx0LnJldmVyc2UoKTtcbn1cblxuZnVuY3Rpb24gdGFrZVRva2Vuc0FmdGVyV2hpbGUoc291cmNlQ29kZSwgbm9kZSwgY29uZGl0aW9uKSB7XG4gIGNvbnN0IHRva2VucyA9IGdldFRva2Vuc09yQ29tbWVudHNBZnRlcihzb3VyY2VDb2RlLCBub2RlLCAxMDApO1xuICBjb25zdCByZXN1bHQgPSBbXTtcbiAgZm9yIChsZXQgaSA9IDA7IGkgPCB0b2tlbnMubGVuZ3RoOyBpKyspIHtcbiAgICBpZiAoY29uZGl0aW9uKHRva2Vuc1tpXSkpIHtcbiAgICAgIHJlc3VsdC5wdXNoKHRva2Vuc1tpXSk7XG4gICAgfSBlbHNlIHtcbiAgICAgIGJyZWFrO1xuICAgIH1cbiAgfVxuICByZXR1cm4gcmVzdWx0O1xufVxuXG5mdW5jdGlvbiB0YWtlVG9rZW5zQmVmb3JlV2hpbGUoc291cmNlQ29kZSwgbm9kZSwgY29uZGl0aW9uKSB7XG4gIGNvbnN0IHRva2VucyA9IGdldFRva2Vuc09yQ29tbWVudHNCZWZvcmUoc291cmNlQ29kZSwgbm9kZSwgMTAwKTtcbiAgY29uc3QgcmVzdWx0ID0gW107XG4gIGZvciAobGV0IGkgPSB0b2tlbnMubGVuZ3RoIC0gMTsgaSA+PSAwOyBpLS0pIHtcbiAgICBpZiAoY29uZGl0aW9uKHRva2Vuc1tpXSkpIHtcbiAgICAgIHJlc3VsdC5wdXNoKHRva2Vuc1tpXSk7XG4gICAgfSBlbHNlIHtcbiAgICAgIGJyZWFrO1xuICAgIH1cbiAgfVxuICByZXR1cm4gcmVzdWx0LnJldmVyc2UoKTtcbn1cblxuZnVuY3Rpb24gZmluZE91dE9mT3JkZXIoaW1wb3J0ZWQpIHtcbiAgaWYgKGltcG9ydGVkLmxlbmd0aCA9PT0gMCkge1xuICAgIHJldHVybiBbXTtcbiAgfVxuICBsZXQgbWF4U2VlblJhbmtOb2RlID0gaW1wb3J0ZWRbMF07XG4gIHJldHVybiBpbXBvcnRlZC5maWx0ZXIoZnVuY3Rpb24gKGltcG9ydGVkTW9kdWxlKSB7XG4gICAgY29uc3QgcmVzID0gaW1wb3J0ZWRNb2R1bGUucmFuayA8IG1heFNlZW5SYW5rTm9kZS5yYW5rO1xuICAgIGlmIChtYXhTZWVuUmFua05vZGUucmFuayA8IGltcG9ydGVkTW9kdWxlLnJhbmspIHtcbiAgICAgIG1heFNlZW5SYW5rTm9kZSA9IGltcG9ydGVkTW9kdWxlO1xuICAgIH1cbiAgICByZXR1cm4gcmVzO1xuICB9KTtcbn1cblxuZnVuY3Rpb24gZmluZFJvb3ROb2RlKG5vZGUpIHtcbiAgbGV0IHBhcmVudCA9IG5vZGU7XG4gIHdoaWxlIChwYXJlbnQucGFyZW50ICE9IG51bGwgJiYgcGFyZW50LnBhcmVudC5ib2R5ID09IG51bGwpIHtcbiAgICBwYXJlbnQgPSBwYXJlbnQucGFyZW50O1xuICB9XG4gIHJldHVybiBwYXJlbnQ7XG59XG5cbmZ1bmN0aW9uIGNvbW1lbnRPblNhbWVMaW5lQXMobm9kZSkge1xuICByZXR1cm4gKHRva2VuKSA9PiAodG9rZW4udHlwZSA9PT0gJ0Jsb2NrJyB8fCAgdG9rZW4udHlwZSA9PT0gJ0xpbmUnKVxuICAgICAgJiYgdG9rZW4ubG9jLnN0YXJ0LmxpbmUgPT09IHRva2VuLmxvYy5lbmQubGluZVxuICAgICAgJiYgdG9rZW4ubG9jLmVuZC5saW5lID09PSBub2RlLmxvYy5lbmQubGluZTtcbn1cblxuZnVuY3Rpb24gZmluZEVuZE9mTGluZVdpdGhDb21tZW50cyhzb3VyY2VDb2RlLCBub2RlKSB7XG4gIGNvbnN0IHRva2Vuc1RvRW5kT2ZMaW5lID0gdGFrZVRva2Vuc0FmdGVyV2hpbGUoc291cmNlQ29kZSwgbm9kZSwgY29tbWVudE9uU2FtZUxpbmVBcyhub2RlKSk7XG4gIGNvbnN0IGVuZE9mVG9rZW5zID0gdG9rZW5zVG9FbmRPZkxpbmUubGVuZ3RoID4gMFxuICAgID8gdG9rZW5zVG9FbmRPZkxpbmVbdG9rZW5zVG9FbmRPZkxpbmUubGVuZ3RoIC0gMV0ucmFuZ2VbMV1cbiAgICA6IG5vZGUucmFuZ2VbMV07XG4gIGxldCByZXN1bHQgPSBlbmRPZlRva2VucztcbiAgZm9yIChsZXQgaSA9IGVuZE9mVG9rZW5zOyBpIDwgc291cmNlQ29kZS50ZXh0Lmxlbmd0aDsgaSsrKSB7XG4gICAgaWYgKHNvdXJjZUNvZGUudGV4dFtpXSA9PT0gJ1xcbicpIHtcbiAgICAgIHJlc3VsdCA9IGkgKyAxO1xuICAgICAgYnJlYWs7XG4gICAgfVxuICAgIGlmIChzb3VyY2VDb2RlLnRleHRbaV0gIT09ICcgJyAmJiBzb3VyY2VDb2RlLnRleHRbaV0gIT09ICdcXHQnICYmIHNvdXJjZUNvZGUudGV4dFtpXSAhPT0gJ1xccicpIHtcbiAgICAgIGJyZWFrO1xuICAgIH1cbiAgICByZXN1bHQgPSBpICsgMTtcbiAgfVxuICByZXR1cm4gcmVzdWx0O1xufVxuXG5mdW5jdGlvbiBmaW5kU3RhcnRPZkxpbmVXaXRoQ29tbWVudHMoc291cmNlQ29kZSwgbm9kZSkge1xuICBjb25zdCB0b2tlbnNUb0VuZE9mTGluZSA9IHRha2VUb2tlbnNCZWZvcmVXaGlsZShzb3VyY2VDb2RlLCBub2RlLCBjb21tZW50T25TYW1lTGluZUFzKG5vZGUpKTtcbiAgY29uc3Qgc3RhcnRPZlRva2VucyA9IHRva2Vuc1RvRW5kT2ZMaW5lLmxlbmd0aCA+IDAgPyB0b2tlbnNUb0VuZE9mTGluZVswXS5yYW5nZVswXSA6IG5vZGUucmFuZ2VbMF07XG4gIGxldCByZXN1bHQgPSBzdGFydE9mVG9rZW5zO1xuICBmb3IgKGxldCBpID0gc3RhcnRPZlRva2VucyAtIDE7IGkgPiAwOyBpLS0pIHtcbiAgICBpZiAoc291cmNlQ29kZS50ZXh0W2ldICE9PSAnICcgJiYgc291cmNlQ29kZS50ZXh0W2ldICE9PSAnXFx0Jykge1xuICAgICAgYnJlYWs7XG4gICAgfVxuICAgIHJlc3VsdCA9IGk7XG4gIH1cbiAgcmV0dXJuIHJlc3VsdDtcbn1cblxuZnVuY3Rpb24gaXNSZXF1aXJlRXhwcmVzc2lvbihleHByKSB7XG4gIHJldHVybiBleHByICE9IG51bGxcbiAgICAmJiBleHByLnR5cGUgPT09ICdDYWxsRXhwcmVzc2lvbidcbiAgICAmJiBleHByLmNhbGxlZSAhPSBudWxsXG4gICAgJiYgZXhwci5jYWxsZWUubmFtZSA9PT0gJ3JlcXVpcmUnXG4gICAgJiYgZXhwci5hcmd1bWVudHMgIT0gbnVsbFxuICAgICYmIGV4cHIuYXJndW1lbnRzLmxlbmd0aCA9PT0gMVxuICAgICYmIGV4cHIuYXJndW1lbnRzWzBdLnR5cGUgPT09ICdMaXRlcmFsJztcbn1cblxuZnVuY3Rpb24gaXNTdXBwb3J0ZWRSZXF1aXJlTW9kdWxlKG5vZGUpIHtcbiAgaWYgKG5vZGUudHlwZSAhPT0gJ1ZhcmlhYmxlRGVjbGFyYXRpb24nKSB7XG4gICAgcmV0dXJuIGZhbHNlO1xuICB9XG4gIGlmIChub2RlLmRlY2xhcmF0aW9ucy5sZW5ndGggIT09IDEpIHtcbiAgICByZXR1cm4gZmFsc2U7XG4gIH1cbiAgY29uc3QgZGVjbCA9IG5vZGUuZGVjbGFyYXRpb25zWzBdO1xuICBjb25zdCBpc1BsYWluUmVxdWlyZSA9IGRlY2wuaWRcbiAgICAmJiAoZGVjbC5pZC50eXBlID09PSAnSWRlbnRpZmllcicgfHwgZGVjbC5pZC50eXBlID09PSAnT2JqZWN0UGF0dGVybicpXG4gICAgJiYgaXNSZXF1aXJlRXhwcmVzc2lvbihkZWNsLmluaXQpO1xuICBjb25zdCBpc1JlcXVpcmVXaXRoTWVtYmVyRXhwcmVzc2lvbiA9IGRlY2wuaWRcbiAgICAmJiAoZGVjbC5pZC50eXBlID09PSAnSWRlbnRpZmllcicgfHwgZGVjbC5pZC50eXBlID09PSAnT2JqZWN0UGF0dGVybicpXG4gICAgJiYgZGVjbC5pbml0ICE9IG51bGxcbiAgICAmJiBkZWNsLmluaXQudHlwZSA9PT0gJ0NhbGxFeHByZXNzaW9uJ1xuICAgICYmIGRlY2wuaW5pdC5jYWxsZWUgIT0gbnVsbFxuICAgICYmIGRlY2wuaW5pdC5jYWxsZWUudHlwZSA9PT0gJ01lbWJlckV4cHJlc3Npb24nXG4gICAgJiYgaXNSZXF1aXJlRXhwcmVzc2lvbihkZWNsLmluaXQuY2FsbGVlLm9iamVjdCk7XG4gIHJldHVybiBpc1BsYWluUmVxdWlyZSB8fCBpc1JlcXVpcmVXaXRoTWVtYmVyRXhwcmVzc2lvbjtcbn1cblxuZnVuY3Rpb24gaXNQbGFpbkltcG9ydE1vZHVsZShub2RlKSB7XG4gIHJldHVybiBub2RlLnR5cGUgPT09ICdJbXBvcnREZWNsYXJhdGlvbicgJiYgbm9kZS5zcGVjaWZpZXJzICE9IG51bGwgJiYgbm9kZS5zcGVjaWZpZXJzLmxlbmd0aCA+IDA7XG59XG5cbmZ1bmN0aW9uIGlzUGxhaW5JbXBvcnRFcXVhbHMobm9kZSkge1xuICByZXR1cm4gbm9kZS50eXBlID09PSAnVFNJbXBvcnRFcXVhbHNEZWNsYXJhdGlvbicgJiYgbm9kZS5tb2R1bGVSZWZlcmVuY2UuZXhwcmVzc2lvbjtcbn1cblxuZnVuY3Rpb24gY2FuQ3Jvc3NOb2RlV2hpbGVSZW9yZGVyKG5vZGUpIHtcbiAgcmV0dXJuIGlzU3VwcG9ydGVkUmVxdWlyZU1vZHVsZShub2RlKSB8fCBpc1BsYWluSW1wb3J0TW9kdWxlKG5vZGUpIHx8IGlzUGxhaW5JbXBvcnRFcXVhbHMobm9kZSk7XG59XG5cbmZ1bmN0aW9uIGNhblJlb3JkZXJJdGVtcyhmaXJzdE5vZGUsIHNlY29uZE5vZGUpIHtcbiAgY29uc3QgcGFyZW50ID0gZmlyc3ROb2RlLnBhcmVudDtcbiAgY29uc3QgW2ZpcnN0SW5kZXgsIHNlY29uZEluZGV4XSA9IFtcbiAgICBwYXJlbnQuYm9keS5pbmRleE9mKGZpcnN0Tm9kZSksXG4gICAgcGFyZW50LmJvZHkuaW5kZXhPZihzZWNvbmROb2RlKSxcbiAgXS5zb3J0KCk7XG4gIGNvbnN0IG5vZGVzQmV0d2VlbiA9IHBhcmVudC5ib2R5LnNsaWNlKGZpcnN0SW5kZXgsIHNlY29uZEluZGV4ICsgMSk7XG4gIGZvciAoY29uc3Qgbm9kZUJldHdlZW4gb2Ygbm9kZXNCZXR3ZWVuKSB7XG4gICAgaWYgKCFjYW5Dcm9zc05vZGVXaGlsZVJlb3JkZXIobm9kZUJldHdlZW4pKSB7XG4gICAgICByZXR1cm4gZmFsc2U7XG4gICAgfVxuICB9XG4gIHJldHVybiB0cnVlO1xufVxuXG5mdW5jdGlvbiBtYWtlSW1wb3J0RGVzY3JpcHRpb24obm9kZSkge1xuICBpZiAobm9kZS5ub2RlLmltcG9ydEtpbmQgPT09ICd0eXBlJykge1xuICAgIHJldHVybiAndHlwZSBpbXBvcnQnO1xuICB9XG4gIGlmIChub2RlLm5vZGUuaW1wb3J0S2luZCA9PT0gJ3R5cGVvZicpIHtcbiAgICByZXR1cm4gJ3R5cGVvZiBpbXBvcnQnO1xuICB9XG4gIHJldHVybiAnaW1wb3J0Jztcbn1cblxuZnVuY3Rpb24gZml4T3V0T2ZPcmRlcihjb250ZXh0LCBmaXJzdE5vZGUsIHNlY29uZE5vZGUsIG9yZGVyKSB7XG4gIGNvbnN0IHNvdXJjZUNvZGUgPSBjb250ZXh0LmdldFNvdXJjZUNvZGUoKTtcblxuICBjb25zdCBmaXJzdFJvb3QgPSBmaW5kUm9vdE5vZGUoZmlyc3ROb2RlLm5vZGUpO1xuICBjb25zdCBmaXJzdFJvb3RTdGFydCA9IGZpbmRTdGFydE9mTGluZVdpdGhDb21tZW50cyhzb3VyY2VDb2RlLCBmaXJzdFJvb3QpO1xuICBjb25zdCBmaXJzdFJvb3RFbmQgPSBmaW5kRW5kT2ZMaW5lV2l0aENvbW1lbnRzKHNvdXJjZUNvZGUsIGZpcnN0Um9vdCk7XG5cbiAgY29uc3Qgc2Vjb25kUm9vdCA9IGZpbmRSb290Tm9kZShzZWNvbmROb2RlLm5vZGUpO1xuICBjb25zdCBzZWNvbmRSb290U3RhcnQgPSBmaW5kU3RhcnRPZkxpbmVXaXRoQ29tbWVudHMoc291cmNlQ29kZSwgc2Vjb25kUm9vdCk7XG4gIGNvbnN0IHNlY29uZFJvb3RFbmQgPSBmaW5kRW5kT2ZMaW5lV2l0aENvbW1lbnRzKHNvdXJjZUNvZGUsIHNlY29uZFJvb3QpO1xuICBjb25zdCBjYW5GaXggPSBjYW5SZW9yZGVySXRlbXMoZmlyc3RSb290LCBzZWNvbmRSb290KTtcblxuICBsZXQgbmV3Q29kZSA9IHNvdXJjZUNvZGUudGV4dC5zdWJzdHJpbmcoc2Vjb25kUm9vdFN0YXJ0LCBzZWNvbmRSb290RW5kKTtcbiAgaWYgKG5ld0NvZGVbbmV3Q29kZS5sZW5ndGggLSAxXSAhPT0gJ1xcbicpIHtcbiAgICBuZXdDb2RlID0gYCR7bmV3Q29kZX1cXG5gO1xuICB9XG5cbiAgY29uc3QgZmlyc3RJbXBvcnQgPSBgJHttYWtlSW1wb3J0RGVzY3JpcHRpb24oZmlyc3ROb2RlKX0gb2YgXFxgJHtmaXJzdE5vZGUuZGlzcGxheU5hbWV9XFxgYDtcbiAgY29uc3Qgc2Vjb25kSW1wb3J0ID0gYFxcYCR7c2Vjb25kTm9kZS5kaXNwbGF5TmFtZX1cXGAgJHttYWtlSW1wb3J0RGVzY3JpcHRpb24oc2Vjb25kTm9kZSl9YDtcbiAgY29uc3QgbWVzc2FnZSA9IGAke3NlY29uZEltcG9ydH0gc2hvdWxkIG9jY3VyICR7b3JkZXJ9ICR7Zmlyc3RJbXBvcnR9YDtcblxuICBpZiAob3JkZXIgPT09ICdiZWZvcmUnKSB7XG4gICAgY29udGV4dC5yZXBvcnQoe1xuICAgICAgbm9kZTogc2Vjb25kTm9kZS5ub2RlLFxuICAgICAgbWVzc2FnZSxcbiAgICAgIGZpeDogY2FuRml4ICYmICgoZml4ZXIpID0+IGZpeGVyLnJlcGxhY2VUZXh0UmFuZ2UoXG4gICAgICAgIFtmaXJzdFJvb3RTdGFydCwgc2Vjb25kUm9vdEVuZF0sXG4gICAgICAgIG5ld0NvZGUgKyBzb3VyY2VDb2RlLnRleHQuc3Vic3RyaW5nKGZpcnN0Um9vdFN0YXJ0LCBzZWNvbmRSb290U3RhcnQpLFxuICAgICAgKSksXG4gICAgfSk7XG4gIH0gZWxzZSBpZiAob3JkZXIgPT09ICdhZnRlcicpIHtcbiAgICBjb250ZXh0LnJlcG9ydCh7XG4gICAgICBub2RlOiBzZWNvbmROb2RlLm5vZGUsXG4gICAgICBtZXNzYWdlLFxuICAgICAgZml4OiBjYW5GaXggJiYgKChmaXhlcikgPT4gZml4ZXIucmVwbGFjZVRleHRSYW5nZShcbiAgICAgICAgW3NlY29uZFJvb3RTdGFydCwgZmlyc3RSb290RW5kXSxcbiAgICAgICAgc291cmNlQ29kZS50ZXh0LnN1YnN0cmluZyhzZWNvbmRSb290RW5kLCBmaXJzdFJvb3RFbmQpICsgbmV3Q29kZSxcbiAgICAgICkpLFxuICAgIH0pO1xuICB9XG59XG5cbmZ1bmN0aW9uIHJlcG9ydE91dE9mT3JkZXIoY29udGV4dCwgaW1wb3J0ZWQsIG91dE9mT3JkZXIsIG9yZGVyKSB7XG4gIG91dE9mT3JkZXIuZm9yRWFjaChmdW5jdGlvbiAoaW1wKSB7XG4gICAgY29uc3QgZm91bmQgPSBpbXBvcnRlZC5maW5kKGZ1bmN0aW9uIGhhc0hpZ2hlclJhbmsoaW1wb3J0ZWRJdGVtKSB7XG4gICAgICByZXR1cm4gaW1wb3J0ZWRJdGVtLnJhbmsgPiBpbXAucmFuaztcbiAgICB9KTtcbiAgICBmaXhPdXRPZk9yZGVyKGNvbnRleHQsIGZvdW5kLCBpbXAsIG9yZGVyKTtcbiAgfSk7XG59XG5cbmZ1bmN0aW9uIG1ha2VPdXRPZk9yZGVyUmVwb3J0KGNvbnRleHQsIGltcG9ydGVkKSB7XG4gIGNvbnN0IG91dE9mT3JkZXIgPSBmaW5kT3V0T2ZPcmRlcihpbXBvcnRlZCk7XG4gIGlmICghb3V0T2ZPcmRlci5sZW5ndGgpIHtcbiAgICByZXR1cm47XG4gIH1cblxuICAvLyBUaGVyZSBhcmUgdGhpbmdzIHRvIHJlcG9ydC4gVHJ5IHRvIG1pbmltaXplIHRoZSBudW1iZXIgb2YgcmVwb3J0ZWQgZXJyb3JzLlxuICBjb25zdCByZXZlcnNlZEltcG9ydGVkID0gcmV2ZXJzZShpbXBvcnRlZCk7XG4gIGNvbnN0IHJldmVyc2VkT3JkZXIgPSBmaW5kT3V0T2ZPcmRlcihyZXZlcnNlZEltcG9ydGVkKTtcbiAgaWYgKHJldmVyc2VkT3JkZXIubGVuZ3RoIDwgb3V0T2ZPcmRlci5sZW5ndGgpIHtcbiAgICByZXBvcnRPdXRPZk9yZGVyKGNvbnRleHQsIHJldmVyc2VkSW1wb3J0ZWQsIHJldmVyc2VkT3JkZXIsICdhZnRlcicpO1xuICAgIHJldHVybjtcbiAgfVxuICByZXBvcnRPdXRPZk9yZGVyKGNvbnRleHQsIGltcG9ydGVkLCBvdXRPZk9yZGVyLCAnYmVmb3JlJyk7XG59XG5cbmNvbnN0IGNvbXBhcmVTdHJpbmcgPSAoYSwgYikgPT4ge1xuICBpZiAoYSA8IGIpIHtcbiAgICByZXR1cm4gLTE7XG4gIH1cbiAgaWYgKGEgPiBiKSB7XG4gICAgcmV0dXJuIDE7XG4gIH1cbiAgcmV0dXJuIDA7XG59O1xuXG4vKiogU29tZSBwYXJzZXJzIChsYW5ndWFnZXMgd2l0aG91dCB0eXBlcykgZG9uJ3QgcHJvdmlkZSBJbXBvcnRLaW5kICovXG5jb25zdCBERUFGVUxUX0lNUE9SVF9LSU5EID0gJ3ZhbHVlJztcbmNvbnN0IGdldE5vcm1hbGl6ZWRWYWx1ZSA9IChub2RlLCB0b0xvd2VyQ2FzZSkgPT4ge1xuICBjb25zdCB2YWx1ZSA9IG5vZGUudmFsdWU7XG4gIHJldHVybiB0b0xvd2VyQ2FzZSA/IFN0cmluZyh2YWx1ZSkudG9Mb3dlckNhc2UoKSA6IHZhbHVlO1xufTtcblxuZnVuY3Rpb24gZ2V0U29ydGVyKGFscGhhYmV0aXplT3B0aW9ucykge1xuICBjb25zdCBtdWx0aXBsaWVyID0gYWxwaGFiZXRpemVPcHRpb25zLm9yZGVyID09PSAnYXNjJyA/IDEgOiAtMTtcbiAgY29uc3Qgb3JkZXJJbXBvcnRLaW5kID0gYWxwaGFiZXRpemVPcHRpb25zLm9yZGVySW1wb3J0S2luZDtcbiAgY29uc3QgbXVsdGlwbGllckltcG9ydEtpbmQgPSBvcmRlckltcG9ydEtpbmQgIT09ICdpZ25vcmUnXG4gICAgJiYgKGFscGhhYmV0aXplT3B0aW9ucy5vcmRlckltcG9ydEtpbmQgPT09ICdhc2MnID8gMSA6IC0xKTtcblxuICByZXR1cm4gZnVuY3Rpb24gaW1wb3J0c1NvcnRlcihub2RlQSwgbm9kZUIpIHtcbiAgICBjb25zdCBpbXBvcnRBID0gZ2V0Tm9ybWFsaXplZFZhbHVlKG5vZGVBLCBhbHBoYWJldGl6ZU9wdGlvbnMuY2FzZUluc2Vuc2l0aXZlKTtcbiAgICBjb25zdCBpbXBvcnRCID0gZ2V0Tm9ybWFsaXplZFZhbHVlKG5vZGVCLCBhbHBoYWJldGl6ZU9wdGlvbnMuY2FzZUluc2Vuc2l0aXZlKTtcbiAgICBsZXQgcmVzdWx0ID0gMDtcblxuICAgIGlmICghaW5jbHVkZXMoaW1wb3J0QSwgJy8nKSAmJiAhaW5jbHVkZXMoaW1wb3J0QiwgJy8nKSkge1xuICAgICAgcmVzdWx0ID0gY29tcGFyZVN0cmluZyhpbXBvcnRBLCBpbXBvcnRCKTtcbiAgICB9IGVsc2Uge1xuICAgICAgY29uc3QgQSA9IGltcG9ydEEuc3BsaXQoJy8nKTtcbiAgICAgIGNvbnN0IEIgPSBpbXBvcnRCLnNwbGl0KCcvJyk7XG4gICAgICBjb25zdCBhID0gQS5sZW5ndGg7XG4gICAgICBjb25zdCBiID0gQi5sZW5ndGg7XG5cbiAgICAgIGZvciAobGV0IGkgPSAwOyBpIDwgTWF0aC5taW4oYSwgYik7IGkrKykge1xuICAgICAgICAvLyBTa2lwIGNvbXBhcmluZyB0aGUgZmlyc3QgcGF0aCBzZWdtZW50LCBpZiB0aGV5IGFyZSByZWxhdGl2ZSBzZWdtZW50cyBmb3IgYm90aCBpbXBvcnRzXG4gICAgICAgIGlmIChpID09PSAwICYmICgoQVtpXSA9PT0gJy4nIHx8IEFbaV0gPT09ICcuLicpICYmIChCW2ldID09PSAnLicgfHwgQltpXSA9PT0gJy4uJykpKSB7XG4gICAgICAgICAgLy8gSWYgb25lIGlzIHNpYmxpbmcgYW5kIHRoZSBvdGhlciBwYXJlbnQgaW1wb3J0LCBubyBuZWVkIHRvIGNvbXBhcmUgYXQgYWxsLCBzaW5jZSB0aGUgcGF0aHMgYmVsb25nIGluIGRpZmZlcmVudCBncm91cHNcbiAgICAgICAgICBpZiAoQVtpXSAhPT0gQltpXSkgeyBicmVhazsgfVxuICAgICAgICAgIGNvbnRpbnVlO1xuICAgICAgICB9XG4gICAgICAgIHJlc3VsdCA9IGNvbXBhcmVTdHJpbmcoQVtpXSwgQltpXSk7XG4gICAgICAgIGlmIChyZXN1bHQpIHsgYnJlYWs7IH1cbiAgICAgIH1cblxuICAgICAgaWYgKCFyZXN1bHQgJiYgYSAhPT0gYikge1xuICAgICAgICByZXN1bHQgPSBhIDwgYiA/IC0xIDogMTtcbiAgICAgIH1cbiAgICB9XG5cbiAgICByZXN1bHQgPSByZXN1bHQgKiBtdWx0aXBsaWVyO1xuXG4gICAgLy8gSW4gY2FzZSB0aGUgcGF0aHMgYXJlIGVxdWFsIChyZXN1bHQgPT09IDApLCBzb3J0IHRoZW0gYnkgaW1wb3J0S2luZFxuICAgIGlmICghcmVzdWx0ICYmIG11bHRpcGxpZXJJbXBvcnRLaW5kKSB7XG4gICAgICByZXN1bHQgPSBtdWx0aXBsaWVySW1wb3J0S2luZCAqIGNvbXBhcmVTdHJpbmcoXG4gICAgICAgIG5vZGVBLm5vZGUuaW1wb3J0S2luZCB8fCBERUFGVUxUX0lNUE9SVF9LSU5ELFxuICAgICAgICBub2RlQi5ub2RlLmltcG9ydEtpbmQgfHwgREVBRlVMVF9JTVBPUlRfS0lORCxcbiAgICAgICk7XG4gICAgfVxuXG4gICAgcmV0dXJuIHJlc3VsdDtcbiAgfTtcbn1cblxuZnVuY3Rpb24gbXV0YXRlUmFua3NUb0FscGhhYmV0aXplKGltcG9ydGVkLCBhbHBoYWJldGl6ZU9wdGlvbnMpIHtcbiAgY29uc3QgZ3JvdXBlZEJ5UmFua3MgPSBncm91cEJ5KGltcG9ydGVkLCAoaXRlbSkgPT4gaXRlbS5yYW5rKTtcblxuICBjb25zdCBzb3J0ZXJGbiA9IGdldFNvcnRlcihhbHBoYWJldGl6ZU9wdGlvbnMpO1xuXG4gIC8vIHNvcnQgZ3JvdXAga2V5cyBzbyB0aGF0IHRoZXkgY2FuIGJlIGl0ZXJhdGVkIG9uIGluIG9yZGVyXG4gIGNvbnN0IGdyb3VwUmFua3MgPSBPYmplY3Qua2V5cyhncm91cGVkQnlSYW5rcykuc29ydChmdW5jdGlvbiAoYSwgYikge1xuICAgIHJldHVybiBhIC0gYjtcbiAgfSk7XG5cbiAgLy8gc29ydCBpbXBvcnRzIGxvY2FsbHkgd2l0aGluIHRoZWlyIGdyb3VwXG4gIGdyb3VwUmFua3MuZm9yRWFjaChmdW5jdGlvbiAoZ3JvdXBSYW5rKSB7XG4gICAgZ3JvdXBlZEJ5UmFua3NbZ3JvdXBSYW5rXS5zb3J0KHNvcnRlckZuKTtcbiAgfSk7XG5cbiAgLy8gYXNzaWduIGdsb2JhbGx5IHVuaXF1ZSByYW5rIHRvIGVhY2ggaW1wb3J0XG4gIGxldCBuZXdSYW5rID0gMDtcbiAgY29uc3QgYWxwaGFiZXRpemVkUmFua3MgPSBncm91cFJhbmtzLnJlZHVjZShmdW5jdGlvbiAoYWNjLCBncm91cFJhbmspIHtcbiAgICBncm91cGVkQnlSYW5rc1tncm91cFJhbmtdLmZvckVhY2goZnVuY3Rpb24gKGltcG9ydGVkSXRlbSkge1xuICAgICAgYWNjW2Ake2ltcG9ydGVkSXRlbS52YWx1ZX18JHtpbXBvcnRlZEl0ZW0ubm9kZS5pbXBvcnRLaW5kfWBdID0gcGFyc2VJbnQoZ3JvdXBSYW5rLCAxMCkgKyBuZXdSYW5rO1xuICAgICAgbmV3UmFuayArPSAxO1xuICAgIH0pO1xuICAgIHJldHVybiBhY2M7XG4gIH0sIHt9KTtcblxuICAvLyBtdXRhdGUgdGhlIG9yaWdpbmFsIGdyb3VwLXJhbmsgd2l0aCBhbHBoYWJldGl6ZWQtcmFua1xuICBpbXBvcnRlZC5mb3JFYWNoKGZ1bmN0aW9uIChpbXBvcnRlZEl0ZW0pIHtcbiAgICBpbXBvcnRlZEl0ZW0ucmFuayA9IGFscGhhYmV0aXplZFJhbmtzW2Ake2ltcG9ydGVkSXRlbS52YWx1ZX18JHtpbXBvcnRlZEl0ZW0ubm9kZS5pbXBvcnRLaW5kfWBdO1xuICB9KTtcbn1cblxuLy8gREVURUNUSU5HXG5cbmZ1bmN0aW9uIGNvbXB1dGVQYXRoUmFuayhyYW5rcywgcGF0aEdyb3VwcywgcGF0aCwgbWF4UG9zaXRpb24pIHtcbiAgZm9yIChsZXQgaSA9IDAsIGwgPSBwYXRoR3JvdXBzLmxlbmd0aDsgaSA8IGw7IGkrKykge1xuICAgIGNvbnN0IHsgcGF0dGVybiwgcGF0dGVybk9wdGlvbnMsIGdyb3VwLCBwb3NpdGlvbiA9IDEgfSA9IHBhdGhHcm91cHNbaV07XG4gICAgaWYgKG1pbmltYXRjaChwYXRoLCBwYXR0ZXJuLCBwYXR0ZXJuT3B0aW9ucyB8fCB7IG5vY29tbWVudDogdHJ1ZSB9KSkge1xuICAgICAgcmV0dXJuIHJhbmtzW2dyb3VwXSArIHBvc2l0aW9uIC8gbWF4UG9zaXRpb247XG4gICAgfVxuICB9XG59XG5cbmZ1bmN0aW9uIGNvbXB1dGVSYW5rKGNvbnRleHQsIHJhbmtzLCBpbXBvcnRFbnRyeSwgZXhjbHVkZWRJbXBvcnRUeXBlcykge1xuICBsZXQgaW1wVHlwZTtcbiAgbGV0IHJhbms7XG4gIGlmIChpbXBvcnRFbnRyeS50eXBlID09PSAnaW1wb3J0Om9iamVjdCcpIHtcbiAgICBpbXBUeXBlID0gJ29iamVjdCc7XG4gIH0gZWxzZSBpZiAoaW1wb3J0RW50cnkubm9kZS5pbXBvcnRLaW5kID09PSAndHlwZScgJiYgcmFua3Mub21pdHRlZFR5cGVzLmluZGV4T2YoJ3R5cGUnKSA9PT0gLTEpIHtcbiAgICBpbXBUeXBlID0gJ3R5cGUnO1xuICB9IGVsc2Uge1xuICAgIGltcFR5cGUgPSBpbXBvcnRUeXBlKGltcG9ydEVudHJ5LnZhbHVlLCBjb250ZXh0KTtcbiAgfVxuICBpZiAoIWV4Y2x1ZGVkSW1wb3J0VHlwZXMuaGFzKGltcFR5cGUpKSB7XG4gICAgcmFuayA9IGNvbXB1dGVQYXRoUmFuayhyYW5rcy5ncm91cHMsIHJhbmtzLnBhdGhHcm91cHMsIGltcG9ydEVudHJ5LnZhbHVlLCByYW5rcy5tYXhQb3NpdGlvbik7XG4gIH1cbiAgaWYgKHR5cGVvZiByYW5rID09PSAndW5kZWZpbmVkJykge1xuICAgIHJhbmsgPSByYW5rcy5ncm91cHNbaW1wVHlwZV07XG4gIH1cbiAgaWYgKGltcG9ydEVudHJ5LnR5cGUgIT09ICdpbXBvcnQnICYmICFpbXBvcnRFbnRyeS50eXBlLnN0YXJ0c1dpdGgoJ2ltcG9ydDonKSkge1xuICAgIHJhbmsgKz0gMTAwO1xuICB9XG5cbiAgcmV0dXJuIHJhbms7XG59XG5cbmZ1bmN0aW9uIHJlZ2lzdGVyTm9kZShjb250ZXh0LCBpbXBvcnRFbnRyeSwgcmFua3MsIGltcG9ydGVkLCBleGNsdWRlZEltcG9ydFR5cGVzKSB7XG4gIGNvbnN0IHJhbmsgPSBjb21wdXRlUmFuayhjb250ZXh0LCByYW5rcywgaW1wb3J0RW50cnksIGV4Y2x1ZGVkSW1wb3J0VHlwZXMpO1xuICBpZiAocmFuayAhPT0gLTEpIHtcbiAgICBpbXBvcnRlZC5wdXNoKHsgLi4uaW1wb3J0RW50cnksIHJhbmsgfSk7XG4gIH1cbn1cblxuZnVuY3Rpb24gZ2V0UmVxdWlyZUJsb2NrKG5vZGUpIHtcbiAgbGV0IG4gPSBub2RlO1xuICAvLyBIYW5kbGUgY2FzZXMgbGlrZSBgY29uc3QgYmF6ID0gcmVxdWlyZSgnZm9vJykuYmFyLmJhemBcbiAgLy8gYW5kIGBjb25zdCBmb28gPSByZXF1aXJlKCdmb28nKSgpYFxuICB3aGlsZSAoXG4gICAgbi5wYXJlbnQudHlwZSA9PT0gJ01lbWJlckV4cHJlc3Npb24nICYmIG4ucGFyZW50Lm9iamVjdCA9PT0gblxuICAgIHx8IG4ucGFyZW50LnR5cGUgPT09ICdDYWxsRXhwcmVzc2lvbicgJiYgbi5wYXJlbnQuY2FsbGVlID09PSBuXG4gICkge1xuICAgIG4gPSBuLnBhcmVudDtcbiAgfVxuICBpZiAoXG4gICAgbi5wYXJlbnQudHlwZSA9PT0gJ1ZhcmlhYmxlRGVjbGFyYXRvcidcbiAgICAmJiBuLnBhcmVudC5wYXJlbnQudHlwZSA9PT0gJ1ZhcmlhYmxlRGVjbGFyYXRpb24nXG4gICAgJiYgbi5wYXJlbnQucGFyZW50LnBhcmVudC50eXBlID09PSAnUHJvZ3JhbSdcbiAgKSB7XG4gICAgcmV0dXJuIG4ucGFyZW50LnBhcmVudC5wYXJlbnQ7XG4gIH1cbn1cblxuY29uc3QgdHlwZXMgPSBbJ2J1aWx0aW4nLCAnZXh0ZXJuYWwnLCAnaW50ZXJuYWwnLCAndW5rbm93bicsICdwYXJlbnQnLCAnc2libGluZycsICdpbmRleCcsICdvYmplY3QnLCAndHlwZSddO1xuXG4vLyBDcmVhdGVzIGFuIG9iamVjdCB3aXRoIHR5cGUtcmFuayBwYWlycy5cbi8vIEV4YW1wbGU6IHsgaW5kZXg6IDAsIHNpYmxpbmc6IDEsIHBhcmVudDogMSwgZXh0ZXJuYWw6IDEsIGJ1aWx0aW46IDIsIGludGVybmFsOiAyIH1cbi8vIFdpbGwgdGhyb3cgYW4gZXJyb3IgaWYgaXQgY29udGFpbnMgYSB0eXBlIHRoYXQgZG9lcyBub3QgZXhpc3QsIG9yIGhhcyBhIGR1cGxpY2F0ZVxuZnVuY3Rpb24gY29udmVydEdyb3Vwc1RvUmFua3MoZ3JvdXBzKSB7XG4gIGNvbnN0IHJhbmtPYmplY3QgPSBncm91cHMucmVkdWNlKGZ1bmN0aW9uIChyZXMsIGdyb3VwLCBpbmRleCkge1xuICAgIFtdLmNvbmNhdChncm91cCkuZm9yRWFjaChmdW5jdGlvbiAoZ3JvdXBJdGVtKSB7XG4gICAgICBpZiAodHlwZXMuaW5kZXhPZihncm91cEl0ZW0pID09PSAtMSkge1xuICAgICAgICB0aHJvdyBuZXcgRXJyb3IoYEluY29ycmVjdCBjb25maWd1cmF0aW9uIG9mIHRoZSBydWxlOiBVbmtub3duIHR5cGUgXFxgJHtKU09OLnN0cmluZ2lmeShncm91cEl0ZW0pfVxcYGApO1xuICAgICAgfVxuICAgICAgaWYgKHJlc1tncm91cEl0ZW1dICE9PSB1bmRlZmluZWQpIHtcbiAgICAgICAgdGhyb3cgbmV3IEVycm9yKGBJbmNvcnJlY3QgY29uZmlndXJhdGlvbiBvZiB0aGUgcnVsZTogXFxgJHtncm91cEl0ZW19XFxgIGlzIGR1cGxpY2F0ZWRgKTtcbiAgICAgIH1cbiAgICAgIHJlc1tncm91cEl0ZW1dID0gaW5kZXggKiAyO1xuICAgIH0pO1xuICAgIHJldHVybiByZXM7XG4gIH0sIHt9KTtcblxuICBjb25zdCBvbWl0dGVkVHlwZXMgPSB0eXBlcy5maWx0ZXIoZnVuY3Rpb24gKHR5cGUpIHtcbiAgICByZXR1cm4gdHlwZW9mIHJhbmtPYmplY3RbdHlwZV0gPT09ICd1bmRlZmluZWQnO1xuICB9KTtcblxuICBjb25zdCByYW5rcyA9IG9taXR0ZWRUeXBlcy5yZWR1Y2UoZnVuY3Rpb24gKHJlcywgdHlwZSkge1xuICAgIHJlc1t0eXBlXSA9IGdyb3Vwcy5sZW5ndGggKiAyO1xuICAgIHJldHVybiByZXM7XG4gIH0sIHJhbmtPYmplY3QpO1xuXG4gIHJldHVybiB7IGdyb3VwczogcmFua3MsIG9taXR0ZWRUeXBlcyB9O1xufVxuXG5mdW5jdGlvbiBjb252ZXJ0UGF0aEdyb3Vwc0ZvclJhbmtzKHBhdGhHcm91cHMpIHtcbiAgY29uc3QgYWZ0ZXIgPSB7fTtcbiAgY29uc3QgYmVmb3JlID0ge307XG5cbiAgY29uc3QgdHJhbnNmb3JtZWQgPSBwYXRoR3JvdXBzLm1hcCgocGF0aEdyb3VwLCBpbmRleCkgPT4ge1xuICAgIGNvbnN0IHsgZ3JvdXAsIHBvc2l0aW9uOiBwb3NpdGlvblN0cmluZyB9ID0gcGF0aEdyb3VwO1xuICAgIGxldCBwb3NpdGlvbiA9IDA7XG4gICAgaWYgKHBvc2l0aW9uU3RyaW5nID09PSAnYWZ0ZXInKSB7XG4gICAgICBpZiAoIWFmdGVyW2dyb3VwXSkge1xuICAgICAgICBhZnRlcltncm91cF0gPSAxO1xuICAgICAgfVxuICAgICAgcG9zaXRpb24gPSBhZnRlcltncm91cF0rKztcbiAgICB9IGVsc2UgaWYgKHBvc2l0aW9uU3RyaW5nID09PSAnYmVmb3JlJykge1xuICAgICAgaWYgKCFiZWZvcmVbZ3JvdXBdKSB7XG4gICAgICAgIGJlZm9yZVtncm91cF0gPSBbXTtcbiAgICAgIH1cbiAgICAgIGJlZm9yZVtncm91cF0ucHVzaChpbmRleCk7XG4gICAgfVxuXG4gICAgcmV0dXJuIHsgLi4ucGF0aEdyb3VwLCBwb3NpdGlvbiB9O1xuICB9KTtcblxuICBsZXQgbWF4UG9zaXRpb24gPSAxO1xuXG4gIE9iamVjdC5rZXlzKGJlZm9yZSkuZm9yRWFjaCgoZ3JvdXApID0+IHtcbiAgICBjb25zdCBncm91cExlbmd0aCA9IGJlZm9yZVtncm91cF0ubGVuZ3RoO1xuICAgIGJlZm9yZVtncm91cF0uZm9yRWFjaCgoZ3JvdXBJbmRleCwgaW5kZXgpID0+IHtcbiAgICAgIHRyYW5zZm9ybWVkW2dyb3VwSW5kZXhdLnBvc2l0aW9uID0gLTEgKiAoZ3JvdXBMZW5ndGggLSBpbmRleCk7XG4gICAgfSk7XG4gICAgbWF4UG9zaXRpb24gPSBNYXRoLm1heChtYXhQb3NpdGlvbiwgZ3JvdXBMZW5ndGgpO1xuICB9KTtcblxuICBPYmplY3Qua2V5cyhhZnRlcikuZm9yRWFjaCgoa2V5KSA9PiB7XG4gICAgY29uc3QgZ3JvdXBOZXh0UG9zaXRpb24gPSBhZnRlcltrZXldO1xuICAgIG1heFBvc2l0aW9uID0gTWF0aC5tYXgobWF4UG9zaXRpb24sIGdyb3VwTmV4dFBvc2l0aW9uIC0gMSk7XG4gIH0pO1xuXG4gIHJldHVybiB7XG4gICAgcGF0aEdyb3VwczogdHJhbnNmb3JtZWQsXG4gICAgbWF4UG9zaXRpb246IG1heFBvc2l0aW9uID4gMTAgPyBNYXRoLnBvdygxMCwgTWF0aC5jZWlsKE1hdGgubG9nMTAobWF4UG9zaXRpb24pKSkgOiAxMCxcbiAgfTtcbn1cblxuZnVuY3Rpb24gZml4TmV3TGluZUFmdGVySW1wb3J0KGNvbnRleHQsIHByZXZpb3VzSW1wb3J0KSB7XG4gIGNvbnN0IHByZXZSb290ID0gZmluZFJvb3ROb2RlKHByZXZpb3VzSW1wb3J0Lm5vZGUpO1xuICBjb25zdCB0b2tlbnNUb0VuZE9mTGluZSA9IHRha2VUb2tlbnNBZnRlcldoaWxlKFxuICAgIGNvbnRleHQuZ2V0U291cmNlQ29kZSgpLCBwcmV2Um9vdCwgY29tbWVudE9uU2FtZUxpbmVBcyhwcmV2Um9vdCkpO1xuXG4gIGxldCBlbmRPZkxpbmUgPSBwcmV2Um9vdC5yYW5nZVsxXTtcbiAgaWYgKHRva2Vuc1RvRW5kT2ZMaW5lLmxlbmd0aCA+IDApIHtcbiAgICBlbmRPZkxpbmUgPSB0b2tlbnNUb0VuZE9mTGluZVt0b2tlbnNUb0VuZE9mTGluZS5sZW5ndGggLSAxXS5yYW5nZVsxXTtcbiAgfVxuICByZXR1cm4gKGZpeGVyKSA9PiBmaXhlci5pbnNlcnRUZXh0QWZ0ZXJSYW5nZShbcHJldlJvb3QucmFuZ2VbMF0sIGVuZE9mTGluZV0sICdcXG4nKTtcbn1cblxuZnVuY3Rpb24gcmVtb3ZlTmV3TGluZUFmdGVySW1wb3J0KGNvbnRleHQsIGN1cnJlbnRJbXBvcnQsIHByZXZpb3VzSW1wb3J0KSB7XG4gIGNvbnN0IHNvdXJjZUNvZGUgPSBjb250ZXh0LmdldFNvdXJjZUNvZGUoKTtcbiAgY29uc3QgcHJldlJvb3QgPSBmaW5kUm9vdE5vZGUocHJldmlvdXNJbXBvcnQubm9kZSk7XG4gIGNvbnN0IGN1cnJSb290ID0gZmluZFJvb3ROb2RlKGN1cnJlbnRJbXBvcnQubm9kZSk7XG4gIGNvbnN0IHJhbmdlVG9SZW1vdmUgPSBbXG4gICAgZmluZEVuZE9mTGluZVdpdGhDb21tZW50cyhzb3VyY2VDb2RlLCBwcmV2Um9vdCksXG4gICAgZmluZFN0YXJ0T2ZMaW5lV2l0aENvbW1lbnRzKHNvdXJjZUNvZGUsIGN1cnJSb290KSxcbiAgXTtcbiAgaWYgKCgvXlxccyokLykudGVzdChzb3VyY2VDb2RlLnRleHQuc3Vic3RyaW5nKHJhbmdlVG9SZW1vdmVbMF0sIHJhbmdlVG9SZW1vdmVbMV0pKSkge1xuICAgIHJldHVybiAoZml4ZXIpID0+IGZpeGVyLnJlbW92ZVJhbmdlKHJhbmdlVG9SZW1vdmUpO1xuICB9XG4gIHJldHVybiB1bmRlZmluZWQ7XG59XG5cbmZ1bmN0aW9uIG1ha2VOZXdsaW5lc0JldHdlZW5SZXBvcnQoY29udGV4dCwgaW1wb3J0ZWQsIG5ld2xpbmVzQmV0d2VlbkltcG9ydHMsIGRpc3RpbmN0R3JvdXApIHtcbiAgY29uc3QgZ2V0TnVtYmVyT2ZFbXB0eUxpbmVzQmV0d2VlbiA9IChjdXJyZW50SW1wb3J0LCBwcmV2aW91c0ltcG9ydCkgPT4ge1xuICAgIGNvbnN0IGxpbmVzQmV0d2VlbkltcG9ydHMgPSBjb250ZXh0LmdldFNvdXJjZUNvZGUoKS5saW5lcy5zbGljZShcbiAgICAgIHByZXZpb3VzSW1wb3J0Lm5vZGUubG9jLmVuZC5saW5lLFxuICAgICAgY3VycmVudEltcG9ydC5ub2RlLmxvYy5zdGFydC5saW5lIC0gMSxcbiAgICApO1xuXG4gICAgcmV0dXJuIGxpbmVzQmV0d2VlbkltcG9ydHMuZmlsdGVyKChsaW5lKSA9PiAhbGluZS50cmltKCkubGVuZ3RoKS5sZW5ndGg7XG4gIH07XG4gIGNvbnN0IGdldElzU3RhcnRPZkRpc3RpbmN0R3JvdXAgPSAoY3VycmVudEltcG9ydCwgcHJldmlvdXNJbXBvcnQpID0+IGN1cnJlbnRJbXBvcnQucmFuayAtIDEgPj0gcHJldmlvdXNJbXBvcnQucmFuaztcbiAgbGV0IHByZXZpb3VzSW1wb3J0ID0gaW1wb3J0ZWRbMF07XG5cbiAgaW1wb3J0ZWQuc2xpY2UoMSkuZm9yRWFjaChmdW5jdGlvbiAoY3VycmVudEltcG9ydCkge1xuICAgIGNvbnN0IGVtcHR5TGluZXNCZXR3ZWVuID0gZ2V0TnVtYmVyT2ZFbXB0eUxpbmVzQmV0d2VlbihjdXJyZW50SW1wb3J0LCBwcmV2aW91c0ltcG9ydCk7XG4gICAgY29uc3QgaXNTdGFydE9mRGlzdGluY3RHcm91cCA9IGdldElzU3RhcnRPZkRpc3RpbmN0R3JvdXAoY3VycmVudEltcG9ydCwgcHJldmlvdXNJbXBvcnQpO1xuXG4gICAgaWYgKG5ld2xpbmVzQmV0d2VlbkltcG9ydHMgPT09ICdhbHdheXMnXG4gICAgICAgIHx8IG5ld2xpbmVzQmV0d2VlbkltcG9ydHMgPT09ICdhbHdheXMtYW5kLWluc2lkZS1ncm91cHMnKSB7XG4gICAgICBpZiAoY3VycmVudEltcG9ydC5yYW5rICE9PSBwcmV2aW91c0ltcG9ydC5yYW5rICYmIGVtcHR5TGluZXNCZXR3ZWVuID09PSAwKSB7XG4gICAgICAgIGlmIChkaXN0aW5jdEdyb3VwIHx8ICFkaXN0aW5jdEdyb3VwICYmIGlzU3RhcnRPZkRpc3RpbmN0R3JvdXApIHtcbiAgICAgICAgICBjb250ZXh0LnJlcG9ydCh7XG4gICAgICAgICAgICBub2RlOiBwcmV2aW91c0ltcG9ydC5ub2RlLFxuICAgICAgICAgICAgbWVzc2FnZTogJ1RoZXJlIHNob3VsZCBiZSBhdCBsZWFzdCBvbmUgZW1wdHkgbGluZSBiZXR3ZWVuIGltcG9ydCBncm91cHMnLFxuICAgICAgICAgICAgZml4OiBmaXhOZXdMaW5lQWZ0ZXJJbXBvcnQoY29udGV4dCwgcHJldmlvdXNJbXBvcnQpLFxuICAgICAgICAgIH0pO1xuICAgICAgICB9XG4gICAgICB9IGVsc2UgaWYgKGVtcHR5TGluZXNCZXR3ZWVuID4gMFxuICAgICAgICAmJiBuZXdsaW5lc0JldHdlZW5JbXBvcnRzICE9PSAnYWx3YXlzLWFuZC1pbnNpZGUtZ3JvdXBzJykge1xuICAgICAgICBpZiAoZGlzdGluY3RHcm91cCAmJiBjdXJyZW50SW1wb3J0LnJhbmsgPT09IHByZXZpb3VzSW1wb3J0LnJhbmsgfHwgIWRpc3RpbmN0R3JvdXAgJiYgIWlzU3RhcnRPZkRpc3RpbmN0R3JvdXApIHtcbiAgICAgICAgICBjb250ZXh0LnJlcG9ydCh7XG4gICAgICAgICAgICBub2RlOiBwcmV2aW91c0ltcG9ydC5ub2RlLFxuICAgICAgICAgICAgbWVzc2FnZTogJ1RoZXJlIHNob3VsZCBiZSBubyBlbXB0eSBsaW5lIHdpdGhpbiBpbXBvcnQgZ3JvdXAnLFxuICAgICAgICAgICAgZml4OiByZW1vdmVOZXdMaW5lQWZ0ZXJJbXBvcnQoY29udGV4dCwgY3VycmVudEltcG9ydCwgcHJldmlvdXNJbXBvcnQpLFxuICAgICAgICAgIH0pO1xuICAgICAgICB9XG4gICAgICB9XG4gICAgfSBlbHNlIGlmIChlbXB0eUxpbmVzQmV0d2VlbiA+IDApIHtcbiAgICAgIGNvbnRleHQucmVwb3J0KHtcbiAgICAgICAgbm9kZTogcHJldmlvdXNJbXBvcnQubm9kZSxcbiAgICAgICAgbWVzc2FnZTogJ1RoZXJlIHNob3VsZCBiZSBubyBlbXB0eSBsaW5lIGJldHdlZW4gaW1wb3J0IGdyb3VwcycsXG4gICAgICAgIGZpeDogcmVtb3ZlTmV3TGluZUFmdGVySW1wb3J0KGNvbnRleHQsIGN1cnJlbnRJbXBvcnQsIHByZXZpb3VzSW1wb3J0KSxcbiAgICAgIH0pO1xuICAgIH1cblxuICAgIHByZXZpb3VzSW1wb3J0ID0gY3VycmVudEltcG9ydDtcbiAgfSk7XG59XG5cbmZ1bmN0aW9uIGdldEFscGhhYmV0aXplQ29uZmlnKG9wdGlvbnMpIHtcbiAgY29uc3QgYWxwaGFiZXRpemUgPSBvcHRpb25zLmFscGhhYmV0aXplIHx8IHt9O1xuICBjb25zdCBvcmRlciA9IGFscGhhYmV0aXplLm9yZGVyIHx8ICdpZ25vcmUnO1xuICBjb25zdCBvcmRlckltcG9ydEtpbmQgPSBhbHBoYWJldGl6ZS5vcmRlckltcG9ydEtpbmQgfHwgJ2lnbm9yZSc7XG4gIGNvbnN0IGNhc2VJbnNlbnNpdGl2ZSA9IGFscGhhYmV0aXplLmNhc2VJbnNlbnNpdGl2ZSB8fCBmYWxzZTtcblxuICByZXR1cm4geyBvcmRlciwgb3JkZXJJbXBvcnRLaW5kLCBjYXNlSW5zZW5zaXRpdmUgfTtcbn1cblxuLy8gVE9ETywgc2VtdmVyLW1ham9yOiBDaGFuZ2UgdGhlIGRlZmF1bHQgb2YgXCJkaXN0aW5jdEdyb3VwXCIgZnJvbSB0cnVlIHRvIGZhbHNlXG5jb25zdCBkZWZhdWx0RGlzdGluY3RHcm91cCA9IHRydWU7XG5cbm1vZHVsZS5leHBvcnRzID0ge1xuICBtZXRhOiB7XG4gICAgdHlwZTogJ3N1Z2dlc3Rpb24nLFxuICAgIGRvY3M6IHtcbiAgICAgIGNhdGVnb3J5OiAnU3R5bGUgZ3VpZGUnLFxuICAgICAgZGVzY3JpcHRpb246ICdFbmZvcmNlIGEgY29udmVudGlvbiBpbiBtb2R1bGUgaW1wb3J0IG9yZGVyLicsXG4gICAgICB1cmw6IGRvY3NVcmwoJ29yZGVyJyksXG4gICAgfSxcblxuICAgIGZpeGFibGU6ICdjb2RlJyxcbiAgICBzY2hlbWE6IFtcbiAgICAgIHtcbiAgICAgICAgdHlwZTogJ29iamVjdCcsXG4gICAgICAgIHByb3BlcnRpZXM6IHtcbiAgICAgICAgICBncm91cHM6IHtcbiAgICAgICAgICAgIHR5cGU6ICdhcnJheScsXG4gICAgICAgICAgfSxcbiAgICAgICAgICBwYXRoR3JvdXBzRXhjbHVkZWRJbXBvcnRUeXBlczoge1xuICAgICAgICAgICAgdHlwZTogJ2FycmF5JyxcbiAgICAgICAgICB9LFxuICAgICAgICAgIGRpc3RpbmN0R3JvdXA6IHtcbiAgICAgICAgICAgIHR5cGU6ICdib29sZWFuJyxcbiAgICAgICAgICAgIGRlZmF1bHQ6IGRlZmF1bHREaXN0aW5jdEdyb3VwLFxuICAgICAgICAgIH0sXG4gICAgICAgICAgcGF0aEdyb3Vwczoge1xuICAgICAgICAgICAgdHlwZTogJ2FycmF5JyxcbiAgICAgICAgICAgIGl0ZW1zOiB7XG4gICAgICAgICAgICAgIHR5cGU6ICdvYmplY3QnLFxuICAgICAgICAgICAgICBwcm9wZXJ0aWVzOiB7XG4gICAgICAgICAgICAgICAgcGF0dGVybjoge1xuICAgICAgICAgICAgICAgICAgdHlwZTogJ3N0cmluZycsXG4gICAgICAgICAgICAgICAgfSxcbiAgICAgICAgICAgICAgICBwYXR0ZXJuT3B0aW9uczoge1xuICAgICAgICAgICAgICAgICAgdHlwZTogJ29iamVjdCcsXG4gICAgICAgICAgICAgICAgfSxcbiAgICAgICAgICAgICAgICBncm91cDoge1xuICAgICAgICAgICAgICAgICAgdHlwZTogJ3N0cmluZycsXG4gICAgICAgICAgICAgICAgICBlbnVtOiB0eXBlcyxcbiAgICAgICAgICAgICAgICB9LFxuICAgICAgICAgICAgICAgIHBvc2l0aW9uOiB7XG4gICAgICAgICAgICAgICAgICB0eXBlOiAnc3RyaW5nJyxcbiAgICAgICAgICAgICAgICAgIGVudW06IFsnYWZ0ZXInLCAnYmVmb3JlJ10sXG4gICAgICAgICAgICAgICAgfSxcbiAgICAgICAgICAgICAgfSxcbiAgICAgICAgICAgICAgYWRkaXRpb25hbFByb3BlcnRpZXM6IGZhbHNlLFxuICAgICAgICAgICAgICByZXF1aXJlZDogWydwYXR0ZXJuJywgJ2dyb3VwJ10sXG4gICAgICAgICAgICB9LFxuICAgICAgICAgIH0sXG4gICAgICAgICAgJ25ld2xpbmVzLWJldHdlZW4nOiB7XG4gICAgICAgICAgICBlbnVtOiBbXG4gICAgICAgICAgICAgICdpZ25vcmUnLFxuICAgICAgICAgICAgICAnYWx3YXlzJyxcbiAgICAgICAgICAgICAgJ2Fsd2F5cy1hbmQtaW5zaWRlLWdyb3VwcycsXG4gICAgICAgICAgICAgICduZXZlcicsXG4gICAgICAgICAgICBdLFxuICAgICAgICAgIH0sXG4gICAgICAgICAgYWxwaGFiZXRpemU6IHtcbiAgICAgICAgICAgIHR5cGU6ICdvYmplY3QnLFxuICAgICAgICAgICAgcHJvcGVydGllczoge1xuICAgICAgICAgICAgICBjYXNlSW5zZW5zaXRpdmU6IHtcbiAgICAgICAgICAgICAgICB0eXBlOiAnYm9vbGVhbicsXG4gICAgICAgICAgICAgICAgZGVmYXVsdDogZmFsc2UsXG4gICAgICAgICAgICAgIH0sXG4gICAgICAgICAgICAgIG9yZGVyOiB7XG4gICAgICAgICAgICAgICAgZW51bTogWydpZ25vcmUnLCAnYXNjJywgJ2Rlc2MnXSxcbiAgICAgICAgICAgICAgICBkZWZhdWx0OiAnaWdub3JlJyxcbiAgICAgICAgICAgICAgfSxcbiAgICAgICAgICAgICAgb3JkZXJJbXBvcnRLaW5kOiB7XG4gICAgICAgICAgICAgICAgZW51bTogWydpZ25vcmUnLCAnYXNjJywgJ2Rlc2MnXSxcbiAgICAgICAgICAgICAgICBkZWZhdWx0OiAnaWdub3JlJyxcbiAgICAgICAgICAgICAgfSxcbiAgICAgICAgICAgIH0sXG4gICAgICAgICAgICBhZGRpdGlvbmFsUHJvcGVydGllczogZmFsc2UsXG4gICAgICAgICAgfSxcbiAgICAgICAgICB3YXJuT25VbmFzc2lnbmVkSW1wb3J0czoge1xuICAgICAgICAgICAgdHlwZTogJ2Jvb2xlYW4nLFxuICAgICAgICAgICAgZGVmYXVsdDogZmFsc2UsXG4gICAgICAgICAgfSxcbiAgICAgICAgfSxcbiAgICAgICAgYWRkaXRpb25hbFByb3BlcnRpZXM6IGZhbHNlLFxuICAgICAgfSxcbiAgICBdLFxuICB9LFxuXG4gIGNyZWF0ZTogZnVuY3Rpb24gaW1wb3J0T3JkZXJSdWxlKGNvbnRleHQpIHtcbiAgICBjb25zdCBvcHRpb25zID0gY29udGV4dC5vcHRpb25zWzBdIHx8IHt9O1xuICAgIGNvbnN0IG5ld2xpbmVzQmV0d2VlbkltcG9ydHMgPSBvcHRpb25zWyduZXdsaW5lcy1iZXR3ZWVuJ10gfHwgJ2lnbm9yZSc7XG4gICAgY29uc3QgcGF0aEdyb3Vwc0V4Y2x1ZGVkSW1wb3J0VHlwZXMgPSBuZXcgU2V0KG9wdGlvbnMucGF0aEdyb3Vwc0V4Y2x1ZGVkSW1wb3J0VHlwZXMgfHwgWydidWlsdGluJywgJ2V4dGVybmFsJywgJ29iamVjdCddKTtcbiAgICBjb25zdCBhbHBoYWJldGl6ZSA9IGdldEFscGhhYmV0aXplQ29uZmlnKG9wdGlvbnMpO1xuICAgIGNvbnN0IGRpc3RpbmN0R3JvdXAgPSBvcHRpb25zLmRpc3RpbmN0R3JvdXAgPT0gbnVsbCA/IGRlZmF1bHREaXN0aW5jdEdyb3VwIDogISFvcHRpb25zLmRpc3RpbmN0R3JvdXA7XG4gICAgbGV0IHJhbmtzO1xuXG4gICAgdHJ5IHtcbiAgICAgIGNvbnN0IHsgcGF0aEdyb3VwcywgbWF4UG9zaXRpb24gfSA9IGNvbnZlcnRQYXRoR3JvdXBzRm9yUmFua3Mob3B0aW9ucy5wYXRoR3JvdXBzIHx8IFtdKTtcbiAgICAgIGNvbnN0IHsgZ3JvdXBzLCBvbWl0dGVkVHlwZXMgfSA9IGNvbnZlcnRHcm91cHNUb1JhbmtzKG9wdGlvbnMuZ3JvdXBzIHx8IGRlZmF1bHRHcm91cHMpO1xuICAgICAgcmFua3MgPSB7XG4gICAgICAgIGdyb3VwcyxcbiAgICAgICAgb21pdHRlZFR5cGVzLFxuICAgICAgICBwYXRoR3JvdXBzLFxuICAgICAgICBtYXhQb3NpdGlvbixcbiAgICAgIH07XG4gICAgfSBjYXRjaCAoZXJyb3IpIHtcbiAgICAgIC8vIE1hbGZvcm1lZCBjb25maWd1cmF0aW9uXG4gICAgICByZXR1cm4ge1xuICAgICAgICBQcm9ncmFtKG5vZGUpIHtcbiAgICAgICAgICBjb250ZXh0LnJlcG9ydChub2RlLCBlcnJvci5tZXNzYWdlKTtcbiAgICAgICAgfSxcbiAgICAgIH07XG4gICAgfVxuICAgIGNvbnN0IGltcG9ydE1hcCA9IG5ldyBNYXAoKTtcblxuICAgIGZ1bmN0aW9uIGdldEJsb2NrSW1wb3J0cyhub2RlKSB7XG4gICAgICBpZiAoIWltcG9ydE1hcC5oYXMobm9kZSkpIHtcbiAgICAgICAgaW1wb3J0TWFwLnNldChub2RlLCBbXSk7XG4gICAgICB9XG4gICAgICByZXR1cm4gaW1wb3J0TWFwLmdldChub2RlKTtcbiAgICB9XG5cbiAgICByZXR1cm4ge1xuICAgICAgSW1wb3J0RGVjbGFyYXRpb246IGZ1bmN0aW9uIGhhbmRsZUltcG9ydHMobm9kZSkge1xuICAgICAgICAvLyBJZ25vcmluZyB1bmFzc2lnbmVkIGltcG9ydHMgdW5sZXNzIHdhcm5PblVuYXNzaWduZWRJbXBvcnRzIGlzIHNldFxuICAgICAgICBpZiAobm9kZS5zcGVjaWZpZXJzLmxlbmd0aCB8fCBvcHRpb25zLndhcm5PblVuYXNzaWduZWRJbXBvcnRzKSB7XG4gICAgICAgICAgY29uc3QgbmFtZSA9IG5vZGUuc291cmNlLnZhbHVlO1xuICAgICAgICAgIHJlZ2lzdGVyTm9kZShcbiAgICAgICAgICAgIGNvbnRleHQsXG4gICAgICAgICAgICB7XG4gICAgICAgICAgICAgIG5vZGUsXG4gICAgICAgICAgICAgIHZhbHVlOiBuYW1lLFxuICAgICAgICAgICAgICBkaXNwbGF5TmFtZTogbmFtZSxcbiAgICAgICAgICAgICAgdHlwZTogJ2ltcG9ydCcsXG4gICAgICAgICAgICB9LFxuICAgICAgICAgICAgcmFua3MsXG4gICAgICAgICAgICBnZXRCbG9ja0ltcG9ydHMobm9kZS5wYXJlbnQpLFxuICAgICAgICAgICAgcGF0aEdyb3Vwc0V4Y2x1ZGVkSW1wb3J0VHlwZXMsXG4gICAgICAgICAgKTtcbiAgICAgICAgfVxuICAgICAgfSxcbiAgICAgIFRTSW1wb3J0RXF1YWxzRGVjbGFyYXRpb246IGZ1bmN0aW9uIGhhbmRsZUltcG9ydHMobm9kZSkge1xuICAgICAgICBsZXQgZGlzcGxheU5hbWU7XG4gICAgICAgIGxldCB2YWx1ZTtcbiAgICAgICAgbGV0IHR5cGU7XG4gICAgICAgIC8vIHNraXAgXCJleHBvcnQgaW1wb3J0XCJzXG4gICAgICAgIGlmIChub2RlLmlzRXhwb3J0KSB7XG4gICAgICAgICAgcmV0dXJuO1xuICAgICAgICB9XG4gICAgICAgIGlmIChub2RlLm1vZHVsZVJlZmVyZW5jZS50eXBlID09PSAnVFNFeHRlcm5hbE1vZHVsZVJlZmVyZW5jZScpIHtcbiAgICAgICAgICB2YWx1ZSA9IG5vZGUubW9kdWxlUmVmZXJlbmNlLmV4cHJlc3Npb24udmFsdWU7XG4gICAgICAgICAgZGlzcGxheU5hbWUgPSB2YWx1ZTtcbiAgICAgICAgICB0eXBlID0gJ2ltcG9ydCc7XG4gICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgdmFsdWUgPSAnJztcbiAgICAgICAgICBkaXNwbGF5TmFtZSA9IGNvbnRleHQuZ2V0U291cmNlQ29kZSgpLmdldFRleHQobm9kZS5tb2R1bGVSZWZlcmVuY2UpO1xuICAgICAgICAgIHR5cGUgPSAnaW1wb3J0Om9iamVjdCc7XG4gICAgICAgIH1cbiAgICAgICAgcmVnaXN0ZXJOb2RlKFxuICAgICAgICAgIGNvbnRleHQsXG4gICAgICAgICAge1xuICAgICAgICAgICAgbm9kZSxcbiAgICAgICAgICAgIHZhbHVlLFxuICAgICAgICAgICAgZGlzcGxheU5hbWUsXG4gICAgICAgICAgICB0eXBlLFxuICAgICAgICAgIH0sXG4gICAgICAgICAgcmFua3MsXG4gICAgICAgICAgZ2V0QmxvY2tJbXBvcnRzKG5vZGUucGFyZW50KSxcbiAgICAgICAgICBwYXRoR3JvdXBzRXhjbHVkZWRJbXBvcnRUeXBlcyxcbiAgICAgICAgKTtcbiAgICAgIH0sXG4gICAgICBDYWxsRXhwcmVzc2lvbjogZnVuY3Rpb24gaGFuZGxlUmVxdWlyZXMobm9kZSkge1xuICAgICAgICBpZiAoIWlzU3RhdGljUmVxdWlyZShub2RlKSkge1xuICAgICAgICAgIHJldHVybjtcbiAgICAgICAgfVxuICAgICAgICBjb25zdCBibG9jayA9IGdldFJlcXVpcmVCbG9jayhub2RlKTtcbiAgICAgICAgaWYgKCFibG9jaykge1xuICAgICAgICAgIHJldHVybjtcbiAgICAgICAgfVxuICAgICAgICBjb25zdCBuYW1lID0gbm9kZS5hcmd1bWVudHNbMF0udmFsdWU7XG4gICAgICAgIHJlZ2lzdGVyTm9kZShcbiAgICAgICAgICBjb250ZXh0LFxuICAgICAgICAgIHtcbiAgICAgICAgICAgIG5vZGUsXG4gICAgICAgICAgICB2YWx1ZTogbmFtZSxcbiAgICAgICAgICAgIGRpc3BsYXlOYW1lOiBuYW1lLFxuICAgICAgICAgICAgdHlwZTogJ3JlcXVpcmUnLFxuICAgICAgICAgIH0sXG4gICAgICAgICAgcmFua3MsXG4gICAgICAgICAgZ2V0QmxvY2tJbXBvcnRzKGJsb2NrKSxcbiAgICAgICAgICBwYXRoR3JvdXBzRXhjbHVkZWRJbXBvcnRUeXBlcyxcbiAgICAgICAgKTtcbiAgICAgIH0sXG4gICAgICAnUHJvZ3JhbTpleGl0JzogZnVuY3Rpb24gcmVwb3J0QW5kUmVzZXQoKSB7XG4gICAgICAgIGltcG9ydE1hcC5mb3JFYWNoKChpbXBvcnRlZCkgPT4ge1xuICAgICAgICAgIGlmIChuZXdsaW5lc0JldHdlZW5JbXBvcnRzICE9PSAnaWdub3JlJykge1xuICAgICAgICAgICAgbWFrZU5ld2xpbmVzQmV0d2VlblJlcG9ydChjb250ZXh0LCBpbXBvcnRlZCwgbmV3bGluZXNCZXR3ZWVuSW1wb3J0cywgZGlzdGluY3RHcm91cCk7XG4gICAgICAgICAgfVxuXG4gICAgICAgICAgaWYgKGFscGhhYmV0aXplLm9yZGVyICE9PSAnaWdub3JlJykge1xuICAgICAgICAgICAgbXV0YXRlUmFua3NUb0FscGhhYmV0aXplKGltcG9ydGVkLCBhbHBoYWJldGl6ZSk7XG4gICAgICAgICAgfVxuXG4gICAgICAgICAgbWFrZU91dE9mT3JkZXJSZXBvcnQoY29udGV4dCwgaW1wb3J0ZWQpO1xuICAgICAgICB9KTtcblxuICAgICAgICBpbXBvcnRNYXAuY2xlYXIoKTtcbiAgICAgIH0sXG4gICAgfTtcbiAgfSxcbn07XG4iXX0=