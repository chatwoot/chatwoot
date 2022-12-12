import { getRootNode, isFocusable } from '../commons/dom';
import { isAccessibleRef } from '../commons/aria';
import { escapeSelector } from '../core/utils';

function duplicateIdActiveMatches(node) {
  const id = node.getAttribute('id').trim();
  const idSelector = `*[id="${escapeSelector(id)}"]`;
  const idMatchingElms = Array.from(
    getRootNode(node).querySelectorAll(idSelector)
  );

  return !isAccessibleRef(node) && idMatchingElms.some(isFocusable);
}

export default duplicateIdActiveMatches;
