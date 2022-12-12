import { sanitize } from '../commons/text';

function frameTitleHasTextMatches(node) {
  var title = node.getAttribute('title');
  return !!sanitize(title);
}

export default frameTitleHasTextMatches;
