"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.Track = void 0;
var inherits_1 = __importDefault(require("inherits"));
var facade_1 = require("./facade");
var identify_1 = require("./identify");
var is_email_1 = __importDefault(require("./is-email"));
var obj_case_1 = __importDefault(require("obj-case"));
function Track(dictionary, opts) {
    facade_1.Facade.call(this, dictionary, opts);
}
exports.Track = Track;
inherits_1.default(Track, facade_1.Facade);
var t = Track.prototype;
t.action = function () {
    return "track";
};
t.type = t.action;
t.event = facade_1.Facade.field("event");
t.value = facade_1.Facade.proxy("properties.value");
t.category = facade_1.Facade.proxy("properties.category");
t.id = facade_1.Facade.proxy("properties.id");
t.productId = function () {
    return (this.proxy("properties.product_id") || this.proxy("properties.productId"));
};
t.promotionId = function () {
    return (this.proxy("properties.promotion_id") ||
        this.proxy("properties.promotionId"));
};
t.cartId = function () {
    return this.proxy("properties.cart_id") || this.proxy("properties.cartId");
};
t.checkoutId = function () {
    return (this.proxy("properties.checkout_id") || this.proxy("properties.checkoutId"));
};
t.paymentId = function () {
    return (this.proxy("properties.payment_id") || this.proxy("properties.paymentId"));
};
t.couponId = function () {
    return (this.proxy("properties.coupon_id") || this.proxy("properties.couponId"));
};
t.wishlistId = function () {
    return (this.proxy("properties.wishlist_id") || this.proxy("properties.wishlistId"));
};
t.reviewId = function () {
    return (this.proxy("properties.review_id") || this.proxy("properties.reviewId"));
};
t.orderId = function () {
    return (this.proxy("properties.id") ||
        this.proxy("properties.order_id") ||
        this.proxy("properties.orderId"));
};
t.sku = facade_1.Facade.proxy("properties.sku");
t.tax = facade_1.Facade.proxy("properties.tax");
t.name = facade_1.Facade.proxy("properties.name");
t.price = facade_1.Facade.proxy("properties.price");
t.total = facade_1.Facade.proxy("properties.total");
t.repeat = facade_1.Facade.proxy("properties.repeat");
t.coupon = facade_1.Facade.proxy("properties.coupon");
t.shipping = facade_1.Facade.proxy("properties.shipping");
t.discount = facade_1.Facade.proxy("properties.discount");
t.shippingMethod = function () {
    return (this.proxy("properties.shipping_method") ||
        this.proxy("properties.shippingMethod"));
};
t.paymentMethod = function () {
    return (this.proxy("properties.payment_method") ||
        this.proxy("properties.paymentMethod"));
};
t.description = facade_1.Facade.proxy("properties.description");
t.plan = facade_1.Facade.proxy("properties.plan");
t.subtotal = function () {
    var subtotal = obj_case_1.default(this.properties(), "subtotal");
    var total = this.total() || this.revenue();
    if (subtotal)
        return subtotal;
    if (!total)
        return 0;
    if (this.total()) {
        var n = this.tax();
        if (n)
            total -= n;
        n = this.shipping();
        if (n)
            total -= n;
        n = this.discount();
        if (n)
            total += n;
    }
    return total;
};
t.products = function () {
    var props = this.properties();
    var products = obj_case_1.default(props, "products");
    if (Array.isArray(products)) {
        return products.filter(function (item) { return item !== null; });
    }
    return [];
};
t.quantity = function () {
    var props = this.obj.properties || {};
    return props.quantity || 1;
};
t.currency = function () {
    var props = this.obj.properties || {};
    return props.currency || "USD";
};
t.referrer = function () {
    return (this.proxy("context.referrer.url") ||
        this.proxy("context.page.referrer") ||
        this.proxy("properties.referrer"));
};
t.query = facade_1.Facade.proxy("options.query");
t.properties = function (aliases) {
    var ret = this.field("properties") || {};
    aliases = aliases || {};
    for (var alias in aliases) {
        if (Object.prototype.hasOwnProperty.call(aliases, alias)) {
            var value = this[alias] == null
                ? this.proxy("properties." + alias)
                : this[alias]();
            if (value == null)
                continue;
            ret[aliases[alias]] = value;
            delete ret[alias];
        }
    }
    return ret;
};
t.username = function () {
    return (this.proxy("traits.username") ||
        this.proxy("properties.username") ||
        this.userId() ||
        this.sessionId());
};
t.email = function () {
    var email = this.proxy("traits.email") ||
        this.proxy("properties.email") ||
        this.proxy("options.traits.email");
    if (email)
        return email;
    var userId = this.userId();
    if (is_email_1.default(userId))
        return userId;
};
t.revenue = function () {
    var revenue = this.proxy("properties.revenue");
    var event = this.event();
    var orderCompletedRegExp = /^[ _]?completed[ _]?order[ _]?|^[ _]?order[ _]?completed[ _]?$/i;
    if (!revenue && event && event.match(orderCompletedRegExp)) {
        revenue = this.proxy("properties.total");
    }
    return currency(revenue);
};
t.cents = function () {
    var revenue = this.revenue();
    return typeof revenue !== "number" ? this.value() || 0 : revenue * 100;
};
t.identify = function () {
    var json = this.json();
    json.traits = this.traits();
    return new identify_1.Identify(json, this.opts);
};
function currency(val) {
    if (!val)
        return;
    if (typeof val === "number") {
        return val;
    }
    if (typeof val !== "string") {
        return;
    }
    val = val.replace(/\$/g, "");
    val = parseFloat(val);
    if (!isNaN(val)) {
        return val;
    }
}
//# sourceMappingURL=track.js.map