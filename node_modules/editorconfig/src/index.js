"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : new P(function (resolve) { resolve(result.value); }).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __generator = (this && this.__generator) || function (thisArg, body) {
    var _ = { label: 0, sent: function() { if (t[0] & 1) throw t[1]; return t[1]; }, trys: [], ops: [] }, f, y, t, g;
    return g = { next: verb(0), "throw": verb(1), "return": verb(2) }, typeof Symbol === "function" && (g[Symbol.iterator] = function() { return this; }), g;
    function verb(n) { return function (v) { return step([n, v]); }; }
    function step(op) {
        if (f) throw new TypeError("Generator is already executing.");
        while (_) try {
            if (f = 1, y && (t = op[0] & 2 ? y["return"] : op[0] ? y["throw"] || ((t = y["return"]) && t.call(y), 0) : y.next) && !(t = t.call(y, op[1])).done) return t;
            if (y = 0, t) op = [op[0] & 2, t.value];
            switch (op[0]) {
                case 0: case 1: t = op; break;
                case 4: _.label++; return { value: op[1], done: false };
                case 5: _.label++; y = op[1]; op = [0]; continue;
                case 7: op = _.ops.pop(); _.trys.pop(); continue;
                default:
                    if (!(t = _.trys, t = t.length > 0 && t[t.length - 1]) && (op[0] === 6 || op[0] === 2)) { _ = 0; continue; }
                    if (op[0] === 3 && (!t || (op[1] > t[0] && op[1] < t[3]))) { _.label = op[1]; break; }
                    if (op[0] === 6 && _.label < t[1]) { _.label = t[1]; t = op; break; }
                    if (t && _.label < t[2]) { _.label = t[2]; _.ops.push(op); break; }
                    if (t[2]) _.ops.pop();
                    _.trys.pop(); continue;
            }
            op = body.call(thisArg, _);
        } catch (e) { op = [6, e]; y = 0; } finally { f = t = 0; }
        if (op[0] & 5) throw op[1]; return { value: op[0] ? op[1] : void 0, done: true };
    }
};
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (Object.hasOwnProperty.call(mod, k)) result[k] = mod[k];
    result["default"] = mod;
    return result;
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
var fs = __importStar(require("fs"));
var path = __importStar(require("path"));
var semver = __importStar(require("semver"));
var fnmatch_1 = __importDefault(require("./lib/fnmatch"));
var ini_1 = require("./lib/ini");
exports.parseString = ini_1.parseString;
var package_json_1 = __importDefault(require("../package.json"));
var knownProps = {
    end_of_line: true,
    indent_style: true,
    indent_size: true,
    insert_final_newline: true,
    trim_trailing_whitespace: true,
    charset: true,
};
function fnmatch(filepath, glob) {
    var matchOptions = { matchBase: true, dot: true, noext: true };
    glob = glob.replace(/\*\*/g, '{*,**/**/**}');
    return fnmatch_1.default(filepath, glob, matchOptions);
}
function getConfigFileNames(filepath, options) {
    var paths = [];
    do {
        filepath = path.dirname(filepath);
        paths.push(path.join(filepath, options.config));
    } while (filepath !== options.root);
    return paths;
}
function processMatches(matches, version) {
    // Set indent_size to 'tab' if indent_size is unspecified and
    // indent_style is set to 'tab'.
    if ('indent_style' in matches
        && matches.indent_style === 'tab'
        && !('indent_size' in matches)
        && semver.gte(version, '0.10.0')) {
        matches.indent_size = 'tab';
    }
    // Set tab_width to indent_size if indent_size is specified and
    // tab_width is unspecified
    if ('indent_size' in matches
        && !('tab_width' in matches)
        && matches.indent_size !== 'tab') {
        matches.tab_width = matches.indent_size;
    }
    // Set indent_size to tab_width if indent_size is 'tab'
    if ('indent_size' in matches
        && 'tab_width' in matches
        && matches.indent_size === 'tab') {
        matches.indent_size = matches.tab_width;
    }
    return matches;
}
function processOptions(options, filepath) {
    if (options === void 0) { options = {}; }
    return {
        config: options.config || '.editorconfig',
        version: options.version || package_json_1.default.version,
        root: path.resolve(options.root || path.parse(filepath).root),
    };
}
function buildFullGlob(pathPrefix, glob) {
    switch (glob.indexOf('/')) {
        case -1:
            glob = '**/' + glob;
            break;
        case 0:
            glob = glob.substring(1);
            break;
        default:
            break;
    }
    return path.join(pathPrefix, glob);
}
function extendProps(props, options) {
    if (props === void 0) { props = {}; }
    if (options === void 0) { options = {}; }
    for (var key in options) {
        if (options.hasOwnProperty(key)) {
            var value = options[key];
            var key2 = key.toLowerCase();
            var value2 = value;
            if (knownProps[key2]) {
                value2 = value.toLowerCase();
            }
            try {
                value2 = JSON.parse(value);
            }
            catch (e) { }
            if (typeof value === 'undefined' || value === null) {
                // null and undefined are values specific to JSON (no special meaning
                // in editorconfig) & should just be returned as regular strings.
                value2 = String(value);
            }
            props[key2] = value2;
        }
    }
    return props;
}
function parseFromConfigs(configs, filepath, options) {
    return processMatches(configs
        .reverse()
        .reduce(function (matches, file) {
        var pathPrefix = path.dirname(file.name);
        file.contents.forEach(function (section) {
            var glob = section[0];
            var options2 = section[1];
            if (!glob) {
                return;
            }
            var fullGlob = buildFullGlob(pathPrefix, glob);
            if (!fnmatch(filepath, fullGlob)) {
                return;
            }
            matches = extendProps(matches, options2);
        });
        return matches;
    }, {}), options.version);
}
function getConfigsForFiles(files) {
    var configs = [];
    for (var i in files) {
        if (files.hasOwnProperty(i)) {
            var file = files[i];
            var contents = ini_1.parseString(file.contents);
            configs.push({
                name: file.name,
                contents: contents,
            });
            if ((contents[0][1].root || '').toLowerCase() === 'true') {
                break;
            }
        }
    }
    return configs;
}
function readConfigFiles(filepaths) {
    return __awaiter(this, void 0, void 0, function () {
        return __generator(this, function (_a) {
            return [2 /*return*/, Promise.all(filepaths.map(function (name) { return new Promise(function (resolve) {
                    fs.readFile(name, 'utf8', function (err, data) {
                        resolve({
                            name: name,
                            contents: err ? '' : data,
                        });
                    });
                }); }))];
        });
    });
}
function readConfigFilesSync(filepaths) {
    var files = [];
    var file;
    filepaths.forEach(function (filepath) {
        try {
            file = fs.readFileSync(filepath, 'utf8');
        }
        catch (e) {
            file = '';
        }
        files.push({
            name: filepath,
            contents: file,
        });
    });
    return files;
}
function opts(filepath, options) {
    if (options === void 0) { options = {}; }
    var resolvedFilePath = path.resolve(filepath);
    return [
        resolvedFilePath,
        processOptions(options, resolvedFilePath),
    ];
}
function parseFromFiles(filepath, files, options) {
    if (options === void 0) { options = {}; }
    return __awaiter(this, void 0, void 0, function () {
        var _a, resolvedFilePath, processedOptions;
        return __generator(this, function (_b) {
            _a = opts(filepath, options), resolvedFilePath = _a[0], processedOptions = _a[1];
            return [2 /*return*/, files.then(getConfigsForFiles)
                    .then(function (configs) { return parseFromConfigs(configs, resolvedFilePath, processedOptions); })];
        });
    });
}
exports.parseFromFiles = parseFromFiles;
function parseFromFilesSync(filepath, files, options) {
    if (options === void 0) { options = {}; }
    var _a = opts(filepath, options), resolvedFilePath = _a[0], processedOptions = _a[1];
    return parseFromConfigs(getConfigsForFiles(files), resolvedFilePath, processedOptions);
}
exports.parseFromFilesSync = parseFromFilesSync;
function parse(_filepath, _options) {
    if (_options === void 0) { _options = {}; }
    return __awaiter(this, void 0, void 0, function () {
        var _a, resolvedFilePath, processedOptions, filepaths;
        return __generator(this, function (_b) {
            _a = opts(_filepath, _options), resolvedFilePath = _a[0], processedOptions = _a[1];
            filepaths = getConfigFileNames(resolvedFilePath, processedOptions);
            return [2 /*return*/, readConfigFiles(filepaths)
                    .then(getConfigsForFiles)
                    .then(function (configs) { return parseFromConfigs(configs, resolvedFilePath, processedOptions); })];
        });
    });
}
exports.parse = parse;
function parseSync(_filepath, _options) {
    if (_options === void 0) { _options = {}; }
    var _a = opts(_filepath, _options), resolvedFilePath = _a[0], processedOptions = _a[1];
    var filepaths = getConfigFileNames(resolvedFilePath, processedOptions);
    var files = readConfigFilesSync(filepaths);
    return parseFromConfigs(getConfigsForFiles(files), resolvedFilePath, processedOptions);
}
exports.parseSync = parseSync;
