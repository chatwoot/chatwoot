import { ComponentValue, SimpleBlockNode } from '@csstools/css-parser-algorithms';
import { MediaAnd } from '../nodes/media-and';
import { MediaCondition } from '../nodes/media-condition';
import { MediaConditionListWithAnd, MediaConditionListWithOr } from '../nodes/media-condition-list';
import { MediaInParens } from '../nodes/media-in-parens';
import { MediaNot } from '../nodes/media-not';
import { MediaOr } from '../nodes/media-or';
import { MediaQuery } from '../nodes/media-query';
export declare function parseMediaQuery(componentValues: Array<ComponentValue>): MediaQuery | false;
export declare function parseMediaConditionListWithOr(componentValues: Array<ComponentValue>): MediaConditionListWithOr | false;
export declare function parseMediaConditionListWithAnd(componentValues: Array<ComponentValue>): MediaConditionListWithAnd | false;
export declare function parseMediaCondition(componentValues: Array<ComponentValue>): MediaCondition | false;
export declare function parseMediaConditionWithoutOr(componentValues: Array<ComponentValue>): MediaCondition | false;
export declare function parseMediaInParens(componentValues: Array<ComponentValue>): MediaInParens | false;
export declare function parseMediaInParensFromSimpleBlock(simpleBlock: SimpleBlockNode): MediaInParens | false;
export declare function parseMediaNot(componentValues: Array<ComponentValue>): MediaNot | false;
export declare function parseMediaOr(componentValues: Array<ComponentValue>): false | {
    advance: number;
    node: MediaOr;
};
export declare function parseMediaAnd(componentValues: Array<ComponentValue>): false | {
    advance: number;
    node: MediaAnd;
};
