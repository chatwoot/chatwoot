Object.defineProperty(exports, '__esModule', { value: true });

const utils = require('@sentry/utils');
const spanUtils = require('../utils/spanUtils.js');

/**
 * A Sentry Span that is non-recording, meaning it will not be sent to Sentry.
 */
class SentryNonRecordingSpan  {

   constructor(spanContext = {}) {
    this._traceId = spanContext.traceId || utils.uuid4();
    this._spanId = spanContext.spanId || utils.uuid4().substring(16);
  }

  /** @inheritdoc */
   spanContext() {
    return {
      spanId: this._spanId,
      traceId: this._traceId,
      traceFlags: spanUtils.TRACE_FLAG_NONE,
    };
  }

  /** @inheritdoc */
  // eslint-disable-next-line @typescript-eslint/no-empty-function
   end(_timestamp) {}

  /** @inheritdoc */
   setAttribute(_key, _value) {
    return this;
  }

  /** @inheritdoc */
   setAttributes(_values) {
    return this;
  }

  /** @inheritdoc */
   setStatus(_status) {
    return this;
  }

  /** @inheritdoc */
   updateName(_name) {
    return this;
  }

  /** @inheritdoc */
   isRecording() {
    return false;
  }

  /** @inheritdoc */
   addEvent(
    _name,
    _attributesOrStartTime,
    _startTime,
  ) {
    return this;
  }

  /**
   * This should generally not be used,
   * but we need it for being comliant with the OTEL Span interface.
   *
   * @hidden
   * @internal
   */
   addLink(_link) {
    return this;
  }

  /**
   * This should generally not be used,
   * but we need it for being comliant with the OTEL Span interface.
   *
   * @hidden
   * @internal
   */
   addLinks(_links) {
    return this;
  }

  /**
   * This should generally not be used,
   * but we need it for being comliant with the OTEL Span interface.
   *
   * @hidden
   * @internal
   */
   recordException(_exception, _time) {
    // noop
  }
}

exports.SentryNonRecordingSpan = SentryNonRecordingSpan;
//# sourceMappingURL=sentryNonRecordingSpan.js.map
