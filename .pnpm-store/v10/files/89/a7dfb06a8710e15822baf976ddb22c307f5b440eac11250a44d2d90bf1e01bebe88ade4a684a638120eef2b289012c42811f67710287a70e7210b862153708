/**
 * @file async-stream.js
 */
import Stream from '@videojs/vhs-utils/es/stream.js';

/**
 * A wrapper around the Stream class to use setTimeout
 * and run stream "jobs" Asynchronously
 *
 * @class AsyncStream
 * @extends Stream
 */
export default class AsyncStream extends Stream {
  constructor() {
    super(Stream);
    this.jobs = [];
    this.delay = 1;
    this.timeout_ = null;
  }

  /**
   * process an async job
   *
   * @private
   */
  processJob_() {
    this.jobs.shift()();
    if (this.jobs.length) {
      this.timeout_ = setTimeout(
        this.processJob_.bind(this),
        this.delay
      );
    } else {
      this.timeout_ = null;
    }
  }

  /**
   * push a job into the stream
   *
   * @param {Function} job the job to push into the stream
   */
  push(job) {
    this.jobs.push(job);
    if (!this.timeout_) {
      this.timeout_ = setTimeout(
        this.processJob_.bind(this),
        this.delay
      );
    }
  }
}

