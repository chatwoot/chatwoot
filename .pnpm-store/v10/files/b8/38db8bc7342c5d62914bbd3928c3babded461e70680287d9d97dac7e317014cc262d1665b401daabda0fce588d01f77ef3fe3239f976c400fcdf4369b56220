"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getRelativePath = exports.convertPathToPosix = void 0;
const path_1 = require("path");
function convertPathToPosix(filepath) {
    const normalizedFilepath = (0, path_1.normalize)(filepath);
    const posixFilepath = normalizedFilepath.replace(/\\/g, '/');
    return posixFilepath;
}
exports.convertPathToPosix = convertPathToPosix;
function getRelativePath(filepath, baseDir) {
    const absolutePath = (0, path_1.isAbsolute)(filepath) ? filepath : (0, path_1.resolve)(filepath);
    if (baseDir) {
        if (!(0, path_1.isAbsolute)(baseDir)) {
            throw new Error(`baseDir should be an absolute path: ${baseDir}`);
        }
        return (0, path_1.relative)(baseDir, absolutePath);
    }
    return absolutePath.replace(/^\//, '');
}
exports.getRelativePath = getRelativePath;
