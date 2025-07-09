import { Analytics, InitOptions } from '../core/analytics';
export interface AnalyticsSnippet extends AnalyticsStandalone {
    load: (writeKey: string, options?: InitOptions) => void;
}
export interface AnalyticsStandalone extends Analytics {
    _loadOptions?: InitOptions;
    _writeKey?: string;
    _cdn?: string;
}
declare global {
    interface Window {
        analytics: AnalyticsSnippet;
    }
}
export declare function install(): Promise<void>;
//# sourceMappingURL=standalone-analytics.d.ts.map