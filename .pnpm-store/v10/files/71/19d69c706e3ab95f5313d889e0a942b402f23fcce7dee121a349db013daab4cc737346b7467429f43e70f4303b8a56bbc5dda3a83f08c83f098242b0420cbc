import EventEmitter from './event-emitter.js';
class Timer extends EventEmitter {
    constructor() {
        super(...arguments);
        this.unsubscribe = () => undefined;
    }
    start() {
        this.unsubscribe = this.on('tick', () => {
            requestAnimationFrame(() => {
                this.emit('tick');
            });
        });
        this.emit('tick');
    }
    stop() {
        this.unsubscribe();
    }
    destroy() {
        this.unsubscribe();
    }
}
export default Timer;
