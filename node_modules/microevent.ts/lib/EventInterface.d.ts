interface EventInterface<EventPayload> {
    addHandler<T>(handler: EventInterface.HandlerInterface<EventPayload, T>, context?: T): EventInterface<EventPayload>;
    removeHandler<T>(handler: EventInterface.HandlerInterface<EventPayload, T>, context?: T): EventInterface<EventPayload>;
}
declare module EventInterface {
    interface HandlerInterface<EventPayload, T> {
        (payload: EventPayload, context: T): void;
    }
}
export default EventInterface;
