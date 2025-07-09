import {Plugin, Transaction, EditorState, TextSelection, Command} from "prosemirror-state"
import {EditorView} from "prosemirror-view"

/// Input rules are regular expressions describing a piece of text
/// that, when typed, causes something to happen. This might be
/// changing two dashes into an emdash, wrapping a paragraph starting
/// with `"> "` into a blockquote, or something entirely different.
export class InputRule {
  /// @internal
  handler: (state: EditorState, match: RegExpMatchArray, start: number, end: number) => Transaction | null

  /// @internal
  undoable: boolean
  inCode: boolean | "only"

  // :: (RegExp, union<string, (state: EditorState, match: [string], start: number, end: number) → ?Transaction>)
  /// Create an input rule. The rule applies when the user typed
  /// something and the text directly in front of the cursor matches
  /// `match`, which should end with `$`.
  ///
  /// The `handler` can be a string, in which case the matched text, or
  /// the first matched group in the regexp, is replaced by that
  /// string.
  ///
  /// Or a it can be a function, which will be called with the match
  /// array produced by
  /// [`RegExp.exec`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/RegExp/exec),
  /// as well as the start and end of the matched range, and which can
  /// return a [transaction](#state.Transaction) that describes the
  /// rule's effect, or null to indicate the input was not handled.
  constructor(
    /// @internal
    readonly match: RegExp,
    handler: string | ((state: EditorState, match: RegExpMatchArray, start: number, end: number) => Transaction | null),
    options: {
      /// When set to false,
      /// [`undoInputRule`](#inputrules.undoInputRule) doesn't work on
      /// this rule.
      undoable?: boolean,
      /// By default, input rules will not apply inside nodes marked
      /// as [code](#model.NodeSpec.code). Set this to true to change
      /// that, or to `"only"` to _only_ match in such nodes.
      inCode?: boolean | "only"
    } = {}
  ) {
    this.match = match
    this.handler = typeof handler == "string" ? stringHandler(handler) : handler
    this.undoable = options.undoable !== false
    this.inCode = options.inCode || false
  }
}

function stringHandler(string: string) {
  return function(state: EditorState, match: RegExpMatchArray, start: number, end: number) {
    let insert = string
    if (match[1]) {
      let offset = match[0].lastIndexOf(match[1])
      insert += match[0].slice(offset + match[1].length)
      start += offset
      let cutOff = start - end
      if (cutOff > 0) {
        insert = match[0].slice(offset - cutOff, offset) + insert
        start = end
      }
    }
    return state.tr.insertText(insert, start, end)
  }
}

const MAX_MATCH = 500

type PluginState = {transform: Transaction, from: number, to: number, text: string} | null

/// Create an input rules plugin. When enabled, it will cause text
/// input that matches any of the given rules to trigger the rule's
/// action.
export function inputRules({rules}: {rules: readonly InputRule[]}) {
  let plugin: Plugin<PluginState> = new Plugin<PluginState>({
    state: {
      init() { return null },
      apply(this: typeof plugin, tr, prev) {
        let stored = tr.getMeta(this)
        if (stored) return stored
        return tr.selectionSet || tr.docChanged ? null : prev
      }
    },

    props: {
      handleTextInput(view, from, to, text) {
        return run(view, from, to, text, rules, plugin)
      },
      handleDOMEvents: {
        compositionend: (view) => {
          setTimeout(() => {
            let {$cursor} = view.state.selection as TextSelection
            if ($cursor) run(view, $cursor.pos, $cursor.pos, "", rules, plugin)
          })
        }
      }
    },

    isInputRules: true
  })
  return plugin
}

function run(view: EditorView, from: number, to: number, text: string, rules: readonly InputRule[], plugin: Plugin) {
  if (view.composing) return false
  let state = view.state, $from = state.doc.resolve(from)
  let textBefore = $from.parent.textBetween(Math.max(0, $from.parentOffset - MAX_MATCH), $from.parentOffset,
                                            null, "\ufffc") + text
  for (let i = 0; i < rules.length; i++) {
    let rule = rules[i];
    if ($from.parent.type.spec.code) {
      if (!rule.inCode) continue
    } else if (rule.inCode === "only") {
      continue
    }
    let match = rule.match.exec(textBefore)
    let tr = match && rule.handler(state, match, from - (match[0].length - text.length), to)
    if (!tr) continue
    if (rule.undoable) tr.setMeta(plugin, {transform: tr, from, to, text})
    view.dispatch(tr)
    return true
  }
  return false
}

/// This is a command that will undo an input rule, if applying such a
/// rule was the last thing that the user did.
export const undoInputRule: Command = (state, dispatch) => {
  let plugins = state.plugins
  for (let i = 0; i < plugins.length; i++) {
    let plugin = plugins[i], undoable
    if ((plugin.spec as any).isInputRules && (undoable = plugin.getState(state))) {
      if (dispatch) {
        let tr = state.tr, toUndo = undoable.transform
        for (let j = toUndo.steps.length - 1; j >= 0; j--)
          tr.step(toUndo.steps[j].invert(toUndo.docs[j]))
        if (undoable.text) {
          let marks = tr.doc.resolve(undoable.from).marks()
          tr.replaceWith(undoable.from, undoable.to, state.schema.text(undoable.text, marks))
        } else {
          tr.delete(undoable.from, undoable.to)
        }
        dispatch(tr)
      }
      return true
    }
  }
  return false
}
