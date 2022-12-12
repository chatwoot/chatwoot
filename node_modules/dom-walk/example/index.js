var walk = require("../index")

walk(document, function (node) {
    console.log("node", node)
})
