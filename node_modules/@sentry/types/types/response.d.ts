import { Event, EventType } from './event';
import { EventStatus } from './eventstatus';
import { Session } from './session';
/** JSDoc */
export interface Response {
    status: EventStatus;
    event?: Event | Session;
    type?: EventType;
    reason?: string;
}
//# sourceMappingURL=response.d.ts.map