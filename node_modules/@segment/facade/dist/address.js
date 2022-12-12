"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
var obj_case_1 = __importDefault(require("obj-case"));
function trait(a, b) {
    return function () {
        var traits = this.traits();
        var props = this.properties ? this.properties() : {};
        return (obj_case_1.default(traits, "address." + a) ||
            obj_case_1.default(traits, a) ||
            (b ? obj_case_1.default(traits, "address." + b) : null) ||
            (b ? obj_case_1.default(traits, b) : null) ||
            obj_case_1.default(props, "address." + a) ||
            obj_case_1.default(props, a) ||
            (b ? obj_case_1.default(props, "address." + b) : null) ||
            (b ? obj_case_1.default(props, b) : null));
    };
}
function default_1(proto) {
    proto.zip = trait("postalCode", "zip");
    proto.country = trait("country");
    proto.street = trait("street");
    proto.state = trait("state");
    proto.city = trait("city");
    proto.region = trait("region");
}
exports.default = default_1;
//# sourceMappingURL=address.js.map