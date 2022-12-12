import getRootNode from '../dom/get-root-node';
import cache from '../../core/base/cache';
import { tokenList } from '../../core/utils';
import standards from '../../standards';
import { sanitize } from '../text/';

const idRefsRegex = /^idrefs?$/;

/**
 * Cache all ID references of a node and its children
 */
function cacheIdRefs(node, idRefs, refAttrs) {
  if (node.hasAttribute) {
    if (node.nodeName.toUpperCase() === 'LABEL' && node.hasAttribute('for')) {
      const id = node.getAttribute('for');
      idRefs[id] = idRefs[id] || [];
      idRefs[id].push(node);
    }

    for (let i = 0; i < refAttrs.length; ++i) {
      const attr = refAttrs[i];
      const attrValue = sanitize(node.getAttribute(attr) || '');

      if (!attrValue) {
        continue;
      }

      const tokens = tokenList(attrValue);
      for (let k = 0; k < tokens.length; ++k) {
        idRefs[tokens[k]] = idRefs[tokens[k]] || [];
        idRefs[tokens[k]].push(node);
      }
    }
  }

  for (let i = 0; i < node.children.length; i++) {
    cacheIdRefs(node.children[i], idRefs, refAttrs);
  }
}

/**
 * Return all DOM nodes that use the nodes ID in the accessibility tree.
 * @param {Element} node
 * @returns {Element[]}
 */
function getAccessibleRefs(node) {
  node = node.actualNode || node;
  let root = getRootNode(node);
  root = root.documentElement || root; // account for shadow roots

  let idRefsByRoot = cache.get('idRefsByRoot');
  if (!idRefsByRoot) {
    idRefsByRoot = new WeakMap();
    cache.set('idRefsByRoot', idRefsByRoot);
  }

  let idRefs = idRefsByRoot.get(root);
  if (!idRefs) {
    idRefs = {};
    idRefsByRoot.set(root, idRefs);

    const refAttrs = Object.keys(standards.ariaAttrs).filter(attr => {
      const { type } = standards.ariaAttrs[attr];
      return idRefsRegex.test(type);
    });

    cacheIdRefs(root, idRefs, refAttrs);
  }

  return idRefs[node.id] || [];
}

export default getAccessibleRefs;
