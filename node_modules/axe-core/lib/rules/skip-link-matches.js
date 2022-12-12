import { isSkipLink, isOffscreen } from '../commons/dom';

function skipLinkMatches(node) {
  return isSkipLink(node) && isOffscreen(node);
}

export default skipLinkMatches;
