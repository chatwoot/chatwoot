"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.LocaleMessages = exports.FileLocaleMessage = exports.BlockLocaleMessage = exports.LocaleMessage = void 0;
const path_1 = require("path");
const fs_1 = require("fs");
const parsers_1 = require("./parsers");
const resource_loader_1 = require("./resource-loader");
const json5_1 = require("json5");
const js_yaml_1 = require("js-yaml");
const key_path_1 = require("./key-path");
const DEFAULT_LOCALE_PATTERN = '[A-Za-z0-9-_]+';
const DEFAULT_LOCALE_FIELNAME_REGEX = new RegExp(`(${DEFAULT_LOCALE_PATTERN})\.`, 'i');
const DEFAULT_LOCALE_CAPTURE_REGEX = new RegExp(`^.*\/(?<locale>${DEFAULT_LOCALE_PATTERN})\.(json5?|ya?ml)$`, 'i');
class LocaleMessage {
    constructor({ fullpath, locales, localeKey, localePattern }) {
        this.fullpath = fullpath;
        this.localeKey = localeKey;
        this.file = fullpath.replace(/^.*(\\|\/|:)/, '');
        this.localePattern = this.getLocalePatternWithRegex(localePattern);
        this._locales = locales;
    }
    getLocalePatternWithRegex(localePattern) {
        return localePattern != null
            ? typeof localePattern === 'string'
                ? new RegExp(localePattern, 'i')
                : Object.prototype.toString.call(localePattern) === '[object RegExp]'
                    ? localePattern
                    : DEFAULT_LOCALE_CAPTURE_REGEX
            : DEFAULT_LOCALE_CAPTURE_REGEX;
    }
    get messages() {
        return this.getMessagesInternal();
    }
    get locales() {
        var _a;
        if (this._locales) {
            return this._locales;
        }
        if (this.localeKey === 'file') {
            const matched = this.file.match(DEFAULT_LOCALE_FIELNAME_REGEX);
            return (this._locales = [(matched && matched[1]) || this.file]);
        }
        else if (this.localeKey === 'path') {
            const matched = this.fullpath.match(this.localePattern);
            return (this._locales = [
                (matched && ((_a = matched.groups) === null || _a === void 0 ? void 0 : _a.locale)) || this.fullpath
            ]);
        }
        else if (this.localeKey === 'key') {
            return (this._locales = Object.keys(this.messages));
        }
        return (this._locales = []);
    }
    isResolvedLocaleByFileName() {
        return this.localeKey === 'file' || this.localeKey === 'path';
    }
    getMessagesFromLocale(locale) {
        if (this.isResolvedLocaleByFileName()) {
            if (!this.locales.includes(locale)) {
                return {};
            }
            return this.messages;
        }
        if (this.localeKey === 'key') {
            return (this.messages[locale] || {});
        }
        return {};
    }
}
exports.LocaleMessage = LocaleMessage;
class BlockLocaleMessage extends LocaleMessage {
    constructor({ block, fullpath, locales, localeKey, lang = 'json' }) {
        super({
            fullpath,
            locales,
            localeKey
        });
        this._messages = null;
        this.block = block;
        this.lang = lang || 'json';
    }
    getMessagesInternal() {
        if (this._messages) {
            return this._messages;
        }
        const { lang } = this;
        if (lang === 'json' || lang === 'json5') {
            this._messages = (0, parsers_1.parseJsonValuesInI18nBlock)(this.block) || {};
        }
        else if (lang === 'yaml' || lang === 'yml') {
            this._messages = (0, parsers_1.parseYamlValuesInI18nBlock)(this.block) || {};
        }
        else {
            this._messages = {};
        }
        return this._messages;
    }
}
exports.BlockLocaleMessage = BlockLocaleMessage;
class FileLocaleMessage extends LocaleMessage {
    constructor({ fullpath, locales, localeKey, localePattern }) {
        super({
            fullpath,
            locales,
            localeKey,
            localePattern
        });
        this._resource = new resource_loader_1.ResourceLoader(fullpath, fileName => {
            const ext = (0, path_1.extname)(fileName).toLowerCase();
            if (ext === '.js') {
                const key = require.resolve(fileName);
                delete require.cache[key];
                return require(fileName);
            }
            else if (ext === '.yaml' || ext === '.yml') {
                return (0, js_yaml_1.load)((0, fs_1.readFileSync)(fileName, 'utf8'));
            }
            else if (ext === '.json' || ext === '.json5') {
                return (0, json5_1.parse)((0, fs_1.readFileSync)(fileName, 'utf8'));
            }
        });
    }
    getMessagesInternal() {
        return this._resource.getResource();
    }
}
exports.FileLocaleMessage = FileLocaleMessage;
class LocaleMessages {
    constructor(localeMessages) {
        this.localeMessages = localeMessages;
    }
    get locales() {
        const locales = new Set();
        for (const localeMessage of this.localeMessages) {
            for (const locale of localeMessage.locales) {
                locales.add(locale);
            }
        }
        return [...locales];
    }
    isEmpty() {
        return this.localeMessages.length <= 0;
    }
    findExistLocaleMessage(fullpath) {
        return (this.localeMessages.find(message => message.fullpath === fullpath) || null);
    }
    findBlockLocaleMessage(block) {
        return (this.localeMessages.find((message) => message.block === block) || null);
    }
    findMissingPath(key) {
        let missingPath = [];
        for (const locale of this.locales) {
            const localeMessages = this.localeMessages.map(lm => lm.getMessagesFromLocale(locale));
            if (localeMessages.some(last => {
                return last && typeof last === 'object' ? last[key] != null : false;
            })) {
                return null;
            }
            const paths = [...(0, key_path_1.parsePath)(key)];
            let lasts = localeMessages;
            const targetPaths = [];
            let hasMissing = false;
            while (paths.length) {
                const path = paths.shift();
                targetPaths.push(path);
                const values = lasts
                    .map(last => {
                    return last && typeof last === 'object' ? last[path] : undefined;
                })
                    .filter((val) => val != null);
                if (values.length === 0) {
                    if (missingPath.length <= targetPaths.length) {
                        missingPath = targetPaths;
                    }
                    hasMissing = true;
                    break;
                }
                lasts = values;
            }
            if (!hasMissing) {
                return null;
            }
        }
        return (0, key_path_1.joinPath)(...missingPath);
    }
}
exports.LocaleMessages = LocaleMessages;
