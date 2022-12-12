import { ReportHandler } from './types';
export interface LargestContentfulPaint extends PerformanceEntry {
    renderTime: DOMHighResTimeStamp;
    loadTime: DOMHighResTimeStamp;
    size: number;
    id: string;
    url: string;
    element?: Element;
    toJSON(): Record<string, string>;
}
export declare const getLCP: (onReport: ReportHandler, reportAllChanges?: boolean | undefined) => void;
//# sourceMappingURL=getLCP.d.ts.map