"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const path_1 = require("path");
const memfs_1 = require("memfs");
/**
 * It's an implementation of FileSystem interface which reads from the real file system, but write to the in-memory file system.
 *
 * @param caseSensitive
 * @param realFileSystem
 */
function createPassiveFileSystem(caseSensitive = false, realFileSystem) {
    function normalizePath(path) {
        return caseSensitive ? path_1.normalize(path) : path_1.normalize(path).toLowerCase();
    }
    function memExists(path) {
        return memfs_1.fs.existsSync(normalizePath(path));
    }
    function memReadStats(path) {
        return memExists(path) ? memfs_1.fs.statSync(normalizePath(path)) : undefined;
    }
    function memReadFile(path, encoding) {
        const stats = memReadStats(path);
        if (stats && stats.isFile()) {
            return memfs_1.fs
                .readFileSync(normalizePath(path), { encoding: encoding })
                .toString();
        }
    }
    function memReadDir(path) {
        const stats = memReadStats(path);
        if (stats && stats.isDirectory()) {
            return memfs_1.fs.readdirSync(normalizePath(path), { withFileTypes: true });
        }
        return [];
    }
    function exists(path) {
        return realFileSystem.exists(path) || memExists(path);
    }
    function readFile(path, encoding) {
        const fsStats = realFileSystem.readStats(path);
        const memStats = memReadStats(path);
        if (fsStats && memStats) {
            return fsStats.mtimeMs > memStats.mtimeMs
                ? realFileSystem.readFile(path, encoding)
                : memReadFile(path, encoding);
        }
        else if (fsStats) {
            return realFileSystem.readFile(path, encoding);
        }
        else if (memStats) {
            return memReadFile(path, encoding);
        }
    }
    function readDir(path) {
        const fsDirents = realFileSystem.readDir(path);
        const memDirents = memReadDir(path);
        // merge list of dirents from fs and mem
        return fsDirents
            .filter((fsDirent) => !memDirents.some((memDirent) => memDirent.name === fsDirent.name))
            .concat(memDirents);
    }
    function readStats(path) {
        const fsStats = realFileSystem.readStats(path);
        const memStats = memReadStats(path);
        if (fsStats && memStats) {
            return fsStats.mtimeMs > memStats.mtimeMs ? fsStats : memStats;
        }
        else if (fsStats) {
            return fsStats;
        }
        else if (memStats) {
            return memStats;
        }
    }
    function createDir(path) {
        memfs_1.fs.mkdirSync(normalizePath(path), { recursive: true });
    }
    function writeFile(path, data) {
        if (!memExists(path_1.dirname(path))) {
            createDir(path_1.dirname(path));
        }
        memfs_1.fs.writeFileSync(normalizePath(path), data);
    }
    function deleteFile(path) {
        if (memExists(path)) {
            memfs_1.fs.unlinkSync(normalizePath(path));
        }
    }
    function updateTimes(path, atime, mtime) {
        if (memExists(path)) {
            memfs_1.fs.utimesSync(normalizePath(path), atime, mtime);
        }
    }
    return {
        exists(path) {
            return exists(realFileSystem.realPath(path));
        },
        readFile(path, encoding) {
            return readFile(realFileSystem.realPath(path), encoding);
        },
        readDir(path) {
            return readDir(realFileSystem.realPath(path));
        },
        readStats(path) {
            return readStats(realFileSystem.realPath(path));
        },
        realPath(path) {
            return realFileSystem.realPath(path);
        },
        normalizePath(path) {
            return normalizePath(path);
        },
        writeFile(path, data) {
            writeFile(realFileSystem.realPath(path), data);
        },
        deleteFile(path) {
            deleteFile(realFileSystem.realPath(path));
        },
        createDir(path) {
            createDir(realFileSystem.realPath(path));
        },
        updateTimes(path, atime, mtime) {
            updateTimes(realFileSystem.realPath(path), atime, mtime);
        },
        clearCache() {
            realFileSystem.clearCache();
        },
    };
}
exports.createPassiveFileSystem = createPassiveFileSystem;
