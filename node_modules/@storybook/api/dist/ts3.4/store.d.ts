import { State } from './index';
export declare const STORAGE_KEY = "@storybook/ui/store";
declare type GetState = () => State;
declare type SetState = (a: any, b: any) => any;
interface Upstream {
    getState: GetState;
    setState: SetState;
}
declare type Patch = Partial<State>;
declare type InputFnPatch = (s: State) => Patch;
declare type InputPatch = Patch | InputFnPatch;
export interface Options {
    persistence: 'none' | 'session' | string;
}
declare type CallBack = (s: State) => void;
export default class Store {
    upstreamGetState: GetState;
    upstreamSetState: SetState;
    constructor({ setState, getState }: Upstream);
    getInitialState(base: State): any;
    getState(): State;
    setState(inputPatch: InputPatch, options?: Options): Promise<State>;
    setState(inputPatch: InputPatch, callback?: CallBack, options?: Options): Promise<State>;
}
export {};
