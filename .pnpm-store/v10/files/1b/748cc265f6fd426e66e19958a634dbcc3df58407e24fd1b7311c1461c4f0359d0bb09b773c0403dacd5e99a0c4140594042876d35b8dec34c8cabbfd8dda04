"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.parseAllDocsToCST = void 0;
const yaml_1 = require("yaml");
/** Parse yaml to CST */
function parseAllDocsToCST(ctx) {
    const parser = new yaml_1.Parser();
    const composer = new yaml_1.Composer(Object.assign(Object.assign({}, ctx.options), { keepSourceTokens: true }));
    const cstNodes = [];
    const nodes = [];
    /**
     * Process for Document
     */
    function processDoc(node) {
        for (const error of node.errors) {
            throw ctx.throwError(error.message, error.pos[0]);
        }
        // ignore warns
        // for (const error of doc.warnings) {
        //     throw ctx.throwError(error.message, error.pos[0])
        // }
        nodes.push(node);
    }
    for (const cst of parser.parse(ctx.code)) {
        cstNodes.push(cst);
        for (const doc of composer.next(cst)) {
            processDoc(doc);
        }
    }
    for (const doc of composer.end()) {
        processDoc(doc);
    }
    return { nodes, cstNodes, streamInfo: composer.streamInfo() };
}
exports.parseAllDocsToCST = parseAllDocsToCST;
