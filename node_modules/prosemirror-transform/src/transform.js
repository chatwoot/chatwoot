import {Mapping} from "./map"

export function TransformError(message) {
  let err = Error.call(this, message)
  err.__proto__ = TransformError.prototype
  return err
}

TransformError.prototype = Object.create(Error.prototype)
TransformError.prototype.constructor = TransformError
TransformError.prototype.name = "TransformError"

// ::- Abstraction to build up and track an array of
// [steps](#transform.Step) representing a document transformation.
//
// Most transforming methods return the `Transform` object itself, so
// that they can be chained.
export class Transform {
  // :: (Node)
  // Create a transform that starts with the given document.
  constructor(doc) {
    // :: Node
    // The current document (the result of applying the steps in the
    // transform).
    this.doc = doc
    // :: [Step]
    // The steps in this transform.
    this.steps = []
    // :: [Node]
    // The documents before each of the steps.
    this.docs = []
    // :: Mapping
    // A mapping with the maps for each of the steps in this transform.
    this.mapping = new Mapping
  }

  // :: Node The starting document.
  get before() { return this.docs.length ? this.docs[0] : this.doc }

  // :: (step: Step) → this
  // Apply a new step in this transform, saving the result. Throws an
  // error when the step fails.
  step(object) {
    let result = this.maybeStep(object)
    if (result.failed) throw new TransformError(result.failed)
    return this
  }

  // :: (Step) → StepResult
  // Try to apply a step in this transformation, ignoring it if it
  // fails. Returns the step result.
  maybeStep(step) {
    let result = step.apply(this.doc)
    if (!result.failed) this.addStep(step, result.doc)
    return result
  }

  // :: bool
  // True when the document has been changed (when there are any
  // steps).
  get docChanged() {
    return this.steps.length > 0
  }

  addStep(step, doc) {
    this.docs.push(this.doc)
    this.steps.push(step)
    this.mapping.appendMap(step.getMap())
    this.doc = doc
  }
}
