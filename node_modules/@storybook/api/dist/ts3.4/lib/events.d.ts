import { ComposedRef } from '../modules/refs';
import { API } from '../index';
interface Meta {
    ref?: ComposedRef;
    source?: string;
    sourceType?: 'local' | 'external';
    sourceLocation?: string;
    refId?: string;
    v?: number;
    type: string;
}
export declare const getEventMetadata: (context: Meta, fullAPI: API) => {
    source: string;
    sourceType: string;
    sourceLocation: string;
    refId: string;
    ref: ComposedRef;
    type: string;
};
export {};
