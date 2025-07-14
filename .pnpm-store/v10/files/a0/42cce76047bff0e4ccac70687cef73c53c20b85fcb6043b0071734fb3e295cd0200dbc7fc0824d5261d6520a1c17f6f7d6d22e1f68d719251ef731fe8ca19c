declare module "webrtc-adapter" {
    interface IBrowserDetails {
        browser: string;
        version?: number;
        supportsUnifiedPlan?: boolean;
    }

    interface ICommonShim {
        shimRTCIceCandidate(window: Window): void;
        shimMaxMessageSize(window: Window): void;
        shimSendThrowTypeError(window: Window): void;
        shimConnectionState(window: Window): void;
        removeAllowExtmapMixed(window: Window): void;
    }

    interface IChromeShim {
        shimMediaStream(window: Window): void;
        shimOnTrack(window: Window): void;
        shimGetSendersWithDtmf(window: Window): void;
        shimSenderReceiverGetStats(window: Window): void;
        shimAddTrackRemoveTrackWithNative(window: Window): void;
        shimAddTrackRemoveTrack(window: Window): void;
        shimPeerConnection(window: Window): void;
        fixNegotiationNeeded(window: Window): void;
    }

    interface IFirefoxShim {
        shimOnTrack(window: Window): void;
        shimPeerConnection(window: Window): void;
        shimSenderGetStats(window: Window): void;
        shimReceiverGetStats(window: Window): void;
        shimRemoveStream(window: Window): void;
        shimRTCDataChannel(window: Window): void;
    }

    interface ISafariShim {
        shimLocalStreamsAPI(window: Window): void;
        shimRemoteStreamsAPI(window: Window): void;
        shimCallbacksAPI(window: Window): void;
        shimGetUserMedia(window: Window): void;
        shimConstraints(constraints: MediaStreamConstraints): void;
        shimRTCIceServerUrls(window: Window): void;
        shimTrackEventTransceiver(window: Window): void;
        shimCreateOfferLegacy(window: Window): void;
    }

    export interface IAdapter {
        browserDetails: IBrowserDetails;
        commonShim: ICommonShim;
        browserShim: IChromeShim | IFirefoxShim | ISafariShim | undefined;
        extractVersion(uastring: string, expr: string, pos: number): number;
        disableLog(disable: boolean): void;
        disableWarnings(disable: boolean): void;
    }

    const adapter: IAdapter;
    export default adapter;
}
