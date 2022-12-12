const path = require('path');
const { ScriptTransformer } = require('@jest/transform');
const { dedent } = require('ts-dedent');

const { compileSync } = require('@storybook/mdx1-csf');

module.exports = {
  process(src, filename, config, { instrument }) {
    const result = dedent`
      /* @jsx mdx */
      import React from 'react'
      import { mdx } from '@mdx-js/react'
      ${compileSync(src, { filepath: filename })}
    `;

    const extension = path.extname(filename);
    const jsFileName = `${filename.slice(0, -extension.length)}.js`;

    return new ScriptTransformer(config).transformSource(jsFileName, result, instrument);
  },
};
