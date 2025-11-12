"use strict";
// Portions of this file are derived from getsentry/sentry-javascript by Software, Inc. dba Sentry
// Licensed under the MIT License
Object.defineProperty(exports, "__esModule", { value: true });
exports.getFilenameToChunkIdMap = getFilenameToChunkIdMap;
var parsedStackResults;
var lastKeysCount;
var cachedFilenameChunkIds;
function getFilenameToChunkIdMap(stackParser) {
    var chunkIdMap = globalThis._posthogChunkIds;
    if (!chunkIdMap) {
        return {};
    }
    var chunkIdKeys = Object.keys(chunkIdMap);
    if (cachedFilenameChunkIds && chunkIdKeys.length === lastKeysCount) {
        return cachedFilenameChunkIds;
    }
    lastKeysCount = chunkIdKeys.length;
    cachedFilenameChunkIds = chunkIdKeys.reduce(function (acc, stackKey) {
        if (!parsedStackResults) {
            parsedStackResults = {};
        }
        var result = parsedStackResults[stackKey];
        if (result) {
            acc[result[0]] = result[1];
        }
        else {
            var parsedStack = stackParser(stackKey);
            for (var i = parsedStack.length - 1; i >= 0; i--) {
                var stackFrame = parsedStack[i];
                var filename = stackFrame === null || stackFrame === void 0 ? void 0 : stackFrame.filename;
                var chunkId = chunkIdMap[stackKey];
                if (filename && chunkId) {
                    acc[filename] = chunkId;
                    parsedStackResults[stackKey] = [filename, chunkId];
                    break;
                }
            }
        }
        return acc;
    }, {});
    return cachedFilenameChunkIds;
}
//# sourceMappingURL=chunk-ids.js.map