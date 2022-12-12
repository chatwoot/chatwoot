import escapeSelector from './escape-selector';
import getFriendlyUriEnd from './get-friendly-uri-end';
import getNodeAttributes from './get-node-attributes';
import matchesSelector from './element-matches';
import isXHTML from './is-xhtml';
import getShadowSelector from './get-shadow-selector';

let xhtml;
const ignoredAttributes = [
  'class',
  'style',
  'id',
  'selected',
  'checked',
  'disabled',
  'tabindex',
  'aria-checked',
  'aria-selected',
  'aria-invalid',
  'aria-activedescendant',
  'aria-busy',
  'aria-disabled',
  'aria-expanded',
  'aria-grabbed',
  'aria-pressed',
  'aria-valuenow'
];
const MAXATTRIBUTELENGTH = 31;

/**
 * get the attribute name and value as a string
 * @param {Element} node		The element that has the attribute
 * @param {Attribute} at		The attribute
 * @return {String}
 */
function getAttributeNameValue(node, at) {
  const name = at.name;
  let atnv;

  if (name.indexOf('href') !== -1 || name.indexOf('src') !== -1) {
    const friendly = getFriendlyUriEnd(node.getAttribute(name));
    if (friendly) {
      const value = encodeURI(friendly);
      if (value) {
        atnv = escapeSelector(at.name) + '$="' + escapeSelector(value) + '"';
      } else {
        return;
      }
    } else {
      atnv =
        escapeSelector(at.name) +
        '="' +
        escapeSelector(node.getAttribute(name)) +
        '"';
    }
  } else {
    atnv = escapeSelector(name) + '="' + escapeSelector(at.value) + '"';
  }
  return atnv;
}

function countSort(a, b) {
  return a.count < b.count ? -1 : a.count === b.count ? 0 : 1;
}

/**
 * Filter the attributes
 * @param {Attribute}		The potential attribute
 * @return {Boolean}		 Whether to include or exclude
 */
function filterAttributes(at) {
  return (
    !ignoredAttributes.includes(at.name) &&
    at.name.indexOf(':') === -1 &&
    (!at.value || at.value.length < MAXATTRIBUTELENGTH)
  );
}

/**
 * Calculate the statistics for the classes, attributes and tags on the page, using
 * the virtual DOM tree
 * @param {Object} domTree		The root node of the virtual DOM tree
 * @returns {Object}					The statistics consisting of three maps, one for classes,
 *														one for tags and one for attributes. The map values are
 *														the counts for how many elements with that feature exist
 */
export function getSelectorData(domTree) {
  /* eslint no-loop-func:0*/

  // Initialize the return structure with the three maps
  const data = {
    classes: {},
    tags: {},
    attributes: {}
  };

  domTree = Array.isArray(domTree) ? domTree : [domTree];
  let currentLevel = domTree.slice();
  const stack = [];
  while (currentLevel.length) {
    const current = currentLevel.pop();
    const node = current.actualNode;

    if (!!node.querySelectorAll) {
      // ignore #text nodes

      // count the tag
      const tag = node.nodeName;
      if (data.tags[tag]) {
        data.tags[tag]++;
      } else {
        data.tags[tag] = 1;
      }

      // count all the classes
      if (node.classList) {
        Array.from(node.classList).forEach(cl => {
          const ind = escapeSelector(cl);
          if (data.classes[ind]) {
            data.classes[ind]++;
          } else {
            data.classes[ind] = 1;
          }
        });
      }

      // count all the filtered attributes
      if (node.hasAttributes()) {
        Array.from(getNodeAttributes(node))
          .filter(filterAttributes)
          .forEach(at => {
            const atnv = getAttributeNameValue(node, at);
            if (atnv) {
              if (data.attributes[atnv]) {
                data.attributes[atnv]++;
              } else {
                data.attributes[atnv] = 1;
              }
            }
          });
      }
    }
    if (current.children.length) {
      // "recurse"
      stack.push(currentLevel);
      currentLevel = current.children.slice();
    }
    while (!currentLevel.length && stack.length) {
      currentLevel = stack.pop();
    }
  }
  return data;
}

/**
 * Given a node and the statistics on class frequency on the page,
 * return all its uncommon class data sorted in order of decreasing uniqueness
 * @param {Element} node			The node
 * @param {Object} classData	The map of classes to counts
 * @return {Array}						The sorted array of uncommon class data
 */
function uncommonClasses(node, selectorData) {
  // eslint no-loop-func:false
  const retVal = [];
  const classData = selectorData.classes;
  const tagData = selectorData.tags;

  if (node.classList) {
    Array.from(node.classList).forEach(cl => {
      const ind = escapeSelector(cl);
      if (classData[ind] < tagData[node.nodeName]) {
        retVal.push({
          name: ind,
          count: classData[ind],
          species: 'class'
        });
      }
    });
  }
  return retVal.sort(countSort);
}

/**
 * Given an element and a selector that finds that element (but possibly other sibling elements)
 * return the :nth-child(n) pseudo selector that uniquely finds the node within its siblings
 * @param {Element} elm			 The Element
 * @param {String} selector	 The selector
 * @return {String}					 The nth-child selector
 */
function getNthChildString(elm, selector) {
  const siblings =
    (elm.parentNode && Array.from(elm.parentNode.children || '')) || [];
  const hasMatchingSiblings = siblings.find(
    sibling => sibling !== elm && matchesSelector(sibling, selector)
  );
  if (hasMatchingSiblings) {
    const nthChild = 1 + siblings.indexOf(elm);
    return ':nth-child(' + nthChild + ')';
  } else {
    return '';
  }
}

/**
 * Get ID selector
 */
function getElmId(elm) {
  if (!elm.getAttribute('id')) {
    return;
  }
  const doc = (elm.getRootNode && elm.getRootNode()) || document;
  const id = '#' + escapeSelector(elm.getAttribute('id') || '');
  if (
    // Don't include youtube's uid values, they change	on reload
    !id.match(/player_uid_/) &&
    // Don't include IDs that occur more then once on the page
    doc.querySelectorAll(id).length === 1
  ) {
    return id;
  }
}

/**
 * Return the base CSS selector for a given element
 * @param	{HTMLElement} elm				 The element to get the selector for
 * @return {String|Array<String>}	Base CSS selector for the node
 */
function getBaseSelector(elm) {
  if (typeof xhtml === 'undefined') {
    xhtml = isXHTML(document);
  }
  return escapeSelector(xhtml ? elm.localName : elm.nodeName.toLowerCase());
}

/**
 * Given a node and the statistics on attribute frequency on the page,
 * return all its uncommon attribute data sorted in order of decreasing uniqueness
 * @param {Element} node			The node
 * @param {Object} attData		The map of attributes to counts
 * @return {Array}						The sorted array of uncommon attribute data
 */
function uncommonAttributes(node, selectorData) {
  const retVal = [];
  const attData = selectorData.attributes;
  const tagData = selectorData.tags;

  if (node.hasAttributes()) {
    Array.from(getNodeAttributes(node))
      .filter(filterAttributes)
      .forEach(at => {
        const atnv = getAttributeNameValue(node, at);

        if (atnv && attData[atnv] < tagData[node.nodeName]) {
          retVal.push({
            name: atnv,
            count: attData[atnv],
            species: 'attribute'
          });
        }
      });
  }
  return retVal.sort(countSort);
}

/**
 * generates a selector fragment for an element based on the statistics of the page in
 * which the element exists. This function takes into account the fact that selectors that
 * use classes and tags are much faster than universal selectors. It also tries to use a
 * unique class selector before a unique attribute selector (with the tag), followed by
 * a selector made up of the three least common features statistically. A feature will
 * also only be used if it is less common than the tag of the element itself.
 *
 * @param {Element} elm			The element for which to generate a selector
 * @param {Object} options	 Options for how to generate the selector
 * @param {RootNode} doc		 The root node of the document or document fragment
 * @returns {String}				 The selector
 */

function getThreeLeastCommonFeatures(elm, selectorData) {
  let selector = '';
  let features;
  const clss = uncommonClasses(elm, selectorData);
  const atts = uncommonAttributes(elm, selectorData);

  if (clss.length && clss[0].count === 1) {
    // only use the unique class
    features = [clss[0]];
  } else if (atts.length && atts[0].count === 1) {
    // only use the unique attribute value
    features = [atts[0]];
    // if no class, add the tag
    selector = getBaseSelector(elm);
  } else {
    features = clss.concat(atts);
    // sort by least common
    features.sort(countSort);

    // select three least common features
    features = features.slice(0, 3);

    // if no class, add the tag
    if (
      !features.some(feat => {
        return feat.species === 'class';
      })
    ) {
      // has no class
      selector = getBaseSelector(elm);
    } else {
      // put the classes at the front of the selector
      features.sort((a, b) => {
        return a.species !== b.species && a.species === 'class'
          ? -1
          : a.species === b.species
          ? 0
          : 1;
      });
    }
  }

  // construct the return value
  return (selector += features.reduce((val, feat) => {
    /*eslint indent: 0*/
    switch (feat.species) {
      case 'class':
        return val + '.' + feat.name;
      case 'attribute':
        return val + '[' + feat.name + ']';
    }
    return val; // should never happen
  }, ''));
}

/**
 * generates a single selector for an element
 * @param {Element} elm			The element for which to generate a selector
 * @param {Object} options	 Options for how to generate the selector
 * @param {RootNode} doc		 The root node of the document or document fragment
 * @returns {String}				 The selector
 */

function generateSelector(elm, options, doc) {
  /*eslint no-loop-func:0*/
  // TODO: es-modules_selectorData
  if (!axe._selectorData) {
    throw new Error('Expect axe._selectorData to be set up');
  }
  const { toRoot = false } = options;
  let selector;
  let similar;

  /**
   * Try to find a unique selector by filtering out all the clashing
   * nodes by adding ancestor selectors iteratively.
   * This loop is much faster than recursing and using querySelectorAll
   */
  do {
    let features = getElmId(elm);
    if (!features) {
      features = getThreeLeastCommonFeatures(elm, axe._selectorData);
      features += getNthChildString(elm, features);
    }
    if (selector) {
      selector = features + ' > ' + selector;
    } else {
      selector = features;
    }
    if (!similar) {
      similar = Array.from(doc.querySelectorAll(selector));
    } else {
      similar = similar.filter(item => {
        return matchesSelector(item, selector);
      });
    }
    elm = elm.parentElement;
  } while ((similar.length > 1 || toRoot) && elm && elm.nodeType !== 11);

  if (similar.length === 1) {
    return selector;
  } else if (selector.indexOf(' > ') !== -1) {
    // For the odd case that document doesn't have a unique selector
    return ':root' + selector.substring(selector.indexOf(' > '));
  }
  return ':root';
}

/**
 * Gets a unique CSS selector
 * @param {HTMLElement} node The element to get the selector for
 * @param {Object} optional options
 * @returns {String|Array<String>} Unique CSS selector for the node
 */
export default function getSelector(elm, options) {
  return getShadowSelector(generateSelector, elm, options);
}
