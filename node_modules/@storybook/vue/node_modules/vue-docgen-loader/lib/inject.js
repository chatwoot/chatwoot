"use strict";

const jscodeshift = require('jscodeshift');
/**
 * Inject docgen results into components.
 * @param content {string} - JS source code
 * @param infoList {object[]} - A list of docgen result
 * @param injectAt {string} - Property name to inject docgen info
 * @return {string} - source code with docgen info
 */


const inject = (content, infoList, injectAt) => {
  // In order to inject info object to Component, we need to assign default
  // exported expression to a variable.
  const [normalizedCode, defaultExportAltName] = reDeclareDefaultExport(content, infoList);
  const infoInjectors = infoList.map(info => {
    const name = !info.exportName || info.exportName === 'default' ? defaultExportAltName : info.exportName;
    return `${name}.${injectAt} = ${JSON.stringify(info)}`;
  }).join('\n');
  return normalizedCode + '\n' + infoInjectors;
};

module.exports = inject;
/**
 * Replace default export with variable declaration and default export.
 *
 * ```js
 * export default { props: ['foo'] }
 *
 * // to ...
 *
 * const __vuedocgen_export_0 = { props: ['foo'] }
 * export default __vuedocgen_export_0
 * ```
 *
 * @param content {string} - JS source code
 * @param infoList {object[]} - A list of docgen result
 * @return {[string, string]} - Modified source code and variable name to inject info
 */

const reDeclareDefaultExport = (content, infoList) => {
  if (!infoList.some(info => !info.exportName || info.exportName === 'default')) {
    return [content, null];
  }

  const ast = jscodeshift(content);
  const defaultExportAltName = generateDefaultExportAltName(ast);
  ast.find(jscodeshift.ExportDefaultDeclaration).forEach(path => {
    const info = infoList.find(info => info.exportName === 'default' || !info.exportName);

    if (!info) {
      return;
    }

    jscodeshift(path).replaceWith(jscodeshift.variableDeclaration('const', [jscodeshift.variableDeclarator(jscodeshift.identifier(defaultExportAltName), path.value.declaration)]));
    jscodeshift(path).insertAfter(jscodeshift.exportDefaultDeclaration(jscodeshift.identifier(defaultExportAltName)));
  });
  return [ast.toSource(), defaultExportAltName];
};
/**
 * Generate a name for default exported expression.
 * @param ast {object}
 * @return {string} - identifier
 */


const generateDefaultExportAltName = (ast, i = 0) => {
  const name = `__vuedocgen_export_${i}`;
  const idents = ast.find(jscodeshift.Identifier, node => node.name === name);
  return idents.length === 0 ? name : generateDefaultExportAltName(ast, i + 1);
};