import { DecoratorFunction } from '../models';
export declare const decorateAction: (_decorators: DecoratorFunction[]) => () => void;
export declare const decorate: (_decorators: DecoratorFunction[]) => () => {
    action: () => void;
    actions: () => void;
    withActions: () => void;
};
