import type { RecordPlugin } from '@rrweb/types';
import { CapturedNetworkRequest, Headers, NetworkRecordOptions } from '../../../types';
export type NetworkData = {
    requests: CapturedNetworkRequest[];
    isInitial?: boolean;
};
export declare function findLast<T>(array: Array<T>, predicate: (value: T) => boolean): T | undefined;
export declare function shouldRecordBody({ type, recordBody, headers, url, }: {
    type: 'request' | 'response';
    headers: Headers;
    url: string | URL | RequestInfo;
    recordBody: NetworkRecordOptions['recordBody'];
}): boolean;
export declare const NETWORK_PLUGIN_NAME = "rrweb/network@1";
export declare const getRecordNetworkPlugin: (options?: NetworkRecordOptions) => RecordPlugin;
