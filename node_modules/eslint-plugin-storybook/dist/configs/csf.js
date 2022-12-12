"use strict";
module.exports = {
    plugins: ['storybook'],
    overrides: [
        {
            files: ['*.stories.@(ts|tsx|js|jsx|mjs|cjs)', '*.story.@(ts|tsx|js|jsx|mjs|cjs)'],
            rules: {
                'import/no-anonymous-default-export': 'off',
                'storybook/csf-component': 'warn',
                'storybook/default-exports': 'error',
                'storybook/hierarchy-separator': 'warn',
                'storybook/no-redundant-story-name': 'warn',
                'storybook/story-exports': 'error',
            },
        },
    ],
};
