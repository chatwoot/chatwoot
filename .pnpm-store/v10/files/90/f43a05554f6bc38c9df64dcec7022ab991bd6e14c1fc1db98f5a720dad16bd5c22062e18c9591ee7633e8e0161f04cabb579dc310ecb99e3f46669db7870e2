'use strict';var _typeof = typeof Symbol === "function" && typeof Symbol.iterator === "symbol" ? function (obj) {return typeof obj;} : function (obj) {return obj && typeof Symbol === "function" && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj;};





var _ignore = require('eslint-module-utils/ignore');
var _resolve = require('eslint-module-utils/resolve');var _resolve2 = _interopRequireDefault(_resolve);
var _visit = require('eslint-module-utils/visit');var _visit2 = _interopRequireDefault(_visit);
var _path = require('path');
var _readPkgUp2 = require('eslint-module-utils/readPkgUp');var _readPkgUp3 = _interopRequireDefault(_readPkgUp2);
var _object = require('object.values');var _object2 = _interopRequireDefault(_object);
var _arrayIncludes = require('array-includes');var _arrayIncludes2 = _interopRequireDefault(_arrayIncludes);
var _arrayPrototype = require('array.prototype.flatmap');var _arrayPrototype2 = _interopRequireDefault(_arrayPrototype);

var _fsWalk = require('../core/fsWalk');
var _builder = require('../exportMap/builder');var _builder2 = _interopRequireDefault(_builder);
var _patternCapture = require('../exportMap/patternCapture');var _patternCapture2 = _interopRequireDefault(_patternCapture);
var _docsUrl = require('../docsUrl');var _docsUrl2 = _interopRequireDefault(_docsUrl);function _interopRequireDefault(obj) {return obj && obj.__esModule ? obj : { 'default': obj };}function _toConsumableArray(arr) {if (Array.isArray(arr)) {for (var i = 0, arr2 = Array(arr.length); i < arr.length; i++) {arr2[i] = arr[i];}return arr2;} else {return Array.from(arr);}} /**
                                                                                                                                                                                                                                                                                                                                                                                 * @fileOverview Ensures that modules contain exports and/or all
                                                                                                                                                                                                                                                                                                                                                                                 * modules are consumed within other modules.
                                                                                                                                                                                                                                                                                                                                                                                 * @author René Fermann
                                                                                                                                                                                                                                                                                                                                                                                 */ /**
                                                                                                                                                                                                                                                                                                                                                                                     * Attempt to load the internal `FileEnumerator` class, which has existed in a couple
                                                                                                                                                                                                                                                                                                                                                                                     * of different places, depending on the version of `eslint`.  Try requiring it from both
                                                                                                                                                                                                                                                                                                                                                                                     * locations.
                                                                                                                                                                                                                                                                                                                                                                                     * @returns Returns the `FileEnumerator` class if its requirable, otherwise `undefined`.
                                                                                                                                                                                                                                                                                                                                                                                     */function requireFileEnumerator() {var FileEnumerator = void 0;

  // Try getting it from the eslint private / deprecated api
  try {var _require =
    require('eslint/use-at-your-own-risk');FileEnumerator = _require.FileEnumerator;
  } catch (e) {
    // Absorb this if it's MODULE_NOT_FOUND
    if (e.code !== 'MODULE_NOT_FOUND') {
      throw e;
    }

    // If not there, then try getting it from eslint/lib/cli-engine/file-enumerator (moved there in v6)
    try {var _require2 =
      require('eslint/lib/cli-engine/file-enumerator');FileEnumerator = _require2.FileEnumerator;
    } catch (e) {
      // Absorb this if it's MODULE_NOT_FOUND
      if (e.code !== 'MODULE_NOT_FOUND') {
        throw e;
      }
    }
  }
  return FileEnumerator;
}

/**
   *
   * @param FileEnumerator the `FileEnumerator` class from `eslint`'s internal api
   * @param {string} src path to the src root
   * @param {string[]} extensions list of supported extensions
   * @returns {{ filename: string, ignored: boolean }[]} list of files to operate on
   */
function listFilesUsingFileEnumerator(FileEnumerator, src, extensions) {
  var e = new FileEnumerator({
    extensions: extensions });


  return Array.from(
  e.iterateFiles(src),
  function (_ref) {var filePath = _ref.filePath,ignored = _ref.ignored;return { filename: filePath, ignored: ignored };});

}

/**
   * Attempt to require old versions of the file enumeration capability from v6 `eslint` and earlier, and use
   * those functions to provide the list of files to operate on
   * @param {string} src path to the src root
   * @param {string[]} extensions list of supported extensions
   * @returns {string[]} list of files to operate on
   */
function listFilesWithLegacyFunctions(src, extensions) {
  try {
    // eslint/lib/util/glob-util has been moved to eslint/lib/util/glob-utils with version 5.3
    var _require3 = require('eslint/lib/util/glob-utils'),originalListFilesToProcess = _require3.listFilesToProcess;
    // Prevent passing invalid options (extensions array) to old versions of the function.
    // https://github.com/eslint/eslint/blob/v5.16.0/lib/util/glob-utils.js#L178-L280
    // https://github.com/eslint/eslint/blob/v5.2.0/lib/util/glob-util.js#L174-L269

    return originalListFilesToProcess(src, {
      extensions: extensions });

  } catch (e) {
    // Absorb this if it's MODULE_NOT_FOUND
    if (e.code !== 'MODULE_NOT_FOUND') {
      throw e;
    }

    // Last place to try (pre v5.3)
    var _require4 =

    require('eslint/lib/util/glob-util'),_originalListFilesToProcess = _require4.listFilesToProcess;
    var patterns = src.concat(
    (0, _arrayPrototype2['default'])(
    src,
    function (pattern) {return extensions.map(function (extension) {return (/\*\*|\*\./.test(pattern) ? pattern : String(pattern) + '/**/*' + String(extension));});}));



    return _originalListFilesToProcess(patterns);
  }
}

/**
   * Given a source root and list of supported extensions, use fsWalk and the
   * new `eslint` `context.session` api to build the list of files we want to operate on
   * @param {string[]} srcPaths array of source paths (for flat config this should just be a singular root (e.g. cwd))
   * @param {string[]} extensions list of supported extensions
   * @param {{ isDirectoryIgnored: (path: string) => boolean, isFileIgnored: (path: string) => boolean }} session eslint context session object
   * @returns {string[]} list of files to operate on
   */
function listFilesWithModernApi(srcPaths, extensions, session) {
  /** @type {string[]} */
  var files = [];var _loop = function _loop(

  i) {
    var src = srcPaths[i];
    // Use walkSync along with the new session api to gather the list of files
    var entries = (0, _fsWalk.walkSync)(src, {
      deepFilter: function () {function deepFilter(entry) {
          var fullEntryPath = (0, _path.resolve)(src, entry.path);

          // Include the directory if it's not marked as ignore by eslint
          return !session.isDirectoryIgnored(fullEntryPath);
        }return deepFilter;}(),
      entryFilter: function () {function entryFilter(entry) {
          var fullEntryPath = (0, _path.resolve)(src, entry.path);

          // Include the file if it's not marked as ignore by eslint and its extension is included in our list
          return (
            !session.isFileIgnored(fullEntryPath) &&
            extensions.find(function (extension) {return entry.path.endsWith(extension);}));

        }return entryFilter;}() });


    // Filter out directories and map entries to their paths
    files.push.apply(files, _toConsumableArray(
    entries.
    filter(function (entry) {return !entry.dirent.isDirectory();}).
    map(function (entry) {return entry.path;})));};for (var i = 0; i < srcPaths.length; i++) {_loop(i);

  }
  return files;
}

/**
   * Given a src pattern and list of supported extensions, return a list of files to process
   * with this rule.
   * @param {string} src - file, directory, or glob pattern of files to act on
   * @param {string[]} extensions - list of supported file extensions
   * @param {import('eslint').Rule.RuleContext} context - the eslint context object
   * @returns {string[] | { filename: string, ignored: boolean }[]} the list of files that this rule will evaluate.
   */
function listFilesToProcess(src, extensions, context) {
  // If the context object has the new session functions, then prefer those
  // Otherwise, fallback to using the deprecated `FileEnumerator` for legacy support.
  // https://github.com/eslint/eslint/issues/18087
  if (
  context.session &&
  context.session.isFileIgnored &&
  context.session.isDirectoryIgnored)
  {
    return listFilesWithModernApi(src, extensions, context.session);
  }

  // Fallback to og FileEnumerator
  var FileEnumerator = requireFileEnumerator();

  // If we got the FileEnumerator, then let's go with that
  if (FileEnumerator) {
    return listFilesUsingFileEnumerator(FileEnumerator, src, extensions);
  }
  // If not, then we can try even older versions of this capability (listFilesToProcess)
  return listFilesWithLegacyFunctions(src, extensions);
}

var EXPORT_DEFAULT_DECLARATION = 'ExportDefaultDeclaration';
var EXPORT_NAMED_DECLARATION = 'ExportNamedDeclaration';
var EXPORT_ALL_DECLARATION = 'ExportAllDeclaration';
var IMPORT_DECLARATION = 'ImportDeclaration';
var IMPORT_NAMESPACE_SPECIFIER = 'ImportNamespaceSpecifier';
var IMPORT_DEFAULT_SPECIFIER = 'ImportDefaultSpecifier';
var VARIABLE_DECLARATION = 'VariableDeclaration';
var FUNCTION_DECLARATION = 'FunctionDeclaration';
var CLASS_DECLARATION = 'ClassDeclaration';
var IDENTIFIER = 'Identifier';
var OBJECT_PATTERN = 'ObjectPattern';
var ARRAY_PATTERN = 'ArrayPattern';
var TS_INTERFACE_DECLARATION = 'TSInterfaceDeclaration';
var TS_TYPE_ALIAS_DECLARATION = 'TSTypeAliasDeclaration';
var TS_ENUM_DECLARATION = 'TSEnumDeclaration';
var DEFAULT = 'default';

function forEachDeclarationIdentifier(declaration, cb) {
  if (declaration) {
    var isTypeDeclaration = declaration.type === TS_INTERFACE_DECLARATION ||
    declaration.type === TS_TYPE_ALIAS_DECLARATION ||
    declaration.type === TS_ENUM_DECLARATION;

    if (
    declaration.type === FUNCTION_DECLARATION ||
    declaration.type === CLASS_DECLARATION ||
    isTypeDeclaration)
    {
      cb(declaration.id.name, isTypeDeclaration);
    } else if (declaration.type === VARIABLE_DECLARATION) {
      declaration.declarations.forEach(function (_ref2) {var id = _ref2.id;
        if (id.type === OBJECT_PATTERN) {
          (0, _patternCapture2['default'])(id, function (pattern) {
            if (pattern.type === IDENTIFIER) {
              cb(pattern.name, false);
            }
          });
        } else if (id.type === ARRAY_PATTERN) {
          id.elements.forEach(function (_ref3) {var name = _ref3.name;
            cb(name, false);
          });
        } else {
          cb(id.name, false);
        }
      });
    }
  }
}

/**
   * List of imports per file.
   *
   * Represented by a two-level Map to a Set of identifiers. The upper-level Map
   * keys are the paths to the modules containing the imports, while the
   * lower-level Map keys are the paths to the files which are being imported
   * from. Lastly, the Set of identifiers contains either names being imported
   * or a special AST node name listed above (e.g ImportDefaultSpecifier).
   *
   * For example, if we have a file named foo.js containing:
   *
   *   import { o2 } from './bar.js';
   *
   * Then we will have a structure that looks like:
   *
   *   Map { 'foo.js' => Map { 'bar.js' => Set { 'o2' } } }
   *
   * @type {Map<string, Map<string, Set<string>>>}
   */
var importList = new Map();

/**
                             * List of exports per file.
                             *
                             * Represented by a two-level Map to an object of metadata. The upper-level Map
                             * keys are the paths to the modules containing the exports, while the
                             * lower-level Map keys are the specific identifiers or special AST node names
                             * being exported. The leaf-level metadata object at the moment only contains a
                             * `whereUsed` property, which contains a Set of paths to modules that import
                             * the name.
                             *
                             * For example, if we have a file named bar.js containing the following exports:
                             *
                             *   const o2 = 'bar';
                             *   export { o2 };
                             *
                             * And a file named foo.js containing the following import:
                             *
                             *   import { o2 } from './bar.js';
                             *
                             * Then we will have a structure that looks like:
                             *
                             *   Map { 'bar.js' => Map { 'o2' => { whereUsed: Set { 'foo.js' } } } }
                             *
                             * @type {Map<string, Map<string, object>>}
                             */
var exportList = new Map();

var visitorKeyMap = new Map();

/** @type {Set<string>} */
var ignoredFiles = new Set();
var filesOutsideSrc = new Set();

var isNodeModule = function isNodeModule(path) {return (/\/(node_modules)\//.test(path));};

/**
                                                                                             * read all files matching the patterns in src and ignoreExports
                                                                                             *
                                                                                             * return all files matching src pattern, which are not matching the ignoreExports pattern
                                                                                             * @type {(src: string, ignoreExports: string, context: import('eslint').Rule.RuleContext) => Set<string>}
                                                                                             */
function resolveFiles(src, ignoreExports, context) {
  var extensions = Array.from((0, _ignore.getFileExtensions)(context.settings));

  var srcFileList = listFilesToProcess(src, extensions, context);

  // prepare list of ignored files
  var ignoredFilesList = listFilesToProcess(ignoreExports, extensions, context);

  // The modern api will return a list of file paths, rather than an object
  if (ignoredFilesList.length && typeof ignoredFilesList[0] === 'string') {
    ignoredFilesList.forEach(function (filename) {return ignoredFiles.add(filename);});
  } else {
    ignoredFilesList.forEach(function (_ref4) {var filename = _ref4.filename;return ignoredFiles.add(filename);});
  }

  // prepare list of source files, don't consider files from node_modules
  var resolvedFiles = srcFileList.length && typeof srcFileList[0] === 'string' ?
  srcFileList.filter(function (filePath) {return !isNodeModule(filePath);}) :
  (0, _arrayPrototype2['default'])(srcFileList, function (_ref5) {var filename = _ref5.filename;return isNodeModule(filename) ? [] : filename;});

  return new Set(resolvedFiles);
}

/**
   * parse all source files and build up 2 maps containing the existing imports and exports
   */
var prepareImportsAndExports = function prepareImportsAndExports(srcFiles, context) {
  var exportAll = new Map();
  srcFiles.forEach(function (file) {
    var exports = new Map();
    var imports = new Map();
    var currentExports = _builder2['default'].get(file, context);
    if (currentExports) {var

      dependencies =




      currentExports.dependencies,reexports = currentExports.reexports,localImportList = currentExports.imports,namespace = currentExports.namespace,visitorKeys = currentExports.visitorKeys;

      visitorKeyMap.set(file, visitorKeys);
      // dependencies === export * from
      var currentExportAll = new Set();
      dependencies.forEach(function (getDependency) {
        var dependency = getDependency();
        if (dependency === null) {
          return;
        }

        currentExportAll.add(dependency.path);
      });
      exportAll.set(file, currentExportAll);

      reexports.forEach(function (value, key) {
        if (key === DEFAULT) {
          exports.set(IMPORT_DEFAULT_SPECIFIER, { whereUsed: new Set() });
        } else {
          exports.set(key, { whereUsed: new Set() });
        }
        var reexport = value.getImport();
        if (!reexport) {
          return;
        }
        var localImport = imports.get(reexport.path);
        var currentValue = void 0;
        if (value.local === DEFAULT) {
          currentValue = IMPORT_DEFAULT_SPECIFIER;
        } else {
          currentValue = value.local;
        }
        if (typeof localImport !== 'undefined') {
          localImport = new Set([].concat(_toConsumableArray(localImport), [currentValue]));
        } else {
          localImport = new Set([currentValue]);
        }
        imports.set(reexport.path, localImport);
      });

      localImportList.forEach(function (value, key) {
        if (isNodeModule(key)) {
          return;
        }
        var localImport = imports.get(key) || new Set();
        value.declarations.forEach(function (_ref6) {var importedSpecifiers = _ref6.importedSpecifiers;
          importedSpecifiers.forEach(function (specifier) {
            localImport.add(specifier);
          });
        });
        imports.set(key, localImport);
      });
      importList.set(file, imports);

      // build up export list only, if file is not ignored
      if (ignoredFiles.has(file)) {
        return;
      }
      namespace.forEach(function (value, key) {
        if (key === DEFAULT) {
          exports.set(IMPORT_DEFAULT_SPECIFIER, { whereUsed: new Set() });
        } else {
          exports.set(key, { whereUsed: new Set() });
        }
      });
    }
    exports.set(EXPORT_ALL_DECLARATION, { whereUsed: new Set() });
    exports.set(IMPORT_NAMESPACE_SPECIFIER, { whereUsed: new Set() });
    exportList.set(file, exports);
  });
  exportAll.forEach(function (value, key) {
    value.forEach(function (val) {
      var currentExports = exportList.get(val);
      if (currentExports) {
        var currentExport = currentExports.get(EXPORT_ALL_DECLARATION);
        currentExport.whereUsed.add(key);
      }
    });
  });
};

/**
    * traverse through all imports and add the respective path to the whereUsed-list
    * of the corresponding export
    */
var determineUsage = function determineUsage() {
  importList.forEach(function (listValue, listKey) {
    listValue.forEach(function (value, key) {
      var exports = exportList.get(key);
      if (typeof exports !== 'undefined') {
        value.forEach(function (currentImport) {
          var specifier = void 0;
          if (currentImport === IMPORT_NAMESPACE_SPECIFIER) {
            specifier = IMPORT_NAMESPACE_SPECIFIER;
          } else if (currentImport === IMPORT_DEFAULT_SPECIFIER) {
            specifier = IMPORT_DEFAULT_SPECIFIER;
          } else {
            specifier = currentImport;
          }
          if (typeof specifier !== 'undefined') {
            var exportStatement = exports.get(specifier);
            if (typeof exportStatement !== 'undefined') {var
              whereUsed = exportStatement.whereUsed;
              whereUsed.add(listKey);
              exports.set(specifier, { whereUsed: whereUsed });
            }
          }
        });
      }
    });
  });
};

var getSrc = function getSrc(src) {
  if (src) {
    return src;
  }
  return [process.cwd()];
};

/**
    * prepare the lists of existing imports and exports - should only be executed once at
    * the start of a new eslint run
    */
/** @type {Set<string>} */
var srcFiles = void 0;
var lastPrepareKey = void 0;
var doPreparation = function doPreparation(src, ignoreExports, context) {
  var prepareKey = JSON.stringify({
    src: (src || []).sort(),
    ignoreExports: (ignoreExports || []).sort(),
    extensions: Array.from((0, _ignore.getFileExtensions)(context.settings)).sort() });

  if (prepareKey === lastPrepareKey) {
    return;
  }

  importList.clear();
  exportList.clear();
  ignoredFiles.clear();
  filesOutsideSrc.clear();

  srcFiles = resolveFiles(getSrc(src), ignoreExports, context);
  prepareImportsAndExports(srcFiles, context);
  determineUsage();
  lastPrepareKey = prepareKey;
};

var newNamespaceImportExists = function newNamespaceImportExists(specifiers) {return specifiers.some(function (_ref7) {var type = _ref7.type;return type === IMPORT_NAMESPACE_SPECIFIER;});};

var newDefaultImportExists = function newDefaultImportExists(specifiers) {return specifiers.some(function (_ref8) {var type = _ref8.type;return type === IMPORT_DEFAULT_SPECIFIER;});};

var fileIsInPkg = function fileIsInPkg(file) {var _readPkgUp =
  (0, _readPkgUp3['default'])({ cwd: file }),path = _readPkgUp.path,pkg = _readPkgUp.pkg;
  var basePath = (0, _path.dirname)(path);

  var checkPkgFieldString = function checkPkgFieldString(pkgField) {
    if ((0, _path.join)(basePath, pkgField) === file) {
      return true;
    }
  };

  var checkPkgFieldObject = function checkPkgFieldObject(pkgField) {
    var pkgFieldFiles = (0, _arrayPrototype2['default'])((0, _object2['default'])(pkgField), function (value) {return typeof value === 'boolean' ? [] : (0, _path.join)(basePath, value);});

    if ((0, _arrayIncludes2['default'])(pkgFieldFiles, file)) {
      return true;
    }
  };

  var checkPkgField = function checkPkgField(pkgField) {
    if (typeof pkgField === 'string') {
      return checkPkgFieldString(pkgField);
    }

    if ((typeof pkgField === 'undefined' ? 'undefined' : _typeof(pkgField)) === 'object') {
      return checkPkgFieldObject(pkgField);
    }
  };

  if (pkg['private'] === true) {
    return false;
  }

  if (pkg.bin) {
    if (checkPkgField(pkg.bin)) {
      return true;
    }
  }

  if (pkg.browser) {
    if (checkPkgField(pkg.browser)) {
      return true;
    }
  }

  if (pkg.main) {
    if (checkPkgFieldString(pkg.main)) {
      return true;
    }
  }

  return false;
};

module.exports = {
  meta: {
    type: 'suggestion',
    docs: {
      category: 'Helpful warnings',
      description: 'Forbid modules without exports, or exports without matching import in another module.',
      url: (0, _docsUrl2['default'])('no-unused-modules') },

    schema: [{
      properties: {
        src: {
          description: 'files/paths to be analyzed (only for unused exports)',
          type: 'array',
          uniqueItems: true,
          items: {
            type: 'string',
            minLength: 1 } },


        ignoreExports: {
          description: 'files/paths for which unused exports will not be reported (e.g module entry points)',
          type: 'array',
          uniqueItems: true,
          items: {
            type: 'string',
            minLength: 1 } },


        missingExports: {
          description: 'report modules without any exports',
          type: 'boolean' },

        unusedExports: {
          description: 'report exports without any usage',
          type: 'boolean' },

        ignoreUnusedTypeExports: {
          description: 'ignore type exports without any usage',
          type: 'boolean' } },


      anyOf: [
      {
        properties: {
          unusedExports: { 'enum': [true] },
          src: {
            minItems: 1 } },


        required: ['unusedExports'] },

      {
        properties: {
          missingExports: { 'enum': [true] } },

        required: ['missingExports'] }] }] },





  create: function () {function create(context) {var _ref9 =






      context.options[0] || {},src = _ref9.src,_ref9$ignoreExports = _ref9.ignoreExports,ignoreExports = _ref9$ignoreExports === undefined ? [] : _ref9$ignoreExports,missingExports = _ref9.missingExports,unusedExports = _ref9.unusedExports,ignoreUnusedTypeExports = _ref9.ignoreUnusedTypeExports;

      if (unusedExports) {
        doPreparation(src, ignoreExports, context);
      }

      var file = context.getPhysicalFilename ? context.getPhysicalFilename() : context.getFilename();

      var checkExportPresence = function () {function checkExportPresence(node) {
          if (!missingExports) {
            return;
          }

          if (ignoredFiles.has(file)) {
            return;
          }

          var exportCount = exportList.get(file);
          var exportAll = exportCount.get(EXPORT_ALL_DECLARATION);
          var namespaceImports = exportCount.get(IMPORT_NAMESPACE_SPECIFIER);

          exportCount['delete'](EXPORT_ALL_DECLARATION);
          exportCount['delete'](IMPORT_NAMESPACE_SPECIFIER);
          if (exportCount.size < 1) {
            // node.body[0] === 'undefined' only happens, if everything is commented out in the file
            // being linted
            context.report(node.body[0] ? node.body[0] : node, 'No exports found');
          }
          exportCount.set(EXPORT_ALL_DECLARATION, exportAll);
          exportCount.set(IMPORT_NAMESPACE_SPECIFIER, namespaceImports);
        }return checkExportPresence;}();

      var checkUsage = function () {function checkUsage(node, exportedValue, isTypeExport) {
          if (!unusedExports) {
            return;
          }

          if (isTypeExport && ignoreUnusedTypeExports) {
            return;
          }

          if (ignoredFiles.has(file)) {
            return;
          }

          if (fileIsInPkg(file)) {
            return;
          }

          if (filesOutsideSrc.has(file)) {
            return;
          }

          // make sure file to be linted is included in source files
          if (!srcFiles.has(file)) {
            srcFiles = resolveFiles(getSrc(src), ignoreExports, context);
            if (!srcFiles.has(file)) {
              filesOutsideSrc.add(file);
              return;
            }
          }

          exports = exportList.get(file);

          if (!exports) {
            console.error('file `' + String(file) + '` has no exports. Please update to the latest, and if it still happens, report this on https://github.com/import-js/eslint-plugin-import/issues/2866!');
          }

          // special case: export * from
          var exportAll = exports.get(EXPORT_ALL_DECLARATION);
          if (typeof exportAll !== 'undefined' && exportedValue !== IMPORT_DEFAULT_SPECIFIER) {
            if (exportAll.whereUsed.size > 0) {
              return;
            }
          }

          // special case: namespace import
          var namespaceImports = exports.get(IMPORT_NAMESPACE_SPECIFIER);
          if (typeof namespaceImports !== 'undefined') {
            if (namespaceImports.whereUsed.size > 0) {
              return;
            }
          }

          // exportsList will always map any imported value of 'default' to 'ImportDefaultSpecifier'
          var exportsKey = exportedValue === DEFAULT ? IMPORT_DEFAULT_SPECIFIER : exportedValue;

          var exportStatement = exports.get(exportsKey);

          var value = exportsKey === IMPORT_DEFAULT_SPECIFIER ? DEFAULT : exportsKey;

          if (typeof exportStatement !== 'undefined') {
            if (exportStatement.whereUsed.size < 1) {
              context.report(
              node, 'exported declaration \'' +
              value + '\' not used within other modules');

            }
          } else {
            context.report(
            node, 'exported declaration \'' +
            value + '\' not used within other modules');

          }
        }return checkUsage;}();

      /**
                                 * only useful for tools like vscode-eslint
                                 *
                                 * update lists of existing exports during runtime
                                 */
      var updateExportUsage = function () {function updateExportUsage(node) {
          if (ignoredFiles.has(file)) {
            return;
          }

          var exports = exportList.get(file);

          // new module has been created during runtime
          // include it in further processing
          if (typeof exports === 'undefined') {
            exports = new Map();
          }

          var newExports = new Map();
          var newExportIdentifiers = new Set();

          node.body.forEach(function (_ref10) {var type = _ref10.type,declaration = _ref10.declaration,specifiers = _ref10.specifiers;
            if (type === EXPORT_DEFAULT_DECLARATION) {
              newExportIdentifiers.add(IMPORT_DEFAULT_SPECIFIER);
            }
            if (type === EXPORT_NAMED_DECLARATION) {
              if (specifiers.length > 0) {
                specifiers.forEach(function (specifier) {
                  if (specifier.exported) {
                    newExportIdentifiers.add(specifier.exported.name || specifier.exported.value);
                  }
                });
              }
              forEachDeclarationIdentifier(declaration, function (name) {
                newExportIdentifiers.add(name);
              });
            }
          });

          // old exports exist within list of new exports identifiers: add to map of new exports
          exports.forEach(function (value, key) {
            if (newExportIdentifiers.has(key)) {
              newExports.set(key, value);
            }
          });

          // new export identifiers added: add to map of new exports
          newExportIdentifiers.forEach(function (key) {
            if (!exports.has(key)) {
              newExports.set(key, { whereUsed: new Set() });
            }
          });

          // preserve information about namespace imports
          var exportAll = exports.get(EXPORT_ALL_DECLARATION);
          var namespaceImports = exports.get(IMPORT_NAMESPACE_SPECIFIER);

          if (typeof namespaceImports === 'undefined') {
            namespaceImports = { whereUsed: new Set() };
          }

          newExports.set(EXPORT_ALL_DECLARATION, exportAll);
          newExports.set(IMPORT_NAMESPACE_SPECIFIER, namespaceImports);
          exportList.set(file, newExports);
        }return updateExportUsage;}();

      /**
                                        * only useful for tools like vscode-eslint
                                        *
                                        * update lists of existing imports during runtime
                                        */
      var updateImportUsage = function () {function updateImportUsage(node) {
          if (!unusedExports) {
            return;
          }

          var oldImportPaths = importList.get(file);
          if (typeof oldImportPaths === 'undefined') {
            oldImportPaths = new Map();
          }

          var oldNamespaceImports = new Set();
          var newNamespaceImports = new Set();

          var oldExportAll = new Set();
          var newExportAll = new Set();

          var oldDefaultImports = new Set();
          var newDefaultImports = new Set();

          var oldImports = new Map();
          var newImports = new Map();
          oldImportPaths.forEach(function (value, key) {
            if (value.has(EXPORT_ALL_DECLARATION)) {
              oldExportAll.add(key);
            }
            if (value.has(IMPORT_NAMESPACE_SPECIFIER)) {
              oldNamespaceImports.add(key);
            }
            if (value.has(IMPORT_DEFAULT_SPECIFIER)) {
              oldDefaultImports.add(key);
            }
            value.forEach(function (val) {
              if (
              val !== IMPORT_NAMESPACE_SPECIFIER &&
              val !== IMPORT_DEFAULT_SPECIFIER)
              {
                oldImports.set(val, key);
              }
            });
          });

          function processDynamicImport(source) {
            if (source.type !== 'Literal') {
              return null;
            }
            var p = (0, _resolve2['default'])(source.value, context);
            if (p == null) {
              return null;
            }
            newNamespaceImports.add(p);
          }

          (0, _visit2['default'])(node, visitorKeyMap.get(file), {
            ImportExpression: function () {function ImportExpression(child) {
                processDynamicImport(child.source);
              }return ImportExpression;}(),
            CallExpression: function () {function CallExpression(child) {
                if (child.callee.type === 'Import') {
                  processDynamicImport(child.arguments[0]);
                }
              }return CallExpression;}() });


          node.body.forEach(function (astNode) {
            var resolvedPath = void 0;

            // support for export { value } from 'module'
            if (astNode.type === EXPORT_NAMED_DECLARATION) {
              if (astNode.source) {
                resolvedPath = (0, _resolve2['default'])(astNode.source.raw.replace(/('|")/g, ''), context);
                astNode.specifiers.forEach(function (specifier) {
                  var name = specifier.local.name || specifier.local.value;
                  if (name === DEFAULT) {
                    newDefaultImports.add(resolvedPath);
                  } else {
                    newImports.set(name, resolvedPath);
                  }
                });
              }
            }

            if (astNode.type === EXPORT_ALL_DECLARATION) {
              resolvedPath = (0, _resolve2['default'])(astNode.source.raw.replace(/('|")/g, ''), context);
              newExportAll.add(resolvedPath);
            }

            if (astNode.type === IMPORT_DECLARATION) {
              resolvedPath = (0, _resolve2['default'])(astNode.source.raw.replace(/('|")/g, ''), context);
              if (!resolvedPath) {
                return;
              }

              if (isNodeModule(resolvedPath)) {
                return;
              }

              if (newNamespaceImportExists(astNode.specifiers)) {
                newNamespaceImports.add(resolvedPath);
              }

              if (newDefaultImportExists(astNode.specifiers)) {
                newDefaultImports.add(resolvedPath);
              }

              astNode.specifiers.
              filter(function (specifier) {return specifier.type !== IMPORT_DEFAULT_SPECIFIER && specifier.type !== IMPORT_NAMESPACE_SPECIFIER;}).
              forEach(function (specifier) {
                newImports.set(specifier.imported.name || specifier.imported.value, resolvedPath);
              });
            }
          });

          newExportAll.forEach(function (value) {
            if (!oldExportAll.has(value)) {
              var imports = oldImportPaths.get(value);
              if (typeof imports === 'undefined') {
                imports = new Set();
              }
              imports.add(EXPORT_ALL_DECLARATION);
              oldImportPaths.set(value, imports);

              var _exports = exportList.get(value);
              var currentExport = void 0;
              if (typeof _exports !== 'undefined') {
                currentExport = _exports.get(EXPORT_ALL_DECLARATION);
              } else {
                _exports = new Map();
                exportList.set(value, _exports);
              }

              if (typeof currentExport !== 'undefined') {
                currentExport.whereUsed.add(file);
              } else {
                var whereUsed = new Set();
                whereUsed.add(file);
                _exports.set(EXPORT_ALL_DECLARATION, { whereUsed: whereUsed });
              }
            }
          });

          oldExportAll.forEach(function (value) {
            if (!newExportAll.has(value)) {
              var imports = oldImportPaths.get(value);
              imports['delete'](EXPORT_ALL_DECLARATION);

              var _exports2 = exportList.get(value);
              if (typeof _exports2 !== 'undefined') {
                var currentExport = _exports2.get(EXPORT_ALL_DECLARATION);
                if (typeof currentExport !== 'undefined') {
                  currentExport.whereUsed['delete'](file);
                }
              }
            }
          });

          newDefaultImports.forEach(function (value) {
            if (!oldDefaultImports.has(value)) {
              var imports = oldImportPaths.get(value);
              if (typeof imports === 'undefined') {
                imports = new Set();
              }
              imports.add(IMPORT_DEFAULT_SPECIFIER);
              oldImportPaths.set(value, imports);

              var _exports3 = exportList.get(value);
              var currentExport = void 0;
              if (typeof _exports3 !== 'undefined') {
                currentExport = _exports3.get(IMPORT_DEFAULT_SPECIFIER);
              } else {
                _exports3 = new Map();
                exportList.set(value, _exports3);
              }

              if (typeof currentExport !== 'undefined') {
                currentExport.whereUsed.add(file);
              } else {
                var whereUsed = new Set();
                whereUsed.add(file);
                _exports3.set(IMPORT_DEFAULT_SPECIFIER, { whereUsed: whereUsed });
              }
            }
          });

          oldDefaultImports.forEach(function (value) {
            if (!newDefaultImports.has(value)) {
              var imports = oldImportPaths.get(value);
              imports['delete'](IMPORT_DEFAULT_SPECIFIER);

              var _exports4 = exportList.get(value);
              if (typeof _exports4 !== 'undefined') {
                var currentExport = _exports4.get(IMPORT_DEFAULT_SPECIFIER);
                if (typeof currentExport !== 'undefined') {
                  currentExport.whereUsed['delete'](file);
                }
              }
            }
          });

          newNamespaceImports.forEach(function (value) {
            if (!oldNamespaceImports.has(value)) {
              var imports = oldImportPaths.get(value);
              if (typeof imports === 'undefined') {
                imports = new Set();
              }
              imports.add(IMPORT_NAMESPACE_SPECIFIER);
              oldImportPaths.set(value, imports);

              var _exports5 = exportList.get(value);
              var currentExport = void 0;
              if (typeof _exports5 !== 'undefined') {
                currentExport = _exports5.get(IMPORT_NAMESPACE_SPECIFIER);
              } else {
                _exports5 = new Map();
                exportList.set(value, _exports5);
              }

              if (typeof currentExport !== 'undefined') {
                currentExport.whereUsed.add(file);
              } else {
                var whereUsed = new Set();
                whereUsed.add(file);
                _exports5.set(IMPORT_NAMESPACE_SPECIFIER, { whereUsed: whereUsed });
              }
            }
          });

          oldNamespaceImports.forEach(function (value) {
            if (!newNamespaceImports.has(value)) {
              var imports = oldImportPaths.get(value);
              imports['delete'](IMPORT_NAMESPACE_SPECIFIER);

              var _exports6 = exportList.get(value);
              if (typeof _exports6 !== 'undefined') {
                var currentExport = _exports6.get(IMPORT_NAMESPACE_SPECIFIER);
                if (typeof currentExport !== 'undefined') {
                  currentExport.whereUsed['delete'](file);
                }
              }
            }
          });

          newImports.forEach(function (value, key) {
            if (!oldImports.has(key)) {
              var imports = oldImportPaths.get(value);
              if (typeof imports === 'undefined') {
                imports = new Set();
              }
              imports.add(key);
              oldImportPaths.set(value, imports);

              var _exports7 = exportList.get(value);
              var currentExport = void 0;
              if (typeof _exports7 !== 'undefined') {
                currentExport = _exports7.get(key);
              } else {
                _exports7 = new Map();
                exportList.set(value, _exports7);
              }

              if (typeof currentExport !== 'undefined') {
                currentExport.whereUsed.add(file);
              } else {
                var whereUsed = new Set();
                whereUsed.add(file);
                _exports7.set(key, { whereUsed: whereUsed });
              }
            }
          });

          oldImports.forEach(function (value, key) {
            if (!newImports.has(key)) {
              var imports = oldImportPaths.get(value);
              imports['delete'](key);

              var _exports8 = exportList.get(value);
              if (typeof _exports8 !== 'undefined') {
                var currentExport = _exports8.get(key);
                if (typeof currentExport !== 'undefined') {
                  currentExport.whereUsed['delete'](file);
                }
              }
            }
          });
        }return updateImportUsage;}();

      return {
        'Program:exit': function () {function ProgramExit(node) {
            updateExportUsage(node);
            updateImportUsage(node);
            checkExportPresence(node);
          }return ProgramExit;}(),
        ExportDefaultDeclaration: function () {function ExportDefaultDeclaration(node) {
            checkUsage(node, IMPORT_DEFAULT_SPECIFIER, false);
          }return ExportDefaultDeclaration;}(),
        ExportNamedDeclaration: function () {function ExportNamedDeclaration(node) {
            node.specifiers.forEach(function (specifier) {
              checkUsage(specifier, specifier.exported.name || specifier.exported.value, false);
            });
            forEachDeclarationIdentifier(node.declaration, function (name, isTypeExport) {
              checkUsage(node, name, isTypeExport);
            });
          }return ExportNamedDeclaration;}() };

    }return create;}() };
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIi4uLy4uL3NyYy9ydWxlcy9uby11bnVzZWQtbW9kdWxlcy5qcyJdLCJuYW1lcyI6WyJyZXF1aXJlRmlsZUVudW1lcmF0b3IiLCJGaWxlRW51bWVyYXRvciIsInJlcXVpcmUiLCJlIiwiY29kZSIsImxpc3RGaWxlc1VzaW5nRmlsZUVudW1lcmF0b3IiLCJzcmMiLCJleHRlbnNpb25zIiwiQXJyYXkiLCJmcm9tIiwiaXRlcmF0ZUZpbGVzIiwiZmlsZVBhdGgiLCJpZ25vcmVkIiwiZmlsZW5hbWUiLCJsaXN0RmlsZXNXaXRoTGVnYWN5RnVuY3Rpb25zIiwib3JpZ2luYWxMaXN0RmlsZXNUb1Byb2Nlc3MiLCJsaXN0RmlsZXNUb1Byb2Nlc3MiLCJwYXR0ZXJucyIsImNvbmNhdCIsInBhdHRlcm4iLCJtYXAiLCJleHRlbnNpb24iLCJ0ZXN0IiwibGlzdEZpbGVzV2l0aE1vZGVybkFwaSIsInNyY1BhdGhzIiwic2Vzc2lvbiIsImZpbGVzIiwiaSIsImVudHJpZXMiLCJkZWVwRmlsdGVyIiwiZW50cnkiLCJmdWxsRW50cnlQYXRoIiwicGF0aCIsImlzRGlyZWN0b3J5SWdub3JlZCIsImVudHJ5RmlsdGVyIiwiaXNGaWxlSWdub3JlZCIsImZpbmQiLCJlbmRzV2l0aCIsInB1c2giLCJmaWx0ZXIiLCJkaXJlbnQiLCJpc0RpcmVjdG9yeSIsImxlbmd0aCIsImNvbnRleHQiLCJFWFBPUlRfREVGQVVMVF9ERUNMQVJBVElPTiIsIkVYUE9SVF9OQU1FRF9ERUNMQVJBVElPTiIsIkVYUE9SVF9BTExfREVDTEFSQVRJT04iLCJJTVBPUlRfREVDTEFSQVRJT04iLCJJTVBPUlRfTkFNRVNQQUNFX1NQRUNJRklFUiIsIklNUE9SVF9ERUZBVUxUX1NQRUNJRklFUiIsIlZBUklBQkxFX0RFQ0xBUkFUSU9OIiwiRlVOQ1RJT05fREVDTEFSQVRJT04iLCJDTEFTU19ERUNMQVJBVElPTiIsIklERU5USUZJRVIiLCJPQkpFQ1RfUEFUVEVSTiIsIkFSUkFZX1BBVFRFUk4iLCJUU19JTlRFUkZBQ0VfREVDTEFSQVRJT04iLCJUU19UWVBFX0FMSUFTX0RFQ0xBUkFUSU9OIiwiVFNfRU5VTV9ERUNMQVJBVElPTiIsIkRFRkFVTFQiLCJmb3JFYWNoRGVjbGFyYXRpb25JZGVudGlmaWVyIiwiZGVjbGFyYXRpb24iLCJjYiIsImlzVHlwZURlY2xhcmF0aW9uIiwidHlwZSIsImlkIiwibmFtZSIsImRlY2xhcmF0aW9ucyIsImZvckVhY2giLCJlbGVtZW50cyIsImltcG9ydExpc3QiLCJNYXAiLCJleHBvcnRMaXN0IiwidmlzaXRvcktleU1hcCIsImlnbm9yZWRGaWxlcyIsIlNldCIsImZpbGVzT3V0c2lkZVNyYyIsImlzTm9kZU1vZHVsZSIsInJlc29sdmVGaWxlcyIsImlnbm9yZUV4cG9ydHMiLCJzZXR0aW5ncyIsInNyY0ZpbGVMaXN0IiwiaWdub3JlZEZpbGVzTGlzdCIsImFkZCIsInJlc29sdmVkRmlsZXMiLCJwcmVwYXJlSW1wb3J0c0FuZEV4cG9ydHMiLCJzcmNGaWxlcyIsImV4cG9ydEFsbCIsImZpbGUiLCJleHBvcnRzIiwiaW1wb3J0cyIsImN1cnJlbnRFeHBvcnRzIiwiRXhwb3J0TWFwQnVpbGRlciIsImdldCIsImRlcGVuZGVuY2llcyIsInJlZXhwb3J0cyIsImxvY2FsSW1wb3J0TGlzdCIsIm5hbWVzcGFjZSIsInZpc2l0b3JLZXlzIiwic2V0IiwiY3VycmVudEV4cG9ydEFsbCIsImdldERlcGVuZGVuY3kiLCJkZXBlbmRlbmN5IiwidmFsdWUiLCJrZXkiLCJ3aGVyZVVzZWQiLCJyZWV4cG9ydCIsImdldEltcG9ydCIsImxvY2FsSW1wb3J0IiwiY3VycmVudFZhbHVlIiwibG9jYWwiLCJpbXBvcnRlZFNwZWNpZmllcnMiLCJzcGVjaWZpZXIiLCJoYXMiLCJ2YWwiLCJjdXJyZW50RXhwb3J0IiwiZGV0ZXJtaW5lVXNhZ2UiLCJsaXN0VmFsdWUiLCJsaXN0S2V5IiwiY3VycmVudEltcG9ydCIsImV4cG9ydFN0YXRlbWVudCIsImdldFNyYyIsInByb2Nlc3MiLCJjd2QiLCJsYXN0UHJlcGFyZUtleSIsImRvUHJlcGFyYXRpb24iLCJwcmVwYXJlS2V5IiwiSlNPTiIsInN0cmluZ2lmeSIsInNvcnQiLCJjbGVhciIsIm5ld05hbWVzcGFjZUltcG9ydEV4aXN0cyIsInNwZWNpZmllcnMiLCJzb21lIiwibmV3RGVmYXVsdEltcG9ydEV4aXN0cyIsImZpbGVJc0luUGtnIiwicGtnIiwiYmFzZVBhdGgiLCJjaGVja1BrZ0ZpZWxkU3RyaW5nIiwicGtnRmllbGQiLCJjaGVja1BrZ0ZpZWxkT2JqZWN0IiwicGtnRmllbGRGaWxlcyIsImNoZWNrUGtnRmllbGQiLCJiaW4iLCJicm93c2VyIiwibWFpbiIsIm1vZHVsZSIsIm1ldGEiLCJkb2NzIiwiY2F0ZWdvcnkiLCJkZXNjcmlwdGlvbiIsInVybCIsInNjaGVtYSIsInByb3BlcnRpZXMiLCJ1bmlxdWVJdGVtcyIsIml0ZW1zIiwibWluTGVuZ3RoIiwibWlzc2luZ0V4cG9ydHMiLCJ1bnVzZWRFeHBvcnRzIiwiaWdub3JlVW51c2VkVHlwZUV4cG9ydHMiLCJhbnlPZiIsIm1pbkl0ZW1zIiwicmVxdWlyZWQiLCJjcmVhdGUiLCJvcHRpb25zIiwiZ2V0UGh5c2ljYWxGaWxlbmFtZSIsImdldEZpbGVuYW1lIiwiY2hlY2tFeHBvcnRQcmVzZW5jZSIsIm5vZGUiLCJleHBvcnRDb3VudCIsIm5hbWVzcGFjZUltcG9ydHMiLCJzaXplIiwicmVwb3J0IiwiYm9keSIsImNoZWNrVXNhZ2UiLCJleHBvcnRlZFZhbHVlIiwiaXNUeXBlRXhwb3J0IiwiY29uc29sZSIsImVycm9yIiwiZXhwb3J0c0tleSIsInVwZGF0ZUV4cG9ydFVzYWdlIiwibmV3RXhwb3J0cyIsIm5ld0V4cG9ydElkZW50aWZpZXJzIiwiZXhwb3J0ZWQiLCJ1cGRhdGVJbXBvcnRVc2FnZSIsIm9sZEltcG9ydFBhdGhzIiwib2xkTmFtZXNwYWNlSW1wb3J0cyIsIm5ld05hbWVzcGFjZUltcG9ydHMiLCJvbGRFeHBvcnRBbGwiLCJuZXdFeHBvcnRBbGwiLCJvbGREZWZhdWx0SW1wb3J0cyIsIm5ld0RlZmF1bHRJbXBvcnRzIiwib2xkSW1wb3J0cyIsIm5ld0ltcG9ydHMiLCJwcm9jZXNzRHluYW1pY0ltcG9ydCIsInNvdXJjZSIsInAiLCJJbXBvcnRFeHByZXNzaW9uIiwiY2hpbGQiLCJDYWxsRXhwcmVzc2lvbiIsImNhbGxlZSIsImFyZ3VtZW50cyIsImFzdE5vZGUiLCJyZXNvbHZlZFBhdGgiLCJyYXciLCJyZXBsYWNlIiwiaW1wb3J0ZWQiLCJFeHBvcnREZWZhdWx0RGVjbGFyYXRpb24iLCJFeHBvcnROYW1lZERlY2xhcmF0aW9uIl0sIm1hcHBpbmdzIjoiOzs7Ozs7QUFNQTtBQUNBLHNEO0FBQ0Esa0Q7QUFDQTtBQUNBLDJEO0FBQ0EsdUM7QUFDQSwrQztBQUNBLHlEOztBQUVBO0FBQ0EsK0M7QUFDQSw2RDtBQUNBLHFDLDJVQWxCQTs7OztvWEFvQkE7Ozs7O3VYQU1BLFNBQVNBLHFCQUFULEdBQWlDLENBQy9CLElBQUlDLHVCQUFKOztBQUVBO0FBQ0EsTUFBSTtBQUNvQkMsWUFBUSw2QkFBUixDQURwQixDQUNDRCxjQURELFlBQ0NBLGNBREQ7QUFFSCxHQUZELENBRUUsT0FBT0UsQ0FBUCxFQUFVO0FBQ1Y7QUFDQSxRQUFJQSxFQUFFQyxJQUFGLEtBQVcsa0JBQWYsRUFBbUM7QUFDakMsWUFBTUQsQ0FBTjtBQUNEOztBQUVEO0FBQ0EsUUFBSTtBQUNvQkQsY0FBUSx1Q0FBUixDQURwQixDQUNDRCxjQURELGFBQ0NBLGNBREQ7QUFFSCxLQUZELENBRUUsT0FBT0UsQ0FBUCxFQUFVO0FBQ1Y7QUFDQSxVQUFJQSxFQUFFQyxJQUFGLEtBQVcsa0JBQWYsRUFBbUM7QUFDakMsY0FBTUQsQ0FBTjtBQUNEO0FBQ0Y7QUFDRjtBQUNELFNBQU9GLGNBQVA7QUFDRDs7QUFFRDs7Ozs7OztBQU9BLFNBQVNJLDRCQUFULENBQXNDSixjQUF0QyxFQUFzREssR0FBdEQsRUFBMkRDLFVBQTNELEVBQXVFO0FBQ3JFLE1BQU1KLElBQUksSUFBSUYsY0FBSixDQUFtQjtBQUMzQk0sMEJBRDJCLEVBQW5CLENBQVY7OztBQUlBLFNBQU9DLE1BQU1DLElBQU47QUFDTE4sSUFBRU8sWUFBRixDQUFlSixHQUFmLENBREs7QUFFTCx1QkFBR0ssUUFBSCxRQUFHQSxRQUFILENBQWFDLE9BQWIsUUFBYUEsT0FBYixRQUE0QixFQUFFQyxVQUFVRixRQUFaLEVBQXNCQyxnQkFBdEIsRUFBNUIsRUFGSyxDQUFQOztBQUlEOztBQUVEOzs7Ozs7O0FBT0EsU0FBU0UsNEJBQVQsQ0FBc0NSLEdBQXRDLEVBQTJDQyxVQUEzQyxFQUF1RDtBQUNyRCxNQUFJO0FBQ0Y7QUFERSxvQkFFeURMLFFBQVEsNEJBQVIsQ0FGekQsQ0FFMEJhLDBCQUYxQixhQUVNQyxrQkFGTjtBQUdGO0FBQ0E7QUFDQTs7QUFFQSxXQUFPRCwyQkFBMkJULEdBQTNCLEVBQWdDO0FBQ3JDQyw0QkFEcUMsRUFBaEMsQ0FBUDs7QUFHRCxHQVZELENBVUUsT0FBT0osQ0FBUCxFQUFVO0FBQ1Y7QUFDQSxRQUFJQSxFQUFFQyxJQUFGLEtBQVcsa0JBQWYsRUFBbUM7QUFDakMsWUFBTUQsQ0FBTjtBQUNEOztBQUVEO0FBTlU7O0FBU05ELFlBQVEsMkJBQVIsQ0FUTSxDQVFZYSwyQkFSWixhQVFSQyxrQkFSUTtBQVVWLFFBQU1DLFdBQVdYLElBQUlZLE1BQUo7QUFDZjtBQUNFWixPQURGO0FBRUUsY0FBQ2EsT0FBRCxVQUFhWixXQUFXYSxHQUFYLENBQWUsVUFBQ0MsU0FBRCxVQUFnQixZQUFELENBQWNDLElBQWQsQ0FBbUJILE9BQW5CLElBQThCQSxPQUE5QixVQUEyQ0EsT0FBM0MscUJBQTBERSxTQUExRCxDQUFmLEdBQWYsQ0FBYixFQUZGLENBRGUsQ0FBakI7Ozs7QUFPQSxXQUFPTiw0QkFBMkJFLFFBQTNCLENBQVA7QUFDRDtBQUNGOztBQUVEOzs7Ozs7OztBQVFBLFNBQVNNLHNCQUFULENBQWdDQyxRQUFoQyxFQUEwQ2pCLFVBQTFDLEVBQXNEa0IsT0FBdEQsRUFBK0Q7QUFDN0Q7QUFDQSxNQUFNQyxRQUFRLEVBQWQsQ0FGNkQ7O0FBSXBEQyxHQUpvRDtBQUszRCxRQUFNckIsTUFBTWtCLFNBQVNHLENBQVQsQ0FBWjtBQUNBO0FBQ0EsUUFBTUMsVUFBVSxzQkFBU3RCLEdBQVQsRUFBYztBQUM1QnVCLGdCQUQ0QixtQ0FDakJDLEtBRGlCLEVBQ1Y7QUFDaEIsY0FBTUMsZ0JBQWdCLG1CQUFZekIsR0FBWixFQUFpQndCLE1BQU1FLElBQXZCLENBQXRCOztBQUVBO0FBQ0EsaUJBQU8sQ0FBQ1AsUUFBUVEsa0JBQVIsQ0FBMkJGLGFBQTNCLENBQVI7QUFDRCxTQU4yQjtBQU81QkcsaUJBUDRCLG9DQU9oQkosS0FQZ0IsRUFPVDtBQUNqQixjQUFNQyxnQkFBZ0IsbUJBQVl6QixHQUFaLEVBQWlCd0IsTUFBTUUsSUFBdkIsQ0FBdEI7O0FBRUE7QUFDQTtBQUNFLGFBQUNQLFFBQVFVLGFBQVIsQ0FBc0JKLGFBQXRCLENBQUQ7QUFDR3hCLHVCQUFXNkIsSUFBWCxDQUFnQixVQUFDZixTQUFELFVBQWVTLE1BQU1FLElBQU4sQ0FBV0ssUUFBWCxDQUFvQmhCLFNBQXBCLENBQWYsRUFBaEIsQ0FGTDs7QUFJRCxTQWYyQix3QkFBZCxDQUFoQjs7O0FBa0JBO0FBQ0FLLFVBQU1ZLElBQU47QUFDS1Y7QUFDQVcsVUFEQSxDQUNPLFVBQUNULEtBQUQsVUFBVyxDQUFDQSxNQUFNVSxNQUFOLENBQWFDLFdBQWIsRUFBWixFQURQO0FBRUFyQixPQUZBLENBRUksVUFBQ1UsS0FBRCxVQUFXQSxNQUFNRSxJQUFqQixFQUZKLENBREwsR0ExQjJELEVBSTdELEtBQUssSUFBSUwsSUFBSSxDQUFiLEVBQWdCQSxJQUFJSCxTQUFTa0IsTUFBN0IsRUFBcUNmLEdBQXJDLEVBQTBDLE9BQWpDQSxDQUFpQzs7QUEyQnpDO0FBQ0QsU0FBT0QsS0FBUDtBQUNEOztBQUVEOzs7Ozs7OztBQVFBLFNBQVNWLGtCQUFULENBQTRCVixHQUE1QixFQUFpQ0MsVUFBakMsRUFBNkNvQyxPQUE3QyxFQUFzRDtBQUNwRDtBQUNBO0FBQ0E7QUFDQTtBQUNFQSxVQUFRbEIsT0FBUjtBQUNHa0IsVUFBUWxCLE9BQVIsQ0FBZ0JVLGFBRG5CO0FBRUdRLFVBQVFsQixPQUFSLENBQWdCUSxrQkFIckI7QUFJRTtBQUNBLFdBQU9WLHVCQUF1QmpCLEdBQXZCLEVBQTRCQyxVQUE1QixFQUF3Q29DLFFBQVFsQixPQUFoRCxDQUFQO0FBQ0Q7O0FBRUQ7QUFDQSxNQUFNeEIsaUJBQWlCRCx1QkFBdkI7O0FBRUE7QUFDQSxNQUFJQyxjQUFKLEVBQW9CO0FBQ2xCLFdBQU9JLDZCQUE2QkosY0FBN0IsRUFBNkNLLEdBQTdDLEVBQWtEQyxVQUFsRCxDQUFQO0FBQ0Q7QUFDRDtBQUNBLFNBQU9PLDZCQUE2QlIsR0FBN0IsRUFBa0NDLFVBQWxDLENBQVA7QUFDRDs7QUFFRCxJQUFNcUMsNkJBQTZCLDBCQUFuQztBQUNBLElBQU1DLDJCQUEyQix3QkFBakM7QUFDQSxJQUFNQyx5QkFBeUIsc0JBQS9CO0FBQ0EsSUFBTUMscUJBQXFCLG1CQUEzQjtBQUNBLElBQU1DLDZCQUE2QiwwQkFBbkM7QUFDQSxJQUFNQywyQkFBMkIsd0JBQWpDO0FBQ0EsSUFBTUMsdUJBQXVCLHFCQUE3QjtBQUNBLElBQU1DLHVCQUF1QixxQkFBN0I7QUFDQSxJQUFNQyxvQkFBb0Isa0JBQTFCO0FBQ0EsSUFBTUMsYUFBYSxZQUFuQjtBQUNBLElBQU1DLGlCQUFpQixlQUF2QjtBQUNBLElBQU1DLGdCQUFnQixjQUF0QjtBQUNBLElBQU1DLDJCQUEyQix3QkFBakM7QUFDQSxJQUFNQyw0QkFBNEIsd0JBQWxDO0FBQ0EsSUFBTUMsc0JBQXNCLG1CQUE1QjtBQUNBLElBQU1DLFVBQVUsU0FBaEI7O0FBRUEsU0FBU0MsNEJBQVQsQ0FBc0NDLFdBQXRDLEVBQW1EQyxFQUFuRCxFQUF1RDtBQUNyRCxNQUFJRCxXQUFKLEVBQWlCO0FBQ2YsUUFBTUUsb0JBQW9CRixZQUFZRyxJQUFaLEtBQXFCUix3QkFBckI7QUFDckJLLGdCQUFZRyxJQUFaLEtBQXFCUCx5QkFEQTtBQUVyQkksZ0JBQVlHLElBQVosS0FBcUJOLG1CQUYxQjs7QUFJQTtBQUNFRyxnQkFBWUcsSUFBWixLQUFxQmIsb0JBQXJCO0FBQ0dVLGdCQUFZRyxJQUFaLEtBQXFCWixpQkFEeEI7QUFFR1cscUJBSEw7QUFJRTtBQUNBRCxTQUFHRCxZQUFZSSxFQUFaLENBQWVDLElBQWxCLEVBQXdCSCxpQkFBeEI7QUFDRCxLQU5ELE1BTU8sSUFBSUYsWUFBWUcsSUFBWixLQUFxQmQsb0JBQXpCLEVBQStDO0FBQ3BEVyxrQkFBWU0sWUFBWixDQUF5QkMsT0FBekIsQ0FBaUMsaUJBQVksS0FBVEgsRUFBUyxTQUFUQSxFQUFTO0FBQzNDLFlBQUlBLEdBQUdELElBQUgsS0FBWVYsY0FBaEIsRUFBZ0M7QUFDOUIsMkNBQXdCVyxFQUF4QixFQUE0QixVQUFDOUMsT0FBRCxFQUFhO0FBQ3ZDLGdCQUFJQSxRQUFRNkMsSUFBUixLQUFpQlgsVUFBckIsRUFBaUM7QUFDL0JTLGlCQUFHM0MsUUFBUStDLElBQVgsRUFBaUIsS0FBakI7QUFDRDtBQUNGLFdBSkQ7QUFLRCxTQU5ELE1BTU8sSUFBSUQsR0FBR0QsSUFBSCxLQUFZVCxhQUFoQixFQUErQjtBQUNwQ1UsYUFBR0ksUUFBSCxDQUFZRCxPQUFaLENBQW9CLGlCQUFjLEtBQVhGLElBQVcsU0FBWEEsSUFBVztBQUNoQ0osZUFBR0ksSUFBSCxFQUFTLEtBQVQ7QUFDRCxXQUZEO0FBR0QsU0FKTSxNQUlBO0FBQ0xKLGFBQUdHLEdBQUdDLElBQU4sRUFBWSxLQUFaO0FBQ0Q7QUFDRixPQWREO0FBZUQ7QUFDRjtBQUNGOztBQUVEOzs7Ozs7Ozs7Ozs7Ozs7Ozs7O0FBbUJBLElBQU1JLGFBQWEsSUFBSUMsR0FBSixFQUFuQjs7QUFFQTs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7OztBQXlCQSxJQUFNQyxhQUFhLElBQUlELEdBQUosRUFBbkI7O0FBRUEsSUFBTUUsZ0JBQWdCLElBQUlGLEdBQUosRUFBdEI7O0FBRUE7QUFDQSxJQUFNRyxlQUFlLElBQUlDLEdBQUosRUFBckI7QUFDQSxJQUFNQyxrQkFBa0IsSUFBSUQsR0FBSixFQUF4Qjs7QUFFQSxJQUFNRSxlQUFlLFNBQWZBLFlBQWUsQ0FBQzdDLElBQUQsVUFBVyxxQkFBRCxDQUF1QlYsSUFBdkIsQ0FBNEJVLElBQTVCLENBQVYsR0FBckI7O0FBRUE7Ozs7OztBQU1BLFNBQVM4QyxZQUFULENBQXNCeEUsR0FBdEIsRUFBMkJ5RSxhQUEzQixFQUEwQ3BDLE9BQTFDLEVBQW1EO0FBQ2pELE1BQU1wQyxhQUFhQyxNQUFNQyxJQUFOLENBQVcsK0JBQWtCa0MsUUFBUXFDLFFBQTFCLENBQVgsQ0FBbkI7O0FBRUEsTUFBTUMsY0FBY2pFLG1CQUFtQlYsR0FBbkIsRUFBd0JDLFVBQXhCLEVBQW9Db0MsT0FBcEMsQ0FBcEI7O0FBRUE7QUFDQSxNQUFNdUMsbUJBQW1CbEUsbUJBQW1CK0QsYUFBbkIsRUFBa0N4RSxVQUFsQyxFQUE4Q29DLE9BQTlDLENBQXpCOztBQUVBO0FBQ0EsTUFBSXVDLGlCQUFpQnhDLE1BQWpCLElBQTJCLE9BQU93QyxpQkFBaUIsQ0FBakIsQ0FBUCxLQUErQixRQUE5RCxFQUF3RTtBQUN0RUEscUJBQWlCZCxPQUFqQixDQUF5QixVQUFDdkQsUUFBRCxVQUFjNkQsYUFBYVMsR0FBYixDQUFpQnRFLFFBQWpCLENBQWQsRUFBekI7QUFDRCxHQUZELE1BRU87QUFDTHFFLHFCQUFpQmQsT0FBakIsQ0FBeUIsc0JBQUd2RCxRQUFILFNBQUdBLFFBQUgsUUFBa0I2RCxhQUFhUyxHQUFiLENBQWlCdEUsUUFBakIsQ0FBbEIsRUFBekI7QUFDRDs7QUFFRDtBQUNBLE1BQU11RSxnQkFBZ0JILFlBQVl2QyxNQUFaLElBQXNCLE9BQU91QyxZQUFZLENBQVosQ0FBUCxLQUEwQixRQUFoRDtBQUNsQkEsY0FBWTFDLE1BQVosQ0FBbUIsVUFBQzVCLFFBQUQsVUFBYyxDQUFDa0UsYUFBYWxFLFFBQWIsQ0FBZixFQUFuQixDQURrQjtBQUVsQixtQ0FBUXNFLFdBQVIsRUFBcUIsc0JBQUdwRSxRQUFILFNBQUdBLFFBQUgsUUFBa0JnRSxhQUFhaEUsUUFBYixJQUF5QixFQUF6QixHQUE4QkEsUUFBaEQsRUFBckIsQ0FGSjs7QUFJQSxTQUFPLElBQUk4RCxHQUFKLENBQVFTLGFBQVIsQ0FBUDtBQUNEOztBQUVEOzs7QUFHQSxJQUFNQywyQkFBMkIsU0FBM0JBLHdCQUEyQixDQUFDQyxRQUFELEVBQVczQyxPQUFYLEVBQXVCO0FBQ3RELE1BQU00QyxZQUFZLElBQUloQixHQUFKLEVBQWxCO0FBQ0FlLFdBQVNsQixPQUFULENBQWlCLFVBQUNvQixJQUFELEVBQVU7QUFDekIsUUFBTUMsVUFBVSxJQUFJbEIsR0FBSixFQUFoQjtBQUNBLFFBQU1tQixVQUFVLElBQUluQixHQUFKLEVBQWhCO0FBQ0EsUUFBTW9CLGlCQUFpQkMscUJBQWlCQyxHQUFqQixDQUFxQkwsSUFBckIsRUFBMkI3QyxPQUEzQixDQUF2QjtBQUNBLFFBQUlnRCxjQUFKLEVBQW9COztBQUVoQkcsa0JBRmdCOzs7OztBQU9kSCxvQkFQYyxDQUVoQkcsWUFGZ0IsQ0FHaEJDLFNBSGdCLEdBT2RKLGNBUGMsQ0FHaEJJLFNBSGdCLENBSVBDLGVBSk8sR0FPZEwsY0FQYyxDQUloQkQsT0FKZ0IsQ0FLaEJPLFNBTGdCLEdBT2ROLGNBUGMsQ0FLaEJNLFNBTGdCLENBTWhCQyxXQU5nQixHQU9kUCxjQVBjLENBTWhCTyxXQU5nQjs7QUFTbEJ6QixvQkFBYzBCLEdBQWQsQ0FBa0JYLElBQWxCLEVBQXdCVSxXQUF4QjtBQUNBO0FBQ0EsVUFBTUUsbUJBQW1CLElBQUl6QixHQUFKLEVBQXpCO0FBQ0FtQixtQkFBYTFCLE9BQWIsQ0FBcUIsVUFBQ2lDLGFBQUQsRUFBbUI7QUFDdEMsWUFBTUMsYUFBYUQsZUFBbkI7QUFDQSxZQUFJQyxlQUFlLElBQW5CLEVBQXlCO0FBQ3ZCO0FBQ0Q7O0FBRURGLHlCQUFpQmpCLEdBQWpCLENBQXFCbUIsV0FBV3RFLElBQWhDO0FBQ0QsT0FQRDtBQVFBdUQsZ0JBQVVZLEdBQVYsQ0FBY1gsSUFBZCxFQUFvQlksZ0JBQXBCOztBQUVBTCxnQkFBVTNCLE9BQVYsQ0FBa0IsVUFBQ21DLEtBQUQsRUFBUUMsR0FBUixFQUFnQjtBQUNoQyxZQUFJQSxRQUFRN0MsT0FBWixFQUFxQjtBQUNuQjhCLGtCQUFRVSxHQUFSLENBQVlsRCx3QkFBWixFQUFzQyxFQUFFd0QsV0FBVyxJQUFJOUIsR0FBSixFQUFiLEVBQXRDO0FBQ0QsU0FGRCxNQUVPO0FBQ0xjLGtCQUFRVSxHQUFSLENBQVlLLEdBQVosRUFBaUIsRUFBRUMsV0FBVyxJQUFJOUIsR0FBSixFQUFiLEVBQWpCO0FBQ0Q7QUFDRCxZQUFNK0IsV0FBV0gsTUFBTUksU0FBTixFQUFqQjtBQUNBLFlBQUksQ0FBQ0QsUUFBTCxFQUFlO0FBQ2I7QUFDRDtBQUNELFlBQUlFLGNBQWNsQixRQUFRRyxHQUFSLENBQVlhLFNBQVMxRSxJQUFyQixDQUFsQjtBQUNBLFlBQUk2RSxxQkFBSjtBQUNBLFlBQUlOLE1BQU1PLEtBQU4sS0FBZ0JuRCxPQUFwQixFQUE2QjtBQUMzQmtELHlCQUFlNUQsd0JBQWY7QUFDRCxTQUZELE1BRU87QUFDTDRELHlCQUFlTixNQUFNTyxLQUFyQjtBQUNEO0FBQ0QsWUFBSSxPQUFPRixXQUFQLEtBQXVCLFdBQTNCLEVBQXdDO0FBQ3RDQSx3QkFBYyxJQUFJakMsR0FBSiw4QkFBWWlDLFdBQVosSUFBeUJDLFlBQXpCLEdBQWQ7QUFDRCxTQUZELE1BRU87QUFDTEQsd0JBQWMsSUFBSWpDLEdBQUosQ0FBUSxDQUFDa0MsWUFBRCxDQUFSLENBQWQ7QUFDRDtBQUNEbkIsZ0JBQVFTLEdBQVIsQ0FBWU8sU0FBUzFFLElBQXJCLEVBQTJCNEUsV0FBM0I7QUFDRCxPQXZCRDs7QUF5QkFaLHNCQUFnQjVCLE9BQWhCLENBQXdCLFVBQUNtQyxLQUFELEVBQVFDLEdBQVIsRUFBZ0I7QUFDdEMsWUFBSTNCLGFBQWEyQixHQUFiLENBQUosRUFBdUI7QUFDckI7QUFDRDtBQUNELFlBQU1JLGNBQWNsQixRQUFRRyxHQUFSLENBQVlXLEdBQVosS0FBb0IsSUFBSTdCLEdBQUosRUFBeEM7QUFDQTRCLGNBQU1wQyxZQUFOLENBQW1CQyxPQUFuQixDQUEyQixpQkFBNEIsS0FBekIyQyxrQkFBeUIsU0FBekJBLGtCQUF5QjtBQUNyREEsNkJBQW1CM0MsT0FBbkIsQ0FBMkIsVUFBQzRDLFNBQUQsRUFBZTtBQUN4Q0osd0JBQVl6QixHQUFaLENBQWdCNkIsU0FBaEI7QUFDRCxXQUZEO0FBR0QsU0FKRDtBQUtBdEIsZ0JBQVFTLEdBQVIsQ0FBWUssR0FBWixFQUFpQkksV0FBakI7QUFDRCxPQVhEO0FBWUF0QyxpQkFBVzZCLEdBQVgsQ0FBZVgsSUFBZixFQUFxQkUsT0FBckI7O0FBRUE7QUFDQSxVQUFJaEIsYUFBYXVDLEdBQWIsQ0FBaUJ6QixJQUFqQixDQUFKLEVBQTRCO0FBQzFCO0FBQ0Q7QUFDRFMsZ0JBQVU3QixPQUFWLENBQWtCLFVBQUNtQyxLQUFELEVBQVFDLEdBQVIsRUFBZ0I7QUFDaEMsWUFBSUEsUUFBUTdDLE9BQVosRUFBcUI7QUFDbkI4QixrQkFBUVUsR0FBUixDQUFZbEQsd0JBQVosRUFBc0MsRUFBRXdELFdBQVcsSUFBSTlCLEdBQUosRUFBYixFQUF0QztBQUNELFNBRkQsTUFFTztBQUNMYyxrQkFBUVUsR0FBUixDQUFZSyxHQUFaLEVBQWlCLEVBQUVDLFdBQVcsSUFBSTlCLEdBQUosRUFBYixFQUFqQjtBQUNEO0FBQ0YsT0FORDtBQU9EO0FBQ0RjLFlBQVFVLEdBQVIsQ0FBWXJELHNCQUFaLEVBQW9DLEVBQUUyRCxXQUFXLElBQUk5QixHQUFKLEVBQWIsRUFBcEM7QUFDQWMsWUFBUVUsR0FBUixDQUFZbkQsMEJBQVosRUFBd0MsRUFBRXlELFdBQVcsSUFBSTlCLEdBQUosRUFBYixFQUF4QztBQUNBSCxlQUFXMkIsR0FBWCxDQUFlWCxJQUFmLEVBQXFCQyxPQUFyQjtBQUNELEdBaEZEO0FBaUZBRixZQUFVbkIsT0FBVixDQUFrQixVQUFDbUMsS0FBRCxFQUFRQyxHQUFSLEVBQWdCO0FBQ2hDRCxVQUFNbkMsT0FBTixDQUFjLFVBQUM4QyxHQUFELEVBQVM7QUFDckIsVUFBTXZCLGlCQUFpQm5CLFdBQVdxQixHQUFYLENBQWVxQixHQUFmLENBQXZCO0FBQ0EsVUFBSXZCLGNBQUosRUFBb0I7QUFDbEIsWUFBTXdCLGdCQUFnQnhCLGVBQWVFLEdBQWYsQ0FBbUIvQyxzQkFBbkIsQ0FBdEI7QUFDQXFFLHNCQUFjVixTQUFkLENBQXdCdEIsR0FBeEIsQ0FBNEJxQixHQUE1QjtBQUNEO0FBQ0YsS0FORDtBQU9ELEdBUkQ7QUFTRCxDQTVGRDs7QUE4RkE7Ozs7QUFJQSxJQUFNWSxpQkFBaUIsU0FBakJBLGNBQWlCLEdBQU07QUFDM0I5QyxhQUFXRixPQUFYLENBQW1CLFVBQUNpRCxTQUFELEVBQVlDLE9BQVosRUFBd0I7QUFDekNELGNBQVVqRCxPQUFWLENBQWtCLFVBQUNtQyxLQUFELEVBQVFDLEdBQVIsRUFBZ0I7QUFDaEMsVUFBTWYsVUFBVWpCLFdBQVdxQixHQUFYLENBQWVXLEdBQWYsQ0FBaEI7QUFDQSxVQUFJLE9BQU9mLE9BQVAsS0FBbUIsV0FBdkIsRUFBb0M7QUFDbENjLGNBQU1uQyxPQUFOLENBQWMsVUFBQ21ELGFBQUQsRUFBbUI7QUFDL0IsY0FBSVAsa0JBQUo7QUFDQSxjQUFJTyxrQkFBa0J2RSwwQkFBdEIsRUFBa0Q7QUFDaERnRSx3QkFBWWhFLDBCQUFaO0FBQ0QsV0FGRCxNQUVPLElBQUl1RSxrQkFBa0J0RSx3QkFBdEIsRUFBZ0Q7QUFDckQrRCx3QkFBWS9ELHdCQUFaO0FBQ0QsV0FGTSxNQUVBO0FBQ0wrRCx3QkFBWU8sYUFBWjtBQUNEO0FBQ0QsY0FBSSxPQUFPUCxTQUFQLEtBQXFCLFdBQXpCLEVBQXNDO0FBQ3BDLGdCQUFNUSxrQkFBa0IvQixRQUFRSSxHQUFSLENBQVltQixTQUFaLENBQXhCO0FBQ0EsZ0JBQUksT0FBT1EsZUFBUCxLQUEyQixXQUEvQixFQUE0QztBQUNsQ2YsdUJBRGtDLEdBQ3BCZSxlQURvQixDQUNsQ2YsU0FEa0M7QUFFMUNBLHdCQUFVdEIsR0FBVixDQUFjbUMsT0FBZDtBQUNBN0Isc0JBQVFVLEdBQVIsQ0FBWWEsU0FBWixFQUF1QixFQUFFUCxvQkFBRixFQUF2QjtBQUNEO0FBQ0Y7QUFDRixTQWpCRDtBQWtCRDtBQUNGLEtBdEJEO0FBdUJELEdBeEJEO0FBeUJELENBMUJEOztBQTRCQSxJQUFNZ0IsU0FBUyxTQUFUQSxNQUFTLENBQUNuSCxHQUFELEVBQVM7QUFDdEIsTUFBSUEsR0FBSixFQUFTO0FBQ1AsV0FBT0EsR0FBUDtBQUNEO0FBQ0QsU0FBTyxDQUFDb0gsUUFBUUMsR0FBUixFQUFELENBQVA7QUFDRCxDQUxEOztBQU9BOzs7O0FBSUE7QUFDQSxJQUFJckMsaUJBQUo7QUFDQSxJQUFJc0MsdUJBQUo7QUFDQSxJQUFNQyxnQkFBZ0IsU0FBaEJBLGFBQWdCLENBQUN2SCxHQUFELEVBQU15RSxhQUFOLEVBQXFCcEMsT0FBckIsRUFBaUM7QUFDckQsTUFBTW1GLGFBQWFDLEtBQUtDLFNBQUwsQ0FBZTtBQUNoQzFILFNBQUssQ0FBQ0EsT0FBTyxFQUFSLEVBQVkySCxJQUFaLEVBRDJCO0FBRWhDbEQsbUJBQWUsQ0FBQ0EsaUJBQWlCLEVBQWxCLEVBQXNCa0QsSUFBdEIsRUFGaUI7QUFHaEMxSCxnQkFBWUMsTUFBTUMsSUFBTixDQUFXLCtCQUFrQmtDLFFBQVFxQyxRQUExQixDQUFYLEVBQWdEaUQsSUFBaEQsRUFIb0IsRUFBZixDQUFuQjs7QUFLQSxNQUFJSCxlQUFlRixjQUFuQixFQUFtQztBQUNqQztBQUNEOztBQUVEdEQsYUFBVzRELEtBQVg7QUFDQTFELGFBQVcwRCxLQUFYO0FBQ0F4RCxlQUFhd0QsS0FBYjtBQUNBdEQsa0JBQWdCc0QsS0FBaEI7O0FBRUE1QyxhQUFXUixhQUFhMkMsT0FBT25ILEdBQVAsQ0FBYixFQUEwQnlFLGFBQTFCLEVBQXlDcEMsT0FBekMsQ0FBWDtBQUNBMEMsMkJBQXlCQyxRQUF6QixFQUFtQzNDLE9BQW5DO0FBQ0F5RTtBQUNBUSxtQkFBaUJFLFVBQWpCO0FBQ0QsQ0FuQkQ7O0FBcUJBLElBQU1LLDJCQUEyQixTQUEzQkEsd0JBQTJCLENBQUNDLFVBQUQsVUFBZ0JBLFdBQVdDLElBQVgsQ0FBZ0Isc0JBQUdyRSxJQUFILFNBQUdBLElBQUgsUUFBY0EsU0FBU2hCLDBCQUF2QixFQUFoQixDQUFoQixFQUFqQzs7QUFFQSxJQUFNc0YseUJBQXlCLFNBQXpCQSxzQkFBeUIsQ0FBQ0YsVUFBRCxVQUFnQkEsV0FBV0MsSUFBWCxDQUFnQixzQkFBR3JFLElBQUgsU0FBR0EsSUFBSCxRQUFjQSxTQUFTZix3QkFBdkIsRUFBaEIsQ0FBaEIsRUFBL0I7O0FBRUEsSUFBTXNGLGNBQWMsU0FBZEEsV0FBYyxDQUFDL0MsSUFBRCxFQUFVO0FBQ04sOEJBQVUsRUFBRW1DLEtBQUtuQyxJQUFQLEVBQVYsQ0FETSxDQUNwQnhELElBRG9CLGNBQ3BCQSxJQURvQixDQUNkd0csR0FEYyxjQUNkQSxHQURjO0FBRTVCLE1BQU1DLFdBQVcsbUJBQVF6RyxJQUFSLENBQWpCOztBQUVBLE1BQU0wRyxzQkFBc0IsU0FBdEJBLG1CQUFzQixDQUFDQyxRQUFELEVBQWM7QUFDeEMsUUFBSSxnQkFBS0YsUUFBTCxFQUFlRSxRQUFmLE1BQTZCbkQsSUFBakMsRUFBdUM7QUFDckMsYUFBTyxJQUFQO0FBQ0Q7QUFDRixHQUpEOztBQU1BLE1BQU1vRCxzQkFBc0IsU0FBdEJBLG1CQUFzQixDQUFDRCxRQUFELEVBQWM7QUFDeEMsUUFBTUUsZ0JBQWdCLGlDQUFRLHlCQUFPRixRQUFQLENBQVIsRUFBMEIsVUFBQ3BDLEtBQUQsVUFBVyxPQUFPQSxLQUFQLEtBQWlCLFNBQWpCLEdBQTZCLEVBQTdCLEdBQWtDLGdCQUFLa0MsUUFBTCxFQUFlbEMsS0FBZixDQUE3QyxFQUExQixDQUF0Qjs7QUFFQSxRQUFJLGdDQUFTc0MsYUFBVCxFQUF3QnJELElBQXhCLENBQUosRUFBbUM7QUFDakMsYUFBTyxJQUFQO0FBQ0Q7QUFDRixHQU5EOztBQVFBLE1BQU1zRCxnQkFBZ0IsU0FBaEJBLGFBQWdCLENBQUNILFFBQUQsRUFBYztBQUNsQyxRQUFJLE9BQU9BLFFBQVAsS0FBb0IsUUFBeEIsRUFBa0M7QUFDaEMsYUFBT0Qsb0JBQW9CQyxRQUFwQixDQUFQO0FBQ0Q7O0FBRUQsUUFBSSxRQUFPQSxRQUFQLHlDQUFPQSxRQUFQLE9BQW9CLFFBQXhCLEVBQWtDO0FBQ2hDLGFBQU9DLG9CQUFvQkQsUUFBcEIsQ0FBUDtBQUNEO0FBQ0YsR0FSRDs7QUFVQSxNQUFJSCxtQkFBZ0IsSUFBcEIsRUFBMEI7QUFDeEIsV0FBTyxLQUFQO0FBQ0Q7O0FBRUQsTUFBSUEsSUFBSU8sR0FBUixFQUFhO0FBQ1gsUUFBSUQsY0FBY04sSUFBSU8sR0FBbEIsQ0FBSixFQUE0QjtBQUMxQixhQUFPLElBQVA7QUFDRDtBQUNGOztBQUVELE1BQUlQLElBQUlRLE9BQVIsRUFBaUI7QUFDZixRQUFJRixjQUFjTixJQUFJUSxPQUFsQixDQUFKLEVBQWdDO0FBQzlCLGFBQU8sSUFBUDtBQUNEO0FBQ0Y7O0FBRUQsTUFBSVIsSUFBSVMsSUFBUixFQUFjO0FBQ1osUUFBSVAsb0JBQW9CRixJQUFJUyxJQUF4QixDQUFKLEVBQW1DO0FBQ2pDLGFBQU8sSUFBUDtBQUNEO0FBQ0Y7O0FBRUQsU0FBTyxLQUFQO0FBQ0QsQ0FuREQ7O0FBcURBQyxPQUFPekQsT0FBUCxHQUFpQjtBQUNmMEQsUUFBTTtBQUNKbkYsVUFBTSxZQURGO0FBRUpvRixVQUFNO0FBQ0pDLGdCQUFVLGtCQUROO0FBRUpDLG1CQUFhLHVGQUZUO0FBR0pDLFdBQUssMEJBQVEsbUJBQVIsQ0FIRCxFQUZGOztBQU9KQyxZQUFRLENBQUM7QUFDUEMsa0JBQVk7QUFDVm5KLGFBQUs7QUFDSGdKLHVCQUFhLHNEQURWO0FBRUh0RixnQkFBTSxPQUZIO0FBR0gwRix1QkFBYSxJQUhWO0FBSUhDLGlCQUFPO0FBQ0wzRixrQkFBTSxRQUREO0FBRUw0Rix1QkFBVyxDQUZOLEVBSkosRUFESzs7O0FBVVY3RSx1QkFBZTtBQUNidUUsdUJBQWEscUZBREE7QUFFYnRGLGdCQUFNLE9BRk87QUFHYjBGLHVCQUFhLElBSEE7QUFJYkMsaUJBQU87QUFDTDNGLGtCQUFNLFFBREQ7QUFFTDRGLHVCQUFXLENBRk4sRUFKTSxFQVZMOzs7QUFtQlZDLHdCQUFnQjtBQUNkUCx1QkFBYSxvQ0FEQztBQUVkdEYsZ0JBQU0sU0FGUSxFQW5CTjs7QUF1QlY4Rix1QkFBZTtBQUNiUix1QkFBYSxrQ0FEQTtBQUVidEYsZ0JBQU0sU0FGTyxFQXZCTDs7QUEyQlYrRixpQ0FBeUI7QUFDdkJULHVCQUFhLHVDQURVO0FBRXZCdEYsZ0JBQU0sU0FGaUIsRUEzQmYsRUFETDs7O0FBaUNQZ0csYUFBTztBQUNMO0FBQ0VQLG9CQUFZO0FBQ1ZLLHlCQUFlLEVBQUUsUUFBTSxDQUFDLElBQUQsQ0FBUixFQURMO0FBRVZ4SixlQUFLO0FBQ0gySixzQkFBVSxDQURQLEVBRkssRUFEZDs7O0FBT0VDLGtCQUFVLENBQUMsZUFBRCxDQVBaLEVBREs7O0FBVUw7QUFDRVQsb0JBQVk7QUFDVkksMEJBQWdCLEVBQUUsUUFBTSxDQUFDLElBQUQsQ0FBUixFQUROLEVBRGQ7O0FBSUVLLGtCQUFVLENBQUMsZ0JBQUQsQ0FKWixFQVZLLENBakNBLEVBQUQsQ0FQSixFQURTOzs7Ozs7QUE2RGZDLFFBN0RlLCtCQTZEUnhILE9BN0RRLEVBNkRDOzs7Ozs7O0FBT1ZBLGNBQVF5SCxPQUFSLENBQWdCLENBQWhCLEtBQXNCLEVBUFosQ0FFWjlKLEdBRlksU0FFWkEsR0FGWSw2QkFHWnlFLGFBSFksQ0FHWkEsYUFIWSx1Q0FHSSxFQUhKLHVCQUlaOEUsY0FKWSxTQUlaQSxjQUpZLENBS1pDLGFBTFksU0FLWkEsYUFMWSxDQU1aQyx1QkFOWSxTQU1aQSx1QkFOWTs7QUFTZCxVQUFJRCxhQUFKLEVBQW1CO0FBQ2pCakMsc0JBQWN2SCxHQUFkLEVBQW1CeUUsYUFBbkIsRUFBa0NwQyxPQUFsQztBQUNEOztBQUVELFVBQU02QyxPQUFPN0MsUUFBUTBILG1CQUFSLEdBQThCMUgsUUFBUTBILG1CQUFSLEVBQTlCLEdBQThEMUgsUUFBUTJILFdBQVIsRUFBM0U7O0FBRUEsVUFBTUMsbUNBQXNCLFNBQXRCQSxtQkFBc0IsQ0FBQ0MsSUFBRCxFQUFVO0FBQ3BDLGNBQUksQ0FBQ1gsY0FBTCxFQUFxQjtBQUNuQjtBQUNEOztBQUVELGNBQUluRixhQUFhdUMsR0FBYixDQUFpQnpCLElBQWpCLENBQUosRUFBNEI7QUFDMUI7QUFDRDs7QUFFRCxjQUFNaUYsY0FBY2pHLFdBQVdxQixHQUFYLENBQWVMLElBQWYsQ0FBcEI7QUFDQSxjQUFNRCxZQUFZa0YsWUFBWTVFLEdBQVosQ0FBZ0IvQyxzQkFBaEIsQ0FBbEI7QUFDQSxjQUFNNEgsbUJBQW1CRCxZQUFZNUUsR0FBWixDQUFnQjdDLDBCQUFoQixDQUF6Qjs7QUFFQXlILGdDQUFtQjNILHNCQUFuQjtBQUNBMkgsZ0NBQW1CekgsMEJBQW5CO0FBQ0EsY0FBSXlILFlBQVlFLElBQVosR0FBbUIsQ0FBdkIsRUFBMEI7QUFDeEI7QUFDQTtBQUNBaEksb0JBQVFpSSxNQUFSLENBQWVKLEtBQUtLLElBQUwsQ0FBVSxDQUFWLElBQWVMLEtBQUtLLElBQUwsQ0FBVSxDQUFWLENBQWYsR0FBOEJMLElBQTdDLEVBQW1ELGtCQUFuRDtBQUNEO0FBQ0RDLHNCQUFZdEUsR0FBWixDQUFnQnJELHNCQUFoQixFQUF3Q3lDLFNBQXhDO0FBQ0FrRixzQkFBWXRFLEdBQVosQ0FBZ0JuRCwwQkFBaEIsRUFBNEMwSCxnQkFBNUM7QUFDRCxTQXRCSyw4QkFBTjs7QUF3QkEsVUFBTUksMEJBQWEsU0FBYkEsVUFBYSxDQUFDTixJQUFELEVBQU9PLGFBQVAsRUFBc0JDLFlBQXRCLEVBQXVDO0FBQ3hELGNBQUksQ0FBQ2xCLGFBQUwsRUFBb0I7QUFDbEI7QUFDRDs7QUFFRCxjQUFJa0IsZ0JBQWdCakIsdUJBQXBCLEVBQTZDO0FBQzNDO0FBQ0Q7O0FBRUQsY0FBSXJGLGFBQWF1QyxHQUFiLENBQWlCekIsSUFBakIsQ0FBSixFQUE0QjtBQUMxQjtBQUNEOztBQUVELGNBQUkrQyxZQUFZL0MsSUFBWixDQUFKLEVBQXVCO0FBQ3JCO0FBQ0Q7O0FBRUQsY0FBSVosZ0JBQWdCcUMsR0FBaEIsQ0FBb0J6QixJQUFwQixDQUFKLEVBQStCO0FBQzdCO0FBQ0Q7O0FBRUQ7QUFDQSxjQUFJLENBQUNGLFNBQVMyQixHQUFULENBQWF6QixJQUFiLENBQUwsRUFBeUI7QUFDdkJGLHVCQUFXUixhQUFhMkMsT0FBT25ILEdBQVAsQ0FBYixFQUEwQnlFLGFBQTFCLEVBQXlDcEMsT0FBekMsQ0FBWDtBQUNBLGdCQUFJLENBQUMyQyxTQUFTMkIsR0FBVCxDQUFhekIsSUFBYixDQUFMLEVBQXlCO0FBQ3ZCWiw4QkFBZ0JPLEdBQWhCLENBQW9CSyxJQUFwQjtBQUNBO0FBQ0Q7QUFDRjs7QUFFREMsb0JBQVVqQixXQUFXcUIsR0FBWCxDQUFlTCxJQUFmLENBQVY7O0FBRUEsY0FBSSxDQUFDQyxPQUFMLEVBQWM7QUFDWndGLG9CQUFRQyxLQUFSLG1CQUF3QjFGLElBQXhCO0FBQ0Q7O0FBRUQ7QUFDQSxjQUFNRCxZQUFZRSxRQUFRSSxHQUFSLENBQVkvQyxzQkFBWixDQUFsQjtBQUNBLGNBQUksT0FBT3lDLFNBQVAsS0FBcUIsV0FBckIsSUFBb0N3RixrQkFBa0I5SCx3QkFBMUQsRUFBb0Y7QUFDbEYsZ0JBQUlzQyxVQUFVa0IsU0FBVixDQUFvQmtFLElBQXBCLEdBQTJCLENBQS9CLEVBQWtDO0FBQ2hDO0FBQ0Q7QUFDRjs7QUFFRDtBQUNBLGNBQU1ELG1CQUFtQmpGLFFBQVFJLEdBQVIsQ0FBWTdDLDBCQUFaLENBQXpCO0FBQ0EsY0FBSSxPQUFPMEgsZ0JBQVAsS0FBNEIsV0FBaEMsRUFBNkM7QUFDM0MsZ0JBQUlBLGlCQUFpQmpFLFNBQWpCLENBQTJCa0UsSUFBM0IsR0FBa0MsQ0FBdEMsRUFBeUM7QUFDdkM7QUFDRDtBQUNGOztBQUVEO0FBQ0EsY0FBTVEsYUFBYUosa0JBQWtCcEgsT0FBbEIsR0FBNEJWLHdCQUE1QixHQUF1RDhILGFBQTFFOztBQUVBLGNBQU12RCxrQkFBa0IvQixRQUFRSSxHQUFSLENBQVlzRixVQUFaLENBQXhCOztBQUVBLGNBQU01RSxRQUFRNEUsZUFBZWxJLHdCQUFmLEdBQTBDVSxPQUExQyxHQUFvRHdILFVBQWxFOztBQUVBLGNBQUksT0FBTzNELGVBQVAsS0FBMkIsV0FBL0IsRUFBNEM7QUFDMUMsZ0JBQUlBLGdCQUFnQmYsU0FBaEIsQ0FBMEJrRSxJQUExQixHQUFpQyxDQUFyQyxFQUF3QztBQUN0Q2hJLHNCQUFRaUksTUFBUjtBQUNFSixrQkFERjtBQUUyQmpFLG1CQUYzQjs7QUFJRDtBQUNGLFdBUEQsTUFPTztBQUNMNUQsb0JBQVFpSSxNQUFSO0FBQ0VKLGdCQURGO0FBRTJCakUsaUJBRjNCOztBQUlEO0FBQ0YsU0F4RUsscUJBQU47O0FBMEVBOzs7OztBQUtBLFVBQU02RSxpQ0FBb0IsU0FBcEJBLGlCQUFvQixDQUFDWixJQUFELEVBQVU7QUFDbEMsY0FBSTlGLGFBQWF1QyxHQUFiLENBQWlCekIsSUFBakIsQ0FBSixFQUE0QjtBQUMxQjtBQUNEOztBQUVELGNBQUlDLFVBQVVqQixXQUFXcUIsR0FBWCxDQUFlTCxJQUFmLENBQWQ7O0FBRUE7QUFDQTtBQUNBLGNBQUksT0FBT0MsT0FBUCxLQUFtQixXQUF2QixFQUFvQztBQUNsQ0Esc0JBQVUsSUFBSWxCLEdBQUosRUFBVjtBQUNEOztBQUVELGNBQU04RyxhQUFhLElBQUk5RyxHQUFKLEVBQW5CO0FBQ0EsY0FBTStHLHVCQUF1QixJQUFJM0csR0FBSixFQUE3Qjs7QUFFQTZGLGVBQUtLLElBQUwsQ0FBVXpHLE9BQVYsQ0FBa0Isa0JBQXVDLEtBQXBDSixJQUFvQyxVQUFwQ0EsSUFBb0MsQ0FBOUJILFdBQThCLFVBQTlCQSxXQUE4QixDQUFqQnVFLFVBQWlCLFVBQWpCQSxVQUFpQjtBQUN2RCxnQkFBSXBFLFNBQVNwQiwwQkFBYixFQUF5QztBQUN2QzBJLG1DQUFxQm5HLEdBQXJCLENBQXlCbEMsd0JBQXpCO0FBQ0Q7QUFDRCxnQkFBSWUsU0FBU25CLHdCQUFiLEVBQXVDO0FBQ3JDLGtCQUFJdUYsV0FBVzFGLE1BQVgsR0FBb0IsQ0FBeEIsRUFBMkI7QUFDekIwRiwyQkFBV2hFLE9BQVgsQ0FBbUIsVUFBQzRDLFNBQUQsRUFBZTtBQUNoQyxzQkFBSUEsVUFBVXVFLFFBQWQsRUFBd0I7QUFDdEJELHlDQUFxQm5HLEdBQXJCLENBQXlCNkIsVUFBVXVFLFFBQVYsQ0FBbUJySCxJQUFuQixJQUEyQjhDLFVBQVV1RSxRQUFWLENBQW1CaEYsS0FBdkU7QUFDRDtBQUNGLGlCQUpEO0FBS0Q7QUFDRDNDLDJDQUE2QkMsV0FBN0IsRUFBMEMsVUFBQ0ssSUFBRCxFQUFVO0FBQ2xEb0gscUNBQXFCbkcsR0FBckIsQ0FBeUJqQixJQUF6QjtBQUNELGVBRkQ7QUFHRDtBQUNGLFdBaEJEOztBQWtCQTtBQUNBdUIsa0JBQVFyQixPQUFSLENBQWdCLFVBQUNtQyxLQUFELEVBQVFDLEdBQVIsRUFBZ0I7QUFDOUIsZ0JBQUk4RSxxQkFBcUJyRSxHQUFyQixDQUF5QlQsR0FBekIsQ0FBSixFQUFtQztBQUNqQzZFLHlCQUFXbEYsR0FBWCxDQUFlSyxHQUFmLEVBQW9CRCxLQUFwQjtBQUNEO0FBQ0YsV0FKRDs7QUFNQTtBQUNBK0UsK0JBQXFCbEgsT0FBckIsQ0FBNkIsVUFBQ29DLEdBQUQsRUFBUztBQUNwQyxnQkFBSSxDQUFDZixRQUFRd0IsR0FBUixDQUFZVCxHQUFaLENBQUwsRUFBdUI7QUFDckI2RSx5QkFBV2xGLEdBQVgsQ0FBZUssR0FBZixFQUFvQixFQUFFQyxXQUFXLElBQUk5QixHQUFKLEVBQWIsRUFBcEI7QUFDRDtBQUNGLFdBSkQ7O0FBTUE7QUFDQSxjQUFNWSxZQUFZRSxRQUFRSSxHQUFSLENBQVkvQyxzQkFBWixDQUFsQjtBQUNBLGNBQUk0SCxtQkFBbUJqRixRQUFRSSxHQUFSLENBQVk3QywwQkFBWixDQUF2Qjs7QUFFQSxjQUFJLE9BQU8wSCxnQkFBUCxLQUE0QixXQUFoQyxFQUE2QztBQUMzQ0EsK0JBQW1CLEVBQUVqRSxXQUFXLElBQUk5QixHQUFKLEVBQWIsRUFBbkI7QUFDRDs7QUFFRDBHLHFCQUFXbEYsR0FBWCxDQUFlckQsc0JBQWYsRUFBdUN5QyxTQUF2QztBQUNBOEYscUJBQVdsRixHQUFYLENBQWVuRCwwQkFBZixFQUEyQzBILGdCQUEzQztBQUNBbEcscUJBQVcyQixHQUFYLENBQWVYLElBQWYsRUFBcUI2RixVQUFyQjtBQUNELFNBM0RLLDRCQUFOOztBQTZEQTs7Ozs7QUFLQSxVQUFNRyxpQ0FBb0IsU0FBcEJBLGlCQUFvQixDQUFDaEIsSUFBRCxFQUFVO0FBQ2xDLGNBQUksQ0FBQ1YsYUFBTCxFQUFvQjtBQUNsQjtBQUNEOztBQUVELGNBQUkyQixpQkFBaUJuSCxXQUFXdUIsR0FBWCxDQUFlTCxJQUFmLENBQXJCO0FBQ0EsY0FBSSxPQUFPaUcsY0FBUCxLQUEwQixXQUE5QixFQUEyQztBQUN6Q0EsNkJBQWlCLElBQUlsSCxHQUFKLEVBQWpCO0FBQ0Q7O0FBRUQsY0FBTW1ILHNCQUFzQixJQUFJL0csR0FBSixFQUE1QjtBQUNBLGNBQU1nSCxzQkFBc0IsSUFBSWhILEdBQUosRUFBNUI7O0FBRUEsY0FBTWlILGVBQWUsSUFBSWpILEdBQUosRUFBckI7QUFDQSxjQUFNa0gsZUFBZSxJQUFJbEgsR0FBSixFQUFyQjs7QUFFQSxjQUFNbUgsb0JBQW9CLElBQUluSCxHQUFKLEVBQTFCO0FBQ0EsY0FBTW9ILG9CQUFvQixJQUFJcEgsR0FBSixFQUExQjs7QUFFQSxjQUFNcUgsYUFBYSxJQUFJekgsR0FBSixFQUFuQjtBQUNBLGNBQU0wSCxhQUFhLElBQUkxSCxHQUFKLEVBQW5CO0FBQ0FrSCx5QkFBZXJILE9BQWYsQ0FBdUIsVUFBQ21DLEtBQUQsRUFBUUMsR0FBUixFQUFnQjtBQUNyQyxnQkFBSUQsTUFBTVUsR0FBTixDQUFVbkUsc0JBQVYsQ0FBSixFQUF1QztBQUNyQzhJLDJCQUFhekcsR0FBYixDQUFpQnFCLEdBQWpCO0FBQ0Q7QUFDRCxnQkFBSUQsTUFBTVUsR0FBTixDQUFVakUsMEJBQVYsQ0FBSixFQUEyQztBQUN6QzBJLGtDQUFvQnZHLEdBQXBCLENBQXdCcUIsR0FBeEI7QUFDRDtBQUNELGdCQUFJRCxNQUFNVSxHQUFOLENBQVVoRSx3QkFBVixDQUFKLEVBQXlDO0FBQ3ZDNkksZ0NBQWtCM0csR0FBbEIsQ0FBc0JxQixHQUF0QjtBQUNEO0FBQ0RELGtCQUFNbkMsT0FBTixDQUFjLFVBQUM4QyxHQUFELEVBQVM7QUFDckI7QUFDRUEsc0JBQVFsRSwwQkFBUjtBQUNHa0Usc0JBQVFqRSx3QkFGYjtBQUdFO0FBQ0ErSSwyQkFBVzdGLEdBQVgsQ0FBZWUsR0FBZixFQUFvQlYsR0FBcEI7QUFDRDtBQUNGLGFBUEQ7QUFRRCxXQWxCRDs7QUFvQkEsbUJBQVMwRixvQkFBVCxDQUE4QkMsTUFBOUIsRUFBc0M7QUFDcEMsZ0JBQUlBLE9BQU9uSSxJQUFQLEtBQWdCLFNBQXBCLEVBQStCO0FBQzdCLHFCQUFPLElBQVA7QUFDRDtBQUNELGdCQUFNb0ksSUFBSSwwQkFBUUQsT0FBTzVGLEtBQWYsRUFBc0I1RCxPQUF0QixDQUFWO0FBQ0EsZ0JBQUl5SixLQUFLLElBQVQsRUFBZTtBQUNiLHFCQUFPLElBQVA7QUFDRDtBQUNEVCxnQ0FBb0J4RyxHQUFwQixDQUF3QmlILENBQXhCO0FBQ0Q7O0FBRUQsa0NBQU01QixJQUFOLEVBQVkvRixjQUFjb0IsR0FBZCxDQUFrQkwsSUFBbEIsQ0FBWixFQUFxQztBQUNuQzZHLDRCQURtQyx5Q0FDbEJDLEtBRGtCLEVBQ1g7QUFDdEJKLHFDQUFxQkksTUFBTUgsTUFBM0I7QUFDRCxlQUhrQztBQUluQ0ksMEJBSm1DLHVDQUlwQkQsS0FKb0IsRUFJYjtBQUNwQixvQkFBSUEsTUFBTUUsTUFBTixDQUFheEksSUFBYixLQUFzQixRQUExQixFQUFvQztBQUNsQ2tJLHVDQUFxQkksTUFBTUcsU0FBTixDQUFnQixDQUFoQixDQUFyQjtBQUNEO0FBQ0YsZUFSa0MsMkJBQXJDOzs7QUFXQWpDLGVBQUtLLElBQUwsQ0FBVXpHLE9BQVYsQ0FBa0IsVUFBQ3NJLE9BQUQsRUFBYTtBQUM3QixnQkFBSUMscUJBQUo7O0FBRUE7QUFDQSxnQkFBSUQsUUFBUTFJLElBQVIsS0FBaUJuQix3QkFBckIsRUFBK0M7QUFDN0Msa0JBQUk2SixRQUFRUCxNQUFaLEVBQW9CO0FBQ2xCUSwrQkFBZSwwQkFBUUQsUUFBUVAsTUFBUixDQUFlUyxHQUFmLENBQW1CQyxPQUFuQixDQUEyQixRQUEzQixFQUFxQyxFQUFyQyxDQUFSLEVBQWtEbEssT0FBbEQsQ0FBZjtBQUNBK0osd0JBQVF0RSxVQUFSLENBQW1CaEUsT0FBbkIsQ0FBMkIsVUFBQzRDLFNBQUQsRUFBZTtBQUN4QyxzQkFBTTlDLE9BQU84QyxVQUFVRixLQUFWLENBQWdCNUMsSUFBaEIsSUFBd0I4QyxVQUFVRixLQUFWLENBQWdCUCxLQUFyRDtBQUNBLHNCQUFJckMsU0FBU1AsT0FBYixFQUFzQjtBQUNwQm9JLHNDQUFrQjVHLEdBQWxCLENBQXNCd0gsWUFBdEI7QUFDRCxtQkFGRCxNQUVPO0FBQ0xWLCtCQUFXOUYsR0FBWCxDQUFlakMsSUFBZixFQUFxQnlJLFlBQXJCO0FBQ0Q7QUFDRixpQkFQRDtBQVFEO0FBQ0Y7O0FBRUQsZ0JBQUlELFFBQVExSSxJQUFSLEtBQWlCbEIsc0JBQXJCLEVBQTZDO0FBQzNDNkosNkJBQWUsMEJBQVFELFFBQVFQLE1BQVIsQ0FBZVMsR0FBZixDQUFtQkMsT0FBbkIsQ0FBMkIsUUFBM0IsRUFBcUMsRUFBckMsQ0FBUixFQUFrRGxLLE9BQWxELENBQWY7QUFDQWtKLDJCQUFhMUcsR0FBYixDQUFpQndILFlBQWpCO0FBQ0Q7O0FBRUQsZ0JBQUlELFFBQVExSSxJQUFSLEtBQWlCakIsa0JBQXJCLEVBQXlDO0FBQ3ZDNEosNkJBQWUsMEJBQVFELFFBQVFQLE1BQVIsQ0FBZVMsR0FBZixDQUFtQkMsT0FBbkIsQ0FBMkIsUUFBM0IsRUFBcUMsRUFBckMsQ0FBUixFQUFrRGxLLE9BQWxELENBQWY7QUFDQSxrQkFBSSxDQUFDZ0ssWUFBTCxFQUFtQjtBQUNqQjtBQUNEOztBQUVELGtCQUFJOUgsYUFBYThILFlBQWIsQ0FBSixFQUFnQztBQUM5QjtBQUNEOztBQUVELGtCQUFJeEUseUJBQXlCdUUsUUFBUXRFLFVBQWpDLENBQUosRUFBa0Q7QUFDaER1RCxvQ0FBb0J4RyxHQUFwQixDQUF3QndILFlBQXhCO0FBQ0Q7O0FBRUQsa0JBQUlyRSx1QkFBdUJvRSxRQUFRdEUsVUFBL0IsQ0FBSixFQUFnRDtBQUM5QzJELGtDQUFrQjVHLEdBQWxCLENBQXNCd0gsWUFBdEI7QUFDRDs7QUFFREQsc0JBQVF0RSxVQUFSO0FBQ0c3RixvQkFESCxDQUNVLFVBQUN5RSxTQUFELFVBQWVBLFVBQVVoRCxJQUFWLEtBQW1CZix3QkFBbkIsSUFBK0MrRCxVQUFVaEQsSUFBVixLQUFtQmhCLDBCQUFqRixFQURWO0FBRUdvQixxQkFGSCxDQUVXLFVBQUM0QyxTQUFELEVBQWU7QUFDdEJpRiwyQkFBVzlGLEdBQVgsQ0FBZWEsVUFBVThGLFFBQVYsQ0FBbUI1SSxJQUFuQixJQUEyQjhDLFVBQVU4RixRQUFWLENBQW1CdkcsS0FBN0QsRUFBb0VvRyxZQUFwRTtBQUNELGVBSkg7QUFLRDtBQUNGLFdBL0NEOztBQWlEQWQsdUJBQWF6SCxPQUFiLENBQXFCLFVBQUNtQyxLQUFELEVBQVc7QUFDOUIsZ0JBQUksQ0FBQ3FGLGFBQWEzRSxHQUFiLENBQWlCVixLQUFqQixDQUFMLEVBQThCO0FBQzVCLGtCQUFJYixVQUFVK0YsZUFBZTVGLEdBQWYsQ0FBbUJVLEtBQW5CLENBQWQ7QUFDQSxrQkFBSSxPQUFPYixPQUFQLEtBQW1CLFdBQXZCLEVBQW9DO0FBQ2xDQSwwQkFBVSxJQUFJZixHQUFKLEVBQVY7QUFDRDtBQUNEZSxzQkFBUVAsR0FBUixDQUFZckMsc0JBQVo7QUFDQTJJLDZCQUFldEYsR0FBZixDQUFtQkksS0FBbkIsRUFBMEJiLE9BQTFCOztBQUVBLGtCQUFJRCxXQUFVakIsV0FBV3FCLEdBQVgsQ0FBZVUsS0FBZixDQUFkO0FBQ0Esa0JBQUlZLHNCQUFKO0FBQ0Esa0JBQUksT0FBTzFCLFFBQVAsS0FBbUIsV0FBdkIsRUFBb0M7QUFDbEMwQixnQ0FBZ0IxQixTQUFRSSxHQUFSLENBQVkvQyxzQkFBWixDQUFoQjtBQUNELGVBRkQsTUFFTztBQUNMMkMsMkJBQVUsSUFBSWxCLEdBQUosRUFBVjtBQUNBQywyQkFBVzJCLEdBQVgsQ0FBZUksS0FBZixFQUFzQmQsUUFBdEI7QUFDRDs7QUFFRCxrQkFBSSxPQUFPMEIsYUFBUCxLQUF5QixXQUE3QixFQUEwQztBQUN4Q0EsOEJBQWNWLFNBQWQsQ0FBd0J0QixHQUF4QixDQUE0QkssSUFBNUI7QUFDRCxlQUZELE1BRU87QUFDTCxvQkFBTWlCLFlBQVksSUFBSTlCLEdBQUosRUFBbEI7QUFDQThCLDBCQUFVdEIsR0FBVixDQUFjSyxJQUFkO0FBQ0FDLHlCQUFRVSxHQUFSLENBQVlyRCxzQkFBWixFQUFvQyxFQUFFMkQsb0JBQUYsRUFBcEM7QUFDRDtBQUNGO0FBQ0YsV0ExQkQ7O0FBNEJBbUYsdUJBQWF4SCxPQUFiLENBQXFCLFVBQUNtQyxLQUFELEVBQVc7QUFDOUIsZ0JBQUksQ0FBQ3NGLGFBQWE1RSxHQUFiLENBQWlCVixLQUFqQixDQUFMLEVBQThCO0FBQzVCLGtCQUFNYixVQUFVK0YsZUFBZTVGLEdBQWYsQ0FBbUJVLEtBQW5CLENBQWhCO0FBQ0FiLGdDQUFlNUMsc0JBQWY7O0FBRUEsa0JBQU0yQyxZQUFVakIsV0FBV3FCLEdBQVgsQ0FBZVUsS0FBZixDQUFoQjtBQUNBLGtCQUFJLE9BQU9kLFNBQVAsS0FBbUIsV0FBdkIsRUFBb0M7QUFDbEMsb0JBQU0wQixnQkFBZ0IxQixVQUFRSSxHQUFSLENBQVkvQyxzQkFBWixDQUF0QjtBQUNBLG9CQUFJLE9BQU9xRSxhQUFQLEtBQXlCLFdBQTdCLEVBQTBDO0FBQ3hDQSxnQ0FBY1YsU0FBZCxXQUErQmpCLElBQS9CO0FBQ0Q7QUFDRjtBQUNGO0FBQ0YsV0FiRDs7QUFlQXVHLDRCQUFrQjNILE9BQWxCLENBQTBCLFVBQUNtQyxLQUFELEVBQVc7QUFDbkMsZ0JBQUksQ0FBQ3VGLGtCQUFrQjdFLEdBQWxCLENBQXNCVixLQUF0QixDQUFMLEVBQW1DO0FBQ2pDLGtCQUFJYixVQUFVK0YsZUFBZTVGLEdBQWYsQ0FBbUJVLEtBQW5CLENBQWQ7QUFDQSxrQkFBSSxPQUFPYixPQUFQLEtBQW1CLFdBQXZCLEVBQW9DO0FBQ2xDQSwwQkFBVSxJQUFJZixHQUFKLEVBQVY7QUFDRDtBQUNEZSxzQkFBUVAsR0FBUixDQUFZbEMsd0JBQVo7QUFDQXdJLDZCQUFldEYsR0FBZixDQUFtQkksS0FBbkIsRUFBMEJiLE9BQTFCOztBQUVBLGtCQUFJRCxZQUFVakIsV0FBV3FCLEdBQVgsQ0FBZVUsS0FBZixDQUFkO0FBQ0Esa0JBQUlZLHNCQUFKO0FBQ0Esa0JBQUksT0FBTzFCLFNBQVAsS0FBbUIsV0FBdkIsRUFBb0M7QUFDbEMwQixnQ0FBZ0IxQixVQUFRSSxHQUFSLENBQVk1Qyx3QkFBWixDQUFoQjtBQUNELGVBRkQsTUFFTztBQUNMd0MsNEJBQVUsSUFBSWxCLEdBQUosRUFBVjtBQUNBQywyQkFBVzJCLEdBQVgsQ0FBZUksS0FBZixFQUFzQmQsU0FBdEI7QUFDRDs7QUFFRCxrQkFBSSxPQUFPMEIsYUFBUCxLQUF5QixXQUE3QixFQUEwQztBQUN4Q0EsOEJBQWNWLFNBQWQsQ0FBd0J0QixHQUF4QixDQUE0QkssSUFBNUI7QUFDRCxlQUZELE1BRU87QUFDTCxvQkFBTWlCLFlBQVksSUFBSTlCLEdBQUosRUFBbEI7QUFDQThCLDBCQUFVdEIsR0FBVixDQUFjSyxJQUFkO0FBQ0FDLDBCQUFRVSxHQUFSLENBQVlsRCx3QkFBWixFQUFzQyxFQUFFd0Qsb0JBQUYsRUFBdEM7QUFDRDtBQUNGO0FBQ0YsV0ExQkQ7O0FBNEJBcUYsNEJBQWtCMUgsT0FBbEIsQ0FBMEIsVUFBQ21DLEtBQUQsRUFBVztBQUNuQyxnQkFBSSxDQUFDd0Ysa0JBQWtCOUUsR0FBbEIsQ0FBc0JWLEtBQXRCLENBQUwsRUFBbUM7QUFDakMsa0JBQU1iLFVBQVUrRixlQUFlNUYsR0FBZixDQUFtQlUsS0FBbkIsQ0FBaEI7QUFDQWIsZ0NBQWV6Qyx3QkFBZjs7QUFFQSxrQkFBTXdDLFlBQVVqQixXQUFXcUIsR0FBWCxDQUFlVSxLQUFmLENBQWhCO0FBQ0Esa0JBQUksT0FBT2QsU0FBUCxLQUFtQixXQUF2QixFQUFvQztBQUNsQyxvQkFBTTBCLGdCQUFnQjFCLFVBQVFJLEdBQVIsQ0FBWTVDLHdCQUFaLENBQXRCO0FBQ0Esb0JBQUksT0FBT2tFLGFBQVAsS0FBeUIsV0FBN0IsRUFBMEM7QUFDeENBLGdDQUFjVixTQUFkLFdBQStCakIsSUFBL0I7QUFDRDtBQUNGO0FBQ0Y7QUFDRixXQWJEOztBQWVBbUcsOEJBQW9CdkgsT0FBcEIsQ0FBNEIsVUFBQ21DLEtBQUQsRUFBVztBQUNyQyxnQkFBSSxDQUFDbUYsb0JBQW9CekUsR0FBcEIsQ0FBd0JWLEtBQXhCLENBQUwsRUFBcUM7QUFDbkMsa0JBQUliLFVBQVUrRixlQUFlNUYsR0FBZixDQUFtQlUsS0FBbkIsQ0FBZDtBQUNBLGtCQUFJLE9BQU9iLE9BQVAsS0FBbUIsV0FBdkIsRUFBb0M7QUFDbENBLDBCQUFVLElBQUlmLEdBQUosRUFBVjtBQUNEO0FBQ0RlLHNCQUFRUCxHQUFSLENBQVluQywwQkFBWjtBQUNBeUksNkJBQWV0RixHQUFmLENBQW1CSSxLQUFuQixFQUEwQmIsT0FBMUI7O0FBRUEsa0JBQUlELFlBQVVqQixXQUFXcUIsR0FBWCxDQUFlVSxLQUFmLENBQWQ7QUFDQSxrQkFBSVksc0JBQUo7QUFDQSxrQkFBSSxPQUFPMUIsU0FBUCxLQUFtQixXQUF2QixFQUFvQztBQUNsQzBCLGdDQUFnQjFCLFVBQVFJLEdBQVIsQ0FBWTdDLDBCQUFaLENBQWhCO0FBQ0QsZUFGRCxNQUVPO0FBQ0x5Qyw0QkFBVSxJQUFJbEIsR0FBSixFQUFWO0FBQ0FDLDJCQUFXMkIsR0FBWCxDQUFlSSxLQUFmLEVBQXNCZCxTQUF0QjtBQUNEOztBQUVELGtCQUFJLE9BQU8wQixhQUFQLEtBQXlCLFdBQTdCLEVBQTBDO0FBQ3hDQSw4QkFBY1YsU0FBZCxDQUF3QnRCLEdBQXhCLENBQTRCSyxJQUE1QjtBQUNELGVBRkQsTUFFTztBQUNMLG9CQUFNaUIsWUFBWSxJQUFJOUIsR0FBSixFQUFsQjtBQUNBOEIsMEJBQVV0QixHQUFWLENBQWNLLElBQWQ7QUFDQUMsMEJBQVFVLEdBQVIsQ0FBWW5ELDBCQUFaLEVBQXdDLEVBQUV5RCxvQkFBRixFQUF4QztBQUNEO0FBQ0Y7QUFDRixXQTFCRDs7QUE0QkFpRiw4QkFBb0J0SCxPQUFwQixDQUE0QixVQUFDbUMsS0FBRCxFQUFXO0FBQ3JDLGdCQUFJLENBQUNvRixvQkFBb0IxRSxHQUFwQixDQUF3QlYsS0FBeEIsQ0FBTCxFQUFxQztBQUNuQyxrQkFBTWIsVUFBVStGLGVBQWU1RixHQUFmLENBQW1CVSxLQUFuQixDQUFoQjtBQUNBYixnQ0FBZTFDLDBCQUFmOztBQUVBLGtCQUFNeUMsWUFBVWpCLFdBQVdxQixHQUFYLENBQWVVLEtBQWYsQ0FBaEI7QUFDQSxrQkFBSSxPQUFPZCxTQUFQLEtBQW1CLFdBQXZCLEVBQW9DO0FBQ2xDLG9CQUFNMEIsZ0JBQWdCMUIsVUFBUUksR0FBUixDQUFZN0MsMEJBQVosQ0FBdEI7QUFDQSxvQkFBSSxPQUFPbUUsYUFBUCxLQUF5QixXQUE3QixFQUEwQztBQUN4Q0EsZ0NBQWNWLFNBQWQsV0FBK0JqQixJQUEvQjtBQUNEO0FBQ0Y7QUFDRjtBQUNGLFdBYkQ7O0FBZUF5RyxxQkFBVzdILE9BQVgsQ0FBbUIsVUFBQ21DLEtBQUQsRUFBUUMsR0FBUixFQUFnQjtBQUNqQyxnQkFBSSxDQUFDd0YsV0FBVy9FLEdBQVgsQ0FBZVQsR0FBZixDQUFMLEVBQTBCO0FBQ3hCLGtCQUFJZCxVQUFVK0YsZUFBZTVGLEdBQWYsQ0FBbUJVLEtBQW5CLENBQWQ7QUFDQSxrQkFBSSxPQUFPYixPQUFQLEtBQW1CLFdBQXZCLEVBQW9DO0FBQ2xDQSwwQkFBVSxJQUFJZixHQUFKLEVBQVY7QUFDRDtBQUNEZSxzQkFBUVAsR0FBUixDQUFZcUIsR0FBWjtBQUNBaUYsNkJBQWV0RixHQUFmLENBQW1CSSxLQUFuQixFQUEwQmIsT0FBMUI7O0FBRUEsa0JBQUlELFlBQVVqQixXQUFXcUIsR0FBWCxDQUFlVSxLQUFmLENBQWQ7QUFDQSxrQkFBSVksc0JBQUo7QUFDQSxrQkFBSSxPQUFPMUIsU0FBUCxLQUFtQixXQUF2QixFQUFvQztBQUNsQzBCLGdDQUFnQjFCLFVBQVFJLEdBQVIsQ0FBWVcsR0FBWixDQUFoQjtBQUNELGVBRkQsTUFFTztBQUNMZiw0QkFBVSxJQUFJbEIsR0FBSixFQUFWO0FBQ0FDLDJCQUFXMkIsR0FBWCxDQUFlSSxLQUFmLEVBQXNCZCxTQUF0QjtBQUNEOztBQUVELGtCQUFJLE9BQU8wQixhQUFQLEtBQXlCLFdBQTdCLEVBQTBDO0FBQ3hDQSw4QkFBY1YsU0FBZCxDQUF3QnRCLEdBQXhCLENBQTRCSyxJQUE1QjtBQUNELGVBRkQsTUFFTztBQUNMLG9CQUFNaUIsWUFBWSxJQUFJOUIsR0FBSixFQUFsQjtBQUNBOEIsMEJBQVV0QixHQUFWLENBQWNLLElBQWQ7QUFDQUMsMEJBQVFVLEdBQVIsQ0FBWUssR0FBWixFQUFpQixFQUFFQyxvQkFBRixFQUFqQjtBQUNEO0FBQ0Y7QUFDRixXQTFCRDs7QUE0QkF1RixxQkFBVzVILE9BQVgsQ0FBbUIsVUFBQ21DLEtBQUQsRUFBUUMsR0FBUixFQUFnQjtBQUNqQyxnQkFBSSxDQUFDeUYsV0FBV2hGLEdBQVgsQ0FBZVQsR0FBZixDQUFMLEVBQTBCO0FBQ3hCLGtCQUFNZCxVQUFVK0YsZUFBZTVGLEdBQWYsQ0FBbUJVLEtBQW5CLENBQWhCO0FBQ0FiLGdDQUFlYyxHQUFmOztBQUVBLGtCQUFNZixZQUFVakIsV0FBV3FCLEdBQVgsQ0FBZVUsS0FBZixDQUFoQjtBQUNBLGtCQUFJLE9BQU9kLFNBQVAsS0FBbUIsV0FBdkIsRUFBb0M7QUFDbEMsb0JBQU0wQixnQkFBZ0IxQixVQUFRSSxHQUFSLENBQVlXLEdBQVosQ0FBdEI7QUFDQSxvQkFBSSxPQUFPVyxhQUFQLEtBQXlCLFdBQTdCLEVBQTBDO0FBQ3hDQSxnQ0FBY1YsU0FBZCxXQUErQmpCLElBQS9CO0FBQ0Q7QUFDRjtBQUNGO0FBQ0YsV0FiRDtBQWNELFNBM1JLLDRCQUFOOztBQTZSQSxhQUFPO0FBQ0wsc0JBREssb0NBQ1VnRixJQURWLEVBQ2dCO0FBQ25CWSw4QkFBa0JaLElBQWxCO0FBQ0FnQiw4QkFBa0JoQixJQUFsQjtBQUNBRCxnQ0FBb0JDLElBQXBCO0FBQ0QsV0FMSTtBQU1MdUMsZ0NBTkssaURBTW9CdkMsSUFOcEIsRUFNMEI7QUFDN0JNLHVCQUFXTixJQUFYLEVBQWlCdkgsd0JBQWpCLEVBQTJDLEtBQTNDO0FBQ0QsV0FSSTtBQVNMK0osOEJBVEssK0NBU2tCeEMsSUFUbEIsRUFTd0I7QUFDM0JBLGlCQUFLcEMsVUFBTCxDQUFnQmhFLE9BQWhCLENBQXdCLFVBQUM0QyxTQUFELEVBQWU7QUFDckM4RCx5QkFBVzlELFNBQVgsRUFBc0JBLFVBQVV1RSxRQUFWLENBQW1CckgsSUFBbkIsSUFBMkI4QyxVQUFVdUUsUUFBVixDQUFtQmhGLEtBQXBFLEVBQTJFLEtBQTNFO0FBQ0QsYUFGRDtBQUdBM0MseUNBQTZCNEcsS0FBSzNHLFdBQWxDLEVBQStDLFVBQUNLLElBQUQsRUFBTzhHLFlBQVAsRUFBd0I7QUFDckVGLHlCQUFXTixJQUFYLEVBQWlCdEcsSUFBakIsRUFBdUI4RyxZQUF2QjtBQUNELGFBRkQ7QUFHRCxXQWhCSSxtQ0FBUDs7QUFrQkQsS0FwaUJjLG1CQUFqQiIsImZpbGUiOiJuby11bnVzZWQtbW9kdWxlcy5qcyIsInNvdXJjZXNDb250ZW50IjpbIi8qKlxuICogQGZpbGVPdmVydmlldyBFbnN1cmVzIHRoYXQgbW9kdWxlcyBjb250YWluIGV4cG9ydHMgYW5kL29yIGFsbFxuICogbW9kdWxlcyBhcmUgY29uc3VtZWQgd2l0aGluIG90aGVyIG1vZHVsZXMuXG4gKiBAYXV0aG9yIFJlbsOpIEZlcm1hbm5cbiAqL1xuXG5pbXBvcnQgeyBnZXRGaWxlRXh0ZW5zaW9ucyB9IGZyb20gJ2VzbGludC1tb2R1bGUtdXRpbHMvaWdub3JlJztcbmltcG9ydCByZXNvbHZlIGZyb20gJ2VzbGludC1tb2R1bGUtdXRpbHMvcmVzb2x2ZSc7XG5pbXBvcnQgdmlzaXQgZnJvbSAnZXNsaW50LW1vZHVsZS11dGlscy92aXNpdCc7XG5pbXBvcnQgeyBkaXJuYW1lLCBqb2luLCByZXNvbHZlIGFzIHJlc29sdmVQYXRoIH0gZnJvbSAncGF0aCc7XG5pbXBvcnQgcmVhZFBrZ1VwIGZyb20gJ2VzbGludC1tb2R1bGUtdXRpbHMvcmVhZFBrZ1VwJztcbmltcG9ydCB2YWx1ZXMgZnJvbSAnb2JqZWN0LnZhbHVlcyc7XG5pbXBvcnQgaW5jbHVkZXMgZnJvbSAnYXJyYXktaW5jbHVkZXMnO1xuaW1wb3J0IGZsYXRNYXAgZnJvbSAnYXJyYXkucHJvdG90eXBlLmZsYXRtYXAnO1xuXG5pbXBvcnQgeyB3YWxrU3luYyB9IGZyb20gJy4uL2NvcmUvZnNXYWxrJztcbmltcG9ydCBFeHBvcnRNYXBCdWlsZGVyIGZyb20gJy4uL2V4cG9ydE1hcC9idWlsZGVyJztcbmltcG9ydCByZWN1cnNpdmVQYXR0ZXJuQ2FwdHVyZSBmcm9tICcuLi9leHBvcnRNYXAvcGF0dGVybkNhcHR1cmUnO1xuaW1wb3J0IGRvY3NVcmwgZnJvbSAnLi4vZG9jc1VybCc7XG5cbi8qKlxuICogQXR0ZW1wdCB0byBsb2FkIHRoZSBpbnRlcm5hbCBgRmlsZUVudW1lcmF0b3JgIGNsYXNzLCB3aGljaCBoYXMgZXhpc3RlZCBpbiBhIGNvdXBsZVxuICogb2YgZGlmZmVyZW50IHBsYWNlcywgZGVwZW5kaW5nIG9uIHRoZSB2ZXJzaW9uIG9mIGBlc2xpbnRgLiAgVHJ5IHJlcXVpcmluZyBpdCBmcm9tIGJvdGhcbiAqIGxvY2F0aW9ucy5cbiAqIEByZXR1cm5zIFJldHVybnMgdGhlIGBGaWxlRW51bWVyYXRvcmAgY2xhc3MgaWYgaXRzIHJlcXVpcmFibGUsIG90aGVyd2lzZSBgdW5kZWZpbmVkYC5cbiAqL1xuZnVuY3Rpb24gcmVxdWlyZUZpbGVFbnVtZXJhdG9yKCkge1xuICBsZXQgRmlsZUVudW1lcmF0b3I7XG5cbiAgLy8gVHJ5IGdldHRpbmcgaXQgZnJvbSB0aGUgZXNsaW50IHByaXZhdGUgLyBkZXByZWNhdGVkIGFwaVxuICB0cnkge1xuICAgICh7IEZpbGVFbnVtZXJhdG9yIH0gPSByZXF1aXJlKCdlc2xpbnQvdXNlLWF0LXlvdXItb3duLXJpc2snKSk7XG4gIH0gY2F0Y2ggKGUpIHtcbiAgICAvLyBBYnNvcmIgdGhpcyBpZiBpdCdzIE1PRFVMRV9OT1RfRk9VTkRcbiAgICBpZiAoZS5jb2RlICE9PSAnTU9EVUxFX05PVF9GT1VORCcpIHtcbiAgICAgIHRocm93IGU7XG4gICAgfVxuXG4gICAgLy8gSWYgbm90IHRoZXJlLCB0aGVuIHRyeSBnZXR0aW5nIGl0IGZyb20gZXNsaW50L2xpYi9jbGktZW5naW5lL2ZpbGUtZW51bWVyYXRvciAobW92ZWQgdGhlcmUgaW4gdjYpXG4gICAgdHJ5IHtcbiAgICAgICh7IEZpbGVFbnVtZXJhdG9yIH0gPSByZXF1aXJlKCdlc2xpbnQvbGliL2NsaS1lbmdpbmUvZmlsZS1lbnVtZXJhdG9yJykpO1xuICAgIH0gY2F0Y2ggKGUpIHtcbiAgICAgIC8vIEFic29yYiB0aGlzIGlmIGl0J3MgTU9EVUxFX05PVF9GT1VORFxuICAgICAgaWYgKGUuY29kZSAhPT0gJ01PRFVMRV9OT1RfRk9VTkQnKSB7XG4gICAgICAgIHRocm93IGU7XG4gICAgICB9XG4gICAgfVxuICB9XG4gIHJldHVybiBGaWxlRW51bWVyYXRvcjtcbn1cblxuLyoqXG4gKlxuICogQHBhcmFtIEZpbGVFbnVtZXJhdG9yIHRoZSBgRmlsZUVudW1lcmF0b3JgIGNsYXNzIGZyb20gYGVzbGludGAncyBpbnRlcm5hbCBhcGlcbiAqIEBwYXJhbSB7c3RyaW5nfSBzcmMgcGF0aCB0byB0aGUgc3JjIHJvb3RcbiAqIEBwYXJhbSB7c3RyaW5nW119IGV4dGVuc2lvbnMgbGlzdCBvZiBzdXBwb3J0ZWQgZXh0ZW5zaW9uc1xuICogQHJldHVybnMge3sgZmlsZW5hbWU6IHN0cmluZywgaWdub3JlZDogYm9vbGVhbiB9W119IGxpc3Qgb2YgZmlsZXMgdG8gb3BlcmF0ZSBvblxuICovXG5mdW5jdGlvbiBsaXN0RmlsZXNVc2luZ0ZpbGVFbnVtZXJhdG9yKEZpbGVFbnVtZXJhdG9yLCBzcmMsIGV4dGVuc2lvbnMpIHtcbiAgY29uc3QgZSA9IG5ldyBGaWxlRW51bWVyYXRvcih7XG4gICAgZXh0ZW5zaW9ucyxcbiAgfSk7XG5cbiAgcmV0dXJuIEFycmF5LmZyb20oXG4gICAgZS5pdGVyYXRlRmlsZXMoc3JjKSxcbiAgICAoeyBmaWxlUGF0aCwgaWdub3JlZCB9KSA9PiAoeyBmaWxlbmFtZTogZmlsZVBhdGgsIGlnbm9yZWQgfSksXG4gICk7XG59XG5cbi8qKlxuICogQXR0ZW1wdCB0byByZXF1aXJlIG9sZCB2ZXJzaW9ucyBvZiB0aGUgZmlsZSBlbnVtZXJhdGlvbiBjYXBhYmlsaXR5IGZyb20gdjYgYGVzbGludGAgYW5kIGVhcmxpZXIsIGFuZCB1c2VcbiAqIHRob3NlIGZ1bmN0aW9ucyB0byBwcm92aWRlIHRoZSBsaXN0IG9mIGZpbGVzIHRvIG9wZXJhdGUgb25cbiAqIEBwYXJhbSB7c3RyaW5nfSBzcmMgcGF0aCB0byB0aGUgc3JjIHJvb3RcbiAqIEBwYXJhbSB7c3RyaW5nW119IGV4dGVuc2lvbnMgbGlzdCBvZiBzdXBwb3J0ZWQgZXh0ZW5zaW9uc1xuICogQHJldHVybnMge3N0cmluZ1tdfSBsaXN0IG9mIGZpbGVzIHRvIG9wZXJhdGUgb25cbiAqL1xuZnVuY3Rpb24gbGlzdEZpbGVzV2l0aExlZ2FjeUZ1bmN0aW9ucyhzcmMsIGV4dGVuc2lvbnMpIHtcbiAgdHJ5IHtcbiAgICAvLyBlc2xpbnQvbGliL3V0aWwvZ2xvYi11dGlsIGhhcyBiZWVuIG1vdmVkIHRvIGVzbGludC9saWIvdXRpbC9nbG9iLXV0aWxzIHdpdGggdmVyc2lvbiA1LjNcbiAgICBjb25zdCB7IGxpc3RGaWxlc1RvUHJvY2Vzczogb3JpZ2luYWxMaXN0RmlsZXNUb1Byb2Nlc3MgfSA9IHJlcXVpcmUoJ2VzbGludC9saWIvdXRpbC9nbG9iLXV0aWxzJyk7XG4gICAgLy8gUHJldmVudCBwYXNzaW5nIGludmFsaWQgb3B0aW9ucyAoZXh0ZW5zaW9ucyBhcnJheSkgdG8gb2xkIHZlcnNpb25zIG9mIHRoZSBmdW5jdGlvbi5cbiAgICAvLyBodHRwczovL2dpdGh1Yi5jb20vZXNsaW50L2VzbGludC9ibG9iL3Y1LjE2LjAvbGliL3V0aWwvZ2xvYi11dGlscy5qcyNMMTc4LUwyODBcbiAgICAvLyBodHRwczovL2dpdGh1Yi5jb20vZXNsaW50L2VzbGludC9ibG9iL3Y1LjIuMC9saWIvdXRpbC9nbG9iLXV0aWwuanMjTDE3NC1MMjY5XG5cbiAgICByZXR1cm4gb3JpZ2luYWxMaXN0RmlsZXNUb1Byb2Nlc3Moc3JjLCB7XG4gICAgICBleHRlbnNpb25zLFxuICAgIH0pO1xuICB9IGNhdGNoIChlKSB7XG4gICAgLy8gQWJzb3JiIHRoaXMgaWYgaXQncyBNT0RVTEVfTk9UX0ZPVU5EXG4gICAgaWYgKGUuY29kZSAhPT0gJ01PRFVMRV9OT1RfRk9VTkQnKSB7XG4gICAgICB0aHJvdyBlO1xuICAgIH1cblxuICAgIC8vIExhc3QgcGxhY2UgdG8gdHJ5IChwcmUgdjUuMylcbiAgICBjb25zdCB7XG4gICAgICBsaXN0RmlsZXNUb1Byb2Nlc3M6IG9yaWdpbmFsTGlzdEZpbGVzVG9Qcm9jZXNzLFxuICAgIH0gPSByZXF1aXJlKCdlc2xpbnQvbGliL3V0aWwvZ2xvYi11dGlsJyk7XG4gICAgY29uc3QgcGF0dGVybnMgPSBzcmMuY29uY2F0KFxuICAgICAgZmxhdE1hcChcbiAgICAgICAgc3JjLFxuICAgICAgICAocGF0dGVybikgPT4gZXh0ZW5zaW9ucy5tYXAoKGV4dGVuc2lvbikgPT4gKC9cXCpcXCp8XFwqXFwuLykudGVzdChwYXR0ZXJuKSA/IHBhdHRlcm4gOiBgJHtwYXR0ZXJufS8qKi8qJHtleHRlbnNpb259YCksXG4gICAgICApLFxuICAgICk7XG5cbiAgICByZXR1cm4gb3JpZ2luYWxMaXN0RmlsZXNUb1Byb2Nlc3MocGF0dGVybnMpO1xuICB9XG59XG5cbi8qKlxuICogR2l2ZW4gYSBzb3VyY2Ugcm9vdCBhbmQgbGlzdCBvZiBzdXBwb3J0ZWQgZXh0ZW5zaW9ucywgdXNlIGZzV2FsayBhbmQgdGhlXG4gKiBuZXcgYGVzbGludGAgYGNvbnRleHQuc2Vzc2lvbmAgYXBpIHRvIGJ1aWxkIHRoZSBsaXN0IG9mIGZpbGVzIHdlIHdhbnQgdG8gb3BlcmF0ZSBvblxuICogQHBhcmFtIHtzdHJpbmdbXX0gc3JjUGF0aHMgYXJyYXkgb2Ygc291cmNlIHBhdGhzIChmb3IgZmxhdCBjb25maWcgdGhpcyBzaG91bGQganVzdCBiZSBhIHNpbmd1bGFyIHJvb3QgKGUuZy4gY3dkKSlcbiAqIEBwYXJhbSB7c3RyaW5nW119IGV4dGVuc2lvbnMgbGlzdCBvZiBzdXBwb3J0ZWQgZXh0ZW5zaW9uc1xuICogQHBhcmFtIHt7IGlzRGlyZWN0b3J5SWdub3JlZDogKHBhdGg6IHN0cmluZykgPT4gYm9vbGVhbiwgaXNGaWxlSWdub3JlZDogKHBhdGg6IHN0cmluZykgPT4gYm9vbGVhbiB9fSBzZXNzaW9uIGVzbGludCBjb250ZXh0IHNlc3Npb24gb2JqZWN0XG4gKiBAcmV0dXJucyB7c3RyaW5nW119IGxpc3Qgb2YgZmlsZXMgdG8gb3BlcmF0ZSBvblxuICovXG5mdW5jdGlvbiBsaXN0RmlsZXNXaXRoTW9kZXJuQXBpKHNyY1BhdGhzLCBleHRlbnNpb25zLCBzZXNzaW9uKSB7XG4gIC8qKiBAdHlwZSB7c3RyaW5nW119ICovXG4gIGNvbnN0IGZpbGVzID0gW107XG5cbiAgZm9yIChsZXQgaSA9IDA7IGkgPCBzcmNQYXRocy5sZW5ndGg7IGkrKykge1xuICAgIGNvbnN0IHNyYyA9IHNyY1BhdGhzW2ldO1xuICAgIC8vIFVzZSB3YWxrU3luYyBhbG9uZyB3aXRoIHRoZSBuZXcgc2Vzc2lvbiBhcGkgdG8gZ2F0aGVyIHRoZSBsaXN0IG9mIGZpbGVzXG4gICAgY29uc3QgZW50cmllcyA9IHdhbGtTeW5jKHNyYywge1xuICAgICAgZGVlcEZpbHRlcihlbnRyeSkge1xuICAgICAgICBjb25zdCBmdWxsRW50cnlQYXRoID0gcmVzb2x2ZVBhdGgoc3JjLCBlbnRyeS5wYXRoKTtcblxuICAgICAgICAvLyBJbmNsdWRlIHRoZSBkaXJlY3RvcnkgaWYgaXQncyBub3QgbWFya2VkIGFzIGlnbm9yZSBieSBlc2xpbnRcbiAgICAgICAgcmV0dXJuICFzZXNzaW9uLmlzRGlyZWN0b3J5SWdub3JlZChmdWxsRW50cnlQYXRoKTtcbiAgICAgIH0sXG4gICAgICBlbnRyeUZpbHRlcihlbnRyeSkge1xuICAgICAgICBjb25zdCBmdWxsRW50cnlQYXRoID0gcmVzb2x2ZVBhdGgoc3JjLCBlbnRyeS5wYXRoKTtcblxuICAgICAgICAvLyBJbmNsdWRlIHRoZSBmaWxlIGlmIGl0J3Mgbm90IG1hcmtlZCBhcyBpZ25vcmUgYnkgZXNsaW50IGFuZCBpdHMgZXh0ZW5zaW9uIGlzIGluY2x1ZGVkIGluIG91ciBsaXN0XG4gICAgICAgIHJldHVybiAoXG4gICAgICAgICAgIXNlc3Npb24uaXNGaWxlSWdub3JlZChmdWxsRW50cnlQYXRoKVxuICAgICAgICAgICYmIGV4dGVuc2lvbnMuZmluZCgoZXh0ZW5zaW9uKSA9PiBlbnRyeS5wYXRoLmVuZHNXaXRoKGV4dGVuc2lvbikpXG4gICAgICAgICk7XG4gICAgICB9LFxuICAgIH0pO1xuXG4gICAgLy8gRmlsdGVyIG91dCBkaXJlY3RvcmllcyBhbmQgbWFwIGVudHJpZXMgdG8gdGhlaXIgcGF0aHNcbiAgICBmaWxlcy5wdXNoKFxuICAgICAgLi4uZW50cmllc1xuICAgICAgICAuZmlsdGVyKChlbnRyeSkgPT4gIWVudHJ5LmRpcmVudC5pc0RpcmVjdG9yeSgpKVxuICAgICAgICAubWFwKChlbnRyeSkgPT4gZW50cnkucGF0aCksXG4gICAgKTtcbiAgfVxuICByZXR1cm4gZmlsZXM7XG59XG5cbi8qKlxuICogR2l2ZW4gYSBzcmMgcGF0dGVybiBhbmQgbGlzdCBvZiBzdXBwb3J0ZWQgZXh0ZW5zaW9ucywgcmV0dXJuIGEgbGlzdCBvZiBmaWxlcyB0byBwcm9jZXNzXG4gKiB3aXRoIHRoaXMgcnVsZS5cbiAqIEBwYXJhbSB7c3RyaW5nfSBzcmMgLSBmaWxlLCBkaXJlY3RvcnksIG9yIGdsb2IgcGF0dGVybiBvZiBmaWxlcyB0byBhY3Qgb25cbiAqIEBwYXJhbSB7c3RyaW5nW119IGV4dGVuc2lvbnMgLSBsaXN0IG9mIHN1cHBvcnRlZCBmaWxlIGV4dGVuc2lvbnNcbiAqIEBwYXJhbSB7aW1wb3J0KCdlc2xpbnQnKS5SdWxlLlJ1bGVDb250ZXh0fSBjb250ZXh0IC0gdGhlIGVzbGludCBjb250ZXh0IG9iamVjdFxuICogQHJldHVybnMge3N0cmluZ1tdIHwgeyBmaWxlbmFtZTogc3RyaW5nLCBpZ25vcmVkOiBib29sZWFuIH1bXX0gdGhlIGxpc3Qgb2YgZmlsZXMgdGhhdCB0aGlzIHJ1bGUgd2lsbCBldmFsdWF0ZS5cbiAqL1xuZnVuY3Rpb24gbGlzdEZpbGVzVG9Qcm9jZXNzKHNyYywgZXh0ZW5zaW9ucywgY29udGV4dCkge1xuICAvLyBJZiB0aGUgY29udGV4dCBvYmplY3QgaGFzIHRoZSBuZXcgc2Vzc2lvbiBmdW5jdGlvbnMsIHRoZW4gcHJlZmVyIHRob3NlXG4gIC8vIE90aGVyd2lzZSwgZmFsbGJhY2sgdG8gdXNpbmcgdGhlIGRlcHJlY2F0ZWQgYEZpbGVFbnVtZXJhdG9yYCBmb3IgbGVnYWN5IHN1cHBvcnQuXG4gIC8vIGh0dHBzOi8vZ2l0aHViLmNvbS9lc2xpbnQvZXNsaW50L2lzc3Vlcy8xODA4N1xuICBpZiAoXG4gICAgY29udGV4dC5zZXNzaW9uXG4gICAgJiYgY29udGV4dC5zZXNzaW9uLmlzRmlsZUlnbm9yZWRcbiAgICAmJiBjb250ZXh0LnNlc3Npb24uaXNEaXJlY3RvcnlJZ25vcmVkXG4gICkge1xuICAgIHJldHVybiBsaXN0RmlsZXNXaXRoTW9kZXJuQXBpKHNyYywgZXh0ZW5zaW9ucywgY29udGV4dC5zZXNzaW9uKTtcbiAgfVxuXG4gIC8vIEZhbGxiYWNrIHRvIG9nIEZpbGVFbnVtZXJhdG9yXG4gIGNvbnN0IEZpbGVFbnVtZXJhdG9yID0gcmVxdWlyZUZpbGVFbnVtZXJhdG9yKCk7XG5cbiAgLy8gSWYgd2UgZ290IHRoZSBGaWxlRW51bWVyYXRvciwgdGhlbiBsZXQncyBnbyB3aXRoIHRoYXRcbiAgaWYgKEZpbGVFbnVtZXJhdG9yKSB7XG4gICAgcmV0dXJuIGxpc3RGaWxlc1VzaW5nRmlsZUVudW1lcmF0b3IoRmlsZUVudW1lcmF0b3IsIHNyYywgZXh0ZW5zaW9ucyk7XG4gIH1cbiAgLy8gSWYgbm90LCB0aGVuIHdlIGNhbiB0cnkgZXZlbiBvbGRlciB2ZXJzaW9ucyBvZiB0aGlzIGNhcGFiaWxpdHkgKGxpc3RGaWxlc1RvUHJvY2VzcylcbiAgcmV0dXJuIGxpc3RGaWxlc1dpdGhMZWdhY3lGdW5jdGlvbnMoc3JjLCBleHRlbnNpb25zKTtcbn1cblxuY29uc3QgRVhQT1JUX0RFRkFVTFRfREVDTEFSQVRJT04gPSAnRXhwb3J0RGVmYXVsdERlY2xhcmF0aW9uJztcbmNvbnN0IEVYUE9SVF9OQU1FRF9ERUNMQVJBVElPTiA9ICdFeHBvcnROYW1lZERlY2xhcmF0aW9uJztcbmNvbnN0IEVYUE9SVF9BTExfREVDTEFSQVRJT04gPSAnRXhwb3J0QWxsRGVjbGFyYXRpb24nO1xuY29uc3QgSU1QT1JUX0RFQ0xBUkFUSU9OID0gJ0ltcG9ydERlY2xhcmF0aW9uJztcbmNvbnN0IElNUE9SVF9OQU1FU1BBQ0VfU1BFQ0lGSUVSID0gJ0ltcG9ydE5hbWVzcGFjZVNwZWNpZmllcic7XG5jb25zdCBJTVBPUlRfREVGQVVMVF9TUEVDSUZJRVIgPSAnSW1wb3J0RGVmYXVsdFNwZWNpZmllcic7XG5jb25zdCBWQVJJQUJMRV9ERUNMQVJBVElPTiA9ICdWYXJpYWJsZURlY2xhcmF0aW9uJztcbmNvbnN0IEZVTkNUSU9OX0RFQ0xBUkFUSU9OID0gJ0Z1bmN0aW9uRGVjbGFyYXRpb24nO1xuY29uc3QgQ0xBU1NfREVDTEFSQVRJT04gPSAnQ2xhc3NEZWNsYXJhdGlvbic7XG5jb25zdCBJREVOVElGSUVSID0gJ0lkZW50aWZpZXInO1xuY29uc3QgT0JKRUNUX1BBVFRFUk4gPSAnT2JqZWN0UGF0dGVybic7XG5jb25zdCBBUlJBWV9QQVRURVJOID0gJ0FycmF5UGF0dGVybic7XG5jb25zdCBUU19JTlRFUkZBQ0VfREVDTEFSQVRJT04gPSAnVFNJbnRlcmZhY2VEZWNsYXJhdGlvbic7XG5jb25zdCBUU19UWVBFX0FMSUFTX0RFQ0xBUkFUSU9OID0gJ1RTVHlwZUFsaWFzRGVjbGFyYXRpb24nO1xuY29uc3QgVFNfRU5VTV9ERUNMQVJBVElPTiA9ICdUU0VudW1EZWNsYXJhdGlvbic7XG5jb25zdCBERUZBVUxUID0gJ2RlZmF1bHQnO1xuXG5mdW5jdGlvbiBmb3JFYWNoRGVjbGFyYXRpb25JZGVudGlmaWVyKGRlY2xhcmF0aW9uLCBjYikge1xuICBpZiAoZGVjbGFyYXRpb24pIHtcbiAgICBjb25zdCBpc1R5cGVEZWNsYXJhdGlvbiA9IGRlY2xhcmF0aW9uLnR5cGUgPT09IFRTX0lOVEVSRkFDRV9ERUNMQVJBVElPTlxuICAgICAgfHwgZGVjbGFyYXRpb24udHlwZSA9PT0gVFNfVFlQRV9BTElBU19ERUNMQVJBVElPTlxuICAgICAgfHwgZGVjbGFyYXRpb24udHlwZSA9PT0gVFNfRU5VTV9ERUNMQVJBVElPTjtcblxuICAgIGlmIChcbiAgICAgIGRlY2xhcmF0aW9uLnR5cGUgPT09IEZVTkNUSU9OX0RFQ0xBUkFUSU9OXG4gICAgICB8fCBkZWNsYXJhdGlvbi50eXBlID09PSBDTEFTU19ERUNMQVJBVElPTlxuICAgICAgfHwgaXNUeXBlRGVjbGFyYXRpb25cbiAgICApIHtcbiAgICAgIGNiKGRlY2xhcmF0aW9uLmlkLm5hbWUsIGlzVHlwZURlY2xhcmF0aW9uKTtcbiAgICB9IGVsc2UgaWYgKGRlY2xhcmF0aW9uLnR5cGUgPT09IFZBUklBQkxFX0RFQ0xBUkFUSU9OKSB7XG4gICAgICBkZWNsYXJhdGlvbi5kZWNsYXJhdGlvbnMuZm9yRWFjaCgoeyBpZCB9KSA9PiB7XG4gICAgICAgIGlmIChpZC50eXBlID09PSBPQkpFQ1RfUEFUVEVSTikge1xuICAgICAgICAgIHJlY3Vyc2l2ZVBhdHRlcm5DYXB0dXJlKGlkLCAocGF0dGVybikgPT4ge1xuICAgICAgICAgICAgaWYgKHBhdHRlcm4udHlwZSA9PT0gSURFTlRJRklFUikge1xuICAgICAgICAgICAgICBjYihwYXR0ZXJuLm5hbWUsIGZhbHNlKTtcbiAgICAgICAgICAgIH1cbiAgICAgICAgICB9KTtcbiAgICAgICAgfSBlbHNlIGlmIChpZC50eXBlID09PSBBUlJBWV9QQVRURVJOKSB7XG4gICAgICAgICAgaWQuZWxlbWVudHMuZm9yRWFjaCgoeyBuYW1lIH0pID0+IHtcbiAgICAgICAgICAgIGNiKG5hbWUsIGZhbHNlKTtcbiAgICAgICAgICB9KTtcbiAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICBjYihpZC5uYW1lLCBmYWxzZSk7XG4gICAgICAgIH1cbiAgICAgIH0pO1xuICAgIH1cbiAgfVxufVxuXG4vKipcbiAqIExpc3Qgb2YgaW1wb3J0cyBwZXIgZmlsZS5cbiAqXG4gKiBSZXByZXNlbnRlZCBieSBhIHR3by1sZXZlbCBNYXAgdG8gYSBTZXQgb2YgaWRlbnRpZmllcnMuIFRoZSB1cHBlci1sZXZlbCBNYXBcbiAqIGtleXMgYXJlIHRoZSBwYXRocyB0byB0aGUgbW9kdWxlcyBjb250YWluaW5nIHRoZSBpbXBvcnRzLCB3aGlsZSB0aGVcbiAqIGxvd2VyLWxldmVsIE1hcCBrZXlzIGFyZSB0aGUgcGF0aHMgdG8gdGhlIGZpbGVzIHdoaWNoIGFyZSBiZWluZyBpbXBvcnRlZFxuICogZnJvbS4gTGFzdGx5LCB0aGUgU2V0IG9mIGlkZW50aWZpZXJzIGNvbnRhaW5zIGVpdGhlciBuYW1lcyBiZWluZyBpbXBvcnRlZFxuICogb3IgYSBzcGVjaWFsIEFTVCBub2RlIG5hbWUgbGlzdGVkIGFib3ZlIChlLmcgSW1wb3J0RGVmYXVsdFNwZWNpZmllcikuXG4gKlxuICogRm9yIGV4YW1wbGUsIGlmIHdlIGhhdmUgYSBmaWxlIG5hbWVkIGZvby5qcyBjb250YWluaW5nOlxuICpcbiAqICAgaW1wb3J0IHsgbzIgfSBmcm9tICcuL2Jhci5qcyc7XG4gKlxuICogVGhlbiB3ZSB3aWxsIGhhdmUgYSBzdHJ1Y3R1cmUgdGhhdCBsb29rcyBsaWtlOlxuICpcbiAqICAgTWFwIHsgJ2Zvby5qcycgPT4gTWFwIHsgJ2Jhci5qcycgPT4gU2V0IHsgJ28yJyB9IH0gfVxuICpcbiAqIEB0eXBlIHtNYXA8c3RyaW5nLCBNYXA8c3RyaW5nLCBTZXQ8c3RyaW5nPj4+fVxuICovXG5jb25zdCBpbXBvcnRMaXN0ID0gbmV3IE1hcCgpO1xuXG4vKipcbiAqIExpc3Qgb2YgZXhwb3J0cyBwZXIgZmlsZS5cbiAqXG4gKiBSZXByZXNlbnRlZCBieSBhIHR3by1sZXZlbCBNYXAgdG8gYW4gb2JqZWN0IG9mIG1ldGFkYXRhLiBUaGUgdXBwZXItbGV2ZWwgTWFwXG4gKiBrZXlzIGFyZSB0aGUgcGF0aHMgdG8gdGhlIG1vZHVsZXMgY29udGFpbmluZyB0aGUgZXhwb3J0cywgd2hpbGUgdGhlXG4gKiBsb3dlci1sZXZlbCBNYXAga2V5cyBhcmUgdGhlIHNwZWNpZmljIGlkZW50aWZpZXJzIG9yIHNwZWNpYWwgQVNUIG5vZGUgbmFtZXNcbiAqIGJlaW5nIGV4cG9ydGVkLiBUaGUgbGVhZi1sZXZlbCBtZXRhZGF0YSBvYmplY3QgYXQgdGhlIG1vbWVudCBvbmx5IGNvbnRhaW5zIGFcbiAqIGB3aGVyZVVzZWRgIHByb3BlcnR5LCB3aGljaCBjb250YWlucyBhIFNldCBvZiBwYXRocyB0byBtb2R1bGVzIHRoYXQgaW1wb3J0XG4gKiB0aGUgbmFtZS5cbiAqXG4gKiBGb3IgZXhhbXBsZSwgaWYgd2UgaGF2ZSBhIGZpbGUgbmFtZWQgYmFyLmpzIGNvbnRhaW5pbmcgdGhlIGZvbGxvd2luZyBleHBvcnRzOlxuICpcbiAqICAgY29uc3QgbzIgPSAnYmFyJztcbiAqICAgZXhwb3J0IHsgbzIgfTtcbiAqXG4gKiBBbmQgYSBmaWxlIG5hbWVkIGZvby5qcyBjb250YWluaW5nIHRoZSBmb2xsb3dpbmcgaW1wb3J0OlxuICpcbiAqICAgaW1wb3J0IHsgbzIgfSBmcm9tICcuL2Jhci5qcyc7XG4gKlxuICogVGhlbiB3ZSB3aWxsIGhhdmUgYSBzdHJ1Y3R1cmUgdGhhdCBsb29rcyBsaWtlOlxuICpcbiAqICAgTWFwIHsgJ2Jhci5qcycgPT4gTWFwIHsgJ28yJyA9PiB7IHdoZXJlVXNlZDogU2V0IHsgJ2Zvby5qcycgfSB9IH0gfVxuICpcbiAqIEB0eXBlIHtNYXA8c3RyaW5nLCBNYXA8c3RyaW5nLCBvYmplY3Q+Pn1cbiAqL1xuY29uc3QgZXhwb3J0TGlzdCA9IG5ldyBNYXAoKTtcblxuY29uc3QgdmlzaXRvcktleU1hcCA9IG5ldyBNYXAoKTtcblxuLyoqIEB0eXBlIHtTZXQ8c3RyaW5nPn0gKi9cbmNvbnN0IGlnbm9yZWRGaWxlcyA9IG5ldyBTZXQoKTtcbmNvbnN0IGZpbGVzT3V0c2lkZVNyYyA9IG5ldyBTZXQoKTtcblxuY29uc3QgaXNOb2RlTW9kdWxlID0gKHBhdGgpID0+ICgvXFwvKG5vZGVfbW9kdWxlcylcXC8vKS50ZXN0KHBhdGgpO1xuXG4vKipcbiAqIHJlYWQgYWxsIGZpbGVzIG1hdGNoaW5nIHRoZSBwYXR0ZXJucyBpbiBzcmMgYW5kIGlnbm9yZUV4cG9ydHNcbiAqXG4gKiByZXR1cm4gYWxsIGZpbGVzIG1hdGNoaW5nIHNyYyBwYXR0ZXJuLCB3aGljaCBhcmUgbm90IG1hdGNoaW5nIHRoZSBpZ25vcmVFeHBvcnRzIHBhdHRlcm5cbiAqIEB0eXBlIHsoc3JjOiBzdHJpbmcsIGlnbm9yZUV4cG9ydHM6IHN0cmluZywgY29udGV4dDogaW1wb3J0KCdlc2xpbnQnKS5SdWxlLlJ1bGVDb250ZXh0KSA9PiBTZXQ8c3RyaW5nPn1cbiAqL1xuZnVuY3Rpb24gcmVzb2x2ZUZpbGVzKHNyYywgaWdub3JlRXhwb3J0cywgY29udGV4dCkge1xuICBjb25zdCBleHRlbnNpb25zID0gQXJyYXkuZnJvbShnZXRGaWxlRXh0ZW5zaW9ucyhjb250ZXh0LnNldHRpbmdzKSk7XG5cbiAgY29uc3Qgc3JjRmlsZUxpc3QgPSBsaXN0RmlsZXNUb1Byb2Nlc3Moc3JjLCBleHRlbnNpb25zLCBjb250ZXh0KTtcblxuICAvLyBwcmVwYXJlIGxpc3Qgb2YgaWdub3JlZCBmaWxlc1xuICBjb25zdCBpZ25vcmVkRmlsZXNMaXN0ID0gbGlzdEZpbGVzVG9Qcm9jZXNzKGlnbm9yZUV4cG9ydHMsIGV4dGVuc2lvbnMsIGNvbnRleHQpO1xuXG4gIC8vIFRoZSBtb2Rlcm4gYXBpIHdpbGwgcmV0dXJuIGEgbGlzdCBvZiBmaWxlIHBhdGhzLCByYXRoZXIgdGhhbiBhbiBvYmplY3RcbiAgaWYgKGlnbm9yZWRGaWxlc0xpc3QubGVuZ3RoICYmIHR5cGVvZiBpZ25vcmVkRmlsZXNMaXN0WzBdID09PSAnc3RyaW5nJykge1xuICAgIGlnbm9yZWRGaWxlc0xpc3QuZm9yRWFjaCgoZmlsZW5hbWUpID0+IGlnbm9yZWRGaWxlcy5hZGQoZmlsZW5hbWUpKTtcbiAgfSBlbHNlIHtcbiAgICBpZ25vcmVkRmlsZXNMaXN0LmZvckVhY2goKHsgZmlsZW5hbWUgfSkgPT4gaWdub3JlZEZpbGVzLmFkZChmaWxlbmFtZSkpO1xuICB9XG5cbiAgLy8gcHJlcGFyZSBsaXN0IG9mIHNvdXJjZSBmaWxlcywgZG9uJ3QgY29uc2lkZXIgZmlsZXMgZnJvbSBub2RlX21vZHVsZXNcbiAgY29uc3QgcmVzb2x2ZWRGaWxlcyA9IHNyY0ZpbGVMaXN0Lmxlbmd0aCAmJiB0eXBlb2Ygc3JjRmlsZUxpc3RbMF0gPT09ICdzdHJpbmcnXG4gICAgPyBzcmNGaWxlTGlzdC5maWx0ZXIoKGZpbGVQYXRoKSA9PiAhaXNOb2RlTW9kdWxlKGZpbGVQYXRoKSlcbiAgICA6IGZsYXRNYXAoc3JjRmlsZUxpc3QsICh7IGZpbGVuYW1lIH0pID0+IGlzTm9kZU1vZHVsZShmaWxlbmFtZSkgPyBbXSA6IGZpbGVuYW1lKTtcblxuICByZXR1cm4gbmV3IFNldChyZXNvbHZlZEZpbGVzKTtcbn1cblxuLyoqXG4gKiBwYXJzZSBhbGwgc291cmNlIGZpbGVzIGFuZCBidWlsZCB1cCAyIG1hcHMgY29udGFpbmluZyB0aGUgZXhpc3RpbmcgaW1wb3J0cyBhbmQgZXhwb3J0c1xuICovXG5jb25zdCBwcmVwYXJlSW1wb3J0c0FuZEV4cG9ydHMgPSAoc3JjRmlsZXMsIGNvbnRleHQpID0+IHtcbiAgY29uc3QgZXhwb3J0QWxsID0gbmV3IE1hcCgpO1xuICBzcmNGaWxlcy5mb3JFYWNoKChmaWxlKSA9PiB7XG4gICAgY29uc3QgZXhwb3J0cyA9IG5ldyBNYXAoKTtcbiAgICBjb25zdCBpbXBvcnRzID0gbmV3IE1hcCgpO1xuICAgIGNvbnN0IGN1cnJlbnRFeHBvcnRzID0gRXhwb3J0TWFwQnVpbGRlci5nZXQoZmlsZSwgY29udGV4dCk7XG4gICAgaWYgKGN1cnJlbnRFeHBvcnRzKSB7XG4gICAgICBjb25zdCB7XG4gICAgICAgIGRlcGVuZGVuY2llcyxcbiAgICAgICAgcmVleHBvcnRzLFxuICAgICAgICBpbXBvcnRzOiBsb2NhbEltcG9ydExpc3QsXG4gICAgICAgIG5hbWVzcGFjZSxcbiAgICAgICAgdmlzaXRvcktleXMsXG4gICAgICB9ID0gY3VycmVudEV4cG9ydHM7XG5cbiAgICAgIHZpc2l0b3JLZXlNYXAuc2V0KGZpbGUsIHZpc2l0b3JLZXlzKTtcbiAgICAgIC8vIGRlcGVuZGVuY2llcyA9PT0gZXhwb3J0ICogZnJvbVxuICAgICAgY29uc3QgY3VycmVudEV4cG9ydEFsbCA9IG5ldyBTZXQoKTtcbiAgICAgIGRlcGVuZGVuY2llcy5mb3JFYWNoKChnZXREZXBlbmRlbmN5KSA9PiB7XG4gICAgICAgIGNvbnN0IGRlcGVuZGVuY3kgPSBnZXREZXBlbmRlbmN5KCk7XG4gICAgICAgIGlmIChkZXBlbmRlbmN5ID09PSBudWxsKSB7XG4gICAgICAgICAgcmV0dXJuO1xuICAgICAgICB9XG5cbiAgICAgICAgY3VycmVudEV4cG9ydEFsbC5hZGQoZGVwZW5kZW5jeS5wYXRoKTtcbiAgICAgIH0pO1xuICAgICAgZXhwb3J0QWxsLnNldChmaWxlLCBjdXJyZW50RXhwb3J0QWxsKTtcblxuICAgICAgcmVleHBvcnRzLmZvckVhY2goKHZhbHVlLCBrZXkpID0+IHtcbiAgICAgICAgaWYgKGtleSA9PT0gREVGQVVMVCkge1xuICAgICAgICAgIGV4cG9ydHMuc2V0KElNUE9SVF9ERUZBVUxUX1NQRUNJRklFUiwgeyB3aGVyZVVzZWQ6IG5ldyBTZXQoKSB9KTtcbiAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICBleHBvcnRzLnNldChrZXksIHsgd2hlcmVVc2VkOiBuZXcgU2V0KCkgfSk7XG4gICAgICAgIH1cbiAgICAgICAgY29uc3QgcmVleHBvcnQgPSB2YWx1ZS5nZXRJbXBvcnQoKTtcbiAgICAgICAgaWYgKCFyZWV4cG9ydCkge1xuICAgICAgICAgIHJldHVybjtcbiAgICAgICAgfVxuICAgICAgICBsZXQgbG9jYWxJbXBvcnQgPSBpbXBvcnRzLmdldChyZWV4cG9ydC5wYXRoKTtcbiAgICAgICAgbGV0IGN1cnJlbnRWYWx1ZTtcbiAgICAgICAgaWYgKHZhbHVlLmxvY2FsID09PSBERUZBVUxUKSB7XG4gICAgICAgICAgY3VycmVudFZhbHVlID0gSU1QT1JUX0RFRkFVTFRfU1BFQ0lGSUVSO1xuICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgIGN1cnJlbnRWYWx1ZSA9IHZhbHVlLmxvY2FsO1xuICAgICAgICB9XG4gICAgICAgIGlmICh0eXBlb2YgbG9jYWxJbXBvcnQgIT09ICd1bmRlZmluZWQnKSB7XG4gICAgICAgICAgbG9jYWxJbXBvcnQgPSBuZXcgU2V0KFsuLi5sb2NhbEltcG9ydCwgY3VycmVudFZhbHVlXSk7XG4gICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgbG9jYWxJbXBvcnQgPSBuZXcgU2V0KFtjdXJyZW50VmFsdWVdKTtcbiAgICAgICAgfVxuICAgICAgICBpbXBvcnRzLnNldChyZWV4cG9ydC5wYXRoLCBsb2NhbEltcG9ydCk7XG4gICAgICB9KTtcblxuICAgICAgbG9jYWxJbXBvcnRMaXN0LmZvckVhY2goKHZhbHVlLCBrZXkpID0+IHtcbiAgICAgICAgaWYgKGlzTm9kZU1vZHVsZShrZXkpKSB7XG4gICAgICAgICAgcmV0dXJuO1xuICAgICAgICB9XG4gICAgICAgIGNvbnN0IGxvY2FsSW1wb3J0ID0gaW1wb3J0cy5nZXQoa2V5KSB8fCBuZXcgU2V0KCk7XG4gICAgICAgIHZhbHVlLmRlY2xhcmF0aW9ucy5mb3JFYWNoKCh7IGltcG9ydGVkU3BlY2lmaWVycyB9KSA9PiB7XG4gICAgICAgICAgaW1wb3J0ZWRTcGVjaWZpZXJzLmZvckVhY2goKHNwZWNpZmllcikgPT4ge1xuICAgICAgICAgICAgbG9jYWxJbXBvcnQuYWRkKHNwZWNpZmllcik7XG4gICAgICAgICAgfSk7XG4gICAgICAgIH0pO1xuICAgICAgICBpbXBvcnRzLnNldChrZXksIGxvY2FsSW1wb3J0KTtcbiAgICAgIH0pO1xuICAgICAgaW1wb3J0TGlzdC5zZXQoZmlsZSwgaW1wb3J0cyk7XG5cbiAgICAgIC8vIGJ1aWxkIHVwIGV4cG9ydCBsaXN0IG9ubHksIGlmIGZpbGUgaXMgbm90IGlnbm9yZWRcbiAgICAgIGlmIChpZ25vcmVkRmlsZXMuaGFzKGZpbGUpKSB7XG4gICAgICAgIHJldHVybjtcbiAgICAgIH1cbiAgICAgIG5hbWVzcGFjZS5mb3JFYWNoKCh2YWx1ZSwga2V5KSA9PiB7XG4gICAgICAgIGlmIChrZXkgPT09IERFRkFVTFQpIHtcbiAgICAgICAgICBleHBvcnRzLnNldChJTVBPUlRfREVGQVVMVF9TUEVDSUZJRVIsIHsgd2hlcmVVc2VkOiBuZXcgU2V0KCkgfSk7XG4gICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgZXhwb3J0cy5zZXQoa2V5LCB7IHdoZXJlVXNlZDogbmV3IFNldCgpIH0pO1xuICAgICAgICB9XG4gICAgICB9KTtcbiAgICB9XG4gICAgZXhwb3J0cy5zZXQoRVhQT1JUX0FMTF9ERUNMQVJBVElPTiwgeyB3aGVyZVVzZWQ6IG5ldyBTZXQoKSB9KTtcbiAgICBleHBvcnRzLnNldChJTVBPUlRfTkFNRVNQQUNFX1NQRUNJRklFUiwgeyB3aGVyZVVzZWQ6IG5ldyBTZXQoKSB9KTtcbiAgICBleHBvcnRMaXN0LnNldChmaWxlLCBleHBvcnRzKTtcbiAgfSk7XG4gIGV4cG9ydEFsbC5mb3JFYWNoKCh2YWx1ZSwga2V5KSA9PiB7XG4gICAgdmFsdWUuZm9yRWFjaCgodmFsKSA9PiB7XG4gICAgICBjb25zdCBjdXJyZW50RXhwb3J0cyA9IGV4cG9ydExpc3QuZ2V0KHZhbCk7XG4gICAgICBpZiAoY3VycmVudEV4cG9ydHMpIHtcbiAgICAgICAgY29uc3QgY3VycmVudEV4cG9ydCA9IGN1cnJlbnRFeHBvcnRzLmdldChFWFBPUlRfQUxMX0RFQ0xBUkFUSU9OKTtcbiAgICAgICAgY3VycmVudEV4cG9ydC53aGVyZVVzZWQuYWRkKGtleSk7XG4gICAgICB9XG4gICAgfSk7XG4gIH0pO1xufTtcblxuLyoqXG4gKiB0cmF2ZXJzZSB0aHJvdWdoIGFsbCBpbXBvcnRzIGFuZCBhZGQgdGhlIHJlc3BlY3RpdmUgcGF0aCB0byB0aGUgd2hlcmVVc2VkLWxpc3RcbiAqIG9mIHRoZSBjb3JyZXNwb25kaW5nIGV4cG9ydFxuICovXG5jb25zdCBkZXRlcm1pbmVVc2FnZSA9ICgpID0+IHtcbiAgaW1wb3J0TGlzdC5mb3JFYWNoKChsaXN0VmFsdWUsIGxpc3RLZXkpID0+IHtcbiAgICBsaXN0VmFsdWUuZm9yRWFjaCgodmFsdWUsIGtleSkgPT4ge1xuICAgICAgY29uc3QgZXhwb3J0cyA9IGV4cG9ydExpc3QuZ2V0KGtleSk7XG4gICAgICBpZiAodHlwZW9mIGV4cG9ydHMgIT09ICd1bmRlZmluZWQnKSB7XG4gICAgICAgIHZhbHVlLmZvckVhY2goKGN1cnJlbnRJbXBvcnQpID0+IHtcbiAgICAgICAgICBsZXQgc3BlY2lmaWVyO1xuICAgICAgICAgIGlmIChjdXJyZW50SW1wb3J0ID09PSBJTVBPUlRfTkFNRVNQQUNFX1NQRUNJRklFUikge1xuICAgICAgICAgICAgc3BlY2lmaWVyID0gSU1QT1JUX05BTUVTUEFDRV9TUEVDSUZJRVI7XG4gICAgICAgICAgfSBlbHNlIGlmIChjdXJyZW50SW1wb3J0ID09PSBJTVBPUlRfREVGQVVMVF9TUEVDSUZJRVIpIHtcbiAgICAgICAgICAgIHNwZWNpZmllciA9IElNUE9SVF9ERUZBVUxUX1NQRUNJRklFUjtcbiAgICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgICAgc3BlY2lmaWVyID0gY3VycmVudEltcG9ydDtcbiAgICAgICAgICB9XG4gICAgICAgICAgaWYgKHR5cGVvZiBzcGVjaWZpZXIgIT09ICd1bmRlZmluZWQnKSB7XG4gICAgICAgICAgICBjb25zdCBleHBvcnRTdGF0ZW1lbnQgPSBleHBvcnRzLmdldChzcGVjaWZpZXIpO1xuICAgICAgICAgICAgaWYgKHR5cGVvZiBleHBvcnRTdGF0ZW1lbnQgIT09ICd1bmRlZmluZWQnKSB7XG4gICAgICAgICAgICAgIGNvbnN0IHsgd2hlcmVVc2VkIH0gPSBleHBvcnRTdGF0ZW1lbnQ7XG4gICAgICAgICAgICAgIHdoZXJlVXNlZC5hZGQobGlzdEtleSk7XG4gICAgICAgICAgICAgIGV4cG9ydHMuc2V0KHNwZWNpZmllciwgeyB3aGVyZVVzZWQgfSk7XG4gICAgICAgICAgICB9XG4gICAgICAgICAgfVxuICAgICAgICB9KTtcbiAgICAgIH1cbiAgICB9KTtcbiAgfSk7XG59O1xuXG5jb25zdCBnZXRTcmMgPSAoc3JjKSA9PiB7XG4gIGlmIChzcmMpIHtcbiAgICByZXR1cm4gc3JjO1xuICB9XG4gIHJldHVybiBbcHJvY2Vzcy5jd2QoKV07XG59O1xuXG4vKipcbiAqIHByZXBhcmUgdGhlIGxpc3RzIG9mIGV4aXN0aW5nIGltcG9ydHMgYW5kIGV4cG9ydHMgLSBzaG91bGQgb25seSBiZSBleGVjdXRlZCBvbmNlIGF0XG4gKiB0aGUgc3RhcnQgb2YgYSBuZXcgZXNsaW50IHJ1blxuICovXG4vKiogQHR5cGUge1NldDxzdHJpbmc+fSAqL1xubGV0IHNyY0ZpbGVzO1xubGV0IGxhc3RQcmVwYXJlS2V5O1xuY29uc3QgZG9QcmVwYXJhdGlvbiA9IChzcmMsIGlnbm9yZUV4cG9ydHMsIGNvbnRleHQpID0+IHtcbiAgY29uc3QgcHJlcGFyZUtleSA9IEpTT04uc3RyaW5naWZ5KHtcbiAgICBzcmM6IChzcmMgfHwgW10pLnNvcnQoKSxcbiAgICBpZ25vcmVFeHBvcnRzOiAoaWdub3JlRXhwb3J0cyB8fCBbXSkuc29ydCgpLFxuICAgIGV4dGVuc2lvbnM6IEFycmF5LmZyb20oZ2V0RmlsZUV4dGVuc2lvbnMoY29udGV4dC5zZXR0aW5ncykpLnNvcnQoKSxcbiAgfSk7XG4gIGlmIChwcmVwYXJlS2V5ID09PSBsYXN0UHJlcGFyZUtleSkge1xuICAgIHJldHVybjtcbiAgfVxuXG4gIGltcG9ydExpc3QuY2xlYXIoKTtcbiAgZXhwb3J0TGlzdC5jbGVhcigpO1xuICBpZ25vcmVkRmlsZXMuY2xlYXIoKTtcbiAgZmlsZXNPdXRzaWRlU3JjLmNsZWFyKCk7XG5cbiAgc3JjRmlsZXMgPSByZXNvbHZlRmlsZXMoZ2V0U3JjKHNyYyksIGlnbm9yZUV4cG9ydHMsIGNvbnRleHQpO1xuICBwcmVwYXJlSW1wb3J0c0FuZEV4cG9ydHMoc3JjRmlsZXMsIGNvbnRleHQpO1xuICBkZXRlcm1pbmVVc2FnZSgpO1xuICBsYXN0UHJlcGFyZUtleSA9IHByZXBhcmVLZXk7XG59O1xuXG5jb25zdCBuZXdOYW1lc3BhY2VJbXBvcnRFeGlzdHMgPSAoc3BlY2lmaWVycykgPT4gc3BlY2lmaWVycy5zb21lKCh7IHR5cGUgfSkgPT4gdHlwZSA9PT0gSU1QT1JUX05BTUVTUEFDRV9TUEVDSUZJRVIpO1xuXG5jb25zdCBuZXdEZWZhdWx0SW1wb3J0RXhpc3RzID0gKHNwZWNpZmllcnMpID0+IHNwZWNpZmllcnMuc29tZSgoeyB0eXBlIH0pID0+IHR5cGUgPT09IElNUE9SVF9ERUZBVUxUX1NQRUNJRklFUik7XG5cbmNvbnN0IGZpbGVJc0luUGtnID0gKGZpbGUpID0+IHtcbiAgY29uc3QgeyBwYXRoLCBwa2cgfSA9IHJlYWRQa2dVcCh7IGN3ZDogZmlsZSB9KTtcbiAgY29uc3QgYmFzZVBhdGggPSBkaXJuYW1lKHBhdGgpO1xuXG4gIGNvbnN0IGNoZWNrUGtnRmllbGRTdHJpbmcgPSAocGtnRmllbGQpID0+IHtcbiAgICBpZiAoam9pbihiYXNlUGF0aCwgcGtnRmllbGQpID09PSBmaWxlKSB7XG4gICAgICByZXR1cm4gdHJ1ZTtcbiAgICB9XG4gIH07XG5cbiAgY29uc3QgY2hlY2tQa2dGaWVsZE9iamVjdCA9IChwa2dGaWVsZCkgPT4ge1xuICAgIGNvbnN0IHBrZ0ZpZWxkRmlsZXMgPSBmbGF0TWFwKHZhbHVlcyhwa2dGaWVsZCksICh2YWx1ZSkgPT4gdHlwZW9mIHZhbHVlID09PSAnYm9vbGVhbicgPyBbXSA6IGpvaW4oYmFzZVBhdGgsIHZhbHVlKSk7XG5cbiAgICBpZiAoaW5jbHVkZXMocGtnRmllbGRGaWxlcywgZmlsZSkpIHtcbiAgICAgIHJldHVybiB0cnVlO1xuICAgIH1cbiAgfTtcblxuICBjb25zdCBjaGVja1BrZ0ZpZWxkID0gKHBrZ0ZpZWxkKSA9PiB7XG4gICAgaWYgKHR5cGVvZiBwa2dGaWVsZCA9PT0gJ3N0cmluZycpIHtcbiAgICAgIHJldHVybiBjaGVja1BrZ0ZpZWxkU3RyaW5nKHBrZ0ZpZWxkKTtcbiAgICB9XG5cbiAgICBpZiAodHlwZW9mIHBrZ0ZpZWxkID09PSAnb2JqZWN0Jykge1xuICAgICAgcmV0dXJuIGNoZWNrUGtnRmllbGRPYmplY3QocGtnRmllbGQpO1xuICAgIH1cbiAgfTtcblxuICBpZiAocGtnLnByaXZhdGUgPT09IHRydWUpIHtcbiAgICByZXR1cm4gZmFsc2U7XG4gIH1cblxuICBpZiAocGtnLmJpbikge1xuICAgIGlmIChjaGVja1BrZ0ZpZWxkKHBrZy5iaW4pKSB7XG4gICAgICByZXR1cm4gdHJ1ZTtcbiAgICB9XG4gIH1cblxuICBpZiAocGtnLmJyb3dzZXIpIHtcbiAgICBpZiAoY2hlY2tQa2dGaWVsZChwa2cuYnJvd3NlcikpIHtcbiAgICAgIHJldHVybiB0cnVlO1xuICAgIH1cbiAgfVxuXG4gIGlmIChwa2cubWFpbikge1xuICAgIGlmIChjaGVja1BrZ0ZpZWxkU3RyaW5nKHBrZy5tYWluKSkge1xuICAgICAgcmV0dXJuIHRydWU7XG4gICAgfVxuICB9XG5cbiAgcmV0dXJuIGZhbHNlO1xufTtcblxubW9kdWxlLmV4cG9ydHMgPSB7XG4gIG1ldGE6IHtcbiAgICB0eXBlOiAnc3VnZ2VzdGlvbicsXG4gICAgZG9jczoge1xuICAgICAgY2F0ZWdvcnk6ICdIZWxwZnVsIHdhcm5pbmdzJyxcbiAgICAgIGRlc2NyaXB0aW9uOiAnRm9yYmlkIG1vZHVsZXMgd2l0aG91dCBleHBvcnRzLCBvciBleHBvcnRzIHdpdGhvdXQgbWF0Y2hpbmcgaW1wb3J0IGluIGFub3RoZXIgbW9kdWxlLicsXG4gICAgICB1cmw6IGRvY3NVcmwoJ25vLXVudXNlZC1tb2R1bGVzJyksXG4gICAgfSxcbiAgICBzY2hlbWE6IFt7XG4gICAgICBwcm9wZXJ0aWVzOiB7XG4gICAgICAgIHNyYzoge1xuICAgICAgICAgIGRlc2NyaXB0aW9uOiAnZmlsZXMvcGF0aHMgdG8gYmUgYW5hbHl6ZWQgKG9ubHkgZm9yIHVudXNlZCBleHBvcnRzKScsXG4gICAgICAgICAgdHlwZTogJ2FycmF5JyxcbiAgICAgICAgICB1bmlxdWVJdGVtczogdHJ1ZSxcbiAgICAgICAgICBpdGVtczoge1xuICAgICAgICAgICAgdHlwZTogJ3N0cmluZycsXG4gICAgICAgICAgICBtaW5MZW5ndGg6IDEsXG4gICAgICAgICAgfSxcbiAgICAgICAgfSxcbiAgICAgICAgaWdub3JlRXhwb3J0czoge1xuICAgICAgICAgIGRlc2NyaXB0aW9uOiAnZmlsZXMvcGF0aHMgZm9yIHdoaWNoIHVudXNlZCBleHBvcnRzIHdpbGwgbm90IGJlIHJlcG9ydGVkIChlLmcgbW9kdWxlIGVudHJ5IHBvaW50cyknLFxuICAgICAgICAgIHR5cGU6ICdhcnJheScsXG4gICAgICAgICAgdW5pcXVlSXRlbXM6IHRydWUsXG4gICAgICAgICAgaXRlbXM6IHtcbiAgICAgICAgICAgIHR5cGU6ICdzdHJpbmcnLFxuICAgICAgICAgICAgbWluTGVuZ3RoOiAxLFxuICAgICAgICAgIH0sXG4gICAgICAgIH0sXG4gICAgICAgIG1pc3NpbmdFeHBvcnRzOiB7XG4gICAgICAgICAgZGVzY3JpcHRpb246ICdyZXBvcnQgbW9kdWxlcyB3aXRob3V0IGFueSBleHBvcnRzJyxcbiAgICAgICAgICB0eXBlOiAnYm9vbGVhbicsXG4gICAgICAgIH0sXG4gICAgICAgIHVudXNlZEV4cG9ydHM6IHtcbiAgICAgICAgICBkZXNjcmlwdGlvbjogJ3JlcG9ydCBleHBvcnRzIHdpdGhvdXQgYW55IHVzYWdlJyxcbiAgICAgICAgICB0eXBlOiAnYm9vbGVhbicsXG4gICAgICAgIH0sXG4gICAgICAgIGlnbm9yZVVudXNlZFR5cGVFeHBvcnRzOiB7XG4gICAgICAgICAgZGVzY3JpcHRpb246ICdpZ25vcmUgdHlwZSBleHBvcnRzIHdpdGhvdXQgYW55IHVzYWdlJyxcbiAgICAgICAgICB0eXBlOiAnYm9vbGVhbicsXG4gICAgICAgIH0sXG4gICAgICB9LFxuICAgICAgYW55T2Y6IFtcbiAgICAgICAge1xuICAgICAgICAgIHByb3BlcnRpZXM6IHtcbiAgICAgICAgICAgIHVudXNlZEV4cG9ydHM6IHsgZW51bTogW3RydWVdIH0sXG4gICAgICAgICAgICBzcmM6IHtcbiAgICAgICAgICAgICAgbWluSXRlbXM6IDEsXG4gICAgICAgICAgICB9LFxuICAgICAgICAgIH0sXG4gICAgICAgICAgcmVxdWlyZWQ6IFsndW51c2VkRXhwb3J0cyddLFxuICAgICAgICB9LFxuICAgICAgICB7XG4gICAgICAgICAgcHJvcGVydGllczoge1xuICAgICAgICAgICAgbWlzc2luZ0V4cG9ydHM6IHsgZW51bTogW3RydWVdIH0sXG4gICAgICAgICAgfSxcbiAgICAgICAgICByZXF1aXJlZDogWydtaXNzaW5nRXhwb3J0cyddLFxuICAgICAgICB9LFxuICAgICAgXSxcbiAgICB9XSxcbiAgfSxcblxuICBjcmVhdGUoY29udGV4dCkge1xuICAgIGNvbnN0IHtcbiAgICAgIHNyYyxcbiAgICAgIGlnbm9yZUV4cG9ydHMgPSBbXSxcbiAgICAgIG1pc3NpbmdFeHBvcnRzLFxuICAgICAgdW51c2VkRXhwb3J0cyxcbiAgICAgIGlnbm9yZVVudXNlZFR5cGVFeHBvcnRzLFxuICAgIH0gPSBjb250ZXh0Lm9wdGlvbnNbMF0gfHwge307XG5cbiAgICBpZiAodW51c2VkRXhwb3J0cykge1xuICAgICAgZG9QcmVwYXJhdGlvbihzcmMsIGlnbm9yZUV4cG9ydHMsIGNvbnRleHQpO1xuICAgIH1cblxuICAgIGNvbnN0IGZpbGUgPSBjb250ZXh0LmdldFBoeXNpY2FsRmlsZW5hbWUgPyBjb250ZXh0LmdldFBoeXNpY2FsRmlsZW5hbWUoKSA6IGNvbnRleHQuZ2V0RmlsZW5hbWUoKTtcblxuICAgIGNvbnN0IGNoZWNrRXhwb3J0UHJlc2VuY2UgPSAobm9kZSkgPT4ge1xuICAgICAgaWYgKCFtaXNzaW5nRXhwb3J0cykge1xuICAgICAgICByZXR1cm47XG4gICAgICB9XG5cbiAgICAgIGlmIChpZ25vcmVkRmlsZXMuaGFzKGZpbGUpKSB7XG4gICAgICAgIHJldHVybjtcbiAgICAgIH1cblxuICAgICAgY29uc3QgZXhwb3J0Q291bnQgPSBleHBvcnRMaXN0LmdldChmaWxlKTtcbiAgICAgIGNvbnN0IGV4cG9ydEFsbCA9IGV4cG9ydENvdW50LmdldChFWFBPUlRfQUxMX0RFQ0xBUkFUSU9OKTtcbiAgICAgIGNvbnN0IG5hbWVzcGFjZUltcG9ydHMgPSBleHBvcnRDb3VudC5nZXQoSU1QT1JUX05BTUVTUEFDRV9TUEVDSUZJRVIpO1xuXG4gICAgICBleHBvcnRDb3VudC5kZWxldGUoRVhQT1JUX0FMTF9ERUNMQVJBVElPTik7XG4gICAgICBleHBvcnRDb3VudC5kZWxldGUoSU1QT1JUX05BTUVTUEFDRV9TUEVDSUZJRVIpO1xuICAgICAgaWYgKGV4cG9ydENvdW50LnNpemUgPCAxKSB7XG4gICAgICAgIC8vIG5vZGUuYm9keVswXSA9PT0gJ3VuZGVmaW5lZCcgb25seSBoYXBwZW5zLCBpZiBldmVyeXRoaW5nIGlzIGNvbW1lbnRlZCBvdXQgaW4gdGhlIGZpbGVcbiAgICAgICAgLy8gYmVpbmcgbGludGVkXG4gICAgICAgIGNvbnRleHQucmVwb3J0KG5vZGUuYm9keVswXSA/IG5vZGUuYm9keVswXSA6IG5vZGUsICdObyBleHBvcnRzIGZvdW5kJyk7XG4gICAgICB9XG4gICAgICBleHBvcnRDb3VudC5zZXQoRVhQT1JUX0FMTF9ERUNMQVJBVElPTiwgZXhwb3J0QWxsKTtcbiAgICAgIGV4cG9ydENvdW50LnNldChJTVBPUlRfTkFNRVNQQUNFX1NQRUNJRklFUiwgbmFtZXNwYWNlSW1wb3J0cyk7XG4gICAgfTtcblxuICAgIGNvbnN0IGNoZWNrVXNhZ2UgPSAobm9kZSwgZXhwb3J0ZWRWYWx1ZSwgaXNUeXBlRXhwb3J0KSA9PiB7XG4gICAgICBpZiAoIXVudXNlZEV4cG9ydHMpIHtcbiAgICAgICAgcmV0dXJuO1xuICAgICAgfVxuXG4gICAgICBpZiAoaXNUeXBlRXhwb3J0ICYmIGlnbm9yZVVudXNlZFR5cGVFeHBvcnRzKSB7XG4gICAgICAgIHJldHVybjtcbiAgICAgIH1cblxuICAgICAgaWYgKGlnbm9yZWRGaWxlcy5oYXMoZmlsZSkpIHtcbiAgICAgICAgcmV0dXJuO1xuICAgICAgfVxuXG4gICAgICBpZiAoZmlsZUlzSW5Qa2coZmlsZSkpIHtcbiAgICAgICAgcmV0dXJuO1xuICAgICAgfVxuXG4gICAgICBpZiAoZmlsZXNPdXRzaWRlU3JjLmhhcyhmaWxlKSkge1xuICAgICAgICByZXR1cm47XG4gICAgICB9XG5cbiAgICAgIC8vIG1ha2Ugc3VyZSBmaWxlIHRvIGJlIGxpbnRlZCBpcyBpbmNsdWRlZCBpbiBzb3VyY2UgZmlsZXNcbiAgICAgIGlmICghc3JjRmlsZXMuaGFzKGZpbGUpKSB7XG4gICAgICAgIHNyY0ZpbGVzID0gcmVzb2x2ZUZpbGVzKGdldFNyYyhzcmMpLCBpZ25vcmVFeHBvcnRzLCBjb250ZXh0KTtcbiAgICAgICAgaWYgKCFzcmNGaWxlcy5oYXMoZmlsZSkpIHtcbiAgICAgICAgICBmaWxlc091dHNpZGVTcmMuYWRkKGZpbGUpO1xuICAgICAgICAgIHJldHVybjtcbiAgICAgICAgfVxuICAgICAgfVxuXG4gICAgICBleHBvcnRzID0gZXhwb3J0TGlzdC5nZXQoZmlsZSk7XG5cbiAgICAgIGlmICghZXhwb3J0cykge1xuICAgICAgICBjb25zb2xlLmVycm9yKGBmaWxlIFxcYCR7ZmlsZX1cXGAgaGFzIG5vIGV4cG9ydHMuIFBsZWFzZSB1cGRhdGUgdG8gdGhlIGxhdGVzdCwgYW5kIGlmIGl0IHN0aWxsIGhhcHBlbnMsIHJlcG9ydCB0aGlzIG9uIGh0dHBzOi8vZ2l0aHViLmNvbS9pbXBvcnQtanMvZXNsaW50LXBsdWdpbi1pbXBvcnQvaXNzdWVzLzI4NjYhYCk7XG4gICAgICB9XG5cbiAgICAgIC8vIHNwZWNpYWwgY2FzZTogZXhwb3J0ICogZnJvbVxuICAgICAgY29uc3QgZXhwb3J0QWxsID0gZXhwb3J0cy5nZXQoRVhQT1JUX0FMTF9ERUNMQVJBVElPTik7XG4gICAgICBpZiAodHlwZW9mIGV4cG9ydEFsbCAhPT0gJ3VuZGVmaW5lZCcgJiYgZXhwb3J0ZWRWYWx1ZSAhPT0gSU1QT1JUX0RFRkFVTFRfU1BFQ0lGSUVSKSB7XG4gICAgICAgIGlmIChleHBvcnRBbGwud2hlcmVVc2VkLnNpemUgPiAwKSB7XG4gICAgICAgICAgcmV0dXJuO1xuICAgICAgICB9XG4gICAgICB9XG5cbiAgICAgIC8vIHNwZWNpYWwgY2FzZTogbmFtZXNwYWNlIGltcG9ydFxuICAgICAgY29uc3QgbmFtZXNwYWNlSW1wb3J0cyA9IGV4cG9ydHMuZ2V0KElNUE9SVF9OQU1FU1BBQ0VfU1BFQ0lGSUVSKTtcbiAgICAgIGlmICh0eXBlb2YgbmFtZXNwYWNlSW1wb3J0cyAhPT0gJ3VuZGVmaW5lZCcpIHtcbiAgICAgICAgaWYgKG5hbWVzcGFjZUltcG9ydHMud2hlcmVVc2VkLnNpemUgPiAwKSB7XG4gICAgICAgICAgcmV0dXJuO1xuICAgICAgICB9XG4gICAgICB9XG5cbiAgICAgIC8vIGV4cG9ydHNMaXN0IHdpbGwgYWx3YXlzIG1hcCBhbnkgaW1wb3J0ZWQgdmFsdWUgb2YgJ2RlZmF1bHQnIHRvICdJbXBvcnREZWZhdWx0U3BlY2lmaWVyJ1xuICAgICAgY29uc3QgZXhwb3J0c0tleSA9IGV4cG9ydGVkVmFsdWUgPT09IERFRkFVTFQgPyBJTVBPUlRfREVGQVVMVF9TUEVDSUZJRVIgOiBleHBvcnRlZFZhbHVlO1xuXG4gICAgICBjb25zdCBleHBvcnRTdGF0ZW1lbnQgPSBleHBvcnRzLmdldChleHBvcnRzS2V5KTtcblxuICAgICAgY29uc3QgdmFsdWUgPSBleHBvcnRzS2V5ID09PSBJTVBPUlRfREVGQVVMVF9TUEVDSUZJRVIgPyBERUZBVUxUIDogZXhwb3J0c0tleTtcblxuICAgICAgaWYgKHR5cGVvZiBleHBvcnRTdGF0ZW1lbnQgIT09ICd1bmRlZmluZWQnKSB7XG4gICAgICAgIGlmIChleHBvcnRTdGF0ZW1lbnQud2hlcmVVc2VkLnNpemUgPCAxKSB7XG4gICAgICAgICAgY29udGV4dC5yZXBvcnQoXG4gICAgICAgICAgICBub2RlLFxuICAgICAgICAgICAgYGV4cG9ydGVkIGRlY2xhcmF0aW9uICcke3ZhbHVlfScgbm90IHVzZWQgd2l0aGluIG90aGVyIG1vZHVsZXNgLFxuICAgICAgICAgICk7XG4gICAgICAgIH1cbiAgICAgIH0gZWxzZSB7XG4gICAgICAgIGNvbnRleHQucmVwb3J0KFxuICAgICAgICAgIG5vZGUsXG4gICAgICAgICAgYGV4cG9ydGVkIGRlY2xhcmF0aW9uICcke3ZhbHVlfScgbm90IHVzZWQgd2l0aGluIG90aGVyIG1vZHVsZXNgLFxuICAgICAgICApO1xuICAgICAgfVxuICAgIH07XG5cbiAgICAvKipcbiAgICAgKiBvbmx5IHVzZWZ1bCBmb3IgdG9vbHMgbGlrZSB2c2NvZGUtZXNsaW50XG4gICAgICpcbiAgICAgKiB1cGRhdGUgbGlzdHMgb2YgZXhpc3RpbmcgZXhwb3J0cyBkdXJpbmcgcnVudGltZVxuICAgICAqL1xuICAgIGNvbnN0IHVwZGF0ZUV4cG9ydFVzYWdlID0gKG5vZGUpID0+IHtcbiAgICAgIGlmIChpZ25vcmVkRmlsZXMuaGFzKGZpbGUpKSB7XG4gICAgICAgIHJldHVybjtcbiAgICAgIH1cblxuICAgICAgbGV0IGV4cG9ydHMgPSBleHBvcnRMaXN0LmdldChmaWxlKTtcblxuICAgICAgLy8gbmV3IG1vZHVsZSBoYXMgYmVlbiBjcmVhdGVkIGR1cmluZyBydW50aW1lXG4gICAgICAvLyBpbmNsdWRlIGl0IGluIGZ1cnRoZXIgcHJvY2Vzc2luZ1xuICAgICAgaWYgKHR5cGVvZiBleHBvcnRzID09PSAndW5kZWZpbmVkJykge1xuICAgICAgICBleHBvcnRzID0gbmV3IE1hcCgpO1xuICAgICAgfVxuXG4gICAgICBjb25zdCBuZXdFeHBvcnRzID0gbmV3IE1hcCgpO1xuICAgICAgY29uc3QgbmV3RXhwb3J0SWRlbnRpZmllcnMgPSBuZXcgU2V0KCk7XG5cbiAgICAgIG5vZGUuYm9keS5mb3JFYWNoKCh7IHR5cGUsIGRlY2xhcmF0aW9uLCBzcGVjaWZpZXJzIH0pID0+IHtcbiAgICAgICAgaWYgKHR5cGUgPT09IEVYUE9SVF9ERUZBVUxUX0RFQ0xBUkFUSU9OKSB7XG4gICAgICAgICAgbmV3RXhwb3J0SWRlbnRpZmllcnMuYWRkKElNUE9SVF9ERUZBVUxUX1NQRUNJRklFUik7XG4gICAgICAgIH1cbiAgICAgICAgaWYgKHR5cGUgPT09IEVYUE9SVF9OQU1FRF9ERUNMQVJBVElPTikge1xuICAgICAgICAgIGlmIChzcGVjaWZpZXJzLmxlbmd0aCA+IDApIHtcbiAgICAgICAgICAgIHNwZWNpZmllcnMuZm9yRWFjaCgoc3BlY2lmaWVyKSA9PiB7XG4gICAgICAgICAgICAgIGlmIChzcGVjaWZpZXIuZXhwb3J0ZWQpIHtcbiAgICAgICAgICAgICAgICBuZXdFeHBvcnRJZGVudGlmaWVycy5hZGQoc3BlY2lmaWVyLmV4cG9ydGVkLm5hbWUgfHwgc3BlY2lmaWVyLmV4cG9ydGVkLnZhbHVlKTtcbiAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgfSk7XG4gICAgICAgICAgfVxuICAgICAgICAgIGZvckVhY2hEZWNsYXJhdGlvbklkZW50aWZpZXIoZGVjbGFyYXRpb24sIChuYW1lKSA9PiB7XG4gICAgICAgICAgICBuZXdFeHBvcnRJZGVudGlmaWVycy5hZGQobmFtZSk7XG4gICAgICAgICAgfSk7XG4gICAgICAgIH1cbiAgICAgIH0pO1xuXG4gICAgICAvLyBvbGQgZXhwb3J0cyBleGlzdCB3aXRoaW4gbGlzdCBvZiBuZXcgZXhwb3J0cyBpZGVudGlmaWVyczogYWRkIHRvIG1hcCBvZiBuZXcgZXhwb3J0c1xuICAgICAgZXhwb3J0cy5mb3JFYWNoKCh2YWx1ZSwga2V5KSA9PiB7XG4gICAgICAgIGlmIChuZXdFeHBvcnRJZGVudGlmaWVycy5oYXMoa2V5KSkge1xuICAgICAgICAgIG5ld0V4cG9ydHMuc2V0KGtleSwgdmFsdWUpO1xuICAgICAgICB9XG4gICAgICB9KTtcblxuICAgICAgLy8gbmV3IGV4cG9ydCBpZGVudGlmaWVycyBhZGRlZDogYWRkIHRvIG1hcCBvZiBuZXcgZXhwb3J0c1xuICAgICAgbmV3RXhwb3J0SWRlbnRpZmllcnMuZm9yRWFjaCgoa2V5KSA9PiB7XG4gICAgICAgIGlmICghZXhwb3J0cy5oYXMoa2V5KSkge1xuICAgICAgICAgIG5ld0V4cG9ydHMuc2V0KGtleSwgeyB3aGVyZVVzZWQ6IG5ldyBTZXQoKSB9KTtcbiAgICAgICAgfVxuICAgICAgfSk7XG5cbiAgICAgIC8vIHByZXNlcnZlIGluZm9ybWF0aW9uIGFib3V0IG5hbWVzcGFjZSBpbXBvcnRzXG4gICAgICBjb25zdCBleHBvcnRBbGwgPSBleHBvcnRzLmdldChFWFBPUlRfQUxMX0RFQ0xBUkFUSU9OKTtcbiAgICAgIGxldCBuYW1lc3BhY2VJbXBvcnRzID0gZXhwb3J0cy5nZXQoSU1QT1JUX05BTUVTUEFDRV9TUEVDSUZJRVIpO1xuXG4gICAgICBpZiAodHlwZW9mIG5hbWVzcGFjZUltcG9ydHMgPT09ICd1bmRlZmluZWQnKSB7XG4gICAgICAgIG5hbWVzcGFjZUltcG9ydHMgPSB7IHdoZXJlVXNlZDogbmV3IFNldCgpIH07XG4gICAgICB9XG5cbiAgICAgIG5ld0V4cG9ydHMuc2V0KEVYUE9SVF9BTExfREVDTEFSQVRJT04sIGV4cG9ydEFsbCk7XG4gICAgICBuZXdFeHBvcnRzLnNldChJTVBPUlRfTkFNRVNQQUNFX1NQRUNJRklFUiwgbmFtZXNwYWNlSW1wb3J0cyk7XG4gICAgICBleHBvcnRMaXN0LnNldChmaWxlLCBuZXdFeHBvcnRzKTtcbiAgICB9O1xuXG4gICAgLyoqXG4gICAgICogb25seSB1c2VmdWwgZm9yIHRvb2xzIGxpa2UgdnNjb2RlLWVzbGludFxuICAgICAqXG4gICAgICogdXBkYXRlIGxpc3RzIG9mIGV4aXN0aW5nIGltcG9ydHMgZHVyaW5nIHJ1bnRpbWVcbiAgICAgKi9cbiAgICBjb25zdCB1cGRhdGVJbXBvcnRVc2FnZSA9IChub2RlKSA9PiB7XG4gICAgICBpZiAoIXVudXNlZEV4cG9ydHMpIHtcbiAgICAgICAgcmV0dXJuO1xuICAgICAgfVxuXG4gICAgICBsZXQgb2xkSW1wb3J0UGF0aHMgPSBpbXBvcnRMaXN0LmdldChmaWxlKTtcbiAgICAgIGlmICh0eXBlb2Ygb2xkSW1wb3J0UGF0aHMgPT09ICd1bmRlZmluZWQnKSB7XG4gICAgICAgIG9sZEltcG9ydFBhdGhzID0gbmV3IE1hcCgpO1xuICAgICAgfVxuXG4gICAgICBjb25zdCBvbGROYW1lc3BhY2VJbXBvcnRzID0gbmV3IFNldCgpO1xuICAgICAgY29uc3QgbmV3TmFtZXNwYWNlSW1wb3J0cyA9IG5ldyBTZXQoKTtcblxuICAgICAgY29uc3Qgb2xkRXhwb3J0QWxsID0gbmV3IFNldCgpO1xuICAgICAgY29uc3QgbmV3RXhwb3J0QWxsID0gbmV3IFNldCgpO1xuXG4gICAgICBjb25zdCBvbGREZWZhdWx0SW1wb3J0cyA9IG5ldyBTZXQoKTtcbiAgICAgIGNvbnN0IG5ld0RlZmF1bHRJbXBvcnRzID0gbmV3IFNldCgpO1xuXG4gICAgICBjb25zdCBvbGRJbXBvcnRzID0gbmV3IE1hcCgpO1xuICAgICAgY29uc3QgbmV3SW1wb3J0cyA9IG5ldyBNYXAoKTtcbiAgICAgIG9sZEltcG9ydFBhdGhzLmZvckVhY2goKHZhbHVlLCBrZXkpID0+IHtcbiAgICAgICAgaWYgKHZhbHVlLmhhcyhFWFBPUlRfQUxMX0RFQ0xBUkFUSU9OKSkge1xuICAgICAgICAgIG9sZEV4cG9ydEFsbC5hZGQoa2V5KTtcbiAgICAgICAgfVxuICAgICAgICBpZiAodmFsdWUuaGFzKElNUE9SVF9OQU1FU1BBQ0VfU1BFQ0lGSUVSKSkge1xuICAgICAgICAgIG9sZE5hbWVzcGFjZUltcG9ydHMuYWRkKGtleSk7XG4gICAgICAgIH1cbiAgICAgICAgaWYgKHZhbHVlLmhhcyhJTVBPUlRfREVGQVVMVF9TUEVDSUZJRVIpKSB7XG4gICAgICAgICAgb2xkRGVmYXVsdEltcG9ydHMuYWRkKGtleSk7XG4gICAgICAgIH1cbiAgICAgICAgdmFsdWUuZm9yRWFjaCgodmFsKSA9PiB7XG4gICAgICAgICAgaWYgKFxuICAgICAgICAgICAgdmFsICE9PSBJTVBPUlRfTkFNRVNQQUNFX1NQRUNJRklFUlxuICAgICAgICAgICAgJiYgdmFsICE9PSBJTVBPUlRfREVGQVVMVF9TUEVDSUZJRVJcbiAgICAgICAgICApIHtcbiAgICAgICAgICAgIG9sZEltcG9ydHMuc2V0KHZhbCwga2V5KTtcbiAgICAgICAgICB9XG4gICAgICAgIH0pO1xuICAgICAgfSk7XG5cbiAgICAgIGZ1bmN0aW9uIHByb2Nlc3NEeW5hbWljSW1wb3J0KHNvdXJjZSkge1xuICAgICAgICBpZiAoc291cmNlLnR5cGUgIT09ICdMaXRlcmFsJykge1xuICAgICAgICAgIHJldHVybiBudWxsO1xuICAgICAgICB9XG4gICAgICAgIGNvbnN0IHAgPSByZXNvbHZlKHNvdXJjZS52YWx1ZSwgY29udGV4dCk7XG4gICAgICAgIGlmIChwID09IG51bGwpIHtcbiAgICAgICAgICByZXR1cm4gbnVsbDtcbiAgICAgICAgfVxuICAgICAgICBuZXdOYW1lc3BhY2VJbXBvcnRzLmFkZChwKTtcbiAgICAgIH1cblxuICAgICAgdmlzaXQobm9kZSwgdmlzaXRvcktleU1hcC5nZXQoZmlsZSksIHtcbiAgICAgICAgSW1wb3J0RXhwcmVzc2lvbihjaGlsZCkge1xuICAgICAgICAgIHByb2Nlc3NEeW5hbWljSW1wb3J0KGNoaWxkLnNvdXJjZSk7XG4gICAgICAgIH0sXG4gICAgICAgIENhbGxFeHByZXNzaW9uKGNoaWxkKSB7XG4gICAgICAgICAgaWYgKGNoaWxkLmNhbGxlZS50eXBlID09PSAnSW1wb3J0Jykge1xuICAgICAgICAgICAgcHJvY2Vzc0R5bmFtaWNJbXBvcnQoY2hpbGQuYXJndW1lbnRzWzBdKTtcbiAgICAgICAgICB9XG4gICAgICAgIH0sXG4gICAgICB9KTtcblxuICAgICAgbm9kZS5ib2R5LmZvckVhY2goKGFzdE5vZGUpID0+IHtcbiAgICAgICAgbGV0IHJlc29sdmVkUGF0aDtcblxuICAgICAgICAvLyBzdXBwb3J0IGZvciBleHBvcnQgeyB2YWx1ZSB9IGZyb20gJ21vZHVsZSdcbiAgICAgICAgaWYgKGFzdE5vZGUudHlwZSA9PT0gRVhQT1JUX05BTUVEX0RFQ0xBUkFUSU9OKSB7XG4gICAgICAgICAgaWYgKGFzdE5vZGUuc291cmNlKSB7XG4gICAgICAgICAgICByZXNvbHZlZFBhdGggPSByZXNvbHZlKGFzdE5vZGUuc291cmNlLnJhdy5yZXBsYWNlKC8oJ3xcIikvZywgJycpLCBjb250ZXh0KTtcbiAgICAgICAgICAgIGFzdE5vZGUuc3BlY2lmaWVycy5mb3JFYWNoKChzcGVjaWZpZXIpID0+IHtcbiAgICAgICAgICAgICAgY29uc3QgbmFtZSA9IHNwZWNpZmllci5sb2NhbC5uYW1lIHx8IHNwZWNpZmllci5sb2NhbC52YWx1ZTtcbiAgICAgICAgICAgICAgaWYgKG5hbWUgPT09IERFRkFVTFQpIHtcbiAgICAgICAgICAgICAgICBuZXdEZWZhdWx0SW1wb3J0cy5hZGQocmVzb2x2ZWRQYXRoKTtcbiAgICAgICAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICAgICAgICBuZXdJbXBvcnRzLnNldChuYW1lLCByZXNvbHZlZFBhdGgpO1xuICAgICAgICAgICAgICB9XG4gICAgICAgICAgICB9KTtcbiAgICAgICAgICB9XG4gICAgICAgIH1cblxuICAgICAgICBpZiAoYXN0Tm9kZS50eXBlID09PSBFWFBPUlRfQUxMX0RFQ0xBUkFUSU9OKSB7XG4gICAgICAgICAgcmVzb2x2ZWRQYXRoID0gcmVzb2x2ZShhc3ROb2RlLnNvdXJjZS5yYXcucmVwbGFjZSgvKCd8XCIpL2csICcnKSwgY29udGV4dCk7XG4gICAgICAgICAgbmV3RXhwb3J0QWxsLmFkZChyZXNvbHZlZFBhdGgpO1xuICAgICAgICB9XG5cbiAgICAgICAgaWYgKGFzdE5vZGUudHlwZSA9PT0gSU1QT1JUX0RFQ0xBUkFUSU9OKSB7XG4gICAgICAgICAgcmVzb2x2ZWRQYXRoID0gcmVzb2x2ZShhc3ROb2RlLnNvdXJjZS5yYXcucmVwbGFjZSgvKCd8XCIpL2csICcnKSwgY29udGV4dCk7XG4gICAgICAgICAgaWYgKCFyZXNvbHZlZFBhdGgpIHtcbiAgICAgICAgICAgIHJldHVybjtcbiAgICAgICAgICB9XG5cbiAgICAgICAgICBpZiAoaXNOb2RlTW9kdWxlKHJlc29sdmVkUGF0aCkpIHtcbiAgICAgICAgICAgIHJldHVybjtcbiAgICAgICAgICB9XG5cbiAgICAgICAgICBpZiAobmV3TmFtZXNwYWNlSW1wb3J0RXhpc3RzKGFzdE5vZGUuc3BlY2lmaWVycykpIHtcbiAgICAgICAgICAgIG5ld05hbWVzcGFjZUltcG9ydHMuYWRkKHJlc29sdmVkUGF0aCk7XG4gICAgICAgICAgfVxuXG4gICAgICAgICAgaWYgKG5ld0RlZmF1bHRJbXBvcnRFeGlzdHMoYXN0Tm9kZS5zcGVjaWZpZXJzKSkge1xuICAgICAgICAgICAgbmV3RGVmYXVsdEltcG9ydHMuYWRkKHJlc29sdmVkUGF0aCk7XG4gICAgICAgICAgfVxuXG4gICAgICAgICAgYXN0Tm9kZS5zcGVjaWZpZXJzXG4gICAgICAgICAgICAuZmlsdGVyKChzcGVjaWZpZXIpID0+IHNwZWNpZmllci50eXBlICE9PSBJTVBPUlRfREVGQVVMVF9TUEVDSUZJRVIgJiYgc3BlY2lmaWVyLnR5cGUgIT09IElNUE9SVF9OQU1FU1BBQ0VfU1BFQ0lGSUVSKVxuICAgICAgICAgICAgLmZvckVhY2goKHNwZWNpZmllcikgPT4ge1xuICAgICAgICAgICAgICBuZXdJbXBvcnRzLnNldChzcGVjaWZpZXIuaW1wb3J0ZWQubmFtZSB8fCBzcGVjaWZpZXIuaW1wb3J0ZWQudmFsdWUsIHJlc29sdmVkUGF0aCk7XG4gICAgICAgICAgICB9KTtcbiAgICAgICAgfVxuICAgICAgfSk7XG5cbiAgICAgIG5ld0V4cG9ydEFsbC5mb3JFYWNoKCh2YWx1ZSkgPT4ge1xuICAgICAgICBpZiAoIW9sZEV4cG9ydEFsbC5oYXModmFsdWUpKSB7XG4gICAgICAgICAgbGV0IGltcG9ydHMgPSBvbGRJbXBvcnRQYXRocy5nZXQodmFsdWUpO1xuICAgICAgICAgIGlmICh0eXBlb2YgaW1wb3J0cyA9PT0gJ3VuZGVmaW5lZCcpIHtcbiAgICAgICAgICAgIGltcG9ydHMgPSBuZXcgU2V0KCk7XG4gICAgICAgICAgfVxuICAgICAgICAgIGltcG9ydHMuYWRkKEVYUE9SVF9BTExfREVDTEFSQVRJT04pO1xuICAgICAgICAgIG9sZEltcG9ydFBhdGhzLnNldCh2YWx1ZSwgaW1wb3J0cyk7XG5cbiAgICAgICAgICBsZXQgZXhwb3J0cyA9IGV4cG9ydExpc3QuZ2V0KHZhbHVlKTtcbiAgICAgICAgICBsZXQgY3VycmVudEV4cG9ydDtcbiAgICAgICAgICBpZiAodHlwZW9mIGV4cG9ydHMgIT09ICd1bmRlZmluZWQnKSB7XG4gICAgICAgICAgICBjdXJyZW50RXhwb3J0ID0gZXhwb3J0cy5nZXQoRVhQT1JUX0FMTF9ERUNMQVJBVElPTik7XG4gICAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICAgIGV4cG9ydHMgPSBuZXcgTWFwKCk7XG4gICAgICAgICAgICBleHBvcnRMaXN0LnNldCh2YWx1ZSwgZXhwb3J0cyk7XG4gICAgICAgICAgfVxuXG4gICAgICAgICAgaWYgKHR5cGVvZiBjdXJyZW50RXhwb3J0ICE9PSAndW5kZWZpbmVkJykge1xuICAgICAgICAgICAgY3VycmVudEV4cG9ydC53aGVyZVVzZWQuYWRkKGZpbGUpO1xuICAgICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgICBjb25zdCB3aGVyZVVzZWQgPSBuZXcgU2V0KCk7XG4gICAgICAgICAgICB3aGVyZVVzZWQuYWRkKGZpbGUpO1xuICAgICAgICAgICAgZXhwb3J0cy5zZXQoRVhQT1JUX0FMTF9ERUNMQVJBVElPTiwgeyB3aGVyZVVzZWQgfSk7XG4gICAgICAgICAgfVxuICAgICAgICB9XG4gICAgICB9KTtcblxuICAgICAgb2xkRXhwb3J0QWxsLmZvckVhY2goKHZhbHVlKSA9PiB7XG4gICAgICAgIGlmICghbmV3RXhwb3J0QWxsLmhhcyh2YWx1ZSkpIHtcbiAgICAgICAgICBjb25zdCBpbXBvcnRzID0gb2xkSW1wb3J0UGF0aHMuZ2V0KHZhbHVlKTtcbiAgICAgICAgICBpbXBvcnRzLmRlbGV0ZShFWFBPUlRfQUxMX0RFQ0xBUkFUSU9OKTtcblxuICAgICAgICAgIGNvbnN0IGV4cG9ydHMgPSBleHBvcnRMaXN0LmdldCh2YWx1ZSk7XG4gICAgICAgICAgaWYgKHR5cGVvZiBleHBvcnRzICE9PSAndW5kZWZpbmVkJykge1xuICAgICAgICAgICAgY29uc3QgY3VycmVudEV4cG9ydCA9IGV4cG9ydHMuZ2V0KEVYUE9SVF9BTExfREVDTEFSQVRJT04pO1xuICAgICAgICAgICAgaWYgKHR5cGVvZiBjdXJyZW50RXhwb3J0ICE9PSAndW5kZWZpbmVkJykge1xuICAgICAgICAgICAgICBjdXJyZW50RXhwb3J0LndoZXJlVXNlZC5kZWxldGUoZmlsZSk7XG4gICAgICAgICAgICB9XG4gICAgICAgICAgfVxuICAgICAgICB9XG4gICAgICB9KTtcblxuICAgICAgbmV3RGVmYXVsdEltcG9ydHMuZm9yRWFjaCgodmFsdWUpID0+IHtcbiAgICAgICAgaWYgKCFvbGREZWZhdWx0SW1wb3J0cy5oYXModmFsdWUpKSB7XG4gICAgICAgICAgbGV0IGltcG9ydHMgPSBvbGRJbXBvcnRQYXRocy5nZXQodmFsdWUpO1xuICAgICAgICAgIGlmICh0eXBlb2YgaW1wb3J0cyA9PT0gJ3VuZGVmaW5lZCcpIHtcbiAgICAgICAgICAgIGltcG9ydHMgPSBuZXcgU2V0KCk7XG4gICAgICAgICAgfVxuICAgICAgICAgIGltcG9ydHMuYWRkKElNUE9SVF9ERUZBVUxUX1NQRUNJRklFUik7XG4gICAgICAgICAgb2xkSW1wb3J0UGF0aHMuc2V0KHZhbHVlLCBpbXBvcnRzKTtcblxuICAgICAgICAgIGxldCBleHBvcnRzID0gZXhwb3J0TGlzdC5nZXQodmFsdWUpO1xuICAgICAgICAgIGxldCBjdXJyZW50RXhwb3J0O1xuICAgICAgICAgIGlmICh0eXBlb2YgZXhwb3J0cyAhPT0gJ3VuZGVmaW5lZCcpIHtcbiAgICAgICAgICAgIGN1cnJlbnRFeHBvcnQgPSBleHBvcnRzLmdldChJTVBPUlRfREVGQVVMVF9TUEVDSUZJRVIpO1xuICAgICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgICBleHBvcnRzID0gbmV3IE1hcCgpO1xuICAgICAgICAgICAgZXhwb3J0TGlzdC5zZXQodmFsdWUsIGV4cG9ydHMpO1xuICAgICAgICAgIH1cblxuICAgICAgICAgIGlmICh0eXBlb2YgY3VycmVudEV4cG9ydCAhPT0gJ3VuZGVmaW5lZCcpIHtcbiAgICAgICAgICAgIGN1cnJlbnRFeHBvcnQud2hlcmVVc2VkLmFkZChmaWxlKTtcbiAgICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgICAgY29uc3Qgd2hlcmVVc2VkID0gbmV3IFNldCgpO1xuICAgICAgICAgICAgd2hlcmVVc2VkLmFkZChmaWxlKTtcbiAgICAgICAgICAgIGV4cG9ydHMuc2V0KElNUE9SVF9ERUZBVUxUX1NQRUNJRklFUiwgeyB3aGVyZVVzZWQgfSk7XG4gICAgICAgICAgfVxuICAgICAgICB9XG4gICAgICB9KTtcblxuICAgICAgb2xkRGVmYXVsdEltcG9ydHMuZm9yRWFjaCgodmFsdWUpID0+IHtcbiAgICAgICAgaWYgKCFuZXdEZWZhdWx0SW1wb3J0cy5oYXModmFsdWUpKSB7XG4gICAgICAgICAgY29uc3QgaW1wb3J0cyA9IG9sZEltcG9ydFBhdGhzLmdldCh2YWx1ZSk7XG4gICAgICAgICAgaW1wb3J0cy5kZWxldGUoSU1QT1JUX0RFRkFVTFRfU1BFQ0lGSUVSKTtcblxuICAgICAgICAgIGNvbnN0IGV4cG9ydHMgPSBleHBvcnRMaXN0LmdldCh2YWx1ZSk7XG4gICAgICAgICAgaWYgKHR5cGVvZiBleHBvcnRzICE9PSAndW5kZWZpbmVkJykge1xuICAgICAgICAgICAgY29uc3QgY3VycmVudEV4cG9ydCA9IGV4cG9ydHMuZ2V0KElNUE9SVF9ERUZBVUxUX1NQRUNJRklFUik7XG4gICAgICAgICAgICBpZiAodHlwZW9mIGN1cnJlbnRFeHBvcnQgIT09ICd1bmRlZmluZWQnKSB7XG4gICAgICAgICAgICAgIGN1cnJlbnRFeHBvcnQud2hlcmVVc2VkLmRlbGV0ZShmaWxlKTtcbiAgICAgICAgICAgIH1cbiAgICAgICAgICB9XG4gICAgICAgIH1cbiAgICAgIH0pO1xuXG4gICAgICBuZXdOYW1lc3BhY2VJbXBvcnRzLmZvckVhY2goKHZhbHVlKSA9PiB7XG4gICAgICAgIGlmICghb2xkTmFtZXNwYWNlSW1wb3J0cy5oYXModmFsdWUpKSB7XG4gICAgICAgICAgbGV0IGltcG9ydHMgPSBvbGRJbXBvcnRQYXRocy5nZXQodmFsdWUpO1xuICAgICAgICAgIGlmICh0eXBlb2YgaW1wb3J0cyA9PT0gJ3VuZGVmaW5lZCcpIHtcbiAgICAgICAgICAgIGltcG9ydHMgPSBuZXcgU2V0KCk7XG4gICAgICAgICAgfVxuICAgICAgICAgIGltcG9ydHMuYWRkKElNUE9SVF9OQU1FU1BBQ0VfU1BFQ0lGSUVSKTtcbiAgICAgICAgICBvbGRJbXBvcnRQYXRocy5zZXQodmFsdWUsIGltcG9ydHMpO1xuXG4gICAgICAgICAgbGV0IGV4cG9ydHMgPSBleHBvcnRMaXN0LmdldCh2YWx1ZSk7XG4gICAgICAgICAgbGV0IGN1cnJlbnRFeHBvcnQ7XG4gICAgICAgICAgaWYgKHR5cGVvZiBleHBvcnRzICE9PSAndW5kZWZpbmVkJykge1xuICAgICAgICAgICAgY3VycmVudEV4cG9ydCA9IGV4cG9ydHMuZ2V0KElNUE9SVF9OQU1FU1BBQ0VfU1BFQ0lGSUVSKTtcbiAgICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgICAgZXhwb3J0cyA9IG5ldyBNYXAoKTtcbiAgICAgICAgICAgIGV4cG9ydExpc3Quc2V0KHZhbHVlLCBleHBvcnRzKTtcbiAgICAgICAgICB9XG5cbiAgICAgICAgICBpZiAodHlwZW9mIGN1cnJlbnRFeHBvcnQgIT09ICd1bmRlZmluZWQnKSB7XG4gICAgICAgICAgICBjdXJyZW50RXhwb3J0LndoZXJlVXNlZC5hZGQoZmlsZSk7XG4gICAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICAgIGNvbnN0IHdoZXJlVXNlZCA9IG5ldyBTZXQoKTtcbiAgICAgICAgICAgIHdoZXJlVXNlZC5hZGQoZmlsZSk7XG4gICAgICAgICAgICBleHBvcnRzLnNldChJTVBPUlRfTkFNRVNQQUNFX1NQRUNJRklFUiwgeyB3aGVyZVVzZWQgfSk7XG4gICAgICAgICAgfVxuICAgICAgICB9XG4gICAgICB9KTtcblxuICAgICAgb2xkTmFtZXNwYWNlSW1wb3J0cy5mb3JFYWNoKCh2YWx1ZSkgPT4ge1xuICAgICAgICBpZiAoIW5ld05hbWVzcGFjZUltcG9ydHMuaGFzKHZhbHVlKSkge1xuICAgICAgICAgIGNvbnN0IGltcG9ydHMgPSBvbGRJbXBvcnRQYXRocy5nZXQodmFsdWUpO1xuICAgICAgICAgIGltcG9ydHMuZGVsZXRlKElNUE9SVF9OQU1FU1BBQ0VfU1BFQ0lGSUVSKTtcblxuICAgICAgICAgIGNvbnN0IGV4cG9ydHMgPSBleHBvcnRMaXN0LmdldCh2YWx1ZSk7XG4gICAgICAgICAgaWYgKHR5cGVvZiBleHBvcnRzICE9PSAndW5kZWZpbmVkJykge1xuICAgICAgICAgICAgY29uc3QgY3VycmVudEV4cG9ydCA9IGV4cG9ydHMuZ2V0KElNUE9SVF9OQU1FU1BBQ0VfU1BFQ0lGSUVSKTtcbiAgICAgICAgICAgIGlmICh0eXBlb2YgY3VycmVudEV4cG9ydCAhPT0gJ3VuZGVmaW5lZCcpIHtcbiAgICAgICAgICAgICAgY3VycmVudEV4cG9ydC53aGVyZVVzZWQuZGVsZXRlKGZpbGUpO1xuICAgICAgICAgICAgfVxuICAgICAgICAgIH1cbiAgICAgICAgfVxuICAgICAgfSk7XG5cbiAgICAgIG5ld0ltcG9ydHMuZm9yRWFjaCgodmFsdWUsIGtleSkgPT4ge1xuICAgICAgICBpZiAoIW9sZEltcG9ydHMuaGFzKGtleSkpIHtcbiAgICAgICAgICBsZXQgaW1wb3J0cyA9IG9sZEltcG9ydFBhdGhzLmdldCh2YWx1ZSk7XG4gICAgICAgICAgaWYgKHR5cGVvZiBpbXBvcnRzID09PSAndW5kZWZpbmVkJykge1xuICAgICAgICAgICAgaW1wb3J0cyA9IG5ldyBTZXQoKTtcbiAgICAgICAgICB9XG4gICAgICAgICAgaW1wb3J0cy5hZGQoa2V5KTtcbiAgICAgICAgICBvbGRJbXBvcnRQYXRocy5zZXQodmFsdWUsIGltcG9ydHMpO1xuXG4gICAgICAgICAgbGV0IGV4cG9ydHMgPSBleHBvcnRMaXN0LmdldCh2YWx1ZSk7XG4gICAgICAgICAgbGV0IGN1cnJlbnRFeHBvcnQ7XG4gICAgICAgICAgaWYgKHR5cGVvZiBleHBvcnRzICE9PSAndW5kZWZpbmVkJykge1xuICAgICAgICAgICAgY3VycmVudEV4cG9ydCA9IGV4cG9ydHMuZ2V0KGtleSk7XG4gICAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICAgIGV4cG9ydHMgPSBuZXcgTWFwKCk7XG4gICAgICAgICAgICBleHBvcnRMaXN0LnNldCh2YWx1ZSwgZXhwb3J0cyk7XG4gICAgICAgICAgfVxuXG4gICAgICAgICAgaWYgKHR5cGVvZiBjdXJyZW50RXhwb3J0ICE9PSAndW5kZWZpbmVkJykge1xuICAgICAgICAgICAgY3VycmVudEV4cG9ydC53aGVyZVVzZWQuYWRkKGZpbGUpO1xuICAgICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgICBjb25zdCB3aGVyZVVzZWQgPSBuZXcgU2V0KCk7XG4gICAgICAgICAgICB3aGVyZVVzZWQuYWRkKGZpbGUpO1xuICAgICAgICAgICAgZXhwb3J0cy5zZXQoa2V5LCB7IHdoZXJlVXNlZCB9KTtcbiAgICAgICAgICB9XG4gICAgICAgIH1cbiAgICAgIH0pO1xuXG4gICAgICBvbGRJbXBvcnRzLmZvckVhY2goKHZhbHVlLCBrZXkpID0+IHtcbiAgICAgICAgaWYgKCFuZXdJbXBvcnRzLmhhcyhrZXkpKSB7XG4gICAgICAgICAgY29uc3QgaW1wb3J0cyA9IG9sZEltcG9ydFBhdGhzLmdldCh2YWx1ZSk7XG4gICAgICAgICAgaW1wb3J0cy5kZWxldGUoa2V5KTtcblxuICAgICAgICAgIGNvbnN0IGV4cG9ydHMgPSBleHBvcnRMaXN0LmdldCh2YWx1ZSk7XG4gICAgICAgICAgaWYgKHR5cGVvZiBleHBvcnRzICE9PSAndW5kZWZpbmVkJykge1xuICAgICAgICAgICAgY29uc3QgY3VycmVudEV4cG9ydCA9IGV4cG9ydHMuZ2V0KGtleSk7XG4gICAgICAgICAgICBpZiAodHlwZW9mIGN1cnJlbnRFeHBvcnQgIT09ICd1bmRlZmluZWQnKSB7XG4gICAgICAgICAgICAgIGN1cnJlbnRFeHBvcnQud2hlcmVVc2VkLmRlbGV0ZShmaWxlKTtcbiAgICAgICAgICAgIH1cbiAgICAgICAgICB9XG4gICAgICAgIH1cbiAgICAgIH0pO1xuICAgIH07XG5cbiAgICByZXR1cm4ge1xuICAgICAgJ1Byb2dyYW06ZXhpdCcobm9kZSkge1xuICAgICAgICB1cGRhdGVFeHBvcnRVc2FnZShub2RlKTtcbiAgICAgICAgdXBkYXRlSW1wb3J0VXNhZ2Uobm9kZSk7XG4gICAgICAgIGNoZWNrRXhwb3J0UHJlc2VuY2Uobm9kZSk7XG4gICAgICB9LFxuICAgICAgRXhwb3J0RGVmYXVsdERlY2xhcmF0aW9uKG5vZGUpIHtcbiAgICAgICAgY2hlY2tVc2FnZShub2RlLCBJTVBPUlRfREVGQVVMVF9TUEVDSUZJRVIsIGZhbHNlKTtcbiAgICAgIH0sXG4gICAgICBFeHBvcnROYW1lZERlY2xhcmF0aW9uKG5vZGUpIHtcbiAgICAgICAgbm9kZS5zcGVjaWZpZXJzLmZvckVhY2goKHNwZWNpZmllcikgPT4ge1xuICAgICAgICAgIGNoZWNrVXNhZ2Uoc3BlY2lmaWVyLCBzcGVjaWZpZXIuZXhwb3J0ZWQubmFtZSB8fCBzcGVjaWZpZXIuZXhwb3J0ZWQudmFsdWUsIGZhbHNlKTtcbiAgICAgICAgfSk7XG4gICAgICAgIGZvckVhY2hEZWNsYXJhdGlvbklkZW50aWZpZXIobm9kZS5kZWNsYXJhdGlvbiwgKG5hbWUsIGlzVHlwZUV4cG9ydCkgPT4ge1xuICAgICAgICAgIGNoZWNrVXNhZ2Uobm9kZSwgbmFtZSwgaXNUeXBlRXhwb3J0KTtcbiAgICAgICAgfSk7XG4gICAgICB9LFxuICAgIH07XG4gIH0sXG59O1xuIl19