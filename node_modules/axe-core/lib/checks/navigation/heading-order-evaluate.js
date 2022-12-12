import cache from '../../core/base/cache';
import { querySelectorAllFilter, getAncestry } from '../../core/utils';
import { isVisible } from '../../commons/dom';

function getLevel(vNode) {
  const role = vNode.attr('role');
  if (role && role.includes('heading')) {
    const ariaHeadingLevel = vNode.attr('aria-level');
    const level = parseInt(ariaHeadingLevel, 10);

    // default aria-level for a heading is 2 if it is
    // not set or set to an incorrect value
    // @see https://www.w3.org/TR/wai-aria-1.1/#heading
    if (isNaN(level) || level < 1 || level > 6) {
      return 2;
    }

    return level;
  }

  const headingLevel = vNode.props.nodeName.match(/h(\d)/);
  if (headingLevel) {
    return parseInt(headingLevel[1], 10);
  }

  return -1;
}

function headingOrderEvaluate() {
  let headingOrder = cache.get('headingOrder');
  if (headingOrder) {
    return true;
  }

  // find all headings, even ones that are outside the current
  // context. also need to know where iframes are so we can insert
  // the results of any in-context iframes into their proper order
  // @see https://github.com/dequelabs/axe-core/issues/728
  const selector = 'h1, h2, h3, h4, h5, h6, [role=heading], iframe, frame';
  // TODO: es-modules_tree
  const vNodes = querySelectorAllFilter(axe._tree[0], selector, vNode =>
    isVisible(vNode.actualNode, true)
  );

  headingOrder = vNodes.map(vNode => {
    // save the path so we can reconstruct the heading order
    return {
      ancestry: [getAncestry(vNode.actualNode)],
      level: getLevel(vNode)
    };
  });

  this.data({ headingOrder });
  cache.set('headingOrder', vNodes);
  return true;
}

export default headingOrderEvaluate;
