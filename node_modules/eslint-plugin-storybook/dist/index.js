"use strict";
/**
 * @fileoverview Best practice rules for Storybook
 * @author Yann Braga
 */
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.configs = exports.rules = void 0;
//------------------------------------------------------------------------------
// Requirements
//------------------------------------------------------------------------------
const requireindex_1 = __importDefault(require("requireindex"));
//------------------------------------------------------------------------------
// Plugin Definition
//------------------------------------------------------------------------------
// import all rules in lib/rules
exports.rules = (0, requireindex_1.default)(__dirname + '/rules');
exports.configs = (0, requireindex_1.default)(__dirname + '/configs');
