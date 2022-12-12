import type { Args, ArgTypes, StoryContext, AnyFramework } from '@storybook/csf';
export declare const mapArgsToTypes: (args: Args, argTypes: ArgTypes) => Args;
export declare const combineArgs: (value: any, update: any) => Args;
export declare const validateOptions: (args: Args, argTypes: ArgTypes) => Args;
export declare const DEEPLY_EQUAL: unique symbol;
export declare const deepDiff: (value: any, update: any) => any;
export declare const NO_TARGET_NAME = "";
export declare function groupArgsByTarget<TArgs = Args>({ args, argTypes, }: StoryContext<AnyFramework, TArgs>): Record<string, Partial<TArgs>>;
export declare function noTargetArgs<TArgs = Args>(context: StoryContext<AnyFramework, TArgs>): Partial<TArgs>;
