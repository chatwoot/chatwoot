import { Args, Globals, InputType, Conditional } from './story';
export declare const testValue: (cond: Pick<Conditional, never>, value: any) => boolean;
export declare const includeConditionalArg: (argType: InputType, args: Args, globals: Globals) => boolean;
