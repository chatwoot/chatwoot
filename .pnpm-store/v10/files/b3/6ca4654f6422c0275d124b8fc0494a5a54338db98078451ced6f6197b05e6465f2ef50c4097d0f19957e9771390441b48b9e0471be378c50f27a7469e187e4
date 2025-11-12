import type { eventWithTime } from '@rrweb/types';
import { SnapshotBuffer } from './sessionrecording';
export declare function circularReferenceReplacer(): (this: any, _key: string, value: any) => any;
export declare function estimateSize(sizeable: unknown): number;
export declare const replacementImageURI = "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTYiIGhlaWdodD0iMTYiIHZpZXdCb3g9IjAgMCAxNiAxNiIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPHJlY3Qgd2lkdGg9IjE2IiBoZWlnaHQ9IjE2IiBmaWxsPSJibGFjayIvPgo8cGF0aCBkPSJNOCAwSDE2TDAgMTZWOEw4IDBaIiBmaWxsPSIjMkQyRDJEIi8+CjxwYXRoIGQ9Ik0xNiA4VjE2SDhMMTYgOFoiIGZpbGw9IiMyRDJEMkQiLz4KPC9zdmc+Cg==";
export declare const FULL_SNAPSHOT_EVENT_TYPE = 2;
export declare const META_EVENT_TYPE = 4;
export declare const INCREMENTAL_SNAPSHOT_EVENT_TYPE = 3;
export declare const PLUGIN_EVENT_TYPE = 6;
export declare const MUTATION_SOURCE_TYPE = 0;
export declare const MAX_MESSAGE_SIZE = 5000000;
export declare function ensureMaxMessageSize(data: eventWithTime): {
    event: eventWithTime;
    size: number;
};
export declare const CONSOLE_LOG_PLUGIN_NAME = "rrweb/console@1";
export declare function truncateLargeConsoleLogs(_event: eventWithTime): eventWithTime;
export declare const SEVEN_MEGABYTES: number;
export declare function splitBuffer(buffer: SnapshotBuffer, sizeLimit?: number): SnapshotBuffer[];
