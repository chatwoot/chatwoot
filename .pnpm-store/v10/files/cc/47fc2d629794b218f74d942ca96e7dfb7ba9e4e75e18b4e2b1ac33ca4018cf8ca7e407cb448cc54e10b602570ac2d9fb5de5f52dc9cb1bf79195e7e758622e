Object.defineProperty(exports, '__esModule', { value: true });

const instrument = require('./metrics/instrument.js');
const browserMetrics = require('./metrics/browserMetrics.js');
const dom = require('./instrument/dom.js');
const history = require('./instrument/history.js');
const getNativeImplementation = require('./getNativeImplementation.js');
const xhr = require('./instrument/xhr.js');
const inp = require('./metrics/inp.js');



exports.addClsInstrumentationHandler = instrument.addClsInstrumentationHandler;
exports.addFidInstrumentationHandler = instrument.addFidInstrumentationHandler;
exports.addInpInstrumentationHandler = instrument.addInpInstrumentationHandler;
exports.addLcpInstrumentationHandler = instrument.addLcpInstrumentationHandler;
exports.addPerformanceInstrumentationHandler = instrument.addPerformanceInstrumentationHandler;
exports.addTtfbInstrumentationHandler = instrument.addTtfbInstrumentationHandler;
exports.addPerformanceEntries = browserMetrics.addPerformanceEntries;
exports.startTrackingInteractions = browserMetrics.startTrackingInteractions;
exports.startTrackingLongAnimationFrames = browserMetrics.startTrackingLongAnimationFrames;
exports.startTrackingLongTasks = browserMetrics.startTrackingLongTasks;
exports.startTrackingWebVitals = browserMetrics.startTrackingWebVitals;
exports.addClickKeypressInstrumentationHandler = dom.addClickKeypressInstrumentationHandler;
exports.addHistoryInstrumentationHandler = history.addHistoryInstrumentationHandler;
exports.clearCachedImplementation = getNativeImplementation.clearCachedImplementation;
exports.fetch = getNativeImplementation.fetch;
exports.getNativeImplementation = getNativeImplementation.getNativeImplementation;
exports.setTimeout = getNativeImplementation.setTimeout;
exports.SENTRY_XHR_DATA_KEY = xhr.SENTRY_XHR_DATA_KEY;
exports.addXhrInstrumentationHandler = xhr.addXhrInstrumentationHandler;
exports.registerInpInteractionListener = inp.registerInpInteractionListener;
exports.startTrackingINP = inp.startTrackingINP;
//# sourceMappingURL=index.js.map
