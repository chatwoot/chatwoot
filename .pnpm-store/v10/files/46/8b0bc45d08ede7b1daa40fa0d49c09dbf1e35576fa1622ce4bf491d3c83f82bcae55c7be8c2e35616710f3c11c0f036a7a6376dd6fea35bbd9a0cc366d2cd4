import { NetworkRecordOptions, PostHogConfig } from '../../types';
export declare const defaultNetworkOptions: Required<NetworkRecordOptions>;
/**
 *  whether a maskRequestFn is provided or not,
 *  we ensure that we remove the denied header from requests
 *  we _never_ want to record that header by accident
 *  if someone complains then we'll add an opt-in to let them override it
 */
export declare const buildNetworkRequestOptions: (instanceConfig: PostHogConfig, remoteNetworkOptions: Pick<NetworkRecordOptions, "recordHeaders" | "recordBody" | "recordPerformance" | "payloadHostDenyList">) => NetworkRecordOptions;
