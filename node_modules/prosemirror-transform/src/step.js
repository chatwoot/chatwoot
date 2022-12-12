import {ReplaceError} from "prosemirror-model"

import {StepMap} from "./map"

function mustOverride() { throw new Error("Override me") }

const stepsByID = Object.create(null)

// ::- A step object represents an atomic change. It generally applies
// only to the document it was created for, since the positions
// stored in it will only make sense for that document.
//
// New steps are defined by creating classes that extend `Step`,
// overriding the `apply`, `invert`, `map`, `getMap` and `fromJSON`
// methods, and registering your class with a unique
// JSON-serialization identifier using
// [`Step.jsonID`](#transform.Step^jsonID).
export class Step {
  // :: (doc: Node) → StepResult
  // Applies this step to the given document, returning a result
  // object that either indicates failure, if the step can not be
  // applied to this document, or indicates success by containing a
  // transformed document.
  apply(_doc) { return mustOverride() }

  // :: () → StepMap
  // Get the step map that represents the changes made by this step,
  // and which can be used to transform between positions in the old
  // and the new document.
  getMap() { return StepMap.empty }

  // :: (doc: Node) → Step
  // Create an inverted version of this step. Needs the document as it
  // was before the step as argument.
  invert(_doc) { return mustOverride() }

  // :: (mapping: Mappable) → ?Step
  // Map this step through a mappable thing, returning either a
  // version of that step with its positions adjusted, or `null` if
  // the step was entirely deleted by the mapping.
  map(_mapping) { return mustOverride() }

  // :: (other: Step) → ?Step
  // Try to merge this step with another one, to be applied directly
  // after it. Returns the merged step when possible, null if the
  // steps can't be merged.
  merge(_other) { return null }

  // :: () → Object
  // Create a JSON-serializeable representation of this step. When
  // defining this for a custom subclass, make sure the result object
  // includes the step type's [JSON id](#transform.Step^jsonID) under
  // the `stepType` property.
  toJSON() { return mustOverride() }

  // :: (Schema, Object) → Step
  // Deserialize a step from its JSON representation. Will call
  // through to the step class' own implementation of this method.
  static fromJSON(schema, json) {
    if (!json || !json.stepType) throw new RangeError("Invalid input for Step.fromJSON")
    let type = stepsByID[json.stepType]
    if (!type) throw new RangeError(`No step type ${json.stepType} defined`)
    return type.fromJSON(schema, json)
  }

  // :: (string, constructor<Step>)
  // To be able to serialize steps to JSON, each step needs a string
  // ID to attach to its JSON representation. Use this method to
  // register an ID for your step classes. Try to pick something
  // that's unlikely to clash with steps from other modules.
  static jsonID(id, stepClass) {
    if (id in stepsByID) throw new RangeError("Duplicate use of step JSON ID " + id)
    stepsByID[id] = stepClass
    stepClass.prototype.jsonID = id
    return stepClass
  }
}

// ::- The result of [applying](#transform.Step.apply) a step. Contains either a
// new document or a failure value.
export class StepResult {
  // : (?Node, ?string)
  constructor(doc, failed) {
    // :: ?Node The transformed document.
    this.doc = doc
    // :: ?string Text providing information about a failed step.
    this.failed = failed
  }

  // :: (Node) → StepResult
  // Create a successful step result.
  static ok(doc) { return new StepResult(doc, null) }

  // :: (string) → StepResult
  // Create a failed step result.
  static fail(message) { return new StepResult(null, message) }

  // :: (Node, number, number, Slice) → StepResult
  // Call [`Node.replace`](#model.Node.replace) with the given
  // arguments. Create a successful result if it succeeds, and a
  // failed one if it throws a `ReplaceError`.
  static fromReplace(doc, from, to, slice) {
    try {
      return StepResult.ok(doc.replace(from, to, slice))
    } catch (e) {
      if (e instanceof ReplaceError) return StepResult.fail(e.message)
      throw e
    }
  }
}
