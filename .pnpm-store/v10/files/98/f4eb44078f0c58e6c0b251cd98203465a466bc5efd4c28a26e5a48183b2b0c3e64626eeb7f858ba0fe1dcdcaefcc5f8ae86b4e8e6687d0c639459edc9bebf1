export type SDPBlob = string;
export type SDPLine = string;
export type SDPSection = string;

export type SDPDirection = 'sendonly' | 'recvonly' | 'sendrecv' | 'inactive';

export interface SDPIceCandidate {
    foundation: string;
    component: 'rtp' | 'rtcp' | number;
    protocol: 'tcp' | 'udp';
    priority: number;
    ip: string;
    address: string;
    port: number;
    type: 'host' | 'prflx' | 'srflx' | 'relay';
    relatedAddress?: string;
    relatedPort?: number;
    tcpType?: string;
    ufrag?: string;
    usernameFragment?: string;
}

export interface SDPIceParameters {
    iceLite?: boolean;
    usernameFragment: string;
    password: string;
}

export interface SDPCodecParameters {
    payloadType: number;
    preferredPayloadType?: number;
    name: string;
    clockRate: number;
    channels: number;
    numChannels?: number;
    maxptime?: number;
}

export interface SDPCodecAdditionalParameters {
    [key: string]: string;
}

export interface SDPHeaderExtension {
    id: number;
    direction?: SDPDirection;
    uri: string;
    atrributes: string | undefined;
}

export interface SDPFeedbackParameter {
    type: string;
    parameter: string;
}

export interface SDPFingerprint {
    algorithm: string;
    value: string;
}

export interface SDPDtlsParameters {
    role: string;
    fingerprints: SDPFingerprint[];
}

export interface SDPMediaSource {
    ssrc: number;
    attribute?: string;
    value?: string;
}

export interface SDPMediaSourceGroup {
    semantics: string;
    ssrcs: number[];
}

export interface SDPMediaStreamId {
    stream: string;
    track: string;
}

export interface SDPCodec extends SDPCodecParameters {
    payloadType: number;
    preferredPayloadType?: number;
    parameters?: SDPCodecAdditionalParameters;
    rtcpFeedback?: SDPFeedbackParameter[];
}

export interface SDPGroup {
    semantics: string;
    mids: string[];
}

export interface SDPMLine {
    kind: string;
    port?: number;
    protocol: string;
    fmt?: string;
}

export interface SDPOLine {
    username: string;
    sessionId: string;
    sessionVersion: number;
    netType: string;
    addressType: string;
    address: string;
}

export interface SDPRtcpParameters {
    cname?: string;
    ssrc?: number;
    reducedSize?: boolean;
    compound?: boolean;
    mux?: boolean;
}

export interface SDPEncodingParameters {
    ssrc: number;
    codecPayloadType?: number;
    rtx?: {
        ssrc: number;
    };
    fec?: {
        ssrc: number;
        mechanism: string;
    };
}

export interface SDPRtpCapabilities {
    codecs: SDPCodec[];
    headerExtensions: SDPHeaderExtension[];
    fecMechanisms: string[];
    rtcp?: SDPRtcpParameters[];
}

export interface SDPSctpDescription {
    port: number;
    protocol: string;
    maxMessageSize?: number;
}

export const localCname: string;

export function generateIdentifier(): string;

export function splitLines(blob: SDPBlob): SDPLine[];
export function splitSections(blob: SDPBlob): SDPSection[];

export function getDescription(blob: SDPBlob): SDPSection;
export function getMediaSections(blob: SDPBlob): SDPSection[];

export function matchPrefix(blob: SDPBlob, prefix: string): SDPLine[];

export function parseCandidate(line: SDPLine): SDPIceCandidate;
export function writeCandidate(candidate: SDPIceCandidate): SDPLine;

export function parseIceOptions(line: SDPLine): string[];

export function parseRtpMap(line: SDPLine): SDPCodecParameters;
export function writeRtpMap(codec: SDPCodecParameters): SDPLine;

export function parseExtmap(line: SDPLine): SDPHeaderExtension;
export function writeExtmap(headerExtension: SDPHeaderExtension): SDPLine;

export function parseFmtp(line: SDPLine): SDPCodecAdditionalParameters;
export function writeFmtp(codec: SDPCodec): SDPLine;

export function parseRtcpFb(line: SDPLine): SDPFeedbackParameter;
export function writeRtcpFb(codec: SDPCodec): SDPLine[];

export function parseSsrcMedia(line: SDPLine): SDPMediaSource;
export function parseSsrcGroup(line: SDPLine): SDPMediaSourceGroup;

export function getMid(mediaSection: SDPSection): string;

export function parseFingerprint(line: SDPLine): SDPFingerprint;

export function getDtlsParameters(
    mediaSection: SDPSection,
    session: SDPSection
): SDPDtlsParameters;
export function writeDtlsParameters(params: SDPDtlsParameters, setupType: string): SDPLine;

export function getIceParameters(
    mediaSection: SDPSection,
    session: SDPSection
): SDPIceParameters;
export function writeIceParameters(params: SDPIceParameters): SDPLine;

export function parseRtpParameters(mediaSection: SDPSection): SDPRtpCapabilities;
export function writeRtpDescription(kind: string, caps: SDPRtpCapabilities): SDPSection;

export function parseRtpEncodingParameters(mediaSection: SDPSection): SDPEncodingParameters[];

export function parseRtcpParameters(mediaSection: SDPSection): SDPRtcpParameters;
export function writeRtcpParameters(params: SDPRtcpParameters): SDPLine;

export function parseMsid(mediaSection: SDPSection): SDPMediaStreamId;

export function parseSctpDescription(mediaSection: SDPSection): SDPSctpDescription;
export function writeSctpDescription(
    mediaSection: SDPMLine,
    desc: SDPSctpDescription
): SDPSection;

export function generateSessionId(): string;
export function writeSessionBoilerplate(
    sessId?: string,
    sessVer?: number,
    sessUser?: string
): SDPBlob;

export function getDirection(mediaSection: SDPSection, sessionpart: SDPSection): SDPDirection;
export function getKind(mediaSection: SDPSection): string;
export function isRejected(mediaSection: SDPSection): boolean;

export function parseMLine(mediaSection: SDPSection): SDPMLine;
export function parseOLine(mediaSection: SDPSection): SDPOLine;

export function isValidSDP(blob: SDPBlob): boolean;
