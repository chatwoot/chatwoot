import {Fragment} from "./fragment"

// ::- Instances of this class represent a match state of a node
// type's [content expression](#model.NodeSpec.content), and can be
// used to find out whether further content matches here, and whether
// a given position is a valid end of the node.
export class ContentMatch {
  constructor(validEnd) {
    // :: bool
    // True when this match state represents a valid end of the node.
    this.validEnd = validEnd
    this.next = []
    this.wrapCache = []
  }

  static parse(string, nodeTypes) {
    let stream = new TokenStream(string, nodeTypes)
    if (stream.next == null) return ContentMatch.empty
    let expr = parseExpr(stream)
    if (stream.next) stream.err("Unexpected trailing text")
    let match = dfa(nfa(expr))
    checkForDeadEnds(match, stream)
    return match
  }

  // :: (NodeType) → ?ContentMatch
  // Match a node type, returning a match after that node if
  // successful.
  matchType(type) {
    for (let i = 0; i < this.next.length; i += 2)
      if (this.next[i] == type) return this.next[i + 1]
    return null
  }

  // :: (Fragment, ?number, ?number) → ?ContentMatch
  // Try to match a fragment. Returns the resulting match when
  // successful.
  matchFragment(frag, start = 0, end = frag.childCount) {
    let cur = this
    for (let i = start; cur && i < end; i++)
      cur = cur.matchType(frag.child(i).type)
    return cur
  }

  get inlineContent() {
    let first = this.next[0]
    return first ? first.isInline : false
  }

  // :: ?NodeType
  // Get the first matching node type at this match position that can
  // be generated.
  get defaultType() {
    for (let i = 0; i < this.next.length; i += 2) {
      let type = this.next[i]
      if (!(type.isText || type.hasRequiredAttrs())) return type
    }
  }

  compatible(other) {
    for (let i = 0; i < this.next.length; i += 2)
      for (let j = 0; j < other.next.length; j += 2)
        if (this.next[i] == other.next[j]) return true
    return false
  }

  // :: (Fragment, bool, ?number) → ?Fragment
  // Try to match the given fragment, and if that fails, see if it can
  // be made to match by inserting nodes in front of it. When
  // successful, return a fragment of inserted nodes (which may be
  // empty if nothing had to be inserted). When `toEnd` is true, only
  // return a fragment if the resulting match goes to the end of the
  // content expression.
  fillBefore(after, toEnd = false, startIndex = 0) {
    let seen = [this]
    function search(match, types) {
      let finished = match.matchFragment(after, startIndex)
      if (finished && (!toEnd || finished.validEnd))
        return Fragment.from(types.map(tp => tp.createAndFill()))

      for (let i = 0; i < match.next.length; i += 2) {
        let type = match.next[i], next = match.next[i + 1]
        if (!(type.isText || type.hasRequiredAttrs()) && seen.indexOf(next) == -1) {
          seen.push(next)
          let found = search(next, types.concat(type))
          if (found) return found
        }
      }
    }

    return search(this, [])
  }

  // :: (NodeType) → ?[NodeType]
  // Find a set of wrapping node types that would allow a node of the
  // given type to appear at this position. The result may be empty
  // (when it fits directly) and will be null when no such wrapping
  // exists.
  findWrapping(target) {
    for (let i = 0; i < this.wrapCache.length; i += 2)
      if (this.wrapCache[i] == target) return this.wrapCache[i + 1]
    let computed = this.computeWrapping(target)
    this.wrapCache.push(target, computed)
    return computed
  }

  computeWrapping(target) {
    let seen = Object.create(null), active = [{match: this, type: null, via: null}]
    while (active.length) {
      let current = active.shift(), match = current.match
      if (match.matchType(target)) {
        let result = []
        for (let obj = current; obj.type; obj = obj.via)
          result.push(obj.type)
        return result.reverse()
      }
      for (let i = 0; i < match.next.length; i += 2) {
        let type = match.next[i]
        if (!type.isLeaf && !type.hasRequiredAttrs() && !(type.name in seen) && (!current.type || match.next[i + 1].validEnd)) {
          active.push({match: type.contentMatch, type, via: current})
          seen[type.name] = true
        }
      }
    }
  }

  // :: number
  // The number of outgoing edges this node has in the finite
  // automaton that describes the content expression.
  get edgeCount() {
    return this.next.length >> 1
  }

  // :: (number) → {type: NodeType, next: ContentMatch}
  // Get the _n_​th outgoing edge from this node in the finite
  // automaton that describes the content expression.
  edge(n) {
    let i = n << 1
    if (i >= this.next.length) throw new RangeError(`There's no ${n}th edge in this content match`)
    return {type: this.next[i], next: this.next[i + 1]}
  }

  toString() {
    let seen = []
    function scan(m) {
      seen.push(m)
      for (let i = 1; i < m.next.length; i += 2)
        if (seen.indexOf(m.next[i]) == -1) scan(m.next[i])
    }
    scan(this)
    return seen.map((m, i) => {
      let out = i + (m.validEnd ? "*" : " ") + " "
      for (let i = 0; i < m.next.length; i += 2)
        out += (i ? ", " : "") + m.next[i].name + "->" + seen.indexOf(m.next[i + 1])
      return out
    }).join("\n")
  }
}

ContentMatch.empty = new ContentMatch(true)

class TokenStream {
  constructor(string, nodeTypes) {
    this.string = string
    this.nodeTypes = nodeTypes
    this.inline = null
    this.pos = 0
    this.tokens = string.split(/\s*(?=\b|\W|$)/)
    if (this.tokens[this.tokens.length - 1] == "") this.tokens.pop()
    if (this.tokens[0] == "") this.tokens.shift()
  }

  get next() { return this.tokens[this.pos] }

  eat(tok) { return this.next == tok && (this.pos++ || true) }

  err(str) { throw new SyntaxError(str + " (in content expression '" + this.string + "')") }
}

function parseExpr(stream) {
  let exprs = []
  do { exprs.push(parseExprSeq(stream)) }
  while (stream.eat("|"))
  return exprs.length == 1 ? exprs[0] : {type: "choice", exprs}
}

function parseExprSeq(stream) {
  let exprs = []
  do { exprs.push(parseExprSubscript(stream)) }
  while (stream.next && stream.next != ")" && stream.next != "|")
  return exprs.length == 1 ? exprs[0] : {type: "seq", exprs}
}

function parseExprSubscript(stream) {
  let expr = parseExprAtom(stream)
  for (;;) {
    if (stream.eat("+"))
      expr = {type: "plus", expr}
    else if (stream.eat("*"))
      expr = {type: "star", expr}
    else if (stream.eat("?"))
      expr = {type: "opt", expr}
    else if (stream.eat("{"))
      expr = parseExprRange(stream, expr)
    else break
  }
  return expr
}

function parseNum(stream) {
  if (/\D/.test(stream.next)) stream.err("Expected number, got '" + stream.next + "'")
  let result = Number(stream.next)
  stream.pos++
  return result
}

function parseExprRange(stream, expr) {
  let min = parseNum(stream), max = min
  if (stream.eat(",")) {
    if (stream.next != "}") max = parseNum(stream)
    else max = -1
  }
  if (!stream.eat("}")) stream.err("Unclosed braced range")
  return {type: "range", min, max, expr}
}

function resolveName(stream, name) {
  let types = stream.nodeTypes, type = types[name]
  if (type) return [type]
  let result = []
  for (let typeName in types) {
    let type = types[typeName]
    if (type.groups.indexOf(name) > -1) result.push(type)
  }
  if (result.length == 0) stream.err("No node type or group '" + name + "' found")
  return result
}

function parseExprAtom(stream) {
  if (stream.eat("(")) {
    let expr = parseExpr(stream)
    if (!stream.eat(")")) stream.err("Missing closing paren")
    return expr
  } else if (!/\W/.test(stream.next)) {
    let exprs = resolveName(stream, stream.next).map(type => {
      if (stream.inline == null) stream.inline = type.isInline
      else if (stream.inline != type.isInline) stream.err("Mixing inline and block content")
      return {type: "name", value: type}
    })
    stream.pos++
    return exprs.length == 1 ? exprs[0] : {type: "choice", exprs}
  } else {
    stream.err("Unexpected token '" + stream.next + "'")
  }
}

// The code below helps compile a regular-expression-like language
// into a deterministic finite automaton. For a good introduction to
// these concepts, see https://swtch.com/~rsc/regexp/regexp1.html

// : (Object) → [[{term: ?any, to: number}]]
// Construct an NFA from an expression as returned by the parser. The
// NFA is represented as an array of states, which are themselves
// arrays of edges, which are `{term, to}` objects. The first state is
// the entry state and the last node is the success state.
//
// Note that unlike typical NFAs, the edge ordering in this one is
// significant, in that it is used to contruct filler content when
// necessary.
function nfa(expr) {
  let nfa = [[]]
  connect(compile(expr, 0), node())
  return nfa

  function node() { return nfa.push([]) - 1 }
  function edge(from, to, term) {
    let edge = {term, to}
    nfa[from].push(edge)
    return edge
  }
  function connect(edges, to) { edges.forEach(edge => edge.to = to) }

  function compile(expr, from) {
    if (expr.type == "choice") {
      return expr.exprs.reduce((out, expr) => out.concat(compile(expr, from)), [])
    } else if (expr.type == "seq") {
      for (let i = 0;; i++) {
        let next = compile(expr.exprs[i], from)
        if (i == expr.exprs.length - 1) return next
        connect(next, from = node())
      }
    } else if (expr.type == "star") {
      let loop = node()
      edge(from, loop)
      connect(compile(expr.expr, loop), loop)
      return [edge(loop)]
    } else if (expr.type == "plus") {
      let loop = node()
      connect(compile(expr.expr, from), loop)
      connect(compile(expr.expr, loop), loop)
      return [edge(loop)]
    } else if (expr.type == "opt") {
      return [edge(from)].concat(compile(expr.expr, from))
    } else if (expr.type == "range") {
      let cur = from
      for (let i = 0; i < expr.min; i++) {
        let next = node()
        connect(compile(expr.expr, cur), next)
        cur = next
      }
      if (expr.max == -1) {
        connect(compile(expr.expr, cur), cur)
      } else {
        for (let i = expr.min; i < expr.max; i++) {
          let next = node()
          edge(cur, next)
          connect(compile(expr.expr, cur), next)
          cur = next
        }
      }
      return [edge(cur)]
    } else if (expr.type == "name") {
      return [edge(from, null, expr.value)]
    }
  }
}

function cmp(a, b) { return b - a }

// Get the set of nodes reachable by null edges from `node`. Omit
// nodes with only a single null-out-edge, since they may lead to
// needless duplicated nodes.
function nullFrom(nfa, node) {
  let result = []
  scan(node)
  return result.sort(cmp)

  function scan(node) {
    let edges = nfa[node]
    if (edges.length == 1 && !edges[0].term) return scan(edges[0].to)
    result.push(node)
    for (let i = 0; i < edges.length; i++) {
      let {term, to} = edges[i]
      if (!term && result.indexOf(to) == -1) scan(to)
    }
  }
}

// : ([[{term: ?any, to: number}]]) → ContentMatch
// Compiles an NFA as produced by `nfa` into a DFA, modeled as a set
// of state objects (`ContentMatch` instances) with transitions
// between them.
function dfa(nfa) {
  let labeled = Object.create(null)
  return explore(nullFrom(nfa, 0))

  function explore(states) {
    let out = []
    states.forEach(node => {
      nfa[node].forEach(({term, to}) => {
        if (!term) return
        let known = out.indexOf(term), set = known > -1 && out[known + 1]
        nullFrom(nfa, to).forEach(node => {
          if (!set) out.push(term, set = [])
          if (set.indexOf(node) == -1) set.push(node)
        })
      })
    })
    let state = labeled[states.join(",")] = new ContentMatch(states.indexOf(nfa.length - 1) > -1)
    for (let i = 0; i < out.length; i += 2) {
      let states = out[i + 1].sort(cmp)
      state.next.push(out[i], labeled[states.join(",")] || explore(states))
    }
    return state
  }
}

function checkForDeadEnds(match, stream) {
  for (let i = 0, work = [match]; i < work.length; i++) {
    let state = work[i], dead = !state.validEnd, nodes = []
    for (let j = 0; j < state.next.length; j += 2) {
      let node = state.next[j], next = state.next[j + 1]
      nodes.push(node.name)
      if (dead && !(node.isText || node.hasRequiredAttrs())) dead = false
      if (work.indexOf(next) == -1) work.push(next)
    }
    if (dead) stream.err("Only non-generatable nodes (" + nodes.join(", ") + ") in a required position (see https://prosemirror.net/docs/guide/#generatable)")
  }
}
