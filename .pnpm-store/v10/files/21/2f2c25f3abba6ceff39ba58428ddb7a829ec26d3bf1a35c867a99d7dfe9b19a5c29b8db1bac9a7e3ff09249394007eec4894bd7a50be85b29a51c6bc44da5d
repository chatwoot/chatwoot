import { MetricType, MetricRatingThresholds } from '../types.js';
export declare const bindReporter: <MetricName extends "CLS" | "FCP" | "FID" | "INP" | "LCP" | "TTFB">(callback: (metric: Extract<import("../types.js").CLSMetric, {
    name: MetricName;
}> | Extract<import("../types.js").FCPMetric, {
    name: MetricName;
}> | Extract<import("../types.js").FIDMetric, {
    name: MetricName;
}> | Extract<import("../types.js").INPMetric, {
    name: MetricName;
}> | Extract<import("../types.js").LCPMetric, {
    name: MetricName;
}> | Extract<import("../types.js").TTFBMetric, {
    name: MetricName;
}>) => void, metric: Extract<import("../types.js").CLSMetric, {
    name: MetricName;
}> | Extract<import("../types.js").FCPMetric, {
    name: MetricName;
}> | Extract<import("../types.js").FIDMetric, {
    name: MetricName;
}> | Extract<import("../types.js").INPMetric, {
    name: MetricName;
}> | Extract<import("../types.js").LCPMetric, {
    name: MetricName;
}> | Extract<import("../types.js").TTFBMetric, {
    name: MetricName;
}>, thresholds: MetricRatingThresholds, reportAllChanges?: boolean) => (forceReport?: boolean) => void;
