"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.Alias = void 0;
var inherits_1 = __importDefault(require("inherits"));
var facade_1 = require("./facade");
function Alias(dictionary, opts) {
    facade_1.Facade.call(this, dictionary, opts);
}
exports.Alias = Alias;
inherits_1.default(Alias, facade_1.Facade);
Alias.prototype.action = function () {
    return "alias";
};
Alias.prototype.type = Alias.prototype.action;
Alias.prototype.previousId = function () {
    return this.field("previousId") || this.field("from");
};
Alias.prototype.from = Alias.prototype.previousId;
Alias.prototype.userId = function () {
    return this.field("userId") || this.field("to");
};
Alias.prototype.to = Alias.prototype.userId;
//# sourceMappingURL=alias.js.map