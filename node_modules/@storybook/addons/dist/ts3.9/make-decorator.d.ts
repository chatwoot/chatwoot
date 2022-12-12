import { StoryWrapper } from './types';
declare type MakeDecoratorResult = (...args: any) => any;
interface MakeDecoratorOptions {
    name: string;
    parameterName: string;
    skipIfNoParametersOrOptions?: boolean;
    wrapper: StoryWrapper;
}
export declare const makeDecorator: ({ name, parameterName, wrapper, skipIfNoParametersOrOptions, }: MakeDecoratorOptions) => MakeDecoratorResult;
export {};
