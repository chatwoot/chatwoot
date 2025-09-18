import type { TraceContext } from './context';
interface CrontabSchedule {
    type: 'crontab';
    value: string;
}
interface IntervalSchedule {
    type: 'interval';
    value: number;
    unit: 'year' | 'month' | 'week' | 'day' | 'hour' | 'minute';
}
type MonitorSchedule = CrontabSchedule | IntervalSchedule;
export interface SerializedCheckIn {
    check_in_id: string;
    monitor_slug: string;
    status: 'in_progress' | 'ok' | 'error';
    duration?: number;
    release?: string;
    environment?: string;
    monitor_config?: {
        schedule: MonitorSchedule;
        checkin_margin?: number;
        max_runtime?: number;
        timezone?: string;
        failure_issue_threshold?: number;
        recovery_threshold?: number;
    };
    contexts?: {
        trace?: TraceContext;
    };
}
export interface HeartbeatCheckIn {
    monitorSlug: SerializedCheckIn['monitor_slug'];
    status: 'ok' | 'error';
}
export interface InProgressCheckIn {
    monitorSlug: SerializedCheckIn['monitor_slug'];
    status: 'in_progress';
}
export interface FinishedCheckIn {
    monitorSlug: SerializedCheckIn['monitor_slug'];
    status: 'ok' | 'error';
    checkInId: SerializedCheckIn['check_in_id'];
    duration?: SerializedCheckIn['duration'];
}
export type CheckIn = HeartbeatCheckIn | InProgressCheckIn | FinishedCheckIn;
type SerializedMonitorConfig = NonNullable<SerializedCheckIn['monitor_config']>;
export interface MonitorConfig {
    schedule: MonitorSchedule;
    checkinMargin?: SerializedMonitorConfig['checkin_margin'];
    maxRuntime?: SerializedMonitorConfig['max_runtime'];
    timezone?: SerializedMonitorConfig['timezone'];
    failureIssueThreshold?: SerializedMonitorConfig['failure_issue_threshold'];
    recoveryThreshold?: SerializedMonitorConfig['recovery_threshold'];
}
export {};
//# sourceMappingURL=checkin.d.ts.map