import { Matcher, Rule } from '@segment/tsub/dist/store';
import { DestinationMiddlewareFunction } from '../middleware';
type RoutingRuleMatcher = Matcher & {
    config?: {
        expr: string;
    };
};
export type RoutingRule = Rule & {
    matchers: RoutingRuleMatcher[];
};
export declare const tsubMiddleware: (rules: RoutingRule[]) => DestinationMiddlewareFunction;
export {};
//# sourceMappingURL=index.d.ts.map