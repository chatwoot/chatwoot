import { FeatureFlagDetail, FeatureFlagValue, PostHogFlagsResponse, PostHogV1FlagsResponse, PostHogV2FlagsResponse, PartialWithRequired, PostHogFeatureFlagsResponse } from './types';
export declare const normalizeFlagsResponse: (flagsResponse: PartialWithRequired<PostHogV2FlagsResponse, "flags"> | PartialWithRequired<PostHogV1FlagsResponse, "featureFlags" | "featureFlagPayloads">) => PostHogFeatureFlagsResponse;
/**
 * Get the flag values from the flags v4 response.
 * @param flags - The flags
 * @returns The flag values
 */
export declare const getFlagValuesFromFlags: (flags: PostHogFlagsResponse["flags"]) => PostHogFlagsResponse["featureFlags"];
/**
 * Get the payloads from the flags v4 response.
 * @param flags - The flags
 * @returns The payloads
 */
export declare const getPayloadsFromFlags: (flags: PostHogFlagsResponse["flags"]) => PostHogFlagsResponse["featureFlagPayloads"];
/**
 * Get the flag details from the legacy v1 flags and payloads. As such, it will lack the reason, id, version, and description.
 * @param flagsResponse - The flags response
 * @returns The flag details
 */
export declare const getFlagDetailsFromFlagsAndPayloads: (flagsResponse: PostHogFeatureFlagsResponse) => PostHogFlagsResponse["flags"];
export declare const getFeatureFlagValue: (detail: FeatureFlagDetail | undefined) => FeatureFlagValue | undefined;
export declare const parsePayload: (response: any) => any;
/**
 * Get the normalized flag details from the flags and payloads.
 * This is used to convert things like boostrap and stored feature flags and payloads to the v4 format.
 * This helps us ensure backwards compatibility.
 * If a key exists in the featureFlagPayloads that is not in the featureFlags, we treat it as a true feature flag.
 *
 * @param featureFlags - The feature flags
 * @param featureFlagPayloads - The feature flag payloads
 * @returns The normalized flag details
 */
export declare const createFlagsResponseFromFlagsAndPayloads: (featureFlags: PostHogV1FlagsResponse["featureFlags"], featureFlagPayloads: PostHogV1FlagsResponse["featureFlagPayloads"]) => PostHogFeatureFlagsResponse;
export declare const updateFlagValue: (flag: FeatureFlagDetail, value: FeatureFlagValue) => FeatureFlagDetail;
//# sourceMappingURL=featureFlagUtils.d.ts.map