import {type EditorView, type EditorProps} from "prosemirror-view"
import {EditorState, EditorStateConfig} from "./state"
import {Transaction} from "./transaction"

/// This is the type passed to the [`Plugin`](#state.Plugin)
/// constructor. It provides a definition for a plugin.
export interface PluginSpec<PluginState> {
  /// The [view props](#view.EditorProps) added by this plugin. Props
  /// that are functions will be bound to have the plugin instance as
  /// their `this` binding.
  props?: EditorProps<Plugin<PluginState>>

  /// Allows a plugin to define a [state field](#state.StateField), an
  /// extra slot in the state object in which it can keep its own data.
  state?: StateField<PluginState>

  /// Can be used to make this a keyed plugin. You can have only one
  /// plugin with a given key in a given state, but it is possible to
  /// access the plugin's configuration and state through the key,
  /// without having access to the plugin instance object.
  key?: PluginKey

  /// When the plugin needs to interact with the editor view, or
  /// set something up in the DOM, use this field. The function
  /// will be called when the plugin's state is associated with an
  /// editor view.
  view?: (view: EditorView) => PluginView

  /// When present, this will be called before a transaction is
  /// applied by the state, allowing the plugin to cancel it (by
  /// returning false).
  filterTransaction?: (tr: Transaction, state: EditorState) => boolean

  /// Allows the plugin to append another transaction to be applied
  /// after the given array of transactions. When another plugin
  /// appends a transaction after this was called, it is called again
  /// with the new state and new transactions—but only the new
  /// transactions, i.e. it won't be passed transactions that it
  /// already saw.
  appendTransaction?: (transactions: readonly Transaction[], oldState: EditorState, newState: EditorState) => Transaction | null | undefined

  /// Additional properties are allowed on plugin specs, which can be
  /// read via [`Plugin.spec`](#state.Plugin.spec).
  [key: string]: any
}

/// A stateful object that can be installed in an editor by a
/// [plugin](#state.PluginSpec.view).
export type PluginView = {
  /// Called whenever the view's state is updated.
  update?: (view: EditorView, prevState: EditorState) => void

  /// Called when the view is destroyed or receives a state
  /// with different plugins.
  destroy?: () => void
}

function bindProps(obj: {[prop: string]: any}, self: any, target: {[prop: string]: any}) {
  for (let prop in obj) {
    let val = obj[prop]
    if (val instanceof Function) val = val.bind(self)
    else if (prop == "handleDOMEvents") val = bindProps(val, self, {})
    target[prop] = val
  }
  return target
}

/// Plugins bundle functionality that can be added to an editor.
/// They are part of the [editor state](#state.EditorState) and
/// may influence that state and the view that contains it.
export class Plugin<PluginState = any> {
  /// Create a plugin.
  constructor(
    /// The plugin's [spec object](#state.PluginSpec).
    readonly spec: PluginSpec<PluginState>
  ) {
    if (spec.props) bindProps(spec.props, this, this.props)
    this.key = spec.key ? spec.key.key : createKey("plugin")
  }

  /// The [props](#view.EditorProps) exported by this plugin.
  readonly props: EditorProps<Plugin<PluginState>> = {}

  /// @internal
  key: string

  /// Extract the plugin's state field from an editor state.
  getState(state: EditorState): PluginState | undefined { return (state as any)[this.key] }
}

/// A plugin spec may provide a state field (under its
/// [`state`](#state.PluginSpec.state) property) of this type, which
/// describes the state it wants to keep. Functions provided here are
/// always called with the plugin instance as their `this` binding.
export interface StateField<T> {
  /// Initialize the value of the field. `config` will be the object
  /// passed to [`EditorState.create`](#state.EditorState^create). Note
  /// that `instance` is a half-initialized state instance, and will
  /// not have values for plugin fields initialized after this one.
  init: (config: EditorStateConfig, instance: EditorState) => T

  /// Apply the given transaction to this state field, producing a new
  /// field value. Note that the `newState` argument is again a partially
  /// constructed state does not yet contain the state from plugins
  /// coming after this one.
  apply: (tr: Transaction, value: T, oldState: EditorState, newState: EditorState) => T

  /// Convert this field to JSON. Optional, can be left off to disable
  /// JSON serialization for the field.
  toJSON?: (value: T) => any

  /// Deserialize the JSON representation of this field. Note that the
  /// `state` argument is again a half-initialized state.
  fromJSON?: (config: EditorStateConfig, value: any, state: EditorState) => T
}

const keys = Object.create(null)

function createKey(name: string) {
  if (name in keys) return name + "$" + ++keys[name]
  keys[name] = 0
  return name + "$"
}

/// A key is used to [tag](#state.PluginSpec.key) plugins in a way
/// that makes it possible to find them, given an editor state.
/// Assigning a key does mean only one plugin of that type can be
/// active in a state.
export class PluginKey<PluginState = any> {
  /// @internal
  key: string

  /// Create a plugin key.
  constructor(name = "key") { this.key = createKey(name) }

  /// Get the active plugin with this key, if any, from an editor
  /// state.
  get(state: EditorState): Plugin<PluginState> | undefined { return state.config.pluginsByKey[this.key] }

  /// Get the plugin's state from an editor state.
  getState(state: EditorState): PluginState | undefined { return (state as any)[this.key] }
}
