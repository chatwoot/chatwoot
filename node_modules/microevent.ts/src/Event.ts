import EventInterface from './EventInterface';

const factories: Array<Function> = [];

factories[0] = function(): Function {
    return function dispatcher0() {};
};

factories[1] = function(callback: Function, context?: any): Function {
    if (typeof(context) === 'undefined') return callback;

    return function dispatcher1(payload: any) {
        callback(payload, context);
    };
};

function getFactory(handlerCount: number) {
    if (!factories[handlerCount]) factories[handlerCount] = compileFactory(handlerCount);

    return factories[handlerCount];
}

function compileFactory(handlerCount: number): Function {
    let src: string = 'return function dispatcher' + handlerCount + '(payload) {\n';

    const argsHandlers: Array<string> = [],
        argsContexts: Array<string> = [];

    for (let i = 0; i < handlerCount; i++) {
        argsHandlers.push('cb' + i);
        argsContexts.push('ctx' + i);
        src += '    cb' + i + '(payload, ctx' + i + ');\n';
    }

    src += '};';

    return new Function(...argsHandlers.concat(argsContexts), src);
}

class Event<EventPayload> implements EventInterface<EventPayload> {

    constructor() {
        this._createDispatcher();
    }

    addHandler<T>(handler: EventInterface.HandlerInterface<EventPayload, T>, context?: T): Event<EventPayload> {
        if (!this.isHandlerAttached(handler, context)) {
            this._handlers.push(handler);
            this._contexts.push(context);

            this._createDispatcher();
            this._updateHasHandlers();
        }

        return this;
    }

    removeHandler<T>(handler: EventInterface.HandlerInterface<EventPayload, T>, context?: T): Event<EventPayload> {
        const idx = this._getHandlerIndex(handler, context);

        if (typeof(idx) !== 'undefined') {
            this._handlers.splice(idx, 1);
            this._contexts.splice(idx, 1);

            this._createDispatcher();
            this._updateHasHandlers();
        }

        return this;
    }

    isHandlerAttached<T>(handler: EventInterface.HandlerInterface<EventPayload, T>, context?: T) {
        return typeof(this._getHandlerIndex(handler, context)) !== 'undefined';
    }

    dispatch: (payload: EventPayload) => void;

    hasHandlers = false;

    private _updateHasHandlers() {
        this.hasHandlers = !!this._handlers.length;
    }

    private _getHandlerIndex<T>(handler: EventInterface.HandlerInterface<EventPayload, T>, context?: T): number {
        const handlerCount = this._handlers.length;

        let idx: number;
        for (idx = 0; idx < handlerCount; idx++) {
            if (this._handlers[idx] === handler && this._contexts[idx] === context) break;
        }

        return idx < handlerCount ? idx : undefined;
    }

    private _createDispatcher() {
        this.dispatch = getFactory(this._handlers.length).apply(this, this._handlers.concat(this._contexts));
    }

    private _handlers: Array<(payload: EventPayload, context: any) => void> = [];
    private _contexts: Array<any> = [];
}

export default Event;
