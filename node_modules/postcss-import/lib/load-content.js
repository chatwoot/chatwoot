"use strict"

const readCache = require("read-cache")

module.exports = filename => readCache(filename, "utf-8")
