import { Session as SessionInterface, SessionContext, SessionStatus } from '@sentry/types';
/**
 * @inheritdoc
 */
export declare class Session implements SessionInterface {
    userAgent?: string;
    errors: number;
    release?: string;
    sid: string;
    did?: string;
    timestamp: number;
    started: number;
    duration?: number;
    status: SessionStatus;
    environment?: string;
    ipAddress?: string;
    init: boolean;
    ignoreDuration: boolean;
    constructor(context?: Omit<SessionContext, 'started' | 'status'>);
    /** JSDoc */
    update(context?: SessionContext): void;
    /** JSDoc */
    close(status?: Exclude<SessionStatus, 'ok'>): void;
    /** JSDoc */
    toJSON(): {
        init: boolean;
        sid: string;
        did?: string;
        timestamp: string;
        started: string;
        duration?: number;
        status: SessionStatus;
        errors: number;
        attrs?: {
            release?: string;
            environment?: string;
            user_agent?: string;
            ip_address?: string;
        };
    };
}
//# sourceMappingURL=session.d.ts.map