import { getExplicitRole } from '../commons/aria';

function ariaAllowedRoleMatches(node) {
  return (
    getExplicitRole(node, {
      dpub: true,
      fallback: true
    }) !== null
  );
}

export default ariaAllowedRoleMatches;
