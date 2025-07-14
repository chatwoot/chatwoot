declare type EventName = string;
declare type EventFnArgs = any[];
declare type EmitterContract = Record<EventName, EventFnArgs>;
/**
 * Event Emitter that takes the expected contract as a generic
 * @example
 * ```ts
 *  type Contract = {
 *    delivery_success: [DeliverySuccessResponse, Metrics],
 *    delivery_failure: [DeliveryError]
 * }
 *  new Emitter<Contract>()
 *  .on('delivery_success', (res, metrics) => ...)
 *  .on('delivery_failure', (err) => ...)
 * ```
 */
export declare class Emitter<Contract extends EmitterContract = EmitterContract> {
    private callbacks;
    on<EventName extends keyof Contract>(event: EventName, callback: (...args: Contract[EventName]) => void): this;
    once<EventName extends keyof Contract>(event: EventName, callback: (...args: Contract[EventName]) => void): this;
    off<EventName extends keyof Contract>(event: EventName, callback: (...args: Contract[EventName]) => void): this;
    emit<EventName extends keyof Contract>(event: EventName, ...args: Contract[EventName]): this;
}
export {};
//# sourceMappingURL=index.d.ts.map