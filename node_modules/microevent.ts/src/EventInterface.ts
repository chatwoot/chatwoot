interface EventInterface <EventPayload> {

    addHandler<T>(handler: EventInterface.HandlerInterface<EventPayload, T>, context?: T): EventInterface<EventPayload>;

    removeHandler<T>(handler: EventInterface.HandlerInterface<EventPayload, T>, context?: T): EventInterface<EventPayload>;
}

module EventInterface {

    export interface HandlerInterface<EventPayload, T> {
        (payload: EventPayload, context: T): void;
    }

}

export default EventInterface;
