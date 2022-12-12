function noRoleMatches(node) {
  return !node.getAttribute('role');
}

export default noRoleMatches;
