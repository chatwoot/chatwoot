// https://stackoverflow.com/a/46971044/970769
// "Breaking changes in Typescript 2.1"
// "Extending built-ins like Error, Array, and Map may no longer work."
// "As a recommendation, you can manually adjust the prototype immediately after any super(...) calls."
// https://github.com/Microsoft/TypeScript-wiki/blob/main/Breaking-Changes.md#extending-built-ins-like-error-array-and-map-may-no-longer-work
export default class ParseError extends Error {
  constructor(code) {
    super(code)
    // Set the prototype explicitly.
    // Any subclass of FooError will have to manually set the prototype as well.
    Object.setPrototypeOf(this, ParseError.prototype)
    this.name = this.constructor.name
  }
}