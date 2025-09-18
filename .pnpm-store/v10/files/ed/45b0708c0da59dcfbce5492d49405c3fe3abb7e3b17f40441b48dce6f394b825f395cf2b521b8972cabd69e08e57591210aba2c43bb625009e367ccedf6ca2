import { User } from './user';
export interface RequestSession {
    status?: RequestSessionStatus;
}
export interface Session {
    sid: string;
    did?: string | number;
    init: boolean;
    timestamp: number;
    started: number;
    duration?: number;
    status: SessionStatus;
    release?: string;
    environment?: string;
    userAgent?: string;
    ipAddress?: string;
    errors: number;
    user?: User | null;
    ignoreDuration: boolean;
    abnormal_mechanism?: string;
    /**
     * Overrides default JSON serialization of the Session because
     * the Sentry servers expect a slightly different schema of a session
     * which is described in the interface @see SerializedSession in this file.
     *
     * @return a Sentry-backend conforming JSON object of the session
     */
    toJSON(): SerializedSession;
}
export type SessionContext = Partial<Session>;
export type SessionStatus = 'ok' | 'exited' | 'crashed' | 'abnormal';
export type RequestSessionStatus = 'ok' | 'errored' | 'crashed';
/** JSDoc */
export interface SessionAggregates {
    attrs?: {
        environment?: string;
        release?: string;
    };
    aggregates: Array<AggregationCounts>;
}
export interface SessionFlusherLike {
    /**
     * Increments the Session Status bucket in SessionAggregates Object corresponding to the status of the session
     * captured
     */
    incrementSessionStatusCount(): void;
    /** Empties Aggregate Buckets and Sends them to Transport Buffer */
    flush(): void;
    /** Clears setInterval and calls flush */
    close(): void;
}
export interface AggregationCounts {
    started: string;
    errored?: number;
    exited?: number;
    crashed?: number;
}
export interface SerializedSession {
    init: boolean;
    sid: string;
    did?: string;
    timestamp: string;
    started: string;
    duration?: number;
    status: SessionStatus;
    errors: number;
    abnormal_mechanism?: string;
    attrs?: {
        release?: string;
        environment?: string;
        user_agent?: string;
        ip_address?: string;
    };
}
//# sourceMappingURL=session.d.ts.map
