import cache from '../../core/base/cache';
import { querySelectorAllFilter } from '../../core/utils';
import { isVisible, findUpVirtual } from '../../commons/dom';

function pageNoDuplicateEvaluate(node, options, virtualNode) {
  if (!options || !options.selector || typeof options.selector !== 'string') {
    throw new TypeError(
      'page-no-duplicate requires options.selector to be a string'
    );
  }

  // only look at the first node and it's related nodes
  const key = 'page-no-duplicate;' + options.selector;
  if (cache.get(key)) {
    this.data('ignored');
    return;
  }
  cache.set(key, true);

  let elms = querySelectorAllFilter(axe._tree[0], options.selector, elm =>
    isVisible(elm.actualNode)
  );

  // Filter elements that, within certain contexts, don't map their role.
  // e.g. a <footer> inside a <main> is not a banner, but in the <body> context it is
  if (typeof options.nativeScopeFilter === 'string') {
    elms = elms.filter(elm => {
      return (
        elm.actualNode.hasAttribute('role') ||
        !findUpVirtual(elm, options.nativeScopeFilter)
      );
    });
  }

  this.relatedNodes(
    elms.filter(elm => elm !== virtualNode).map(elm => elm.actualNode)
  );

  return elms.length <= 1;
}

export default pageNoDuplicateEvaluate;
