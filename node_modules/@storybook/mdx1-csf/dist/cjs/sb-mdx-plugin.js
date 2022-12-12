"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.createCompiler = createCompiler;
exports.wrapperJs = void 0;

var _mdxHastToJsx = require("@mdx-js/mdx/mdx-hast-to-jsx");

var _parser = require("@babel/parser");

var t = _interopRequireWildcard(require("@babel/types"));

var _generator = _interopRequireDefault(require("@babel/generator"));

var _camelCase = _interopRequireDefault(require("lodash/camelCase"));

var _jsStringEscape = _interopRequireDefault(require("js-string-escape"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _getRequireWildcardCache(nodeInterop) { if (typeof WeakMap !== "function") return null; var cacheBabelInterop = new WeakMap(); var cacheNodeInterop = new WeakMap(); return (_getRequireWildcardCache = function (nodeInterop) { return nodeInterop ? cacheNodeInterop : cacheBabelInterop; })(nodeInterop); }

function _interopRequireWildcard(obj, nodeInterop) { if (!nodeInterop && obj && obj.__esModule) { return obj; } if (obj === null || typeof obj !== "object" && typeof obj !== "function") { return { default: obj }; } var cache = _getRequireWildcardCache(nodeInterop); if (cache && cache.has(obj)) { return cache.get(obj); } var newObj = {}; var hasPropertyDescriptor = Object.defineProperty && Object.getOwnPropertyDescriptor; for (var key in obj) { if (key !== "default" && Object.prototype.hasOwnProperty.call(obj, key)) { var desc = hasPropertyDescriptor ? Object.getOwnPropertyDescriptor(obj, key) : null; if (desc && (desc.get || desc.set)) { Object.defineProperty(newObj, key, desc); } else { newObj[key] = obj[key]; } } } newObj.default = obj; if (cache) { cache.set(obj, newObj); } return newObj; }

const generate = (node, context) => (0, _generator.default)(node, context); // Defined in MDX2.0


// Generate the MDX as is, but append named exports for every
// story in the contents
const STORY_REGEX = /^<Story[\s>]/;
const CANVAS_REGEX = /^<(Preview|Canvas)[\s>]/;
const META_REGEX = /^<Meta[\s>]/;
const RESERVED = /^(?:do|if|in|for|let|new|try|var|case|else|enum|eval|false|null|this|true|void|with|await|break|catch|class|const|super|throw|while|yield|delete|export|import|public|return|static|switch|typeof|default|extends|finally|package|private|continue|debugger|function|arguments|interface|protected|implements|instanceof)$/;

function getAttr(elt, what) {
  const attr = elt.attributes.find(n => n.name.name === what);
  return attr === null || attr === void 0 ? void 0 : attr.value;
}

const isReserved = name => RESERVED.exec(name);

const startsWithNumber = name => /^\d/.exec(name);

const sanitizeName = name => {
  let key = (0, _camelCase.default)(name);

  if (startsWithNumber(key)) {
    key = `_${key}`;
  } else if (isReserved(key)) {
    key = `${key}Story`;
  }

  return key;
};

const getStoryKey = (name, counter) => name ? sanitizeName(name) : `story${counter}`;

function genAttribute(key, element) {
  const value = getAttr(element, key);

  if (t.isJSXExpressionContainer(value)) {
    const {
      code
    } = generate(value.expression, {});
    return code;
  }

  return undefined;
}

function genImportStory(ast, storyDef, storyName, context) {
  const {
    code: story
  } = generate(storyDef.expression, {});
  const storyKey = `_${story.split('.').pop()}_`;
  const statements = [`export const ${storyKey} = ${story};`];

  if (storyName) {
    context.storyNameToKey[storyName] = storyKey;
    statements.push(`${storyKey}.storyName = '${storyName}';`);
  } else {
    context.storyNameToKey[storyKey] = storyKey;
    ast.openingElement.attributes.push(t.jsxAttribute(t.jsxIdentifier('name'), t.stringLiteral(storyKey)));
  }

  return {
    [storyKey]: statements.join('\n')
  };
}

function getBodyPart(bodyNode, context) {
  const body = t.isJSXExpressionContainer(bodyNode) ? bodyNode.expression : bodyNode;
  let sourceBody = body;

  if (t.isCallExpression(body) && t.isMemberExpression(body.callee) && t.isIdentifier(body.callee.object) && t.isIdentifier(body.callee.property) && body.callee.property.name === 'bind' && (body.arguments.length === 0 || body.arguments.length === 1 && t.isObjectExpression(body.arguments[0]) && body.arguments[0].properties.length === 0)) {
    const bound = body.callee.object.name;
    const namedExport = context.namedExports[bound];

    if (namedExport) {
      sourceBody = namedExport;
    }
  }

  const {
    code: storyCode
  } = generate(body, {});
  const {
    code: sourceCode
  } = generate(sourceBody, {});
  return {
    storyCode,
    sourceCode,
    body
  };
}

const idOrNull = attr => t.isStringLiteral(attr) ? attr.value : null;

const expressionOrNull = attr => t.isJSXExpressionContainer(attr) ? attr.expression : null;

function genStoryExport(ast, context) {
  const storyName = idOrNull(getAttr(ast.openingElement, 'name'));
  const storyId = idOrNull(getAttr(ast.openingElement, 'id'));
  const storyRef = getAttr(ast.openingElement, 'story');

  if (!storyId && !storyName && !storyRef) {
    throw new Error('Expected a Story name, id, or story attribute');
  } // We don't generate exports for story references or the smart "current story"


  if (storyId) {
    return null;
  }

  if (storyRef) {
    return genImportStory(ast, storyRef, storyName, context);
  }

  const statements = [];
  const storyKey = getStoryKey(storyName, context.counter);
  const bodyNodes = ast.children.filter(n => !t.isJSXText(n));
  let storyCode = null;
  let sourceCode = null;
  let storyVal = null;

  if (!bodyNodes.length) {
    if (ast.children.length > 0) {
      // plain text node
      const {
        code
      } = generate(ast.children[0], {});
      storyCode = `'${code}'`;
      sourceCode = storyCode;
      storyVal = `() => (
        ${storyCode}
      )`;
    } else {
      sourceCode = '{}';
      storyVal = '{}';
    }
  } else {
    const bodyParts = bodyNodes.map(bodyNode => getBodyPart(bodyNode, context)); // if we have more than two children
    // 1. Add line breaks
    // 2. Enclose in <> ... </>

    storyCode = bodyParts.map(({
      storyCode: code
    }) => code).join('\n');
    sourceCode = bodyParts.map(({
      sourceCode: code
    }) => code).join('\n');
    const storyReactCode = bodyParts.length > 1 ? `<>\n${storyCode}\n</>` : storyCode; // keep track if an identifier or function call
    // avoid breaking change for 5.3

    const BIND_REGEX = /\.bind\(.*\)/;

    if (bodyParts.length === 1) {
      if (BIND_REGEX.test(bodyParts[0].storyCode)) {
        storyVal = bodyParts[0].storyCode;
      } else if (t.isIdentifier(bodyParts[0].body)) {
        storyVal = `assertIsFn(${storyCode})`;
      } else if (t.isArrowFunctionExpression(bodyParts[0].body)) {
        storyVal = `(${storyCode})`;
      } else {
        storyVal = `() => (
          ${storyReactCode}
        )`;
      }
    } else {
      storyVal = `() => (
        ${storyReactCode}
      )`;
    }
  }

  statements.push(`export const ${storyKey} = ${storyVal};`); // always preserve the name, since CSF exports can get modified by displayName

  statements.push(`${storyKey}.storyName = '${storyName}';`);
  const argTypes = genAttribute('argTypes', ast.openingElement);
  if (argTypes) statements.push(`${storyKey}.argTypes = ${argTypes};`);
  const args = genAttribute('args', ast.openingElement);
  if (args) statements.push(`${storyKey}.args = ${args};`);
  const parameters = expressionOrNull(getAttr(ast.openingElement, 'parameters'));
  const source = (0, _jsStringEscape.default)(sourceCode);
  const sourceParam = `storySource: { source: '${source}' }`;

  if (parameters) {
    const {
      code: params
    } = generate(parameters, {});
    statements.push(`${storyKey}.parameters = { ${sourceParam}, ...${params} };`);
  } else {
    statements.push(`${storyKey}.parameters = { ${sourceParam} };`);
  }

  const decorators = expressionOrNull(getAttr(ast.openingElement, 'decorators'));

  if (decorators) {
    const {
      code: decos
    } = generate(decorators, {});
    statements.push(`${storyKey}.decorators = ${decos};`);
  }

  const loaders = expressionOrNull(getAttr(ast.openingElement, 'loaders'));

  if (loaders) {
    const {
      code: loaderCode
    } = generate(loaders, {});
    statements.push(`${storyKey}.loaders = ${loaderCode};`);
  }

  const play = expressionOrNull(getAttr(ast.openingElement, 'play'));

  if (play) {
    const {
      code: playCode
    } = generate(play, {});
    statements.push(`${storyKey}.play = ${playCode};`);
  }

  const render = expressionOrNull(getAttr(ast.openingElement, 'render'));

  if (render) {
    const {
      code: renderCode
    } = generate(render, {});
    statements.push(`${storyKey}.render = ${renderCode};`);
  }

  context.storyNameToKey[storyName] = storyKey;
  return {
    [storyKey]: statements.join('\n')
  };
}

function genCanvasExports(ast, context) {
  const canvasExports = {};

  for (let i = 0; i < ast.children.length; i += 1) {
    const child = ast.children[i];

    if (t.isJSXElement(child) && t.isJSXIdentifier(child.openingElement.name) && child.openingElement.name.name === 'Story') {
      const storyExport = genStoryExport(child, context);
      const {
        code
      } = generate(child, {}); // @ts-ignore

      child.value = code;

      if (storyExport) {
        Object.assign(canvasExports, storyExport);
        context.counter += 1;
      }
    }
  }

  return canvasExports;
}

function genMeta(ast, options) {
  const titleAttr = getAttr(ast.openingElement, 'title');
  const idAttr = getAttr(ast.openingElement, 'id');
  let title = null;

  if (titleAttr) {
    if (t.isStringLiteral(titleAttr)) {
      title = "'".concat((0, _jsStringEscape.default)(titleAttr.value), "'");
    } else if (t.isJSXExpressionContainer(titleAttr)) {
      try {
        // generate code, so the expression is evaluated by the CSF compiler
        const {
          code
        } = generate(titleAttr.expression, {}); // remove the curly brackets at start and end of code

        title = code.replace(/^\{(.+)\}$/, '$1');
      } catch (e) {
        // eat exception if title parsing didn't go well
        // eslint-disable-next-line no-console
        console.warn('Invalid title:', options.filepath);
        title = undefined;
      }
    } else {
      console.warn(`Unknown title attr: ${titleAttr.type}`);
    }
  }

  const id = t.isStringLiteral(idAttr) ? `'${idAttr.value}'` : null;
  const parameters = genAttribute('parameters', ast.openingElement);
  const decorators = genAttribute('decorators', ast.openingElement);
  const loaders = genAttribute('loaders', ast.openingElement);
  const component = genAttribute('component', ast.openingElement);
  const subcomponents = genAttribute('subcomponents', ast.openingElement);
  const args = genAttribute('args', ast.openingElement);
  const argTypes = genAttribute('argTypes', ast.openingElement);
  const render = genAttribute('render', ast.openingElement);
  return {
    title,
    id,
    parameters,
    decorators,
    loaders,
    component,
    subcomponents,
    args,
    argTypes,
    render
  };
}

function getExports(node, context, options) {
  const {
    value,
    type
  } = node;

  if (type === 'jsx') {
    if (STORY_REGEX.exec(value)) {
      // Single story
      const ast = (0, _parser.parseExpression)(value, {
        plugins: ['jsx']
      });
      const storyExport = genStoryExport(ast, context);
      const {
        code
      } = generate(ast, {}); // eslint-disable-next-line no-param-reassign

      node.value = code;
      return storyExport && {
        stories: storyExport
      };
    }

    if (CANVAS_REGEX.exec(value)) {
      // Canvas/Preview, possibly containing multiple stories
      const ast = (0, _parser.parseExpression)(value, {
        plugins: ['jsx']
      });
      const canvasExports = genCanvasExports(ast, context); // We're overwriting the Canvas tag here with a version that
      // has the `name` attribute (e.g. `<Story name="..." story={...} />`)
      // even if the user didn't provide one. We need the name attribute when
      // we render the node at runtime.

      const {
        code
      } = generate(ast, {}); // eslint-disable-next-line no-param-reassign

      node.value = code;
      return {
        stories: canvasExports
      };
    }

    if (META_REGEX.exec(value)) {
      const ast = (0, _parser.parseExpression)(value, {
        plugins: ['jsx']
      });
      return {
        meta: genMeta(ast, options)
      };
    }
  }

  return null;
} // insert `mdxStoryNameToKey` and `mdxComponentMeta` into the context so that we
// can reconstruct the Story ID dynamically from the `name` at render time


const wrapperJs = `
componentMeta.parameters = componentMeta.parameters || {};
componentMeta.parameters.docs = {
  ...(componentMeta.parameters.docs || {}),
  page: () => <AddContext mdxStoryNameToKey={mdxStoryNameToKey} mdxComponentAnnotations={componentMeta}><MDXContent /></AddContext>,
};
`.trim(); // Use this rather than JSON.stringify because `Meta`'s attributes
// are already valid code strings, so we want to insert them raw
// rather than add an extra set of quotes

exports.wrapperJs = wrapperJs;

function stringifyMeta(meta) {
  let result = '{ ';
  Object.entries(meta).forEach(([key, val]) => {
    if (val) {
      result += `${key}: ${val}, `;
    }
  });
  result += ' }';
  return result;
}

const hasStoryChild = node => {
  if (node.openingElement && t.isJSXIdentifier(node.openingElement.name) && node.openingElement.name.name === 'Story') {
    return !!node;
  }

  if (node.children && node.children.length > 0) {
    return !!node.children.find(child => hasStoryChild(child));
  }

  return false;
};

const getMdxSource = children => encodeURI(children.map(el => generate(el, {}).code).join('\n')); // Parse out the named exports from a node, where the key
// is the variable name and the value is the AST of the
// variable declaration initializer


const getNamedExports = node => {
  const namedExports = {};
  const ast = (0, _parser.parse)(node.value, {
    sourceType: 'module',
    plugins: ['jsx'] // FIXME!!! presets: ['env]

  });

  if (t.isFile(ast) && t.isProgram(ast.program) && ast.program.body.length === 1) {
    const exported = ast.program.body[0];

    if (t.isExportNamedDeclaration(exported) && t.isVariableDeclaration(exported.declaration) && exported.declaration.declarations.length === 1) {
      const declaration = exported.declaration.declarations[0];

      if (t.isVariableDeclarator(declaration) && t.isIdentifier(declaration.id)) {
        const {
          name
        } = declaration.id;
        namedExports[name] = declaration.init;
      }
    }
  }

  return namedExports;
};

function extractExports(root, options) {
  const namedExports = {};
  root.children.forEach(child => {
    if (child.type === 'jsx') {
      try {
        const ast = (0, _parser.parseExpression)(child.value, {
          plugins: ['jsx']
        });

        if (t.isJSXOpeningElement(ast.openingElement) && ['Preview', 'Canvas'].includes(ast.openingElement.name.name) && !hasStoryChild(ast)) {
          const canvasAst = ast.openingElement;
          canvasAst.attributes.push(t.jsxAttribute(t.jsxIdentifier('mdxSource'), t.stringLiteral(getMdxSource(ast.children))));
        }

        const {
          code
        } = generate(ast, {}); // eslint-disable-next-line no-param-reassign

        child.value = code;
      } catch {
        /** catch erroneous child.value string where the babel parseExpression makes exception
         * https://github.com/mdx-js/mdx/issues/767
         * eg <button>
         *      <div>hello world</div>
         *
         *    </button>
         * generates error
         * 1. child.value =`<button>\n  <div>hello world</div`
         * 2. child.value =`\n`
         * 3. child.value =`</button>`
         *
         */
      }
    } else if (child.type === 'export') {
      Object.assign(namedExports, getNamedExports(child));
    }
  }); // we're overriding default export

  const storyExports = [];
  const includeStories = [];
  let metaExport = null;
  const context = {
    counter: 0,
    storyNameToKey: {},
    root,
    namedExports
  };
  root.children.forEach(n => {
    const exports = getExports(n, context, options);

    if (exports) {
      const {
        stories,
        meta
      } = exports;

      if (stories) {
        Object.entries(stories).forEach(([key, story]) => {
          includeStories.push(key);
          storyExports.push(story);
        });
      }

      if (meta) {
        if (metaExport) {
          throw new Error('Meta can only be declared once');
        }

        metaExport = meta;
      }
    }
  });

  if (metaExport) {
    if (!storyExports.length) {
      storyExports.push('export const __page = () => { throw new Error("Docs-only story"); };');
      storyExports.push('__page.parameters = { docsOnly: true };');
      includeStories.push('__page');
    }
  } else {
    metaExport = {};
  }

  metaExport.includeStories = JSON.stringify(includeStories);
  const defaultJsx = (0, _mdxHastToJsx.toJSX)(root, {}, { ...options,
    skipExport: true
  });
  const fullJsx = ['import { assertIsFn, AddContext } from "@storybook/addon-docs";', defaultJsx, ...storyExports, `const componentMeta = ${stringifyMeta(metaExport)};`, `const mdxStoryNameToKey = ${JSON.stringify(context.storyNameToKey)};`, wrapperJs, 'export default componentMeta;'].join('\n\n');
  return fullJsx;
}

function createCompiler(mdxOptions) {
  return function compiler(options = {}) {
    this.Compiler = root => extractExports(root, options);
  };
}