/// <reference types="node" />
import type { MessagePort } from 'node:worker_threads';
import type { ServerStoryFile, ServerStory } from '@histoire/shared';
export interface Payload {
    root: string;
    base: string;
    port: MessagePort;
    storyFile: ServerStoryFile;
}
export interface ReturnData {
    storyData: ServerStory[];
}
declare const _default: (payload: Payload) => Promise<ReturnData>;
export default _default;
