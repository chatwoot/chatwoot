This module exports a number of _commands_, which are building block
functions that encapsulate an editing action. A command function takes
an editor state, _optionally_ a `dispatch` function that it can use
to dispatch a transaction and _optionally_ an `EditorView` instance.
It should return a boolean that indicates whether it could perform any
action. When no `dispatch` callback is passed, the command should do a 
'dry run', determining whether it is applicable, but not actually doing
anything.

These are mostly used to bind keys and define menu items.

@chainCommands
@deleteSelection
@joinBackward
@selectNodeBackward
@joinForward
@selectNodeForward
@joinUp
@joinDown
@lift
@newlineInCode
@exitCode
@createParagraphNear
@liftEmptyBlock
@splitBlock
@splitBlockKeepMarks
@selectParentNode
@selectAll
@wrapIn
@setBlockType
@toggleMark
@autoJoin
@baseKeymap
@pcBaseKeymap
@macBaseKeymap
