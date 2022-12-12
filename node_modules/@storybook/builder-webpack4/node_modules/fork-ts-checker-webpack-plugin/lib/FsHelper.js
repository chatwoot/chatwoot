"use strict";
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (Object.hasOwnProperty.call(mod, k)) result[k] = mod[k];
    result["default"] = mod;
    return result;
};
Object.defineProperty(exports, "__esModule", { value: true });
var fs = __importStar(require("fs"));
function fileExistsSync(filePath) {
    try {
        fs.statSync(filePath);
    }
    catch (err) {
        if (err.code === 'ENOENT') {
            return false;
        }
        else {
            throw err;
        }
    }
    return true;
}
exports.fileExistsSync = fileExistsSync;
// eslint-disable-next-line @typescript-eslint/no-explicit-any
function throwIfIsInvalidSourceFileError(filepath, error) {
    if (fileExistsSync(filepath) &&
        // check the error type due to file system lag
        !(error instanceof Error) &&
        !(error.constructor.name === 'FatalError') &&
        !(error.message && error.message.trim().startsWith('Invalid source file'))) {
        // it's not because file doesn't exist - throw error
        throw error;
    }
}
exports.throwIfIsInvalidSourceFileError = throwIfIsInvalidSourceFileError;
//# sourceMappingURL=FsHelper.js.map