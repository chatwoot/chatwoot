import { AttachmentType } from './attachment';
import { SerializedCheckIn } from './checkin';
import { ClientReport } from './clientreport';
import { DsnComponents } from './dsn';
import { Event } from './event';
import { FeedbackEvent, UserFeedback } from './feedback';
import { Profile, ProfileChunk } from './profiling';
import { ReplayEvent, ReplayRecordingData } from './replay';
import { SdkInfo } from './sdkinfo';
import { SerializedSession, SessionAggregates } from './session';
import { SpanJSON } from './span';
export type DynamicSamplingContext = {
    trace_id: string;
    public_key: DsnComponents['publicKey'];
    sample_rate?: string;
    release?: string;
    environment?: string;
    transaction?: string;
    replay_id?: string;
    sampled?: string;
};
export type EnvelopeItemType = 'client_report' | 'user_report' | 'feedback' | 'session' | 'sessions' | 'transaction' | 'attachment' | 'event' | 'profile' | 'profile_chunk' | 'replay_event' | 'replay_recording' | 'check_in' | 'statsd' | 'span';
export type BaseEnvelopeHeaders = {
    [key: string]: unknown;
    dsn?: string;
    sdk?: SdkInfo;
};
export type BaseEnvelopeItemHeaders = {
    [key: string]: unknown;
    type: EnvelopeItemType;
    length?: number;
};
type BaseEnvelopeItem<ItemHeader, P> = [
    ItemHeader & BaseEnvelopeItemHeaders,
    P
];
type BaseEnvelope<EnvelopeHeader, Item> = [
    EnvelopeHeader & BaseEnvelopeHeaders,
    Array<Item & BaseEnvelopeItem<BaseEnvelopeItemHeaders, unknown>>
];
type EventItemHeaders = {
    type: 'event' | 'transaction' | 'profile' | 'feedback';
};
type AttachmentItemHeaders = {
    type: 'attachment';
    length: number;
    filename: string;
    content_type?: string;
    attachment_type?: AttachmentType;
};
type UserFeedbackItemHeaders = {
    type: 'user_report';
};
type FeedbackItemHeaders = {
    type: 'feedback';
};
type SessionItemHeaders = {
    type: 'session';
};
type SessionAggregatesItemHeaders = {
    type: 'sessions';
};
type ClientReportItemHeaders = {
    type: 'client_report';
};
type ReplayEventItemHeaders = {
    type: 'replay_event';
};
type ReplayRecordingItemHeaders = {
    type: 'replay_recording';
    length: number;
};
type CheckInItemHeaders = {
    type: 'check_in';
};
type ProfileItemHeaders = {
    type: 'profile';
};
type ProfileChunkItemHeaders = {
    type: 'profile_chunk';
};
type StatsdItemHeaders = {
    type: 'statsd';
    length: number;
};
type SpanItemHeaders = {
    type: 'span';
};
export type EventItem = BaseEnvelopeItem<EventItemHeaders, Event>;
export type AttachmentItem = BaseEnvelopeItem<AttachmentItemHeaders, string | Uint8Array>;
export type UserFeedbackItem = BaseEnvelopeItem<UserFeedbackItemHeaders, UserFeedback>;
export type SessionItem = BaseEnvelopeItem<SessionItemHeaders, SerializedSession> | BaseEnvelopeItem<SessionAggregatesItemHeaders, SessionAggregates>;
export type ClientReportItem = BaseEnvelopeItem<ClientReportItemHeaders, ClientReport>;
export type CheckInItem = BaseEnvelopeItem<CheckInItemHeaders, SerializedCheckIn>;
type ReplayEventItem = BaseEnvelopeItem<ReplayEventItemHeaders, ReplayEvent>;
type ReplayRecordingItem = BaseEnvelopeItem<ReplayRecordingItemHeaders, ReplayRecordingData>;
export type StatsdItem = BaseEnvelopeItem<StatsdItemHeaders, string>;
export type FeedbackItem = BaseEnvelopeItem<FeedbackItemHeaders, FeedbackEvent>;
export type ProfileItem = BaseEnvelopeItem<ProfileItemHeaders, Profile>;
export type ProfileChunkItem = BaseEnvelopeItem<ProfileChunkItemHeaders, ProfileChunk>;
export type SpanItem = BaseEnvelopeItem<SpanItemHeaders, Partial<SpanJSON>>;
export type EventEnvelopeHeaders = {
    event_id: string;
    sent_at: string;
    trace?: DynamicSamplingContext;
};
type SessionEnvelopeHeaders = {
    sent_at: string;
};
type CheckInEnvelopeHeaders = {
    trace?: DynamicSamplingContext;
};
type ClientReportEnvelopeHeaders = BaseEnvelopeHeaders;
type ReplayEnvelopeHeaders = BaseEnvelopeHeaders;
type StatsdEnvelopeHeaders = BaseEnvelopeHeaders;
type SpanEnvelopeHeaders = BaseEnvelopeHeaders & {
    trace?: DynamicSamplingContext;
};
export type EventEnvelope = BaseEnvelope<EventEnvelopeHeaders, EventItem | AttachmentItem | UserFeedbackItem | FeedbackItem | ProfileItem>;
export type SessionEnvelope = BaseEnvelope<SessionEnvelopeHeaders, SessionItem>;
export type ClientReportEnvelope = BaseEnvelope<ClientReportEnvelopeHeaders, ClientReportItem>;
export type ReplayEnvelope = [
    ReplayEnvelopeHeaders,
    [
        ReplayEventItem,
        ReplayRecordingItem
    ]
];
export type CheckInEnvelope = BaseEnvelope<CheckInEnvelopeHeaders, CheckInItem>;
export type StatsdEnvelope = BaseEnvelope<StatsdEnvelopeHeaders, StatsdItem>;
export type SpanEnvelope = BaseEnvelope<SpanEnvelopeHeaders, SpanItem>;
export type ProfileChunkEnvelope = BaseEnvelope<BaseEnvelopeHeaders, ProfileChunkItem>;
export type Envelope = EventEnvelope | SessionEnvelope | ClientReportEnvelope | ProfileChunkEnvelope | ReplayEnvelope | CheckInEnvelope | StatsdEnvelope | SpanEnvelope;
export type EnvelopeItem = Envelope[1][number];
export {};
//# sourceMappingURL=envelope.d.ts.map
