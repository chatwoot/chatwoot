"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
var setupEventHandler_1 = __importDefault(require("./setupEventHandler"));
var setupPropHandler_1 = __importDefault(require("./setupPropHandler"));
var setupExposedHandler_1 = __importDefault(require("./setupExposedHandler"));
exports.default = [setupEventHandler_1.default, setupPropHandler_1.default, setupExposedHandler_1.default];
