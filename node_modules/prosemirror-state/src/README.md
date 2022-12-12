This module implements the state object of a ProseMirror editor, along
with the representation of the selection and the plugin abstraction.

### Editor State

ProseMirror keeps all editor state (the things, basically, that would
be required to create an editor just like the current one) in a single
[object](#state.EditorState). That object is updated (creating a new
state) by applying [transactions](#state.Transaction) to it.

@EditorState
@Transaction

### Selection

A ProseMirror selection can be one of several types. This module
defines types for classical [text selections](#state.TextSelection)
(of which cursors are a special case) and [_node_
selections](#state.NodeSelection), where a specific document node is
selected. It is possible to extend the editor with custom selection
types.

@Selection
@TextSelection
@NodeSelection
@AllSelection

@SelectionRange
@SelectionBookmark

### Plugin System

To make it easy to package and enable extra editor functionality,
ProseMirror has a plugin system.

@PluginSpec
@StateField
@Plugin
@PluginKey
