import generateStoryCommand from './commands/generate-story.server.js';
import { listComponentFiles } from './util/list-components.js';
export function HstVue() {
    return {
        name: '@histoire/plugin-vue',
        defaultConfig() {
            return {
                supportMatch: [
                    {
                        id: 'vue',
                        patterns: ['**/*.vue'],
                        pluginIds: ['vue3'],
                    },
                ],
            };
        },
        config() {
            return {
                vite: {
                    plugins: [
                        {
                            name: 'histoire-plugin-vue',
                            enforce: 'post',
                            transform(code, id) {
                                // Remove vue warnings about unknown components
                                if (this.meta.histoire?.isCollecting && id.endsWith('.vue')) {
                                    return `const _stubComponent = (name) => ['Story','Variant'].includes(name) ? _resolveComponent(name) : ({ render: () => null });${code?.replaceAll('_resolveComponent(', '_stubComponent(') ?? ''}`;
                                }
                            },
                        },
                    ],
                },
            };
        },
        supportPlugin: {
            id: 'vue3',
            moduleName: '@histoire/plugin-vue',
            setupFn: 'setupVue3',
            importStoriesPrepend: `import { defineAsyncComponent as defineAsyncComponentVue3 } from 'vue'`,
            importStoryComponent: (file, index) => `const Comp${index} = defineAsyncComponentVue3(() => import(${JSON.stringify(file.moduleId)}))`,
        },
        commands: [
            generateStoryCommand,
        ],
        async onDevEvent(api) {
            switch (api.event) {
                case 'listVueComponents': {
                    return listComponentFiles(api.payload.search, api.getConfig().storyMatch);
                }
            }
        },
    };
}
export * from './helpers.js';
