import { ExtractedNodeRequestData, WorkerLocation } from './misc';
import { SpanAttributes } from './span';
/**
 * Context data passed by the user when starting a transaction, to be used by the tracesSampler method.
 */
export interface CustomSamplingContext {
    [key: string]: any;
}
/**
 * Data passed to the `tracesSampler` function, which forms the basis for whatever decisions it might make.
 *
 * Adds default data to data provided by the user. See {@link Hub.startTransaction}
 */
export interface SamplingContext extends CustomSamplingContext {
    /**
     * Context data with which transaction being sampled was created.
     * @deprecated This is duplicate data and will be removed eventually.
     */
    transactionContext: {
        name: string;
        parentSampled?: boolean | undefined;
    };
    /**
     * Sampling decision from the parent transaction, if any.
     */
    parentSampled?: boolean;
    /**
     * Object representing the URL of the current page or worker script. Passed by default when using the `BrowserTracing`
     * integration.
     */
    location?: WorkerLocation;
    /**
     * Object representing the incoming request to a node server. Passed by default when using the TracingHandler.
     */
    request?: ExtractedNodeRequestData;
    /** The name of the span being sampled. */
    name: string;
    /** Initial attributes that have been passed to the span being sampled. */
    attributes?: SpanAttributes;
}
//# sourceMappingURL=samplingcontext.d.ts.map
