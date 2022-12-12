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
  observeValueOfHTMLElement(window.HTMLTextAreaElement); // form control elements selector

  const selector = 'input,select,textarea'; // conditionally update all form control elements

  Array.prototype.forEach.call(document.querySelectorAll(selector), node => {
    node.addEventListener('input', configureCssBlankAttribute);
    configureCssBlankAttribute.call(node);
  }); // conditionally observe added or unobserve removed form control elements

  new MutationObserver(mutationsList => {
    mutationsList.forEach(mutation => {
      if (mutation.addedNodes) {
        mutation.addedNodes.forEach(node => {
          if (node.nodeType === 1 && node.matches(selector)) {
            node.addEventListener('input', configureCssBlankAttribute);
            configureCssBlankAttribute.call(node);
          }
        });
      }

      if (mutation.removedNodes) {
        mutation.removedNodes.forEach(node => {
          if (node.nodeType === 1 && node.matches(selector)) {
            node.removeEventListener('input', configureCssBlankAttribute);
          }
        });
      }
    });
  }).observe(document, {
    childList: true,
    subtree: true
  }); // update a form control element’s css-blank attribute

  function configureCssBlankAttribute() {
    if (this.value) {
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
  }
}

export default cssBlankPseudo;
//# sourceMappingURL=index.mjs.map
