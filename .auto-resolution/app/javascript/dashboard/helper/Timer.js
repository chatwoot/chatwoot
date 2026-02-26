export default class Timer {
  constructor(onTick = null) {
    this.elapsed = 0;
    this.intervalId = null;
    this.onTick = onTick;
  }

  start() {
    if (this.intervalId) {
      clearInterval(this.intervalId);
    }
    this.elapsed = 0;
    this.intervalId = setInterval(() => {
      this.elapsed += 1;
      if (this.onTick) {
        this.onTick(this.elapsed);
      }
    }, 1000);
  }

  stop() {
    if (this.intervalId) {
      clearInterval(this.intervalId);
      this.intervalId = null;
    }
    this.elapsed = 0;
  }
}
