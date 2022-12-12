const { getOptions } = require('loader-utils');
const mdx = require('@mdx-js/mdx');
const { createCompiler } = require('./dist/cjs');

const DEFAULT_RENDERER = `
import React from 'react'
import { mdx } from '@mdx-js/react'
`;

// Lifted from MDXv1 loader
// https://github.com/mdx-js/mdx/blob/v1/packages/loader/index.js
//
// Added
// - webpack5 support
// - MDX compiler built in
const loader = async function (content) {
  const callback = this.async();
  // this.getOptions() is webpack5 only
  const queryOptions = this.getOptions ? this.getOptions() : getOptions(this);
  const options = Object.assign({}, queryOptions, {
    filepath: this.resourcePath,
  });
  if (!options.skipCsf) {
    options.compilers = [createCompiler(options), ...(options.compilers || [])];
  }

  let result;

  try {
    result = await mdx(content, options);
  } catch (err) {
    return callback(err);
  }

  const { renderer = DEFAULT_RENDERER } = options;

  const code = `${renderer}\n${result}`;
  return callback(null, code);
};

module.exports = loader;
