import { isAccessibleRef } from '../commons/aria';

function duplicateIdAriaMatches(node) {
  return isAccessibleRef(node);
}

export default duplicateIdAriaMatches;
