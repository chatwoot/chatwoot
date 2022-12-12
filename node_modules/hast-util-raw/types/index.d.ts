// Minimum TypeScript Version: 3.2

import {Node} from 'hast'
import {VFile} from 'vfile'

/**
 * Given a hast tree and an optional vfile (for positional info), return a new parsed-again hast tree.
 * @param tree original hast tree
 * @param file positional info
 */
declare function raw(tree: Node, file?: VFile): Node

export = raw
