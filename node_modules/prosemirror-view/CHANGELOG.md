## 1.18.4 (2021-04-27)

### Bug fixes

Fix incorrect drag cursor in Chrome on some platforms.

Fix an issue where a race condition could leave a node uneditable when clicked.

Fix scroll handling when the editor is placed through a DOM component slot.

Fix a typo in the Chrome backspace workaround.

Fixes an issue where, when mouseup events weren't being delivered, the editor could leak event handlers.

## 1.18.3 (2021-04-13)

### Bug fixes

Fix an issue where, when pressing enter or space at the start of a composition, the cursor would jump to the end of the composition on Chrome Android.

Fix an issue that would cause Enter presses to be dropped on Android when in a node whose DOM representation nested more than one element.

Fix a bug where pasting specific types of HTML could cause a crash.

## 1.18.2 (2021-03-25)

### Bug fixes

Properly handle CSS class name strings with extra spaces in decorations.

Fix a performance bug when updating nodes with thousands of children.

## 1.18.1 (2021-03-15)

### Bug fixes

Fix the scrolling-into-view logic in the case where a scale transformation is applied to the editor. Strip carriage return chars from text pasted as code

Remove carriage return characters when pasting text into code blocks.

## 1.18.0 (2021-03-04)

### Bug fixes

Fix a crash in `posAtDOM`.

### New features

Node view constructors and `update` methods are now passed the inner decorations of the node.

## 1.17.8 (2021-02-26)

### Bug fixes

Fix an issue where some user actions (such as enter on iOS) in a node whose content DOM element isn't it's top element could leave the DOM in a damaged state.

## 1.17.7 (2021-02-22)

### Bug fixes

Fix an issue where the `ProseMirror-hideselection` element class would be briefly removed and then restored when moving from one invisible selection to another.

Fix an issue where the cursor could end up on the wrong side of a widget with `side` < 0.

## 1.17.6 (2021-02-11)

### Bug fixes

Fix an issue where using the vertical arrow keys after select-all didn't update the selection.

## 1.17.5 (2021-02-05)

### Bug fixes

Fix an issue where the view could go into an endless DOM flush loop in specific circumstances involving asynchronous DOM mutation.

## 1.17.4 (2021-02-04)

### Bug fixes

Add another kludge to work around an issue where Firefox displays the cursor in the wrong place in code blocks.

Fix a bug where validation of decorations passed to `DecorationSet.add` sometimes passed the wrong offsets to the validator.

Fix bad selection position in empty textblocks. Solves several issues with editing in Firefox Android.

## 1.17.3 (2021-01-29)

### Bug fixes

Fix a bug where adding invalid decorations (for example zero-length inline decorations) with `DecorationSet.add` would fail to drop those.

## 1.17.2 (2021-01-12)

### Bug fixes

The library will now always let the browser perform its native pasting behavior when the clipboard data is empty and no paste handler handles the event.

Fix a bug where `domAtPos` (and thus cursor placement) would pick positions inside uneditable DOM or atom nodes.

## 1.17.1 (2021-01-08)

### Bug fixes

Fix a regression in `coordsAtPos` when used on an empty line at the end of a code block.

## 1.17.0 (2021-01-07)

### Bug fixes

Fix an issue where starting a composition with stored marks would sometimes create the wrong steps (and thus break the mark) on Chrome.

### New features

`EditorView.domAtPos` now takes a second parameter that can be used to control whether it should enter DOM nodes on the side of the given position.

## 1.16.5 (2020-12-11)

### Bug fixes

Fix platform detection on recent iPadOS versions, restoring several workarounds for bugs that were accidentally turned off there.

## 1.16.4 (2020-12-02)

### Bug fixes

Fix an issue where the cursor ended up in the wrong place when pressing enter in an empty heading on iOS.

## 1.16.3 (2020-11-23)

### Bug fixes

Fix an issue where pressing enter at the start of a line in a code block would leave the visible cursor in the wrong place on Firefox.

## 1.16.2 (2020-11-18)

### Bug fixes

Fix a bug where overlapping inline decorations would get drawn incorrectly (and even corrupt the drawing of unrelated content).

## 1.16.1 (2020-10-26)

### Bug fixes

Fix an issue where the attributes of defining nodes were dropped when copying to the clipboard.

## 1.16.0 (2020-10-01)

### Bug fixes

Fix an issue where a drag starting briefly after an aborted drag could confuse the view and break the second drag. Allow callers of coordsAtPos to specify a side

### New features

`EditorView.coordsAtPos` now takes a `side` argument that determines which side of the position to look, if ambiguous.

## 1.15.7 (2020-09-11)

### Bug fixes

Fix an issue where, when inserting `<br>` nodes, Safari would briefly show the cursor before the inserted break, though the DOM selection had already been set after it.

When dragging inside the editor, whether the operation copies or moves is now determined by the modifiers held on drop, not on drag start.

## 1.15.6 (2020-09-03)

### Bug fixes

Fix issue where the DOM selection could end up in an invalid state after a keyboard cursor motion event that had no effect.

Fix an issue where some types of drop events would fail to select the dropped content.

Work around Safari issues when pressing shift-down with the cursor before an uneditable element.

## 1.15.5 (2020-08-25)

### Bug fixes

Fix an issue where mapping a decoration set could corrupt the decoration positions in specific cases.

## 1.15.4 (2020-08-13)

### Bug fixes

Fix a crash that occurred when inline decorations covered inline nodes that weren't leaf nodes.

## 1.15.3 (2020-08-11)

### Bug fixes

Work around a Firefox issue where the cursor is sometimes shown in the wrong place when directly after a `<br>` node.

The editor will now reset composition when stored marks are set on the state, so that the marks can be added to the next input.

Inline decorations are no longer applied to inline nodes that aren't leaves, only to the innermost layer.

## 1.15.2 (2020-07-09)

### Bug fixes

Adjust the workaround for Chrome's DOM selection corruption bug to cover more cases.

## 1.15.1 (2020-07-09)

### Bug fixes

Work around another issue where Chrome misreports the DOM selection.

## 1.15.0 (2020-06-24)

### Bug fixes

Fix an issue where Enter on iOS might be handled twice on slow devices. Pass plain text flag to transformPastedText and clipboardTextParser props

Fix a bug where typing in front of a mark could in some circumstances cause the editor to discard the new content.

### New features

The `transformPastedText` and `clipboardTextParser` props now receive an extra argument, `plain`, indicating whether the paste was forced as plain text.

## 1.14.13 (2020-06-05)

### Bug fixes

Fix a bug where storing DOM nodes directly in widget decorations (not recommended) could cause the view to try and place the same DOM node multiple times.

## 1.14.12 (2020-06-03)

### Bug fixes

Fix a crash when the editor tries to read a DOM selection outside of itself.

Improve the way inline decorations covering non-leaf inline nodes are rendered. Ensure elt is defined before accessing it in posAtCoords

Fix a crash in Safari when the browser's `elementFromPoint` returns null in `posAtCoords`. Handle case where Chrome flips the nesting order of edited inline nodes

Fix the issue of `<a>` marks on decorated text being lost during editing because Chrome changes the nesting order of the link and the decoration `<span>` element in the DOM.

Fix an issue where, when pressing enter with a bolded virtual keyboard suggestion on Android's Gboard, the cursor would stay on the wrong line.

## 1.14.11 (2020-05-19)

### Bug fixes

Fix bug in the way the editor handles Cmd-arrow presses on macOS.

## 1.14.10 (2020-05-18)

### Bug fixes

Fix an issue where the editor would override behavior for Cmd-arrow key presses on macOS the wrong way in some situations.

Fix handling of copy and paste in IE when top-level elements can't be focused.

## 1.14.9 (2020-05-06)

### Bug fixes

Fix a crash on IE, which sets `document.activeElement` to null in some circumstances.

## 1.14.8 (2020-05-01)

### Bug fixes

Work around an issue in Safari where you couldn't click inside a selected element to put the cursor there.

Fix enter at start of paragraph in iOS inserting two new paragraphs.

Scrolling the cursor into view now makes sure it doesn't end up below a scrollbar.

## 1.14.7 (2020-04-20)

### Bug fixes

Fix a crash on Chrome during selection updates when `Selection.collapse` inexplicably leaves the selection empty. Update documented type for handlePaste event arg

Fix another issue that could break decoration set mapping in deeply nested nodes.

## 1.14.6 (2020-03-25)

### Bug fixes

Fix superfluous cursor showing up in Chrome when there is a gap cursor or similar custom empty selection active.

Fix an issue where `DecorationSet.remove` would ignore the positions of its argument decorations, and only compare by type.

## 1.14.5 (2020-03-23)

### Bug fixes

Work around Chrome Android issue where pasting would close the virtual keyboard.

Fix an issue where some kinds of changes would cause nodes to show up twice in the DOM.

## 1.14.4 (2020-03-17)

### Bug fixes

Improve return values from `coordsAtPos` on line breaks in Safari and Firefox.

Make sure enter on iOS is handled even when the native behavior has no effect.

## 1.14.3 (2020-03-16)

### Bug fixes

Fix mismatch between DOM and state selection bug at compositionend in IE11.

Make sure `handleDrop`](https://prosemirror.net/docs/ref/#view.EditorProps.handleDrop) is called even when there's nothing on the clipboard.

Fix a bug where reconfiguring a view in a way that changed both the active node views and the attributes of the top node left the old attributes active.

Work around another case where Chrome lies to the script about its current DOM selection state.

Avoid redrawing nodes when both their content and a widget in front of them is updated in the same transaction.

Fix issue where scrolling with multiple scrollable containers sometimes moves to the wrong position.

## 1.14.2 (2020-02-10)

### Bug fixes

Fix bug when starting a composition after a link, when the composition started with the character that ended the link.

## 1.14.1 (2020-02-08)

### Bug fixes

Fix issue where scrolling the cursor into view in a scrollable editor would sometimes inappropriately scroll an outer container as well.

## 1.14.0 (2020-02-07)

### Bug fixes

Fix parsing of `tbody`, `tfoot`, and `caption` elements in pasted HTML content. Fix bug in selection-is-at-edge check

Fix an issue where moving focus to the editor with the keyboard or the DOM `focus` method would leave the DOM and state selections inconsistent.

### New features

Widget decorations can now take an `ignoreSelection` option, that causes the editor to leave selections inside them alone.

## 1.13.11 (2020-01-31)

### Bug fixes

Fix an issue that could lead to the editor making regular content uneditable on Safari.

## 1.13.10 (2020-01-29)

### Bug fixes

Fix a crash on Firefox when starting a composition after a marked non-text node.

## 1.13.9 (2020-01-29)

### Bug fixes

Make sure to reset the selection when the browser moves it into an uneditable node.

Fix issue where the editor would fail to create a meaningful DOM selection for a node selection on Safari.

Makes sure the iOS virtual keyboard gets its internal state (autocorrection, autocapitalization) updated when the user presses enter.

## 1.13.8 (2020-01-24)

### Bug fixes

Fix bug that would sometimes cause widget decorations to be drawn with marks from the node after the text node they were inside of.

## 1.13.7 (2019-12-16)

### Bug fixes

Fix a bug that caused the DOM to go out of sync with the decorations when updating inline decorations that added multiple wrapping nodes to a piece of content.

## 1.13.6 (2019-12-13)

### Bug fixes

Fix a crash when deleting a list item in Safari while using a parse rule with a `context` property for `<li>` elements.

Work around another case where Chrome reports an incorrect selection.

Work around issue where Firefox will insert a stray BR node when deleting a text node in some types of DOM structure.

## 1.13.5 (2019-12-09)

### Bug fixes

Fix the way decorations update node styles to allow removing CSS custom properties. Link to https in readme and changelog

The `root` accessor on views now makes sure that, when it returns a shadow root, that object has a `getSelection` method.

Fix an issue where the DOM selection could get out of sync with ProseMirror's selection state in Edge.

## 1.13.4 (2019-11-20)

### Bug fixes

Rename ES module files to use a .js extension, since Webpack gets confused by .mjs

## 1.13.3 (2019-11-19)

### Bug fixes

Fix issue where the editor wouldn't update its internal selection when the editor was blurred, its selection was changed programatically, and then the editor was re-focused with its old DOM selection.

The file referred to in the package's `module` field now is compiled down to ES5.

## 1.13.2 (2019-11-14)

### Bug fixes

Fix issue where `EditorView.focus` would scroll the top of the document into view on Safari.

## 1.13.1 (2019-11-12)

### Bug fixes

Work around selection jumping that sometimes occurs on Chrome when focusing the editor.

## 1.13.0 (2019-11-08)

### New features

Add a `module` field to package json file.

## 1.12.3 (2019-11-07)

### Bug fixes

Fix issue where paste events were stopped when the clipboard parser failed to make sense of the content.

Fix issue where the `handlePaste` prop might be called multiple times for a single paste.

## 1.12.2 (2019-11-05)

### Bug fixes

Set the editable element to use a `white-space: break-spaces` style so that whitespace at the end of a line properly moves the cursor to the next line.

Fix issue where `posAtCoords` could throw an error in some circumstances on Firefox.

Don't force focus back on the editor if a node view moves focus in its `setSelection` method.

## 1.12.1 (2019-10-28)

### Bug fixes

Reduce unnecessary redraws when typing creates a new text node on Chrome.

The default prosemirror.css now also turns off ligatures in Edge.

Fix issue where the cursor stays before the typed text in Edge, when typing in an empty paragraph or between hard break nodes.

## 1.12.0 (2019-10-21)

### New features

The mutation records passed to [`ignoreMutation`](https://prosemirror.net/docs/ref/#view.NodeView.ignoreMutation) now contain the old attribute value.

## 1.11.7 (2019-10-15)

### Bug fixes

Enabling a mark and then starting a composition, on Chrome Android, will no longer cause the cursor to jump to the start of the composition.

## 1.11.6 (2019-10-07)

### Bug fixes

Fix workaround for broken IE11 DOM change records when inserting between `<br>` nodes to handle more cases.

## 1.11.5 (2019-10-04)

### Bug fixes

Don't leave DOM selection in place when it is inside a node view but not inside its content DOM element.

## 1.11.4 (2019-09-27)

### Bug fixes

Fix an IE11 issue where marks would sometimes unexpectedly get dropped when inserting a space after marked text.

Fixes an issue where `handleTextInput` wasn't called when typing over a single character with the same character.

## 1.11.3 (2019-09-20)

### Bug fixes

Fix an issue where the DOM node representing a mark could be corrupted when the browser decides to replace it with another node but ProseMirror restored the old node after the change.

Handle another case where typing over a selection in IE11 confused the editor.

## 1.11.2 (2019-09-17)

### Bug fixes

Fix an issue where typing over a decorated piece of text would sometimes just act like deletion.

Fix another problem in IE11 with typing over content, where typing over a decorated bit of text caused a crash.

## 1.11.1 (2019-09-16)

### Bug fixes

Fix issue where typing over the entire contents of an inline node on IE11 would insert the typed content in the wrong position.

## 1.11.0 (2019-09-16)

### Bug fixes

Fix an issue where IE11 would select the entire textblock after deleting content at its start.

### New features

View instances now have a public `editable` property that indicates whether they are in editable mode.

## 1.10.3 (2019-09-04)

### Bug fixes

Fix a regression in 1.10.2 that broke copying on IE11.

## 1.10.2 (2019-09-03)

### Bug fixes

Fix an issue where `posAtCoords` could crash by dereferencing undefined in some circumstances.

Fix inserting text next to a hard break in IE11.

Fix an issue where typing over a selection would result in two different transactions (once for the deletion, once for the insertion) on IE11.

Selecting the word at the start of the document and typing over it no longer causes the text input to appear at the end of the document in IE11.

## 1.10.1 (2019-08-28)

### Bug fixes

Copying content will no longer create elements in the main document, which prevents images from loading just because they appear in clipboard content.

## 1.10.0 (2019-08-13)

### Bug fixes

Fix an issue that caused the cursor to be scrolled into view when `focus()` was called on IE11.

Fix problem where the cursor cycled through pieces of right-to-left text on Firefox during horizontal motion when the gapcursor plugin was enabled.

Fix spurious mutation events in Firefox causing mark replacement at end of composition. Restore call to dom.focus on view.focus

Fix a bug that could cause node views in front of marked nodes to not be destroyed when deleted, and caused confusion in composition handling in some situations.

Cursor wrappers (a kludge to make sure typed text gets wrapping DOM structure corresponding to the current marks) are now created less eagerly, and in a less invasive way, which resolves a number of problems with composition (especially on Safari) and bidirectional text.

### New features

Node views can now ignore selection change events through their [`ignoreMutation`](https://prosemirror.net/docs/ref/#view.NodeView.ignoreMutation) callback.

## 1.9.13 (2019-07-29)

### Bug fixes

Fix an issue where copying content from a ProseMirror instance into an instance using another schema could, in some circumstances, insert schema-violating content.

Fix comparison of decoration sets, which should solve unneccesary re-renders when updating decorations with an identical but newly allocated set. Don't update DOM selection in uneditable editors when the focus is elsewhere

Fix a bug where the editor would steal focus from child elements when in non-editable mode.

Fix error and corruption in IE11 when backspacing out a single character after a br node.

## 1.9.12 (2019-07-16)

### Bug fixes

Fix a crash `posAtCoords` in Firefox when the coordinates are above a text input field.

## 1.9.11 (2019-07-03)

### Bug fixes

Fix an issue where the DOM change handler would treat the parsed content as the wrong part of the document.

Fix an issue in IE11 where deleting the last character in a textblock causes a crash.

Fix an issue where backspacing out the first character in a textblock would cause IE11 to move the selection to some incorrect position.

## 1.9.10 (2019-06-12)

### Bug fixes

Fix a crash in `coordsAtPos` caused by use of an incorrect variable name.

## 1.9.9 (2019-06-09)

### Bug fixes

Fix arrowing over unselectable inline nodes in Chrome and Safari, which by default introduce an extra needless cursor position before the node.

Fix a bug that caused DOM changes to be ignored when happening directly in front of some types of DOM events (such as focus/blur).

## 1.9.8 (2019-05-29)

### Bug fixes

Fix an issue where moving focus from a node inside of the editor to the editor itself could sometimes lead to a node selection around the inner node rather than the intended selection (on Chrome).

## 1.9.7 (2019-05-28)

### Bug fixes

ProseMirror will no longer try to stabilize the scroll position during updates on browsers that support [scroll anchoring](https://developer.mozilla.org/en-US/docs/Web/CSS/overflow-anchor), since it'd inadvertently cancel the browser's behavior.

Fix an issue in Safari where the editor would interrupt the composition spacebar menu because it incorrectly interpreted the mutation events fired by the browser as representing a replacement of the selection with identical text.

Work around an issue where, on Safari, an IME composition started in an empty textblock would vanish when you press enter.

## 1.9.6 (2019-05-17)

### Bug fixes

Fix bug in composition handling when the composition's parent node has an extra wrapper node around its content.

## 1.9.5 (2019-05-14)

### Bug fixes

Fix regression in handling text editing events on IE11.

## 1.9.4 (2019-05-13)

### Bug fixes

Fix a regression where all plugin views were recreated when calling [`setProps`](https://prosemirror.net/docs/ref/#view.EditorView.setProps).

## 1.9.3 (2019-05-10)

### Bug fixes

Fix a bug where, if the document was changed at exactly the right moment, `handleClickOn` could be called with `null` as the node.

## 1.9.2 (2019-05-08)

### Bug fixes

Fix a bug where updating to a reconfigured state would not recreate the view's plugin views.

## 1.9.1 (2019-05-04)

### Bug fixes

Fix a regression where mouse selection would sometimes raise an error.

## 1.9.0 (2019-05-03)

### New features

Changes made during compositions now immediately fire transactions on each update, rather than only a single one at the end of the composition.

The view now immediately shows changes to the document or decorations during composition, even if they come from transactions not directly generated by the use's editing. The only exception is decorations that affect the focused text node—those are still delayed to avoid unneccesarily canceling the composition.

## 1.8.9 (2019-04-18)

### Bug fixes

Improve display update times for nodes with thousands of children by fix an accidental piece of quadratic complexity.

Fixes an issue where changes to the [`nodeViews` prop](https://prosemirror.net/docs/ref/#view.EditorProps.nodeViews) weren't noticed when using [`updateState`](https://prosemirror.net/docs/ref/#view.EditorView.updateState) to update the view.

Fix issue where sometimes moving the selection back its last position with the mouse failed to update ProseMirror's selection state.

No longer call [`deselectNode`](https://prosemirror.net/docs/ref/#view.NodeView.deselectNode) on already-destroyed node views.

## 1.8.8 (2019-04-11)

### Bug fixes

Fix a regression from 1.8.4 that made it return unreasonable rectangles for positions between blocks.

## 1.8.7 (2019-04-09)

### Bug fixes

The [`handlePaste`](https://prosemirror.net/docs/ref/#view.EditorProps.handlePaste) prop is now activated even when the default parser can't make any sense of the clipboard content.

## 1.8.6 (2019-04-08)

### Bug fixes

Fix a bug where decorations splitting a text node would sometimes confuse the display updater and make decorated nodes disappear.

## 1.8.5 (2019-04-08)

### Bug fixes

Multiple [`transformPastedHTML`](https://prosemirror.net/docs/ref/#view.EditorProps.transformPastedHTML) props are now all properly called in order, rather than only the first one.

Fixes an issue where invalid change positions were computed when a composition happened concurrently with a change that inserted content at the same position.

## 1.8.4 (2019-03-20)

### Bug fixes

[`EditorView.coordsAtPos`](https://prosemirror.net/docs/ref/#view.EditorView.coordsAtPos) is now more accurate in right-to-left text on Chrome and Firefox.

[`EditorView.coordsAtPos`](https://prosemirror.net/docs/ref/#view.EditorView.coordsAtPos) returns more accurate coordinates when querying the position directly after a line wrap point.

Fix an issue where clicking directly in front of a node selection doesn't clear the node selection markup.

## 1.8.3 (2019-03-04)

### Bug fixes

Fix an issue where clicking when there's a non-text selection active sometimes doesn't cause the appropriate new selection.

## 1.8.2 (2019-02-28)

### Bug fixes

Fix an issue where a view state update happening between a change to the DOM selection and the corresponding browser event could disrupt mouse selection.

## 1.8.1 (2019-02-22)

### Bug fixes

Fix infinite loop in `coordsAtPos`.

## 1.8.0 (2019-02-21)

### Bug fixes

Fix a bug where [`endOfTextblock`](https://prosemirror.net/docs/ref/#view.EditorView.endOfTextblock) spuriously returns true when the cursor is in a mark.

### New features

[`posAtCoords`](https://prosemirror.net/docs/ref/#view.EditorView.posAtCoords) will no longer return `null` when called with coordinates outside the browser's viewport. (It _will_ still return null for coordinates outside of the editor's bounding box.)

## 1.7.3 (2019-02-20)

### Bug fixes

[`endOfTextblock`](https://prosemirror.net/docs/ref/#view.EditorView.endOfTextblock) now works on textblocks that are the editor's top-level node.

## 1.7.2 (2019-02-20)

### Bug fixes

Pressing shift-left/right next to a selectable node no longer selects the node instead of creating a text selection across it.

## 1.7.1 (2019-02-04)

### Bug fixes

Fix an issue on Safari where an Enter key events that was part of a composition is interpreted as stand-alone Enter press.

## 1.7.0 (2019-01-29)

### Bug fixes

Fix an issue where node selections on uneditable nodes couldn't be copied or cut on Chrome.

### New features

The editable view now recognizes the [`spanning`](https://prosemirror.net/docs/ref/#model.MarkSpec.spanning) mark property.

## 1.6.8 (2019-01-03)

### Bug fixes

When replacing a selection by typing over it with a letter that matches its start or end, the editor now generates a step that covers the whole replacement.

Fixes dragging a node when the mouse is in a child DOM element that doesn't represent a document node. Work around Chrome bug in selection management

Fixes an issue in Chrome where clicking at the start of a textblock after a selected node would sometimes not move the cursor there.

Fix issue where a node view's `getPos` callback could sometimes return `NaN`.

Fix an issue where deleting more than 5 nodes might cause the nodes after that to be needlessly redrawn.

## 1.6.7 (2018-11-26)

### Bug fixes

Avoids redrawing of content with marks when other content in front of it is deleted.

## 1.6.6 (2018-11-15)

### Bug fixes

Work around a Chrome bug where programmatic changes near the cursor sometimes cause the visible and reported selection to disagree.

Changing the `nodeView` prop will no longer leave outdated node views in the DOM.

Work around an issue where Chrome unfocuses the editor or scrolls way down when pressing down arrow with the cursor between the start of a textblock and an uneditable element.

Fix a bug where mapping decoration sets through changes that changed the structure of decorated subtrees sometimes produced corrupted output.

## 1.6.5 (2018-10-29)

### Bug fixes

Work around Safari issue where deleting the last bit of text in a table cell creates weird HTML with a BR in a table row.

## 1.6.4 (2018-10-19)

### Bug fixes

Fix pasting when both text and files are present on the clipboard.

## 1.6.3 (2018-10-12)

### Bug fixes

The editor will no longer try to handle file paste events with the old-browser compatibility kludge (which might cause scrolling and focus flickering).

## 1.6.2 (2018-10-08)

### Bug fixes

Fixes an issue where event handlers were leaked when destroying an editor

## 1.6.1 (2018-10-01)

### Bug fixes

Fixes situation where a vertical [`endOfTextblock`](https://prosemirror.net/docs/ref/#view.EditorView.endOfTextblock) query could get confused by nearby widgets or complex parent node representation.

## 1.6.0 (2018-09-27)

### Bug fixes

Fixes a corner case in which DecorationSet.map would map decorations to incorrect new positions.

When the editor contains scrollable elements, scrolling the cursor into view also scrolls those.

### New features

The `scrollMargin` and `scrollThreshold` props may now hold `{left, right, top, bottom}` objects to set different margins and thresholds for different sides. Make scrolling from a given start node more robust

## 1.5.3 (2018-09-24)

### Bug fixes

The cursor is now scrolled into view after keyboard driven selection changes even when they were handled by the browser.

## 1.5.2 (2018-09-07)

### Bug fixes

Improves selection management around widgets with no actual HTML content (possibly drawn using CSS pseudo elements).

Fix extra whitespace in pasted HTML caused by previously-collapsed spacing.

Slow triple-clicks are no longer treated as two double-clicks in a row.

## 1.5.1 (2018-08-24)

### Bug fixes

Fix issue where some DOM selections would cause a non-editable view to crash when reading the selection.

## 1.5.0 (2018-08-21)

### New features

Mark views are now passed a boolean that indicates whether the mark's content is inline as third argument.

## 1.4.4 (2018-08-13)

### Bug fixes

Fix an issue where a non-empty DOM selection could stick around even though the state's selection is empty.

Fix an issue where Firefox would create an extra cursor position when arrow-keying through a widget.

## 1.4.3 (2018-08-12)

### Bug fixes

Fix an issue where the editor got stuck believing shift was down (and hence pasting as plain text) when it was unfocused with shift held down.

## 1.4.2 (2018-08-03)

### Bug fixes

Fix an issue where reading the selection from the DOM might crash in non-editable mode.

## 1.4.1 (2018-08-02)

### Bug fixes

Fixes an issue where backspacing out the last character between the start of a textblock and a widget in Chrome would insert a random hard break.

## 1.4.0 (2018-07-26)

### New features

The `dispatchTransaction` prop is now called with `this` bound to the editor view.

## 1.3.8 (2018-07-24)

### Bug fixes

Fix an issue where Chrome Android would move the cursor forward by one after backspace-joining two paragraphs.

## 1.3.7 (2018-07-02)

### Bug fixes

Fix a crash when scrolling things into view when the editor isn't a child of `document.body`.

## 1.3.6 (2018-06-21)

### Bug fixes

Make sure Safari version detection for clipboard support also works in iOS webview.

## 1.3.5 (2018-06-20)

### Bug fixes

Use shared implementation of [`dropPoint`](https://prosemirror.net/docs/ref/#transform.dropPoint) to handle finding a drop position.

## 1.3.4 (2018-06-20)

### Bug fixes

Enable use of browser clipboard API on Mobile Safari version 11 and up, which makes cut work on that platform and should generally improve clipboard handling.

## 1.3.3 (2018-06-15)

### Bug fixes

Fix arrow-left cursor motion from cursor wrapper (for example after a link).

Fix selection glitches when shift-selecting around widget decorations.

Fix issue where a parsing a code block from the editor DOM might drop newlines in the code.

## 1.3.2 (2018-06-15)

### Bug fixes

[`handleKeyDown`](https://prosemirror.net/docs/ref/#view.EditorProps.handleKeyDown) will now get notified of key events happening directly after a composition ends.

## 1.3.1 (2018-06-08)

### Bug fixes

The package can now be loaded in a web worker context (where `navigator` is defined but `document` isn't) without crashing.

Dropping something like a list item into a textblock will no longer split the textblock.

## 1.3.0 (2018-04-24)

### Bug fixes

Fix mouse-selecting (in IE and Edge) from the end of links and other positions that cause a cursor wrapper.

[Widget decorations](https://prosemirror.net/docs/ref/#view.Decoration^widget) with the same [key](https://prosemirror.net/docs/ref/#view.Decoration^widget^spec.key) are now considered equivalent, even if their other spec fields differ.

### New features

The new [`EditorView.posAtDOM` method](https://prosemirror.net/docs/ref/#view.EditorView.posAtDOM) can be used to find the document position corresponding to a given DOM position.

The new [`EditorView.nodeDOM` method](https://prosemirror.net/docs/ref/#view.EditorView.nodeDOM) gives you the DOM node that is used to represent a specific node in the document.

[`Decoration.widget`](https://prosemirror.net/docs/ref/#view.Decoration^widget) now accepts a function as second argument, which can be used to delay rendering of the widget until the document is drawn (at which point a reference to the view is available).

The `getPos` function passed to a [node view constructor](https://prosemirror.net/docs/ref/#view.editorProps.nodeViews) can now be called immediately (it used to return undefined until rendering had finished).

The function used to render a [widget](https://prosemirror.net/docs/ref/#view.Decoration^widget) is now passed a `getPos` method that event handlers can use to figure out where in the DOM the widget is.

## 1.2.0 (2018-03-14)

### Bug fixes

Fix a problem where updating the state of a non-editable view would not set the selection, causing problems when the DOM was updated in a way that disrupted the DOM selection.

Fix an issue where, on IE and Chrome, starting a drag selection in a position that required a cursor wrapper (on a mark boundary) would sometimes fail to work.

Fix crash in key handling when the editor is focused but there is no DOM selection.

Fixes a bug that prevented decorations inside node views with a [`contentDOM` property](https://prosemirror.net/docs/ref/#view.NodeView.contentDOM) from being drawn.

Fixes an issue where, on Firefox, depending on a race condition, the skipping over insignificant DOM nodes done at keypress was canceled again before the keypress took effect.

Fixes an issue where an `:after` pseudo-element on a non-inclusive mark could block the cursor, making it impossible to arrow past it.

### New features

The DOM structure for marks is no longer constrained to a single node. [Mark views](https://prosemirror.net/docs/ref/#view.NodeView) can have a `contentDOM` property, and [mark spec](https://prosemirror.net/docs/ref/#model.MarkSpec) `toDOM` methods can return structures with holes.

[Widget decorations](https://prosemirror.net/docs/ref/#view.Decoration^widget) are now wrapped in the marks of the node after them when their [`side` option](https://prosemirror.net/docs/ref/#view.Decoration^widget^spec.side) is >= 0.

[Widget decorations](https://prosemirror.net/docs/ref/#view.Decoration^widget) may now specify a [`marks` option](https://prosemirror.net/docs/ref/#view.Decoration^widget^spec.marks) to set the precise set of marks they should be wrapped in.

## 1.1.1 (2018-03-01)

### Bug fixes

Fixes typo that broke paste.

## 1.1.0 (2018-02-28)

### Bug fixes

Fixes issue where dragging a draggable node directly below a selected node would move the old selection rather than the target node.

A drop that can't fit the dropped content will no longer dispatch an empty transaction.

### New features

Transactions generated for drop now have a `"uiEvent"` metadata field holding `"drop"`. Paste and cut transactions get that field set to `"paste"` or `"cut"`.

## 1.0.11 (2018-02-16)

### Bug fixes

Fix issue where the cursor was visible when a node was selected on recent Chrome versions.

## 1.0.10 (2018-01-24)

### Bug fixes

Improve preservation of open and closed nodes in slices taken from the clipboard.

## 1.0.9 (2018-01-17)

### Bug fixes

Work around a Chrome cursor motion bug by making sure <br> nodes don't get a contenteditable=false attribute.

## 1.0.8 (2018-01-09)

### Bug fixes

Fix issue where [`Decoration.map`](https://prosemirror.net/docs/ref/#view.DecorationSet.map) would in some situations with nested nodes incorrectly map decoration positions.

## 1.0.7 (2018-01-05)

### Bug fixes

Pasting from an external source no longer opens isolating nodes like table cells.

## 1.0.6 (2017-12-26)

### Bug fixes

[`DecorationSet.remove`](https://prosemirror.net/docs/ref/#view.DecorationSet.remove) now uses a proper deep compare to determine if widgets are the same (it used to compare by identity).

## 1.0.5 (2017-12-05)

### Bug fixes

Fix an issue where deeply nested decorations were mapped incorrectly in corner cases.

## 1.0.4 (2017-11-27)

### Bug fixes

Fix a corner-case crash during drop.

## 1.0.3 (2017-11-23)

### Bug fixes

Pressing backspace between two identical characters will no longer generate a transaction that deletes the second one.

## 1.0.2 (2017-11-20)

### Bug fixes

Fix test for whether a node can be selected when arrowing onto it from the right.

Calling [`posAtCoords`](https://prosemirror.net/docs/ref/#view.EditorView.posAtCoords) while a read from the DOM is pending will no longer return a malformed result.

## 1.0.1 (2017-11-10)

### Bug fixes

Deleting the last character in a list item no longer results in a spurious hard_break node on Safari.

Fixes a crash on IE11 when starting to drag.

## 1.0.0 (2017-10-13)

### Bug fixes

Dragging nodes with a node view that handles its own mouse events should work better now.

List item DOM nodes are no longer assigned `pointer-events: none` in the default style. Ctrl-clicking list markers now properly selects the list item again.

Arrow-down through an empty textblock no longer causes the browser to forget the cursor's horizontal position.

Copy-dragging on OS X is now done by holding option, rather than control, following the convention on that system.

Fixes a crash related to decoration management.

Fixes a problem where using cut on IE11 wouldn't actually remove the selected text.

Copy/paste on Edge 15 and up now uses the clipboard API, fixing a problem that made them fail entirely.

### New features

The [`dragging`](https://prosemirror.net/docs/ref/#view.EditorView.dragging) property of a view, which contains information about editor content being dragged, is now part of the public interface.

## 0.24.0 (2017-09-25)

### New features

The [`clipboardTextParser`](https://prosemirror.net/docs/ref/version/0.24.0.html#view.EditorProps.clipboardTextParser) prop is now passed a context position.

## 0.23.0 (2017-09-13)

### Breaking changes

The `onFocus`, `onBlur`, and `handleContextMenu` props are no longer supported. You can achieve their effect with the [`handleDOMEvents`](https://prosemirror.net/docs/ref/version/0.23.0.html#view.EditorProps.handleDOMEvents) prop.

### Bug fixes

Fixes occasional crash when reading the selection in Firefox.

Putting a table cell on the clipboard now properly wraps it in a table.

The view will no longer scroll into view when receiving a state that isn't derived from its previous state.

### New features

Transactions caused by a paste now have their "paste" meta property set to true.

Adds a new view prop, [`handleScrollToSelection`](https://prosemirror.net/docs/ref/version/0.23.0.html#view.EditorProps.handleScrollToSelection) to override the behavior of scrolling the selection into view.

The new editor prop [`clipboardTextSerializer`](https://prosemirror.net/docs/ref/version/0.23.0.html#view.EditorProps.clipboardTextSerializer) allows you to override the way a piece of document is converted to clipboard text.

Adds the editor prop [`clipboardTextParser`](https://prosemirror.net/docs/ref/version/0.23.0.html#view.EditorProps.clipboardTextParser), which can be used to define your own parsing strategy for clipboard text content.

[`DecorationSet.find`](https://prosemirror.net/docs/ref/version/0.23.0.html#view.DecorationSet.find) now supports passing a predicate to filter decorations by spec.

## 0.22.1 (2017-08-16)

### Bug fixes

Invisible selections that don't cover any content (i.e., a cursor) are now properly hidden.

Initializing the editor view non-editable no longer causes a crash.

## 0.22.0 (2017-06-29)

### Bug fixes

Fix an issue where moving the cursor through a text widget causes the editor to lose the selection in Chrome.

Fixes an issue where down-arrow in front of a widget would sometimes not cause any cursor motion on Chrome.

[Destroying](https://prosemirror.net/docs/ref/version/0.22.0.html#view.EditorView.destroy) a [mounted](https://prosemirror.net/docs/ref/version/0.22.0.html#view.EditorView.constructor) editor view no longer leaks event handlers.

Display updates for regular, non-composition input are now synchronous, which should reduce flickering when, for example, updating decorations in response to typing.

### New features

The editor can now be initialized in a document other than the global document (say, an `iframe`).

Editor views now have a [`domAtPos` method](https://prosemirror.net/docs/ref/version/0.22.0.html#view.EditorView.domAtPos), which gives you the DOM position corresponding to a given document position.

## 0.21.1 (2017-05-09)

### Bug fixes

Copying and pasting table cells on Edge no longer strips the table structure.

## 0.21.0 (2017-05-03)

### Breaking changes

The `associative` option to widget decorations is no longer supported. To make a widget left-associative, set its `side` option to a negative number. `associative` will continue to work with a warning until the next release.

### New features

[Widget decorations](https://prosemirror.net/docs/ref/version/0.21.0.html#view.Decoration^widget) now support a `side` option that controls which side of them the cursor is drawn, where they move when content is inserted at their position, and the order in which they appear relative to other widgets at the same position.

## 0.20.5 (2017-05-02)

### Bug fixes

Fixes an issue where the DOM selection could be shown on the wrong side of hard break or image nodes.

## 0.20.4 (2017-04-24)

### Bug fixes

Fix a bug that prevented the DOM selection from being updated when the new position was near the old one in some circumstances.

Stop interfering with alt-d keypresses on OS X.

Fix issue where reading a DOM change in a previously empty node could crash.

Fixes crash when reading a change that removed a decorated text node from the DOM.

## 0.20.3 (2017-04-12)

### Bug fixes

Shift-pasting and pasting into a code block now does the right thing on IE and Edge.

## 0.20.2 (2017-04-05)

### Bug fixes

Fixes a bug that broke dragging from the editor.

## 0.20.1 (2017-04-04)

### Bug fixes

Typing in code blocks no longer replaces newlines with spaces.

Copy and paste on Internet Explorer, Edge, and mobile Safari should now behave more like it does on other browsers. Handlers are called, and the changes to the document are made by ProseMirror's code, not the browser.

Fixes a problem where triple-clicking the editor would sometimes cause the scroll position to inexplicably jump around on IE11.

## 0.20.0 (2017-04-03)

### Breaking changes

The `inclusiveLeft` and `inclusiveRight` options to inline decorations were renamed to [`inclusiveStart`](https://prosemirror.net/docs/ref/version/0.20.0.html#view.Decoration^inline^spec.inclusiveStart) and [`inclusiveEnd`](https://prosemirror.net/docs/ref/version/0.20.0.html#view.Decoration^inline^spec.inclusiveEnd) so that they also make sense in right-to-left text. The old names work with a warning until the next release.

The default styling for lists and blockquotes was removed from `prosemirror.css`. (They were moved to the [`example-setup`](https://github.com/ProseMirror/prosemirror-example-setup) module.)

### Bug fixes

Fixes reading of selection in Chrome in a shadow DOM.

Registering DOM event handlers that the editor doesn't listen to by default with the `handleDOMEvents` prop should work again.

Backspacing after turning off a mark now works again in Firefox.

### New features

The new props [`handlePaste`](https://prosemirror.net/docs/ref/version/0.20.0.html#view.EditorProps.handlePaste) and [`handleDrop`](https://prosemirror.net/docs/ref/version/0.20.0.html#view.EditorProps.handleDrop) can be used to override drop and paste behavior.

## 0.19.1 (2017-03-18)

### Bug fixes

Fixes a number of issues with characters being duplicated or disappearing when typing on mark boundaries.

## 0.19.0 (2017-03-16)

### Breaking changes

[`endOfTextblock`](https://prosemirror.net/docs/ref/version/0.19.0.html#view.EditorView.endOfTextblock) no longer always returns false for horizontal motion on non-cursor selections, but checks the position of the selection head instead.

### Bug fixes

Typing after adding/removing a mark no longer briefly shows the new text with the wrong marks.

[`posAtCoords`](https://prosemirror.net/docs/ref/version/0.19.0.html#view.EditorView.posAtCoords) is now more reliable on modern browsers by using browser APIs.

Fix a bug where the view would in some circumstances leave superfluous DOM nodes around inside marks.

### New features

You can now override the selection the editor creates for a given DOM selection with the [`createSelectionBetween`](https://prosemirror.net/docs/ref/version/0.19.0.html#view.EditorProps.createSelectionBetween) prop.

## 0.18.0 (2017-02-24)

### Breaking changes

`Decoration` objects now store their definition object under [`spec`](https://prosemirror.net/docs/ref/version/0.18.0.html#Decoration.spec), not `options`. The old property name still works, with a warning, until the next release.

### Bug fixes

Fix bug where calling [`focus`](https://prosemirror.net/docs/ref/version/0.18.0.html#view.EditorView.focus) when there was a text selection would sometimes result in `state.selection` receiving an incorrect value.

[`EditorView.props`](https://prosemirror.net/docs/ref/version/0.18.0.html#view.EditorView.props) now has its `state` property updated when you call `updateState`.

Putting decorations on or inside a node view with an `update` method now works.

### New features

[Plugin view](https://prosemirror.net/docs/ref/version/0.18.0.html#state.PluginSpec.view) update methods are now passed the view's previous state as second argument.

The `place` agument to the [`EditorView` constructor](https://prosemirror.net/docs/ref/version/0.18.0.html#view.EditorView) can now be an object with a `mount` property to directly provide the node that should be made editable.

The new [`EditorView.setProps` method](https://prosemirror.net/docs/ref/version/0.18.0.html#view.EditorView.setProps) makes it easier to update individual props.

## 0.17.7 (2017-02-08)

### Bug fixes

Fixes crash in the code that maintains the scroll position when the document is empty or hidden.

## 0.17.6 (2017-02-08)

### Bug fixes

Transactions that shouldn't [scroll the selection into view](https://prosemirror.net/docs/ref/version/0.17.0.html#state.transaction.scrollIntoView) now no longer do so.

## 0.17.4 (2017-02-02)

### Bug fixes

Fixes bug where widget decorations would sometimes get parsed as content when editing near them.

The editor now prevents the behavior of Ctrl-d and Ctrl-h on textblock boundaries on OS X, as intended.

Make sure long words don't cause a horizontal scrollbar in Firefox

Various behavior fixes for IE11.

## 0.17.3 (2017-01-19)

### Bug fixes

DOM changes deleting a node's inner wrapping DOM element (for example the `<code>` tag in a schema-basic code block) no longer break the editor.

## 0.17.2 (2017-01-16)

### Bug fixes

Call custom click handlers before applying select-node behavior for a ctrl/cmd-click.

Fix failure to apply DOM changes that start at document position 0.

## 0.17.1 (2017-01-07)

### Bug fixes

Fix issue where a document update that left the selection in the same place sometimes led to an incorrect DOM selection.

Make sure [`EditorView.focus`](https://prosemirror.net/docs/ref/version/0.17.0.html#view.EditorView.focus) doesn't cause the browser to scroll the top of the editor into view.

## 0.17.0 (2017-01-05)

### Breaking changes

The `handleDOMEvent` prop has been dropped in favor of the [`handleDOMEvents`](https://prosemirror.net/docs/ref/version/0.17.0.html#view.EditorProps.handleDOMEvents) (plural) prop.

The `onChange` prop has been replaced by a [`dispatchTransaction`](https://prosemirror.net/docs/ref/version/0.17.0.html#view.EditorProps.dispatchTransaction) prop (which takes a transaction instead of an action).

### New features

Added support for a [`handleDOMEvents` prop](https://prosemirror.net/docs/ref/version/0.17.0.html#view.EditorProps.handleDOMEvents), which allows you to provide handler functions per DOM event, and works even for events that the editor doesn't normally add a handler for.

Add view method [`dispatch`](https://prosemirror.net/docs/ref/version/0.17.0.html#view.EditorView.dispatch), which provides a convenient way to dispatch transactions.

The [`dispatchTransaction`](https://prosemirror.net/docs/ref/version/0.17.0.html#view.EditorProps.dispatchTransaction) (used to be `onAction`) prop is now optional, and will default to simply applying the transaction to the current view state.

[Widget decorations](https://prosemirror.net/docs/ref/version/0.17.0.html#view.Decoration.widget) now accept an option `associative` which can be used to configure on which side of content inserted at their position they end up.

Typing immediately after deleting text now preserves the marks of the deleted text.

Transactions that update the selection because of mouse or touch input now get a metadata property `pointer` with the value `true`.

## 0.16.0 (2016-12-23)

### Bug fixes

Solve problem where setting a node selection would trigger a DOM read, leading to the selection being reset.

## 0.16.0 (2016-12-23)

### Breaking changes

The `spellcheck`, `label`, and `class` props are now replaced by an [`attributes` prop](https://prosemirror.net/docs/ref/version/0.16.0.html#view.EditorProps.attributes).

### Bug fixes

Ignoring/aborting an action should no longer lead to the DOM being stuck in an outdated state.

Typing at the end of a textblock which ends in a non-text node now actually works.

DOM nodes for leaf document nodes are now set as non-editable to prevent various issues such as stray cursors inside of them and Firefox adding image resize controls.

Inserting a node no longer causes nodes of the same type after it to be neednessly redrawn.

### New features

Add a new editor prop [`editable`](https://prosemirror.net/docs/ref/version/0.16.0.html#view.EditorProps.editable) which controls whether the editor's `contentEditable` behavior is enabled.

Plugins and props can now set any DOM attribute on the outer editor node using the [`attributes` prop](https://prosemirror.net/docs/ref/version/0.16.0.html#view.EditorProps.attributes).

Node view constructors and update methods now have access to the node's wrapping decorations, which can be used to pass information to a node view without encoding it in the document.

Attributes added or removed by node and inline [decorations](https://prosemirror.net/docs/ref/version/0.16.0.html#view.Decoration) no longer cause the nodes inside of them to be fully redrawn, making node views more stable and allowing CSS transitions to be used.

## 0.15.2 (2016-12-10)

### Bug fixes

The native selection is now appropriately hidden when there is a node selection.

## 0.15.1 (2016-12-10)

### Bug fixes

Fix DOM parsing for decorated text nodes.

## 0.15.0 (2016-12-10)

### Breaking changes

The editor view no longer wraps its editable DOM element in a wrapper element. The `ProseMirror` CSS class now applies directly to the editable element. The `ProseMirror-content` CSS class is still present for ease of upgrading but will be dropped in the next release.

The editor view no longer draws a drop cursor when dragging content over the editor. The new [`prosemirror-dropcursor`](https://github.com/prosemirror/prosemirror-dropcursor) module implements this as a plugin.

### Bug fixes

Simple typing and backspacing now gets handled by the browser without ProseMirror redrawing the touched nodes, making spell-checking and various platform-specific input tricks (long-press on OS X, double space on iOS) work in the editor.

Improve tracking of DOM nodes that have been touched by user changes, so that [`updateState`](https://prosemirror.net/docs/ref/version/0.15.0.html#view.EditorView.updateState) can reliably fix them.

Changes to the document that happen while dragging editor content no longer break moving of the content.

Adding or removing a mark directly in the DOM (for example with the bold/italic buttons in iOS' context menu) now produces mark steps, rather than replace steps.

Pressing backspace at the start of a paragraph on Android now allows key handlers for backspace to fire.

Toggling a mark when there is no selection now works better on mobile platforms.

### New features

Introduces an [`endOfTextblock`](https://prosemirror.net/docs/ref/version/0.15.0.html#view.EditorView.endOfTextblock) method on views, which can be used to find out in a bidi- and layout-aware way whether the selection is on the edge of a textblock.

## 0.14.4 (2016-12-02)

### Bug fixes

Fix issue where node decorations would stick around in the DOM after the decoration was removed.

Setting or removing a node selection in an unfocused editor now properly updates the DOM to show that selection.

## 0.14.2 (2016-11-30)

### Bug fixes

FIX: Avoid unneeded selection resets which sometimes confused browsers.

## 0.14.2 (2016-11-29)

### Bug fixes

Fix a bug where inverted selections weren't created in the DOM correctly.

## 0.14.1 (2016-11-29)

### Bug fixes

Restores previously broken kludge that allows the cursor to appear after non-text content at the end of a line.

## 0.14.0 (2016-11-28)

### Breaking changes

Wrapping decorations are now created using the [`nodeName`](https://prosemirror.net/docs/ref/version/0.14.0.html#view.DecorationAttrs.nodeName) property. The `wrapper` property is no longer supported.

The `onUnmountDOM` prop is no longer supported (use a node view with a [`destroy`](https://prosemirror.net/docs/ref/version/0.14.0.html#view.NodeView.destroy) method instead).

The `domSerializer` prop is no longer supported. Use [node views](https://prosemirror.net/docs/ref/version/0.14.0.html#view.EditorProps.nodeViews) to configure editor-specific node representations.

### New features

Widget decorations can now be given a [`key`](https://prosemirror.net/docs/ref/version/0.14.0.html#view.Decoration.widget^options.key) property to prevent unneccesary redraws.

The `EditorView` class now has a [`destroy`](https://prosemirror.net/docs/ref/version/0.14.0.html#view.EditorView.destroy) method for cleaning up.

The [`handleClickOn`](https://prosemirror.net/docs/ref/version/0.14.0.html#view.EditorProps.handleClickOn) prop and friends now receive a `direct` boolean argument that indicates whether the node was clicked directly.

[Widget decorations](https://prosemirror.net/docs/ref/version/0.14.0.html#view.Decoration^widget) now support a `stopEvent` option that can be used to control which DOM events that pass through them should be ignored by the editor view.

You can now [specify](https://prosemirror.net/docs/ref/version/0.14.0.html#view.EditorProps.nodeViews) custom [node views](https://prosemirror.net/docs/ref/version/0.14.0.html#view.NodeView) for an editor view, which give you control over the way node of a given type are represented in the DOM. See the related [RFC](https://discuss.prosemirror.net/t/rfc-node-views-to-manage-the-representation-of-nodes/463).

## 0.13.2 (2016-11-15)

### Bug fixes

Fixes an issue where widget decorations in the middle of text nodes would sometimes disappear.

## 0.13.1 (2016-11-15)

### Bug fixes

Fixes event handler crash (and subsequent bad default behavior) when pasting some types of external HTML into an editor.

## 0.13.0 (2016-11-11)

### Breaking changes

Selecting nodes on OS X is now done with cmd-leftclick rather than ctrl-leftclick.

### Bug fixes

Pasting text into a code block will now insert the raw text.

Widget decorations at the start or end of a textblock no longer block horizontal cursor motion through them.

Widget nodes at the end of textblocks are now reliably drawn during display updates.

### New features

[`DecorationSet.map`](https://prosemirror.net/docs/ref/version/0.13.0.html#view.DecorationSet.map) now takes an options object which allows you to specify an `onRemove` callback to be notified when remapping drops decorations.

The [`transformPastedHTML`](https://prosemirror.net/docs/ref/version/0.13.0.html#view.EditorProps.transformPastedHTML) and [`transformPastedText`](https://prosemirror.net/docs/ref/version/0.13.0.html#view.EditorProps.transformPastedText) props were (re-)added, and can be used to clean up pasted content.

## 0.12.2 (2016-11-02)

### Bug fixes

Inline decorations that span across an empty textblock no longer crash the display drawing code.

## 0.12.1 (2016-11-01)

### Bug fixes

Use a separate document to parse pasted HTML to better protect
against cross-site scripting attacks.

Specifying multiple classes in a decoration now actually works.

Ignore empty inline decorations when building a decoration set.

## 0.12.0 (2016-10-21)

### Breaking changes

The return value of
[`EditorView.posAtCoords`](https://prosemirror.net/docs/ref/version/0.12.0.html#view.EditorView.posAtCoords) changed to
contain an `inside` property pointing at the innermost node that the
coordinates are inside of. (Note that the docs for this method were
wrong in the previous release.)

### Bug fixes

Reduce reliance on shift-state tracking to minimize damage when
it gets out of sync.

Fix bug that'd produce bogus document positions for DOM positions
inside non-document nodes.

Don't treat fast ctrl-clicks as double or triple clicks.

### New features

Implement [decorations](https://prosemirror.net/docs/ref/version/0.12.0.html#view.Decoration), a way to
influence the way the document is drawn. Add the [`decorations`
prop](https://prosemirror.net/docs/ref/version/0.12.0.html#view.EditorProps.decorations) to specify them.

## 0.11.2 (2016-10-04)

### Bug fixes

Pass actual event object to [`handleDOMEvent`](https://prosemirror.net/docs/ref/version/0.11.0.html#view.EditorProps.handleDOMEvent), rather than just its name.

Fix display corruption caused by using the wrong state as previous version during IME.

## 0.11.0 (2016-09-21)

### Breaking changes

Moved into a separate module from the old `edit` submodule. Completely
new approach to managing the editor's DOM representation and input.

Event handlers and options are now replaced by
[props](https://prosemirror.net/docs/ref/version/0.11.0.html#view.EditorProps). The view's state is now 'shallow',
represented entirely by a set of props, one of which holds an editor
state value from the [state](https://prosemirror.net/docs/ref/version/0.11.0.html#state) module.

When the user interacts with the editor, it will pass an
[action](https://prosemirror.net/docs/ref/version/0.11.0.html#state.Action) to its
[`onAction`](https://prosemirror.net/docs/ref/version/0.11.0.html#view.EditorProps.onAction) prop, which is responsible
for triggering an view update.

The `markRange` system was dropped, to be replaced in the next release
by a 'decoration' system.

There is no keymap support in the view module anymore. Use a
[keymap](https://prosemirror.net/docs/ref/version/0.11.0.html#keymap) plugin for that.

The undo [history](https://prosemirror.net/docs/ref/version/0.11.0.html#history) is now a separate plugin.

CSS needed by the editor is no longer injected implicitly into the
page. Instead, you should arrange for the `style/prosemirror.css` file
to be loaded into your page.

### New features

The DOM [parser](https://prosemirror.net/docs/ref/version/0.11.0.html#model.DOMParser) and
[serializer](https://prosemirror.net/docs/ref/version/0.11.0.html#model.DOMSerializer) used to interact with the visible
DOM and the clipboard can now be customized through
[props](https://prosemirror.net/docs/ref/version/0.11.0.html#view.EditorProps).

You can now provide a catch-all DOM
[event handler](https://prosemirror.net/docs/ref/version/0.11.0.html#view.EditorProps.handleDOMEvent) to get a first
chance at handling DOM events.

The [`onUnmountDOM`](https://prosemirror.net/docs/ref/version/0.11.0.html#view.EditorProps.onUnmountDOM) can be used to
be notified when a piece of the document DOM is thrown away (in case
cleanup is needed).

