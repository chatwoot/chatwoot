"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getStaticJSONValue = exports.isUndefinedIdentifier = exports.isNumberIdentifier = exports.isExpression = void 0;
function isExpression(node) {
    if (node.type === "JSONIdentifier" || node.type === "JSONLiteral") {
        const parent = node.parent;
        if (parent.type === "JSONProperty" && parent.key === node) {
            return false;
        }
        return true;
    }
    if (node.type === "JSONObjectExpression" ||
        node.type === "JSONArrayExpression" ||
        node.type === "JSONUnaryExpression" ||
        node.type === "JSONTemplateLiteral" ||
        node.type === "JSONBinaryExpression") {
        return true;
    }
    return false;
}
exports.isExpression = isExpression;
function isNumberIdentifier(node) {
    return (isExpression(node) && (node.name === "Infinity" || node.name === "NaN"));
}
exports.isNumberIdentifier = isNumberIdentifier;
function isUndefinedIdentifier(node) {
    return isExpression(node) && node.name === "undefined";
}
exports.isUndefinedIdentifier = isUndefinedIdentifier;
const resolver = {
    Program(node) {
        if (node.body.length !== 1 ||
            node.body[0].type !== "JSONExpressionStatement") {
            throw new Error("Illegal argument");
        }
        return getStaticJSONValue(node.body[0]);
    },
    JSONExpressionStatement(node) {
        return getStaticJSONValue(node.expression);
    },
    JSONObjectExpression(node) {
        const object = {};
        for (const prop of node.properties) {
            Object.assign(object, getStaticJSONValue(prop));
        }
        return object;
    },
    JSONProperty(node) {
        const keyName = node.key.type === "JSONLiteral" ? `${node.key.value}` : node.key.name;
        return {
            [keyName]: getStaticJSONValue(node.value),
        };
    },
    JSONArrayExpression(node) {
        const array = [];
        for (let index = 0; index < node.elements.length; index++) {
            const element = node.elements[index];
            if (element) {
                array[index] = getStaticJSONValue(element);
            }
        }
        return array;
    },
    JSONLiteral(node) {
        if (node.regex) {
            try {
                return new RegExp(node.regex.pattern, node.regex.flags);
            }
            catch (_a) {
                return `/${node.regex.pattern}/${node.regex.flags}`;
            }
        }
        if (node.bigint != null) {
            try {
                return BigInt(node.bigint);
            }
            catch (_b) {
                return `${node.bigint}`;
            }
        }
        return node.value;
    },
    JSONUnaryExpression(node) {
        const value = getStaticJSONValue(node.argument);
        return node.operator === "-" ? -value : value;
    },
    JSONBinaryExpression(node) {
        const left = getStaticJSONValue(node.left);
        const right = getStaticJSONValue(node.right);
        return node.operator === "+"
            ? left + right
            : node.operator === "-"
                ? left - right
                : node.operator === "*"
                    ? left * right
                    : node.operator === "/"
                        ? left / right
                        : node.operator === "%"
                            ? left % right
                            : node.operator === "**"
                                ? Math.pow(left, right)
                                : (() => {
                                    throw new Error(`Unknown operator: ${node.operator}`);
                                })();
    },
    JSONIdentifier(node) {
        if (node.name === "Infinity") {
            return Infinity;
        }
        if (node.name === "NaN") {
            return NaN;
        }
        if (node.name === "undefined") {
            return undefined;
        }
        throw new Error("Illegal argument");
    },
    JSONTemplateLiteral(node) {
        return getStaticJSONValue(node.quasis[0]);
    },
    JSONTemplateElement(node) {
        return node.value.cooked;
    },
};
function getStaticJSONValue(node) {
    return resolver[node.type](node);
}
exports.getStaticJSONValue = getStaticJSONValue;
