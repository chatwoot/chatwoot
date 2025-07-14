import { Event, ScopeData } from '@sentry/types';
/**
 * Applies data from the scope to the event and runs all event processors on it.
 */
export declare function applyScopeDataToEvent(event: Event, data: ScopeData): void;
/** Merge data of two scopes together. */
export declare function mergeScopeData(data: ScopeData, mergeData: ScopeData): void;
/**
 * Merges certain scope data. Undefined values will overwrite any existing values.
 * Exported only for tests.
 */
export declare function mergeAndOverwriteScopeData<Prop extends 'extra' | 'tags' | 'user' | 'contexts' | 'sdkProcessingMetadata', Data extends ScopeData>(data: Data, prop: Prop, mergeVal: Data[Prop]): void;
/** Exported only for tests */
export declare function mergeArray<Prop extends 'breadcrumbs' | 'fingerprint'>(event: Event, prop: Prop, mergeVal: ScopeData[Prop]): void;
//# sourceMappingURL=applyScopeDataToEvent.d.ts.map
