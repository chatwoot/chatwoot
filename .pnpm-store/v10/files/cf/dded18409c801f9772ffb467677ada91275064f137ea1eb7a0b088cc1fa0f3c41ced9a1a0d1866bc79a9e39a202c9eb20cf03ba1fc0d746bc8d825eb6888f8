"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.validateEvent = exports.ValidationError = void 0;
var tslib_1 = require("tslib");
var helpers_1 = require("./helpers");
var ValidationError = /** @class */ (function (_super) {
    tslib_1.__extends(ValidationError, _super);
    function ValidationError(field, message) {
        var _this = _super.call(this, message) || this;
        _this.field = field;
        return _this;
    }
    return ValidationError;
}(Error));
exports.ValidationError = ValidationError;
function validateEvent(event) {
    if (!event || typeof event !== 'object') {
        throw new ValidationError('event', 'Event is missing');
    }
    if (!(0, helpers_1.isString)(event.type)) {
        throw new ValidationError('type', 'type is not a string');
    }
    if (event.type === 'track') {
        if (!(0, helpers_1.isString)(event.event)) {
            throw new ValidationError('event', 'Event is not a string');
        }
        if (!(0, helpers_1.isPlainObject)(event.properties)) {
            throw new ValidationError('properties', 'properties is not an object');
        }
    }
    if (['group', 'identify'].includes(event.type)) {
        if (!(0, helpers_1.isPlainObject)(event.traits)) {
            throw new ValidationError('traits', 'traits is not an object');
        }
    }
    if (!(0, helpers_1.hasUser)(event)) {
        throw new ValidationError('userId/anonymousId/previousId/groupId', 'Must have userId or anonymousId or previousId or groupId');
    }
}
exports.validateEvent = validateEvent;
//# sourceMappingURL=assertions.js.map