import { TransformerConfig } from './transformers';
export interface Rule {
    scope: string;
    target_type: string;
    matchers: Matcher[];
    transformers: Transformer[][];
    destinationName?: string;
}
export interface Matcher {
    type: string;
    ir: string;
}
export interface Transformer {
    type: string;
    config?: TransformerConfig;
}
export default class Store {
    private readonly rules;
    constructor(rules?: Rule[]);
    getRulesByDestinationName(destinationName: string): Rule[];
}
