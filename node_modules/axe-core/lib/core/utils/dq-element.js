import getSelector from './get-selector';
import getAncestry from './get-ancestry';
import getXpath from './get-xpath';

function truncate(str, maxLength) {
  maxLength = maxLength || 300;

  if (str.length > maxLength) {
    var index = str.indexOf('>');
    str = str.substring(0, index + 1);
  }

  return str;
}

function getSource(element) {
  var source = element.outerHTML;
  if (!source && typeof XMLSerializer === 'function') {
    source = new XMLSerializer().serializeToString(element);
  }
  return truncate(source || '');
}

/**
 * "Serialized" `HTMLElement`. It will calculate the CSS selector,
 * grab the source (outerHTML) and offer an array for storing frame paths
 * @param {HTMLElement} element The element to serialize
 * @param {Object} spec Properties to use in place of the element when instantiated on Elements from other frames
 */
function DqElement(element, options, spec) {
  this._fromFrame = !!spec;

  this.spec = spec || {};
  if (options && options.absolutePaths) {
    this._options = { toRoot: true };
  }

  /**
   * The generated HTML source code of the element
   * @type {String}
   */
  // TODO: es-modules_audit
  if (axe._audit.noHtml) {
    this.source = null;
  } else if (this.spec.source !== undefined) {
    this.source = this.spec.source;
  } else {
    this.source = getSource(element);
  }

  /**
   * The element which this object is based off or the containing frame, used for sorting.
   * Excluded in toJSON method.
   * @type {HTMLElement}
   */
  this._element = element;
}

DqElement.prototype = {
  /**
   * A unique CSS selector for the element, designed for readability
   * @return {String}
   */
  get selector() {
    return this.spec.selector || [getSelector(this.element, this._options)];
  },

  /**
   * A unique CSS selector for the element, including its ancestors down to the root node
   * @return {String}
   */
  get ancestry() {
    return this.spec.ancestry || [getAncestry(this.element)];
  },

  /**
   * Xpath to the element
   * @return {String}
   */
  get xpath() {
    return this.spec.xpath || [getXpath(this.element)];
  },

  /**
   * Direct reference to the `HTMLElement` wrapped by this `DQElement`.
   */
  get element() {
    return this._element;
  },

  get fromFrame() {
    return this._fromFrame;
  },

  toJSON() {
    return {
      selector: this.selector,
      source: this.source,
      xpath: this.xpath,
      ancestry: this.ancestry
    };
  }
};

DqElement.fromFrame = function fromFrame(node, options, frame) {
  const spec = {
    ...node,
    selector: [...frame.selector, ...node.selector],
    ancestry: [...frame.ancestry, ...node.ancestry],
    xpath: [...frame.xpath, ...node.xpath]
  };
  return new DqElement(frame.element, options, spec);
};

export default DqElement;
