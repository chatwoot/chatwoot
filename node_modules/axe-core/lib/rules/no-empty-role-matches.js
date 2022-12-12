function noEmptyRoleMatches(node, virtualNode) {
  if (!virtualNode.hasAttr('role')) {
    return false;
  }

  if (!virtualNode.attr('role').trim()) {
    return false;
  }

  return true;
}

export default noEmptyRoleMatches;
