const { FEATURES } = require('global');
const fs = require('fs-extra');

const lib = require('./dist/cjs/index');

const readCsfOrMdx = async (fileName, options) => {
  let code = (await fs.readFile(fileName, 'utf-8')).toString();
  if (fileName.endsWith('.mdx')) {
    const { compile } =
      FEATURES && FEATURES.previewMdx2
        ? await import('@storybook/mdx2-csf')
        : await import('@storybook/mdx1-csf');
    code = await compile(code);
  }
  return lib.loadCsf(code, { ...options, fileName });
};

module.exports = {
  readCsfOrMdx,
  ...lib,
};
