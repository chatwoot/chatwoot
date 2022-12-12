'use strict';

function cssBlankPseudo(document, opts) {
  // configuration
  const className = Object(opts).className;
  const attr = Object(opts).attr || 'blank';
  const force = Object(opts).force;

  try {
    document.querySelector(':blank');

    if (!force) {
      return;
    }
  } catch (ignoredError) {}
  /* do nothing and continue */
  // observe value changes on <input>, <select>, and <textarea>


  const window = (document.ownerDocument || document).defaultView;
  observeValueOfHTMLElement(window.HTMLInputElement);
  observeValueOfHTMLElement(window.HTMLSelectElement);
  observeValueOfHTMLElement(window.HTMLTextAreaElement);
  observeSelectedOfHTMLElement(window.HTMLOptionElement); // form control elements selector

  const selector = 'INPUT,SELECT,TEXTAREA';
  const selectorRegExp = /^(INPUT|SELECT|TEXTAREA)$/; // conditionally update all form control elements

  Array.prototype.forEach.call(document.querySelectorAll(selector), node => {
    if (node.nodeName === 'SELECT') {
      node.addEventListener('change', configureCssBlankAttribute);
    } else {
      node.addEventListener('input', configureCssBlankAttribute);
    }

    configureCssBlankAttribute.call(node);
  }); // conditionally observe added or unobserve removed form control elements

  new MutationObserver(mutationsList => {
    mutationsList.forEach(mutation => {
      Array.prototype.forEach.call(mutation.addedNodes || [], node => {
        if (node.nodeType === 1 && selectorRegExp.test(node.nodeName)) {
          if (node.nodeName === 'SELECT') {
            node.addEventListener('change', configureCssBlankAttribute);
          } else {
            node.addEventListener('input', configureCssBlankAttribute);
          }

          configureCssBlankAttribute.call(node);
        }
      });
      Array.prototype.forEach.call(mutation.removedNodes || [], node => {
        if (node.nodeType === 1 && selectorRegExp.test(node.nodeName)) {
          if (node.nodeName === 'SELECT') {
            node.removeEventListener('change', configureCssBlankAttribute);
          } else {
            node.removeEventListener('input', configureCssBlankAttribute);
          }
        }
      });
    });
  }).observe(document, {
    childList: true,
    subtree: true
  }); // update a form control element’s css-blank attribute

  function configureCssBlankAttribute() {
    if (this.value || this.nodeName === 'SELECT' && this.options[this.selectedIndex].value) {
      if (attr) {
        this.removeAttribute(attr);
      }

      if (className) {
        this.classList.remove(className);
      }

      this.removeAttribute('blank');
    } else {
      if (attr) {
        this.setAttribute('blank', attr);
      }

      if (className) {
        this.classList.add(className);
      }
    }
  } // observe changes to the "value" property on an HTML Element


  function observeValueOfHTMLElement(HTMLElement) {
    const descriptor = Object.getOwnPropertyDescriptor(HTMLElement.prototype, 'value');
    const nativeSet = descriptor.set;

    descriptor.set = function set(value) {
      // eslint-disable-line no-unused-vars
      nativeSet.apply(this, arguments);
      configureCssBlankAttribute.apply(this);
    };

    Object.defineProperty(HTMLElement.prototype, 'value', descriptor);
  } // observe changes to the "selected" property on an HTML Element


  function observeSelectedOfHTMLElement(HTMLElement) {
    const descriptor = Object.getOwnPropertyDescriptor(HTMLElement.prototype, 'selected');
    const nativeSet = descriptor.set;

    descriptor.set = function set(value) {
      // eslint-disable-line no-unused-vars
      nativeSet.apply(this, arguments);
      const event = document.createEvent('Event');
      event.initEvent('change', true, true);
      this.dispatchEvent(event);
    };

    Object.defineProperty(HTMLElement.prototype, 'selected', descriptor);
  }
}

module.exports = cssBlankPseudo;
//# sourceMappingURL=legacy.js.map
