interface GetChannelParams {
    channelType?: ChannelKey;
    medium?: string;
}
interface GetMaxUploadParams extends GetChannelParams {
    mime?: string;
}
export declare const INBOX_TYPES: {
    readonly WEB: "Channel::WebWidget";
    readonly FB: "Channel::FacebookPage";
    readonly TWITTER: "Channel::TwitterProfile";
    readonly TWILIO: "Channel::TwilioSms";
    readonly WHATSAPP: "Channel::Whatsapp";
    readonly API: "Channel::Api";
    readonly EMAIL: "Channel::Email";
    readonly TELEGRAM: "Channel::Telegram";
    readonly LINE: "Channel::Line";
    readonly SMS: "Channel::Sms";
    readonly INSTAGRAM: "Channel::Instagram";
    readonly VOICE: "Channel::Voice";
};
declare type ChannelKey = typeof INBOX_TYPES[keyof typeof INBOX_TYPES];
/**
 * @name getAllowedFileTypesByChannel
 * @description Builds the full "accept" string for <input type="file">,
 * based on channel + medium rules.
 *
 * @param {Object} params
 * @param {string} [params.channelType] - Channel type (from INBOX_TYPES).
 * @param {string} [params.medium] - Medium under the channel.
 * @returns {string} Comma-separated list of allowed MIME types/extensions.
 *
 * @example
 * getAllowedFileTypesByChannel({ channelType: INBOX_TYPES.WHATSAPP });
 * → "audio/aac, audio/amr, image/jpeg, image/png, video/3gp, ..."
 */
export declare const getAllowedFileTypesByChannel: ({ channelType, medium, }?: GetChannelParams) => string;
/**
 * @name getMaxUploadSizeByChannel
 * @description Gets the maximum allowed file size (in MB) for a channel, medium, and MIME type.
 *
 * Priority:
 * - Category-specific size (image/video/audio/document).
 * - Channel/medium-level max.
 * - Global default max.
 *
 * @param {Object} params
 * @param {string} [params.channelType] - Channel type (from INBOX_TYPES).
 * @param {string} [params.medium] - Medium under the channel.
 * @param {string} [params.mime] - MIME type string (for category lookup).
 * @returns {number} Maximum file size in MB.
 *
 * @example
 * getMaxUploadSizeByChannel({ channelType: INBOX_TYPES.WHATSAPP, mime: "image/png" });
 * → 5
 */
export declare const getMaxUploadSizeByChannel: ({ channelType, medium, mime, }?: GetMaxUploadParams) => number;
export {};
