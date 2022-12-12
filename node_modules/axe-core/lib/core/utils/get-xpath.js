import escapeSelector from './escape-selector';

function getXPathArray(node, path) {
  var sibling, count;
  // Gets an XPath for an element which describes its hierarchical location.
  if (!node) {
    return [];
  }
  if (!path && node.nodeType === 9) {
    // special case for when we are called and give the document itself as the starting node
    path = [
      {
        str: 'html'
      }
    ];
    return path;
  }
  path = path || [];
  if (node.parentNode && node.parentNode !== node) {
    path = getXPathArray(node.parentNode, path);
  }

  if (node.previousSibling) {
    count = 1;
    sibling = node.previousSibling;
    do {
      if (sibling.nodeType === 1 && sibling.nodeName === node.nodeName) {
        count++;
      }
      sibling = sibling.previousSibling;
    } while (sibling);
    if (count === 1) {
      count = null;
    }
  } else if (node.nextSibling) {
    sibling = node.nextSibling;
    do {
      if (sibling.nodeType === 1 && sibling.nodeName === node.nodeName) {
        count = 1;
        sibling = null;
      } else {
        count = null;
        sibling = sibling.previousSibling;
      }
    } while (sibling);
  }

  if (node.nodeType === 1) {
    var element = {};
    element.str = node.nodeName.toLowerCase();
    // add the id and the count so we can construct robust versions of the xpath
    var id = node.getAttribute && escapeSelector(node.getAttribute('id'));
    if (id && node.ownerDocument.querySelectorAll('#' + id).length === 1) {
      element.id = node.getAttribute('id');
    }
    if (count > 1) {
      element.count = count;
    }
    path.push(element);
  }
  return path;
}

// Robust is intended to allow xpaths to be robust to changes in the HTML structure of the page
// This means always use the id when present
// Non robust means always use the count (i.e. the exact position of the element)
// Ironically this is a bit of a misnomer because in very, very dynamic pages (e.g. where ids are generated on the fly)
// the non-ribust Xpaths will work whereas the robust ones will not work
function xpathToString(xpathArray) {
  return xpathArray.reduce((str, elm) => {
    if (elm.id) {
      return `/${elm.str}[@id='${elm.id}']`;
    } else {
      return str + `/${elm.str}` + (elm.count > 0 ? `[${elm.count}]` : '');
    }
  }, '');
}

function getXpath(node) {
  var xpathArray = getXPathArray(node);
  return xpathToString(xpathArray);
}

export default getXpath;
