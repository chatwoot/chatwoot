import { Event, EventEnvelope, SentryRequest, SentryRequestType, Session, SessionAggregates, SessionEnvelope } from '@sentry/types';
import { APIDetails } from './api';
/** Creates an envelope from a Session */
export declare function createSessionEnvelope(session: Session | SessionAggregates, api: APIDetails): [SessionEnvelope, SentryRequestType];
/** Creates a SentryRequest from a Session. */
export declare function sessionToSentryRequest(session: Session | SessionAggregates, api: APIDetails): SentryRequest;
/**
 * Create an Envelope from an event. Note that this is duplicated from below,
 * but on purpose as this will be refactored in v7.
 */
export declare function createEventEnvelope(event: Event, api: APIDetails): EventEnvelope;
/** Creates a SentryRequest from an event. */
export declare function eventToSentryRequest(event: Event, api: APIDetails): SentryRequest;
//# sourceMappingURL=request.d.ts.map