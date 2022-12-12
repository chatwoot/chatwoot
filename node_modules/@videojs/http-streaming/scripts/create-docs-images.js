/* eslint-disable no-console */
const nomnoml = require('nomnoml');
const fs = require('fs');
const path = require('path');

const basePath = path.resolve(__dirname, '..');
const docImageDir = path.join(basePath, 'docs/images');
const nomnomlSourceDir = path.join(basePath, 'docs/images/sources');

const buildImages = {
  build() {
    const files = fs.readdirSync(nomnomlSourceDir);

    while (files.length > 0) {
      const file = path.resolve(nomnomlSourceDir, files.shift());
      const basename = path.basename(file, 'txt');

      if (/.nomnoml/.test(basename)) {
        const fileContents = fs.readFileSync(file, 'utf-8');
        const generated = nomnoml.renderSvg(fileContents);
        const newFilePath = path.join(docImageDir, basename) + 'svg';
        const outFile = fs.createWriteStream(newFilePath);

        console.log(`wrote file ${newFilePath}`);
        outFile.write(generated);
      }
    }
  }
};

buildImages.build();
