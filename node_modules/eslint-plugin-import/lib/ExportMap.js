'use strict';Object.defineProperty(exports, "__esModule", { value: true });exports.



































































































































































































































































































































































































































































































































































































































































recursivePatternCapture = recursivePatternCapture;var _fs = require('fs');var _fs2 = _interopRequireDefault(_fs);var _doctrine = require('doctrine');var _doctrine2 = _interopRequireDefault(_doctrine);var _debug = require('debug');var _debug2 = _interopRequireDefault(_debug);var _eslint = require('eslint');var _parse = require('eslint-module-utils/parse');var _parse2 = _interopRequireDefault(_parse);var _resolve = require('eslint-module-utils/resolve');var _resolve2 = _interopRequireDefault(_resolve);var _ignore = require('eslint-module-utils/ignore');var _ignore2 = _interopRequireDefault(_ignore);var _hash = require('eslint-module-utils/hash');var _unambiguous = require('eslint-module-utils/unambiguous');var unambiguous = _interopRequireWildcard(_unambiguous);var _tsconfigLoader = require('tsconfig-paths/lib/tsconfig-loader');var _arrayIncludes = require('array-includes');var _arrayIncludes2 = _interopRequireDefault(_arrayIncludes);function _interopRequireWildcard(obj) {if (obj && obj.__esModule) {return obj;} else {var newObj = {};if (obj != null) {for (var key in obj) {if (Object.prototype.hasOwnProperty.call(obj, key)) newObj[key] = obj[key];}}newObj.default = obj;return newObj;}}function _interopRequireDefault(obj) {return obj && obj.__esModule ? obj : { default: obj };}let parseConfigFileTextToJson;const log = (0, _debug2.default)('eslint-plugin-import:ExportMap');const exportCache = new Map();class ExportMap {constructor(path) {this.path = path;this.namespace = new Map(); // todo: restructure to key on path, value is resolver + map of names
    this.reexports = new Map(); /**
                                 * star-exports
                                 * @type {Set} of () => ExportMap
                                 */this.dependencies = new Set(); /**
                                                                   * dependencies of this module that are not explicitly re-exported
                                                                   * @type {Map} from path = () => ExportMap
                                                                   */this.imports = new Map();this.errors = [];}get hasDefault() {return this.get('default') != null;} // stronger than this.has
  get size() {let size = this.namespace.size + this.reexports.size;this.dependencies.forEach(dep => {const d = dep(); // CJS / ignored dependencies won't exist (#717)
      if (d == null) return;size += d.size;});return size;} /**
                                                             * Note that this does not check explicitly re-exported names for existence
                                                             * in the base namespace, but it will expand all `export * from '...'` exports
                                                             * if not found in the explicit namespace.
                                                             * @param  {string}  name
                                                             * @return {Boolean} true if `name` is exported by this module.
                                                             */has(name) {if (this.namespace.has(name)) return true;if (this.reexports.has(name)) return true; // default exports must be explicitly re-exported (#328)
    if (name !== 'default') {for (let dep of this.dependencies) {let innerMap = dep(); // todo: report as unresolved?
        if (!innerMap) continue;if (innerMap.has(name)) return true;}}return false;} /**
                                                                                      * ensure that imported name fully resolves.
                                                                                      * @param  {[type]}  name [description]
                                                                                      * @return {Boolean}      [description]
                                                                                      */hasDeep(name) {if (this.namespace.has(name)) return { found: true, path: [this] };if (this.reexports.has(name)) {const reexports = this.reexports.get(name),imported = reexports.getImport(); // if import is ignored, return explicit 'null'
      if (imported == null) return { found: true, path: [this] // safeguard against cycles, only if name matches
      };if (imported.path === this.path && reexports.local === name) {return { found: false, path: [this] };}const deep = imported.hasDeep(reexports.local);deep.path.unshift(this);return deep;} // default exports must be explicitly re-exported (#328)
    if (name !== 'default') {for (let dep of this.dependencies) {let innerMap = dep();if (innerMap == null) return { found: true, path: [this] // todo: report as unresolved?
        };if (!innerMap) continue; // safeguard against cycles
        if (innerMap.path === this.path) continue;let innerValue = innerMap.hasDeep(name);if (innerValue.found) {innerValue.path.unshift(this);return innerValue;}}}return { found: false, path: [this] };}get(name) {if (this.namespace.has(name)) return this.namespace.get(name);if (this.reexports.has(name)) {const reexports = this.reexports.get(name),imported = reexports.getImport(); // if import is ignored, return explicit 'null'
      if (imported == null) return null; // safeguard against cycles, only if name matches
      if (imported.path === this.path && reexports.local === name) return undefined;return imported.get(reexports.local);} // default exports must be explicitly re-exported (#328)
    if (name !== 'default') {for (let dep of this.dependencies) {let innerMap = dep(); // todo: report as unresolved?
        if (!innerMap) continue; // safeguard against cycles
        if (innerMap.path === this.path) continue;let innerValue = innerMap.get(name);if (innerValue !== undefined) return innerValue;}}return undefined;}forEach(callback, thisArg) {this.namespace.forEach((v, n) => callback.call(thisArg, v, n, this));this.reexports.forEach((reexports, name) => {const reexported = reexports.getImport(); // can't look up meta for ignored re-exports (#348)
      callback.call(thisArg, reexported && reexported.get(reexports.local), name, this);});this.dependencies.forEach(dep => {const d = dep(); // CJS / ignored dependencies won't exist (#717)
      if (d == null) return;d.forEach((v, n) => n !== 'default' && callback.call(thisArg, v, n, this));});} // todo: keys, values, entries?
  reportErrors(context, declaration) {context.report({ node: declaration.source, message: `Parse errors in imported module '${declaration.source.value}': ` + `${this.errors.map(e => `${e.message} (${e.lineNumber}:${e.column})`).join(', ')}` });}}exports.default = ExportMap; /**
                                                                                                                                                                                                                                                                                    * parse docs from the first node that has leading comments
                                                                                                                                                                                                                                                                                    */function captureDoc(source, docStyleParsers) {const metadata = {}; // 'some' short-circuits on first 'true'
  for (var _len = arguments.length, nodes = Array(_len > 2 ? _len - 2 : 0), _key = 2; _key < _len; _key++) {nodes[_key - 2] = arguments[_key];}nodes.some(n => {try {let leadingComments; // n.leadingComments is legacy `attachComments` behavior
      if ('leadingComments' in n) {leadingComments = n.leadingComments;} else if (n.range) {leadingComments = source.getCommentsBefore(n);}if (!leadingComments || leadingComments.length === 0) return false;for (let name in docStyleParsers) {const doc = docStyleParsers[name](leadingComments);if (doc) {metadata.doc = doc;}}return true;} catch (err) {return false;}});return metadata;}const availableDocStyleParsers = { jsdoc: captureJsDoc, tomdoc: captureTomDoc /**
                                                                                                                                                                                                                                                                                                                                                                                                                                                                               * parse JSDoc from leading comments
                                                                                                                                                                                                                                                                                                                                                                                                                                                                               * @param  {...[type]} comments [description]
                                                                                                                                                                                                                                                                                                                                                                                                                                                                               * @return {{doc: object}}
                                                                                                                                                                                                                                                                                                                                                                                                                                                                               */ };function captureJsDoc(comments) {let doc; // capture XSDoc
  comments.forEach(comment => {// skip non-block comments
    if (comment.type !== 'Block') return;try {doc = _doctrine2.default.parse(comment.value, { unwrap: true });} catch (err) {/* don't care, for now? maybe add to `errors?` */}});return doc;} /**
                                                                                                                                                                                                 * parse TomDoc section from comments
                                                                                                                                                                                                 */function captureTomDoc(comments) {// collect lines up to first paragraph break
  const lines = [];for (let i = 0; i < comments.length; i++) {const comment = comments[i];if (comment.value.match(/^\s*$/)) break;lines.push(comment.value.trim());} // return doctrine-like object
  const statusMatch = lines.join(' ').match(/^(Public|Internal|Deprecated):\s*(.+)/);if (statusMatch) {return { description: statusMatch[2], tags: [{ title: statusMatch[1].toLowerCase(), description: statusMatch[2] }] };}}ExportMap.get = function (source, context) {const path = (0, _resolve2.default)(source, context);if (path == null) return null;return ExportMap.for(childContext(path, context));};ExportMap.for = function (context) {const path = context.path;const cacheKey = (0, _hash.hashObject)(context).digest('hex');let exportMap = exportCache.get(cacheKey); // return cached ignore
  if (exportMap === null) return null;const stats = _fs2.default.statSync(path);if (exportMap != null) {// date equality check
    if (exportMap.mtime - stats.mtime === 0) {return exportMap;} // future: check content equality?
  } // check valid extensions first
  if (!(0, _ignore.hasValidExtension)(path, context)) {exportCache.set(cacheKey, null);return null;} // check for and cache ignore
  if ((0, _ignore2.default)(path, context)) {log('ignored path due to ignore settings:', path);exportCache.set(cacheKey, null);return null;}const content = _fs2.default.readFileSync(path, { encoding: 'utf8' }); // check for and cache unambiguous modules
  if (!unambiguous.test(content)) {log('ignored path due to unambiguous regex:', path);exportCache.set(cacheKey, null);return null;}log('cache miss', cacheKey, 'for path', path);exportMap = ExportMap.parse(path, content, context); // ambiguous modules return null
  if (exportMap == null) return null;exportMap.mtime = stats.mtime;exportCache.set(cacheKey, exportMap);return exportMap;};ExportMap.parse = function (path, content, context) {var m = new ExportMap(path);try {var ast = (0, _parse2.default)(path, content, context);} catch (err) {log('parse error:', path, err);m.errors.push(err);return m; // can't continue
  }if (!unambiguous.isModule(ast)) return null;const docstyle = context.settings && context.settings['import/docstyle'] || ['jsdoc'];const docStyleParsers = {};docstyle.forEach(style => {docStyleParsers[style] = availableDocStyleParsers[style];}); // attempt to collect module doc
  if (ast.comments) {ast.comments.some(c => {if (c.type !== 'Block') return false;try {const doc = _doctrine2.default.parse(c.value, { unwrap: true });if (doc.tags.some(t => t.title === 'module')) {m.doc = doc;return true;}} catch (err) {/* ignore */}return false;});}const namespaces = new Map();function remotePath(value) {return _resolve2.default.relative(value, path, context.settings);}function resolveImport(value) {const rp = remotePath(value);if (rp == null) return null;return ExportMap.for(childContext(rp, context));}function getNamespace(identifier) {if (!namespaces.has(identifier.name)) return;return function () {return resolveImport(namespaces.get(identifier.name));};}function addNamespace(object, identifier) {const nsfn = getNamespace(identifier);if (nsfn) {Object.defineProperty(object, 'namespace', { get: nsfn });}return object;}function captureDependency(declaration) {if (declaration.source == null) return null;if (declaration.importKind === 'type') return null; // skip Flow type imports
    const importedSpecifiers = new Set();const supportedTypes = new Set(['ImportDefaultSpecifier', 'ImportNamespaceSpecifier']);let hasImportedType = false;if (declaration.specifiers) {declaration.specifiers.forEach(specifier => {const isType = specifier.importKind === 'type';hasImportedType = hasImportedType || isType;if (supportedTypes.has(specifier.type) && !isType) {importedSpecifiers.add(specifier.type);}if (specifier.type === 'ImportSpecifier' && !isType) {importedSpecifiers.add(specifier.imported.name);}});} // only Flow types were imported
    if (hasImportedType && importedSpecifiers.size === 0) return null;const p = remotePath(declaration.source.value);if (p == null) return null;const existing = m.imports.get(p);if (existing != null) return existing.getter;const getter = thunkFor(p, context);m.imports.set(p, { getter, source: { // capturing actual node reference holds full AST in memory!
        value: declaration.source.value, loc: declaration.source.loc }, importedSpecifiers });return getter;}const source = makeSourceCode(content, ast);function isEsModuleInterop() {const tsConfigInfo = (0, _tsconfigLoader.tsConfigLoader)({ cwd: context.parserOptions && context.parserOptions.tsconfigRootDir || process.cwd(), getEnv: key => process.env[key] });try {if (tsConfigInfo.tsConfigPath !== undefined) {const jsonText = _fs2.default.readFileSync(tsConfigInfo.tsConfigPath).toString();if (!parseConfigFileTextToJson) {var _require = require('typescript'); // this is because projects not using TypeScript won't have typescript installed
          parseConfigFileTextToJson = _require.parseConfigFileTextToJson;}const tsConfig = parseConfigFileTextToJson(tsConfigInfo.tsConfigPath, jsonText).config;return tsConfig.compilerOptions.esModuleInterop;}} catch (e) {return false;}}ast.body.forEach(function (n) {if (n.type === 'ExportDefaultDeclaration') {const exportMeta = captureDoc(source, docStyleParsers, n);if (n.declaration.type === 'Identifier') {addNamespace(exportMeta, n.declaration);}m.namespace.set('default', exportMeta);return;}if (n.type === 'ExportAllDeclaration') {const getter = captureDependency(n);if (getter) m.dependencies.add(getter);return;} // capture namespaces in case of later export
    if (n.type === 'ImportDeclaration') {captureDependency(n);let ns;if (n.specifiers.some(s => s.type === 'ImportNamespaceSpecifier' && (ns = s))) {namespaces.set(ns.local.name, n.source.value);}return;}if (n.type === 'ExportNamedDeclaration') {// capture declaration
      if (n.declaration != null) {switch (n.declaration.type) {case 'FunctionDeclaration':case 'ClassDeclaration':case 'TypeAlias': // flowtype with babel-eslint parser
          case 'InterfaceDeclaration':case 'DeclareFunction':case 'TSDeclareFunction':case 'TSEnumDeclaration':case 'TSTypeAliasDeclaration':case 'TSInterfaceDeclaration':case 'TSAbstractClassDeclaration':case 'TSModuleDeclaration':m.namespace.set(n.declaration.id.name, captureDoc(source, docStyleParsers, n));break;case 'VariableDeclaration':n.declaration.declarations.forEach(d => recursivePatternCapture(d.id, id => m.namespace.set(id.name, captureDoc(source, docStyleParsers, d, n))));break;}}const nsource = n.source && n.source.value;n.specifiers.forEach(s => {const exportMeta = {};let local;switch (s.type) {case 'ExportDefaultSpecifier':if (!n.source) return;local = 'default';break;case 'ExportNamespaceSpecifier':m.namespace.set(s.exported.name, Object.defineProperty(exportMeta, 'namespace', { get() {return resolveImport(nsource);} }));return;case 'ExportSpecifier':if (!n.source) {m.namespace.set(s.exported.name, addNamespace(exportMeta, s.local));return;} // else falls through
          default:local = s.local.name;break;} // todo: JSDoc
        m.reexports.set(s.exported.name, { local, getImport: () => resolveImport(nsource) });});}const isEsModuleInteropTrue = isEsModuleInterop();const exports = ['TSExportAssignment'];if (isEsModuleInteropTrue) {exports.push('TSNamespaceExportDeclaration');} // This doesn't declare anything, but changes what's being exported.
    if ((0, _arrayIncludes2.default)(exports, n.type)) {const exportedName = n.type === 'TSNamespaceExportDeclaration' ? n.id.name : n.expression && n.expression.name || n.expression.id && n.expression.id.name || null;const declTypes = ['VariableDeclaration', 'ClassDeclaration', 'TSDeclareFunction', 'TSEnumDeclaration', 'TSTypeAliasDeclaration', 'TSInterfaceDeclaration', 'TSAbstractClassDeclaration', 'TSModuleDeclaration'];const exportedDecls = ast.body.filter((_ref) => {let type = _ref.type,id = _ref.id,declarations = _ref.declarations;return (0, _arrayIncludes2.default)(declTypes, type) && (id && id.name === exportedName || declarations && declarations.find(d => d.id.name === exportedName));});if (exportedDecls.length === 0) {// Export is not referencing any local declaration, must be re-exporting
        m.namespace.set('default', captureDoc(source, docStyleParsers, n));return;}if (isEsModuleInteropTrue) {m.namespace.set('default', {});}exportedDecls.forEach(decl => {if (decl.type === 'TSModuleDeclaration') {if (decl.body && decl.body.type === 'TSModuleDeclaration') {m.namespace.set(decl.body.id.name, captureDoc(source, docStyleParsers, decl.body));} else if (decl.body && decl.body.body) {decl.body.body.forEach(moduleBlockNode => {// Export-assignment exports all members in the namespace,
              // explicitly exported or not.
              const namespaceDecl = moduleBlockNode.type === 'ExportNamedDeclaration' ? moduleBlockNode.declaration : moduleBlockNode;if (!namespaceDecl) {// TypeScript can check this for us; we needn't
              } else if (namespaceDecl.type === 'VariableDeclaration') {namespaceDecl.declarations.forEach(d => recursivePatternCapture(d.id, id => m.namespace.set(id.name, captureDoc(source, docStyleParsers, decl, namespaceDecl, moduleBlockNode))));} else {m.namespace.set(namespaceDecl.id.name, captureDoc(source, docStyleParsers, moduleBlockNode));}});}} else {// Export as default
          m.namespace.set('default', captureDoc(source, docStyleParsers, decl));}});}});return m;}; /**
                                                                                                     * The creation of this closure is isolated from other scopes
                                                                                                     * to avoid over-retention of unrelated variables, which has
                                                                                                     * caused memory leaks. See #1266.
                                                                                                     */function thunkFor(p, context) {return () => ExportMap.for(childContext(p, context));} /**
                                                                                                                                                                                              * Traverse a pattern/identifier node, calling 'callback'
                                                                                                                                                                                              * for each leaf identifier.
                                                                                                                                                                                              * @param  {node}   pattern
                                                                                                                                                                                              * @param  {Function} callback
                                                                                                                                                                                              * @return {void}
                                                                                                                                                                                              */function recursivePatternCapture(pattern, callback) {switch (pattern.type) {case 'Identifier': // base case
      callback(pattern);break;case 'ObjectPattern':pattern.properties.forEach(p => {if (p.type === 'ExperimentalRestProperty' || p.type === 'RestElement') {callback(p.argument);return;}recursivePatternCapture(p.value, callback);});break;case 'ArrayPattern':pattern.elements.forEach(element => {if (element == null) return;if (element.type === 'ExperimentalRestProperty' || element.type === 'RestElement') {callback(element.argument);return;}recursivePatternCapture(element, callback);});break;case 'AssignmentPattern':callback(pattern.left);break;}} /**
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       * don't hold full context object in memory, just grab what we need.
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       */function childContext(path, context) {const settings = context.settings,parserOptions = context.parserOptions,parserPath = context.parserPath;return { settings, parserOptions, parserPath, path };} /**
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               * sometimes legacy support isn't _that_ hard... right?
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               */function makeSourceCode(text, ast) {if (_eslint.SourceCode.length > 1) {// ESLint 3
    return new _eslint.SourceCode(text, ast);} else {// ESLint 4, 5
    return new _eslint.SourceCode({ text, ast });}}
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIi4uL3NyYy9FeHBvcnRNYXAuanMiXSwibmFtZXMiOlsicmVjdXJzaXZlUGF0dGVybkNhcHR1cmUiLCJ1bmFtYmlndW91cyIsInBhcnNlQ29uZmlnRmlsZVRleHRUb0pzb24iLCJsb2ciLCJleHBvcnRDYWNoZSIsIk1hcCIsIkV4cG9ydE1hcCIsImNvbnN0cnVjdG9yIiwicGF0aCIsIm5hbWVzcGFjZSIsInJlZXhwb3J0cyIsImRlcGVuZGVuY2llcyIsIlNldCIsImltcG9ydHMiLCJlcnJvcnMiLCJoYXNEZWZhdWx0IiwiZ2V0Iiwic2l6ZSIsImZvckVhY2giLCJkZXAiLCJkIiwiaGFzIiwibmFtZSIsImlubmVyTWFwIiwiaGFzRGVlcCIsImZvdW5kIiwiaW1wb3J0ZWQiLCJnZXRJbXBvcnQiLCJsb2NhbCIsImRlZXAiLCJ1bnNoaWZ0IiwiaW5uZXJWYWx1ZSIsInVuZGVmaW5lZCIsImNhbGxiYWNrIiwidGhpc0FyZyIsInYiLCJuIiwiY2FsbCIsInJlZXhwb3J0ZWQiLCJyZXBvcnRFcnJvcnMiLCJjb250ZXh0IiwiZGVjbGFyYXRpb24iLCJyZXBvcnQiLCJub2RlIiwic291cmNlIiwibWVzc2FnZSIsInZhbHVlIiwibWFwIiwiZSIsImxpbmVOdW1iZXIiLCJjb2x1bW4iLCJqb2luIiwiY2FwdHVyZURvYyIsImRvY1N0eWxlUGFyc2VycyIsIm1ldGFkYXRhIiwibm9kZXMiLCJzb21lIiwibGVhZGluZ0NvbW1lbnRzIiwicmFuZ2UiLCJnZXRDb21tZW50c0JlZm9yZSIsImxlbmd0aCIsImRvYyIsImVyciIsImF2YWlsYWJsZURvY1N0eWxlUGFyc2VycyIsImpzZG9jIiwiY2FwdHVyZUpzRG9jIiwidG9tZG9jIiwiY2FwdHVyZVRvbURvYyIsImNvbW1lbnRzIiwiY29tbWVudCIsInR5cGUiLCJkb2N0cmluZSIsInBhcnNlIiwidW53cmFwIiwibGluZXMiLCJpIiwibWF0Y2giLCJwdXNoIiwidHJpbSIsInN0YXR1c01hdGNoIiwiZGVzY3JpcHRpb24iLCJ0YWdzIiwidGl0bGUiLCJ0b0xvd2VyQ2FzZSIsImZvciIsImNoaWxkQ29udGV4dCIsImNhY2hlS2V5IiwiZGlnZXN0IiwiZXhwb3J0TWFwIiwic3RhdHMiLCJmcyIsInN0YXRTeW5jIiwibXRpbWUiLCJzZXQiLCJjb250ZW50IiwicmVhZEZpbGVTeW5jIiwiZW5jb2RpbmciLCJ0ZXN0IiwibSIsImFzdCIsImlzTW9kdWxlIiwiZG9jc3R5bGUiLCJzZXR0aW5ncyIsInN0eWxlIiwiYyIsInQiLCJuYW1lc3BhY2VzIiwicmVtb3RlUGF0aCIsInJlc29sdmUiLCJyZWxhdGl2ZSIsInJlc29sdmVJbXBvcnQiLCJycCIsImdldE5hbWVzcGFjZSIsImlkZW50aWZpZXIiLCJhZGROYW1lc3BhY2UiLCJvYmplY3QiLCJuc2ZuIiwiT2JqZWN0IiwiZGVmaW5lUHJvcGVydHkiLCJjYXB0dXJlRGVwZW5kZW5jeSIsImltcG9ydEtpbmQiLCJpbXBvcnRlZFNwZWNpZmllcnMiLCJzdXBwb3J0ZWRUeXBlcyIsImhhc0ltcG9ydGVkVHlwZSIsInNwZWNpZmllcnMiLCJzcGVjaWZpZXIiLCJpc1R5cGUiLCJhZGQiLCJwIiwiZXhpc3RpbmciLCJnZXR0ZXIiLCJ0aHVua0ZvciIsImxvYyIsIm1ha2VTb3VyY2VDb2RlIiwiaXNFc01vZHVsZUludGVyb3AiLCJ0c0NvbmZpZ0luZm8iLCJjd2QiLCJwYXJzZXJPcHRpb25zIiwidHNjb25maWdSb290RGlyIiwicHJvY2VzcyIsImdldEVudiIsImtleSIsImVudiIsInRzQ29uZmlnUGF0aCIsImpzb25UZXh0IiwidG9TdHJpbmciLCJyZXF1aXJlIiwidHNDb25maWciLCJjb25maWciLCJjb21waWxlck9wdGlvbnMiLCJlc01vZHVsZUludGVyb3AiLCJib2R5IiwiZXhwb3J0TWV0YSIsIm5zIiwicyIsImlkIiwiZGVjbGFyYXRpb25zIiwibnNvdXJjZSIsImV4cG9ydGVkIiwiaXNFc01vZHVsZUludGVyb3BUcnVlIiwiZXhwb3J0cyIsImV4cG9ydGVkTmFtZSIsImV4cHJlc3Npb24iLCJkZWNsVHlwZXMiLCJleHBvcnRlZERlY2xzIiwiZmlsdGVyIiwiZmluZCIsImRlY2wiLCJtb2R1bGVCbG9ja05vZGUiLCJuYW1lc3BhY2VEZWNsIiwicGF0dGVybiIsInByb3BlcnRpZXMiLCJhcmd1bWVudCIsImVsZW1lbnRzIiwiZWxlbWVudCIsImxlZnQiLCJwYXJzZXJQYXRoIiwidGV4dCIsIlNvdXJjZUNvZGUiXSwibWFwcGluZ3MiOiI7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7O0FBb29CZ0JBLHVCLEdBQUFBLHVCLENBcG9CaEIsd0IsdUNBRUEsb0MsbURBRUEsOEIsNkNBRUEsZ0NBRUEsa0Qs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LGFBRGlCLENBQ0Z1QyxVQURFLEdBQ2F4SSxPQURiLENBQ0Z3SSxVQURFLENBRW5DLE9BQU8sRUFDTDFFLFFBREssRUFFTG1DLGFBRkssRUFHTHVDLFVBSEssRUFJTHhLLElBSkssRUFBUCxDQU1ELEMsQ0FHRDs7aXZCQUdBLFNBQVM2SCxjQUFULENBQXdCNEMsSUFBeEIsRUFBOEI5RSxHQUE5QixFQUFtQyxDQUNqQyxJQUFJK0UsbUJBQVd0SCxNQUFYLEdBQW9CLENBQXhCLEVBQTJCLENBQ3pCO0FBQ0EsV0FBTyxJQUFJc0gsa0JBQUosQ0FBZUQsSUFBZixFQUFxQjlFLEdBQXJCLENBQVAsQ0FDRCxDQUhELE1BR08sQ0FDTDtBQUNBLFdBQU8sSUFBSStFLGtCQUFKLENBQWUsRUFBRUQsSUFBRixFQUFROUUsR0FBUixFQUFmLENBQVAsQ0FDRCxDQUNGIiwiZmlsZSI6IkV4cG9ydE1hcC5qcyIsInNvdXJjZXNDb250ZW50IjpbImltcG9ydCBmcyBmcm9tICdmcydcblxuaW1wb3J0IGRvY3RyaW5lIGZyb20gJ2RvY3RyaW5lJ1xuXG5pbXBvcnQgZGVidWcgZnJvbSAnZGVidWcnXG5cbmltcG9ydCB7IFNvdXJjZUNvZGUgfSBmcm9tICdlc2xpbnQnXG5cbmltcG9ydCBwYXJzZSBmcm9tICdlc2xpbnQtbW9kdWxlLXV0aWxzL3BhcnNlJ1xuaW1wb3J0IHJlc29sdmUgZnJvbSAnZXNsaW50LW1vZHVsZS11dGlscy9yZXNvbHZlJ1xuaW1wb3J0IGlzSWdub3JlZCwgeyBoYXNWYWxpZEV4dGVuc2lvbiB9IGZyb20gJ2VzbGludC1tb2R1bGUtdXRpbHMvaWdub3JlJ1xuXG5pbXBvcnQgeyBoYXNoT2JqZWN0IH0gZnJvbSAnZXNsaW50LW1vZHVsZS11dGlscy9oYXNoJ1xuaW1wb3J0ICogYXMgdW5hbWJpZ3VvdXMgZnJvbSAnZXNsaW50LW1vZHVsZS11dGlscy91bmFtYmlndW91cydcblxuaW1wb3J0IHsgdHNDb25maWdMb2FkZXIgfSBmcm9tICd0c2NvbmZpZy1wYXRocy9saWIvdHNjb25maWctbG9hZGVyJ1xuXG5pbXBvcnQgaW5jbHVkZXMgZnJvbSAnYXJyYXktaW5jbHVkZXMnXG5cbmxldCBwYXJzZUNvbmZpZ0ZpbGVUZXh0VG9Kc29uXG5cbmNvbnN0IGxvZyA9IGRlYnVnKCdlc2xpbnQtcGx1Z2luLWltcG9ydDpFeHBvcnRNYXAnKVxuXG5jb25zdCBleHBvcnRDYWNoZSA9IG5ldyBNYXAoKVxuXG5leHBvcnQgZGVmYXVsdCBjbGFzcyBFeHBvcnRNYXAge1xuICBjb25zdHJ1Y3RvcihwYXRoKSB7XG4gICAgdGhpcy5wYXRoID0gcGF0aFxuICAgIHRoaXMubmFtZXNwYWNlID0gbmV3IE1hcCgpXG4gICAgLy8gdG9kbzogcmVzdHJ1Y3R1cmUgdG8ga2V5IG9uIHBhdGgsIHZhbHVlIGlzIHJlc29sdmVyICsgbWFwIG9mIG5hbWVzXG4gICAgdGhpcy5yZWV4cG9ydHMgPSBuZXcgTWFwKClcbiAgICAvKipcbiAgICAgKiBzdGFyLWV4cG9ydHNcbiAgICAgKiBAdHlwZSB7U2V0fSBvZiAoKSA9PiBFeHBvcnRNYXBcbiAgICAgKi9cbiAgICB0aGlzLmRlcGVuZGVuY2llcyA9IG5ldyBTZXQoKVxuICAgIC8qKlxuICAgICAqIGRlcGVuZGVuY2llcyBvZiB0aGlzIG1vZHVsZSB0aGF0IGFyZSBub3QgZXhwbGljaXRseSByZS1leHBvcnRlZFxuICAgICAqIEB0eXBlIHtNYXB9IGZyb20gcGF0aCA9ICgpID0+IEV4cG9ydE1hcFxuICAgICAqL1xuICAgIHRoaXMuaW1wb3J0cyA9IG5ldyBNYXAoKVxuICAgIHRoaXMuZXJyb3JzID0gW11cbiAgfVxuXG4gIGdldCBoYXNEZWZhdWx0KCkgeyByZXR1cm4gdGhpcy5nZXQoJ2RlZmF1bHQnKSAhPSBudWxsIH0gLy8gc3Ryb25nZXIgdGhhbiB0aGlzLmhhc1xuXG4gIGdldCBzaXplKCkge1xuICAgIGxldCBzaXplID0gdGhpcy5uYW1lc3BhY2Uuc2l6ZSArIHRoaXMucmVleHBvcnRzLnNpemVcbiAgICB0aGlzLmRlcGVuZGVuY2llcy5mb3JFYWNoKGRlcCA9PiB7XG4gICAgICBjb25zdCBkID0gZGVwKClcbiAgICAgIC8vIENKUyAvIGlnbm9yZWQgZGVwZW5kZW5jaWVzIHdvbid0IGV4aXN0ICgjNzE3KVxuICAgICAgaWYgKGQgPT0gbnVsbCkgcmV0dXJuXG4gICAgICBzaXplICs9IGQuc2l6ZVxuICAgIH0pXG4gICAgcmV0dXJuIHNpemVcbiAgfVxuXG4gIC8qKlxuICAgKiBOb3RlIHRoYXQgdGhpcyBkb2VzIG5vdCBjaGVjayBleHBsaWNpdGx5IHJlLWV4cG9ydGVkIG5hbWVzIGZvciBleGlzdGVuY2VcbiAgICogaW4gdGhlIGJhc2UgbmFtZXNwYWNlLCBidXQgaXQgd2lsbCBleHBhbmQgYWxsIGBleHBvcnQgKiBmcm9tICcuLi4nYCBleHBvcnRzXG4gICAqIGlmIG5vdCBmb3VuZCBpbiB0aGUgZXhwbGljaXQgbmFtZXNwYWNlLlxuICAgKiBAcGFyYW0gIHtzdHJpbmd9ICBuYW1lXG4gICAqIEByZXR1cm4ge0Jvb2xlYW59IHRydWUgaWYgYG5hbWVgIGlzIGV4cG9ydGVkIGJ5IHRoaXMgbW9kdWxlLlxuICAgKi9cbiAgaGFzKG5hbWUpIHtcbiAgICBpZiAodGhpcy5uYW1lc3BhY2UuaGFzKG5hbWUpKSByZXR1cm4gdHJ1ZVxuICAgIGlmICh0aGlzLnJlZXhwb3J0cy5oYXMobmFtZSkpIHJldHVybiB0cnVlXG5cbiAgICAvLyBkZWZhdWx0IGV4cG9ydHMgbXVzdCBiZSBleHBsaWNpdGx5IHJlLWV4cG9ydGVkICgjMzI4KVxuICAgIGlmIChuYW1lICE9PSAnZGVmYXVsdCcpIHtcbiAgICAgIGZvciAobGV0IGRlcCBvZiB0aGlzLmRlcGVuZGVuY2llcykge1xuICAgICAgICBsZXQgaW5uZXJNYXAgPSBkZXAoKVxuXG4gICAgICAgIC8vIHRvZG86IHJlcG9ydCBhcyB1bnJlc29sdmVkP1xuICAgICAgICBpZiAoIWlubmVyTWFwKSBjb250aW51ZVxuXG4gICAgICAgIGlmIChpbm5lck1hcC5oYXMobmFtZSkpIHJldHVybiB0cnVlXG4gICAgICB9XG4gICAgfVxuXG4gICAgcmV0dXJuIGZhbHNlXG4gIH1cblxuICAvKipcbiAgICogZW5zdXJlIHRoYXQgaW1wb3J0ZWQgbmFtZSBmdWxseSByZXNvbHZlcy5cbiAgICogQHBhcmFtICB7W3R5cGVdfSAgbmFtZSBbZGVzY3JpcHRpb25dXG4gICAqIEByZXR1cm4ge0Jvb2xlYW59ICAgICAgW2Rlc2NyaXB0aW9uXVxuICAgKi9cbiAgaGFzRGVlcChuYW1lKSB7XG4gICAgaWYgKHRoaXMubmFtZXNwYWNlLmhhcyhuYW1lKSkgcmV0dXJuIHsgZm91bmQ6IHRydWUsIHBhdGg6IFt0aGlzXSB9XG5cbiAgICBpZiAodGhpcy5yZWV4cG9ydHMuaGFzKG5hbWUpKSB7XG4gICAgICBjb25zdCByZWV4cG9ydHMgPSB0aGlzLnJlZXhwb3J0cy5nZXQobmFtZSlcbiAgICAgICAgICAsIGltcG9ydGVkID0gcmVleHBvcnRzLmdldEltcG9ydCgpXG5cbiAgICAgIC8vIGlmIGltcG9ydCBpcyBpZ25vcmVkLCByZXR1cm4gZXhwbGljaXQgJ251bGwnXG4gICAgICBpZiAoaW1wb3J0ZWQgPT0gbnVsbCkgcmV0dXJuIHsgZm91bmQ6IHRydWUsIHBhdGg6IFt0aGlzXSB9XG5cbiAgICAgIC8vIHNhZmVndWFyZCBhZ2FpbnN0IGN5Y2xlcywgb25seSBpZiBuYW1lIG1hdGNoZXNcbiAgICAgIGlmIChpbXBvcnRlZC5wYXRoID09PSB0aGlzLnBhdGggJiYgcmVleHBvcnRzLmxvY2FsID09PSBuYW1lKSB7XG4gICAgICAgIHJldHVybiB7IGZvdW5kOiBmYWxzZSwgcGF0aDogW3RoaXNdIH1cbiAgICAgIH1cblxuICAgICAgY29uc3QgZGVlcCA9IGltcG9ydGVkLmhhc0RlZXAocmVleHBvcnRzLmxvY2FsKVxuICAgICAgZGVlcC5wYXRoLnVuc2hpZnQodGhpcylcblxuICAgICAgcmV0dXJuIGRlZXBcbiAgICB9XG5cblxuICAgIC8vIGRlZmF1bHQgZXhwb3J0cyBtdXN0IGJlIGV4cGxpY2l0bHkgcmUtZXhwb3J0ZWQgKCMzMjgpXG4gICAgaWYgKG5hbWUgIT09ICdkZWZhdWx0Jykge1xuICAgICAgZm9yIChsZXQgZGVwIG9mIHRoaXMuZGVwZW5kZW5jaWVzKSB7XG4gICAgICAgIGxldCBpbm5lck1hcCA9IGRlcCgpXG4gICAgICAgIGlmIChpbm5lck1hcCA9PSBudWxsKSByZXR1cm4geyBmb3VuZDogdHJ1ZSwgcGF0aDogW3RoaXNdIH1cbiAgICAgICAgLy8gdG9kbzogcmVwb3J0IGFzIHVucmVzb2x2ZWQ/XG4gICAgICAgIGlmICghaW5uZXJNYXApIGNvbnRpbnVlXG5cbiAgICAgICAgLy8gc2FmZWd1YXJkIGFnYWluc3QgY3ljbGVzXG4gICAgICAgIGlmIChpbm5lck1hcC5wYXRoID09PSB0aGlzLnBhdGgpIGNvbnRpbnVlXG5cbiAgICAgICAgbGV0IGlubmVyVmFsdWUgPSBpbm5lck1hcC5oYXNEZWVwKG5hbWUpXG4gICAgICAgIGlmIChpbm5lclZhbHVlLmZvdW5kKSB7XG4gICAgICAgICAgaW5uZXJWYWx1ZS5wYXRoLnVuc2hpZnQodGhpcylcbiAgICAgICAgICByZXR1cm4gaW5uZXJWYWx1ZVxuICAgICAgICB9XG4gICAgICB9XG4gICAgfVxuXG4gICAgcmV0dXJuIHsgZm91bmQ6IGZhbHNlLCBwYXRoOiBbdGhpc10gfVxuICB9XG5cbiAgZ2V0KG5hbWUpIHtcbiAgICBpZiAodGhpcy5uYW1lc3BhY2UuaGFzKG5hbWUpKSByZXR1cm4gdGhpcy5uYW1lc3BhY2UuZ2V0KG5hbWUpXG5cbiAgICBpZiAodGhpcy5yZWV4cG9ydHMuaGFzKG5hbWUpKSB7XG4gICAgICBjb25zdCByZWV4cG9ydHMgPSB0aGlzLnJlZXhwb3J0cy5nZXQobmFtZSlcbiAgICAgICAgICAsIGltcG9ydGVkID0gcmVleHBvcnRzLmdldEltcG9ydCgpXG5cbiAgICAgIC8vIGlmIGltcG9ydCBpcyBpZ25vcmVkLCByZXR1cm4gZXhwbGljaXQgJ251bGwnXG4gICAgICBpZiAoaW1wb3J0ZWQgPT0gbnVsbCkgcmV0dXJuIG51bGxcblxuICAgICAgLy8gc2FmZWd1YXJkIGFnYWluc3QgY3ljbGVzLCBvbmx5IGlmIG5hbWUgbWF0Y2hlc1xuICAgICAgaWYgKGltcG9ydGVkLnBhdGggPT09IHRoaXMucGF0aCAmJiByZWV4cG9ydHMubG9jYWwgPT09IG5hbWUpIHJldHVybiB1bmRlZmluZWRcblxuICAgICAgcmV0dXJuIGltcG9ydGVkLmdldChyZWV4cG9ydHMubG9jYWwpXG4gICAgfVxuXG4gICAgLy8gZGVmYXVsdCBleHBvcnRzIG11c3QgYmUgZXhwbGljaXRseSByZS1leHBvcnRlZCAoIzMyOClcbiAgICBpZiAobmFtZSAhPT0gJ2RlZmF1bHQnKSB7XG4gICAgICBmb3IgKGxldCBkZXAgb2YgdGhpcy5kZXBlbmRlbmNpZXMpIHtcbiAgICAgICAgbGV0IGlubmVyTWFwID0gZGVwKClcbiAgICAgICAgLy8gdG9kbzogcmVwb3J0IGFzIHVucmVzb2x2ZWQ/XG4gICAgICAgIGlmICghaW5uZXJNYXApIGNvbnRpbnVlXG5cbiAgICAgICAgLy8gc2FmZWd1YXJkIGFnYWluc3QgY3ljbGVzXG4gICAgICAgIGlmIChpbm5lck1hcC5wYXRoID09PSB0aGlzLnBhdGgpIGNvbnRpbnVlXG5cbiAgICAgICAgbGV0IGlubmVyVmFsdWUgPSBpbm5lck1hcC5nZXQobmFtZSlcbiAgICAgICAgaWYgKGlubmVyVmFsdWUgIT09IHVuZGVmaW5lZCkgcmV0dXJuIGlubmVyVmFsdWVcbiAgICAgIH1cbiAgICB9XG5cbiAgICByZXR1cm4gdW5kZWZpbmVkXG4gIH1cblxuICBmb3JFYWNoKGNhbGxiYWNrLCB0aGlzQXJnKSB7XG4gICAgdGhpcy5uYW1lc3BhY2UuZm9yRWFjaCgodiwgbikgPT5cbiAgICAgIGNhbGxiYWNrLmNhbGwodGhpc0FyZywgdiwgbiwgdGhpcykpXG5cbiAgICB0aGlzLnJlZXhwb3J0cy5mb3JFYWNoKChyZWV4cG9ydHMsIG5hbWUpID0+IHtcbiAgICAgIGNvbnN0IHJlZXhwb3J0ZWQgPSByZWV4cG9ydHMuZ2V0SW1wb3J0KClcbiAgICAgIC8vIGNhbid0IGxvb2sgdXAgbWV0YSBmb3IgaWdub3JlZCByZS1leHBvcnRzICgjMzQ4KVxuICAgICAgY2FsbGJhY2suY2FsbCh0aGlzQXJnLCByZWV4cG9ydGVkICYmIHJlZXhwb3J0ZWQuZ2V0KHJlZXhwb3J0cy5sb2NhbCksIG5hbWUsIHRoaXMpXG4gICAgfSlcblxuICAgIHRoaXMuZGVwZW5kZW5jaWVzLmZvckVhY2goZGVwID0+IHtcbiAgICAgIGNvbnN0IGQgPSBkZXAoKVxuICAgICAgLy8gQ0pTIC8gaWdub3JlZCBkZXBlbmRlbmNpZXMgd29uJ3QgZXhpc3QgKCM3MTcpXG4gICAgICBpZiAoZCA9PSBudWxsKSByZXR1cm5cblxuICAgICAgZC5mb3JFYWNoKCh2LCBuKSA9PlxuICAgICAgICBuICE9PSAnZGVmYXVsdCcgJiYgY2FsbGJhY2suY2FsbCh0aGlzQXJnLCB2LCBuLCB0aGlzKSlcbiAgICB9KVxuICB9XG5cbiAgLy8gdG9kbzoga2V5cywgdmFsdWVzLCBlbnRyaWVzP1xuXG4gIHJlcG9ydEVycm9ycyhjb250ZXh0LCBkZWNsYXJhdGlvbikge1xuICAgIGNvbnRleHQucmVwb3J0KHtcbiAgICAgIG5vZGU6IGRlY2xhcmF0aW9uLnNvdXJjZSxcbiAgICAgIG1lc3NhZ2U6IGBQYXJzZSBlcnJvcnMgaW4gaW1wb3J0ZWQgbW9kdWxlICcke2RlY2xhcmF0aW9uLnNvdXJjZS52YWx1ZX0nOiBgICtcbiAgICAgICAgICAgICAgICAgIGAke3RoaXMuZXJyb3JzXG4gICAgICAgICAgICAgICAgICAgICAgICAubWFwKGUgPT4gYCR7ZS5tZXNzYWdlfSAoJHtlLmxpbmVOdW1iZXJ9OiR7ZS5jb2x1bW59KWApXG4gICAgICAgICAgICAgICAgICAgICAgICAuam9pbignLCAnKX1gLFxuICAgIH0pXG4gIH1cbn1cblxuLyoqXG4gKiBwYXJzZSBkb2NzIGZyb20gdGhlIGZpcnN0IG5vZGUgdGhhdCBoYXMgbGVhZGluZyBjb21tZW50c1xuICovXG5mdW5jdGlvbiBjYXB0dXJlRG9jKHNvdXJjZSwgZG9jU3R5bGVQYXJzZXJzLCAuLi5ub2Rlcykge1xuICBjb25zdCBtZXRhZGF0YSA9IHt9XG5cbiAgLy8gJ3NvbWUnIHNob3J0LWNpcmN1aXRzIG9uIGZpcnN0ICd0cnVlJ1xuICBub2Rlcy5zb21lKG4gPT4ge1xuICAgIHRyeSB7XG5cbiAgICAgIGxldCBsZWFkaW5nQ29tbWVudHNcblxuICAgICAgLy8gbi5sZWFkaW5nQ29tbWVudHMgaXMgbGVnYWN5IGBhdHRhY2hDb21tZW50c2AgYmVoYXZpb3JcbiAgICAgIGlmICgnbGVhZGluZ0NvbW1lbnRzJyBpbiBuKSB7XG4gICAgICAgIGxlYWRpbmdDb21tZW50cyA9IG4ubGVhZGluZ0NvbW1lbnRzXG4gICAgICB9IGVsc2UgaWYgKG4ucmFuZ2UpIHtcbiAgICAgICAgbGVhZGluZ0NvbW1lbnRzID0gc291cmNlLmdldENvbW1lbnRzQmVmb3JlKG4pXG4gICAgICB9XG5cbiAgICAgIGlmICghbGVhZGluZ0NvbW1lbnRzIHx8IGxlYWRpbmdDb21tZW50cy5sZW5ndGggPT09IDApIHJldHVybiBmYWxzZVxuXG4gICAgICBmb3IgKGxldCBuYW1lIGluIGRvY1N0eWxlUGFyc2Vycykge1xuICAgICAgICBjb25zdCBkb2MgPSBkb2NTdHlsZVBhcnNlcnNbbmFtZV0obGVhZGluZ0NvbW1lbnRzKVxuICAgICAgICBpZiAoZG9jKSB7XG4gICAgICAgICAgbWV0YWRhdGEuZG9jID0gZG9jXG4gICAgICAgIH1cbiAgICAgIH1cblxuICAgICAgcmV0dXJuIHRydWVcbiAgICB9IGNhdGNoIChlcnIpIHtcbiAgICAgIHJldHVybiBmYWxzZVxuICAgIH1cbiAgfSlcblxuICByZXR1cm4gbWV0YWRhdGFcbn1cblxuY29uc3QgYXZhaWxhYmxlRG9jU3R5bGVQYXJzZXJzID0ge1xuICBqc2RvYzogY2FwdHVyZUpzRG9jLFxuICB0b21kb2M6IGNhcHR1cmVUb21Eb2MsXG59XG5cbi8qKlxuICogcGFyc2UgSlNEb2MgZnJvbSBsZWFkaW5nIGNvbW1lbnRzXG4gKiBAcGFyYW0gIHsuLi5bdHlwZV19IGNvbW1lbnRzIFtkZXNjcmlwdGlvbl1cbiAqIEByZXR1cm4ge3tkb2M6IG9iamVjdH19XG4gKi9cbmZ1bmN0aW9uIGNhcHR1cmVKc0RvYyhjb21tZW50cykge1xuICBsZXQgZG9jXG5cbiAgLy8gY2FwdHVyZSBYU0RvY1xuICBjb21tZW50cy5mb3JFYWNoKGNvbW1lbnQgPT4ge1xuICAgIC8vIHNraXAgbm9uLWJsb2NrIGNvbW1lbnRzXG4gICAgaWYgKGNvbW1lbnQudHlwZSAhPT0gJ0Jsb2NrJykgcmV0dXJuXG4gICAgdHJ5IHtcbiAgICAgIGRvYyA9IGRvY3RyaW5lLnBhcnNlKGNvbW1lbnQudmFsdWUsIHsgdW53cmFwOiB0cnVlIH0pXG4gICAgfSBjYXRjaCAoZXJyKSB7XG4gICAgICAvKiBkb24ndCBjYXJlLCBmb3Igbm93PyBtYXliZSBhZGQgdG8gYGVycm9ycz9gICovXG4gICAgfVxuICB9KVxuXG4gIHJldHVybiBkb2Ncbn1cblxuLyoqXG4gICogcGFyc2UgVG9tRG9jIHNlY3Rpb24gZnJvbSBjb21tZW50c1xuICAqL1xuZnVuY3Rpb24gY2FwdHVyZVRvbURvYyhjb21tZW50cykge1xuICAvLyBjb2xsZWN0IGxpbmVzIHVwIHRvIGZpcnN0IHBhcmFncmFwaCBicmVha1xuICBjb25zdCBsaW5lcyA9IFtdXG4gIGZvciAobGV0IGkgPSAwOyBpIDwgY29tbWVudHMubGVuZ3RoOyBpKyspIHtcbiAgICBjb25zdCBjb21tZW50ID0gY29tbWVudHNbaV1cbiAgICBpZiAoY29tbWVudC52YWx1ZS5tYXRjaCgvXlxccyokLykpIGJyZWFrXG4gICAgbGluZXMucHVzaChjb21tZW50LnZhbHVlLnRyaW0oKSlcbiAgfVxuXG4gIC8vIHJldHVybiBkb2N0cmluZS1saWtlIG9iamVjdFxuICBjb25zdCBzdGF0dXNNYXRjaCA9IGxpbmVzLmpvaW4oJyAnKS5tYXRjaCgvXihQdWJsaWN8SW50ZXJuYWx8RGVwcmVjYXRlZCk6XFxzKiguKykvKVxuICBpZiAoc3RhdHVzTWF0Y2gpIHtcbiAgICByZXR1cm4ge1xuICAgICAgZGVzY3JpcHRpb246IHN0YXR1c01hdGNoWzJdLFxuICAgICAgdGFnczogW3tcbiAgICAgICAgdGl0bGU6IHN0YXR1c01hdGNoWzFdLnRvTG93ZXJDYXNlKCksXG4gICAgICAgIGRlc2NyaXB0aW9uOiBzdGF0dXNNYXRjaFsyXSxcbiAgICAgIH1dLFxuICAgIH1cbiAgfVxufVxuXG5FeHBvcnRNYXAuZ2V0ID0gZnVuY3Rpb24gKHNvdXJjZSwgY29udGV4dCkge1xuICBjb25zdCBwYXRoID0gcmVzb2x2ZShzb3VyY2UsIGNvbnRleHQpXG4gIGlmIChwYXRoID09IG51bGwpIHJldHVybiBudWxsXG5cbiAgcmV0dXJuIEV4cG9ydE1hcC5mb3IoY2hpbGRDb250ZXh0KHBhdGgsIGNvbnRleHQpKVxufVxuXG5FeHBvcnRNYXAuZm9yID0gZnVuY3Rpb24gKGNvbnRleHQpIHtcbiAgY29uc3QgeyBwYXRoIH0gPSBjb250ZXh0XG5cbiAgY29uc3QgY2FjaGVLZXkgPSBoYXNoT2JqZWN0KGNvbnRleHQpLmRpZ2VzdCgnaGV4JylcbiAgbGV0IGV4cG9ydE1hcCA9IGV4cG9ydENhY2hlLmdldChjYWNoZUtleSlcblxuICAvLyByZXR1cm4gY2FjaGVkIGlnbm9yZVxuICBpZiAoZXhwb3J0TWFwID09PSBudWxsKSByZXR1cm4gbnVsbFxuXG4gIGNvbnN0IHN0YXRzID0gZnMuc3RhdFN5bmMocGF0aClcbiAgaWYgKGV4cG9ydE1hcCAhPSBudWxsKSB7XG4gICAgLy8gZGF0ZSBlcXVhbGl0eSBjaGVja1xuICAgIGlmIChleHBvcnRNYXAubXRpbWUgLSBzdGF0cy5tdGltZSA9PT0gMCkge1xuICAgICAgcmV0dXJuIGV4cG9ydE1hcFxuICAgIH1cbiAgICAvLyBmdXR1cmU6IGNoZWNrIGNvbnRlbnQgZXF1YWxpdHk/XG4gIH1cblxuICAvLyBjaGVjayB2YWxpZCBleHRlbnNpb25zIGZpcnN0XG4gIGlmICghaGFzVmFsaWRFeHRlbnNpb24ocGF0aCwgY29udGV4dCkpIHtcbiAgICBleHBvcnRDYWNoZS5zZXQoY2FjaGVLZXksIG51bGwpXG4gICAgcmV0dXJuIG51bGxcbiAgfVxuXG4gIC8vIGNoZWNrIGZvciBhbmQgY2FjaGUgaWdub3JlXG4gIGlmIChpc0lnbm9yZWQocGF0aCwgY29udGV4dCkpIHtcbiAgICBsb2coJ2lnbm9yZWQgcGF0aCBkdWUgdG8gaWdub3JlIHNldHRpbmdzOicsIHBhdGgpXG4gICAgZXhwb3J0Q2FjaGUuc2V0KGNhY2hlS2V5LCBudWxsKVxuICAgIHJldHVybiBudWxsXG4gIH1cblxuICBjb25zdCBjb250ZW50ID0gZnMucmVhZEZpbGVTeW5jKHBhdGgsIHsgZW5jb2Rpbmc6ICd1dGY4JyB9KVxuXG4gIC8vIGNoZWNrIGZvciBhbmQgY2FjaGUgdW5hbWJpZ3VvdXMgbW9kdWxlc1xuICBpZiAoIXVuYW1iaWd1b3VzLnRlc3QoY29udGVudCkpIHtcbiAgICBsb2coJ2lnbm9yZWQgcGF0aCBkdWUgdG8gdW5hbWJpZ3VvdXMgcmVnZXg6JywgcGF0aClcbiAgICBleHBvcnRDYWNoZS5zZXQoY2FjaGVLZXksIG51bGwpXG4gICAgcmV0dXJuIG51bGxcbiAgfVxuXG4gIGxvZygnY2FjaGUgbWlzcycsIGNhY2hlS2V5LCAnZm9yIHBhdGgnLCBwYXRoKVxuICBleHBvcnRNYXAgPSBFeHBvcnRNYXAucGFyc2UocGF0aCwgY29udGVudCwgY29udGV4dClcblxuICAvLyBhbWJpZ3VvdXMgbW9kdWxlcyByZXR1cm4gbnVsbFxuICBpZiAoZXhwb3J0TWFwID09IG51bGwpIHJldHVybiBudWxsXG5cbiAgZXhwb3J0TWFwLm10aW1lID0gc3RhdHMubXRpbWVcblxuICBleHBvcnRDYWNoZS5zZXQoY2FjaGVLZXksIGV4cG9ydE1hcClcbiAgcmV0dXJuIGV4cG9ydE1hcFxufVxuXG5cbkV4cG9ydE1hcC5wYXJzZSA9IGZ1bmN0aW9uIChwYXRoLCBjb250ZW50LCBjb250ZXh0KSB7XG4gIHZhciBtID0gbmV3IEV4cG9ydE1hcChwYXRoKVxuXG4gIHRyeSB7XG4gICAgdmFyIGFzdCA9IHBhcnNlKHBhdGgsIGNvbnRlbnQsIGNvbnRleHQpXG4gIH0gY2F0Y2ggKGVycikge1xuICAgIGxvZygncGFyc2UgZXJyb3I6JywgcGF0aCwgZXJyKVxuICAgIG0uZXJyb3JzLnB1c2goZXJyKVxuICAgIHJldHVybiBtIC8vIGNhbid0IGNvbnRpbnVlXG4gIH1cblxuICBpZiAoIXVuYW1iaWd1b3VzLmlzTW9kdWxlKGFzdCkpIHJldHVybiBudWxsXG5cbiAgY29uc3QgZG9jc3R5bGUgPSAoY29udGV4dC5zZXR0aW5ncyAmJiBjb250ZXh0LnNldHRpbmdzWydpbXBvcnQvZG9jc3R5bGUnXSkgfHwgWydqc2RvYyddXG4gIGNvbnN0IGRvY1N0eWxlUGFyc2VycyA9IHt9XG4gIGRvY3N0eWxlLmZvckVhY2goc3R5bGUgPT4ge1xuICAgIGRvY1N0eWxlUGFyc2Vyc1tzdHlsZV0gPSBhdmFpbGFibGVEb2NTdHlsZVBhcnNlcnNbc3R5bGVdXG4gIH0pXG5cbiAgLy8gYXR0ZW1wdCB0byBjb2xsZWN0IG1vZHVsZSBkb2NcbiAgaWYgKGFzdC5jb21tZW50cykge1xuICAgIGFzdC5jb21tZW50cy5zb21lKGMgPT4ge1xuICAgICAgaWYgKGMudHlwZSAhPT0gJ0Jsb2NrJykgcmV0dXJuIGZhbHNlXG4gICAgICB0cnkge1xuICAgICAgICBjb25zdCBkb2MgPSBkb2N0cmluZS5wYXJzZShjLnZhbHVlLCB7IHVud3JhcDogdHJ1ZSB9KVxuICAgICAgICBpZiAoZG9jLnRhZ3Muc29tZSh0ID0+IHQudGl0bGUgPT09ICdtb2R1bGUnKSkge1xuICAgICAgICAgIG0uZG9jID0gZG9jXG4gICAgICAgICAgcmV0dXJuIHRydWVcbiAgICAgICAgfVxuICAgICAgfSBjYXRjaCAoZXJyKSB7IC8qIGlnbm9yZSAqLyB9XG4gICAgICByZXR1cm4gZmFsc2VcbiAgICB9KVxuICB9XG5cbiAgY29uc3QgbmFtZXNwYWNlcyA9IG5ldyBNYXAoKVxuXG4gIGZ1bmN0aW9uIHJlbW90ZVBhdGgodmFsdWUpIHtcbiAgICByZXR1cm4gcmVzb2x2ZS5yZWxhdGl2ZSh2YWx1ZSwgcGF0aCwgY29udGV4dC5zZXR0aW5ncylcbiAgfVxuXG4gIGZ1bmN0aW9uIHJlc29sdmVJbXBvcnQodmFsdWUpIHtcbiAgICBjb25zdCBycCA9IHJlbW90ZVBhdGgodmFsdWUpXG4gICAgaWYgKHJwID09IG51bGwpIHJldHVybiBudWxsXG4gICAgcmV0dXJuIEV4cG9ydE1hcC5mb3IoY2hpbGRDb250ZXh0KHJwLCBjb250ZXh0KSlcbiAgfVxuXG4gIGZ1bmN0aW9uIGdldE5hbWVzcGFjZShpZGVudGlmaWVyKSB7XG4gICAgaWYgKCFuYW1lc3BhY2VzLmhhcyhpZGVudGlmaWVyLm5hbWUpKSByZXR1cm5cblxuICAgIHJldHVybiBmdW5jdGlvbiAoKSB7XG4gICAgICByZXR1cm4gcmVzb2x2ZUltcG9ydChuYW1lc3BhY2VzLmdldChpZGVudGlmaWVyLm5hbWUpKVxuICAgIH1cbiAgfVxuXG4gIGZ1bmN0aW9uIGFkZE5hbWVzcGFjZShvYmplY3QsIGlkZW50aWZpZXIpIHtcbiAgICBjb25zdCBuc2ZuID0gZ2V0TmFtZXNwYWNlKGlkZW50aWZpZXIpXG4gICAgaWYgKG5zZm4pIHtcbiAgICAgIE9iamVjdC5kZWZpbmVQcm9wZXJ0eShvYmplY3QsICduYW1lc3BhY2UnLCB7IGdldDogbnNmbiB9KVxuICAgIH1cblxuICAgIHJldHVybiBvYmplY3RcbiAgfVxuXG4gIGZ1bmN0aW9uIGNhcHR1cmVEZXBlbmRlbmN5KGRlY2xhcmF0aW9uKSB7XG4gICAgaWYgKGRlY2xhcmF0aW9uLnNvdXJjZSA9PSBudWxsKSByZXR1cm4gbnVsbFxuICAgIGlmIChkZWNsYXJhdGlvbi5pbXBvcnRLaW5kID09PSAndHlwZScpIHJldHVybiBudWxsIC8vIHNraXAgRmxvdyB0eXBlIGltcG9ydHNcbiAgICBjb25zdCBpbXBvcnRlZFNwZWNpZmllcnMgPSBuZXcgU2V0KClcbiAgICBjb25zdCBzdXBwb3J0ZWRUeXBlcyA9IG5ldyBTZXQoWydJbXBvcnREZWZhdWx0U3BlY2lmaWVyJywgJ0ltcG9ydE5hbWVzcGFjZVNwZWNpZmllciddKVxuICAgIGxldCBoYXNJbXBvcnRlZFR5cGUgPSBmYWxzZVxuICAgIGlmIChkZWNsYXJhdGlvbi5zcGVjaWZpZXJzKSB7XG4gICAgICBkZWNsYXJhdGlvbi5zcGVjaWZpZXJzLmZvckVhY2goc3BlY2lmaWVyID0+IHtcbiAgICAgICAgY29uc3QgaXNUeXBlID0gc3BlY2lmaWVyLmltcG9ydEtpbmQgPT09ICd0eXBlJ1xuICAgICAgICBoYXNJbXBvcnRlZFR5cGUgPSBoYXNJbXBvcnRlZFR5cGUgfHwgaXNUeXBlXG5cbiAgICAgICAgaWYgKHN1cHBvcnRlZFR5cGVzLmhhcyhzcGVjaWZpZXIudHlwZSkgJiYgIWlzVHlwZSkge1xuICAgICAgICAgIGltcG9ydGVkU3BlY2lmaWVycy5hZGQoc3BlY2lmaWVyLnR5cGUpXG4gICAgICAgIH1cbiAgICAgICAgaWYgKHNwZWNpZmllci50eXBlID09PSAnSW1wb3J0U3BlY2lmaWVyJyAmJiAhaXNUeXBlKSB7XG4gICAgICAgICAgaW1wb3J0ZWRTcGVjaWZpZXJzLmFkZChzcGVjaWZpZXIuaW1wb3J0ZWQubmFtZSlcbiAgICAgICAgfVxuICAgICAgfSlcbiAgICB9XG5cbiAgICAvLyBvbmx5IEZsb3cgdHlwZXMgd2VyZSBpbXBvcnRlZFxuICAgIGlmIChoYXNJbXBvcnRlZFR5cGUgJiYgaW1wb3J0ZWRTcGVjaWZpZXJzLnNpemUgPT09IDApIHJldHVybiBudWxsXG5cbiAgICBjb25zdCBwID0gcmVtb3RlUGF0aChkZWNsYXJhdGlvbi5zb3VyY2UudmFsdWUpXG4gICAgaWYgKHAgPT0gbnVsbCkgcmV0dXJuIG51bGxcbiAgICBjb25zdCBleGlzdGluZyA9IG0uaW1wb3J0cy5nZXQocClcbiAgICBpZiAoZXhpc3RpbmcgIT0gbnVsbCkgcmV0dXJuIGV4aXN0aW5nLmdldHRlclxuXG4gICAgY29uc3QgZ2V0dGVyID0gdGh1bmtGb3IocCwgY29udGV4dClcbiAgICBtLmltcG9ydHMuc2V0KHAsIHtcbiAgICAgIGdldHRlcixcbiAgICAgIHNvdXJjZTogeyAgLy8gY2FwdHVyaW5nIGFjdHVhbCBub2RlIHJlZmVyZW5jZSBob2xkcyBmdWxsIEFTVCBpbiBtZW1vcnkhXG4gICAgICAgIHZhbHVlOiBkZWNsYXJhdGlvbi5zb3VyY2UudmFsdWUsXG4gICAgICAgIGxvYzogZGVjbGFyYXRpb24uc291cmNlLmxvYyxcbiAgICAgIH0sXG4gICAgICBpbXBvcnRlZFNwZWNpZmllcnMsXG4gICAgfSlcbiAgICByZXR1cm4gZ2V0dGVyXG4gIH1cblxuICBjb25zdCBzb3VyY2UgPSBtYWtlU291cmNlQ29kZShjb250ZW50LCBhc3QpXG5cbiAgZnVuY3Rpb24gaXNFc01vZHVsZUludGVyb3AoKSB7XG4gICAgY29uc3QgdHNDb25maWdJbmZvID0gdHNDb25maWdMb2FkZXIoe1xuICAgICAgY3dkOiBjb250ZXh0LnBhcnNlck9wdGlvbnMgJiYgY29udGV4dC5wYXJzZXJPcHRpb25zLnRzY29uZmlnUm9vdERpciB8fCBwcm9jZXNzLmN3ZCgpLFxuICAgICAgZ2V0RW52OiAoa2V5KSA9PiBwcm9jZXNzLmVudltrZXldLFxuICAgIH0pXG4gICAgdHJ5IHtcbiAgICAgIGlmICh0c0NvbmZpZ0luZm8udHNDb25maWdQYXRoICE9PSB1bmRlZmluZWQpIHtcbiAgICAgICAgY29uc3QganNvblRleHQgPSBmcy5yZWFkRmlsZVN5bmModHNDb25maWdJbmZvLnRzQ29uZmlnUGF0aCkudG9TdHJpbmcoKVxuICAgICAgICBpZiAoIXBhcnNlQ29uZmlnRmlsZVRleHRUb0pzb24pIHtcbiAgICAgICAgICAvLyB0aGlzIGlzIGJlY2F1c2UgcHJvamVjdHMgbm90IHVzaW5nIFR5cGVTY3JpcHQgd29uJ3QgaGF2ZSB0eXBlc2NyaXB0IGluc3RhbGxlZFxuICAgICAgICAgICh7cGFyc2VDb25maWdGaWxlVGV4dFRvSnNvbn0gPSByZXF1aXJlKCd0eXBlc2NyaXB0JykpXG4gICAgICAgIH1cbiAgICAgICAgY29uc3QgdHNDb25maWcgPSBwYXJzZUNvbmZpZ0ZpbGVUZXh0VG9Kc29uKHRzQ29uZmlnSW5mby50c0NvbmZpZ1BhdGgsIGpzb25UZXh0KS5jb25maWdcbiAgICAgICAgcmV0dXJuIHRzQ29uZmlnLmNvbXBpbGVyT3B0aW9ucy5lc01vZHVsZUludGVyb3BcbiAgICAgIH1cbiAgICB9IGNhdGNoIChlKSB7XG4gICAgICByZXR1cm4gZmFsc2VcbiAgICB9XG4gIH1cblxuICBhc3QuYm9keS5mb3JFYWNoKGZ1bmN0aW9uIChuKSB7XG4gICAgaWYgKG4udHlwZSA9PT0gJ0V4cG9ydERlZmF1bHREZWNsYXJhdGlvbicpIHtcbiAgICAgIGNvbnN0IGV4cG9ydE1ldGEgPSBjYXB0dXJlRG9jKHNvdXJjZSwgZG9jU3R5bGVQYXJzZXJzLCBuKVxuICAgICAgaWYgKG4uZGVjbGFyYXRpb24udHlwZSA9PT0gJ0lkZW50aWZpZXInKSB7XG4gICAgICAgIGFkZE5hbWVzcGFjZShleHBvcnRNZXRhLCBuLmRlY2xhcmF0aW9uKVxuICAgICAgfVxuICAgICAgbS5uYW1lc3BhY2Uuc2V0KCdkZWZhdWx0JywgZXhwb3J0TWV0YSlcbiAgICAgIHJldHVyblxuICAgIH1cblxuICAgIGlmIChuLnR5cGUgPT09ICdFeHBvcnRBbGxEZWNsYXJhdGlvbicpIHtcbiAgICAgIGNvbnN0IGdldHRlciA9IGNhcHR1cmVEZXBlbmRlbmN5KG4pXG4gICAgICBpZiAoZ2V0dGVyKSBtLmRlcGVuZGVuY2llcy5hZGQoZ2V0dGVyKVxuICAgICAgcmV0dXJuXG4gICAgfVxuXG4gICAgLy8gY2FwdHVyZSBuYW1lc3BhY2VzIGluIGNhc2Ugb2YgbGF0ZXIgZXhwb3J0XG4gICAgaWYgKG4udHlwZSA9PT0gJ0ltcG9ydERlY2xhcmF0aW9uJykge1xuICAgICAgY2FwdHVyZURlcGVuZGVuY3kobilcbiAgICAgIGxldCBuc1xuICAgICAgaWYgKG4uc3BlY2lmaWVycy5zb21lKHMgPT4gcy50eXBlID09PSAnSW1wb3J0TmFtZXNwYWNlU3BlY2lmaWVyJyAmJiAobnMgPSBzKSkpIHtcbiAgICAgICAgbmFtZXNwYWNlcy5zZXQobnMubG9jYWwubmFtZSwgbi5zb3VyY2UudmFsdWUpXG4gICAgICB9XG4gICAgICByZXR1cm5cbiAgICB9XG5cbiAgICBpZiAobi50eXBlID09PSAnRXhwb3J0TmFtZWREZWNsYXJhdGlvbicpIHtcbiAgICAgIC8vIGNhcHR1cmUgZGVjbGFyYXRpb25cbiAgICAgIGlmIChuLmRlY2xhcmF0aW9uICE9IG51bGwpIHtcbiAgICAgICAgc3dpdGNoIChuLmRlY2xhcmF0aW9uLnR5cGUpIHtcbiAgICAgICAgICBjYXNlICdGdW5jdGlvbkRlY2xhcmF0aW9uJzpcbiAgICAgICAgICBjYXNlICdDbGFzc0RlY2xhcmF0aW9uJzpcbiAgICAgICAgICBjYXNlICdUeXBlQWxpYXMnOiAvLyBmbG93dHlwZSB3aXRoIGJhYmVsLWVzbGludCBwYXJzZXJcbiAgICAgICAgICBjYXNlICdJbnRlcmZhY2VEZWNsYXJhdGlvbic6XG4gICAgICAgICAgY2FzZSAnRGVjbGFyZUZ1bmN0aW9uJzpcbiAgICAgICAgICBjYXNlICdUU0RlY2xhcmVGdW5jdGlvbic6XG4gICAgICAgICAgY2FzZSAnVFNFbnVtRGVjbGFyYXRpb24nOlxuICAgICAgICAgIGNhc2UgJ1RTVHlwZUFsaWFzRGVjbGFyYXRpb24nOlxuICAgICAgICAgIGNhc2UgJ1RTSW50ZXJmYWNlRGVjbGFyYXRpb24nOlxuICAgICAgICAgIGNhc2UgJ1RTQWJzdHJhY3RDbGFzc0RlY2xhcmF0aW9uJzpcbiAgICAgICAgICBjYXNlICdUU01vZHVsZURlY2xhcmF0aW9uJzpcbiAgICAgICAgICAgIG0ubmFtZXNwYWNlLnNldChuLmRlY2xhcmF0aW9uLmlkLm5hbWUsIGNhcHR1cmVEb2Moc291cmNlLCBkb2NTdHlsZVBhcnNlcnMsIG4pKVxuICAgICAgICAgICAgYnJlYWtcbiAgICAgICAgICBjYXNlICdWYXJpYWJsZURlY2xhcmF0aW9uJzpcbiAgICAgICAgICAgIG4uZGVjbGFyYXRpb24uZGVjbGFyYXRpb25zLmZvckVhY2goKGQpID0+XG4gICAgICAgICAgICAgIHJlY3Vyc2l2ZVBhdHRlcm5DYXB0dXJlKGQuaWQsXG4gICAgICAgICAgICAgICAgaWQgPT4gbS5uYW1lc3BhY2Uuc2V0KGlkLm5hbWUsIGNhcHR1cmVEb2Moc291cmNlLCBkb2NTdHlsZVBhcnNlcnMsIGQsIG4pKSkpXG4gICAgICAgICAgICBicmVha1xuICAgICAgICB9XG4gICAgICB9XG5cbiAgICAgIGNvbnN0IG5zb3VyY2UgPSBuLnNvdXJjZSAmJiBuLnNvdXJjZS52YWx1ZVxuICAgICAgbi5zcGVjaWZpZXJzLmZvckVhY2goKHMpID0+IHtcbiAgICAgICAgY29uc3QgZXhwb3J0TWV0YSA9IHt9XG4gICAgICAgIGxldCBsb2NhbFxuXG4gICAgICAgIHN3aXRjaCAocy50eXBlKSB7XG4gICAgICAgICAgY2FzZSAnRXhwb3J0RGVmYXVsdFNwZWNpZmllcic6XG4gICAgICAgICAgICBpZiAoIW4uc291cmNlKSByZXR1cm5cbiAgICAgICAgICAgIGxvY2FsID0gJ2RlZmF1bHQnXG4gICAgICAgICAgICBicmVha1xuICAgICAgICAgIGNhc2UgJ0V4cG9ydE5hbWVzcGFjZVNwZWNpZmllcic6XG4gICAgICAgICAgICBtLm5hbWVzcGFjZS5zZXQocy5leHBvcnRlZC5uYW1lLCBPYmplY3QuZGVmaW5lUHJvcGVydHkoZXhwb3J0TWV0YSwgJ25hbWVzcGFjZScsIHtcbiAgICAgICAgICAgICAgZ2V0KCkgeyByZXR1cm4gcmVzb2x2ZUltcG9ydChuc291cmNlKSB9LFxuICAgICAgICAgICAgfSkpXG4gICAgICAgICAgICByZXR1cm5cbiAgICAgICAgICBjYXNlICdFeHBvcnRTcGVjaWZpZXInOlxuICAgICAgICAgICAgaWYgKCFuLnNvdXJjZSkge1xuICAgICAgICAgICAgICBtLm5hbWVzcGFjZS5zZXQocy5leHBvcnRlZC5uYW1lLCBhZGROYW1lc3BhY2UoZXhwb3J0TWV0YSwgcy5sb2NhbCkpXG4gICAgICAgICAgICAgIHJldHVyblxuICAgICAgICAgICAgfVxuICAgICAgICAgICAgLy8gZWxzZSBmYWxscyB0aHJvdWdoXG4gICAgICAgICAgZGVmYXVsdDpcbiAgICAgICAgICAgIGxvY2FsID0gcy5sb2NhbC5uYW1lXG4gICAgICAgICAgICBicmVha1xuICAgICAgICB9XG5cbiAgICAgICAgLy8gdG9kbzogSlNEb2NcbiAgICAgICAgbS5yZWV4cG9ydHMuc2V0KHMuZXhwb3J0ZWQubmFtZSwgeyBsb2NhbCwgZ2V0SW1wb3J0OiAoKSA9PiByZXNvbHZlSW1wb3J0KG5zb3VyY2UpIH0pXG4gICAgICB9KVxuICAgIH1cblxuICAgIGNvbnN0IGlzRXNNb2R1bGVJbnRlcm9wVHJ1ZSA9IGlzRXNNb2R1bGVJbnRlcm9wKClcblxuICAgIGNvbnN0IGV4cG9ydHMgPSBbJ1RTRXhwb3J0QXNzaWdubWVudCddXG4gICAgaWYgKGlzRXNNb2R1bGVJbnRlcm9wVHJ1ZSkge1xuICAgICAgZXhwb3J0cy5wdXNoKCdUU05hbWVzcGFjZUV4cG9ydERlY2xhcmF0aW9uJylcbiAgICB9XG5cbiAgICAvLyBUaGlzIGRvZXNuJ3QgZGVjbGFyZSBhbnl0aGluZywgYnV0IGNoYW5nZXMgd2hhdCdzIGJlaW5nIGV4cG9ydGVkLlxuICAgIGlmIChpbmNsdWRlcyhleHBvcnRzLCBuLnR5cGUpKSB7XG4gICAgICBjb25zdCBleHBvcnRlZE5hbWUgPSBuLnR5cGUgPT09ICdUU05hbWVzcGFjZUV4cG9ydERlY2xhcmF0aW9uJ1xuICAgICAgICA/IG4uaWQubmFtZVxuICAgICAgICA6IChuLmV4cHJlc3Npb24gJiYgbi5leHByZXNzaW9uLm5hbWUgfHwgKG4uZXhwcmVzc2lvbi5pZCAmJiBuLmV4cHJlc3Npb24uaWQubmFtZSkgfHwgbnVsbClcbiAgICAgIGNvbnN0IGRlY2xUeXBlcyA9IFtcbiAgICAgICAgJ1ZhcmlhYmxlRGVjbGFyYXRpb24nLFxuICAgICAgICAnQ2xhc3NEZWNsYXJhdGlvbicsXG4gICAgICAgICdUU0RlY2xhcmVGdW5jdGlvbicsXG4gICAgICAgICdUU0VudW1EZWNsYXJhdGlvbicsXG4gICAgICAgICdUU1R5cGVBbGlhc0RlY2xhcmF0aW9uJyxcbiAgICAgICAgJ1RTSW50ZXJmYWNlRGVjbGFyYXRpb24nLFxuICAgICAgICAnVFNBYnN0cmFjdENsYXNzRGVjbGFyYXRpb24nLFxuICAgICAgICAnVFNNb2R1bGVEZWNsYXJhdGlvbicsXG4gICAgICBdXG4gICAgICBjb25zdCBleHBvcnRlZERlY2xzID0gYXN0LmJvZHkuZmlsdGVyKCh7IHR5cGUsIGlkLCBkZWNsYXJhdGlvbnMgfSkgPT4gaW5jbHVkZXMoZGVjbFR5cGVzLCB0eXBlKSAmJiAoXG4gICAgICAgIChpZCAmJiBpZC5uYW1lID09PSBleHBvcnRlZE5hbWUpIHx8IChkZWNsYXJhdGlvbnMgJiYgZGVjbGFyYXRpb25zLmZpbmQoKGQpID0+IGQuaWQubmFtZSA9PT0gZXhwb3J0ZWROYW1lKSlcbiAgICAgICkpXG4gICAgICBpZiAoZXhwb3J0ZWREZWNscy5sZW5ndGggPT09IDApIHtcbiAgICAgICAgLy8gRXhwb3J0IGlzIG5vdCByZWZlcmVuY2luZyBhbnkgbG9jYWwgZGVjbGFyYXRpb24sIG11c3QgYmUgcmUtZXhwb3J0aW5nXG4gICAgICAgIG0ubmFtZXNwYWNlLnNldCgnZGVmYXVsdCcsIGNhcHR1cmVEb2Moc291cmNlLCBkb2NTdHlsZVBhcnNlcnMsIG4pKVxuICAgICAgICByZXR1cm5cbiAgICAgIH1cbiAgICAgIGlmIChpc0VzTW9kdWxlSW50ZXJvcFRydWUpIHtcbiAgICAgICAgbS5uYW1lc3BhY2Uuc2V0KCdkZWZhdWx0Jywge30pXG4gICAgICB9XG4gICAgICBleHBvcnRlZERlY2xzLmZvckVhY2goKGRlY2wpID0+IHtcbiAgICAgICAgaWYgKGRlY2wudHlwZSA9PT0gJ1RTTW9kdWxlRGVjbGFyYXRpb24nKSB7XG4gICAgICAgICAgaWYgKGRlY2wuYm9keSAmJiBkZWNsLmJvZHkudHlwZSA9PT0gJ1RTTW9kdWxlRGVjbGFyYXRpb24nKSB7XG4gICAgICAgICAgICBtLm5hbWVzcGFjZS5zZXQoZGVjbC5ib2R5LmlkLm5hbWUsIGNhcHR1cmVEb2Moc291cmNlLCBkb2NTdHlsZVBhcnNlcnMsIGRlY2wuYm9keSkpXG4gICAgICAgICAgfSBlbHNlIGlmIChkZWNsLmJvZHkgJiYgZGVjbC5ib2R5LmJvZHkpIHtcbiAgICAgICAgICAgIGRlY2wuYm9keS5ib2R5LmZvckVhY2goKG1vZHVsZUJsb2NrTm9kZSkgPT4ge1xuICAgICAgICAgICAgICAvLyBFeHBvcnQtYXNzaWdubWVudCBleHBvcnRzIGFsbCBtZW1iZXJzIGluIHRoZSBuYW1lc3BhY2UsXG4gICAgICAgICAgICAgIC8vIGV4cGxpY2l0bHkgZXhwb3J0ZWQgb3Igbm90LlxuICAgICAgICAgICAgICBjb25zdCBuYW1lc3BhY2VEZWNsID0gbW9kdWxlQmxvY2tOb2RlLnR5cGUgPT09ICdFeHBvcnROYW1lZERlY2xhcmF0aW9uJyA/XG4gICAgICAgICAgICAgICAgbW9kdWxlQmxvY2tOb2RlLmRlY2xhcmF0aW9uIDpcbiAgICAgICAgICAgICAgICBtb2R1bGVCbG9ja05vZGVcblxuICAgICAgICAgICAgICBpZiAoIW5hbWVzcGFjZURlY2wpIHtcbiAgICAgICAgICAgICAgICAvLyBUeXBlU2NyaXB0IGNhbiBjaGVjayB0aGlzIGZvciB1czsgd2UgbmVlZG4ndFxuICAgICAgICAgICAgICB9IGVsc2UgaWYgKG5hbWVzcGFjZURlY2wudHlwZSA9PT0gJ1ZhcmlhYmxlRGVjbGFyYXRpb24nKSB7XG4gICAgICAgICAgICAgICAgbmFtZXNwYWNlRGVjbC5kZWNsYXJhdGlvbnMuZm9yRWFjaCgoZCkgPT5cbiAgICAgICAgICAgICAgICAgIHJlY3Vyc2l2ZVBhdHRlcm5DYXB0dXJlKGQuaWQsIChpZCkgPT4gbS5uYW1lc3BhY2Uuc2V0KFxuICAgICAgICAgICAgICAgICAgICBpZC5uYW1lLFxuICAgICAgICAgICAgICAgICAgICBjYXB0dXJlRG9jKHNvdXJjZSwgZG9jU3R5bGVQYXJzZXJzLCBkZWNsLCBuYW1lc3BhY2VEZWNsLCBtb2R1bGVCbG9ja05vZGUpXG4gICAgICAgICAgICAgICAgICApKVxuICAgICAgICAgICAgICAgIClcbiAgICAgICAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICAgICAgICBtLm5hbWVzcGFjZS5zZXQoXG4gICAgICAgICAgICAgICAgICBuYW1lc3BhY2VEZWNsLmlkLm5hbWUsXG4gICAgICAgICAgICAgICAgICBjYXB0dXJlRG9jKHNvdXJjZSwgZG9jU3R5bGVQYXJzZXJzLCBtb2R1bGVCbG9ja05vZGUpKVxuICAgICAgICAgICAgICB9XG4gICAgICAgICAgICB9KVxuICAgICAgICAgIH1cbiAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICAvLyBFeHBvcnQgYXMgZGVmYXVsdFxuICAgICAgICAgIG0ubmFtZXNwYWNlLnNldCgnZGVmYXVsdCcsIGNhcHR1cmVEb2Moc291cmNlLCBkb2NTdHlsZVBhcnNlcnMsIGRlY2wpKVxuICAgICAgICB9XG4gICAgICB9KVxuICAgIH1cbiAgfSlcblxuICByZXR1cm4gbVxufVxuXG4vKipcbiAqIFRoZSBjcmVhdGlvbiBvZiB0aGlzIGNsb3N1cmUgaXMgaXNvbGF0ZWQgZnJvbSBvdGhlciBzY29wZXNcbiAqIHRvIGF2b2lkIG92ZXItcmV0ZW50aW9uIG9mIHVucmVsYXRlZCB2YXJpYWJsZXMsIHdoaWNoIGhhc1xuICogY2F1c2VkIG1lbW9yeSBsZWFrcy4gU2VlICMxMjY2LlxuICovXG5mdW5jdGlvbiB0aHVua0ZvcihwLCBjb250ZXh0KSB7XG4gIHJldHVybiAoKSA9PiBFeHBvcnRNYXAuZm9yKGNoaWxkQ29udGV4dChwLCBjb250ZXh0KSlcbn1cblxuXG4vKipcbiAqIFRyYXZlcnNlIGEgcGF0dGVybi9pZGVudGlmaWVyIG5vZGUsIGNhbGxpbmcgJ2NhbGxiYWNrJ1xuICogZm9yIGVhY2ggbGVhZiBpZGVudGlmaWVyLlxuICogQHBhcmFtICB7bm9kZX0gICBwYXR0ZXJuXG4gKiBAcGFyYW0gIHtGdW5jdGlvbn0gY2FsbGJhY2tcbiAqIEByZXR1cm4ge3ZvaWR9XG4gKi9cbmV4cG9ydCBmdW5jdGlvbiByZWN1cnNpdmVQYXR0ZXJuQ2FwdHVyZShwYXR0ZXJuLCBjYWxsYmFjaykge1xuICBzd2l0Y2ggKHBhdHRlcm4udHlwZSkge1xuICAgIGNhc2UgJ0lkZW50aWZpZXInOiAvLyBiYXNlIGNhc2VcbiAgICAgIGNhbGxiYWNrKHBhdHRlcm4pXG4gICAgICBicmVha1xuXG4gICAgY2FzZSAnT2JqZWN0UGF0dGVybic6XG4gICAgICBwYXR0ZXJuLnByb3BlcnRpZXMuZm9yRWFjaChwID0+IHtcbiAgICAgICAgaWYgKHAudHlwZSA9PT0gJ0V4cGVyaW1lbnRhbFJlc3RQcm9wZXJ0eScgfHwgcC50eXBlID09PSAnUmVzdEVsZW1lbnQnKSB7XG4gICAgICAgICAgY2FsbGJhY2socC5hcmd1bWVudClcbiAgICAgICAgICByZXR1cm5cbiAgICAgICAgfVxuICAgICAgICByZWN1cnNpdmVQYXR0ZXJuQ2FwdHVyZShwLnZhbHVlLCBjYWxsYmFjaylcbiAgICAgIH0pXG4gICAgICBicmVha1xuXG4gICAgY2FzZSAnQXJyYXlQYXR0ZXJuJzpcbiAgICAgIHBhdHRlcm4uZWxlbWVudHMuZm9yRWFjaCgoZWxlbWVudCkgPT4ge1xuICAgICAgICBpZiAoZWxlbWVudCA9PSBudWxsKSByZXR1cm5cbiAgICAgICAgaWYgKGVsZW1lbnQudHlwZSA9PT0gJ0V4cGVyaW1lbnRhbFJlc3RQcm9wZXJ0eScgfHwgZWxlbWVudC50eXBlID09PSAnUmVzdEVsZW1lbnQnKSB7XG4gICAgICAgICAgY2FsbGJhY2soZWxlbWVudC5hcmd1bWVudClcbiAgICAgICAgICByZXR1cm5cbiAgICAgICAgfVxuICAgICAgICByZWN1cnNpdmVQYXR0ZXJuQ2FwdHVyZShlbGVtZW50LCBjYWxsYmFjaylcbiAgICAgIH0pXG4gICAgICBicmVha1xuXG4gICAgY2FzZSAnQXNzaWdubWVudFBhdHRlcm4nOlxuICAgICAgY2FsbGJhY2socGF0dGVybi5sZWZ0KVxuICAgICAgYnJlYWtcbiAgfVxufVxuXG4vKipcbiAqIGRvbid0IGhvbGQgZnVsbCBjb250ZXh0IG9iamVjdCBpbiBtZW1vcnksIGp1c3QgZ3JhYiB3aGF0IHdlIG5lZWQuXG4gKi9cbmZ1bmN0aW9uIGNoaWxkQ29udGV4dChwYXRoLCBjb250ZXh0KSB7XG4gIGNvbnN0IHsgc2V0dGluZ3MsIHBhcnNlck9wdGlvbnMsIHBhcnNlclBhdGggfSA9IGNvbnRleHRcbiAgcmV0dXJuIHtcbiAgICBzZXR0aW5ncyxcbiAgICBwYXJzZXJPcHRpb25zLFxuICAgIHBhcnNlclBhdGgsXG4gICAgcGF0aCxcbiAgfVxufVxuXG5cbi8qKlxuICogc29tZXRpbWVzIGxlZ2FjeSBzdXBwb3J0IGlzbid0IF90aGF0XyBoYXJkLi4uIHJpZ2h0P1xuICovXG5mdW5jdGlvbiBtYWtlU291cmNlQ29kZSh0ZXh0LCBhc3QpIHtcbiAgaWYgKFNvdXJjZUNvZGUubGVuZ3RoID4gMSkge1xuICAgIC8vIEVTTGludCAzXG4gICAgcmV0dXJuIG5ldyBTb3VyY2VDb2RlKHRleHQsIGFzdClcbiAgfSBlbHNlIHtcbiAgICAvLyBFU0xpbnQgNCwgNVxuICAgIHJldHVybiBuZXcgU291cmNlQ29kZSh7IHRleHQsIGFzdCB9KVxuICB9XG59XG4iXX0=