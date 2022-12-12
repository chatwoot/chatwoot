'use strict';





var _ExportMap = require('../ExportMap');var _ExportMap2 = _interopRequireDefault(_ExportMap);
var _ignore = require('eslint-module-utils/ignore');
var _resolve = require('eslint-module-utils/resolve');var _resolve2 = _interopRequireDefault(_resolve);
var _docsUrl = require('../docsUrl');var _docsUrl2 = _interopRequireDefault(_docsUrl);
var _path = require('path');
var _readPkgUp = require('read-pkg-up');var _readPkgUp2 = _interopRequireDefault(_readPkgUp);
var _object = require('object.values');var _object2 = _interopRequireDefault(_object);
var _arrayIncludes = require('array-includes');var _arrayIncludes2 = _interopRequireDefault(_arrayIncludes);function _interopRequireDefault(obj) {return obj && obj.__esModule ? obj : { default: obj };}function _toConsumableArray(arr) {if (Array.isArray(arr)) {for (var i = 0, arr2 = Array(arr.length); i < arr.length; i++) arr2[i] = arr[i];return arr2;} else {return Array.from(arr);}} /**
                                                                                                                                                                                                                                                                                                                                                                                                   * @fileOverview Ensures that modules contain exports and/or all
                                                                                                                                                                                                                                                                                                                                                                                                   * modules are consumed within other modules.
                                                                                                                                                                                                                                                                                                                                                                                                   * @author René Fermann
                                                                                                                                                                                                                                                                                                                                                                                                   */ // eslint/lib/util/glob-util has been moved to eslint/lib/util/glob-utils with version 5.3
// and has been moved to eslint/lib/cli-engine/file-enumerator in version 6
let listFilesToProcess;try {const FileEnumerator = require('eslint/lib/cli-engine/file-enumerator').FileEnumerator;
  listFilesToProcess = function (src, extensions) {
    const e = new FileEnumerator({
      extensions: extensions });

    return Array.from(e.iterateFiles(src), (_ref) => {let filePath = _ref.filePath,ignored = _ref.ignored;return {
        ignored,
        filename: filePath };});

  };
} catch (e1) {
  // Prevent passing invalid options (extensions array) to old versions of the function.
  // https://github.com/eslint/eslint/blob/v5.16.0/lib/util/glob-utils.js#L178-L280
  // https://github.com/eslint/eslint/blob/v5.2.0/lib/util/glob-util.js#L174-L269
  let originalListFilesToProcess;
  try {
    originalListFilesToProcess = require('eslint/lib/util/glob-utils').listFilesToProcess;
    listFilesToProcess = function (src, extensions) {
      return originalListFilesToProcess(src, {
        extensions: extensions });

    };
  } catch (e2) {
    originalListFilesToProcess = require('eslint/lib/util/glob-util').listFilesToProcess;

    listFilesToProcess = function (src, extensions) {
      const patterns = src.reduce((carry, pattern) => {
        return carry.concat(extensions.map(extension => {
          return (/\*\*|\*\./.test(pattern) ? pattern : `${pattern}/**/*${extension}`);
        }));
      }, src.slice());

      return originalListFilesToProcess(patterns);
    };
  }
}

const EXPORT_DEFAULT_DECLARATION = 'ExportDefaultDeclaration';
const EXPORT_NAMED_DECLARATION = 'ExportNamedDeclaration';
const EXPORT_ALL_DECLARATION = 'ExportAllDeclaration';
const IMPORT_DECLARATION = 'ImportDeclaration';
const IMPORT_NAMESPACE_SPECIFIER = 'ImportNamespaceSpecifier';
const IMPORT_DEFAULT_SPECIFIER = 'ImportDefaultSpecifier';
const VARIABLE_DECLARATION = 'VariableDeclaration';
const FUNCTION_DECLARATION = 'FunctionDeclaration';
const CLASS_DECLARATION = 'ClassDeclaration';
const INTERFACE_DECLARATION = 'InterfaceDeclaration';
const TYPE_ALIAS = 'TypeAlias';
const TS_INTERFACE_DECLARATION = 'TSInterfaceDeclaration';
const TS_TYPE_ALIAS_DECLARATION = 'TSTypeAliasDeclaration';
const TS_ENUM_DECLARATION = 'TSEnumDeclaration';
const DEFAULT = 'default';

function forEachDeclarationIdentifier(declaration, cb) {
  if (declaration) {
    if (
    declaration.type === FUNCTION_DECLARATION ||
    declaration.type === CLASS_DECLARATION ||
    declaration.type === INTERFACE_DECLARATION ||
    declaration.type === TYPE_ALIAS ||
    declaration.type === TS_INTERFACE_DECLARATION ||
    declaration.type === TS_TYPE_ALIAS_DECLARATION ||
    declaration.type === TS_ENUM_DECLARATION)
    {
      cb(declaration.id.name);
    } else if (declaration.type === VARIABLE_DECLARATION) {
      declaration.declarations.forEach((_ref2) => {let id = _ref2.id;
        cb(id.name);
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
const importList = new Map();

/**
                               * List of exports per file.
                               *
                               * Represented by a two-level Map to an object of metadata. The upper-level Map
                               * keys are the paths to the modules containing the exports, while the
                               * lower-level Map keys are the specific identifiers or special AST node names
                               * being exported. The leaf-level metadata object at the moment only contains a
                               * `whereUsed` propoerty, which contains a Set of paths to modules that import
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
const exportList = new Map();

const ignoredFiles = new Set();
const filesOutsideSrc = new Set();

const isNodeModule = path => {
  return (/\/(node_modules)\//.test(path));
};

/**
    * read all files matching the patterns in src and ignoreExports
    *
    * return all files matching src pattern, which are not matching the ignoreExports pattern
    */
const resolveFiles = (src, ignoreExports, context) => {
  const extensions = Array.from((0, _ignore.getFileExtensions)(context.settings));

  const srcFiles = new Set();
  const srcFileList = listFilesToProcess(src, extensions);

  // prepare list of ignored files
  const ignoredFilesList = listFilesToProcess(ignoreExports, extensions);
  ignoredFilesList.forEach((_ref3) => {let filename = _ref3.filename;return ignoredFiles.add(filename);});

  // prepare list of source files, don't consider files from node_modules
  srcFileList.filter((_ref4) => {let filename = _ref4.filename;return !isNodeModule(filename);}).forEach((_ref5) => {let filename = _ref5.filename;
    srcFiles.add(filename);
  });
  return srcFiles;
};

/**
    * parse all source files and build up 2 maps containing the existing imports and exports
    */
const prepareImportsAndExports = (srcFiles, context) => {
  const exportAll = new Map();
  srcFiles.forEach(file => {
    const exports = new Map();
    const imports = new Map();
    const currentExports = _ExportMap2.default.get(file, context);
    if (currentExports) {const
      dependencies = currentExports.dependencies,reexports = currentExports.reexports,localImportList = currentExports.imports,namespace = currentExports.namespace;

      // dependencies === export * from
      const currentExportAll = new Set();
      dependencies.forEach(getDependency => {
        const dependency = getDependency();
        if (dependency === null) {
          return;
        }

        currentExportAll.add(dependency.path);
      });
      exportAll.set(file, currentExportAll);

      reexports.forEach((value, key) => {
        if (key === DEFAULT) {
          exports.set(IMPORT_DEFAULT_SPECIFIER, { whereUsed: new Set() });
        } else {
          exports.set(key, { whereUsed: new Set() });
        }
        const reexport = value.getImport();
        if (!reexport) {
          return;
        }
        let localImport = imports.get(reexport.path);
        let currentValue;
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

      localImportList.forEach((value, key) => {
        if (isNodeModule(key)) {
          return;
        }
        let localImport = imports.get(key);
        if (typeof localImport !== 'undefined') {
          localImport = new Set([].concat(_toConsumableArray(localImport), _toConsumableArray(value.importedSpecifiers)));
        } else {
          localImport = value.importedSpecifiers;
        }
        imports.set(key, localImport);
      });
      importList.set(file, imports);

      // build up export list only, if file is not ignored
      if (ignoredFiles.has(file)) {
        return;
      }
      namespace.forEach((value, key) => {
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
  exportAll.forEach((value, key) => {
    value.forEach(val => {
      const currentExports = exportList.get(val);
      const currentExport = currentExports.get(EXPORT_ALL_DECLARATION);
      currentExport.whereUsed.add(key);
    });
  });
};

/**
    * traverse through all imports and add the respective path to the whereUsed-list
    * of the corresponding export
    */
const determineUsage = () => {
  importList.forEach((listValue, listKey) => {
    listValue.forEach((value, key) => {
      const exports = exportList.get(key);
      if (typeof exports !== 'undefined') {
        value.forEach(currentImport => {
          let specifier;
          if (currentImport === IMPORT_NAMESPACE_SPECIFIER) {
            specifier = IMPORT_NAMESPACE_SPECIFIER;
          } else if (currentImport === IMPORT_DEFAULT_SPECIFIER) {
            specifier = IMPORT_DEFAULT_SPECIFIER;
          } else {
            specifier = currentImport;
          }
          if (typeof specifier !== 'undefined') {
            const exportStatement = exports.get(specifier);
            if (typeof exportStatement !== 'undefined') {const
              whereUsed = exportStatement.whereUsed;
              whereUsed.add(listKey);
              exports.set(specifier, { whereUsed });
            }
          }
        });
      }
    });
  });
};

const getSrc = src => {
  if (src) {
    return src;
  }
  return [process.cwd()];
};

/**
    * prepare the lists of existing imports and exports - should only be executed once at
    * the start of a new eslint run
    */
let srcFiles;
let lastPrepareKey;
const doPreparation = (src, ignoreExports, context) => {
  const prepareKey = JSON.stringify({
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

const newNamespaceImportExists = specifiers =>
specifiers.some((_ref6) => {let type = _ref6.type;return type === IMPORT_NAMESPACE_SPECIFIER;});

const newDefaultImportExists = specifiers =>
specifiers.some((_ref7) => {let type = _ref7.type;return type === IMPORT_DEFAULT_SPECIFIER;});

const fileIsInPkg = file => {var _readPkgUp$sync =
  _readPkgUp2.default.sync({ cwd: file, normalize: false });const path = _readPkgUp$sync.path,pkg = _readPkgUp$sync.pkg;
  const basePath = (0, _path.dirname)(path);

  const checkPkgFieldString = pkgField => {
    if ((0, _path.join)(basePath, pkgField) === file) {
      return true;
    }
  };

  const checkPkgFieldObject = pkgField => {
    const pkgFieldFiles = (0, _object2.default)(pkgField).map(value => (0, _path.join)(basePath, value));
    if ((0, _arrayIncludes2.default)(pkgFieldFiles, file)) {
      return true;
    }
  };

  const checkPkgField = pkgField => {
    if (typeof pkgField === 'string') {
      return checkPkgFieldString(pkgField);
    }

    if (typeof pkgField === 'object') {
      return checkPkgFieldObject(pkgField);
    }
  };

  if (pkg.private === true) {
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
    docs: { url: (0, _docsUrl2.default)('no-unused-modules') },
    schema: [{
      properties: {
        src: {
          description: 'files/paths to be analyzed (only for unused exports)',
          type: 'array',
          minItems: 1,
          items: {
            type: 'string',
            minLength: 1 } },


        ignoreExports: {
          description:
          'files/paths for which unused exports will not be reported (e.g module entry points)',
          type: 'array',
          minItems: 1,
          items: {
            type: 'string',
            minLength: 1 } },


        missingExports: {
          description: 'report modules without any exports',
          type: 'boolean' },

        unusedExports: {
          description: 'report exports without any usage',
          type: 'boolean' } },


      not: {
        properties: {
          unusedExports: { enum: [false] },
          missingExports: { enum: [false] } } },


      anyOf: [{
        not: {
          properties: {
            unusedExports: { enum: [true] } } },


        required: ['missingExports'] },
      {
        not: {
          properties: {
            missingExports: { enum: [true] } } },


        required: ['unusedExports'] },
      {
        properties: {
          unusedExports: { enum: [true] } },

        required: ['unusedExports'] },
      {
        properties: {
          missingExports: { enum: [true] } },

        required: ['missingExports'] }] }] },




  create: context => {var _ref8 =





    context.options[0] || {};const src = _ref8.src;var _ref8$ignoreExports = _ref8.ignoreExports;const ignoreExports = _ref8$ignoreExports === undefined ? [] : _ref8$ignoreExports,missingExports = _ref8.missingExports,unusedExports = _ref8.unusedExports;

    if (unusedExports) {
      doPreparation(src, ignoreExports, context);
    }

    const file = context.getFilename();

    const checkExportPresence = node => {
      if (!missingExports) {
        return;
      }

      if (ignoredFiles.has(file)) {
        return;
      }

      const exportCount = exportList.get(file);
      const exportAll = exportCount.get(EXPORT_ALL_DECLARATION);
      const namespaceImports = exportCount.get(IMPORT_NAMESPACE_SPECIFIER);

      exportCount.delete(EXPORT_ALL_DECLARATION);
      exportCount.delete(IMPORT_NAMESPACE_SPECIFIER);
      if (exportCount.size < 1) {
        // node.body[0] === 'undefined' only happens, if everything is commented out in the file
        // being linted
        context.report(node.body[0] ? node.body[0] : node, 'No exports found');
      }
      exportCount.set(EXPORT_ALL_DECLARATION, exportAll);
      exportCount.set(IMPORT_NAMESPACE_SPECIFIER, namespaceImports);
    };

    const checkUsage = (node, exportedValue) => {
      if (!unusedExports) {
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

      // special case: export * from
      const exportAll = exports.get(EXPORT_ALL_DECLARATION);
      if (typeof exportAll !== 'undefined' && exportedValue !== IMPORT_DEFAULT_SPECIFIER) {
        if (exportAll.whereUsed.size > 0) {
          return;
        }
      }

      // special case: namespace import
      const namespaceImports = exports.get(IMPORT_NAMESPACE_SPECIFIER);
      if (typeof namespaceImports !== 'undefined') {
        if (namespaceImports.whereUsed.size > 0) {
          return;
        }
      }

      // exportsList will always map any imported value of 'default' to 'ImportDefaultSpecifier'
      const exportsKey = exportedValue === DEFAULT ? IMPORT_DEFAULT_SPECIFIER : exportedValue;

      const exportStatement = exports.get(exportsKey);

      const value = exportsKey === IMPORT_DEFAULT_SPECIFIER ? DEFAULT : exportsKey;

      if (typeof exportStatement !== 'undefined') {
        if (exportStatement.whereUsed.size < 1) {
          context.report(
          node,
          `exported declaration '${value}' not used within other modules`);

        }
      } else {
        context.report(
        node,
        `exported declaration '${value}' not used within other modules`);

      }
    };

    /**
        * only useful for tools like vscode-eslint
        *
        * update lists of existing exports during runtime
        */
    const updateExportUsage = node => {
      if (ignoredFiles.has(file)) {
        return;
      }

      let exports = exportList.get(file);

      // new module has been created during runtime
      // include it in further processing
      if (typeof exports === 'undefined') {
        exports = new Map();
      }

      const newExports = new Map();
      const newExportIdentifiers = new Set();

      node.body.forEach((_ref9) => {let type = _ref9.type,declaration = _ref9.declaration,specifiers = _ref9.specifiers;
        if (type === EXPORT_DEFAULT_DECLARATION) {
          newExportIdentifiers.add(IMPORT_DEFAULT_SPECIFIER);
        }
        if (type === EXPORT_NAMED_DECLARATION) {
          if (specifiers.length > 0) {
            specifiers.forEach(specifier => {
              if (specifier.exported) {
                newExportIdentifiers.add(specifier.exported.name);
              }
            });
          }
          forEachDeclarationIdentifier(declaration, name => {
            newExportIdentifiers.add(name);
          });
        }
      });

      // old exports exist within list of new exports identifiers: add to map of new exports
      exports.forEach((value, key) => {
        if (newExportIdentifiers.has(key)) {
          newExports.set(key, value);
        }
      });

      // new export identifiers added: add to map of new exports
      newExportIdentifiers.forEach(key => {
        if (!exports.has(key)) {
          newExports.set(key, { whereUsed: new Set() });
        }
      });

      // preserve information about namespace imports
      let exportAll = exports.get(EXPORT_ALL_DECLARATION);
      let namespaceImports = exports.get(IMPORT_NAMESPACE_SPECIFIER);

      if (typeof namespaceImports === 'undefined') {
        namespaceImports = { whereUsed: new Set() };
      }

      newExports.set(EXPORT_ALL_DECLARATION, exportAll);
      newExports.set(IMPORT_NAMESPACE_SPECIFIER, namespaceImports);
      exportList.set(file, newExports);
    };

    /**
        * only useful for tools like vscode-eslint
        *
        * update lists of existing imports during runtime
        */
    const updateImportUsage = node => {
      if (!unusedExports) {
        return;
      }

      let oldImportPaths = importList.get(file);
      if (typeof oldImportPaths === 'undefined') {
        oldImportPaths = new Map();
      }

      const oldNamespaceImports = new Set();
      const newNamespaceImports = new Set();

      const oldExportAll = new Set();
      const newExportAll = new Set();

      const oldDefaultImports = new Set();
      const newDefaultImports = new Set();

      const oldImports = new Map();
      const newImports = new Map();
      oldImportPaths.forEach((value, key) => {
        if (value.has(EXPORT_ALL_DECLARATION)) {
          oldExportAll.add(key);
        }
        if (value.has(IMPORT_NAMESPACE_SPECIFIER)) {
          oldNamespaceImports.add(key);
        }
        if (value.has(IMPORT_DEFAULT_SPECIFIER)) {
          oldDefaultImports.add(key);
        }
        value.forEach(val => {
          if (val !== IMPORT_NAMESPACE_SPECIFIER &&
          val !== IMPORT_DEFAULT_SPECIFIER) {
            oldImports.set(val, key);
          }
        });
      });

      node.body.forEach(astNode => {
        let resolvedPath;

        // support for export { value } from 'module'
        if (astNode.type === EXPORT_NAMED_DECLARATION) {
          if (astNode.source) {
            resolvedPath = (0, _resolve2.default)(astNode.source.raw.replace(/('|")/g, ''), context);
            astNode.specifiers.forEach(specifier => {
              const name = specifier.local.name;
              if (specifier.local.name === DEFAULT) {
                newDefaultImports.add(resolvedPath);
              } else {
                newImports.set(name, resolvedPath);
              }
            });
          }
        }

        if (astNode.type === EXPORT_ALL_DECLARATION) {
          resolvedPath = (0, _resolve2.default)(astNode.source.raw.replace(/('|")/g, ''), context);
          newExportAll.add(resolvedPath);
        }

        if (astNode.type === IMPORT_DECLARATION) {
          resolvedPath = (0, _resolve2.default)(astNode.source.raw.replace(/('|")/g, ''), context);
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

          astNode.specifiers.forEach(specifier => {
            if (specifier.type === IMPORT_DEFAULT_SPECIFIER ||
            specifier.type === IMPORT_NAMESPACE_SPECIFIER) {
              return;
            }
            newImports.set(specifier.imported.name, resolvedPath);
          });
        }
      });

      newExportAll.forEach(value => {
        if (!oldExportAll.has(value)) {
          let imports = oldImportPaths.get(value);
          if (typeof imports === 'undefined') {
            imports = new Set();
          }
          imports.add(EXPORT_ALL_DECLARATION);
          oldImportPaths.set(value, imports);

          let exports = exportList.get(value);
          let currentExport;
          if (typeof exports !== 'undefined') {
            currentExport = exports.get(EXPORT_ALL_DECLARATION);
          } else {
            exports = new Map();
            exportList.set(value, exports);
          }

          if (typeof currentExport !== 'undefined') {
            currentExport.whereUsed.add(file);
          } else {
            const whereUsed = new Set();
            whereUsed.add(file);
            exports.set(EXPORT_ALL_DECLARATION, { whereUsed });
          }
        }
      });

      oldExportAll.forEach(value => {
        if (!newExportAll.has(value)) {
          const imports = oldImportPaths.get(value);
          imports.delete(EXPORT_ALL_DECLARATION);

          const exports = exportList.get(value);
          if (typeof exports !== 'undefined') {
            const currentExport = exports.get(EXPORT_ALL_DECLARATION);
            if (typeof currentExport !== 'undefined') {
              currentExport.whereUsed.delete(file);
            }
          }
        }
      });

      newDefaultImports.forEach(value => {
        if (!oldDefaultImports.has(value)) {
          let imports = oldImportPaths.get(value);
          if (typeof imports === 'undefined') {
            imports = new Set();
          }
          imports.add(IMPORT_DEFAULT_SPECIFIER);
          oldImportPaths.set(value, imports);

          let exports = exportList.get(value);
          let currentExport;
          if (typeof exports !== 'undefined') {
            currentExport = exports.get(IMPORT_DEFAULT_SPECIFIER);
          } else {
            exports = new Map();
            exportList.set(value, exports);
          }

          if (typeof currentExport !== 'undefined') {
            currentExport.whereUsed.add(file);
          } else {
            const whereUsed = new Set();
            whereUsed.add(file);
            exports.set(IMPORT_DEFAULT_SPECIFIER, { whereUsed });
          }
        }
      });

      oldDefaultImports.forEach(value => {
        if (!newDefaultImports.has(value)) {
          const imports = oldImportPaths.get(value);
          imports.delete(IMPORT_DEFAULT_SPECIFIER);

          const exports = exportList.get(value);
          if (typeof exports !== 'undefined') {
            const currentExport = exports.get(IMPORT_DEFAULT_SPECIFIER);
            if (typeof currentExport !== 'undefined') {
              currentExport.whereUsed.delete(file);
            }
          }
        }
      });

      newNamespaceImports.forEach(value => {
        if (!oldNamespaceImports.has(value)) {
          let imports = oldImportPaths.get(value);
          if (typeof imports === 'undefined') {
            imports = new Set();
          }
          imports.add(IMPORT_NAMESPACE_SPECIFIER);
          oldImportPaths.set(value, imports);

          let exports = exportList.get(value);
          let currentExport;
          if (typeof exports !== 'undefined') {
            currentExport = exports.get(IMPORT_NAMESPACE_SPECIFIER);
          } else {
            exports = new Map();
            exportList.set(value, exports);
          }

          if (typeof currentExport !== 'undefined') {
            currentExport.whereUsed.add(file);
          } else {
            const whereUsed = new Set();
            whereUsed.add(file);
            exports.set(IMPORT_NAMESPACE_SPECIFIER, { whereUsed });
          }
        }
      });

      oldNamespaceImports.forEach(value => {
        if (!newNamespaceImports.has(value)) {
          const imports = oldImportPaths.get(value);
          imports.delete(IMPORT_NAMESPACE_SPECIFIER);

          const exports = exportList.get(value);
          if (typeof exports !== 'undefined') {
            const currentExport = exports.get(IMPORT_NAMESPACE_SPECIFIER);
            if (typeof currentExport !== 'undefined') {
              currentExport.whereUsed.delete(file);
            }
          }
        }
      });

      newImports.forEach((value, key) => {
        if (!oldImports.has(key)) {
          let imports = oldImportPaths.get(value);
          if (typeof imports === 'undefined') {
            imports = new Set();
          }
          imports.add(key);
          oldImportPaths.set(value, imports);

          let exports = exportList.get(value);
          let currentExport;
          if (typeof exports !== 'undefined') {
            currentExport = exports.get(key);
          } else {
            exports = new Map();
            exportList.set(value, exports);
          }

          if (typeof currentExport !== 'undefined') {
            currentExport.whereUsed.add(file);
          } else {
            const whereUsed = new Set();
            whereUsed.add(file);
            exports.set(key, { whereUsed });
          }
        }
      });

      oldImports.forEach((value, key) => {
        if (!newImports.has(key)) {
          const imports = oldImportPaths.get(value);
          imports.delete(key);

          const exports = exportList.get(value);
          if (typeof exports !== 'undefined') {
            const currentExport = exports.get(key);
            if (typeof currentExport !== 'undefined') {
              currentExport.whereUsed.delete(file);
            }
          }
        }
      });
    };

    return {
      'Program:exit': node => {
        updateExportUsage(node);
        updateImportUsage(node);
        checkExportPresence(node);
      },
      'ExportDefaultDeclaration': node => {
        checkUsage(node, IMPORT_DEFAULT_SPECIFIER);
      },
      'ExportNamedDeclaration': node => {
        node.specifiers.forEach(specifier => {
          checkUsage(node, specifier.exported.name);
        });
        forEachDeclarationIdentifier(node.declaration, name => {
          checkUsage(node, name);
        });
      } };

  } };
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIi4uLy4uL3NyYy9ydWxlcy9uby11bnVzZWQtbW9kdWxlcy5qcyJdLCJuYW1lcyI6WyJsaXN0RmlsZXNUb1Byb2Nlc3MiLCJGaWxlRW51bWVyYXRvciIsInJlcXVpcmUiLCJzcmMiLCJleHRlbnNpb25zIiwiZSIsIkFycmF5IiwiZnJvbSIsIml0ZXJhdGVGaWxlcyIsImZpbGVQYXRoIiwiaWdub3JlZCIsImZpbGVuYW1lIiwiZTEiLCJvcmlnaW5hbExpc3RGaWxlc1RvUHJvY2VzcyIsImUyIiwicGF0dGVybnMiLCJyZWR1Y2UiLCJjYXJyeSIsInBhdHRlcm4iLCJjb25jYXQiLCJtYXAiLCJleHRlbnNpb24iLCJ0ZXN0Iiwic2xpY2UiLCJFWFBPUlRfREVGQVVMVF9ERUNMQVJBVElPTiIsIkVYUE9SVF9OQU1FRF9ERUNMQVJBVElPTiIsIkVYUE9SVF9BTExfREVDTEFSQVRJT04iLCJJTVBPUlRfREVDTEFSQVRJT04iLCJJTVBPUlRfTkFNRVNQQUNFX1NQRUNJRklFUiIsIklNUE9SVF9ERUZBVUxUX1NQRUNJRklFUiIsIlZBUklBQkxFX0RFQ0xBUkFUSU9OIiwiRlVOQ1RJT05fREVDTEFSQVRJT04iLCJDTEFTU19ERUNMQVJBVElPTiIsIklOVEVSRkFDRV9ERUNMQVJBVElPTiIsIlRZUEVfQUxJQVMiLCJUU19JTlRFUkZBQ0VfREVDTEFSQVRJT04iLCJUU19UWVBFX0FMSUFTX0RFQ0xBUkFUSU9OIiwiVFNfRU5VTV9ERUNMQVJBVElPTiIsIkRFRkFVTFQiLCJmb3JFYWNoRGVjbGFyYXRpb25JZGVudGlmaWVyIiwiZGVjbGFyYXRpb24iLCJjYiIsInR5cGUiLCJpZCIsIm5hbWUiLCJkZWNsYXJhdGlvbnMiLCJmb3JFYWNoIiwiaW1wb3J0TGlzdCIsIk1hcCIsImV4cG9ydExpc3QiLCJpZ25vcmVkRmlsZXMiLCJTZXQiLCJmaWxlc091dHNpZGVTcmMiLCJpc05vZGVNb2R1bGUiLCJwYXRoIiwicmVzb2x2ZUZpbGVzIiwiaWdub3JlRXhwb3J0cyIsImNvbnRleHQiLCJzZXR0aW5ncyIsInNyY0ZpbGVzIiwic3JjRmlsZUxpc3QiLCJpZ25vcmVkRmlsZXNMaXN0IiwiYWRkIiwiZmlsdGVyIiwicHJlcGFyZUltcG9ydHNBbmRFeHBvcnRzIiwiZXhwb3J0QWxsIiwiZmlsZSIsImV4cG9ydHMiLCJpbXBvcnRzIiwiY3VycmVudEV4cG9ydHMiLCJFeHBvcnRzIiwiZ2V0IiwiZGVwZW5kZW5jaWVzIiwicmVleHBvcnRzIiwibG9jYWxJbXBvcnRMaXN0IiwibmFtZXNwYWNlIiwiY3VycmVudEV4cG9ydEFsbCIsImdldERlcGVuZGVuY3kiLCJkZXBlbmRlbmN5Iiwic2V0IiwidmFsdWUiLCJrZXkiLCJ3aGVyZVVzZWQiLCJyZWV4cG9ydCIsImdldEltcG9ydCIsImxvY2FsSW1wb3J0IiwiY3VycmVudFZhbHVlIiwibG9jYWwiLCJpbXBvcnRlZFNwZWNpZmllcnMiLCJoYXMiLCJ2YWwiLCJjdXJyZW50RXhwb3J0IiwiZGV0ZXJtaW5lVXNhZ2UiLCJsaXN0VmFsdWUiLCJsaXN0S2V5IiwiY3VycmVudEltcG9ydCIsInNwZWNpZmllciIsImV4cG9ydFN0YXRlbWVudCIsImdldFNyYyIsInByb2Nlc3MiLCJjd2QiLCJsYXN0UHJlcGFyZUtleSIsImRvUHJlcGFyYXRpb24iLCJwcmVwYXJlS2V5IiwiSlNPTiIsInN0cmluZ2lmeSIsInNvcnQiLCJjbGVhciIsIm5ld05hbWVzcGFjZUltcG9ydEV4aXN0cyIsInNwZWNpZmllcnMiLCJzb21lIiwibmV3RGVmYXVsdEltcG9ydEV4aXN0cyIsImZpbGVJc0luUGtnIiwicmVhZFBrZ1VwIiwic3luYyIsIm5vcm1hbGl6ZSIsInBrZyIsImJhc2VQYXRoIiwiY2hlY2tQa2dGaWVsZFN0cmluZyIsInBrZ0ZpZWxkIiwiY2hlY2tQa2dGaWVsZE9iamVjdCIsInBrZ0ZpZWxkRmlsZXMiLCJjaGVja1BrZ0ZpZWxkIiwicHJpdmF0ZSIsImJpbiIsImJyb3dzZXIiLCJtYWluIiwibW9kdWxlIiwibWV0YSIsImRvY3MiLCJ1cmwiLCJzY2hlbWEiLCJwcm9wZXJ0aWVzIiwiZGVzY3JpcHRpb24iLCJtaW5JdGVtcyIsIml0ZW1zIiwibWluTGVuZ3RoIiwibWlzc2luZ0V4cG9ydHMiLCJ1bnVzZWRFeHBvcnRzIiwibm90IiwiZW51bSIsImFueU9mIiwicmVxdWlyZWQiLCJjcmVhdGUiLCJvcHRpb25zIiwiZ2V0RmlsZW5hbWUiLCJjaGVja0V4cG9ydFByZXNlbmNlIiwibm9kZSIsImV4cG9ydENvdW50IiwibmFtZXNwYWNlSW1wb3J0cyIsImRlbGV0ZSIsInNpemUiLCJyZXBvcnQiLCJib2R5IiwiY2hlY2tVc2FnZSIsImV4cG9ydGVkVmFsdWUiLCJleHBvcnRzS2V5IiwidXBkYXRlRXhwb3J0VXNhZ2UiLCJuZXdFeHBvcnRzIiwibmV3RXhwb3J0SWRlbnRpZmllcnMiLCJsZW5ndGgiLCJleHBvcnRlZCIsInVwZGF0ZUltcG9ydFVzYWdlIiwib2xkSW1wb3J0UGF0aHMiLCJvbGROYW1lc3BhY2VJbXBvcnRzIiwibmV3TmFtZXNwYWNlSW1wb3J0cyIsIm9sZEV4cG9ydEFsbCIsIm5ld0V4cG9ydEFsbCIsIm9sZERlZmF1bHRJbXBvcnRzIiwibmV3RGVmYXVsdEltcG9ydHMiLCJvbGRJbXBvcnRzIiwibmV3SW1wb3J0cyIsImFzdE5vZGUiLCJyZXNvbHZlZFBhdGgiLCJzb3VyY2UiLCJyYXciLCJyZXBsYWNlIiwiaW1wb3J0ZWQiXSwibWFwcGluZ3MiOiI7Ozs7OztBQU1BLHlDO0FBQ0E7QUFDQSxzRDtBQUNBLHFDO0FBQ0E7QUFDQSx3QztBQUNBLHVDO0FBQ0EsK0MsbVZBYkE7Ozs7c1lBZUE7QUFDQTtBQUNBLElBQUlBLGtCQUFKLENBQ0EsSUFBSSxDQUNGLE1BQU1DLGlCQUFpQkMsUUFBUSx1Q0FBUixFQUFpREQsY0FBeEU7QUFDQUQsdUJBQXFCLFVBQVVHLEdBQVYsRUFBZUMsVUFBZixFQUEyQjtBQUM5QyxVQUFNQyxJQUFJLElBQUlKLGNBQUosQ0FBbUI7QUFDM0JHLGtCQUFZQSxVQURlLEVBQW5CLENBQVY7O0FBR0EsV0FBT0UsTUFBTUMsSUFBTixD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cEYsSUFBL0I7QUFDRDtBQUNGO0FBQ0Y7QUFDRixPQWJEO0FBY0QsS0FyUUQ7O0FBdVFBLFdBQU87QUFDTCxzQkFBZ0JpRixRQUFRO0FBQ3RCVSwwQkFBa0JWLElBQWxCO0FBQ0FlLDBCQUFrQmYsSUFBbEI7QUFDQUQsNEJBQW9CQyxJQUFwQjtBQUNELE9BTEk7QUFNTCxrQ0FBNEJBLFFBQVE7QUFDbENPLG1CQUFXUCxJQUFYLEVBQWlCdEgsd0JBQWpCO0FBQ0QsT0FSSTtBQVNMLGdDQUEwQnNILFFBQVE7QUFDaENBLGFBQUt0QyxVQUFMLENBQWdCL0QsT0FBaEIsQ0FBd0JrRCxhQUFhO0FBQ2pDMEQscUJBQVdQLElBQVgsRUFBaUJuRCxVQUFVaUUsUUFBVixDQUFtQnJILElBQXBDO0FBQ0gsU0FGRDtBQUdBTCxxQ0FBNkI0RyxLQUFLM0csV0FBbEMsRUFBZ0RJLElBQUQsSUFBVTtBQUN2RDhHLHFCQUFXUCxJQUFYLEVBQWlCdkcsSUFBakI7QUFDRCxTQUZEO0FBR0QsT0FoQkksRUFBUDs7QUFrQkQsR0E1Z0JjLEVBQWpCIiwiZmlsZSI6Im5vLXVudXNlZC1tb2R1bGVzLmpzIiwic291cmNlc0NvbnRlbnQiOlsiLyoqXG4gKiBAZmlsZU92ZXJ2aWV3IEVuc3VyZXMgdGhhdCBtb2R1bGVzIGNvbnRhaW4gZXhwb3J0cyBhbmQvb3IgYWxsXG4gKiBtb2R1bGVzIGFyZSBjb25zdW1lZCB3aXRoaW4gb3RoZXIgbW9kdWxlcy5cbiAqIEBhdXRob3IgUmVuw6kgRmVybWFublxuICovXG5cbmltcG9ydCBFeHBvcnRzIGZyb20gJy4uL0V4cG9ydE1hcCdcbmltcG9ydCB7IGdldEZpbGVFeHRlbnNpb25zIH0gZnJvbSAnZXNsaW50LW1vZHVsZS11dGlscy9pZ25vcmUnXG5pbXBvcnQgcmVzb2x2ZSBmcm9tICdlc2xpbnQtbW9kdWxlLXV0aWxzL3Jlc29sdmUnXG5pbXBvcnQgZG9jc1VybCBmcm9tICcuLi9kb2NzVXJsJ1xuaW1wb3J0IHsgZGlybmFtZSwgam9pbiB9IGZyb20gJ3BhdGgnXG5pbXBvcnQgcmVhZFBrZ1VwIGZyb20gJ3JlYWQtcGtnLXVwJ1xuaW1wb3J0IHZhbHVlcyBmcm9tICdvYmplY3QudmFsdWVzJ1xuaW1wb3J0IGluY2x1ZGVzIGZyb20gJ2FycmF5LWluY2x1ZGVzJ1xuXG4vLyBlc2xpbnQvbGliL3V0aWwvZ2xvYi11dGlsIGhhcyBiZWVuIG1vdmVkIHRvIGVzbGludC9saWIvdXRpbC9nbG9iLXV0aWxzIHdpdGggdmVyc2lvbiA1LjNcbi8vIGFuZCBoYXMgYmVlbiBtb3ZlZCB0byBlc2xpbnQvbGliL2NsaS1lbmdpbmUvZmlsZS1lbnVtZXJhdG9yIGluIHZlcnNpb24gNlxubGV0IGxpc3RGaWxlc1RvUHJvY2Vzc1xudHJ5IHtcbiAgY29uc3QgRmlsZUVudW1lcmF0b3IgPSByZXF1aXJlKCdlc2xpbnQvbGliL2NsaS1lbmdpbmUvZmlsZS1lbnVtZXJhdG9yJykuRmlsZUVudW1lcmF0b3JcbiAgbGlzdEZpbGVzVG9Qcm9jZXNzID0gZnVuY3Rpb24gKHNyYywgZXh0ZW5zaW9ucykge1xuICAgIGNvbnN0IGUgPSBuZXcgRmlsZUVudW1lcmF0b3Ioe1xuICAgICAgZXh0ZW5zaW9uczogZXh0ZW5zaW9ucyxcbiAgICB9KVxuICAgIHJldHVybiBBcnJheS5mcm9tKGUuaXRlcmF0ZUZpbGVzKHNyYyksICh7IGZpbGVQYXRoLCBpZ25vcmVkIH0pID0+ICh7XG4gICAgICBpZ25vcmVkLFxuICAgICAgZmlsZW5hbWU6IGZpbGVQYXRoLFxuICAgIH0pKVxuICB9XG59IGNhdGNoIChlMSkge1xuICAvLyBQcmV2ZW50IHBhc3NpbmcgaW52YWxpZCBvcHRpb25zIChleHRlbnNpb25zIGFycmF5KSB0byBvbGQgdmVyc2lvbnMgb2YgdGhlIGZ1bmN0aW9uLlxuICAvLyBodHRwczovL2dpdGh1Yi5jb20vZXNsaW50L2VzbGludC9ibG9iL3Y1LjE2LjAvbGliL3V0aWwvZ2xvYi11dGlscy5qcyNMMTc4LUwyODBcbiAgLy8gaHR0cHM6Ly9naXRodWIuY29tL2VzbGludC9lc2xpbnQvYmxvYi92NS4yLjAvbGliL3V0aWwvZ2xvYi11dGlsLmpzI0wxNzQtTDI2OVxuICBsZXQgb3JpZ2luYWxMaXN0RmlsZXNUb1Byb2Nlc3NcbiAgdHJ5IHtcbiAgICBvcmlnaW5hbExpc3RGaWxlc1RvUHJvY2VzcyA9IHJlcXVpcmUoJ2VzbGludC9saWIvdXRpbC9nbG9iLXV0aWxzJykubGlzdEZpbGVzVG9Qcm9jZXNzXG4gICAgbGlzdEZpbGVzVG9Qcm9jZXNzID0gZnVuY3Rpb24gKHNyYywgZXh0ZW5zaW9ucykge1xuICAgICAgcmV0dXJuIG9yaWdpbmFsTGlzdEZpbGVzVG9Qcm9jZXNzKHNyYywge1xuICAgICAgICBleHRlbnNpb25zOiBleHRlbnNpb25zLFxuICAgICAgfSlcbiAgICB9XG4gIH0gY2F0Y2ggKGUyKSB7XG4gICAgb3JpZ2luYWxMaXN0RmlsZXNUb1Byb2Nlc3MgPSByZXF1aXJlKCdlc2xpbnQvbGliL3V0aWwvZ2xvYi11dGlsJykubGlzdEZpbGVzVG9Qcm9jZXNzXG5cbiAgICBsaXN0RmlsZXNUb1Byb2Nlc3MgPSBmdW5jdGlvbiAoc3JjLCBleHRlbnNpb25zKSB7XG4gICAgICBjb25zdCBwYXR0ZXJucyA9IHNyYy5yZWR1Y2UoKGNhcnJ5LCBwYXR0ZXJuKSA9PiB7XG4gICAgICAgIHJldHVybiBjYXJyeS5jb25jYXQoZXh0ZW5zaW9ucy5tYXAoKGV4dGVuc2lvbikgPT4ge1xuICAgICAgICAgIHJldHVybiAvXFwqXFwqfFxcKlxcLi8udGVzdChwYXR0ZXJuKSA/IHBhdHRlcm4gOiBgJHtwYXR0ZXJufS8qKi8qJHtleHRlbnNpb259YFxuICAgICAgICB9KSlcbiAgICAgIH0sIHNyYy5zbGljZSgpKVxuXG4gICAgICByZXR1cm4gb3JpZ2luYWxMaXN0RmlsZXNUb1Byb2Nlc3MocGF0dGVybnMpXG4gICAgfVxuICB9XG59XG5cbmNvbnN0IEVYUE9SVF9ERUZBVUxUX0RFQ0xBUkFUSU9OID0gJ0V4cG9ydERlZmF1bHREZWNsYXJhdGlvbidcbmNvbnN0IEVYUE9SVF9OQU1FRF9ERUNMQVJBVElPTiA9ICdFeHBvcnROYW1lZERlY2xhcmF0aW9uJ1xuY29uc3QgRVhQT1JUX0FMTF9ERUNMQVJBVElPTiA9ICdFeHBvcnRBbGxEZWNsYXJhdGlvbidcbmNvbnN0IElNUE9SVF9ERUNMQVJBVElPTiA9ICdJbXBvcnREZWNsYXJhdGlvbidcbmNvbnN0IElNUE9SVF9OQU1FU1BBQ0VfU1BFQ0lGSUVSID0gJ0ltcG9ydE5hbWVzcGFjZVNwZWNpZmllcidcbmNvbnN0IElNUE9SVF9ERUZBVUxUX1NQRUNJRklFUiA9ICdJbXBvcnREZWZhdWx0U3BlY2lmaWVyJ1xuY29uc3QgVkFSSUFCTEVfREVDTEFSQVRJT04gPSAnVmFyaWFibGVEZWNsYXJhdGlvbidcbmNvbnN0IEZVTkNUSU9OX0RFQ0xBUkFUSU9OID0gJ0Z1bmN0aW9uRGVjbGFyYXRpb24nXG5jb25zdCBDTEFTU19ERUNMQVJBVElPTiA9ICdDbGFzc0RlY2xhcmF0aW9uJ1xuY29uc3QgSU5URVJGQUNFX0RFQ0xBUkFUSU9OID0gJ0ludGVyZmFjZURlY2xhcmF0aW9uJ1xuY29uc3QgVFlQRV9BTElBUyA9ICdUeXBlQWxpYXMnXG5jb25zdCBUU19JTlRFUkZBQ0VfREVDTEFSQVRJT04gPSAnVFNJbnRlcmZhY2VEZWNsYXJhdGlvbidcbmNvbnN0IFRTX1RZUEVfQUxJQVNfREVDTEFSQVRJT04gPSAnVFNUeXBlQWxpYXNEZWNsYXJhdGlvbidcbmNvbnN0IFRTX0VOVU1fREVDTEFSQVRJT04gPSAnVFNFbnVtRGVjbGFyYXRpb24nXG5jb25zdCBERUZBVUxUID0gJ2RlZmF1bHQnXG5cbmZ1bmN0aW9uIGZvckVhY2hEZWNsYXJhdGlvbklkZW50aWZpZXIoZGVjbGFyYXRpb24sIGNiKSB7XG4gIGlmIChkZWNsYXJhdGlvbikge1xuICAgIGlmIChcbiAgICAgIGRlY2xhcmF0aW9uLnR5cGUgPT09IEZVTkNUSU9OX0RFQ0xBUkFUSU9OIHx8XG4gICAgICBkZWNsYXJhdGlvbi50eXBlID09PSBDTEFTU19ERUNMQVJBVElPTiB8fFxuICAgICAgZGVjbGFyYXRpb24udHlwZSA9PT0gSU5URVJGQUNFX0RFQ0xBUkFUSU9OIHx8XG4gICAgICBkZWNsYXJhdGlvbi50eXBlID09PSBUWVBFX0FMSUFTIHx8XG4gICAgICBkZWNsYXJhdGlvbi50eXBlID09PSBUU19JTlRFUkZBQ0VfREVDTEFSQVRJT04gfHxcbiAgICAgIGRlY2xhcmF0aW9uLnR5cGUgPT09IFRTX1RZUEVfQUxJQVNfREVDTEFSQVRJT04gfHxcbiAgICAgIGRlY2xhcmF0aW9uLnR5cGUgPT09IFRTX0VOVU1fREVDTEFSQVRJT05cbiAgICApIHtcbiAgICAgIGNiKGRlY2xhcmF0aW9uLmlkLm5hbWUpXG4gICAgfSBlbHNlIGlmIChkZWNsYXJhdGlvbi50eXBlID09PSBWQVJJQUJMRV9ERUNMQVJBVElPTikge1xuICAgICAgZGVjbGFyYXRpb24uZGVjbGFyYXRpb25zLmZvckVhY2goKHsgaWQgfSkgPT4ge1xuICAgICAgICBjYihpZC5uYW1lKVxuICAgICAgfSlcbiAgICB9XG4gIH1cbn1cblxuLyoqXG4gKiBMaXN0IG9mIGltcG9ydHMgcGVyIGZpbGUuXG4gKlxuICogUmVwcmVzZW50ZWQgYnkgYSB0d28tbGV2ZWwgTWFwIHRvIGEgU2V0IG9mIGlkZW50aWZpZXJzLiBUaGUgdXBwZXItbGV2ZWwgTWFwXG4gKiBrZXlzIGFyZSB0aGUgcGF0aHMgdG8gdGhlIG1vZHVsZXMgY29udGFpbmluZyB0aGUgaW1wb3J0cywgd2hpbGUgdGhlXG4gKiBsb3dlci1sZXZlbCBNYXAga2V5cyBhcmUgdGhlIHBhdGhzIHRvIHRoZSBmaWxlcyB3aGljaCBhcmUgYmVpbmcgaW1wb3J0ZWRcbiAqIGZyb20uIExhc3RseSwgdGhlIFNldCBvZiBpZGVudGlmaWVycyBjb250YWlucyBlaXRoZXIgbmFtZXMgYmVpbmcgaW1wb3J0ZWRcbiAqIG9yIGEgc3BlY2lhbCBBU1Qgbm9kZSBuYW1lIGxpc3RlZCBhYm92ZSAoZS5nIEltcG9ydERlZmF1bHRTcGVjaWZpZXIpLlxuICpcbiAqIEZvciBleGFtcGxlLCBpZiB3ZSBoYXZlIGEgZmlsZSBuYW1lZCBmb28uanMgY29udGFpbmluZzpcbiAqXG4gKiAgIGltcG9ydCB7IG8yIH0gZnJvbSAnLi9iYXIuanMnO1xuICpcbiAqIFRoZW4gd2Ugd2lsbCBoYXZlIGEgc3RydWN0dXJlIHRoYXQgbG9va3MgbGlrZTpcbiAqXG4gKiAgIE1hcCB7ICdmb28uanMnID0+IE1hcCB7ICdiYXIuanMnID0+IFNldCB7ICdvMicgfSB9IH1cbiAqXG4gKiBAdHlwZSB7TWFwPHN0cmluZywgTWFwPHN0cmluZywgU2V0PHN0cmluZz4+Pn1cbiAqL1xuY29uc3QgaW1wb3J0TGlzdCA9IG5ldyBNYXAoKVxuXG4vKipcbiAqIExpc3Qgb2YgZXhwb3J0cyBwZXIgZmlsZS5cbiAqXG4gKiBSZXByZXNlbnRlZCBieSBhIHR3by1sZXZlbCBNYXAgdG8gYW4gb2JqZWN0IG9mIG1ldGFkYXRhLiBUaGUgdXBwZXItbGV2ZWwgTWFwXG4gKiBrZXlzIGFyZSB0aGUgcGF0aHMgdG8gdGhlIG1vZHVsZXMgY29udGFpbmluZyB0aGUgZXhwb3J0cywgd2hpbGUgdGhlXG4gKiBsb3dlci1sZXZlbCBNYXAga2V5cyBhcmUgdGhlIHNwZWNpZmljIGlkZW50aWZpZXJzIG9yIHNwZWNpYWwgQVNUIG5vZGUgbmFtZXNcbiAqIGJlaW5nIGV4cG9ydGVkLiBUaGUgbGVhZi1sZXZlbCBtZXRhZGF0YSBvYmplY3QgYXQgdGhlIG1vbWVudCBvbmx5IGNvbnRhaW5zIGFcbiAqIGB3aGVyZVVzZWRgIHByb3BvZXJ0eSwgd2hpY2ggY29udGFpbnMgYSBTZXQgb2YgcGF0aHMgdG8gbW9kdWxlcyB0aGF0IGltcG9ydFxuICogdGhlIG5hbWUuXG4gKlxuICogRm9yIGV4YW1wbGUsIGlmIHdlIGhhdmUgYSBmaWxlIG5hbWVkIGJhci5qcyBjb250YWluaW5nIHRoZSBmb2xsb3dpbmcgZXhwb3J0czpcbiAqXG4gKiAgIGNvbnN0IG8yID0gJ2Jhcic7XG4gKiAgIGV4cG9ydCB7IG8yIH07XG4gKlxuICogQW5kIGEgZmlsZSBuYW1lZCBmb28uanMgY29udGFpbmluZyB0aGUgZm9sbG93aW5nIGltcG9ydDpcbiAqXG4gKiAgIGltcG9ydCB7IG8yIH0gZnJvbSAnLi9iYXIuanMnO1xuICpcbiAqIFRoZW4gd2Ugd2lsbCBoYXZlIGEgc3RydWN0dXJlIHRoYXQgbG9va3MgbGlrZTpcbiAqXG4gKiAgIE1hcCB7ICdiYXIuanMnID0+IE1hcCB7ICdvMicgPT4geyB3aGVyZVVzZWQ6IFNldCB7ICdmb28uanMnIH0gfSB9IH1cbiAqXG4gKiBAdHlwZSB7TWFwPHN0cmluZywgTWFwPHN0cmluZywgb2JqZWN0Pj59XG4gKi9cbmNvbnN0IGV4cG9ydExpc3QgPSBuZXcgTWFwKClcblxuY29uc3QgaWdub3JlZEZpbGVzID0gbmV3IFNldCgpXG5jb25zdCBmaWxlc091dHNpZGVTcmMgPSBuZXcgU2V0KClcblxuY29uc3QgaXNOb2RlTW9kdWxlID0gcGF0aCA9PiB7XG4gIHJldHVybiAvXFwvKG5vZGVfbW9kdWxlcylcXC8vLnRlc3QocGF0aClcbn1cblxuLyoqXG4gKiByZWFkIGFsbCBmaWxlcyBtYXRjaGluZyB0aGUgcGF0dGVybnMgaW4gc3JjIGFuZCBpZ25vcmVFeHBvcnRzXG4gKlxuICogcmV0dXJuIGFsbCBmaWxlcyBtYXRjaGluZyBzcmMgcGF0dGVybiwgd2hpY2ggYXJlIG5vdCBtYXRjaGluZyB0aGUgaWdub3JlRXhwb3J0cyBwYXR0ZXJuXG4gKi9cbmNvbnN0IHJlc29sdmVGaWxlcyA9IChzcmMsIGlnbm9yZUV4cG9ydHMsIGNvbnRleHQpID0+IHtcbiAgY29uc3QgZXh0ZW5zaW9ucyA9IEFycmF5LmZyb20oZ2V0RmlsZUV4dGVuc2lvbnMoY29udGV4dC5zZXR0aW5ncykpXG5cbiAgY29uc3Qgc3JjRmlsZXMgPSBuZXcgU2V0KClcbiAgY29uc3Qgc3JjRmlsZUxpc3QgPSBsaXN0RmlsZXNUb1Byb2Nlc3Moc3JjLCBleHRlbnNpb25zKVxuXG4gIC8vIHByZXBhcmUgbGlzdCBvZiBpZ25vcmVkIGZpbGVzXG4gIGNvbnN0IGlnbm9yZWRGaWxlc0xpc3QgPSAgbGlzdEZpbGVzVG9Qcm9jZXNzKGlnbm9yZUV4cG9ydHMsIGV4dGVuc2lvbnMpXG4gIGlnbm9yZWRGaWxlc0xpc3QuZm9yRWFjaCgoeyBmaWxlbmFtZSB9KSA9PiBpZ25vcmVkRmlsZXMuYWRkKGZpbGVuYW1lKSlcblxuICAvLyBwcmVwYXJlIGxpc3Qgb2Ygc291cmNlIGZpbGVzLCBkb24ndCBjb25zaWRlciBmaWxlcyBmcm9tIG5vZGVfbW9kdWxlc1xuICBzcmNGaWxlTGlzdC5maWx0ZXIoKHsgZmlsZW5hbWUgfSkgPT4gIWlzTm9kZU1vZHVsZShmaWxlbmFtZSkpLmZvckVhY2goKHsgZmlsZW5hbWUgfSkgPT4ge1xuICAgIHNyY0ZpbGVzLmFkZChmaWxlbmFtZSlcbiAgfSlcbiAgcmV0dXJuIHNyY0ZpbGVzXG59XG5cbi8qKlxuICogcGFyc2UgYWxsIHNvdXJjZSBmaWxlcyBhbmQgYnVpbGQgdXAgMiBtYXBzIGNvbnRhaW5pbmcgdGhlIGV4aXN0aW5nIGltcG9ydHMgYW5kIGV4cG9ydHNcbiAqL1xuY29uc3QgcHJlcGFyZUltcG9ydHNBbmRFeHBvcnRzID0gKHNyY0ZpbGVzLCBjb250ZXh0KSA9PiB7XG4gIGNvbnN0IGV4cG9ydEFsbCA9IG5ldyBNYXAoKVxuICBzcmNGaWxlcy5mb3JFYWNoKGZpbGUgPT4ge1xuICAgIGNvbnN0IGV4cG9ydHMgPSBuZXcgTWFwKClcbiAgICBjb25zdCBpbXBvcnRzID0gbmV3IE1hcCgpXG4gICAgY29uc3QgY3VycmVudEV4cG9ydHMgPSBFeHBvcnRzLmdldChmaWxlLCBjb250ZXh0KVxuICAgIGlmIChjdXJyZW50RXhwb3J0cykge1xuICAgICAgY29uc3QgeyBkZXBlbmRlbmNpZXMsIHJlZXhwb3J0cywgaW1wb3J0czogbG9jYWxJbXBvcnRMaXN0LCBuYW1lc3BhY2UgIH0gPSBjdXJyZW50RXhwb3J0c1xuXG4gICAgICAvLyBkZXBlbmRlbmNpZXMgPT09IGV4cG9ydCAqIGZyb21cbiAgICAgIGNvbnN0IGN1cnJlbnRFeHBvcnRBbGwgPSBuZXcgU2V0KClcbiAgICAgIGRlcGVuZGVuY2llcy5mb3JFYWNoKGdldERlcGVuZGVuY3kgPT4ge1xuICAgICAgICBjb25zdCBkZXBlbmRlbmN5ID0gZ2V0RGVwZW5kZW5jeSgpXG4gICAgICAgIGlmIChkZXBlbmRlbmN5ID09PSBudWxsKSB7XG4gICAgICAgICAgcmV0dXJuXG4gICAgICAgIH1cblxuICAgICAgICBjdXJyZW50RXhwb3J0QWxsLmFkZChkZXBlbmRlbmN5LnBhdGgpXG4gICAgICB9KVxuICAgICAgZXhwb3J0QWxsLnNldChmaWxlLCBjdXJyZW50RXhwb3J0QWxsKVxuXG4gICAgICByZWV4cG9ydHMuZm9yRWFjaCgodmFsdWUsIGtleSkgPT4ge1xuICAgICAgICBpZiAoa2V5ID09PSBERUZBVUxUKSB7XG4gICAgICAgICAgZXhwb3J0cy5zZXQoSU1QT1JUX0RFRkFVTFRfU1BFQ0lGSUVSLCB7IHdoZXJlVXNlZDogbmV3IFNldCgpIH0pXG4gICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgZXhwb3J0cy5zZXQoa2V5LCB7IHdoZXJlVXNlZDogbmV3IFNldCgpIH0pXG4gICAgICAgIH1cbiAgICAgICAgY29uc3QgcmVleHBvcnQgPSAgdmFsdWUuZ2V0SW1wb3J0KClcbiAgICAgICAgaWYgKCFyZWV4cG9ydCkge1xuICAgICAgICAgIHJldHVyblxuICAgICAgICB9XG4gICAgICAgIGxldCBsb2NhbEltcG9ydCA9IGltcG9ydHMuZ2V0KHJlZXhwb3J0LnBhdGgpXG4gICAgICAgIGxldCBjdXJyZW50VmFsdWVcbiAgICAgICAgaWYgKHZhbHVlLmxvY2FsID09PSBERUZBVUxUKSB7XG4gICAgICAgICAgY3VycmVudFZhbHVlID0gSU1QT1JUX0RFRkFVTFRfU1BFQ0lGSUVSXG4gICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgY3VycmVudFZhbHVlID0gdmFsdWUubG9jYWxcbiAgICAgICAgfVxuICAgICAgICBpZiAodHlwZW9mIGxvY2FsSW1wb3J0ICE9PSAndW5kZWZpbmVkJykge1xuICAgICAgICAgIGxvY2FsSW1wb3J0ID0gbmV3IFNldChbLi4ubG9jYWxJbXBvcnQsIGN1cnJlbnRWYWx1ZV0pXG4gICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgbG9jYWxJbXBvcnQgPSBuZXcgU2V0KFtjdXJyZW50VmFsdWVdKVxuICAgICAgICB9XG4gICAgICAgIGltcG9ydHMuc2V0KHJlZXhwb3J0LnBhdGgsIGxvY2FsSW1wb3J0KVxuICAgICAgfSlcblxuICAgICAgbG9jYWxJbXBvcnRMaXN0LmZvckVhY2goKHZhbHVlLCBrZXkpID0+IHtcbiAgICAgICAgaWYgKGlzTm9kZU1vZHVsZShrZXkpKSB7XG4gICAgICAgICAgcmV0dXJuXG4gICAgICAgIH1cbiAgICAgICAgbGV0IGxvY2FsSW1wb3J0ID0gaW1wb3J0cy5nZXQoa2V5KVxuICAgICAgICBpZiAodHlwZW9mIGxvY2FsSW1wb3J0ICE9PSAndW5kZWZpbmVkJykge1xuICAgICAgICAgIGxvY2FsSW1wb3J0ID0gbmV3IFNldChbLi4ubG9jYWxJbXBvcnQsIC4uLnZhbHVlLmltcG9ydGVkU3BlY2lmaWVyc10pXG4gICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgbG9jYWxJbXBvcnQgPSB2YWx1ZS5pbXBvcnRlZFNwZWNpZmllcnNcbiAgICAgICAgfVxuICAgICAgICBpbXBvcnRzLnNldChrZXksIGxvY2FsSW1wb3J0KVxuICAgICAgfSlcbiAgICAgIGltcG9ydExpc3Quc2V0KGZpbGUsIGltcG9ydHMpXG5cbiAgICAgIC8vIGJ1aWxkIHVwIGV4cG9ydCBsaXN0IG9ubHksIGlmIGZpbGUgaXMgbm90IGlnbm9yZWRcbiAgICAgIGlmIChpZ25vcmVkRmlsZXMuaGFzKGZpbGUpKSB7XG4gICAgICAgIHJldHVyblxuICAgICAgfVxuICAgICAgbmFtZXNwYWNlLmZvckVhY2goKHZhbHVlLCBrZXkpID0+IHtcbiAgICAgICAgaWYgKGtleSA9PT0gREVGQVVMVCkge1xuICAgICAgICAgIGV4cG9ydHMuc2V0KElNUE9SVF9ERUZBVUxUX1NQRUNJRklFUiwgeyB3aGVyZVVzZWQ6IG5ldyBTZXQoKSB9KVxuICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgIGV4cG9ydHMuc2V0KGtleSwgeyB3aGVyZVVzZWQ6IG5ldyBTZXQoKSB9KVxuICAgICAgICB9XG4gICAgICB9KVxuICAgIH1cbiAgICBleHBvcnRzLnNldChFWFBPUlRfQUxMX0RFQ0xBUkFUSU9OLCB7IHdoZXJlVXNlZDogbmV3IFNldCgpIH0pXG4gICAgZXhwb3J0cy5zZXQoSU1QT1JUX05BTUVTUEFDRV9TUEVDSUZJRVIsIHsgd2hlcmVVc2VkOiBuZXcgU2V0KCkgfSlcbiAgICBleHBvcnRMaXN0LnNldChmaWxlLCBleHBvcnRzKVxuICB9KVxuICBleHBvcnRBbGwuZm9yRWFjaCgodmFsdWUsIGtleSkgPT4ge1xuICAgIHZhbHVlLmZvckVhY2godmFsID0+IHtcbiAgICAgIGNvbnN0IGN1cnJlbnRFeHBvcnRzID0gZXhwb3J0TGlzdC5nZXQodmFsKVxuICAgICAgY29uc3QgY3VycmVudEV4cG9ydCA9IGN1cnJlbnRFeHBvcnRzLmdldChFWFBPUlRfQUxMX0RFQ0xBUkFUSU9OKVxuICAgICAgY3VycmVudEV4cG9ydC53aGVyZVVzZWQuYWRkKGtleSlcbiAgICB9KVxuICB9KVxufVxuXG4vKipcbiAqIHRyYXZlcnNlIHRocm91Z2ggYWxsIGltcG9ydHMgYW5kIGFkZCB0aGUgcmVzcGVjdGl2ZSBwYXRoIHRvIHRoZSB3aGVyZVVzZWQtbGlzdFxuICogb2YgdGhlIGNvcnJlc3BvbmRpbmcgZXhwb3J0XG4gKi9cbmNvbnN0IGRldGVybWluZVVzYWdlID0gKCkgPT4ge1xuICBpbXBvcnRMaXN0LmZvckVhY2goKGxpc3RWYWx1ZSwgbGlzdEtleSkgPT4ge1xuICAgIGxpc3RWYWx1ZS5mb3JFYWNoKCh2YWx1ZSwga2V5KSA9PiB7XG4gICAgICBjb25zdCBleHBvcnRzID0gZXhwb3J0TGlzdC5nZXQoa2V5KVxuICAgICAgaWYgKHR5cGVvZiBleHBvcnRzICE9PSAndW5kZWZpbmVkJykge1xuICAgICAgICB2YWx1ZS5mb3JFYWNoKGN1cnJlbnRJbXBvcnQgPT4ge1xuICAgICAgICAgIGxldCBzcGVjaWZpZXJcbiAgICAgICAgICBpZiAoY3VycmVudEltcG9ydCA9PT0gSU1QT1JUX05BTUVTUEFDRV9TUEVDSUZJRVIpIHtcbiAgICAgICAgICAgIHNwZWNpZmllciA9IElNUE9SVF9OQU1FU1BBQ0VfU1BFQ0lGSUVSXG4gICAgICAgICAgfSBlbHNlIGlmIChjdXJyZW50SW1wb3J0ID09PSBJTVBPUlRfREVGQVVMVF9TUEVDSUZJRVIpIHtcbiAgICAgICAgICAgIHNwZWNpZmllciA9IElNUE9SVF9ERUZBVUxUX1NQRUNJRklFUlxuICAgICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgICBzcGVjaWZpZXIgPSBjdXJyZW50SW1wb3J0XG4gICAgICAgICAgfVxuICAgICAgICAgIGlmICh0eXBlb2Ygc3BlY2lmaWVyICE9PSAndW5kZWZpbmVkJykge1xuICAgICAgICAgICAgY29uc3QgZXhwb3J0U3RhdGVtZW50ID0gZXhwb3J0cy5nZXQoc3BlY2lmaWVyKVxuICAgICAgICAgICAgaWYgKHR5cGVvZiBleHBvcnRTdGF0ZW1lbnQgIT09ICd1bmRlZmluZWQnKSB7XG4gICAgICAgICAgICAgIGNvbnN0IHsgd2hlcmVVc2VkIH0gPSBleHBvcnRTdGF0ZW1lbnRcbiAgICAgICAgICAgICAgd2hlcmVVc2VkLmFkZChsaXN0S2V5KVxuICAgICAgICAgICAgICBleHBvcnRzLnNldChzcGVjaWZpZXIsIHsgd2hlcmVVc2VkIH0pXG4gICAgICAgICAgICB9XG4gICAgICAgICAgfVxuICAgICAgICB9KVxuICAgICAgfVxuICAgIH0pXG4gIH0pXG59XG5cbmNvbnN0IGdldFNyYyA9IHNyYyA9PiB7XG4gIGlmIChzcmMpIHtcbiAgICByZXR1cm4gc3JjXG4gIH1cbiAgcmV0dXJuIFtwcm9jZXNzLmN3ZCgpXVxufVxuXG4vKipcbiAqIHByZXBhcmUgdGhlIGxpc3RzIG9mIGV4aXN0aW5nIGltcG9ydHMgYW5kIGV4cG9ydHMgLSBzaG91bGQgb25seSBiZSBleGVjdXRlZCBvbmNlIGF0XG4gKiB0aGUgc3RhcnQgb2YgYSBuZXcgZXNsaW50IHJ1blxuICovXG5sZXQgc3JjRmlsZXNcbmxldCBsYXN0UHJlcGFyZUtleVxuY29uc3QgZG9QcmVwYXJhdGlvbiA9IChzcmMsIGlnbm9yZUV4cG9ydHMsIGNvbnRleHQpID0+IHtcbiAgY29uc3QgcHJlcGFyZUtleSA9IEpTT04uc3RyaW5naWZ5KHtcbiAgICBzcmM6IChzcmMgfHwgW10pLnNvcnQoKSxcbiAgICBpZ25vcmVFeHBvcnRzOiAoaWdub3JlRXhwb3J0cyB8fCBbXSkuc29ydCgpLFxuICAgIGV4dGVuc2lvbnM6IEFycmF5LmZyb20oZ2V0RmlsZUV4dGVuc2lvbnMoY29udGV4dC5zZXR0aW5ncykpLnNvcnQoKSxcbiAgfSlcbiAgaWYgKHByZXBhcmVLZXkgPT09IGxhc3RQcmVwYXJlS2V5KSB7XG4gICAgcmV0dXJuXG4gIH1cblxuICBpbXBvcnRMaXN0LmNsZWFyKClcbiAgZXhwb3J0TGlzdC5jbGVhcigpXG4gIGlnbm9yZWRGaWxlcy5jbGVhcigpXG4gIGZpbGVzT3V0c2lkZVNyYy5jbGVhcigpXG5cbiAgc3JjRmlsZXMgPSByZXNvbHZlRmlsZXMoZ2V0U3JjKHNyYyksIGlnbm9yZUV4cG9ydHMsIGNvbnRleHQpXG4gIHByZXBhcmVJbXBvcnRzQW5kRXhwb3J0cyhzcmNGaWxlcywgY29udGV4dClcbiAgZGV0ZXJtaW5lVXNhZ2UoKVxuICBsYXN0UHJlcGFyZUtleSA9IHByZXBhcmVLZXlcbn1cblxuY29uc3QgbmV3TmFtZXNwYWNlSW1wb3J0RXhpc3RzID0gc3BlY2lmaWVycyA9PlxuICBzcGVjaWZpZXJzLnNvbWUoKHsgdHlwZSB9KSA9PiB0eXBlID09PSBJTVBPUlRfTkFNRVNQQUNFX1NQRUNJRklFUilcblxuY29uc3QgbmV3RGVmYXVsdEltcG9ydEV4aXN0cyA9IHNwZWNpZmllcnMgPT5cbiAgc3BlY2lmaWVycy5zb21lKCh7IHR5cGUgfSkgPT4gdHlwZSA9PT0gSU1QT1JUX0RFRkFVTFRfU1BFQ0lGSUVSKVxuXG5jb25zdCBmaWxlSXNJblBrZyA9IGZpbGUgPT4ge1xuICBjb25zdCB7IHBhdGgsIHBrZyB9ID0gcmVhZFBrZ1VwLnN5bmMoe2N3ZDogZmlsZSwgbm9ybWFsaXplOiBmYWxzZX0pXG4gIGNvbnN0IGJhc2VQYXRoID0gZGlybmFtZShwYXRoKVxuXG4gIGNvbnN0IGNoZWNrUGtnRmllbGRTdHJpbmcgPSBwa2dGaWVsZCA9PiB7XG4gICAgaWYgKGpvaW4oYmFzZVBhdGgsIHBrZ0ZpZWxkKSA9PT0gZmlsZSkge1xuICAgICAgICByZXR1cm4gdHJ1ZVxuICAgICAgfVxuICB9XG5cbiAgY29uc3QgY2hlY2tQa2dGaWVsZE9iamVjdCA9IHBrZ0ZpZWxkID0+IHtcbiAgICAgIGNvbnN0IHBrZ0ZpZWxkRmlsZXMgPSB2YWx1ZXMocGtnRmllbGQpLm1hcCh2YWx1ZSA9PiBqb2luKGJhc2VQYXRoLCB2YWx1ZSkpXG4gICAgICBpZiAoaW5jbHVkZXMocGtnRmllbGRGaWxlcywgZmlsZSkpIHtcbiAgICAgICAgcmV0dXJuIHRydWVcbiAgICAgIH1cbiAgfVxuXG4gIGNvbnN0IGNoZWNrUGtnRmllbGQgPSBwa2dGaWVsZCA9PiB7XG4gICAgaWYgKHR5cGVvZiBwa2dGaWVsZCA9PT0gJ3N0cmluZycpIHtcbiAgICAgIHJldHVybiBjaGVja1BrZ0ZpZWxkU3RyaW5nKHBrZ0ZpZWxkKVxuICAgIH1cblxuICAgIGlmICh0eXBlb2YgcGtnRmllbGQgPT09ICdvYmplY3QnKSB7XG4gICAgICByZXR1cm4gY2hlY2tQa2dGaWVsZE9iamVjdChwa2dGaWVsZClcbiAgICB9XG4gIH1cblxuICBpZiAocGtnLnByaXZhdGUgPT09IHRydWUpIHtcbiAgICByZXR1cm4gZmFsc2VcbiAgfVxuXG4gIGlmIChwa2cuYmluKSB7XG4gICAgaWYgKGNoZWNrUGtnRmllbGQocGtnLmJpbikpIHtcbiAgICAgIHJldHVybiB0cnVlXG4gICAgfVxuICB9XG5cbiAgaWYgKHBrZy5icm93c2VyKSB7XG4gICAgaWYgKGNoZWNrUGtnRmllbGQocGtnLmJyb3dzZXIpKSB7XG4gICAgICByZXR1cm4gdHJ1ZVxuICAgIH1cbiAgfVxuXG4gIGlmIChwa2cubWFpbikge1xuICAgIGlmIChjaGVja1BrZ0ZpZWxkU3RyaW5nKHBrZy5tYWluKSkge1xuICAgICAgcmV0dXJuIHRydWVcbiAgICB9XG4gIH1cblxuICByZXR1cm4gZmFsc2Vcbn1cblxubW9kdWxlLmV4cG9ydHMgPSB7XG4gIG1ldGE6IHtcbiAgICB0eXBlOiAnc3VnZ2VzdGlvbicsXG4gICAgZG9jczogeyB1cmw6IGRvY3NVcmwoJ25vLXVudXNlZC1tb2R1bGVzJykgfSxcbiAgICBzY2hlbWE6IFt7XG4gICAgICBwcm9wZXJ0aWVzOiB7XG4gICAgICAgIHNyYzoge1xuICAgICAgICAgIGRlc2NyaXB0aW9uOiAnZmlsZXMvcGF0aHMgdG8gYmUgYW5hbHl6ZWQgKG9ubHkgZm9yIHVudXNlZCBleHBvcnRzKScsXG4gICAgICAgICAgdHlwZTogJ2FycmF5JyxcbiAgICAgICAgICBtaW5JdGVtczogMSxcbiAgICAgICAgICBpdGVtczoge1xuICAgICAgICAgICAgdHlwZTogJ3N0cmluZycsXG4gICAgICAgICAgICBtaW5MZW5ndGg6IDEsXG4gICAgICAgICAgfSxcbiAgICAgICAgfSxcbiAgICAgICAgaWdub3JlRXhwb3J0czoge1xuICAgICAgICAgIGRlc2NyaXB0aW9uOlxuICAgICAgICAgICAgJ2ZpbGVzL3BhdGhzIGZvciB3aGljaCB1bnVzZWQgZXhwb3J0cyB3aWxsIG5vdCBiZSByZXBvcnRlZCAoZS5nIG1vZHVsZSBlbnRyeSBwb2ludHMpJyxcbiAgICAgICAgICB0eXBlOiAnYXJyYXknLFxuICAgICAgICAgIG1pbkl0ZW1zOiAxLFxuICAgICAgICAgIGl0ZW1zOiB7XG4gICAgICAgICAgICB0eXBlOiAnc3RyaW5nJyxcbiAgICAgICAgICAgIG1pbkxlbmd0aDogMSxcbiAgICAgICAgICB9LFxuICAgICAgICB9LFxuICAgICAgICBtaXNzaW5nRXhwb3J0czoge1xuICAgICAgICAgIGRlc2NyaXB0aW9uOiAncmVwb3J0IG1vZHVsZXMgd2l0aG91dCBhbnkgZXhwb3J0cycsXG4gICAgICAgICAgdHlwZTogJ2Jvb2xlYW4nLFxuICAgICAgICB9LFxuICAgICAgICB1bnVzZWRFeHBvcnRzOiB7XG4gICAgICAgICAgZGVzY3JpcHRpb246ICdyZXBvcnQgZXhwb3J0cyB3aXRob3V0IGFueSB1c2FnZScsXG4gICAgICAgICAgdHlwZTogJ2Jvb2xlYW4nLFxuICAgICAgICB9LFxuICAgICAgfSxcbiAgICAgIG5vdDoge1xuICAgICAgICBwcm9wZXJ0aWVzOiB7XG4gICAgICAgICAgdW51c2VkRXhwb3J0czogeyBlbnVtOiBbZmFsc2VdIH0sXG4gICAgICAgICAgbWlzc2luZ0V4cG9ydHM6IHsgZW51bTogW2ZhbHNlXSB9LFxuICAgICAgICB9LFxuICAgICAgfSxcbiAgICAgIGFueU9mOlt7XG4gICAgICAgIG5vdDoge1xuICAgICAgICAgIHByb3BlcnRpZXM6IHtcbiAgICAgICAgICAgIHVudXNlZEV4cG9ydHM6IHsgZW51bTogW3RydWVdIH0sXG4gICAgICAgICAgfSxcbiAgICAgICAgfSxcbiAgICAgICAgcmVxdWlyZWQ6IFsnbWlzc2luZ0V4cG9ydHMnXSxcbiAgICAgIH0sIHtcbiAgICAgICAgbm90OiB7XG4gICAgICAgICAgcHJvcGVydGllczoge1xuICAgICAgICAgICAgbWlzc2luZ0V4cG9ydHM6IHsgZW51bTogW3RydWVdIH0sXG4gICAgICAgICAgfSxcbiAgICAgICAgfSxcbiAgICAgICAgcmVxdWlyZWQ6IFsndW51c2VkRXhwb3J0cyddLFxuICAgICAgfSwge1xuICAgICAgICBwcm9wZXJ0aWVzOiB7XG4gICAgICAgICAgdW51c2VkRXhwb3J0czogeyBlbnVtOiBbdHJ1ZV0gfSxcbiAgICAgICAgfSxcbiAgICAgICAgcmVxdWlyZWQ6IFsndW51c2VkRXhwb3J0cyddLFxuICAgICAgfSwge1xuICAgICAgICBwcm9wZXJ0aWVzOiB7XG4gICAgICAgICAgbWlzc2luZ0V4cG9ydHM6IHsgZW51bTogW3RydWVdIH0sXG4gICAgICAgIH0sXG4gICAgICAgIHJlcXVpcmVkOiBbJ21pc3NpbmdFeHBvcnRzJ10sXG4gICAgICB9XSxcbiAgICB9XSxcbiAgfSxcblxuICBjcmVhdGU6IGNvbnRleHQgPT4ge1xuICAgIGNvbnN0IHtcbiAgICAgIHNyYyxcbiAgICAgIGlnbm9yZUV4cG9ydHMgPSBbXSxcbiAgICAgIG1pc3NpbmdFeHBvcnRzLFxuICAgICAgdW51c2VkRXhwb3J0cyxcbiAgICB9ID0gY29udGV4dC5vcHRpb25zWzBdIHx8IHt9XG5cbiAgICBpZiAodW51c2VkRXhwb3J0cykge1xuICAgICAgZG9QcmVwYXJhdGlvbihzcmMsIGlnbm9yZUV4cG9ydHMsIGNvbnRleHQpXG4gICAgfVxuXG4gICAgY29uc3QgZmlsZSA9IGNvbnRleHQuZ2V0RmlsZW5hbWUoKVxuXG4gICAgY29uc3QgY2hlY2tFeHBvcnRQcmVzZW5jZSA9IG5vZGUgPT4ge1xuICAgICAgaWYgKCFtaXNzaW5nRXhwb3J0cykge1xuICAgICAgICByZXR1cm5cbiAgICAgIH1cblxuICAgICAgaWYgKGlnbm9yZWRGaWxlcy5oYXMoZmlsZSkpIHtcbiAgICAgICAgcmV0dXJuXG4gICAgICB9XG5cbiAgICAgIGNvbnN0IGV4cG9ydENvdW50ID0gZXhwb3J0TGlzdC5nZXQoZmlsZSlcbiAgICAgIGNvbnN0IGV4cG9ydEFsbCA9IGV4cG9ydENvdW50LmdldChFWFBPUlRfQUxMX0RFQ0xBUkFUSU9OKVxuICAgICAgY29uc3QgbmFtZXNwYWNlSW1wb3J0cyA9IGV4cG9ydENvdW50LmdldChJTVBPUlRfTkFNRVNQQUNFX1NQRUNJRklFUilcblxuICAgICAgZXhwb3J0Q291bnQuZGVsZXRlKEVYUE9SVF9BTExfREVDTEFSQVRJT04pXG4gICAgICBleHBvcnRDb3VudC5kZWxldGUoSU1QT1JUX05BTUVTUEFDRV9TUEVDSUZJRVIpXG4gICAgICBpZiAoZXhwb3J0Q291bnQuc2l6ZSA8IDEpIHtcbiAgICAgICAgLy8gbm9kZS5ib2R5WzBdID09PSAndW5kZWZpbmVkJyBvbmx5IGhhcHBlbnMsIGlmIGV2ZXJ5dGhpbmcgaXMgY29tbWVudGVkIG91dCBpbiB0aGUgZmlsZVxuICAgICAgICAvLyBiZWluZyBsaW50ZWRcbiAgICAgICAgY29udGV4dC5yZXBvcnQobm9kZS5ib2R5WzBdID8gbm9kZS5ib2R5WzBdIDogbm9kZSwgJ05vIGV4cG9ydHMgZm91bmQnKVxuICAgICAgfVxuICAgICAgZXhwb3J0Q291bnQuc2V0KEVYUE9SVF9BTExfREVDTEFSQVRJT04sIGV4cG9ydEFsbClcbiAgICAgIGV4cG9ydENvdW50LnNldChJTVBPUlRfTkFNRVNQQUNFX1NQRUNJRklFUiwgbmFtZXNwYWNlSW1wb3J0cylcbiAgICB9XG5cbiAgICBjb25zdCBjaGVja1VzYWdlID0gKG5vZGUsIGV4cG9ydGVkVmFsdWUpID0+IHtcbiAgICAgIGlmICghdW51c2VkRXhwb3J0cykge1xuICAgICAgICByZXR1cm5cbiAgICAgIH1cblxuICAgICAgaWYgKGlnbm9yZWRGaWxlcy5oYXMoZmlsZSkpIHtcbiAgICAgICAgcmV0dXJuXG4gICAgICB9XG5cbiAgICAgIGlmIChmaWxlSXNJblBrZyhmaWxlKSkge1xuICAgICAgICByZXR1cm5cbiAgICAgIH1cblxuICAgICAgaWYgKGZpbGVzT3V0c2lkZVNyYy5oYXMoZmlsZSkpIHtcbiAgICAgICAgcmV0dXJuXG4gICAgICB9XG5cbiAgICAgIC8vIG1ha2Ugc3VyZSBmaWxlIHRvIGJlIGxpbnRlZCBpcyBpbmNsdWRlZCBpbiBzb3VyY2UgZmlsZXNcbiAgICAgIGlmICghc3JjRmlsZXMuaGFzKGZpbGUpKSB7XG4gICAgICAgIHNyY0ZpbGVzID0gcmVzb2x2ZUZpbGVzKGdldFNyYyhzcmMpLCBpZ25vcmVFeHBvcnRzLCBjb250ZXh0KVxuICAgICAgICBpZiAoIXNyY0ZpbGVzLmhhcyhmaWxlKSkge1xuICAgICAgICAgIGZpbGVzT3V0c2lkZVNyYy5hZGQoZmlsZSlcbiAgICAgICAgICByZXR1cm5cbiAgICAgICAgfVxuICAgICAgfVxuXG4gICAgICBleHBvcnRzID0gZXhwb3J0TGlzdC5nZXQoZmlsZSlcblxuICAgICAgLy8gc3BlY2lhbCBjYXNlOiBleHBvcnQgKiBmcm9tXG4gICAgICBjb25zdCBleHBvcnRBbGwgPSBleHBvcnRzLmdldChFWFBPUlRfQUxMX0RFQ0xBUkFUSU9OKVxuICAgICAgaWYgKHR5cGVvZiBleHBvcnRBbGwgIT09ICd1bmRlZmluZWQnICYmIGV4cG9ydGVkVmFsdWUgIT09IElNUE9SVF9ERUZBVUxUX1NQRUNJRklFUikge1xuICAgICAgICBpZiAoZXhwb3J0QWxsLndoZXJlVXNlZC5zaXplID4gMCkge1xuICAgICAgICAgIHJldHVyblxuICAgICAgICB9XG4gICAgICB9XG5cbiAgICAgIC8vIHNwZWNpYWwgY2FzZTogbmFtZXNwYWNlIGltcG9ydFxuICAgICAgY29uc3QgbmFtZXNwYWNlSW1wb3J0cyA9IGV4cG9ydHMuZ2V0KElNUE9SVF9OQU1FU1BBQ0VfU1BFQ0lGSUVSKVxuICAgICAgaWYgKHR5cGVvZiBuYW1lc3BhY2VJbXBvcnRzICE9PSAndW5kZWZpbmVkJykge1xuICAgICAgICBpZiAobmFtZXNwYWNlSW1wb3J0cy53aGVyZVVzZWQuc2l6ZSA+IDApIHtcbiAgICAgICAgICByZXR1cm5cbiAgICAgICAgfVxuICAgICAgfVxuXG4gICAgICAvLyBleHBvcnRzTGlzdCB3aWxsIGFsd2F5cyBtYXAgYW55IGltcG9ydGVkIHZhbHVlIG9mICdkZWZhdWx0JyB0byAnSW1wb3J0RGVmYXVsdFNwZWNpZmllcidcbiAgICAgIGNvbnN0IGV4cG9ydHNLZXkgPSBleHBvcnRlZFZhbHVlID09PSBERUZBVUxUID8gSU1QT1JUX0RFRkFVTFRfU1BFQ0lGSUVSIDogZXhwb3J0ZWRWYWx1ZVxuXG4gICAgICBjb25zdCBleHBvcnRTdGF0ZW1lbnQgPSBleHBvcnRzLmdldChleHBvcnRzS2V5KVxuXG4gICAgICBjb25zdCB2YWx1ZSA9IGV4cG9ydHNLZXkgPT09IElNUE9SVF9ERUZBVUxUX1NQRUNJRklFUiA/IERFRkFVTFQgOiBleHBvcnRzS2V5XG5cbiAgICAgIGlmICh0eXBlb2YgZXhwb3J0U3RhdGVtZW50ICE9PSAndW5kZWZpbmVkJyl7XG4gICAgICAgIGlmIChleHBvcnRTdGF0ZW1lbnQud2hlcmVVc2VkLnNpemUgPCAxKSB7XG4gICAgICAgICAgY29udGV4dC5yZXBvcnQoXG4gICAgICAgICAgICBub2RlLFxuICAgICAgICAgICAgYGV4cG9ydGVkIGRlY2xhcmF0aW9uICcke3ZhbHVlfScgbm90IHVzZWQgd2l0aGluIG90aGVyIG1vZHVsZXNgXG4gICAgICAgICAgKVxuICAgICAgICB9XG4gICAgICB9IGVsc2Uge1xuICAgICAgICBjb250ZXh0LnJlcG9ydChcbiAgICAgICAgICBub2RlLFxuICAgICAgICAgIGBleHBvcnRlZCBkZWNsYXJhdGlvbiAnJHt2YWx1ZX0nIG5vdCB1c2VkIHdpdGhpbiBvdGhlciBtb2R1bGVzYFxuICAgICAgICApXG4gICAgICB9XG4gICAgfVxuXG4gICAgLyoqXG4gICAgICogb25seSB1c2VmdWwgZm9yIHRvb2xzIGxpa2UgdnNjb2RlLWVzbGludFxuICAgICAqXG4gICAgICogdXBkYXRlIGxpc3RzIG9mIGV4aXN0aW5nIGV4cG9ydHMgZHVyaW5nIHJ1bnRpbWVcbiAgICAgKi9cbiAgICBjb25zdCB1cGRhdGVFeHBvcnRVc2FnZSA9IG5vZGUgPT4ge1xuICAgICAgaWYgKGlnbm9yZWRGaWxlcy5oYXMoZmlsZSkpIHtcbiAgICAgICAgcmV0dXJuXG4gICAgICB9XG5cbiAgICAgIGxldCBleHBvcnRzID0gZXhwb3J0TGlzdC5nZXQoZmlsZSlcblxuICAgICAgLy8gbmV3IG1vZHVsZSBoYXMgYmVlbiBjcmVhdGVkIGR1cmluZyBydW50aW1lXG4gICAgICAvLyBpbmNsdWRlIGl0IGluIGZ1cnRoZXIgcHJvY2Vzc2luZ1xuICAgICAgaWYgKHR5cGVvZiBleHBvcnRzID09PSAndW5kZWZpbmVkJykge1xuICAgICAgICBleHBvcnRzID0gbmV3IE1hcCgpXG4gICAgICB9XG5cbiAgICAgIGNvbnN0IG5ld0V4cG9ydHMgPSBuZXcgTWFwKClcbiAgICAgIGNvbnN0IG5ld0V4cG9ydElkZW50aWZpZXJzID0gbmV3IFNldCgpXG5cbiAgICAgIG5vZGUuYm9keS5mb3JFYWNoKCh7IHR5cGUsIGRlY2xhcmF0aW9uLCBzcGVjaWZpZXJzIH0pID0+IHtcbiAgICAgICAgaWYgKHR5cGUgPT09IEVYUE9SVF9ERUZBVUxUX0RFQ0xBUkFUSU9OKSB7XG4gICAgICAgICAgbmV3RXhwb3J0SWRlbnRpZmllcnMuYWRkKElNUE9SVF9ERUZBVUxUX1NQRUNJRklFUilcbiAgICAgICAgfVxuICAgICAgICBpZiAodHlwZSA9PT0gRVhQT1JUX05BTUVEX0RFQ0xBUkFUSU9OKSB7XG4gICAgICAgICAgaWYgKHNwZWNpZmllcnMubGVuZ3RoID4gMCkge1xuICAgICAgICAgICAgc3BlY2lmaWVycy5mb3JFYWNoKHNwZWNpZmllciA9PiB7XG4gICAgICAgICAgICAgIGlmIChzcGVjaWZpZXIuZXhwb3J0ZWQpIHtcbiAgICAgICAgICAgICAgICBuZXdFeHBvcnRJZGVudGlmaWVycy5hZGQoc3BlY2lmaWVyLmV4cG9ydGVkLm5hbWUpXG4gICAgICAgICAgICAgIH1cbiAgICAgICAgICAgIH0pXG4gICAgICAgICAgfVxuICAgICAgICAgIGZvckVhY2hEZWNsYXJhdGlvbklkZW50aWZpZXIoZGVjbGFyYXRpb24sIChuYW1lKSA9PiB7XG4gICAgICAgICAgICBuZXdFeHBvcnRJZGVudGlmaWVycy5hZGQobmFtZSlcbiAgICAgICAgICB9KVxuICAgICAgICB9XG4gICAgICB9KVxuXG4gICAgICAvLyBvbGQgZXhwb3J0cyBleGlzdCB3aXRoaW4gbGlzdCBvZiBuZXcgZXhwb3J0cyBpZGVudGlmaWVyczogYWRkIHRvIG1hcCBvZiBuZXcgZXhwb3J0c1xuICAgICAgZXhwb3J0cy5mb3JFYWNoKCh2YWx1ZSwga2V5KSA9PiB7XG4gICAgICAgIGlmIChuZXdFeHBvcnRJZGVudGlmaWVycy5oYXMoa2V5KSkge1xuICAgICAgICAgIG5ld0V4cG9ydHMuc2V0KGtleSwgdmFsdWUpXG4gICAgICAgIH1cbiAgICAgIH0pXG5cbiAgICAgIC8vIG5ldyBleHBvcnQgaWRlbnRpZmllcnMgYWRkZWQ6IGFkZCB0byBtYXAgb2YgbmV3IGV4cG9ydHNcbiAgICAgIG5ld0V4cG9ydElkZW50aWZpZXJzLmZvckVhY2goa2V5ID0+IHtcbiAgICAgICAgaWYgKCFleHBvcnRzLmhhcyhrZXkpKSB7XG4gICAgICAgICAgbmV3RXhwb3J0cy5zZXQoa2V5LCB7IHdoZXJlVXNlZDogbmV3IFNldCgpIH0pXG4gICAgICAgIH1cbiAgICAgIH0pXG5cbiAgICAgIC8vIHByZXNlcnZlIGluZm9ybWF0aW9uIGFib3V0IG5hbWVzcGFjZSBpbXBvcnRzXG4gICAgICBsZXQgZXhwb3J0QWxsID0gZXhwb3J0cy5nZXQoRVhQT1JUX0FMTF9ERUNMQVJBVElPTilcbiAgICAgIGxldCBuYW1lc3BhY2VJbXBvcnRzID0gZXhwb3J0cy5nZXQoSU1QT1JUX05BTUVTUEFDRV9TUEVDSUZJRVIpXG5cbiAgICAgIGlmICh0eXBlb2YgbmFtZXNwYWNlSW1wb3J0cyA9PT0gJ3VuZGVmaW5lZCcpIHtcbiAgICAgICAgbmFtZXNwYWNlSW1wb3J0cyA9IHsgd2hlcmVVc2VkOiBuZXcgU2V0KCkgfVxuICAgICAgfVxuXG4gICAgICBuZXdFeHBvcnRzLnNldChFWFBPUlRfQUxMX0RFQ0xBUkFUSU9OLCBleHBvcnRBbGwpXG4gICAgICBuZXdFeHBvcnRzLnNldChJTVBPUlRfTkFNRVNQQUNFX1NQRUNJRklFUiwgbmFtZXNwYWNlSW1wb3J0cylcbiAgICAgIGV4cG9ydExpc3Quc2V0KGZpbGUsIG5ld0V4cG9ydHMpXG4gICAgfVxuXG4gICAgLyoqXG4gICAgICogb25seSB1c2VmdWwgZm9yIHRvb2xzIGxpa2UgdnNjb2RlLWVzbGludFxuICAgICAqXG4gICAgICogdXBkYXRlIGxpc3RzIG9mIGV4aXN0aW5nIGltcG9ydHMgZHVyaW5nIHJ1bnRpbWVcbiAgICAgKi9cbiAgICBjb25zdCB1cGRhdGVJbXBvcnRVc2FnZSA9IG5vZGUgPT4ge1xuICAgICAgaWYgKCF1bnVzZWRFeHBvcnRzKSB7XG4gICAgICAgIHJldHVyblxuICAgICAgfVxuXG4gICAgICBsZXQgb2xkSW1wb3J0UGF0aHMgPSBpbXBvcnRMaXN0LmdldChmaWxlKVxuICAgICAgaWYgKHR5cGVvZiBvbGRJbXBvcnRQYXRocyA9PT0gJ3VuZGVmaW5lZCcpIHtcbiAgICAgICAgb2xkSW1wb3J0UGF0aHMgPSBuZXcgTWFwKClcbiAgICAgIH1cblxuICAgICAgY29uc3Qgb2xkTmFtZXNwYWNlSW1wb3J0cyA9IG5ldyBTZXQoKVxuICAgICAgY29uc3QgbmV3TmFtZXNwYWNlSW1wb3J0cyA9IG5ldyBTZXQoKVxuXG4gICAgICBjb25zdCBvbGRFeHBvcnRBbGwgPSBuZXcgU2V0KClcbiAgICAgIGNvbnN0IG5ld0V4cG9ydEFsbCA9IG5ldyBTZXQoKVxuXG4gICAgICBjb25zdCBvbGREZWZhdWx0SW1wb3J0cyA9IG5ldyBTZXQoKVxuICAgICAgY29uc3QgbmV3RGVmYXVsdEltcG9ydHMgPSBuZXcgU2V0KClcblxuICAgICAgY29uc3Qgb2xkSW1wb3J0cyA9IG5ldyBNYXAoKVxuICAgICAgY29uc3QgbmV3SW1wb3J0cyA9IG5ldyBNYXAoKVxuICAgICAgb2xkSW1wb3J0UGF0aHMuZm9yRWFjaCgodmFsdWUsIGtleSkgPT4ge1xuICAgICAgICBpZiAodmFsdWUuaGFzKEVYUE9SVF9BTExfREVDTEFSQVRJT04pKSB7XG4gICAgICAgICAgb2xkRXhwb3J0QWxsLmFkZChrZXkpXG4gICAgICAgIH1cbiAgICAgICAgaWYgKHZhbHVlLmhhcyhJTVBPUlRfTkFNRVNQQUNFX1NQRUNJRklFUikpIHtcbiAgICAgICAgICBvbGROYW1lc3BhY2VJbXBvcnRzLmFkZChrZXkpXG4gICAgICAgIH1cbiAgICAgICAgaWYgKHZhbHVlLmhhcyhJTVBPUlRfREVGQVVMVF9TUEVDSUZJRVIpKSB7XG4gICAgICAgICAgb2xkRGVmYXVsdEltcG9ydHMuYWRkKGtleSlcbiAgICAgICAgfVxuICAgICAgICB2YWx1ZS5mb3JFYWNoKHZhbCA9PiB7XG4gICAgICAgICAgaWYgKHZhbCAhPT0gSU1QT1JUX05BTUVTUEFDRV9TUEVDSUZJRVIgJiZcbiAgICAgICAgICAgICAgdmFsICE9PSBJTVBPUlRfREVGQVVMVF9TUEVDSUZJRVIpIHtcbiAgICAgICAgICAgICAgIG9sZEltcG9ydHMuc2V0KHZhbCwga2V5KVxuICAgICAgICAgICAgIH1cbiAgICAgICAgfSlcbiAgICAgIH0pXG5cbiAgICAgIG5vZGUuYm9keS5mb3JFYWNoKGFzdE5vZGUgPT4ge1xuICAgICAgICBsZXQgcmVzb2x2ZWRQYXRoXG5cbiAgICAgICAgLy8gc3VwcG9ydCBmb3IgZXhwb3J0IHsgdmFsdWUgfSBmcm9tICdtb2R1bGUnXG4gICAgICAgIGlmIChhc3ROb2RlLnR5cGUgPT09IEVYUE9SVF9OQU1FRF9ERUNMQVJBVElPTikge1xuICAgICAgICAgIGlmIChhc3ROb2RlLnNvdXJjZSkge1xuICAgICAgICAgICAgcmVzb2x2ZWRQYXRoID0gcmVzb2x2ZShhc3ROb2RlLnNvdXJjZS5yYXcucmVwbGFjZSgvKCd8XCIpL2csICcnKSwgY29udGV4dClcbiAgICAgICAgICAgIGFzdE5vZGUuc3BlY2lmaWVycy5mb3JFYWNoKHNwZWNpZmllciA9PiB7XG4gICAgICAgICAgICAgIGNvbnN0IG5hbWUgPSBzcGVjaWZpZXIubG9jYWwubmFtZVxuICAgICAgICAgICAgICBpZiAoc3BlY2lmaWVyLmxvY2FsLm5hbWUgPT09IERFRkFVTFQpIHtcbiAgICAgICAgICAgICAgICBuZXdEZWZhdWx0SW1wb3J0cy5hZGQocmVzb2x2ZWRQYXRoKVxuICAgICAgICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgICAgICAgIG5ld0ltcG9ydHMuc2V0KG5hbWUsIHJlc29sdmVkUGF0aClcbiAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgfSlcbiAgICAgICAgICB9XG4gICAgICAgIH1cblxuICAgICAgICBpZiAoYXN0Tm9kZS50eXBlID09PSBFWFBPUlRfQUxMX0RFQ0xBUkFUSU9OKSB7XG4gICAgICAgICAgcmVzb2x2ZWRQYXRoID0gcmVzb2x2ZShhc3ROb2RlLnNvdXJjZS5yYXcucmVwbGFjZSgvKCd8XCIpL2csICcnKSwgY29udGV4dClcbiAgICAgICAgICBuZXdFeHBvcnRBbGwuYWRkKHJlc29sdmVkUGF0aClcbiAgICAgICAgfVxuXG4gICAgICAgIGlmIChhc3ROb2RlLnR5cGUgPT09IElNUE9SVF9ERUNMQVJBVElPTikge1xuICAgICAgICAgIHJlc29sdmVkUGF0aCA9IHJlc29sdmUoYXN0Tm9kZS5zb3VyY2UucmF3LnJlcGxhY2UoLygnfFwiKS9nLCAnJyksIGNvbnRleHQpXG4gICAgICAgICAgaWYgKCFyZXNvbHZlZFBhdGgpIHtcbiAgICAgICAgICAgIHJldHVyblxuICAgICAgICAgIH1cblxuICAgICAgICAgIGlmIChpc05vZGVNb2R1bGUocmVzb2x2ZWRQYXRoKSkge1xuICAgICAgICAgICAgcmV0dXJuXG4gICAgICAgICAgfVxuXG4gICAgICAgICAgaWYgKG5ld05hbWVzcGFjZUltcG9ydEV4aXN0cyhhc3ROb2RlLnNwZWNpZmllcnMpKSB7XG4gICAgICAgICAgICBuZXdOYW1lc3BhY2VJbXBvcnRzLmFkZChyZXNvbHZlZFBhdGgpXG4gICAgICAgICAgfVxuXG4gICAgICAgICAgaWYgKG5ld0RlZmF1bHRJbXBvcnRFeGlzdHMoYXN0Tm9kZS5zcGVjaWZpZXJzKSkge1xuICAgICAgICAgICAgbmV3RGVmYXVsdEltcG9ydHMuYWRkKHJlc29sdmVkUGF0aClcbiAgICAgICAgICB9XG5cbiAgICAgICAgICBhc3ROb2RlLnNwZWNpZmllcnMuZm9yRWFjaChzcGVjaWZpZXIgPT4ge1xuICAgICAgICAgICAgaWYgKHNwZWNpZmllci50eXBlID09PSBJTVBPUlRfREVGQVVMVF9TUEVDSUZJRVIgfHxcbiAgICAgICAgICAgICAgICBzcGVjaWZpZXIudHlwZSA9PT0gSU1QT1JUX05BTUVTUEFDRV9TUEVDSUZJRVIpIHtcbiAgICAgICAgICAgICAgcmV0dXJuXG4gICAgICAgICAgICB9XG4gICAgICAgICAgICBuZXdJbXBvcnRzLnNldChzcGVjaWZpZXIuaW1wb3J0ZWQubmFtZSwgcmVzb2x2ZWRQYXRoKVxuICAgICAgICAgIH0pXG4gICAgICAgIH1cbiAgICAgIH0pXG5cbiAgICAgIG5ld0V4cG9ydEFsbC5mb3JFYWNoKHZhbHVlID0+IHtcbiAgICAgICAgaWYgKCFvbGRFeHBvcnRBbGwuaGFzKHZhbHVlKSkge1xuICAgICAgICAgIGxldCBpbXBvcnRzID0gb2xkSW1wb3J0UGF0aHMuZ2V0KHZhbHVlKVxuICAgICAgICAgIGlmICh0eXBlb2YgaW1wb3J0cyA9PT0gJ3VuZGVmaW5lZCcpIHtcbiAgICAgICAgICAgIGltcG9ydHMgPSBuZXcgU2V0KClcbiAgICAgICAgICB9XG4gICAgICAgICAgaW1wb3J0cy5hZGQoRVhQT1JUX0FMTF9ERUNMQVJBVElPTilcbiAgICAgICAgICBvbGRJbXBvcnRQYXRocy5zZXQodmFsdWUsIGltcG9ydHMpXG5cbiAgICAgICAgICBsZXQgZXhwb3J0cyA9IGV4cG9ydExpc3QuZ2V0KHZhbHVlKVxuICAgICAgICAgIGxldCBjdXJyZW50RXhwb3J0XG4gICAgICAgICAgaWYgKHR5cGVvZiBleHBvcnRzICE9PSAndW5kZWZpbmVkJykge1xuICAgICAgICAgICAgY3VycmVudEV4cG9ydCA9IGV4cG9ydHMuZ2V0KEVYUE9SVF9BTExfREVDTEFSQVRJT04pXG4gICAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICAgIGV4cG9ydHMgPSBuZXcgTWFwKClcbiAgICAgICAgICAgIGV4cG9ydExpc3Quc2V0KHZhbHVlLCBleHBvcnRzKVxuICAgICAgICAgIH1cblxuICAgICAgICAgIGlmICh0eXBlb2YgY3VycmVudEV4cG9ydCAhPT0gJ3VuZGVmaW5lZCcpIHtcbiAgICAgICAgICAgIGN1cnJlbnRFeHBvcnQud2hlcmVVc2VkLmFkZChmaWxlKVxuICAgICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgICBjb25zdCB3aGVyZVVzZWQgPSBuZXcgU2V0KClcbiAgICAgICAgICAgIHdoZXJlVXNlZC5hZGQoZmlsZSlcbiAgICAgICAgICAgIGV4cG9ydHMuc2V0KEVYUE9SVF9BTExfREVDTEFSQVRJT04sIHsgd2hlcmVVc2VkIH0pXG4gICAgICAgICAgfVxuICAgICAgICB9XG4gICAgICB9KVxuXG4gICAgICBvbGRFeHBvcnRBbGwuZm9yRWFjaCh2YWx1ZSA9PiB7XG4gICAgICAgIGlmICghbmV3RXhwb3J0QWxsLmhhcyh2YWx1ZSkpIHtcbiAgICAgICAgICBjb25zdCBpbXBvcnRzID0gb2xkSW1wb3J0UGF0aHMuZ2V0KHZhbHVlKVxuICAgICAgICAgIGltcG9ydHMuZGVsZXRlKEVYUE9SVF9BTExfREVDTEFSQVRJT04pXG5cbiAgICAgICAgICBjb25zdCBleHBvcnRzID0gZXhwb3J0TGlzdC5nZXQodmFsdWUpXG4gICAgICAgICAgaWYgKHR5cGVvZiBleHBvcnRzICE9PSAndW5kZWZpbmVkJykge1xuICAgICAgICAgICAgY29uc3QgY3VycmVudEV4cG9ydCA9IGV4cG9ydHMuZ2V0KEVYUE9SVF9BTExfREVDTEFSQVRJT04pXG4gICAgICAgICAgICBpZiAodHlwZW9mIGN1cnJlbnRFeHBvcnQgIT09ICd1bmRlZmluZWQnKSB7XG4gICAgICAgICAgICAgIGN1cnJlbnRFeHBvcnQud2hlcmVVc2VkLmRlbGV0ZShmaWxlKVxuICAgICAgICAgICAgfVxuICAgICAgICAgIH1cbiAgICAgICAgfVxuICAgICAgfSlcblxuICAgICAgbmV3RGVmYXVsdEltcG9ydHMuZm9yRWFjaCh2YWx1ZSA9PiB7XG4gICAgICAgIGlmICghb2xkRGVmYXVsdEltcG9ydHMuaGFzKHZhbHVlKSkge1xuICAgICAgICAgIGxldCBpbXBvcnRzID0gb2xkSW1wb3J0UGF0aHMuZ2V0KHZhbHVlKVxuICAgICAgICAgIGlmICh0eXBlb2YgaW1wb3J0cyA9PT0gJ3VuZGVmaW5lZCcpIHtcbiAgICAgICAgICAgIGltcG9ydHMgPSBuZXcgU2V0KClcbiAgICAgICAgICB9XG4gICAgICAgICAgaW1wb3J0cy5hZGQoSU1QT1JUX0RFRkFVTFRfU1BFQ0lGSUVSKVxuICAgICAgICAgIG9sZEltcG9ydFBhdGhzLnNldCh2YWx1ZSwgaW1wb3J0cylcblxuICAgICAgICAgIGxldCBleHBvcnRzID0gZXhwb3J0TGlzdC5nZXQodmFsdWUpXG4gICAgICAgICAgbGV0IGN1cnJlbnRFeHBvcnRcbiAgICAgICAgICBpZiAodHlwZW9mIGV4cG9ydHMgIT09ICd1bmRlZmluZWQnKSB7XG4gICAgICAgICAgICBjdXJyZW50RXhwb3J0ID0gZXhwb3J0cy5nZXQoSU1QT1JUX0RFRkFVTFRfU1BFQ0lGSUVSKVxuICAgICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgICBleHBvcnRzID0gbmV3IE1hcCgpXG4gICAgICAgICAgICBleHBvcnRMaXN0LnNldCh2YWx1ZSwgZXhwb3J0cylcbiAgICAgICAgICB9XG5cbiAgICAgICAgICBpZiAodHlwZW9mIGN1cnJlbnRFeHBvcnQgIT09ICd1bmRlZmluZWQnKSB7XG4gICAgICAgICAgICBjdXJyZW50RXhwb3J0LndoZXJlVXNlZC5hZGQoZmlsZSlcbiAgICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgICAgY29uc3Qgd2hlcmVVc2VkID0gbmV3IFNldCgpXG4gICAgICAgICAgICB3aGVyZVVzZWQuYWRkKGZpbGUpXG4gICAgICAgICAgICBleHBvcnRzLnNldChJTVBPUlRfREVGQVVMVF9TUEVDSUZJRVIsIHsgd2hlcmVVc2VkIH0pXG4gICAgICAgICAgfVxuICAgICAgICB9XG4gICAgICB9KVxuXG4gICAgICBvbGREZWZhdWx0SW1wb3J0cy5mb3JFYWNoKHZhbHVlID0+IHtcbiAgICAgICAgaWYgKCFuZXdEZWZhdWx0SW1wb3J0cy5oYXModmFsdWUpKSB7XG4gICAgICAgICAgY29uc3QgaW1wb3J0cyA9IG9sZEltcG9ydFBhdGhzLmdldCh2YWx1ZSlcbiAgICAgICAgICBpbXBvcnRzLmRlbGV0ZShJTVBPUlRfREVGQVVMVF9TUEVDSUZJRVIpXG5cbiAgICAgICAgICBjb25zdCBleHBvcnRzID0gZXhwb3J0TGlzdC5nZXQodmFsdWUpXG4gICAgICAgICAgaWYgKHR5cGVvZiBleHBvcnRzICE9PSAndW5kZWZpbmVkJykge1xuICAgICAgICAgICAgY29uc3QgY3VycmVudEV4cG9ydCA9IGV4cG9ydHMuZ2V0KElNUE9SVF9ERUZBVUxUX1NQRUNJRklFUilcbiAgICAgICAgICAgIGlmICh0eXBlb2YgY3VycmVudEV4cG9ydCAhPT0gJ3VuZGVmaW5lZCcpIHtcbiAgICAgICAgICAgICAgY3VycmVudEV4cG9ydC53aGVyZVVzZWQuZGVsZXRlKGZpbGUpXG4gICAgICAgICAgICB9XG4gICAgICAgICAgfVxuICAgICAgICB9XG4gICAgICB9KVxuXG4gICAgICBuZXdOYW1lc3BhY2VJbXBvcnRzLmZvckVhY2godmFsdWUgPT4ge1xuICAgICAgICBpZiAoIW9sZE5hbWVzcGFjZUltcG9ydHMuaGFzKHZhbHVlKSkge1xuICAgICAgICAgIGxldCBpbXBvcnRzID0gb2xkSW1wb3J0UGF0aHMuZ2V0KHZhbHVlKVxuICAgICAgICAgIGlmICh0eXBlb2YgaW1wb3J0cyA9PT0gJ3VuZGVmaW5lZCcpIHtcbiAgICAgICAgICAgIGltcG9ydHMgPSBuZXcgU2V0KClcbiAgICAgICAgICB9XG4gICAgICAgICAgaW1wb3J0cy5hZGQoSU1QT1JUX05BTUVTUEFDRV9TUEVDSUZJRVIpXG4gICAgICAgICAgb2xkSW1wb3J0UGF0aHMuc2V0KHZhbHVlLCBpbXBvcnRzKVxuXG4gICAgICAgICAgbGV0IGV4cG9ydHMgPSBleHBvcnRMaXN0LmdldCh2YWx1ZSlcbiAgICAgICAgICBsZXQgY3VycmVudEV4cG9ydFxuICAgICAgICAgIGlmICh0eXBlb2YgZXhwb3J0cyAhPT0gJ3VuZGVmaW5lZCcpIHtcbiAgICAgICAgICAgIGN1cnJlbnRFeHBvcnQgPSBleHBvcnRzLmdldChJTVBPUlRfTkFNRVNQQUNFX1NQRUNJRklFUilcbiAgICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgICAgZXhwb3J0cyA9IG5ldyBNYXAoKVxuICAgICAgICAgICAgZXhwb3J0TGlzdC5zZXQodmFsdWUsIGV4cG9ydHMpXG4gICAgICAgICAgfVxuXG4gICAgICAgICAgaWYgKHR5cGVvZiBjdXJyZW50RXhwb3J0ICE9PSAndW5kZWZpbmVkJykge1xuICAgICAgICAgICAgY3VycmVudEV4cG9ydC53aGVyZVVzZWQuYWRkKGZpbGUpXG4gICAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICAgIGNvbnN0IHdoZXJlVXNlZCA9IG5ldyBTZXQoKVxuICAgICAgICAgICAgd2hlcmVVc2VkLmFkZChmaWxlKVxuICAgICAgICAgICAgZXhwb3J0cy5zZXQoSU1QT1JUX05BTUVTUEFDRV9TUEVDSUZJRVIsIHsgd2hlcmVVc2VkIH0pXG4gICAgICAgICAgfVxuICAgICAgICB9XG4gICAgICB9KVxuXG4gICAgICBvbGROYW1lc3BhY2VJbXBvcnRzLmZvckVhY2godmFsdWUgPT4ge1xuICAgICAgICBpZiAoIW5ld05hbWVzcGFjZUltcG9ydHMuaGFzKHZhbHVlKSkge1xuICAgICAgICAgIGNvbnN0IGltcG9ydHMgPSBvbGRJbXBvcnRQYXRocy5nZXQodmFsdWUpXG4gICAgICAgICAgaW1wb3J0cy5kZWxldGUoSU1QT1JUX05BTUVTUEFDRV9TUEVDSUZJRVIpXG5cbiAgICAgICAgICBjb25zdCBleHBvcnRzID0gZXhwb3J0TGlzdC5nZXQodmFsdWUpXG4gICAgICAgICAgaWYgKHR5cGVvZiBleHBvcnRzICE9PSAndW5kZWZpbmVkJykge1xuICAgICAgICAgICAgY29uc3QgY3VycmVudEV4cG9ydCA9IGV4cG9ydHMuZ2V0KElNUE9SVF9OQU1FU1BBQ0VfU1BFQ0lGSUVSKVxuICAgICAgICAgICAgaWYgKHR5cGVvZiBjdXJyZW50RXhwb3J0ICE9PSAndW5kZWZpbmVkJykge1xuICAgICAgICAgICAgICBjdXJyZW50RXhwb3J0LndoZXJlVXNlZC5kZWxldGUoZmlsZSlcbiAgICAgICAgICAgIH1cbiAgICAgICAgICB9XG4gICAgICAgIH1cbiAgICAgIH0pXG5cbiAgICAgIG5ld0ltcG9ydHMuZm9yRWFjaCgodmFsdWUsIGtleSkgPT4ge1xuICAgICAgICBpZiAoIW9sZEltcG9ydHMuaGFzKGtleSkpIHtcbiAgICAgICAgICBsZXQgaW1wb3J0cyA9IG9sZEltcG9ydFBhdGhzLmdldCh2YWx1ZSlcbiAgICAgICAgICBpZiAodHlwZW9mIGltcG9ydHMgPT09ICd1bmRlZmluZWQnKSB7XG4gICAgICAgICAgICBpbXBvcnRzID0gbmV3IFNldCgpXG4gICAgICAgICAgfVxuICAgICAgICAgIGltcG9ydHMuYWRkKGtleSlcbiAgICAgICAgICBvbGRJbXBvcnRQYXRocy5zZXQodmFsdWUsIGltcG9ydHMpXG5cbiAgICAgICAgICBsZXQgZXhwb3J0cyA9IGV4cG9ydExpc3QuZ2V0KHZhbHVlKVxuICAgICAgICAgIGxldCBjdXJyZW50RXhwb3J0XG4gICAgICAgICAgaWYgKHR5cGVvZiBleHBvcnRzICE9PSAndW5kZWZpbmVkJykge1xuICAgICAgICAgICAgY3VycmVudEV4cG9ydCA9IGV4cG9ydHMuZ2V0KGtleSlcbiAgICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgICAgZXhwb3J0cyA9IG5ldyBNYXAoKVxuICAgICAgICAgICAgZXhwb3J0TGlzdC5zZXQodmFsdWUsIGV4cG9ydHMpXG4gICAgICAgICAgfVxuXG4gICAgICAgICAgaWYgKHR5cGVvZiBjdXJyZW50RXhwb3J0ICE9PSAndW5kZWZpbmVkJykge1xuICAgICAgICAgICAgY3VycmVudEV4cG9ydC53aGVyZVVzZWQuYWRkKGZpbGUpXG4gICAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICAgIGNvbnN0IHdoZXJlVXNlZCA9IG5ldyBTZXQoKVxuICAgICAgICAgICAgd2hlcmVVc2VkLmFkZChmaWxlKVxuICAgICAgICAgICAgZXhwb3J0cy5zZXQoa2V5LCB7IHdoZXJlVXNlZCB9KVxuICAgICAgICAgIH1cbiAgICAgICAgfVxuICAgICAgfSlcblxuICAgICAgb2xkSW1wb3J0cy5mb3JFYWNoKCh2YWx1ZSwga2V5KSA9PiB7XG4gICAgICAgIGlmICghbmV3SW1wb3J0cy5oYXMoa2V5KSkge1xuICAgICAgICAgIGNvbnN0IGltcG9ydHMgPSBvbGRJbXBvcnRQYXRocy5nZXQodmFsdWUpXG4gICAgICAgICAgaW1wb3J0cy5kZWxldGUoa2V5KVxuXG4gICAgICAgICAgY29uc3QgZXhwb3J0cyA9IGV4cG9ydExpc3QuZ2V0KHZhbHVlKVxuICAgICAgICAgIGlmICh0eXBlb2YgZXhwb3J0cyAhPT0gJ3VuZGVmaW5lZCcpIHtcbiAgICAgICAgICAgIGNvbnN0IGN1cnJlbnRFeHBvcnQgPSBleHBvcnRzLmdldChrZXkpXG4gICAgICAgICAgICBpZiAodHlwZW9mIGN1cnJlbnRFeHBvcnQgIT09ICd1bmRlZmluZWQnKSB7XG4gICAgICAgICAgICAgIGN1cnJlbnRFeHBvcnQud2hlcmVVc2VkLmRlbGV0ZShmaWxlKVxuICAgICAgICAgICAgfVxuICAgICAgICAgIH1cbiAgICAgICAgfVxuICAgICAgfSlcbiAgICB9XG5cbiAgICByZXR1cm4ge1xuICAgICAgJ1Byb2dyYW06ZXhpdCc6IG5vZGUgPT4ge1xuICAgICAgICB1cGRhdGVFeHBvcnRVc2FnZShub2RlKVxuICAgICAgICB1cGRhdGVJbXBvcnRVc2FnZShub2RlKVxuICAgICAgICBjaGVja0V4cG9ydFByZXNlbmNlKG5vZGUpXG4gICAgICB9LFxuICAgICAgJ0V4cG9ydERlZmF1bHREZWNsYXJhdGlvbic6IG5vZGUgPT4ge1xuICAgICAgICBjaGVja1VzYWdlKG5vZGUsIElNUE9SVF9ERUZBVUxUX1NQRUNJRklFUilcbiAgICAgIH0sXG4gICAgICAnRXhwb3J0TmFtZWREZWNsYXJhdGlvbic6IG5vZGUgPT4ge1xuICAgICAgICBub2RlLnNwZWNpZmllcnMuZm9yRWFjaChzcGVjaWZpZXIgPT4ge1xuICAgICAgICAgICAgY2hlY2tVc2FnZShub2RlLCBzcGVjaWZpZXIuZXhwb3J0ZWQubmFtZSlcbiAgICAgICAgfSlcbiAgICAgICAgZm9yRWFjaERlY2xhcmF0aW9uSWRlbnRpZmllcihub2RlLmRlY2xhcmF0aW9uLCAobmFtZSkgPT4ge1xuICAgICAgICAgIGNoZWNrVXNhZ2Uobm9kZSwgbmFtZSlcbiAgICAgICAgfSlcbiAgICAgIH0sXG4gICAgfVxuICB9LFxufVxuIl19