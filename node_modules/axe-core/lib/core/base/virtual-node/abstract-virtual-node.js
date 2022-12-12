const whitespaceRegex = /[\t\r\n\f]/g;

class AbstractVirtualNode {
  constructor() {
    this.parent = undefined;
  }

  get props() {
    throw new Error(
      'VirtualNode class must have a "props" object consisting ' +
        'of "nodeType" and "nodeName" properties'
    );
  }

  get attrNames() {
    throw new Error('VirtualNode class must have an "attrNames" property');
  }

  attr() {
    throw new Error('VirtualNode class must have an "attr" function');
  }

  hasAttr() {
    throw new Error('VirtualNode class must have a "hasAttr" function');
  }

  hasClass(className) {
    // get the value of the class attribute as svgs return a SVGAnimatedString
    // if you access the className property
    const classAttr = this.attr('class');
    if (!classAttr) {
      return false;
    }

    const selector = ' ' + className + ' ';
    return (
      (' ' + classAttr + ' ').replace(whitespaceRegex, ' ').indexOf(selector) >=
      0
    );
  }
}

export default AbstractVirtualNode;
