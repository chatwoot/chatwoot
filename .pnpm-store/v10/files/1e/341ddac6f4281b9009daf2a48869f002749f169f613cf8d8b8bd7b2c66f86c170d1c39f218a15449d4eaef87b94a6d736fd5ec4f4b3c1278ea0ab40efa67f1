import type { SessionIdManager } from './sessionid';
import type { PostHogPersistence } from './posthog-persistence';
import type { PostHog } from './posthog-core';
interface LegacySessionSourceProps {
    initialPathName: string;
    referringDomain: string;
    utm_medium?: string;
    utm_source?: string;
    utm_campaign?: string;
    utm_content?: string;
    utm_term?: string;
}
interface CurrentSessionSourceProps {
    r: string;
    u: string | undefined;
}
interface StoredSessionSourceProps {
    sessionId: string;
    props: LegacySessionSourceProps | CurrentSessionSourceProps;
}
export declare class SessionPropsManager {
    private readonly _instance;
    private readonly _sessionIdManager;
    private readonly _persistence;
    private readonly _sessionSourceParamGenerator;
    constructor(instance: PostHog, sessionIdManager: SessionIdManager, persistence: PostHogPersistence, sessionSourceParamGenerator?: (instance?: PostHog) => LegacySessionSourceProps | CurrentSessionSourceProps);
    _getStored(): StoredSessionSourceProps | undefined;
    _onSessionIdCallback: (sessionId: string) => void;
    getSetOnceProps(): Record<string, any>;
    getSessionProps(): Record<string, any>;
}
export {};
