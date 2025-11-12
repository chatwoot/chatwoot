/**
 * Integrate Sentry with PostHog. This will add a direct link to the person in Sentry, and an $exception event in PostHog
 *
 * ### Usage
 *
 *     Sentry.init({
 *          dsn: 'https://example',
 *          integrations: [
 *              new posthog.SentryIntegration(posthog)
 *          ]
 *     })
 *
 * @param {Object} [posthog] The posthog object
 * @param {string} [organization] Optional: The Sentry organization, used to send a direct link from PostHog to Sentry
 * @param {Number} [projectId] Optional: The Sentry project id, used to send a direct link from PostHog to Sentry
 * @param {string} [prefix] Optional: Url of a self-hosted sentry instance (default: https://sentry.io/organizations/)
 * @param {SeverityLevel[] | '*'} [severityAllowList] Optional: send events matching the provided levels. Use '*' to send all events (default: ['error'])
 */
import { PostHog } from '../posthog-core';
import { SeverityLevel } from '../types';
type _SentryEvent = any;
type _SentryEventProcessor = any;
type _SentryHub = any;
interface _SentryIntegration {
    name: string;
    processEvent(event: _SentryEvent): _SentryEvent;
}
interface _SentryIntegrationClass {
    name: string;
    setupOnce(addGlobalEventProcessor: (callback: _SentryEventProcessor) => void, getCurrentHub: () => _SentryHub): void;
}
export type SentryIntegrationOptions = {
    organization?: string;
    projectId?: number;
    prefix?: string;
    severityAllowList?: SeverityLevel[] | '*';
};
export declare function createEventProcessor(_posthog: PostHog, { organization, projectId, prefix, severityAllowList }?: SentryIntegrationOptions): (event: _SentryEvent) => _SentryEvent;
export declare function sentryIntegration(_posthog: PostHog, options?: SentryIntegrationOptions): _SentryIntegration;
export declare class SentryIntegration implements _SentryIntegrationClass {
    name: string;
    setupOnce: (addGlobalEventProcessor: (callback: _SentryEventProcessor) => void, getCurrentHub: () => _SentryHub) => void;
    constructor(_posthog: PostHog, organization?: string, projectId?: number, prefix?: string, severityAllowList?: SeverityLevel[] | '*');
}
export {};
