const {lstatSync, symlinkSync, renameSync} = require("fs")

let stats
try {
  stats = lstatSync("node_modules/prosemirror-model")
} catch(_) {
  return
}

if (!stats.isSymbolicLink()) {
  renameSync("node_modules/prosemirror-model", "node_modules/prosemirror-model.disabled")
  symlinkSync("..", "node_modules/prosemirror-model", "dir")
}
