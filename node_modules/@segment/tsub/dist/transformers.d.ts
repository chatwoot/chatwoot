import { Transformer } from './store';
export interface TransformerConfig {
    allow?: Record<string, string[]>;
    drop?: Record<string, string[]>;
    sample?: TransformerConfigSample;
    map?: Record<string, TransformerConfigMap>;
}
export interface TransformerConfigSample {
    percent: number;
    path: string;
}
export interface TransformerConfigMap {
    set?: any;
    copy?: string;
    move?: string;
    to_string?: boolean;
}
export default function transform(payload: any, transformers: Transformer[]): any;
