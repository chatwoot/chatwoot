import { Attachment } from './attachment';
import { Breadcrumb } from './breadcrumb';
import { Contexts } from './context';
import { DebugMeta } from './debugMeta';
import { Exception } from './exception';
import { Extras } from './extra';
import { Measurements } from './measurement';
import { Mechanism } from './mechanism';
import { Primitive } from './misc';
import { Request } from './request';
import { CaptureContext } from './scope';
import { SdkInfo } from './sdkinfo';
import { SeverityLevel } from './severity';
import { MetricSummary, SpanJSON } from './span';
import { Thread } from './thread';
import { TransactionSource } from './transaction';
import { User } from './user';
/** An event to be sent to Sentry. */
export interface Event {
    event_id?: string;
    message?: string;
    logentry?: {
        message?: string;
        params?: string[];
    };
    timestamp?: number;
    start_timestamp?: number;
    level?: SeverityLevel;
    platform?: string;
    logger?: string;
    server_name?: string;
    release?: string;
    dist?: string;
    environment?: string;
    sdk?: SdkInfo;
    request?: Request;
    transaction?: string;
    modules?: {
        [key: string]: string;
    };
    fingerprint?: string[];
    exception?: {
        values?: Exception[];
    };
    breadcrumbs?: Breadcrumb[];
    contexts?: Contexts;
    tags?: {
        [key: string]: Primitive;
    };
    extra?: Extras;
    user?: User;
    type?: EventType;
    spans?: SpanJSON[];
    measurements?: Measurements;
    debug_meta?: DebugMeta;
    sdkProcessingMetadata?: {
        [key: string]: any;
    };
    transaction_info?: {
        source: TransactionSource;
    };
    threads?: {
        values: Thread[];
    };
}
/**
 * The type of an `Event`.
 * Note that `ErrorEvent`s do not have a type (hence its undefined),
 * while all other events are required to have one.
 */
export type EventType = 'transaction' | 'profile' | 'replay_event' | 'feedback' | undefined;
export interface ErrorEvent extends Event {
    type: undefined;
}
export interface TransactionEvent extends Event {
    type: 'transaction';
    _metrics_summary?: Record<string, Array<MetricSummary>>;
}
/** JSDoc */
export interface EventHint {
    event_id?: string;
    captureContext?: CaptureContext;
    mechanism?: Partial<Mechanism>;
    syntheticException?: Error | null;
    originalException?: unknown;
    attachments?: Attachment[];
    data?: any;
    integrations?: string[];
}
//# sourceMappingURL=event.d.ts.map
