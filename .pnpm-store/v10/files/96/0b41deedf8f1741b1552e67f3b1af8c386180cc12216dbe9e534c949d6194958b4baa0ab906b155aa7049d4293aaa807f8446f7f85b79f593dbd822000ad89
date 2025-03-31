import { Context } from '../context';
import { Callback, Options, EventProperties, SegmentEvent, Traits, GroupTraits, UserTraits } from '../events';
import { ID, User } from '../user';
/**
 * Helper for the track method
 */
export declare function resolveArguments(eventName: string | SegmentEvent, properties?: EventProperties | Callback, options?: Options | Callback, callback?: Callback): [string, EventProperties | Callback, Options, Callback | undefined];
/**
 * Helper for page, screen methods
 */
export declare function resolvePageArguments(category?: string | object, name?: string | object | Callback, properties?: EventProperties | Options | Callback | null, options?: Options | Callback, callback?: Callback): [
    string | null,
    string | null,
    EventProperties,
    Options,
    Callback | undefined
];
/**
 * Helper for group, identify methods
 */
export declare const resolveUserArguments: <T extends Traits, U extends User>(user: U) => ResolveUser<T>;
/**
 * Helper for alias method
 */
export declare function resolveAliasArguments(to: string | number, from?: string | number | Options, options?: Options | Callback, callback?: Callback): [string, string | null, Options, Callback | undefined];
type ResolveUser<T extends Traits> = (id?: ID | object, traits?: T | Callback | null, options?: Options | Callback, callback?: Callback) => [ID, T, Options, Callback | undefined];
export type IdentifyParams = Parameters<ResolveUser<UserTraits>>;
export type GroupParams = Parameters<ResolveUser<GroupTraits>>;
export type EventParams = Parameters<typeof resolveArguments>;
export type PageParams = Parameters<typeof resolvePageArguments>;
export type AliasParams = Parameters<typeof resolveAliasArguments>;
export type DispatchedEvent = Context;
export {};
//# sourceMappingURL=index.d.ts.map