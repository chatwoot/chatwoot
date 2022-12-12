/** @typedef {import("webpack/lib/Compilation.js")} WebpackCompilation */
/** @typedef {{timestamp: number, fileDependencies: string[]}} Snapshot */
'use strict';

/**
 *
 * @param {{fileDependencies: string[], contextDependencies: string[], missingDependencies: string[]}} fileDependencies
 * @param {WebpackCompilation} compilation
 * @param {number} startTime
 */
function createSnapshot (fileDependencies, compilation, startTime) {
  const flatDependencies = [];
  Object.keys(fileDependencies).forEach((depencyTypes) => {
    fileDependencies[depencyTypes].forEach(fileDependency => {
      flatDependencies.push(fileDependency);
    });
  });
  return {
    fileDependencies: flatDependencies,
    timestamp: startTime
  };
}

/**
 * Returns true if the files inside this snapshot
 * have not been changed
 *
 * @param {Snapshot} snapshot
 * @param {WebpackCompilation} compilation
 * @returns {Promise<boolean>}
 */
function isSnapShotValid (snapshot, compilation) {
  // Check if any dependent file was changed after the last compilation
  const fileTimestamps = compilation.fileTimestamps;
  const isCacheOutOfDate = snapshot.fileDependencies.some((fileDependency) => {
    const timestamp = fileTimestamps.get(fileDependency);
    // If the timestamp is not known the file is new
    // If the timestamp is larger then the file has changed
    // Otherwise the file is still the same
    return !timestamp || timestamp > snapshot.timestamp;
  });
  return Promise.resolve(!isCacheOutOfDate);
}

/**
 * Ensure that the files keep watched for changes
 * and will trigger a recompile
 *
 * @param {WebpackCompilation} mainCompilation
 * @param {{fileDependencies: string[], contextDependencies: string[], missingDependencies: string[]}} fileDependencies
 */
function watchFiles (mainCompilation, fileDependencies) {
  Object.keys(fileDependencies).forEach((depencyTypes) => {
    fileDependencies[depencyTypes].forEach(fileDependency => {
      mainCompilation.compilationDependencies.add(fileDependency);
    });
  });
}

module.exports = {
  createSnapshot,
  isSnapShotValid,
  watchFiles
};
