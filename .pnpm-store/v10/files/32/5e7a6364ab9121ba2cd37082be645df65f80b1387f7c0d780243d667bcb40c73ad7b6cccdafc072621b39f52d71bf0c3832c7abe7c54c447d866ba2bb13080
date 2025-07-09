"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.buildParserFromConfig = void 0;
const should_use_flat_config_1 = require("./should-use-flat-config");
const build_parser_using_legacy_config_1 = require("./build-parser-using-legacy-config");
const build_parser_using_flat_config_1 = require("./build-parser-using-flat-config");
const parsers = {};
function buildParserFromConfig(cwd) {
    const parser = parsers[cwd];
    if (parser) {
        return parser;
    }
    if ((0, should_use_flat_config_1.shouldUseFlatConfig)(cwd)) {
        return (parsers[cwd] = (0, build_parser_using_flat_config_1.buildParserUsingFlatConfig)(cwd));
    }
    return (parsers[cwd] = (0, build_parser_using_legacy_config_1.buildParserUsingLegacyConfig)(cwd));
}
exports.buildParserFromConfig = buildParserFromConfig;
