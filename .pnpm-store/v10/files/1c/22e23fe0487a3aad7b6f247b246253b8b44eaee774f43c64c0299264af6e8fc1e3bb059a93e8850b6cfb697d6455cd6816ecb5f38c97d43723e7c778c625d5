class SimpleEventEmitter {
    on(event, listener) {
        if (!this.events[event]) this.events[event] = [];
        this.events[event].push(listener);
        return ()=>{
            this.events[event] = this.events[event].filter((x)=>x !== listener);
        };
    }
    emit(event, payload) {
        for (const listener of this.events[event] || [])listener(payload);
        for (const listener of this.events['*'] || [])listener(event, payload);
    }
    constructor(){
        this.events = {};
        this.events = {};
    }
}
export { SimpleEventEmitter };
