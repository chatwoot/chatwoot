import { querySelectorAll } from '../../core/utils';

function internalLinkPresentEvaluate(node, options, virtualNode) {
  const links = querySelectorAll(virtualNode, 'a[href]');
  return links.some(vLink => {
    return /^#[^/!]/.test(vLink.actualNode.getAttribute('href'));
  });
}

export default internalLinkPresentEvaluate;
