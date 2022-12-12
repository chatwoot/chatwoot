import { State } from './index';
interface Addition {
    [key: string]: any;
}
declare type Additions = Addition[];
declare const main: (...additions: Additions) => State;
export default main;
