import { PostHog } from './posthog-core';
export declare enum ConsentStatus {
    PENDING = -1,
    DENIED = 0,
    GRANTED = 1
}
/**
 * ConsentManager provides tools for managing user consent as configured by the application.
 */
export declare class ConsentManager {
    private _instance;
    private _persistentStore?;
    constructor(_instance: PostHog);
    private get _config();
    get consent(): ConsentStatus;
    isOptedOut(): boolean;
    isOptedIn(): boolean;
    isExplicitlyOptedOut(): boolean;
    optInOut(isOptedIn: boolean): void;
    reset(): void;
    private get _storageKey();
    private get _storedConsent();
    private get _storage();
    private _getDnt;
}
