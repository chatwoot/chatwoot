"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getCasingChecker = exports.allowedCaseOptions = exports.pascalCase = exports.camelCase = exports.isScreamingSnakeCase = exports.isPascalCase = exports.isLowerCase = exports.isCamelCase = exports.isSnakeCase = exports.isKebabCase = void 0;
function capitalize(str) {
    return str.charAt(0).toUpperCase() + str.slice(1);
}
function hasSymbols(str) {
    return /[!"#%&'()*+,./:;<=>?@[\\\]^`{|}]/u.exec(str);
}
function hasUpper(str) {
    return /[A-Z]/u.exec(str);
}
function hasLower(str) {
    return /[a-z]/u.test(str);
}
function isKebabCase(str) {
    if (hasUpper(str) ||
        hasSymbols(str) ||
        /^\d/u.exec(str) ||
        /^-/u.exec(str) ||
        /_|--|\s/u.exec(str)) {
        return false;
    }
    return true;
}
exports.isKebabCase = isKebabCase;
function isSnakeCase(str) {
    if (hasUpper(str) ||
        hasSymbols(str) ||
        /^\d/u.exec(str) ||
        /-|__|\s/u.exec(str)) {
        return false;
    }
    return true;
}
exports.isSnakeCase = isSnakeCase;
function isCamelCase(str) {
    if (hasSymbols(str) ||
        /^[A-Z\d]/u.exec(str) ||
        /-|_|\s/u.exec(str)) {
        return false;
    }
    return true;
}
exports.isCamelCase = isCamelCase;
function isLowerCase(str) {
    if (hasSymbols(str) ||
        hasUpper(str) ||
        /-|_|\s/u.exec(str)) {
        return false;
    }
    return true;
}
exports.isLowerCase = isLowerCase;
function isPascalCase(str) {
    if (hasSymbols(str) ||
        /^[a-z\d]/u.exec(str) ||
        /-|_|\s/u.exec(str)) {
        return false;
    }
    return true;
}
exports.isPascalCase = isPascalCase;
function isScreamingSnakeCase(str) {
    if (hasLower(str) || hasSymbols(str) || /-|__|\s/u.test(str)) {
        return false;
    }
    return true;
}
exports.isScreamingSnakeCase = isScreamingSnakeCase;
const checkersMap = {
    'kebab-case': isKebabCase,
    snake_case: isSnakeCase,
    camelCase: isCamelCase,
    lowercase: isLowerCase,
    PascalCase: isPascalCase,
    SCREAMING_SNAKE_CASE: isScreamingSnakeCase
};
function camelCase(str) {
    if (isPascalCase(str)) {
        return str.charAt(0).toLowerCase() + str.slice(1);
    }
    return str.replace(/[-_](\w)/gu, (_, c) => (c ? c.toUpperCase() : ''));
}
exports.camelCase = camelCase;
function pascalCase(str) {
    return capitalize(camelCase(str));
}
exports.pascalCase = pascalCase;
exports.allowedCaseOptions = [
    'camelCase',
    'kebab-case',
    'lowercase',
    'PascalCase',
    'snake_case',
    'SCREAMING_SNAKE_CASE'
];
function getCasingChecker(name) {
    return checkersMap[name] || isPascalCase;
}
exports.getCasingChecker = getCasingChecker;
