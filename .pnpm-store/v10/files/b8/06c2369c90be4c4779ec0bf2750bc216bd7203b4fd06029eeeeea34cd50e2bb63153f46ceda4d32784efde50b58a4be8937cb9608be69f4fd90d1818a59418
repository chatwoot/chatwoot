export declare const initMetric: <MetricName extends "CLS" | "FCP" | "FID" | "INP" | "LCP" | "TTFB">(name: MetricName, value?: number) => {
    name: MetricName;
    value: number;
    rating: "good";
    delta: number;
    entries: (Extract<import("../types.js").CLSMetric, {
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
    }>)["entries"];
    id: string;
    navigationType: "navigate" | "reload" | "back-forward" | "back-forward-cache" | "prerender" | "restore";
};
