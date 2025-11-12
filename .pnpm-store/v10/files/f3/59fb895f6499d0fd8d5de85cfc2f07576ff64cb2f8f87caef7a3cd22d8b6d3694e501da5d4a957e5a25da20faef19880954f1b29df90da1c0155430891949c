/**
 * Extend Segment with extra PostHog JS functionality. Required for things like Recordings and feature flags to work correctly.
 *
 * ### Usage
 *
 *  ```js
 *  // After your standard segment anyalytics install
 *  analytics.load("GOEDfA21zZTtR7clsBuDvmBKAtAdZ6Np");
 *
 *  analytics.ready(() => {
 *    posthog.init('<posthog-api-key>', {
 *      capture_pageview: false,
 *      segment: window.analytics, // NOTE: Be sure to use window.analytics here!
 *    });
 *    window.analytics.page();
 *  })
 *  ```
 */
import { PostHog } from '../posthog-core';
export type SegmentUser = {
    anonymousId(): string | undefined;
    id(): string | undefined;
};
export type SegmentAnalytics = {
    user: () => SegmentUser | Promise<SegmentUser>;
    register: (integration: SegmentPlugin) => Promise<void>;
};
export interface SegmentContext {
    event: {
        event: string;
        userId?: string;
        anonymousId?: string;
        properties: any;
    };
}
type SegmentFunction = (ctx: SegmentContext) => Promise<SegmentContext> | SegmentContext;
export interface SegmentPlugin {
    name: string;
    version: string;
    type: 'enrichment';
    isLoaded: () => boolean;
    load: (ctx: SegmentContext, instance: any, config?: any) => Promise<unknown>;
    unload?: (ctx: SegmentContext, instance: any) => Promise<unknown> | unknown;
    ready?: () => Promise<unknown>;
    track?: SegmentFunction;
    identify?: SegmentFunction;
    page?: SegmentFunction;
    group?: SegmentFunction;
    alias?: SegmentFunction;
    screen?: SegmentFunction;
}
export declare function setupSegmentIntegration(posthog: PostHog, done: () => void): void;
export {};
