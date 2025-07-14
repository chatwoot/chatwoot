"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.Page = void 0;
var inherits_1 = __importDefault(require("inherits"));
var facade_1 = require("./facade");
var track_1 = require("./track");
var is_email_1 = __importDefault(require("./is-email"));
function Page(dictionary, opts) {
    facade_1.Facade.call(this, dictionary, opts);
}
exports.Page = Page;
inherits_1.default(Page, facade_1.Facade);
var p = Page.prototype;
p.action = function () {
    return "page";
};
p.type = p.action;
p.category = facade_1.Facade.field("category");
p.name = facade_1.Facade.field("name");
p.title = facade_1.Facade.proxy("properties.title");
p.path = facade_1.Facade.proxy("properties.path");
p.url = facade_1.Facade.proxy("properties.url");
p.referrer = function () {
    return (this.proxy("context.referrer.url") ||
        this.proxy("context.page.referrer") ||
        this.proxy("properties.referrer"));
};
p.properties = function (aliases) {
    var props = this.field("properties") || {};
    var category = this.category();
    var name = this.name();
    aliases = aliases || {};
    if (category)
        props.category = category;
    if (name)
        props.name = name;
    for (var alias in aliases) {
        if (Object.prototype.hasOwnProperty.call(aliases, alias)) {
            var value = this[alias] == null
                ? this.proxy("properties." + alias)
                : this[alias]();
            if (value == null)
                continue;
            props[aliases[alias]] = value;
            if (alias !== aliases[alias])
                delete props[alias];
        }
    }
    return props;
};
p.email = function () {
    var email = this.proxy("context.traits.email") || this.proxy("properties.email");
    if (email)
        return email;
    var userId = this.userId();
    if (is_email_1.default(userId))
        return userId;
};
p.fullName = function () {
    var category = this.category();
    var name = this.name();
    return name && category ? category + " " + name : name;
};
p.event = function (name) {
    return name ? "Viewed " + name + " Page" : "Loaded a Page";
};
p.track = function (name) {
    var json = this.json();
    json.event = this.event(name);
    json.timestamp = this.timestamp();
    json.properties = this.properties();
    return new track_1.Track(json, this.opts);
};
//# sourceMappingURL=page.js.map