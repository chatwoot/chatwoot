import { ReportHandler } from './types';
export interface LayoutShift extends PerformanceEntry {
    value: number;
    hadRecentInput: boolean;
    sources: Array<LayoutShiftAttribution>;
    toJSON(): Record<string, unknown>;
}
export interface LayoutShiftAttribution {
    node?: Node;
    previousRect: DOMRectReadOnly;
    currentRect: DOMRectReadOnly;
}
export declare const getCLS: (onReport: ReportHandler, reportAllChanges?: boolean | undefined) => void;
//# sourceMappingURL=getCLS.d.ts.map