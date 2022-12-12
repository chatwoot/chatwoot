import { ClientApi } from '@storybook/client-api';
import { StoryStore } from '@storybook/store';
import { toId } from '@storybook/csf';
import { start } from './start';
declare const _default: {
    start: typeof start;
    toId: (kind: string, name?: string) => string;
    ClientApi: typeof ClientApi;
    StoryStore: typeof StoryStore;
};
export default _default;
export { start, toId, ClientApi, StoryStore };
