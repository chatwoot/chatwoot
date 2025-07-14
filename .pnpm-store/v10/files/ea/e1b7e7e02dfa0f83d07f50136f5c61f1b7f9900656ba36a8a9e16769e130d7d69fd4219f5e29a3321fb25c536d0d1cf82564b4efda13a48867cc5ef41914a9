"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.Group = void 0;
var inherits_1 = __importDefault(require("inherits"));
var is_email_1 = __importDefault(require("./is-email"));
var new_date_1 = __importDefault(require("new-date"));
var facade_1 = require("./facade");
function Group(dictionary, opts) {
    facade_1.Facade.call(this, dictionary, opts);
}
exports.Group = Group;
inherits_1.default(Group, facade_1.Facade);
var g = Group.prototype;
g.action = function () {
    return "group";
};
g.type = g.action;
g.groupId = facade_1.Facade.field("groupId");
g.created = function () {
    var created = this.proxy("traits.createdAt") ||
        this.proxy("traits.created") ||
        this.proxy("properties.createdAt") ||
        this.proxy("properties.created");
    if (created)
        return new_date_1.default(created);
};
g.email = function () {
    var email = this.proxy("traits.email");
    if (email)
        return email;
    var groupId = this.groupId();
    if (is_email_1.default(groupId))
        return groupId;
};
g.traits = function (aliases) {
    var ret = this.properties();
    var id = this.groupId();
    aliases = aliases || {};
    if (id)
        ret.id = id;
    for (var alias in aliases) {
        if (Object.prototype.hasOwnProperty.call(aliases, alias)) {
            var value = this[alias] == null
                ? this.proxy("traits." + alias)
                : this[alias]();
            if (value == null)
                continue;
            ret[aliases[alias]] = value;
            delete ret[alias];
        }
    }
    return ret;
};
g.name = facade_1.Facade.proxy("traits.name");
g.industry = facade_1.Facade.proxy("traits.industry");
g.employees = facade_1.Facade.proxy("traits.employees");
g.properties = function () {
    return this.field("traits") || this.field("properties") || {};
};
//# sourceMappingURL=group.js.map