import RopeSequence from "rope-sequence"
import {Mapping, Step, StepMap, Transform} from "prosemirror-transform"
import {Plugin, Command, PluginKey, EditorState, Transaction, SelectionBookmark} from "prosemirror-state"

// ProseMirror's history isn't simply a way to roll back to a previous
// state, because ProseMirror supports applying changes without adding
// them to the history (for example during collaboration).
//
// To this end, each 'Branch' (one for the undo history and one for
// the redo history) keeps an array of 'Items', which can optionally
// hold a step (an actual undoable change), and always hold a position
// map (which is needed to move changes below them to apply to the
// current document).
//
// An item that has both a step and a selection bookmark is the start
// of an 'event' — a group of changes that will be undone or redone at
// once. (It stores only the bookmark, since that way we don't have to
// provide a document until the selection is actually applied, which
// is useful when compressing.)

// Used to schedule history compression
const max_empty_items = 500

class Branch {
  constructor(readonly items: RopeSequence<Item>, readonly eventCount: number) {}

  // Pop the latest event off the branch's history and apply it
  // to a document transform.
  popEvent(state: EditorState, preserveItems: boolean) {
    if (this.eventCount == 0) return null

    let end = this.items.length
    for (;; end--) {
      let next = this.items.get(end - 1)
      if (next.selection) { --end; break }
    }

    let remap: Mapping | undefined, mapFrom: number | undefined
    if (preserveItems) {
      remap = this.remapping(end, this.items.length)
      mapFrom = remap.maps.length
    }
    let transform = state.tr
    let selection: SelectionBookmark | undefined, remaining: Branch | undefined
    let addAfter: Item[] = [], addBefore: Item[] = []

    this.items.forEach((item, i) => {
      if (!item.step) {
        if (!remap) {
          remap = this.remapping(end, i + 1)
          mapFrom = remap.maps.length
        }
        mapFrom!--
        addBefore.push(item)
        return
      }

      if (remap) {
        addBefore.push(new Item(item.map))
        let step = item.step.map(remap.slice(mapFrom)), map

        if (step && transform.maybeStep(step).doc) {
          map = transform.mapping.maps[transform.mapping.maps.length - 1]
          addAfter.push(new Item(map, undefined, undefined, addAfter.length + addBefore.length))
        }
        mapFrom!--
        if (map) remap.appendMap(map, mapFrom)
      } else {
        transform.maybeStep(item.step)
      }

      if (item.selection) {
        selection = remap ? item.selection.map(remap.slice(mapFrom)) : item.selection
        remaining = new Branch(this.items.slice(0, end).append(addBefore.reverse().concat(addAfter)), this.eventCount - 1)
        return false
      }
    }, this.items.length, 0)

    return {remaining: remaining!, transform, selection: selection!}
  }

  // Create a new branch with the given transform added.
  addTransform(transform: Transform, selection: SelectionBookmark | undefined,
               histOptions: Required<HistoryOptions>, preserveItems: boolean) {
    let newItems = [], eventCount = this.eventCount
    let oldItems = this.items, lastItem = !preserveItems && oldItems.length ? oldItems.get(oldItems.length - 1) : null

    for (let i = 0; i < transform.steps.length; i++) {
      let step = transform.steps[i].invert(transform.docs[i])
      let item = new Item(transform.mapping.maps[i], step, selection), merged
      if (merged = lastItem && lastItem.merge(item)) {
        item = merged
        if (i) newItems.pop()
        else oldItems = oldItems.slice(0, oldItems.length - 1)
      }
      newItems.push(item)
      if (selection) {
        eventCount++
        selection = undefined
      }
      if (!preserveItems) lastItem = item
    }
    let overflow = eventCount - histOptions.depth
    if (overflow > DEPTH_OVERFLOW) {
      oldItems = cutOffEvents(oldItems, overflow)
      eventCount -= overflow
    }
    return new Branch(oldItems.append(newItems), eventCount)
  }

  remapping(from: number, to: number): Mapping {
    let maps = new Mapping
    this.items.forEach((item, i) => {
      let mirrorPos = item.mirrorOffset != null && i - item.mirrorOffset >= from
          ? maps.maps.length - item.mirrorOffset : undefined
      maps.appendMap(item.map, mirrorPos)
    }, from, to)
    return maps
  }

  addMaps(array: readonly StepMap[]) {
    if (this.eventCount == 0) return this
    return new Branch(this.items.append(array.map(map => new Item(map))), this.eventCount)
  }

  // When the collab module receives remote changes, the history has
  // to know about those, so that it can adjust the steps that were
  // rebased on top of the remote changes, and include the position
  // maps for the remote changes in its array of items.
  rebased(rebasedTransform: Transform, rebasedCount: number) {
    if (!this.eventCount) return this

    let rebasedItems: Item[] = [], start = Math.max(0, this.items.length - rebasedCount)

    let mapping = rebasedTransform.mapping
    let newUntil = rebasedTransform.steps.length
    let eventCount = this.eventCount
    this.items.forEach(item => { if (item.selection) eventCount-- }, start)

    let iRebased = rebasedCount
    this.items.forEach(item => {
      let pos = mapping.getMirror(--iRebased)
      if (pos == null) return
      newUntil = Math.min(newUntil, pos)
      let map = mapping.maps[pos]
      if (item.step) {
        let step = rebasedTransform.steps[pos].invert(rebasedTransform.docs[pos])
        let selection = item.selection && item.selection.map(mapping.slice(iRebased + 1, pos))
        if (selection) eventCount++
        rebasedItems.push(new Item(map, step, selection))
      } else {
        rebasedItems.push(new Item(map))
      }
    }, start)

    let newMaps = []
    for (let i = rebasedCount; i < newUntil; i++)
      newMaps.push(new Item(mapping.maps[i]))
    let items = this.items.slice(0, start).append(newMaps).append(rebasedItems)
    let branch = new Branch(items, eventCount)

    if (branch.emptyItemCount() > max_empty_items)
      branch = branch.compress(this.items.length - rebasedItems.length)
    return branch
  }

  emptyItemCount() {
    let count = 0
    this.items.forEach(item => { if (!item.step) count++ })
    return count
  }

  // Compressing a branch means rewriting it to push the air (map-only
  // items) out. During collaboration, these naturally accumulate
  // because each remote change adds one. The `upto` argument is used
  // to ensure that only the items below a given level are compressed,
  // because `rebased` relies on a clean, untouched set of items in
  // order to associate old items with rebased steps.
  compress(upto = this.items.length) {
    let remap = this.remapping(0, upto), mapFrom = remap.maps.length
    let items: Item[] = [], events = 0
    this.items.forEach((item, i) => {
      if (i >= upto) {
        items.push(item)
        if (item.selection) events++
      } else if (item.step) {
        let step = item.step.map(remap.slice(mapFrom)), map = step && step.getMap()
        mapFrom--
        if (map) remap.appendMap(map, mapFrom)
        if (step) {
          let selection = item.selection && item.selection.map(remap.slice(mapFrom))
          if (selection) events++
          let newItem = new Item(map!.invert(), step, selection), merged, last = items.length - 1
          if (merged = items.length && items[last].merge(newItem))
            items[last] = merged
          else
            items.push(newItem)
        }
      } else if (item.map) {
        mapFrom--
      }
    }, this.items.length, 0)
    return new Branch(RopeSequence.from(items.reverse()), events)
  }

  static empty = new Branch(RopeSequence.empty, 0)
}

function cutOffEvents(items: RopeSequence<Item>, n: number) {
  let cutPoint: number | undefined
  items.forEach((item, i) => {
    if (item.selection && (n-- == 0)) {
      cutPoint = i
      return false
    }
  })
  return items.slice(cutPoint!)
}

class Item {
  constructor(
    // The (forward) step map for this item.
    readonly map: StepMap,
    // The inverted step
    readonly step?: Step,
    // If this is non-null, this item is the start of a group, and
    // this selection is the starting selection for the group (the one
    // that was active before the first step was applied)
    readonly selection?: SelectionBookmark,
    // If this item is the inverse of a previous mapping on the stack,
    // this points at the inverse's offset
    readonly mirrorOffset?: number
  ) {}

  merge(other: Item) {
    if (this.step && other.step && !other.selection) {
      let step = other.step.merge(this.step)
      if (step) return new Item(step.getMap().invert(), step, this.selection)
    }
  }
}

// The value of the state field that tracks undo/redo history for that
// state. Will be stored in the plugin state when the history plugin
// is active.
class HistoryState {
  constructor(
    readonly done: Branch,
    readonly undone: Branch,
    readonly prevRanges: readonly number[] | null,
    readonly prevTime: number,
    readonly prevComposition: number
  ) {}
}

const DEPTH_OVERFLOW = 20

// Record a transformation in undo history.
function applyTransaction(history: HistoryState, state: EditorState, tr: Transaction, options: Required<HistoryOptions>) {
  let historyTr = tr.getMeta(historyKey), rebased
  if (historyTr) return historyTr.historyState

  if (tr.getMeta(closeHistoryKey)) history = new HistoryState(history.done, history.undone, null, 0, -1)

  let appended = tr.getMeta("appendedTransaction")

  if (tr.steps.length == 0) {
    return history
  } else if (appended && appended.getMeta(historyKey)) {
    if (appended.getMeta(historyKey).redo)
      return new HistoryState(history.done.addTransform(tr, undefined, options, mustPreserveItems(state)),
                              history.undone, rangesFor(tr.mapping.maps),
                              history.prevTime, history.prevComposition)
    else
      return new HistoryState(history.done, history.undone.addTransform(tr, undefined, options, mustPreserveItems(state)),
                              null, history.prevTime, history.prevComposition)
  } else if (tr.getMeta("addToHistory") !== false && !(appended && appended.getMeta("addToHistory") === false)) {
    // Group transforms that occur in quick succession into one event.
    let composition = tr.getMeta("composition")
    let newGroup = history.prevTime == 0 ||
      (!appended && history.prevComposition != composition &&
       (history.prevTime < (tr.time || 0) - options.newGroupDelay || !isAdjacentTo(tr, history.prevRanges!)))
    let prevRanges = appended ? mapRanges(history.prevRanges!, tr.mapping) : rangesFor(tr.mapping.maps)
    return new HistoryState(history.done.addTransform(tr, newGroup ? state.selection.getBookmark() : undefined,
                                                      options, mustPreserveItems(state)),
                            Branch.empty, prevRanges, tr.time, composition == null ? history.prevComposition : composition)
  } else if (rebased = tr.getMeta("rebased")) {
    // Used by the collab module to tell the history that some of its
    // content has been rebased.
    return new HistoryState(history.done.rebased(tr, rebased),
                            history.undone.rebased(tr, rebased),
                            mapRanges(history.prevRanges!, tr.mapping), history.prevTime, history.prevComposition)
  } else {
    return new HistoryState(history.done.addMaps(tr.mapping.maps),
                            history.undone.addMaps(tr.mapping.maps),
                            mapRanges(history.prevRanges!, tr.mapping), history.prevTime, history.prevComposition)
  }
}

function isAdjacentTo(transform: Transform, prevRanges: readonly number[]) {
  if (!prevRanges) return false
  if (!transform.docChanged) return true
  let adjacent = false
  transform.mapping.maps[0].forEach((start, end) => {
    for (let i = 0; i < prevRanges.length; i += 2)
      if (start <= prevRanges[i + 1] && end >= prevRanges[i])
        adjacent = true
  })
  return adjacent
}

function rangesFor(maps: readonly StepMap[]) {
  let result: number[] = []
  for (let i = maps.length - 1; i >= 0 && result.length == 0; i--)
    maps[i].forEach((_from, _to, from, to) => result.push(from, to))
  return result
}

function mapRanges(ranges: readonly number[], mapping: Mapping) {
  if (!ranges) return null
  let result = []
  for (let i = 0; i < ranges.length; i += 2) {
    let from = mapping.map(ranges[i], 1), to = mapping.map(ranges[i + 1], -1)
    if (from <= to) result.push(from, to)
  }
  return result
}

// Apply the latest event from one branch to the document and shift the event
// onto the other branch.
function histTransaction(history: HistoryState, state: EditorState, redo: boolean): Transaction | null {
  let preserveItems = mustPreserveItems(state)
  let histOptions = (historyKey.get(state)!.spec as any).config as Required<HistoryOptions>
  let pop = (redo ? history.undone : history.done).popEvent(state, preserveItems)
  if (!pop) return null

  let selection = pop.selection!.resolve(pop.transform.doc)
  let added = (redo ? history.done : history.undone).addTransform(pop.transform, state.selection.getBookmark(),
                                                                  histOptions, preserveItems)

  let newHist = new HistoryState(redo ? added : pop.remaining, redo ? pop.remaining : added, null, 0, -1)
  return pop.transform.setSelection(selection).setMeta(historyKey, {redo, historyState: newHist})
}

let cachedPreserveItems = false, cachedPreserveItemsPlugins: readonly Plugin[] | null = null
// Check whether any plugin in the given state has a
// `historyPreserveItems` property in its spec, in which case we must
// preserve steps exactly as they came in, so that they can be
// rebased.
function mustPreserveItems(state: EditorState) {
  let plugins = state.plugins
  if (cachedPreserveItemsPlugins != plugins) {
    cachedPreserveItems = false
    cachedPreserveItemsPlugins = plugins
    for (let i = 0; i < plugins.length; i++) if ((plugins[i].spec as any).historyPreserveItems) {
      cachedPreserveItems = true
      break
    }
  }
  return cachedPreserveItems
}

/// Set a flag on the given transaction that will prevent further steps
/// from being appended to an existing history event (so that they
/// require a separate undo command to undo).
export function closeHistory(tr: Transaction) {
  return tr.setMeta(closeHistoryKey, true)
}

const historyKey = new PluginKey("history")
const closeHistoryKey = new PluginKey("closeHistory")

interface HistoryOptions {
  /// The amount of history events that are collected before the
  /// oldest events are discarded. Defaults to 100.
  depth?: number

  /// The delay between changes after which a new group should be
  /// started. Defaults to 500 (milliseconds). Note that when changes
  /// aren't adjacent, a new group is always started.
  newGroupDelay?: number
}

/// Returns a plugin that enables the undo history for an editor. The
/// plugin will track undo and redo stacks, which can be used with the
/// [`undo`](#history.undo) and [`redo`](#history.redo) commands.
///
/// You can set an `"addToHistory"` [metadata
/// property](#state.Transaction.setMeta) of `false` on a transaction
/// to prevent it from being rolled back by undo.
export function history(config: HistoryOptions = {}): Plugin {
  config = {depth: config.depth || 100,
            newGroupDelay: config.newGroupDelay || 500}

  return new Plugin({
    key: historyKey,

    state: {
      init() {
        return new HistoryState(Branch.empty, Branch.empty, null, 0, -1)
      },
      apply(tr, hist, state) {
        return applyTransaction(hist, state, tr, config as Required<HistoryOptions>)
      }
    },

    config,

    props: {
      handleDOMEvents: {
        beforeinput(view, e: Event) {
          let inputType = (e as InputEvent).inputType
          let command = inputType == "historyUndo" ? undo : inputType == "historyRedo" ? redo : null
          if (!command) return false
          e.preventDefault()
          return command(view.state, view.dispatch)
        }
      }
    }
  })
}

function buildCommand(redo: boolean, scroll: boolean): Command {
  return (state, dispatch) => {
    let hist = historyKey.getState(state)
    if (!hist || (redo ? hist.undone : hist.done).eventCount == 0) return false
    if (dispatch) {
      let tr = histTransaction(hist, state, redo)
      if (tr) dispatch(scroll ? tr.scrollIntoView() : tr)
    }
    return true
  }
}

/// A command function that undoes the last change, if any.
export const undo = buildCommand(false, true)

/// A command function that redoes the last undone change, if any.
export const redo = buildCommand(true, true)

/// A command function that undoes the last change. Don't scroll the
/// selection into view.
export const undoNoScroll = buildCommand(false, false)

/// A command function that redoes the last undone change. Don't
/// scroll the selection into view.
export const redoNoScroll = buildCommand(true, false)

/// The amount of undoable events available in a given state.
export function undoDepth(state: EditorState) {
  let hist = historyKey.getState(state)
  return hist ? hist.done.eventCount : 0
}

/// The amount of redoable events available in a given editor state.
export function redoDepth(state: EditorState) {
  let hist = historyKey.getState(state)
  return hist ? hist.undone.eventCount : 0
}
