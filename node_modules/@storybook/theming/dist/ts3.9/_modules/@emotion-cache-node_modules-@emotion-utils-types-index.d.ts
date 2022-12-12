// Definitions by: Junyoung Clare Jang <https://github.com/Ailrun>
// TypeScript Version: 2.2
export interface RegisteredCache {
    [key: string]: string;
}
export interface StyleSheet {
    container: HTMLElement;
    nonce?: string;
    key: string;
    insert(rule: string): void;
    flush(): void;
    tags: Array<HTMLStyleElement>;
}
export interface EmotionCache {
    inserted: {
        [key: string]: string | true;
    };
    registered: RegisteredCache;
    sheet: StyleSheet;
    key: string;
    compat?: true;
    nonce?: string;
    insert(selector: string, serialized: SerializedStyles, sheet: StyleSheet, shouldCache: boolean): string | void;
}
export interface SerializedStyles {
    name: string;
    styles: string;
    map?: string;
    next?: SerializedStyles;
}
export const isBrowser: boolean;
export function getRegisteredStyles(registered: RegisteredCache, registeredStyles: Array<string>, classNames: string): string;
export function registerStyles(cache: EmotionCache, serialized: SerializedStyles, isStringTag: boolean): void;
export function insertStyles(cache: EmotionCache, serialized: SerializedStyles, isStringTag: boolean): string | void;