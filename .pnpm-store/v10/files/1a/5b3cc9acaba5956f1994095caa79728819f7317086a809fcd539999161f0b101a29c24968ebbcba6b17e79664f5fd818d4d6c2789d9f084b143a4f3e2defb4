import { Traits } from '../events';
export type ID = string | null | undefined;
export interface UserOptions {
    /**
     * Disables storing any data about the user.
     */
    disable?: boolean;
    localStorageFallbackDisabled?: boolean;
    persist?: boolean;
    cookie?: {
        key?: string;
        oldKey?: string;
    };
    localStorage?: {
        key: string;
    };
}
export type StoreType = 'cookie' | 'localStorage' | 'memory';
type StorageObject = Record<string, unknown>;
declare class Store {
    private cache;
    get<T>(key: string): T | null;
    set<T>(key: string, value: T | null): void;
    remove(key: string): void;
    get type(): StoreType;
}
export declare class Cookie extends Store {
    static available(): boolean;
    static get defaults(): CookieOptions;
    private options;
    constructor(options?: CookieOptions);
    private opts;
    get<T>(key: string): T | null;
    set<T>(key: string, value: T): void;
    remove(key: string): void;
    get type(): StoreType;
}
export declare class LocalStorage extends Store {
    static available(): boolean;
    get<T>(key: string): T | null;
    set<T>(key: string, value: T): void;
    remove(key: string): void;
    get type(): StoreType;
}
export interface CookieOptions {
    maxage?: number;
    domain?: string;
    path?: string;
    secure?: boolean;
    sameSite?: string;
}
export declare class UniversalStorage<Data extends StorageObject = StorageObject> {
    private enabledStores;
    private storageOptions;
    constructor(stores: StoreType[], storageOptions: StorageOptions);
    private getStores;
    /**
     * get value for the key from the stores. it will pick the first value found in the stores, and then sync the value to all the stores
     * if the found value is a number, it will be converted to a string. this is to support legacy behavior that existed in AJS 1.0
     * @param key key for the value to be retrieved
     * @param storeTypes optional array of store types to be used for performing get and sync
     * @returns value for the key or null if not found
     */
    getAndSync<K extends keyof Data>(key: K, storeTypes?: StoreType[]): Data[K] | null;
    /**
     * get value for the key from the stores. it will return the first value found in the stores
     * @param key key for the value to be retrieved
     * @param storeTypes optional array of store types to be used for retrieving the value
     * @returns value for the key or null if not found
     */
    get<K extends keyof Data>(key: K, storeTypes?: StoreType[]): Data[K] | null;
    /**
     * it will set the value for the key in all the stores
     * @param key key for the value to be stored
     * @param value value to be stored
     * @param storeTypes optional array of store types to be used for storing the value
     * @returns value that was stored
     */
    set<K extends keyof Data>(key: K, value: Data[K] | null, storeTypes?: StoreType[]): void;
    /**
     * remove the value for the key from all the stores
     * @param key key for the value to be removed
     * @param storeTypes optional array of store types to be used for removing the value
     */
    clear<K extends keyof Data>(key: K, storeTypes?: StoreType[]): void;
}
type StorageOptions = {
    cookie: Cookie | undefined;
    localStorage: LocalStorage | undefined;
    memory: Store;
};
export declare function getAvailableStorageOptions(cookieOptions?: CookieOptions): StorageOptions;
export declare class User {
    static defaults: {
        persist: boolean;
        cookie: {
            key: string;
            oldKey: string;
        };
        localStorage: {
            key: string;
        };
    };
    private idKey;
    private traitsKey;
    private anonKey;
    private cookieOptions?;
    private legacyUserStore;
    private traitsStore;
    private identityStore;
    options: UserOptions;
    constructor(options?: UserOptions, cookieOptions?: CookieOptions);
    id: (id?: ID) => ID;
    private legacySIO;
    anonymousId: (id?: ID) => ID;
    traits: (traits?: Traits | null) => Traits | undefined;
    identify(id?: ID, traits?: Traits): void;
    logout(): void;
    reset(): void;
    load(): User;
    save(): boolean;
}
export declare class Group extends User {
    constructor(options?: UserOptions, cookie?: CookieOptions);
    anonymousId: (_id?: ID) => ID;
}
export {};
//# sourceMappingURL=index.d.ts.map