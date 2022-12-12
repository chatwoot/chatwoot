const shallowEqual = function(a, b) {
  // if both are undefined
  // or one or the other is undefined
  // they are not equal
  if ((!a && !b) || (!a && b) || (a && !b)) {
    return false;
  }

  // they are the same object and thus, equal
  if (a === b) {
    return true;
  }

  // sort keys so we can make sure they have
  // all the same keys later.
  const akeys = Object.keys(a).sort();
  const bkeys = Object.keys(b).sort();

  // different number of keys, not equal
  if (akeys.length !== bkeys.length) {
    return false;
  }

  for (let i = 0; i < akeys.length; i++) {
    const key = akeys[i];

    // different sorted keys, not equal
    if (key !== bkeys[i]) {
      return false;
    }

    // different values, not equal
    if (a[key] !== b[key]) {
      return false;
    }
  }

  return true;
};

export default shallowEqual;
