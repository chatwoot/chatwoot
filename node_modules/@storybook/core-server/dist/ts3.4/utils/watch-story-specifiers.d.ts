import { NormalizedStoriesSpecifier } from '@storybook/core-common';
import { Path } from '@storybook/store';
export declare function watchStorySpecifiers(specifiers: NormalizedStoriesSpecifier[], options: {
    workingDir: Path;
}, onInvalidate: (specifier: NormalizedStoriesSpecifier, path: Path, removed: boolean) => void): () => any;
