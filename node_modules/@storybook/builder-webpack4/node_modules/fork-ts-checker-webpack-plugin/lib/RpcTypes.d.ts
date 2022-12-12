import { CancellationTokenData } from './CancellationToken';
import { Message } from './Message';
export declare const RUN = "run";
export declare type RunPayload = CancellationTokenData;
export declare type RunResult = Message | undefined;
