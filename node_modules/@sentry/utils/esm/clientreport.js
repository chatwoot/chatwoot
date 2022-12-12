import { createEnvelope } from './envelope';
import { dateTimestampInSeconds } from './time';
/**
 * Creates client report envelope
 * @param discarded_events An array of discard events
 * @param dsn A DSN that can be set on the header. Optional.
 */
export function createClientReportEnvelope(discarded_events, dsn, timestamp) {
    var clientReportItem = [
        { type: 'client_report' },
        {
            timestamp: timestamp || dateTimestampInSeconds(),
            discarded_events: discarded_events,
        },
    ];
    return createEnvelope(dsn ? { dsn: dsn } : {}, [clientReportItem]);
}
//# sourceMappingURL=clientreport.js.map