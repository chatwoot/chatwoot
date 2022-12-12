import { ClientReport } from './clientreport';
import { Event } from './event';
import { SdkInfo } from './sdkinfo';
import { Session, SessionAggregates } from './session';
import { TransactionSamplingMethod } from './transaction';
import { UserFeedback } from './user';
export declare type BaseEnvelopeHeaders = {
    [key: string]: unknown;
    dsn?: string;
    sdk?: SdkInfo;
};
export declare type BaseEnvelopeItemHeaders = {
    [key: string]: unknown;
    type: string;
    length?: number;
};
declare type BaseEnvelopeItem<IH extends BaseEnvelopeItemHeaders, P extends unknown> = [IH, P];
declare type BaseEnvelope<EH extends BaseEnvelopeHeaders, I extends BaseEnvelopeItem<BaseEnvelopeItemHeaders, unknown>> = [EH, I[]];
declare type EventItemHeaders = {
    type: 'event' | 'transaction';
    sample_rates?: [{
        id?: TransactionSamplingMethod;
        rate?: number;
    }];
};
declare type AttachmentItemHeaders = {
    type: 'attachment';
    filename: string;
};
declare type UserFeedbackItemHeaders = {
    type: 'user_report';
};
declare type SessionItemHeaders = {
    type: 'session';
};
declare type SessionAggregatesItemHeaders = {
    type: 'sessions';
};
declare type ClientReportItemHeaders = {
    type: 'client_report';
};
export declare type EventItem = BaseEnvelopeItem<EventItemHeaders, Event | string>;
export declare type AttachmentItem = BaseEnvelopeItem<AttachmentItemHeaders, unknown>;
export declare type UserFeedbackItem = BaseEnvelopeItem<UserFeedbackItemHeaders, UserFeedback>;
export declare type SessionItem = BaseEnvelopeItem<SessionItemHeaders, Session> | BaseEnvelopeItem<SessionAggregatesItemHeaders, SessionAggregates>;
export declare type ClientReportItem = BaseEnvelopeItem<ClientReportItemHeaders, ClientReport>;
declare type EventEnvelopeHeaders = {
    event_id: string;
    sent_at: string;
};
declare type SessionEnvelopeHeaders = {
    sent_at: string;
};
declare type ClientReportEnvelopeHeaders = BaseEnvelopeHeaders;
export declare type EventEnvelope = BaseEnvelope<EventEnvelopeHeaders, EventItem | AttachmentItem | UserFeedbackItem>;
export declare type SessionEnvelope = BaseEnvelope<SessionEnvelopeHeaders, SessionItem>;
export declare type ClientReportEnvelope = BaseEnvelope<ClientReportEnvelopeHeaders, ClientReportItem>;
export declare type Envelope = EventEnvelope | SessionEnvelope | ClientReportEnvelope;
export {};
//# sourceMappingURL=envelope.d.ts.map