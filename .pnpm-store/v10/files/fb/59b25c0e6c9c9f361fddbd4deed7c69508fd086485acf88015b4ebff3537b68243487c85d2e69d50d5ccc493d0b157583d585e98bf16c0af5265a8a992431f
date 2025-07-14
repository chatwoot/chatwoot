import {Fragment, Slice, Node, Schema} from "prosemirror-model"
import {Step, StepResult} from "./step"
import {StepMap, Mappable} from "./map"

/// Update an attribute in a specific node.
export class AttrStep extends Step {
  /// Construct an attribute step.
  constructor(
    /// The position of the target node.
    readonly pos: number,
    /// The attribute to set.
    readonly attr: string,
    // The attribute's new value.
    readonly value: any
  ) {
    super()
  }

  apply(doc: Node) {
    let node = doc.nodeAt(this.pos)
    if (!node) return StepResult.fail("No node at attribute step's position")
    let attrs = Object.create(null)
    for (let name in node.attrs) attrs[name] = node.attrs[name]
    attrs[this.attr] = this.value
    let updated = node.type.create(attrs, null, node.marks)
    return StepResult.fromReplace(doc, this.pos, this.pos + 1, new Slice(Fragment.from(updated), 0, node.isLeaf ? 0 : 1))
  }

  getMap() {
    return StepMap.empty
  }

  invert(doc: Node) {
    return new AttrStep(this.pos, this.attr, doc.nodeAt(this.pos)!.attrs[this.attr])
  }

  map(mapping: Mappable) {
    let pos = mapping.mapResult(this.pos, 1)
    return pos.deletedAfter ? null : new AttrStep(pos.pos, this.attr, this.value)
  }

  toJSON(): any {
    return {stepType: "attr", pos: this.pos, attr: this.attr, value: this.value}
  }

  static fromJSON(schema: Schema, json: any) {
    if (typeof json.pos != "number" || typeof json.attr != "string")
      throw new RangeError("Invalid input for AttrStep.fromJSON")
    return new AttrStep(json.pos, json.attr, json.value)
  }
}

Step.jsonID("attr", AttrStep)

/// Update an attribute in the doc node.
export class DocAttrStep extends Step {
  /// Construct an attribute step.
  constructor(
    /// The attribute to set.
    readonly attr: string,
    // The attribute's new value.
    readonly value: any
  ) {
    super()
  }

  apply(doc: Node) {
    let attrs = Object.create(null)
    for (let name in doc.attrs) attrs[name] = doc.attrs[name]
    attrs[this.attr] = this.value
    let updated = doc.type.create(attrs, doc.content, doc.marks)
    return StepResult.ok(updated)
  }

  getMap() {
    return StepMap.empty
  }

  invert(doc: Node) {
    return new DocAttrStep(this.attr, doc.attrs[this.attr])
  }

  map(mapping: Mappable) {
    return this
  }

  toJSON(): any {
    return {stepType: "docAttr", attr: this.attr, value: this.value}
  }

  static fromJSON(schema: Schema, json: any) {
    if (typeof json.attr != "string")
      throw new RangeError("Invalid input for DocAttrStep.fromJSON")
    return new DocAttrStep(json.attr, json.value)
  }
}

Step.jsonID("docAttr", DocAttrStep)