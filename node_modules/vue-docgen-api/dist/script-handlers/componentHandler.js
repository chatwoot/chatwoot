"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    Object.defineProperty(o, k2, { enumerable: true, get: function() { return m[k]; } });
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
var bt = __importStar(require("@babel/types"));
var getDocblock_1 = __importDefault(require("../utils/getDocblock"));
var getDoclets_1 = __importDefault(require("../utils/getDoclets"));
var transformTagsIntoObject_1 = __importDefault(require("../utils/transformTagsIntoObject"));
var getProperties_1 = __importDefault(require("./utils/getProperties"));
/**
 * Extracts prop information from an object-style VueJs component
 * @param documentation
 * @param path
 */
function componentHandler(documentation, path) {
    // deal with functional flag
    if (bt.isObjectExpression(path.node)) {
        var functionalPath = (0, getProperties_1.default)(path, 'functional');
        if (functionalPath.length) {
            var functionalValue = functionalPath[0].get('value').node;
            if (bt.isBooleanLiteral(functionalValue)) {
                documentation.set('functional', functionalValue.value);
            }
        }
    }
    var componentCommentedPath = path.parentPath;
    // in case of Vue.extend() structure
    if (bt.isCallExpression(componentCommentedPath.node)) {
        // look for leading comments in the parent structures
        var i = 5;
        while (i-- &&
            !componentCommentedPath.get('leadingComments').value &&
            componentCommentedPath.parentPath.node.type !== 'Program') {
            componentCommentedPath = componentCommentedPath.parentPath;
        }
    }
    else if (bt.isVariableDeclarator(componentCommentedPath.node)) {
        componentCommentedPath = componentCommentedPath.parentPath.parentPath;
        if (componentCommentedPath.parentPath.node.type !== 'Program') {
            componentCommentedPath = componentCommentedPath.parentPath;
        }
    }
    else if (bt.isDeclaration(componentCommentedPath.node)) {
        var classDeclaration = componentCommentedPath.get('declaration');
        if (bt.isClassDeclaration(classDeclaration.node)) {
            componentCommentedPath = classDeclaration;
        }
    }
    var docBlock = (0, getDocblock_1.default)(componentCommentedPath);
    // if no prop return
    if (!docBlock || !docBlock.length) {
        return Promise.resolve();
    }
    var jsDoc = (0, getDoclets_1.default)(docBlock);
    documentation.set('description', jsDoc.description);
    if (jsDoc.tags) {
        var displayNamesTags = jsDoc.tags.filter(function (t) { return t.title === 'displayName'; });
        if (displayNamesTags.length) {
            var displayName = displayNamesTags[0];
            documentation.set('displayName', displayName.content);
        }
        var tagsAsObject = (0, transformTagsIntoObject_1.default)(jsDoc.tags.filter(function (t) { return t.title !== 'example' && t.title !== 'displayName'; }) || []);
        var examples = jsDoc.tags.filter(function (t) { return t.title === 'example'; });
        if (examples.length) {
            tagsAsObject.examples = examples;
        }
        documentation.set('tags', tagsAsObject);
    }
    else {
        documentation.set('tags', {});
    }
    return Promise.resolve();
}
exports.default = componentHandler;
