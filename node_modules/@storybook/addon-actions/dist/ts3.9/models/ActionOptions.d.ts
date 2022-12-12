import type { Options as TelejsonOptions } from 'telejson';
interface Options {
    depth: number;
    clearOnStoryChange: boolean;
    limit: number;
}
export declare type ActionOptions = Partial<Options> & Partial<TelejsonOptions>;
export {};
