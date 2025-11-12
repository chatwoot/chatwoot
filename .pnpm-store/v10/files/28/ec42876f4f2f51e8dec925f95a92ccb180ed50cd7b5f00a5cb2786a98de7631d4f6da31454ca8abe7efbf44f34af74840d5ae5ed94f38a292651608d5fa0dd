"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getYAMLPlainStringOffset = exports.getYAMLDoubleQuotedStringOffset = exports.getYAMLSingleQuotedStringOffset = exports.getJSONStringOffset = exports.getReportIndex = exports.getMessageSyntaxVersions = exports.NodeTypes = void 0;
const semver_1 = require("semver");
exports.NodeTypes = {
    Resource: 0,
    Plural: 1,
    Message: 2,
    Text: 3,
    Named: 4,
    List: 5,
    Linked: 6,
    LinkedKey: 7,
    LinkedModifier: 8,
    Literal: 9
};
const puttedSettingsError = new WeakSet();
function getMessageSyntaxVersions(context) {
    const { settings } = context;
    const messageSyntaxVersion = settings['vue-i18n'] && settings['vue-i18n'].messageSyntaxVersion;
    if (!messageSyntaxVersion) {
        return {
            v8: true,
            v9: true,
            isNotSet: true,
            reportIfMissingSetting: () => {
                if (!puttedSettingsError.has(context)) {
                    const ruleName = context.id;
                    context.report({
                        loc: { line: 1, column: 0 },
                        message: `If you want to use '${ruleName}' rule, you need to set 'messageSyntaxVersion' at 'settings'. See the 'eslint-plugin-vue-i18n' documentation`
                    });
                    puttedSettingsError.add(context);
                }
                return true;
            }
        };
    }
    const range = new semver_1.Range(messageSyntaxVersion);
    return {
        v8: (0, semver_1.intersects)(range, '^8.0.0 || <=8.0.0'),
        v9: (0, semver_1.intersects)(range, '>=9.0.0-0'),
        isNotSet: false,
        reportIfMissingSetting: () => false
    };
}
exports.getMessageSyntaxVersions = getMessageSyntaxVersions;
function getReportIndex(node, stringOffset) {
    if (node.type === 'JSONLiteral' || node.type === 'JSONTemplateLiteral') {
        const stringCode = node.type === 'JSONLiteral'
            ? node.raw.slice(1, -1)
            : node.quasis[0].value.raw;
        return (node.range[0] +
            1 +
            getJSONStringOffset(stringCode, stringOffset));
    }
    if (node.type === 'YAMLScalar') {
        if (node.style === 'single-quoted' || node.style === 'double-quoted') {
            const stringCode = node.raw.slice(1, -1);
            return (node.range[0] +
                1 +
                (node.style === 'single-quoted'
                    ? getYAMLSingleQuotedStringOffset(stringCode, stringOffset)
                    : getYAMLDoubleQuotedStringOffset(stringCode, stringOffset)));
        }
        if (node.style === 'plain') {
            const stringCode = node.raw;
            return node.range[0] + getYAMLPlainStringOffset(stringCode, stringOffset);
        }
    }
    return null;
}
exports.getReportIndex = getReportIndex;
function getJSONStringOffset(code, stringOffset) {
    let offset = stringOffset;
    let codeIndex = 0;
    let char;
    while ((char = code[codeIndex++]) && offset > 0) {
        if (char === '\\') {
            char = code[codeIndex++];
            if (char === 'x') {
                codeIndex += 2;
            }
            else if (char === 'u') {
                char = code[codeIndex++];
                if (char === '{') {
                    let pointStr = '';
                    while ((char = code[codeIndex++]) && char !== '}') {
                        pointStr += char;
                    }
                    let point = parseInt(pointStr, 16);
                    while (point > 0xffff) {
                        offset--;
                        point >>= 16;
                    }
                }
                else {
                    codeIndex += 3;
                }
            }
            else if (char >= '0' && char <= '9') {
                let octalStr = code.substr(codeIndex - 1, 3).match(/^[0-7]+/u)[0];
                const octal = parseInt(octalStr, 8);
                if (octal > 255) {
                    octalStr = octalStr.slice(0, -1);
                }
                if (octalStr.length >= 2) {
                    codeIndex += octalStr.length - 1;
                }
            }
        }
        offset--;
    }
    return Math.min(codeIndex - 1, code.length);
}
exports.getJSONStringOffset = getJSONStringOffset;
function getYAMLSingleQuotedStringOffset(code, stringOffset) {
    let offset = stringOffset;
    let codeIndex = 0;
    let char;
    let lineFolding = 0;
    while ((char = code[codeIndex++]) && offset > 0) {
        if (char === "'" && code[codeIndex] === "'") {
            codeIndex++;
            lineFolding = 0;
        }
        else if (isSpaceOrEOL(char)) {
            let nextCodeIndex = processMaybeLineFolding(code, codeIndex - 1);
            if (nextCodeIndex != null) {
                if (lineFolding === 0 && isEOL(code[nextCodeIndex])) {
                    nextCodeIndex = processMaybeLineFolding(code, nextCodeIndex);
                }
                codeIndex = nextCodeIndex;
                lineFolding++;
            }
            else {
                lineFolding = 0;
            }
        }
        else {
            lineFolding = 0;
        }
        offset--;
    }
    return Math.min(codeIndex - 1, code.length);
}
exports.getYAMLSingleQuotedStringOffset = getYAMLSingleQuotedStringOffset;
function getYAMLDoubleQuotedStringOffset(code, stringOffset) {
    let offset = stringOffset;
    let codeIndex = 0;
    let char;
    let lineFolding = 0;
    while ((char = code[codeIndex++]) && offset > 0) {
        if (char === '\\') {
            char = code[codeIndex++];
            if (char === 'x') {
                codeIndex += 2;
            }
            else if (char === 'u') {
                codeIndex += 4;
            }
            else if (char === 'U') {
                if (code.substr(codeIndex, 4) !== '0000') {
                    offset--;
                }
                codeIndex += 8;
            }
            else if (isEOL(char)) {
                const nextCodeIndex = processMaybeLineFolding(code, codeIndex - 1);
                if (nextCodeIndex != null) {
                    codeIndex = nextCodeIndex + 1;
                    if (code[nextCodeIndex] === '\\') {
                        codeIndex--;
                        lineFolding = 0;
                        continue;
                    }
                }
            }
            lineFolding = 0;
        }
        else if (isSpaceOrEOL(char)) {
            let nextCodeIndex = processMaybeLineFolding(code, codeIndex - 1);
            if (nextCodeIndex != null) {
                if (lineFolding === 0 && isEOL(code[nextCodeIndex])) {
                    nextCodeIndex = processMaybeLineFolding(code, nextCodeIndex);
                }
                codeIndex = nextCodeIndex;
                lineFolding++;
            }
            else {
                lineFolding = 0;
            }
        }
        else {
            lineFolding = 0;
        }
        offset--;
    }
    return Math.min(codeIndex - 1, code.length);
}
exports.getYAMLDoubleQuotedStringOffset = getYAMLDoubleQuotedStringOffset;
function getYAMLPlainStringOffset(code, stringOffset) {
    let offset = stringOffset;
    let codeIndex = 0;
    let char;
    let lineFolding = 0;
    while ((char = code[codeIndex++]) && offset > 0) {
        if (isSpaceOrEOL(char)) {
            let nextCodeIndex = processMaybeLineFolding(code, codeIndex - 1);
            if (nextCodeIndex != null) {
                if (lineFolding === 0 && isEOL(code[nextCodeIndex])) {
                    nextCodeIndex = processMaybeLineFolding(code, nextCodeIndex);
                }
                codeIndex = nextCodeIndex;
                lineFolding++;
            }
            else {
                lineFolding = 0;
            }
        }
        else {
            lineFolding = 0;
        }
        offset--;
    }
    return Math.min(codeIndex - 1, code.length);
}
exports.getYAMLPlainStringOffset = getYAMLPlainStringOffset;
function isSpace(char) {
    return char === ' ' || char === '\t';
}
function isSpaceOrEOL(char) {
    return isSpace(char) || isEOL(char);
}
function isEOL(char) {
    return char === '\n' || char === '\r';
}
function processMaybeLineFolding(code, spaceIndex) {
    let codeIndex = spaceIndex;
    let char;
    let hasNewline = false;
    while ((char = code[codeIndex++])) {
        if (isEOL(char)) {
            if (hasNewline) {
                return codeIndex - 1;
            }
            if (char === '\r' && code[codeIndex] === '\n') {
                codeIndex++;
            }
            hasNewline = true;
        }
        else if (!isSpace(char)) {
            if (hasNewline) {
                return codeIndex - 1;
            }
            else {
                return null;
            }
        }
    }
    if (hasNewline) {
        return codeIndex - 1;
    }
    else {
        return null;
    }
}
