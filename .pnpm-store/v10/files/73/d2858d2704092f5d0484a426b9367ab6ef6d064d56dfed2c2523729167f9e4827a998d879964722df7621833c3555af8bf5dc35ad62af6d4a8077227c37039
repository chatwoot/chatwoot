import { __extends } from "tslib";
import { hasUser, isString, isPlainObject } from './helpers';
var ValidationError = /** @class */ (function (_super) {
    __extends(ValidationError, _super);
    function ValidationError(field, message) {
        var _this = _super.call(this, message) || this;
        _this.field = field;
        return _this;
    }
    return ValidationError;
}(Error));
export { ValidationError };
export function validateEvent(event) {
    if (!event || typeof event !== 'object') {
        throw new ValidationError('event', 'Event is missing');
    }
    if (!isString(event.type)) {
        throw new ValidationError('type', 'type is not a string');
    }
    if (event.type === 'track') {
        if (!isString(event.event)) {
            throw new ValidationError('event', 'Event is not a string');
        }
        if (!isPlainObject(event.properties)) {
            throw new ValidationError('properties', 'properties is not an object');
        }
    }
    if (['group', 'identify'].includes(event.type)) {
        if (!isPlainObject(event.traits)) {
            throw new ValidationError('traits', 'traits is not an object');
        }
    }
    if (!hasUser(event)) {
        throw new ValidationError('userId/anonymousId/previousId/groupId', 'Must have userId or anonymousId or previousId or groupId');
    }
}
//# sourceMappingURL=assertions.js.map