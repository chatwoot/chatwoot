"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.Identify = void 0;
var facade_1 = require("./facade");
var obj_case_1 = __importDefault(require("obj-case"));
var inherits_1 = __importDefault(require("inherits"));
var is_email_1 = __importDefault(require("./is-email"));
var new_date_1 = __importDefault(require("new-date"));
var trim = function (str) { return str.trim(); };
function Identify(dictionary, opts) {
    facade_1.Facade.call(this, dictionary, opts);
}
exports.Identify = Identify;
inherits_1.default(Identify, facade_1.Facade);
var i = Identify.prototype;
i.action = function () {
    return "identify";
};
i.type = i.action;
i.traits = function (aliases) {
    var ret = this.field("traits") || {};
    var id = this.userId();
    aliases = aliases || {};
    if (id)
        ret.id = id;
    for (var alias in aliases) {
        var value = this[alias] == null ? this.proxy("traits." + alias) : this[alias]();
        if (value == null)
            continue;
        ret[aliases[alias]] = value;
        if (alias !== aliases[alias])
            delete ret[alias];
    }
    return ret;
};
i.email = function () {
    var email = this.proxy("traits.email");
    if (email)
        return email;
    var userId = this.userId();
    if (is_email_1.default(userId))
        return userId;
};
i.created = function () {
    var created = this.proxy("traits.created") || this.proxy("traits.createdAt");
    if (created)
        return new_date_1.default(created);
};
i.companyCreated = function () {
    var created = this.proxy("traits.company.created") ||
        this.proxy("traits.company.createdAt");
    if (created) {
        return new_date_1.default(created);
    }
};
i.companyName = function () {
    return this.proxy("traits.company.name");
};
i.name = function () {
    var name = this.proxy("traits.name");
    if (typeof name === "string") {
        return trim(name);
    }
    var firstName = this.firstName();
    var lastName = this.lastName();
    if (firstName && lastName) {
        return trim(firstName + " " + lastName);
    }
};
i.firstName = function () {
    var firstName = this.proxy("traits.firstName");
    if (typeof firstName === "string") {
        return trim(firstName);
    }
    var name = this.proxy("traits.name");
    if (typeof name === "string") {
        return trim(name).split(" ")[0];
    }
};
i.lastName = function () {
    var lastName = this.proxy("traits.lastName");
    if (typeof lastName === "string") {
        return trim(lastName);
    }
    var name = this.proxy("traits.name");
    if (typeof name !== "string") {
        return;
    }
    var space = trim(name).indexOf(" ");
    if (space === -1) {
        return;
    }
    return trim(name.substr(space + 1));
};
i.uid = function () {
    return this.userId() || this.username() || this.email();
};
i.description = function () {
    return this.proxy("traits.description") || this.proxy("traits.background");
};
i.age = function () {
    var date = this.birthday();
    var age = obj_case_1.default(this.traits(), "age");
    if (age != null)
        return age;
    if (!(date instanceof Date))
        return;
    var now = new Date();
    return now.getFullYear() - date.getFullYear();
};
i.avatar = function () {
    var traits = this.traits();
    return (obj_case_1.default(traits, "avatar") || obj_case_1.default(traits, "photoUrl") || obj_case_1.default(traits, "avatarUrl"));
};
i.position = function () {
    var traits = this.traits();
    return obj_case_1.default(traits, "position") || obj_case_1.default(traits, "jobTitle");
};
i.username = facade_1.Facade.proxy("traits.username");
i.website = facade_1.Facade.one("traits.website");
i.websites = facade_1.Facade.multi("traits.website");
i.phone = facade_1.Facade.one("traits.phone");
i.phones = facade_1.Facade.multi("traits.phone");
i.address = facade_1.Facade.proxy("traits.address");
i.gender = facade_1.Facade.proxy("traits.gender");
i.birthday = facade_1.Facade.proxy("traits.birthday");
//# sourceMappingURL=identify.js.map