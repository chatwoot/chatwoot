"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (Object.hasOwnProperty.call(mod, k)) result[k] = mod[k];
    result["default"] = mod;
    return result;
};
Object.defineProperty(exports, "__esModule", { value: true });
// tslint:disable:no-console
var commander_1 = __importDefault(require("commander"));
var editorconfig = __importStar(require("./"));
var package_json_1 = __importDefault(require("../package.json"));
function cli(args) {
    commander_1.default.version('EditorConfig Node.js Core Version ' + package_json_1.default.version);
    commander_1.default
        .usage([
        '[OPTIONS] FILEPATH1 [FILEPATH2 FILEPATH3 ...]',
        commander_1.default._version,
        'FILEPATH can be a hyphen (-) if you want path(s) to be read from stdin.',
    ].join('\n\n  '))
        .option('-f <path>', 'Specify conf filename other than \'.editorconfig\'')
        .option('-b <version>', 'Specify version (used by devs to test compatibility)')
        .option('-v, --version', 'Display version information')
        .parse(args);
    // Throw away the native -V flag in lieu of the one we've manually specified
    // to adhere to testing requirements
    commander_1.default.options.shift();
    var files = commander_1.default.args;
    if (!files.length) {
        commander_1.default.help();
    }
    files
        .map(function (filePath) { return editorconfig.parse(filePath, {
        config: commander_1.default.F,
        version: commander_1.default.B,
    }); })
        .forEach(function (parsing, i, _a) {
        var length = _a.length;
        parsing.then(function (parsed) {
            if (length > 1) {
                console.log("[" + files[i] + "]");
            }
            Object.keys(parsed).forEach(function (key) {
                console.log(key + "=" + parsed[key]);
            });
        });
    });
}
exports.default = cli;
