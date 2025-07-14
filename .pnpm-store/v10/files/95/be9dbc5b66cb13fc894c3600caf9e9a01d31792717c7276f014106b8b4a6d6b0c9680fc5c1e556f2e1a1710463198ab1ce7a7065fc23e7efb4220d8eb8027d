import { SegmentEvent } from '../../core/events';
import { Plugin } from '../../core/plugin';
import { SegmentFacade } from '../../lib/to-facade';
export interface MiddlewareParams {
    payload: SegmentFacade;
    integrations?: SegmentEvent['integrations'];
    next: (payload: MiddlewareParams['payload'] | null) => void;
}
export interface DestinationMiddlewareParams {
    payload: SegmentFacade;
    integration: string;
    next: (payload: MiddlewareParams['payload'] | null) => void;
}
export type MiddlewareFunction = (middleware: MiddlewareParams) => void | Promise<void>;
export type DestinationMiddlewareFunction = (middleware: DestinationMiddlewareParams) => void | Promise<void>;
export declare function applyDestinationMiddleware(destination: string, evt: SegmentEvent, middleware: DestinationMiddlewareFunction[]): Promise<SegmentEvent | null>;
export declare function sourceMiddlewarePlugin(fn: MiddlewareFunction, integrations: SegmentEvent['integrations']): Plugin;
//# sourceMappingURL=index.d.ts.map