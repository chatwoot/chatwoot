"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.createClassFeaturePlugin = createClassFeaturePlugin;
Object.defineProperty(exports, "injectInitialization", {
  enumerable: true,
  get: function () {
    return _misc.injectInitialization;
  }
});
Object.defineProperty(exports, "FEATURES", {
  enumerable: true,
  get: function () {
    return _features.FEATURES;
  }
});

var _core = require("@babel/core");

var _helperFunctionName = _interopRequireDefault(require("@babel/helper-function-name"));

var _helperSplitExportDeclaration = _interopRequireDefault(require("@babel/helper-split-export-declaration"));

var _fields = require("./fields");

var _decorators = require("./decorators");

var _misc = require("./misc");

var _features = require("./features");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

const version = "7.13.11".split(".").reduce((v, x) => v * 1e5 + +x, 0);
const versionKey = "@babel/plugin-class-features/version";

function createClassFeaturePlugin({
  name,
  feature,
  loose,
  manipulateOptions,
  api = {
    assumption: () => {}
  }
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

    pre() {
      (0, _features.enableFeature)(this.file, feature, loose);

      if (!this.file.get(versionKey) || this.file.get(versionKey) < version) {
        this.file.set(versionKey, version);
      }
    },

    visitor: {
      Class(path, state) {
        if (this.file.get(versionKey) !== version) return;
        (0, _features.verifyUsedFeatures)(path, this.file);
        const loose = (0, _features.isLoose)(this.file, feature);
        let constructor;
        let isDecorated = (0, _decorators.hasOwnDecorators)(path.node);
        const props = [];
        const elements = [];
        const computedPaths = [];
        const privateNames = new Set();
        const body = path.get("body");

        for (const path of body.get("body")) {
          (0, _features.verifyUsedFeatures)(path, this.file);

          if (path.node.computed) {
            computedPaths.push(path);
          }

          if (path.isPrivate()) {
            const {
              name
            } = path.node.key.id;
            const getName = `get ${name}`;
            const setName = `set ${name}`;

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

            if (path.isProperty() || path.isPrivate()) {
              props.push(path);
            }
          }

          if (!isDecorated) isDecorated = (0, _decorators.hasOwnDecorators)(path.node);

          if (path.isStaticBlock != null && path.isStaticBlock()) {
            throw path.buildCodeFrameError(`Incorrect plugin order, \`@babel/plugin-proposal-class-static-block\` should be placed before class features plugins
{
  "plugins": [
    "@babel/plugin-proposal-class-static-block",
    "@babel/plugin-proposal-private-property-in-object",
    "@babel/plugin-proposal-private-methods",
    "@babel/plugin-proposal-class-properties",
  ]
}`);
          }
        }

        if (!props.length && !isDecorated) return;
        let ref;

        if (path.isClassExpression() || !path.node.id) {
          (0, _helperFunctionName.default)(path);
          ref = path.scope.generateUidIdentifier("class");
        } else {
          ref = _core.types.cloneNode(path.node.id);
        }

        const privateNamesMap = (0, _fields.buildPrivateNamesMap)(props);
        const privateNamesNodes = (0, _fields.buildPrivateNamesNodes)(privateNamesMap, privateFieldsAsProperties != null ? privateFieldsAsProperties : loose, state);
        (0, _fields.transformPrivateNamesUsage)(ref, path, privateNamesMap, {
          privateFieldsAsProperties: privateFieldsAsProperties != null ? privateFieldsAsProperties : loose,
          noDocumentAll
        }, state);
        let keysNodes, staticNodes, pureStaticNodes, instanceNodes, wrapClass;

        if (isDecorated) {
          staticNodes = pureStaticNodes = keysNodes = [];
          ({
            instanceNodes,
            wrapClass
          } = (0, _decorators.buildDecoratedClass)(ref, path, elements, this.file));
        } else {
          keysNodes = (0, _misc.extractComputedKeys)(ref, path, computedPaths, this.file);
          ({
            staticNodes,
            pureStaticNodes,
            instanceNodes,
            wrapClass
          } = (0, _fields.buildFieldsInitNodes)(ref, path.node.superClass, props, privateNamesMap, state, setPublicClassFields != null ? setPublicClassFields : loose, privateFieldsAsProperties != null ? privateFieldsAsProperties : loose, constantSuper != null ? constantSuper : loose));
        }

        if (instanceNodes.length > 0) {
          (0, _misc.injectInitialization)(path, constructor, instanceNodes, (referenceVisitor, state) => {
            if (isDecorated) return;

            for (const prop of props) {
              if (prop.node.static) continue;
              prop.traverse(referenceVisitor, state);
            }
          });
        }

        path = wrapClass(path);
        path.insertBefore([...privateNamesNodes, ...keysNodes]);

        if (staticNodes.length > 0) {
          path.insertAfter(staticNodes);
        }

        if (pureStaticNodes.length > 0) {
          path.find(parent => parent.isStatement() || parent.isDeclaration()).insertAfter(pureStaticNodes);
        }
      },

      PrivateName(path) {
        if (this.file.get(versionKey) !== version || path.parentPath.isPrivate({
          key: path.node
        })) {
          return;
        }

        throw path.buildCodeFrameError(`Unknown PrivateName "${path}"`);
      },

      ExportDefaultDeclaration(path) {
        if (this.file.get(versionKey) !== version) return;
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
  };
}