import { __assign, __extends } from "tslib";
import { v4 as uuid } from '@lukeed/uuid';
import jar from 'js-cookie';
import { tld } from './tld';
import autoBind from '../../lib/bind-all';
var defaults = {
    persist: true,
    cookie: {
        key: 'ajs_user_id',
        oldKey: 'ajs_user',
    },
    localStorage: {
        key: 'ajs_user_traits',
    },
};
var Store = /** @class */ (function () {
    function Store() {
        this.cache = {};
    }
    Store.prototype.get = function (key) {
        return this.cache[key];
    };
    Store.prototype.set = function (key, value) {
        this.cache[key] = value;
    };
    Store.prototype.remove = function (key) {
        delete this.cache[key];
    };
    Object.defineProperty(Store.prototype, "type", {
        get: function () {
            return 'memory';
        },
        enumerable: false,
        configurable: true
    });
    return Store;
}());
var ONE_YEAR = 365;
var Cookie = /** @class */ (function (_super) {
    __extends(Cookie, _super);
    function Cookie(options) {
        if (options === void 0) { options = Cookie.defaults; }
        var _this = _super.call(this) || this;
        _this.options = __assign(__assign({}, Cookie.defaults), options);
        return _this;
    }
    Cookie.available = function () {
        var cookieEnabled = window.navigator.cookieEnabled;
        if (!cookieEnabled) {
            jar.set('ajs:cookies', 'test');
            cookieEnabled = document.cookie.includes('ajs:cookies');
            jar.remove('ajs:cookies');
        }
        return cookieEnabled;
    };
    Object.defineProperty(Cookie, "defaults", {
        get: function () {
            return {
                maxage: ONE_YEAR,
                domain: tld(window.location.href),
                path: '/',
                sameSite: 'Lax',
            };
        },
        enumerable: false,
        configurable: true
    });
    Cookie.prototype.opts = function () {
        return {
            sameSite: this.options.sameSite,
            expires: this.options.maxage,
            domain: this.options.domain,
            path: this.options.path,
            secure: this.options.secure,
        };
    };
    Cookie.prototype.get = function (key) {
        try {
            var value = jar.get(key);
            if (!value) {
                return null;
            }
            try {
                return JSON.parse(value);
            }
            catch (e) {
                return value;
            }
        }
        catch (e) {
            return null;
        }
    };
    Cookie.prototype.set = function (key, value) {
        if (typeof value === 'string') {
            jar.set(key, value, this.opts());
        }
        else if (value === null) {
            jar.remove(key, this.opts());
        }
        else {
            jar.set(key, JSON.stringify(value), this.opts());
        }
    };
    Cookie.prototype.remove = function (key) {
        return jar.remove(key, this.opts());
    };
    Object.defineProperty(Cookie.prototype, "type", {
        get: function () {
            return 'cookie';
        },
        enumerable: false,
        configurable: true
    });
    return Cookie;
}(Store));
export { Cookie };
var localStorageWarning = function (key, state) {
    console.warn("Unable to access ".concat(key, ", localStorage may be ").concat(state));
};
var LocalStorage = /** @class */ (function (_super) {
    __extends(LocalStorage, _super);
    function LocalStorage() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    LocalStorage.available = function () {
        var test = 'test';
        try {
            localStorage.setItem(test, test);
            localStorage.removeItem(test);
            return true;
        }
        catch (e) {
            return false;
        }
    };
    LocalStorage.prototype.get = function (key) {
        try {
            var val = localStorage.getItem(key);
            if (val === null) {
                return null;
            }
            try {
                return JSON.parse(val);
            }
            catch (e) {
                return val;
            }
        }
        catch (err) {
            localStorageWarning(key, 'unavailable');
            return null;
        }
    };
    LocalStorage.prototype.set = function (key, value) {
        try {
            localStorage.setItem(key, JSON.stringify(value));
        }
        catch (_a) {
            localStorageWarning(key, 'full');
        }
    };
    LocalStorage.prototype.remove = function (key) {
        try {
            return localStorage.removeItem(key);
        }
        catch (err) {
            localStorageWarning(key, 'unavailable');
        }
    };
    Object.defineProperty(LocalStorage.prototype, "type", {
        get: function () {
            return 'localStorage';
        },
        enumerable: false,
        configurable: true
    });
    return LocalStorage;
}(Store));
export { LocalStorage };
var UniversalStorage = /** @class */ (function () {
    function UniversalStorage(stores, storageOptions) {
        this.storageOptions = storageOptions;
        this.enabledStores = stores;
    }
    UniversalStorage.prototype.getStores = function (storeTypes) {
        var _this = this;
        var stores = [];
        this.enabledStores
            .filter(function (i) { return !storeTypes || (storeTypes === null || storeTypes === void 0 ? void 0 : storeTypes.includes(i)); })
            .forEach(function (storeType) {
            var storage = _this.storageOptions[storeType];
            if (storage !== undefined) {
                stores.push(storage);
            }
        });
        return stores;
    };
    /*
      This is to support few scenarios where:
      - value exist in one of the stores ( as a result of other stores being cleared from browser ) and we want to resync them
      - read values in AJS 1.0 format ( for customers after 1.0 --> 2.0 migration ) and then re-write them in AJS 2.0 format
    */
    /**
     * get value for the key from the stores. it will pick the first value found in the stores, and then sync the value to all the stores
     * if the found value is a number, it will be converted to a string. this is to support legacy behavior that existed in AJS 1.0
     * @param key key for the value to be retrieved
     * @param storeTypes optional array of store types to be used for performing get and sync
     * @returns value for the key or null if not found
     */
    UniversalStorage.prototype.getAndSync = function (key, storeTypes) {
        var val = this.get(key, storeTypes);
        // legacy behavior, getAndSync can change the type of a value from number to string (AJS 1.0 stores numerical values as a number)
        var coercedValue = (typeof val === 'number' ? val.toString() : val);
        this.set(key, coercedValue, storeTypes);
        return coercedValue;
    };
    /**
     * get value for the key from the stores. it will return the first value found in the stores
     * @param key key for the value to be retrieved
     * @param storeTypes optional array of store types to be used for retrieving the value
     * @returns value for the key or null if not found
     */
    UniversalStorage.prototype.get = function (key, storeTypes) {
        var val = null;
        for (var _i = 0, _a = this.getStores(storeTypes); _i < _a.length; _i++) {
            var store = _a[_i];
            val = store.get(key);
            if (val) {
                return val;
            }
        }
        return null;
    };
    /**
     * it will set the value for the key in all the stores
     * @param key key for the value to be stored
     * @param value value to be stored
     * @param storeTypes optional array of store types to be used for storing the value
     * @returns value that was stored
     */
    UniversalStorage.prototype.set = function (key, value, storeTypes) {
        for (var _i = 0, _a = this.getStores(storeTypes); _i < _a.length; _i++) {
            var store = _a[_i];
            store.set(key, value);
        }
    };
    /**
     * remove the value for the key from all the stores
     * @param key key for the value to be removed
     * @param storeTypes optional array of store types to be used for removing the value
     */
    UniversalStorage.prototype.clear = function (key, storeTypes) {
        for (var _i = 0, _a = this.getStores(storeTypes); _i < _a.length; _i++) {
            var store = _a[_i];
            store.remove(key);
        }
    };
    return UniversalStorage;
}());
export { UniversalStorage };
export function getAvailableStorageOptions(cookieOptions) {
    return {
        cookie: Cookie.available() ? new Cookie(cookieOptions) : undefined,
        localStorage: LocalStorage.available() ? new LocalStorage() : undefined,
        memory: new Store(),
    };
}
var User = /** @class */ (function () {
    function User(options, cookieOptions) {
        if (options === void 0) { options = defaults; }
        var _this = this;
        var _a, _b, _c, _d;
        this.options = {};
        this.id = function (id) {
            if (_this.options.disable) {
                return null;
            }
            var prevId = _this.identityStore.getAndSync(_this.idKey);
            if (id !== undefined) {
                _this.identityStore.set(_this.idKey, id);
                var changingIdentity = id !== prevId && prevId !== null && id !== null;
                if (changingIdentity) {
                    _this.anonymousId(null);
                }
            }
            var retId = _this.identityStore.getAndSync(_this.idKey);
            if (retId)
                return retId;
            var retLeg = _this.legacyUserStore.get(defaults.cookie.oldKey);
            return retLeg ? (typeof retLeg === 'object' ? retLeg.id : retLeg) : null;
        };
        this.anonymousId = function (id) {
            var _a, _b;
            if (_this.options.disable) {
                return null;
            }
            if (id === undefined) {
                var val = (_a = _this.identityStore.getAndSync(_this.anonKey)) !== null && _a !== void 0 ? _a : (_b = _this.legacySIO()) === null || _b === void 0 ? void 0 : _b[0];
                if (val) {
                    return val;
                }
            }
            if (id === null) {
                _this.identityStore.set(_this.anonKey, null);
                return _this.identityStore.getAndSync(_this.anonKey);
            }
            _this.identityStore.set(_this.anonKey, id !== null && id !== void 0 ? id : uuid());
            return _this.identityStore.getAndSync(_this.anonKey);
        };
        this.traits = function (traits) {
            var _a;
            if (_this.options.disable) {
                return;
            }
            if (traits === null) {
                traits = {};
            }
            if (traits) {
                _this.traitsStore.set(_this.traitsKey, traits !== null && traits !== void 0 ? traits : {});
            }
            return (_a = _this.traitsStore.get(_this.traitsKey)) !== null && _a !== void 0 ? _a : {};
        };
        this.options = options;
        this.cookieOptions = cookieOptions;
        this.idKey = (_b = (_a = options.cookie) === null || _a === void 0 ? void 0 : _a.key) !== null && _b !== void 0 ? _b : defaults.cookie.key;
        this.traitsKey = (_d = (_c = options.localStorage) === null || _c === void 0 ? void 0 : _c.key) !== null && _d !== void 0 ? _d : defaults.localStorage.key;
        this.anonKey = 'ajs_anonymous_id';
        var isDisabled = options.disable === true;
        var shouldPersist = options.persist !== false;
        var defaultStorageTargets = isDisabled
            ? []
            : shouldPersist
                ? ['localStorage', 'cookie', 'memory']
                : ['memory'];
        var storageOptions = getAvailableStorageOptions(cookieOptions);
        if (options.localStorageFallbackDisabled) {
            defaultStorageTargets = defaultStorageTargets.filter(function (t) { return t !== 'localStorage'; });
        }
        this.identityStore = new UniversalStorage(defaultStorageTargets, storageOptions);
        // using only cookies for legacy user store
        this.legacyUserStore = new UniversalStorage(defaultStorageTargets.filter(function (t) { return t !== 'localStorage' && t !== 'memory'; }), storageOptions);
        // using only localStorage / memory for traits store
        this.traitsStore = new UniversalStorage(defaultStorageTargets.filter(function (t) { return t !== 'cookie'; }), storageOptions);
        var legacyUser = this.legacyUserStore.get(defaults.cookie.oldKey);
        if (legacyUser && typeof legacyUser === 'object') {
            legacyUser.id && this.id(legacyUser.id);
            legacyUser.traits && this.traits(legacyUser.traits);
        }
        autoBind(this);
    }
    User.prototype.legacySIO = function () {
        var val = this.legacyUserStore.get('_sio');
        if (!val) {
            return null;
        }
        var _a = val.split('----'), anon = _a[0], user = _a[1];
        return [anon, user];
    };
    User.prototype.identify = function (id, traits) {
        if (this.options.disable) {
            return;
        }
        traits = traits !== null && traits !== void 0 ? traits : {};
        var currentId = this.id();
        if (currentId === null || currentId === id) {
            traits = __assign(__assign({}, this.traits()), traits);
        }
        if (id) {
            this.id(id);
        }
        this.traits(traits);
    };
    User.prototype.logout = function () {
        this.anonymousId(null);
        this.id(null);
        this.traits({});
    };
    User.prototype.reset = function () {
        this.logout();
        this.identityStore.clear(this.idKey);
        this.identityStore.clear(this.anonKey);
        this.traitsStore.clear(this.traitsKey);
    };
    User.prototype.load = function () {
        return new User(this.options, this.cookieOptions);
    };
    User.prototype.save = function () {
        return true;
    };
    User.defaults = defaults;
    return User;
}());
export { User };
var groupDefaults = {
    persist: true,
    cookie: {
        key: 'ajs_group_id',
    },
    localStorage: {
        key: 'ajs_group_properties',
    },
};
var Group = /** @class */ (function (_super) {
    __extends(Group, _super);
    function Group(options, cookie) {
        if (options === void 0) { options = groupDefaults; }
        var _this = _super.call(this, options, cookie) || this;
        _this.anonymousId = function (_id) {
            return undefined;
        };
        autoBind(_this);
        return _this;
    }
    return Group;
}(User));
export { Group };
//# sourceMappingURL=index.js.map