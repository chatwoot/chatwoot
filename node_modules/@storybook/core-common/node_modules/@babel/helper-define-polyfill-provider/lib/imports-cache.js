"use strict";

exports.__esModule = true;
exports.default = void 0;

var _core = require("@babel/core");

class ImportsCache {
  constructor(resolver) {
    this._imports = new WeakMap();
    this._anonymousImports = new WeakMap();
    this._lastImports = new WeakMap();
    this._resolver = resolver;
  }

  storeAnonymous(programPath, url, // eslint-disable-next-line no-undef
  getVal) {
    const key = this._normalizeKey(programPath, url);

    const imports = this._ensure(this._anonymousImports, programPath, Set);

    if (imports.has(key)) return;
    const node = getVal(programPath.node.sourceType === "script", _core.types.stringLiteral(this._resolver(url)));
    imports.add(key);

    this._injectImport(programPath, node);
  }

  storeNamed(programPath, url, name, getVal) {
    const key = this._normalizeKey(programPath, url, name);

    const imports = this._ensure(this._imports, programPath, Map);

    if (!imports.has(key)) {
      const {
        node,
        name: id
      } = getVal(programPath.node.sourceType === "script", _core.types.stringLiteral(this._resolver(url)), _core.types.identifier(name));
      imports.set(key, id);

      this._injectImport(programPath, node);
    }

    return _core.types.identifier(imports.get(key));
  }

  _injectImport(programPath, node) {
    let lastImport = this._lastImports.get(programPath);

    if (lastImport && lastImport.node && // Sometimes the AST is modified and the "last import"
    // we have has been replaced
    lastImport.parent === programPath.node && lastImport.container === programPath.node.body) {
      lastImport = lastImport.insertAfter(node);
    } else {
      lastImport = programPath.unshiftContainer("body", node);
    }

    lastImport = lastImport[lastImport.length - 1];

    this._lastImports.set(programPath, lastImport);
    /*
    let lastImport;
     programPath.get("body").forEach(path => {
      if (path.isImportDeclaration()) lastImport = path;
      if (
        path.isExpressionStatement() &&
        isRequireCall(path.get("expression"))
      ) {
        lastImport = path;
      }
      if (
        path.isVariableDeclaration() &&
        path.get("declarations").length === 1 &&
        (isRequireCall(path.get("declarations.0.init")) ||
          (path.get("declarations.0.init").isMemberExpression() &&
            isRequireCall(path.get("declarations.0.init.object"))))
      ) {
        lastImport = path;
      }
    });*/

  }

  _ensure(map, programPath, Collection) {
    let collection = map.get(programPath);

    if (!collection) {
      collection = new Collection();
      map.set(programPath, collection);
    }

    return collection;
  }

  _normalizeKey(programPath, url, name = "") {
    const {
      sourceType
    } = programPath.node; // If we rely on the imported binding (the "name" parameter), we also need to cache
    // based on the sourceType. This is because the module transforms change the names
    // of the import variables.

    return `${name && sourceType}::${url}::${name}`;
  }

}

exports.default = ImportsCache;