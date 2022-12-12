This module defines a way of modifying documents that allows changes
to be recorded, replayed, and reordered. You can read more about
transformations in [the guide](/docs/guide/#transform).

### Steps

Transforming happens in `Step`s, which are atomic, well-defined
modifications to a document. [Applying](#transform.Step.apply) a step
produces a new document.

Each step provides a [change map](#transform.StepMap) that maps
positions in the old document to position in the transformed document.
Steps can be [inverted](#transform.Step.invert) to create a step that
undoes their effect, and chained together in a convenience object
called a [`Transform`](#transform.Transform).

@Step
@StepResult
@ReplaceStep
@ReplaceAroundStep
@AddMarkStep
@RemoveMarkStep

### Position Mapping

Mapping positions from one document to another by running through the
[step maps](#transform.StepMap) produced by steps is an important
operation in ProseMirror. It is used, for example, for updating the
selection when the document changes.

@Mappable
@MapResult
@StepMap
@Mapping

### Document transforms

Because you often need to collect a number of steps together to effect
a composite change, ProseMirror provides an abstraction to make this
easy. [State transactions](#state.Transaction) are a subclass of
transforms.

@Transform

The following helper functions can be useful when creating
transformations or determining whether they are even possible.

@replaceStep
@liftTarget
@findWrapping
@canSplit
@canJoin
@joinPoint
@insertPoint
@dropPoint
