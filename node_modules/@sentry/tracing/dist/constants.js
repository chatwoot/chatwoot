Object.defineProperty(exports, "__esModule", { value: true });
// Store finish reasons in tuple to save on bundle size
// Readonly type should enforce that this is not mutated.
exports.FINISH_REASON_TAG = 'finishReason';
exports.IDLE_TRANSACTION_FINISH_REASONS = ['heartbeatFailed', 'idleTimeout', 'documentHidden'];
//# sourceMappingURL=constants.js.map