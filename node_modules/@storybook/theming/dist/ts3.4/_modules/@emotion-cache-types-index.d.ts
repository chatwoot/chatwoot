// Definitions by: Junyoung Clare Jang <https://github.com/Ailrun>
// TypeScript Version: 2.2
import { EmotionCache } from "./@emotion-cache-node_modules-@emotion-utils-types-index";
export { EmotionCache };
export interface StylisElement {
    type: string;
    value: string;
    props: Array<string> | string;
    root: StylisElement | null;
    parent: StylisElement | null;
    children: Array<StylisElement> | string;
    line: number;
    column: number;
    length: number;
    return: string;
}
export type StylisPluginCallback = (element: StylisElement, index: number, children: Array<StylisElement>, callback: StylisPluginCallback) => string | void;
export type StylisPlugin = (element: StylisElement, index: number, children: Array<StylisElement>, callback: StylisPluginCallback) => string | void;
export interface Options {
    nonce?: string;
    stylisPlugins?: Array<StylisPlugin>;
    key: string;
    container?: HTMLElement;
    speedy?: boolean;
    /** @deprecate use `insertionPoint` instead */
    prepend?: boolean;
    insertionPoint?: HTMLElement;
}
export default function createCache(options: Options): EmotionCache;
