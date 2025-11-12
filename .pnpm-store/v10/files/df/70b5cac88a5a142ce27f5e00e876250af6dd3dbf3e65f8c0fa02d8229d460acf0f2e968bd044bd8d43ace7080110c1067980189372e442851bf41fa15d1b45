/**
 * @file Runs `prettier` as an ESLint rule.
 * @author Andres Suarez
 */

// @ts-check

/**
 * @typedef {import('eslint').AST.Range} Range
 * @typedef {import('eslint').AST.SourceLocation} SourceLocation
 * @typedef {import('eslint').ESLint.Plugin} Plugin
 * @typedef {import('eslint').ESLint.ObjectMetaProperties} ObjectMetaProperties
 * @typedef {import('prettier').FileInfoOptions} FileInfoOptions
 * @typedef {import('prettier').Options} PrettierOptions
 * @typedef {PrettierOptions & { onDiskFilepath: string, parserMeta?: ObjectMetaProperties['meta'], parserPath?: string, usePrettierrc?: boolean }} Options
 */

'use strict';

// ------------------------------------------------------------------------------
//  Requirements
// ------------------------------------------------------------------------------

const {
  showInvisibles,
  generateDifferences,
} = require('prettier-linter-helpers');
const { name, version } = require('./package.json');

// ------------------------------------------------------------------------------
//  Constants
// ------------------------------------------------------------------------------

const { INSERT, DELETE, REPLACE } = generateDifferences;

// ------------------------------------------------------------------------------
//  Privates
// ------------------------------------------------------------------------------

// Lazily-loaded Prettier.
/**
 * @type {(source: string, options: Options, fileInfoOptions: FileInfoOptions) => string}
 */
let prettierFormat;

// ------------------------------------------------------------------------------
//  Rule Definition
// ------------------------------------------------------------------------------

/**
 * Reports a difference.
 *
 * @param {import('eslint').Rule.RuleContext} context - The ESLint rule context.
 * @param {import('prettier-linter-helpers').Difference} difference - The difference object.
 * @returns {void}
 */
function reportDifference(context, difference) {
  const { operation, offset, deleteText = '', insertText = '' } = difference;
  const range = /** @type {Range} */ ([offset, offset + deleteText.length]);
  // `context.getSourceCode()` was deprecated in ESLint v8.40.0 and replaced
  // with the `sourceCode` property.
  // TODO: Only use property when our eslint peerDependency is >=8.40.0.
  const [start, end] = range.map(index =>
    (context.sourceCode ?? context.getSourceCode()).getLocFromIndex(index),
  );

  context.report({
    messageId: operation,
    data: {
      deleteText: showInvisibles(deleteText),
      insertText: showInvisibles(insertText),
    },
    loc: { start, end },
    fix: fixer => fixer.replaceTextRange(range, insertText),
  });
}

// ------------------------------------------------------------------------------
//  Module Definition
// ------------------------------------------------------------------------------

/**
 * @type {Plugin}
 */
const eslintPluginPrettier = {
  meta: { name, version },
  configs: {
    recommended: {
      extends: ['prettier'],
      plugins: ['prettier'],
      rules: {
        'prettier/prettier': 'error',
        'arrow-body-style': 'off',
        'prefer-arrow-callback': 'off',
      },
    },
  },
  rules: {
    prettier: {
      meta: {
        docs: {
          url: 'https://github.com/prettier/eslint-plugin-prettier#options',
        },
        type: 'layout',
        fixable: 'code',
        schema: [
          // Prettier options:
          {
            type: 'object',
            properties: {},
            additionalProperties: true,
          },
          {
            type: 'object',
            properties: {
              usePrettierrc: { type: 'boolean' },
              fileInfoOptions: {
                type: 'object',
                properties: {},
                additionalProperties: true,
              },
            },
            additionalProperties: true,
          },
        ],
        messages: {
          [INSERT]: 'Insert `{{ insertText }}`',
          [DELETE]: 'Delete `{{ deleteText }}`',
          [REPLACE]: 'Replace `{{ deleteText }}` with `{{ insertText }}`',
        },
      },
      create(context) {
        const usePrettierrc =
          !context.options[1] || context.options[1].usePrettierrc !== false;
        /**
         * @type {FileInfoOptions}
         */
        const fileInfoOptions =
          (context.options[1] && context.options[1].fileInfoOptions) || {};

        // `context.getSourceCode()` was deprecated in ESLint v8.40.0 and replaced
        // with the `sourceCode` property.
        // TODO: Only use property when our eslint peerDependency is >=8.40.0.
        const sourceCode = context.sourceCode ?? context.getSourceCode();
        // `context.getFilename()` was deprecated in ESLint v8.40.0 and replaced
        // with the `filename` property.
        // TODO: Only use property when our eslint peerDependency is >=8.40.0.
        const filepath = context.filename ?? context.getFilename();

        // Processors that extract content from a file, such as the markdown
        // plugin extracting fenced code blocks may choose to specify virtual
        // file paths. If this is the case then we need to resolve prettier
        // config and file info using the on-disk path instead of the virtual
        // path.
        // `context.getPhysicalFilename()` was deprecated in ESLint v8.40.0 and replaced
        // with the `physicalFilename` property.
        // TODO: Only use property when our eslint peerDependency is >=8.40.0.
        const onDiskFilepath =
          context.physicalFilename ?? context.getPhysicalFilename();
        const source = sourceCode.text;

        return {
          Program() {
            if (!prettierFormat) {
              // Prettier is expensive to load, so only load it if needed.
              prettierFormat = require('synckit').createSyncFn(
                require.resolve('./worker'),
              );
            }

            /**
             * @type {PrettierOptions}
             */
            const eslintPrettierOptions = context.options[0] || {};

            const parser = context.languageOptions?.parser;

            // prettier.format() may throw a SyntaxError if it cannot parse the
            // source code it is given. Usually for JS files this isn't a
            // problem as ESLint will report invalid syntax before trying to
            // pass it to the prettier plugin. However this might be a problem
            // for non-JS languages that are handled by a plugin. Notably Vue
            // files throw an error if they contain unclosed elements, such as
            // `<template><div></template>. In this case report an error at the
            // point at which parsing failed.
            /**
             * @type {string}
             */
            let prettierSource;
            try {
              prettierSource = prettierFormat(
                source,
                {
                  ...eslintPrettierOptions,
                  filepath,
                  onDiskFilepath,
                  parserMeta:
                    parser &&
                    (parser.meta ?? {
                      name: parser.name,
                      version: parser.version,
                    }),
                  parserPath: context.parserPath,
                  usePrettierrc,
                },
                fileInfoOptions,
              );
            } catch (err) {
              if (!(err instanceof SyntaxError)) {
                throw err;
              }

              let message = 'Parsing error: ' + err.message;

              const error =
                /** @type {SyntaxError & {codeFrame: string; loc: SourceLocation}} */ (
                  err
                );

              // Prettier's message contains a codeframe style preview of the
              // invalid code and the line/column at which the error occurred.
              // ESLint shows those pieces of information elsewhere already so
              // remove them from the message
              if (error.codeFrame) {
                message = message.replace(`\n${error.codeFrame}`, '');
              }
              if (error.loc) {
                message = message.replace(/ \(\d+:\d+\)$/, '');
              }

              context.report({ message, loc: error.loc });

              return;
            }

            if (prettierSource == null) {
              return;
            }

            if (source !== prettierSource) {
              const differences = generateDifferences(source, prettierSource);

              for (const difference of differences) {
                reportDifference(context, difference);
              }
            }
          },
        };
      },
    },
  },
};

module.exports = eslintPluginPrettier;
