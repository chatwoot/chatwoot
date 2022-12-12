"use strict";
module.exports = {
    plugins: ['storybook'],
    overrides: [
        {
            files: ['*.stories.@(ts|tsx|js|jsx|mjs|cjs)', '*.story.@(ts|tsx|js|jsx|mjs|cjs)'],
            rules: {
                'import/no-anonymous-default-export': 'off',
                'storybook/await-interactions': 'error',
                'storybook/context-in-play-function': 'error',
                'storybook/default-exports': 'error',
                'storybook/hierarchy-separator': 'warn',
                'storybook/no-redundant-story-name': 'warn',
                'storybook/prefer-pascal-case': 'warn',
                'storybook/story-exports': 'error',
                'storybook/use-storybook-expect': 'error',
                'storybook/use-storybook-testing-library': 'error',
            },
        },
    ],
};
