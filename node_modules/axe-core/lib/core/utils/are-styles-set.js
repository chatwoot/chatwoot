function areStylesSet(el, styles, stopAt) {
  var styl = window.getComputedStyle(el, null);
  if (!styl) {
    return false;
  }
  for (var i = 0; i < styles.length; ++i) {
    var att = styles[i];
    if (styl.getPropertyValue(att.property) === att.value) {
      return true;
    }
  }
  if (!el.parentNode || el.nodeName.toUpperCase() === stopAt.toUpperCase()) {
    return false;
  }
  return areStylesSet(el.parentNode, styles, stopAt);
}

export default areStylesSet;
