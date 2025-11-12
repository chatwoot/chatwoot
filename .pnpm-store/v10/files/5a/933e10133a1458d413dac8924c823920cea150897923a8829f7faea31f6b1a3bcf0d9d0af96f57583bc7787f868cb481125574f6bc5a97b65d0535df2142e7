export interface WebExperimentTransform {
    attributes?: {
        name: string;
        value: string;
    }[];
    selector?: string;
    text?: string;
    html?: string;
    imgUrl?: string;
    css?: string;
}
export type WebExperimentUrlMatchType = 'regex' | 'not_regex' | 'exact' | 'is_not' | 'icontains' | 'not_icontains';
export interface WebExperimentVariant {
    conditions?: {
        url?: string;
        urlMatchType?: WebExperimentUrlMatchType;
        utm?: {
            utm_source?: string;
            utm_medium?: string;
            utm_campaign?: string;
            utm_term?: string;
        };
    };
    variant_name: string;
    transforms: WebExperimentTransform[];
}
export interface WebExperiment {
    id: number;
    name: string;
    feature_flag_key?: string;
    variants: Record<string, WebExperimentVariant>;
}
export type WebExperimentsCallback = (webExperiments: WebExperiment[]) => void;
