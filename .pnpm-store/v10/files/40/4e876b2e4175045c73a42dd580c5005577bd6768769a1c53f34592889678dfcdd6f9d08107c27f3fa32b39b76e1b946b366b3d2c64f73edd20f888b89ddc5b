Object.defineProperty(exports, '__esModule', { value: true });

const constants = require('./constants.js');
const utils = require('./utils.js');

/**
 * A metric instance representing a counter.
 */
class CounterMetric  {
   constructor( _value) {this._value = _value;}

  /** @inheritDoc */
   get weight() {
    return 1;
  }

  /** @inheritdoc */
   add(value) {
    this._value += value;
  }

  /** @inheritdoc */
   toString() {
    return `${this._value}`;
  }
}

/**
 * A metric instance representing a gauge.
 */
class GaugeMetric  {

   constructor(value) {
    this._last = value;
    this._min = value;
    this._max = value;
    this._sum = value;
    this._count = 1;
  }

  /** @inheritDoc */
   get weight() {
    return 5;
  }

  /** @inheritdoc */
   add(value) {
    this._last = value;
    if (value < this._min) {
      this._min = value;
    }
    if (value > this._max) {
      this._max = value;
    }
    this._sum += value;
    this._count++;
  }

  /** @inheritdoc */
   toString() {
    return `${this._last}:${this._min}:${this._max}:${this._sum}:${this._count}`;
  }
}

/**
 * A metric instance representing a distribution.
 */
class DistributionMetric  {

   constructor(first) {
    this._value = [first];
  }

  /** @inheritDoc */
   get weight() {
    return this._value.length;
  }

  /** @inheritdoc */
   add(value) {
    this._value.push(value);
  }

  /** @inheritdoc */
   toString() {
    return this._value.join(':');
  }
}

/**
 * A metric instance representing a set.
 */
class SetMetric  {

   constructor( first) {this.first = first;
    this._value = new Set([first]);
  }

  /** @inheritDoc */
   get weight() {
    return this._value.size;
  }

  /** @inheritdoc */
   add(value) {
    this._value.add(value);
  }

  /** @inheritdoc */
   toString() {
    return Array.from(this._value)
      .map(val => (typeof val === 'string' ? utils.simpleHash(val) : val))
      .join(':');
  }
}

const METRIC_MAP = {
  [constants.COUNTER_METRIC_TYPE]: CounterMetric,
  [constants.GAUGE_METRIC_TYPE]: GaugeMetric,
  [constants.DISTRIBUTION_METRIC_TYPE]: DistributionMetric,
  [constants.SET_METRIC_TYPE]: SetMetric,
};

exports.CounterMetric = CounterMetric;
exports.DistributionMetric = DistributionMetric;
exports.GaugeMetric = GaugeMetric;
exports.METRIC_MAP = METRIC_MAP;
exports.SetMetric = SetMetric;
//# sourceMappingURL=instance.js.map
