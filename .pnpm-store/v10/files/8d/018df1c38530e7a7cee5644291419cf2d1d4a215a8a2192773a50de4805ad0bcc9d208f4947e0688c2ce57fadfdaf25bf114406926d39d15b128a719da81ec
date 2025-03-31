/* eslint-env es6 */
const md = require('markdown-it')();
const markdownItAttrs = require('./');

md.use(markdownItAttrs).use(require('../markdown-it-implicit-figures'));

const src = `header1 | header2
------- | -------
column1 | column2

{.special}
`;

const res = md.render(src);

console.log(res);  // eslint-disable-line
