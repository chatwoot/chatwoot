import { PostHog } from '../posthog-core';
/**
 * This class is used to capture pageview events when the user navigates using the history API (pushState, replaceState)
 * and when the user navigates using the browser's back/forward buttons.
 *
 * The behavior is controlled by the `capture_pageview` configuration option:
 * - When set to `'history_change'`, this class will capture pageviews on history API changes
 */
export declare class HistoryAutocapture {
    private _instance;
    private _popstateListener;
    private _lastPathname;
    constructor(instance: PostHog);
    get isEnabled(): boolean;
    startIfEnabled(): void;
    stop(): void;
    monitorHistoryChanges(): void;
    private _capturePageview;
    private _setupPopstateListener;
}
