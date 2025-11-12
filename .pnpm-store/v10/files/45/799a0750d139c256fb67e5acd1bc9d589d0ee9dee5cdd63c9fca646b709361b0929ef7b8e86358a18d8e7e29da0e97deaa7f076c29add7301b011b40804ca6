import { PostHog } from './posthog-core';
import { FlagsResponse, FeatureFlagsCallback, EarlyAccessFeatureCallback, Properties, JsonType, RemoteConfigFeatureFlagCallback, EarlyAccessFeatureStage, FeatureFlagDetail } from './types';
import { PostHogPersistence } from './posthog-persistence';
export declare const filterActiveFeatureFlags: (featureFlags?: Record<string, string | boolean>) => Record<string, string | boolean>;
export declare const parseFlagsResponse: (response: Partial<FlagsResponse>, persistence: PostHogPersistence, currentFlags?: Record<string, string | boolean>, currentFlagPayloads?: Record<string, JsonType>, currentFlagDetails?: Record<string, FeatureFlagDetail>) => void;
type FeatureFlagOverrides = {
    [flagName: string]: string | boolean;
};
type FeatureFlagPayloadOverrides = {
    [flagName: string]: JsonType;
};
type FeatureFlagOverrideOptions = {
    flags?: boolean | string[] | FeatureFlagOverrides;
    payloads?: FeatureFlagPayloadOverrides;
    suppressWarning?: boolean;
};
type OverrideFeatureFlagsOptions = boolean | string[] | FeatureFlagOverrides | FeatureFlagOverrideOptions;
export declare enum QuotaLimitedResource {
    FeatureFlags = "feature_flags",
    Recordings = "recordings"
}
export declare class PostHogFeatureFlags {
    private _instance;
    _override_warning: boolean;
    featureFlagEventHandlers: FeatureFlagsCallback[];
    $anon_distinct_id: string | undefined;
    private _hasLoadedFlags;
    private _requestInFlight;
    private _reloadingDisabled;
    private _additionalReloadRequested;
    private _reloadDebouncer?;
    private _flagsCalled;
    private _flagsLoadedFromRemote;
    constructor(_instance: PostHog);
    flags(): void;
    get hasLoadedFlags(): boolean;
    getFlags(): string[];
    getFlagsWithDetails(): Record<string, FeatureFlagDetail>;
    getFlagVariants(): Record<string, string | boolean>;
    getFlagPayloads(): Record<string, JsonType>;
    /**
     * Reloads feature flags asynchronously.
     *
     * Constraints:
     *
     * 1. Avoid parallel requests
     * 2. Delay a few milliseconds after each reloadFeatureFlags call to batch subsequent changes together
     */
    reloadFeatureFlags(): void;
    private _clearDebouncer;
    ensureFlagsLoaded(): void;
    setAnonymousDistinctId(anon_distinct_id: string): void;
    setReloadingPaused(isPaused: boolean): void;
    /**
     * NOTE: This is used both for flags and remote config. Once the RemoteConfig is fully released this will essentially only
     * be for flags and can eventually be replaced with the new flags endpoint
     */
    _callFlagsEndpoint(options?: {
        disableFlags?: boolean;
    }): void;
    getFeatureFlag(key: string, options?: {
        send_event?: boolean;
    }): boolean | string | undefined;
    getFeatureFlagDetails(key: string): FeatureFlagDetail | undefined;
    getFeatureFlagPayload(key: string): JsonType;
    getRemoteConfigPayload(key: string, callback: RemoteConfigFeatureFlagCallback): void;
    isFeatureEnabled(key: string, options?: {
        send_event?: boolean;
    }): boolean | undefined;
    addFeatureFlagsHandler(handler: FeatureFlagsCallback): void;
    removeFeatureFlagsHandler(handler: FeatureFlagsCallback): void;
    receivedFeatureFlags(response: Partial<FlagsResponse>, errorsLoading?: boolean): void;
    /**
     * @deprecated Use overrideFeatureFlags instead. This will be removed in a future version.
     */
    override(flags: boolean | string[] | Record<string, string | boolean>, suppressWarning?: boolean): void;
    /**
     * Override feature flags on the client-side. Useful for setting non-persistent feature flags,
     * or for testing/debugging feature flags in the PostHog app.
     *
     * ### Usage:
     *
     *     - posthog.featureFlags.overrideFeatureFlags(false) // clear all overrides
     *     - posthog.featureFlags.overrideFeatureFlags(['beta-feature']) // enable flags
     *     - posthog.featureFlags.overrideFeatureFlags({'beta-feature': 'variant'}) // set variants
     *     - posthog.featureFlags.overrideFeatureFlags({ // set both flags and payloads
     *         flags: {'beta-feature': 'variant'},
     *         payloads: { 'beta-feature': { someData: true } }
     *       })
     *     - posthog.featureFlags.overrideFeatureFlags({ // only override payloads
     *         payloads: { 'beta-feature': { someData: true } }
     *       })
     */
    overrideFeatureFlags(overrideOptions: OverrideFeatureFlagsOptions): void;
    onFeatureFlags(callback: FeatureFlagsCallback): () => void;
    updateEarlyAccessFeatureEnrollment(key: string, isEnrolled: boolean, stage?: string): void;
    getEarlyAccessFeatures(callback: EarlyAccessFeatureCallback, force_reload?: boolean, stages?: EarlyAccessFeatureStage[]): void;
    _prepareFeatureFlagsForCallbacks(): {
        flags: string[];
        flagVariants: Record<string, string | boolean>;
    };
    _fireFeatureFlagsCallbacks(errorsLoading?: boolean): void;
    /**
     * Set override person properties for feature flags.
     * This is used when dealing with new persons / where you don't want to wait for ingestion
     * to update user properties.
     */
    setPersonPropertiesForFlags(properties: Properties, reloadFeatureFlags?: boolean): void;
    resetPersonPropertiesForFlags(): void;
    /**
     * Set override group properties for feature flags.
     * This is used when dealing with new groups / where you don't want to wait for ingestion
     * to update properties.
     * Takes in an object, the key of which is the group type.
     * For example:
     *     setGroupPropertiesForFlags({'organization': { name: 'CYZ', employees: '11' } })
     */
    setGroupPropertiesForFlags(properties: {
        [type: string]: Properties;
    }, reloadFeatureFlags?: boolean): void;
    resetGroupPropertiesForFlags(group_type?: string): void;
    reset(): void;
}
export {};
