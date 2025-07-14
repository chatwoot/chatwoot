"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const synckit_1 = require("synckit");
const eslint_1 = require("eslint-compat-utils/eslint");
const parse_by_parser_1 = require("./parse-by-parser");
const ESLint = (0, eslint_1.getESLint)();
(0, synckit_1.runAsWorker)(async (cwd, filePath) => {
    const eslint = new ESLint({ cwd });
    const config = await eslint.calculateConfigForFile(filePath);
    const languageOptions = config.languageOptions || {};
    const parserOptions = Object.assign({
        sourceType: languageOptions.sourceType || 'module',
        ecmaVersion: languageOptions.ecmaVersion || 'latest'
    }, languageOptions.parserOptions, {
        loc: true,
        range: true,
        raw: true,
        tokens: true,
        comment: true,
        eslintVisitorKeys: true,
        eslintScopeManager: true,
        filePath
    });
    const result = (0, parse_by_parser_1.parseByParser)(filePath, languageOptions.parser, parserOptions);
    if (!result) {
        return null;
    }
    return {
        ast: result.ast,
        visitorKeys: result === null || result === void 0 ? void 0 : result.visitorKeys
    };
});
