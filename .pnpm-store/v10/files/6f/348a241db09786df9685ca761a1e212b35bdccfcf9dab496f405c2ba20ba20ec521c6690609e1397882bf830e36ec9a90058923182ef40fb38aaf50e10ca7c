This module exports list-related schema elements and commands. The
commands assume lists to be nestable, with the restriction that the
first child of a list item is a plain paragraph.

These are the node specs:

@orderedList
@bulletList
@listItem

@addListNodes

Using this would look something like this:

```javascript
const mySchema = new Schema({
  nodes: addListNodes(baseSchema.spec.nodes, "paragraph block*", "block"),
  marks: baseSchema.spec.marks
})
```

The following functions are [commands](/docs/guide/#commands):

@wrapInList
@splitListItem
@splitListItemKeepMarks
@liftListItem
@sinkListItem
