# prosemirror-dropcursor

[ [**WEBSITE**](http://prosemirror.net) | [**ISSUES**](https://github.com/prosemirror/prosemirror-dropcursor/issues) | [**FORUM**](https://discuss.prosemirror.net) | [**GITTER**](https://gitter.im/ProseMirror/prosemirror) ]

This is a non-core example module for [ProseMirror](http://prosemirror.net).
ProseMirror is a well-behaved rich semantic content editor based on
contentEditable, with support for collaborative editing and custom
document schemas.

This module implements a plugin that shows a drop cursor for
ProseMirror.

The [project page](http://prosemirror.net) has more information, a
number of [examples](http://prosemirror.net/examples/) and the
[documentation](http://prosemirror.net/docs/).

This code is released under an
[MIT license](https://github.com/prosemirror/prosemirror/tree/master/LICENSE).
There's a [forum](http://discuss.prosemirror.net) for general
discussion and support requests, and the
[Github bug tracker](https://github.com/prosemirror/prosemirror/issues)
is the place to report issues.

We aim to be an inclusive, welcoming community. To make that explicit,
we have a [code of
conduct](http://contributor-covenant.org/version/1/1/0/) that applies
to communication around the project.

## Documentation

**`dropCursor`**`(options: ?Object) → Plugin`

Create a plugin that, when added to a ProseMirror instance, causes a
decoration to show up at the drop position when something is dragged
over the editor.

 - **`options`**`: ?Object`
   - **`color`**`: ?string (default: black)`
   - **`width`**`: ?number (default: 1)`
   - **`class`**`: ?string`\
   Adds a class to the cursor.\
   *Layout overrides such as `width` are not recommended*
