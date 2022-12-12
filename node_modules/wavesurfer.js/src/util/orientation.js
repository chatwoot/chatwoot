const verticalPropMap = {
    width: 'height',
    height: 'width',

    overflowX: 'overflowY',
    overflowY: 'overflowX',

    clientWidth: 'clientHeight',
    clientHeight: 'clientWidth',

    clientX: 'clientY',
    clientY: 'clientX',

    scrollWidth: 'scrollHeight',
    scrollLeft: 'scrollTop',

    offsetLeft: 'offsetTop',
    offsetTop: 'offsetLeft',
    offsetHeight: 'offsetWidth',
    offsetWidth: 'offsetHeight',

    left: 'top',
    right: 'bottom',
    top: 'left',
    bottom: 'right',

    borderRightStyle: 'borderBottomStyle',
    borderRightWidth: 'borderBottomWidth',
    borderRightColor: 'borderBottomColor'
};

/**
 * Convert a horizontally-oriented property name to a vertical one.
 *
 * @param {string} prop A property name
 * @param {bool} vertical Whether the element is oriented vertically
 * @returns {string} prop, converted appropriately
 */
function mapProp(prop, vertical) {
    if (Object.prototype.hasOwnProperty.call(verticalPropMap, prop)) {
        return vertical ? verticalPropMap[prop] : prop;
    } else {
        return prop;
    }
}

const isProxy = Symbol("isProxy");

/**
 * Returns an appropriately oriented object based on vertical.
 * If vertical is true, attribute getting and setting will be mapped through
 * verticalPropMap, so that e.g. getting the object's .width will give its
 * .height instead.
 * Certain methods of an oriented object will return oriented objects as well.
 * Oriented objects can't be added to the DOM directly since they are Proxy objects
 * and thus fail typechecks. Use domElement to get the actual element for this.
 *
 * @param {object} target The object to be wrapped and oriented
 * @param {bool} vertical Whether the element is oriented vertically
 * @returns {Proxy} An oriented object with attr translation via verticalAttrMap
 * @since 5.0.0
 */
export default function withOrientation(target, vertical) {
    if (target[isProxy]) {
        return target;
    } else {
        return new Proxy(
            target, {
                get: function(obj, prop, receiver) {
                    if (prop === isProxy) {
                        return true;
                    } else if (prop === 'domElement') {
                        return obj;
                    } else if (prop === 'style') {
                        return withOrientation(obj.style, vertical);
                    } else if (prop === 'canvas') {
                        return withOrientation(obj.canvas, vertical);
                    } else if (prop === 'getBoundingClientRect') {
                        return function(...args) {
                            return withOrientation(obj.getBoundingClientRect(...args), vertical);
                        };
                    } else if (prop === 'getContext') {
                        return function(...args) {
                            return withOrientation(obj.getContext(...args), vertical);
                        };
                    } else {
                        let value = obj[mapProp(prop, vertical)];
                        return typeof value == 'function' ? value.bind(obj) : value;
                    }
                },
                set: function(obj, prop, value) {
                    obj[mapProp(prop, vertical)] = value;
                    return true;
                }
            }
        );
    }
}
