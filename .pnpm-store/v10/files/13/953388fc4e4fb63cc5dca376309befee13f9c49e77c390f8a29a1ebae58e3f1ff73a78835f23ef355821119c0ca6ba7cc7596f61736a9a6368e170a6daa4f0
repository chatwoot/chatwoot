const md = require('markdown-it')();
const markdownItAttrs = require('markdown-it-attrs');

md.use(markdownItAttrs);

let src = '# header {.style-me}\n';
src += 'paragraph {data-toggle=modal}';

md.render(src);
