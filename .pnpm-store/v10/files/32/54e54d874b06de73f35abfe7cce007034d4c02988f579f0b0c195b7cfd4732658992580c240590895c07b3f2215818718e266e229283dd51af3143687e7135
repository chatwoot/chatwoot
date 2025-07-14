import { CSSToken } from '@csstools/css-tokenizer';
import { NodeType } from '../util/node-type';
import { MediaQuery } from './media-query';
export declare class CustomMedia {
    type: NodeType;
    name: Array<CSSToken>;
    mediaQueryList: Array<MediaQuery> | null;
    trueOrFalseKeyword: Array<CSSToken> | null;
    constructor(name: Array<CSSToken>, mediaQueryList: Array<MediaQuery> | null, trueOrFalseKeyword?: Array<CSSToken>);
    getName(): string;
    getNameToken(): CSSToken | null;
    hasMediaQueryList(): boolean;
    hasTrueKeyword(): boolean;
    hasFalseKeyword(): boolean;
    tokens(): Array<CSSToken>;
    toString(): string;
    toJSON(): {
        type: NodeType;
        string: string;
        nameValue: string;
        name: CSSToken[];
        hasFalseKeyword: boolean;
        hasTrueKeyword: boolean;
        trueOrFalseKeyword: CSSToken[] | null;
        mediaQueryList: ({
            type: NodeType;
            string: string;
            modifier: CSSToken[];
            mediaType: CSSToken[];
            and: CSSToken[] | undefined;
            media: import("./media-condition").MediaCondition | undefined;
        } | {
            type: NodeType;
            string: string;
            media: import("./media-condition").MediaCondition;
        } | {
            type: NodeType;
            string: string;
            media: import("@csstools/css-parser-algorithms").ComponentValue[];
        })[] | undefined;
    };
    isCustomMedia(): this is CustomMedia;
    static isCustomMedia(x: unknown): x is CustomMedia;
}
