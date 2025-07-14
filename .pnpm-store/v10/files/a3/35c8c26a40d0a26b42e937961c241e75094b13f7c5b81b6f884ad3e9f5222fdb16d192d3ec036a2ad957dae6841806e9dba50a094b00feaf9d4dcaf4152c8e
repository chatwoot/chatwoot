"use strict";

class ElementInternalsImpl {
  constructor(globalObject, args, { targetElement }) {
    this._targetElement = targetElement;
  }

  get shadowRoot() {
    const shadow = this._targetElement._shadowRoot;

    if (!shadow || !shadow._availableToElementInternals) {
      return null;
    }

    return shadow;
  }

  // https://html.spec.whatwg.org/#reflecting-content-attributes-in-idl-attributes
  _reflectGetTheElement() {
    return this._targetElement;
  }

  _reflectGetTheContentAttribute(reflectedContentAttributeName) {
    return this._targetElement._internalContentAttributeMap.get(reflectedContentAttributeName) ?? null;
  }

  _reflectSetTheContentAttribute(reflectedContentAttributeName, value) {
    this._targetElement._internalContentAttributeMap.set(reflectedContentAttributeName, value);
  }

  _reflectDeleteTheContentAttribute(reflectedContentAttributeName) {
    this._targetElement._internalContentAttributeMap.delete(reflectedContentAttributeName);
  }
}

module.exports = {
  implementation: ElementInternalsImpl
};
