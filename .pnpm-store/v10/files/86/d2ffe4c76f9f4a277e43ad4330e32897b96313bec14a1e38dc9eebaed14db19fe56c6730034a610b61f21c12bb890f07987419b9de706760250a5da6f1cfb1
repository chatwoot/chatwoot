import { Client, DsnComponents, Event, EventEnvelope, SdkMetadata, Session, SessionAggregates, SessionEnvelope, SpanEnvelope } from '@sentry/types';
import { SentrySpan } from './tracing/sentrySpan';
/** Creates an envelope from a Session */
export declare function createSessionEnvelope(session: Session | SessionAggregates, dsn?: DsnComponents, metadata?: SdkMetadata, tunnel?: string): SessionEnvelope;
/**
 * Create an Envelope from an event.
 */
export declare function createEventEnvelope(event: Event, dsn?: DsnComponents, metadata?: SdkMetadata, tunnel?: string): EventEnvelope;
/**
 * Create envelope from Span item.
 *
 * Takes an optional client and runs spans through `beforeSendSpan` if available.
 */
export declare function createSpanEnvelope(spans: [
    SentrySpan,
    ...SentrySpan[]
], client?: Client): SpanEnvelope;
//# sourceMappingURL=envelope.d.ts.map
