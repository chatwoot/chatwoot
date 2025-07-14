export type GeneralEventTypes = {
    [EventName: string]: unknown[];
};
type EventListener<EventTypes extends GeneralEventTypes, EventName extends keyof EventTypes> = (...args: EventTypes[EventName]) => void;
/** A simple event emitter that can be used to listen to and emit events. */
declare class EventEmitter<EventTypes extends GeneralEventTypes> {
    private listeners;
    /** Subscribe to an event. Returns an unsubscribe function. */
    on<EventName extends keyof EventTypes>(event: EventName, listener: EventListener<EventTypes, EventName>, options?: {
        once?: boolean;
    }): () => void;
    /** Unsubscribe from an event */
    un<EventName extends keyof EventTypes>(event: EventName, listener: EventListener<EventTypes, EventName>): void;
    /** Subscribe to an event only once */
    once<EventName extends keyof EventTypes>(event: EventName, listener: EventListener<EventTypes, EventName>): () => void;
    /** Clear all events */
    unAll(): void;
    /** Emit an event */
    protected emit<EventName extends keyof EventTypes>(eventName: EventName, ...args: EventTypes[EventName]): void;
}
export default EventEmitter;
