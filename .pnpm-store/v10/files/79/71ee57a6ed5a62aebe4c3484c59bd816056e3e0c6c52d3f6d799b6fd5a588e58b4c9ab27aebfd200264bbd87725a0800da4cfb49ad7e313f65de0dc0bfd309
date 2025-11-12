import { JsonType, PostHogCore, PostHogCoreOptions, PostHogFetchOptions, PostHogFetchResponse, PostHogFlagsResponse } from '../../src';
export interface PostHogCoreTestClientMocks {
    fetch: jest.Mock<Promise<PostHogFetchResponse>, [string, PostHogFetchOptions]>;
    storage: {
        getItem: jest.Mock<any | undefined, [string]>;
        setItem: jest.Mock<void, [string, any | null]>;
    };
}
export declare class PostHogCoreTestClient extends PostHogCore {
    private mocks;
    _cachedDistinctId?: string;
    constructor(mocks: PostHogCoreTestClientMocks, apiKey: string, options?: PostHogCoreOptions);
    getFlags(distinctId: string, groups?: Record<string, string | number>, personProperties?: Record<string, string>, groupProperties?: Record<string, Record<string, string>>, extraPayload?: Record<string, any>): Promise<PostHogFlagsResponse | undefined>;
    getPersistedProperty<T>(key: string): T;
    setPersistedProperty<T>(key: string, value: T | null): void;
    fetch(url: string, options: PostHogFetchOptions): Promise<PostHogFetchResponse>;
    getLibraryId(): string;
    getLibraryVersion(): string;
    getCustomUserAgent(): string;
}
export declare const createTestClient: (apiKey: string, options?: PostHogCoreOptions, setupMocks?: (mocks: PostHogCoreTestClientMocks) => void, storageCache?: {
    [key: string]: string | JsonType;
}) => [PostHogCoreTestClient, PostHogCoreTestClientMocks];
//# sourceMappingURL=PostHogCoreTestClient.d.ts.map