declare namespace store {
  export const local: StoreAPI;
  export const session: StoreAPI;
  export const page: StoreAPI;

  export function area(id: string, area: globalThis.Storage): StoreAPI;
  export function set(key: any, data: any, overwrite?: boolean): any;
  export function setAll(data: Object, overwrite?: boolean): StoredData;
  export function add(key: any, data: any): any;
  export function get(key: any, alt?: any): any;
  export function getAll(fillObj?: StoredData): StoredData;
  export function transact(key: any, fn: (data: any) => any, alt?: any): StoreAPI;
  export function clear(): StoreAPI;
  export function has(key: any): boolean;
  export function remove(key: any, alt?: any): any;
  export function each(callback: (key: any, data: any) => false | any, value?: any): StoreAPI;
  export function keys(fillList?: string[]): string[];
  export function size(): number;
  export function clearAll(): StoreAPI;
  export function isFake(): boolean;
  export function namespace(namespace: string, noSession?: true): StoreAPI;

  export interface StoreAPI {
    clear(): StoreAPI;
    clearAll(): StoreAPI;
    each(callback: (key: any, data: any) => false | any): StoreAPI;
    get(key: any, alt?: any): any;
    getAll(fillObj?: StoredData): StoredData;
    has(key: any): boolean;
    isFake(): boolean;
    keys(fillList?: string[]): string[];
    namespace(namespace: string, noSession?: true): StoreAPI;
    remove(key: any, alt?: any): any;
    set(key: any, data: any, overwrite?: boolean): any;
    setAll(data: Object, overwrite?: boolean): StoredData;
    add(key: any, data: any): any;
    size(): number;
    transact(key: any, fn: (data: any) => any, alt?: any): StoreAPI;
  }

  export interface StoredData {
    [key: string]: any;
  }
}

declare function store(key: any, fn: (data: any) => any, alt?: any): store.StoreAPI
declare function store(key: any, data: any): any
declare function store(clearIfFalsy: false | 0): store.StoreAPI
declare function store(key: any): any
declare function store(obj: Object): store.StoredData
declare function store(eachFn: (key: any, data: any) => false | any, value?: any): store.StoredData

export = store;
