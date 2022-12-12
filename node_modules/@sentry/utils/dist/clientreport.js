Object.defineProperty(exports, "__esModule", { value: true });
var envelope_1 = require("./envelope");
var time_1 = require("./time");
/**
 * Creates client report envelope
 * @param discarded_events An array of discard events
 * @param dsn A DSN that can be set on the header. Optional.
 */
function createClientReportEnvelope(discarded_events, dsn, timestamp) {
    var clientReportItem = [
        { type: 'client_report' },
        {
            timestamp: timestamp || time_1.dateTimestampInSeconds(),
            discarded_events: discarded_events,
        },
    ];
    return envelope_1.createEnvelope(dsn ? { dsn: dsn } : {}, [clientReportItem]);
}
exports.createClientReportEnvelope = createClientReportEnvelope;
//# sourceMappingURL=clientreport.js.map