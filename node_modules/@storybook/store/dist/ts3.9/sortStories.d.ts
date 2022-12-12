import type { StorySortParameter, StorySortParameterV7 } from '@storybook/addons';
import type { Story, StoryIndexEntry, Path, Parameters } from './types';
export declare const sortStoriesV7: (stories: StoryIndexEntry[], storySortParameter: StorySortParameterV7, fileNameOrder: Path[]) => StoryIndexEntry[];
export declare const sortStoriesV6: (stories: [string, Story, Parameters, Parameters][], storySortParameter: StorySortParameter, fileNameOrder: Path[]) => StoryIndexEntry[];
