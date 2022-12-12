import EventInterface from './EventInterface';
declare class Event<EventPayload> implements EventInterface<EventPayload> {
    constructor();
    addHandler<T>(handler: EventInterface.HandlerInterface<EventPayload, T>, context?: T): Event<EventPayload>;
    removeHandler<T>(handler: EventInterface.HandlerInterface<EventPayload, T>, context?: T): Event<EventPayload>;
    isHandlerAttached<T>(handler: EventInterface.HandlerInterface<EventPayload, T>, context?: T): boolean;
    dispatch: (payload: EventPayload) => void;
    hasHandlers: boolean;
    private _updateHasHandlers;
    private _getHandlerIndex;
    private _createDispatcher;
    private _handlers;
    private _contexts;
}
export default Event;
