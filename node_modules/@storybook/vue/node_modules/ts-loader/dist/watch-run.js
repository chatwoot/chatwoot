"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.makeWatchRun = void 0;
const path = require("path");
const constants = require("./constants");
const servicesHost_1 = require("./servicesHost");
const utils_1 = require("./utils");
/**
 * Make function which will manually update changed files
 */
function makeWatchRun(instance, loader) {
    // Called Before starting compilation after watch
    const lastTimes = new Map();
    const startTime = 0;
    // Save the loader index.
    const loaderIndex = loader.loaderIndex;
    return (compiler, callback) => {
        var _a, _b, _c, _d, _e, _f;
        (_b = (_a = instance.servicesHost) === null || _a === void 0 ? void 0 : _a.clearCache) === null || _b === void 0 ? void 0 : _b.call(_a);
        (_d = (_c = instance.watchHost) === null || _c === void 0 ? void 0 : _c.clearCache) === null || _d === void 0 ? void 0 : _d.call(_c);
        (_e = instance.moduleResolutionCache) === null || _e === void 0 ? void 0 : _e.clear();
        (_f = instance.typeReferenceResolutionCache) === null || _f === void 0 ? void 0 : _f.clear();
        const promises = [];
        if (instance.loaderOptions.transpileOnly) {
            instance.reportTranspileErrors = true;
        }
        else {
            const times = compiler.fileTimestamps;
            for (const [filePath, date] of times) {
                const key = instance.filePathKeyMapper(filePath);
                const lastTime = lastTimes.get(key) || startTime;
                if (date <= lastTime) {
                    continue;
                }
                lastTimes.set(key, date);
                promises.push(updateFile(instance, key, filePath, loader, loaderIndex));
            }
            // On watch update add all known dts files expect the ones in node_modules
            // (skip @types/* and modules with typings)
            for (const [key, { fileName }] of instance.files.entries()) {
                if (fileName.match(constants.dtsDtsxOrDtsDtsxMapRegex) !== null &&
                    fileName.match(constants.nodeModules) === null) {
                    promises.push(updateFile(instance, key, fileName, loader, loaderIndex));
                }
            }
        }
        // Update all the watched files from solution builder
        if (instance.solutionBuilderHost) {
            for (const { fileName, } of instance.solutionBuilderHost.watchedFiles.values()) {
                instance.solutionBuilderHost.updateSolutionBuilderInputFile(fileName);
            }
            instance.solutionBuilderHost.clearCache();
        }
        Promise.all(promises)
            .then(() => callback())
            .catch(err => callback(err));
    };
}
exports.makeWatchRun = makeWatchRun;
function updateFile(instance, key, filePath, loader, loaderIndex) {
    return new Promise((resolve, reject) => {
        // When other loaders are specified after ts-loader
        // (e.g. `{ test: /\.ts$/, use: ['ts-loader', 'other-loader'] }`),
        // manually apply them to TypeScript files.
        // Otherwise, files not 'preprocessed' by them may cause complication errors (#1111).
        if (loaderIndex + 1 < loader.loaders.length &&
            instance.rootFileNames.has(path.normalize(filePath))) {
            let request = `!!${path.resolve(__dirname, 'stringify-loader.js')}!`;
            for (let i = loaderIndex + 1; i < loader.loaders.length; ++i) {
                request += loader.loaders[i].request + '!';
            }
            request += filePath;
            loader.loadModule(request, (err, source) => {
                if (err) {
                    reject(err);
                }
                else {
                    const text = JSON.parse(source);
                    servicesHost_1.updateFileWithText(instance, key, filePath, () => text);
                    resolve();
                }
            });
        }
        else {
            servicesHost_1.updateFileWithText(instance, key, filePath, nFilePath => utils_1.fsReadFile(nFilePath) || '');
            resolve();
        }
    });
}
//# sourceMappingURL=watch-run.js.map