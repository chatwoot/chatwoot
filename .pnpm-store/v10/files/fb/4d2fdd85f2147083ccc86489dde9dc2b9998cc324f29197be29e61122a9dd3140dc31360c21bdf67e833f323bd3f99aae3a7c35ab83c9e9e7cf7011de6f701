import { isNumber } from "./type-utils.mjs";
function clampToRange(value, min, max, logger, fallbackValue) {
    if (min > max) {
        logger.warn('min cannot be greater than max.');
        min = max;
    }
    if (isNumber(value)) if (value > max) {
        logger.warn(' cannot be  greater than max: ' + max + '. Using max value instead.');
        return max;
    } else {
        if (!(value < min)) return value;
        logger.warn(' cannot be less than min: ' + min + '. Using min value instead.');
        return min;
    }
    logger.warn(' must be a number. using max or fallback. max: ' + max + ', fallback: ' + fallbackValue);
    return clampToRange(fallbackValue || max, min, max, logger);
}
export { clampToRange };
