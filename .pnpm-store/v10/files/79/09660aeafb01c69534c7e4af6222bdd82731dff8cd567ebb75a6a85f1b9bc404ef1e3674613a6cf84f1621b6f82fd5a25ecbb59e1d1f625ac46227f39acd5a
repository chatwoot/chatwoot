export declare const DEFAULT_BLOCKED_UA_STRS: string[];
/**
 * Block various web spiders from executing our JS and sending false capturing data
 */
export declare const isBlockedUA: (ua: string, customBlockedUserAgents: string[]) => boolean;
export interface NavigatorUAData {
    brands?: {
        brand: string;
        version: string;
    }[];
}
declare global {
    interface Navigator {
        userAgentData?: NavigatorUAData;
    }
}
export declare const isLikelyBot: (navigator: Navigator | undefined, customBlockedUserAgents: string[]) => boolean;
