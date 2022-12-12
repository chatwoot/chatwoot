import getStyleSheetFactory from './get-stylesheet-factory';
import uniqueArray from './unique-array';
import getRootNode from './get-root-node';
import parseStylesheet from './parse-stylesheet';
import querySelectorAllFilter from './query-selector-all-filter';

/**
 * Given a rootNode - construct CSSOM
 * -> get all source nodes (document & document fragments) within given root node
 * -> recursively call `parseStylesheets` to resolve styles for each node
 *
 * @method preloadCssom
 * @memberof `axe.utils`
 * @param {Object} options composite options object
 * @property {Array<String>} options.assets array of preloaded assets requested, eg: [`cssom`]
 * @property {Number} options.timeout timeout
 * @property {Object} options.treeRoot (optional) the DOM tree to be inspected
 * @returns {Promise}
 */
// TODO: es-modules_tree
function preloadCssom({ treeRoot = axe._tree[0] }) {
  /**
   * get all `document` and `documentFragment` with in given `tree`
   */
  const rootNodes = getAllRootNodesInTree(treeRoot);

  if (!rootNodes.length) {
    return Promise.resolve();
  }

  const dynamicDoc = document.implementation.createHTMLDocument(
    'Dynamic document for loading cssom'
  );

  const convertDataToStylesheet = getStyleSheetFactory(dynamicDoc);

  return getCssomForAllRootNodes(
    rootNodes,
    convertDataToStylesheet
  ).then(assets => flattenAssets(assets));
}

export default preloadCssom;

/**
 * Returns am array of source nodes containing `document` and `documentFragment` in a given `tree`.
 *
 * @param {Object} treeRoot tree
 * @returns {Array<Object>} array of objects, which each object containing a root and an optional `shadowId`
 */
function getAllRootNodesInTree(tree) {
  const ids = [];

  const rootNodes = querySelectorAllFilter(tree, '*', node => {
    if (ids.includes(node.shadowId)) {
      return false;
    }
    ids.push(node.shadowId);
    return true;
  }).map(node => {
    return {
      shadowId: node.shadowId,
      rootNode: getRootNode(node.actualNode)
    };
  });

  return uniqueArray(rootNodes, []);
}

/**
 * Process CSSOM on all root nodes
 *
 * @param {Array<Object>} rootNodes array of root nodes, where node  is an enhanced `document` or `documentFragment` object returned from `getAllRootNodesInTree`
 * @param {Function} convertDataToStylesheet fn to convert given data to Stylesheet object
 * @returns {Promise}
 */
function getCssomForAllRootNodes(rootNodes, convertDataToStylesheet) {
  const promises = [];

  rootNodes.forEach(({ rootNode, shadowId }, index) => {
    const sheets = getStylesheetsOfRootNode(
      rootNode,
      shadowId,
      convertDataToStylesheet
    );
    if (!sheets) {
      return Promise.all(promises);
    }

    const rootIndex = index + 1;
    const parseOptions = {
      rootNode,
      shadowId,
      convertDataToStylesheet,
      rootIndex
    };
    /**
     * Note:
     * `importedUrls` - keeps urls of already imported stylesheets, to prevent re-fetching
     * eg: nested, cyclic or cross referenced `@import` urls
     */
    const importedUrls = [];

    const p = Promise.all(
      sheets.map((sheet, sheetIndex) => {
        const priority = [rootIndex, sheetIndex];

        return parseStylesheet(sheet, parseOptions, priority, importedUrls);
      })
    );

    promises.push(p);
  });

  return Promise.all(promises);
}

/**
 * Flatten CSSOM assets
 *
 * @param {Array.<Object[]>} assets nested assets (varying depth)
 * @returns {Array<Object>} Array of CSSOM object
 */
function flattenAssets(assets) {
  return assets.reduce(
    (acc, val) =>
      Array.isArray(val) ? acc.concat(flattenAssets(val)) : acc.concat(val),
    []
  );
}

/**
 * Get stylesheet(s) for root
 *
 * @param {Object} options.rootNode `document` or `documentFragment`
 * @param {String} options.shadowId an id if undefined denotes that given root is a document fragment/ shadowDOM
 * @param {Function} options.convertDataToStylesheet a utility function to generate a style sheet from given data (text)
 * @returns {Array<Object>} an array of stylesheets
 */
function getStylesheetsOfRootNode(rootNode, shadowId, convertDataToStylesheet) {
  let sheets;

  // nodeType === 11  -> DOCUMENT_FRAGMENT
  if (rootNode.nodeType === 11 && shadowId) {
    sheets = getStylesheetsFromDocumentFragment(
      rootNode,
      convertDataToStylesheet
    );
  } else {
    sheets = getStylesheetsFromDocument(rootNode);
  }

  return filterStylesheetsWithSameHref(sheets);
}

/**
 * Get stylesheets from `documentFragment`
 *
 * @property {Object} options.rootNode `documentFragment`
 * @property {Function} options.convertDataToStylesheet a utility function to generate a stylesheet from given data
 * @returns {Array<Object>}
 */
function getStylesheetsFromDocumentFragment(rootNode, convertDataToStylesheet) {
  return (
    Array.from(rootNode.children)
      .filter(filerStyleAndLinkAttributesInDocumentFragment)
      // Reducer to convert `<style></style>` and `<link>` references to `CSSStyleSheet` object
      .reduce((out, node) => {
        const nodeName = node.nodeName.toUpperCase();
        const data = nodeName === 'STYLE' ? node.textContent : node;
        const isLink = nodeName === 'LINK';
        const stylesheet = convertDataToStylesheet({
          data,
          isLink,
          root: rootNode
        });
        out.push(stylesheet.sheet);
        return out;
      }, [])
  );
}

/**
 * Get stylesheets from `document`
 * -> filter out stylesheet that are `media=print`
 *
 * @param {Object} rootNode `document`
 * @returns {Array<Object>}
 */
function getStylesheetsFromDocument(rootNode) {
  return Array.from(rootNode.styleSheets).filter(sheet =>
    filterMediaIsPrint(sheet.media.mediaText)
  );
}

/**
 * Get all `<style></style>` and `<link>` attributes
 * -> limit to only `style` or `link` attributes with `rel=stylesheet` and `media != print`
 *
 * @param {Object} node HTMLElement
 * @returns {Boolean}
 */
function filerStyleAndLinkAttributesInDocumentFragment(node) {
  const nodeName = node.nodeName.toUpperCase();
  const linkHref = node.getAttribute('href');
  const linkRel = node.getAttribute('rel');
  const isLink =
    nodeName === 'LINK' &&
    linkHref &&
    linkRel &&
    node.rel.toUpperCase().includes('STYLESHEET');
  const isStyle = nodeName === 'STYLE';
  return isStyle || (isLink && filterMediaIsPrint(node.media));
}

/**
 * Exclude `link[rel='stylesheet]` attributes where `media=print`
 *
 * @param {String} media media value eg: 'print'
 * @returns {Boolean}
 */
function filterMediaIsPrint(media) {
  if (!media) {
    return true;
  }
  return !media.toUpperCase().includes('PRINT');
}

/**
 * Exclude any duplicate `stylesheets`, that share the same `href`
 *
 * @param {Array<Object>} sheets stylesheets
 * @returns {Array<Object>}
 */
function filterStylesheetsWithSameHref(sheets) {
  const hrefs = [];
  return sheets.filter(sheet => {
    if (!sheet.href) {
      // include sheets without `href`
      return true;
    }
    // if `href` is present, ensure they are not duplicates
    if (hrefs.includes(sheet.href)) {
      return false;
    }
    hrefs.push(sheet.href);
    return true;
  });
}
