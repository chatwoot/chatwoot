"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.buildParserUsingLegacyConfig = void 0;
const eslintrc_1 = require("@eslint/eslintrc");
const path_1 = __importDefault(require("path"));
const parse_by_parser_1 = require("./parse-by-parser");
const { CascadingConfigArrayFactory } = eslintrc_1.Legacy;
function buildParserUsingLegacyConfig(cwd) {
    const configArrayFactory = new CascadingConfigArrayFactory({
        additionalPluginPool: new Map([
            ['@intlify/vue-i18n', require('../../index')]
        ]),
        cwd,
        getEslintRecommendedConfig() {
            return {};
        },
        getEslintAllConfig() {
            return {};
        }
    });
    function getConfigForFile(filePath) {
        const absolutePath = path_1.default.resolve(cwd, filePath);
        return configArrayFactory
            .getConfigArrayForFile(absolutePath)
            .extractConfig(absolutePath)
            .toCompatibleObjectAsConfigFileContent();
    }
    return (filePath) => {
        const config = getConfigForFile(filePath);
        const parserOptions = Object.assign({}, config.parserOptions, {
            loc: true,
            range: true,
            raw: true,
            tokens: true,
            comment: true,
            eslintVisitorKeys: true,
            eslintScopeManager: true,
            filePath
        });
        return (0, parse_by_parser_1.parseByParser)(filePath, config.parser, parserOptions);
    };
}
exports.buildParserUsingLegacyConfig = buildParserUsingLegacyConfig;
