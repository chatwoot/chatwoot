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
var crypto_1 = __importDefault(require("crypto"));
var fs = __importStar(require("fs"));
var os = __importStar(require("os"));
var path = __importStar(require("path"));
var FsHelper_1 = require("./FsHelper");
var CancellationToken = /** @class */ (function () {
    function CancellationToken(typescript, cancellationFileName, isCancelled) {
        this.typescript = typescript;
        this.isCancelled = !!isCancelled;
        this.cancellationFileName =
            cancellationFileName || crypto_1.default.randomBytes(64).toString('hex');
        this.lastCancellationCheckTime = 0;
    }
    CancellationToken.createFromJSON = function (typescript, json) {
        return new CancellationToken(typescript, json.cancellationFileName, json.isCancelled);
    };
    CancellationToken.prototype.toJSON = function () {
        return {
            cancellationFileName: this.cancellationFileName,
            isCancelled: this.isCancelled
        };
    };
    CancellationToken.prototype.getCancellationFilePath = function () {
        return path.join(os.tmpdir(), this.cancellationFileName);
    };
    CancellationToken.prototype.isCancellationRequested = function () {
        if (this.isCancelled) {
            return true;
        }
        var time = Date.now();
        var duration = Math.abs(time - this.lastCancellationCheckTime);
        if (duration > 10) {
            // check no more than once every 10 ms
            this.lastCancellationCheckTime = time;
            this.isCancelled = FsHelper_1.fileExistsSync(this.getCancellationFilePath());
        }
        return this.isCancelled;
    };
    CancellationToken.prototype.throwIfCancellationRequested = function () {
        if (this.isCancellationRequested()) {
            throw new this.typescript.OperationCanceledException();
        }
    };
    CancellationToken.prototype.requestCancellation = function () {
        fs.writeFileSync(this.getCancellationFilePath(), '');
        this.isCancelled = true;
    };
    CancellationToken.prototype.cleanupCancellation = function () {
        if (this.isCancelled && FsHelper_1.fileExistsSync(this.getCancellationFilePath())) {
            fs.unlinkSync(this.getCancellationFilePath());
            this.isCancelled = false;
        }
    };
    return CancellationToken;
}());
exports.CancellationToken = CancellationToken;
//# sourceMappingURL=CancellationToken.js.map