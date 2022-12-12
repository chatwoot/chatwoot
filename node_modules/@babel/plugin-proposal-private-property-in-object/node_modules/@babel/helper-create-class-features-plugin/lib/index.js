"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
Object.defineProperty(exports, "FEATURES", {
  enumerable: true,
  get: function () {
    return _features.FEATURES;
  }
});
exports.createClassFeaturePlugin = createClassFeaturePlugin;
Object.defineProperty(exports, "enableFeature", {
  enumerable: true,
  get: function () {
    return _features.enableFeature;
  }
});
Object.defineProperty(exports, "injectInitialization", {
  enumerable: true,
  get: function () {
    return _misc.injectInitialization;
  }
});

var _core = require("@babel/core");

var _helperFunctionName = require("@babel/helper-function-name");

var _helperSplitExportDeclaration = require("@babel/helper-split-export-declaration");

var _fields = require("./fields");

var _decorators = require("./decorators");

var _misc = require("./misc");

var _features = require("./features");

var _typescript = require("./typescript");

const version = "7.18.6".split(".").reduce((v, x) => v * 1e5 + +x, 0);
const versionKey = "@babel/plugin-class-features/version";

function createClassFeaturePlugin({
  name,
  feature,
  loose,
  manipulateOptions,
  api = {
    assumption: () => void 0
  },
  inherits
}) {
  const setPublicClassFields = api.assumption("setPublicClassFields");
  const privateFieldsAsProperties = api.assumption("privateFieldsAsProperties");
  const constantSuper = api.assumption("constantSuper");
  const noDocumentAll = api.assumption("noDocumentAll");

  if (loose === true) {
    const explicit = [];

    if (setPublicClassFields !== undefined) {
      explicit.push(`"setPublicClassFields"`);
    }

    if (privateFieldsAsProperties !== undefined) {
      explicit.push(`"privateFieldsAsProperties"`);
    }

    if (explicit.length !== 0) {
      console.warn(`[${name}]: You are using the "loose: true" option and you are` + ` explicitly setting a value for the ${explicit.join(" and ")}` + ` assumption${explicit.length > 1 ? "s" : ""}. The "loose" option` + ` can cause incompatibilities with the other class features` + ` plugins, so it's recommended that you replace it with the` + ` following top-level option:\n` + `\t"assumptions": {\n` + `\t\t"setPublicClassFields": true,\n` + `\t\t"privateFieldsAsProperties": true\n` + `\t}`);
    }
  }

  return {
    name,
    manipulateOptions,
    inherits,

    pre(file) {
      (0, _features.enableFeature)(file, feature, loose);

      if (!file.get(versionKey) || file.get(versionKey) < version) {
        file.set(versionKey, version);
      }
    },

    visitor: {
      Class(path, {
        file
      }) {
        if (file.get(versionKey) !== version) return;
        if (!(0, _features.shouldTransform)(path, file)) return;
        if (path.isClassDeclaration()) (0, _typescript.assertFieldTransformed)(path);
        const loose = (0, _features.isLoose)(file, feature);
        let constructor;
        const isDecorated = (0, _decorators.hasDecorators)(path.node);
        const props = [];
        const elements = [];
        const computedPaths = [];
        const privateNames = new Set();
        const body = path.get("body");

        for (const path of body.get("body")) {
          if ((path.isClassProperty() || path.isClassMethod()) && path.node.computed) {
            computedPaths.push(path);
          }

          if (path.isPrivate()) {
            const {
              name
            } = path.node.key.id;
            const getName = `get ${name}`;
            const setName = `set ${name}`;

            if (path.isClassPrivateMethod()) {
              if (path.node.kind === "get") {
                if (privateNames.has(getName) || privateNames.has(name) && !privateNames.has(setName)) {
                  throw path.buildCodeFrameError("Duplicate private field");
                }

                privateNames.add(getName).add(name);
              } else if (path.node.kind === "set") {
                if (privateNames.has(setName) || privateNames.has(name) && !privateNames.has(getName)) {
                  throw path.buildCodeFrameError("Duplicate private field");
                }

                privateNames.add(setName).add(name);
              }
            } else {
              if (privateNames.has(name) && !privateNames.has(getName) && !privateNames.has(setName) || privateNames.has(name) && (privateNames.has(getName) || privateNames.has(setName))) {
                throw path.buildCodeFrameError("Duplicate private field");
              }

              privateNames.add(name);
            }
          }

          if (path.isClassMethod({
            kind: "constructor"
          })) {
            constructor = path;
          } else {
            elements.push(path);

            if (path.isProperty() || path.isPrivate() || path.isStaticBlock != null && path.isStaticBlock()) {
              props.push(path);
            }
          }
        }

        {
          if (!props.length && !isDecorated) return;
        }
        const innerBinding = path.node.id;
        let ref;

        if (!innerBinding || path.isClassExpression()) {
          (0, _helperFunctionName.default)(path);
          ref = path.scope.generateUidIdentifier("class");
        } else {
          ref = _core.types.cloneNode(path.node.id);
        }

        const privateNamesMap = (0, _fields.buildPrivateNamesMap)(props);
        const privateNamesNodes = (0, _fields.buildPrivateNamesNodes)(privateNamesMap, privateFieldsAsProperties != null ? privateFieldsAsProperties : loose, file);
        (0, _fields.transformPrivateNamesUsage)(ref, path, privateNamesMap, {
          privateFieldsAsProperties: privateFieldsAsProperties != null ? privateFieldsAsProperties : loose,
          noDocumentAll,
          innerBinding
        }, file);
        let keysNodes, staticNodes, instanceNodes, pureStaticNodes, wrapClass;
        {
          if (isDecorated) {
            staticNodes = pureStaticNodes = keysNodes = [];
            ({
              instanceNodes,
              wrapClass
            } = (0, _decorators.buildDecoratedClass)(ref, path, elements, file));
          } else {
            keysNodes = (0, _misc.extractComputedKeys)(path, computedPaths, file);
            ({
              staticNodes,
              pureStaticNodes,
              instanceNodes,
              wrapClass
            } = (0, _fields.buildFieldsInitNodes)(ref, path.node.superClass, props, privateNamesMap, file, setPublicClassFields != null ? setPublicClassFields : loose, privateFieldsAsProperties != null ? privateFieldsAsProperties : loose, constantSuper != null ? constantSuper : loose, innerBinding));
          }
        }

        if (instanceNodes.length > 0) {
          (0, _misc.injectInitialization)(path, constructor, instanceNodes, (referenceVisitor, state) => {
            {
              if (isDecorated) return;
            }

            for (const prop of props) {
              if (_core.types.isStaticBlock != null && _core.types.isStaticBlock(prop.node) || prop.node.static) continue;
              prop.traverse(referenceVisitor, state);
            }
          });
        }

        const wrappedPath = wrapClass(path);
        wrappedPath.insertBefore([...privateNamesNodes, ...keysNodes]);

        if (staticNodes.length > 0) {
          wrappedPath.insertAfter(staticNodes);
        }

        if (pureStaticNodes.length > 0) {
          wrappedPath.find(parent => parent.isStatement() || parent.isDeclaration()).insertAfter(pureStaticNodes);
        }
      },

      ExportDefaultDeclaration(path, {
        file
      }) {
        {
          if (file.get(versionKey) !== version) return;
          const decl = path.get("declaration");

          if (decl.isClassDeclaration() && (0, _decorators.hasDecorators)(decl.node)) {
            if (decl.node.id) {
              (0, _helperSplitExportDeclaration.default)(path);
            } else {
              decl.node.type = "ClassExpression";
            }
          }
        }
      }

    }
  };
}