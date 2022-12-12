import { isVisible } from '../../commons/dom';
import { getRole, getExplicitRole } from '../../commons/aria';

function onlyDlitemsEvaluate(node, options, virtualNode) {
  const ALLOWED_ROLES = ['definition', 'term', 'list'];
  const base = {
    badNodes: [],
    hasNonEmptyTextNode: false
  };

  const content = virtualNode.children.reduce((content, child) => {
    const { actualNode } = child;
    if (
      actualNode.nodeName.toUpperCase() === 'DIV' &&
      getRole(actualNode) === null
    ) {
      return content.concat(child.children);
    }
    return content.concat(child);
  }, []);

  const result = content.reduce((out, childNode) => {
    const { actualNode } = childNode;
    const tagName = actualNode.nodeName.toUpperCase();

    if (actualNode.nodeType === 1 && isVisible(actualNode, true, false)) {
      const explicitRole = getExplicitRole(actualNode);

      if ((tagName !== 'DT' && tagName !== 'DD') || explicitRole) {
        if (!ALLOWED_ROLES.includes(explicitRole)) {
          // handle comment - https://github.com/dequelabs/axe-core/pull/518/files#r139284668
          out.badNodes.push(actualNode);
        }
      }
    } else if (
      actualNode.nodeType === 3 &&
      actualNode.nodeValue.trim() !== ''
    ) {
      out.hasNonEmptyTextNode = true;
    }
    return out;
  }, base);

  if (result.badNodes.length) {
    this.relatedNodes(result.badNodes);
  }

  return !!result.badNodes.length || result.hasNonEmptyTextNode;
}

export default onlyDlitemsEvaluate;
