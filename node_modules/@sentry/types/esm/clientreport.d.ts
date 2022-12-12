import { SentryRequestType } from './request';
import { Outcome } from './transport';
export declare type ClientReport = {
    timestamp: number;
    discarded_events: Array<{
        reason: Outcome;
        category: SentryRequestType;
        quantity: number;
    }>;
};
//# sourceMappingURL=clientreport.d.ts.map