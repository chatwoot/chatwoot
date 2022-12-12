// @ts-check
/** @typedef {import("webpack/lib/Compilation.js")} WebpackCompilation */
/** @typedef {import("webpack/lib/Compiler.js")} WebpackCompiler */
/** @typedef {import("webpack/lib/Chunk.js")} WebpackChunk */
'use strict';
/**
 * @file
 * This file uses webpack to compile a template with a child compiler.
 *
 * [TEMPLATE] -> [JAVASCRIPT]
 *
 */
'use strict';
const NodeTemplatePlugin = require('webpack/lib/node/NodeTemplatePlugin');
const NodeTargetPlugin = require('webpack/lib/node/NodeTargetPlugin');
const LoaderTargetPlugin = require('webpack/lib/LoaderTargetPlugin');
const LibraryTemplatePlugin = require('webpack/lib/LibraryTemplatePlugin');
const SingleEntryPlugin = require('webpack/lib/SingleEntryPlugin');

/**
 * The HtmlWebpackChildCompiler is a helper to allow reusing one childCompiler
 * for multiple HtmlWebpackPlugin instances to improve the compilation performance.
 */
class HtmlWebpackChildCompiler {
  /**
   *
   * @param {string[]} templates
   */
  constructor (templates) {
    /**
     * @type {string[]} templateIds
     * The template array will allow us to keep track which input generated which output
     */
    this.templates = templates;
    /**
     * @type {Promise<{[templatePath: string]: { content: string, hash: string, entry: WebpackChunk }}>}
     */
    this.compilationPromise; // eslint-disable-line
    /**
     * @type {number}
     */
    this.compilationStartedTimestamp; // eslint-disable-line
    /**
     * @type {number}
     */
    this.compilationEndedTimestamp; // eslint-disable-line
    /**
     * All file dependencies of the child compiler
     * @type {{fileDependencies: string[], contextDependencies: string[], missingDependencies: string[]}}
     */
    this.fileDependencies = { fileDependencies: [], contextDependencies: [], missingDependencies: [] };
  }

  /**
   * Returns true if the childCompiler is currently compiling
   * @returns {boolean}
   */
  isCompiling () {
    return !this.didCompile() && this.compilationStartedTimestamp !== undefined;
  }

  /**
   * Returns true if the childCompiler is done compiling
   */
  didCompile () {
    return this.compilationEndedTimestamp !== undefined;
  }

  /**
   * This function will start the template compilation
   * once it is started no more templates can be added
   *
   * @param {WebpackCompilation} mainCompilation
   * @returns {Promise<{[templatePath: string]: { content: string, hash: string, entry: WebpackChunk }}>}
   */
  compileTemplates (mainCompilation) {
    // To prevent multiple compilations for the same template
    // the compilation is cached in a promise.
    // If it already exists return
    if (this.compilationPromise) {
      return this.compilationPromise;
    }

    // The entry file is just an empty helper as the dynamic template
    // require is added in "loader.js"
    const outputOptions = {
      filename: '__child-[name]',
      publicPath: mainCompilation.outputOptions.publicPath
    };
    const compilerName = 'HtmlWebpackCompiler';
    // Create an additional child compiler which takes the template
    // and turns it into an Node.JS html factory.
    // This allows us to use loaders during the compilation
    const childCompiler = mainCompilation.createChildCompiler(compilerName, outputOptions);
    // The file path context which webpack uses to resolve all relative files to
    childCompiler.context = mainCompilation.compiler.context;
    // Compile the template to nodejs javascript
    new NodeTemplatePlugin(outputOptions).apply(childCompiler);
    new NodeTargetPlugin().apply(childCompiler);
    new LibraryTemplatePlugin('HTML_WEBPACK_PLUGIN_RESULT', 'var').apply(childCompiler);
    new LoaderTargetPlugin('node').apply(childCompiler);

    // Add all templates
    this.templates.forEach((template, index) => {
      new SingleEntryPlugin(childCompiler.context, template, `HtmlWebpackPlugin_${index}`).apply(childCompiler);
    });

    this.compilationStartedTimestamp = new Date().getTime();
    this.compilationPromise = new Promise((resolve, reject) => {
      childCompiler.runAsChild((err, entries, childCompilation) => {
        // Extract templates
        const compiledTemplates = entries
          ? extractHelperFilesFromCompilation(mainCompilation, childCompilation, outputOptions.filename, entries)
          : [];
        // Extract file dependencies
        if (entries) {
          this.fileDependencies = { fileDependencies: Array.from(childCompilation.fileDependencies), contextDependencies: Array.from(childCompilation.contextDependencies), missingDependencies: Array.from(childCompilation.missingDependencies) };
        }
        // Reject the promise if the childCompilation contains error
        if (childCompilation && childCompilation.errors && childCompilation.errors.length) {
          const errorDetails = childCompilation.errors.map(error => {
            let message = error.message;
            if (error.error) {
              message += ':\n' + error.error;
            }
            if (error.stack) {
              message += '\n' + error.stack;
            }
            return message;
          }).join('\n');
          reject(new Error('Child compilation failed:\n' + errorDetails));
          return;
        }
        // Reject if the error object contains errors
        if (err) {
          reject(err);
          return;
        }
        /**
         * @type {{[templatePath: string]: { content: string, hash: string, entry: WebpackChunk }}}
         */
        const result = {};
        compiledTemplates.forEach((templateSource, entryIndex) => {
          // The compiledTemplates are generated from the entries added in
          // the addTemplate function.
          // Therefore the array index of this.templates should be the as entryIndex.
          result[this.templates[entryIndex]] = {
            content: templateSource,
            hash: childCompilation.hash,
            entry: entries[entryIndex]
          };
        });
        this.compilationEndedTimestamp = new Date().getTime();
        resolve(result);
      });
    });

    return this.compilationPromise;
  }
}

/**
 * The webpack child compilation will create files as a side effect.
 * This function will extract them and clean them up so they won't be written to disk.
 *
 * Returns the source code of the compiled templates as string
 *
 * @returns Array<string>
 */
function extractHelperFilesFromCompilation (mainCompilation, childCompilation, filename, childEntryChunks) {
  const webpackMajorVersion = Number(require('webpack/package.json').version.split('.')[0]);

  const helperAssetNames = childEntryChunks.map((entryChunk, index) => {
    const entryConfig = {
      hash: childCompilation.hash,
      chunk: entryChunk,
      name: `HtmlWebpackPlugin_${index}`
    };

    return webpackMajorVersion === 4
      ? mainCompilation.mainTemplate.getAssetPath(filename, entryConfig)
      : mainCompilation.getAssetPath(filename, entryConfig);
  });

  helperAssetNames.forEach((helperFileName) => {
    delete mainCompilation.assets[helperFileName];
  });

  const helperContents = helperAssetNames.map((helperFileName) => {
    return childCompilation.assets[helperFileName].source();
  });

  return helperContents;
}

module.exports = {
  HtmlWebpackChildCompiler
};
