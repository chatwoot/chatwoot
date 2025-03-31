import { resolve } from 'pathe';
import * as VirtualFiles from './index.js';
import { ID_SEPARATOR } from './util.js';
import { generateDocSearchData, generateTitleSearchData, getSearchDataJS } from '../search.js';
export const createVirtualFilesPlugin = (ctx, isServer) => ({
    name: 'histoire-virtual-files',
    async resolveId(id, importer) {
        if (id.startsWith(VirtualFiles.STORIES_ID)) {
            return VirtualFiles.RESOLVED_STORIES_ID;
        }
        if (id.startsWith(VirtualFiles.SETUP_ID)) {
            const setupFileConfig = ctx.config.setupFile;
            if (setupFileConfig) {
                let file;
                if (typeof setupFileConfig === 'string') {
                    file = setupFileConfig;
                }
                else if (isServer && 'server' in setupFileConfig) {
                    file = setupFileConfig.server;
                }
                else if (!isServer && 'browser' in setupFileConfig) {
                    file = setupFileConfig.browser;
                }
                if (file) {
                    return this.resolve(resolve(ctx.root, file), importer, {
                        skipSelf: true,
                    });
                }
            }
            return VirtualFiles.NOOP_ID;
        }
        if (id.startsWith(VirtualFiles.CONFIG_ID)) {
            return VirtualFiles.RESOLVED_CONFIG_ID;
        }
        if (id.startsWith(VirtualFiles.THEME_ID)) {
            return VirtualFiles.RESOLVED_THEME_ID;
        }
        if (id.startsWith(VirtualFiles.SEARCH_TITLE_DATA_ID)) {
            return VirtualFiles.RESOLVED_SEARCH_TITLE_DATA_ID;
        }
        if (id.startsWith(VirtualFiles.SEARCH_DOCS_DATA_ID)) {
            return VirtualFiles.RESOLVED_SEARCH_DOCS_DATA_ID;
        }
        if (id.startsWith(VirtualFiles.GENERATED_GLOBAL_SETUP)) {
            return VirtualFiles.RESOLVED_GENERATED_GLOBAL_SETUP;
        }
        if (id.startsWith(VirtualFiles.GENERATED_SETUP_CODE)) {
            const [, index] = id.split(ID_SEPARATOR);
            return `${VirtualFiles.RESOLVED_GENERATED_SETUP_CODE}${ID_SEPARATOR}${index}`;
        }
        if (id.startsWith(VirtualFiles.SUPPORT_PLUGINS_CLIENT)) {
            return VirtualFiles.RESOLVED_SUPPORT_PLUGINS_CLIENT;
        }
        if (id.startsWith(VirtualFiles.SUPPORT_PLUGINS_COLLECT)) {
            return VirtualFiles.RESOLVED_SUPPORT_PLUGINS_COLLECT;
        }
        if (id.startsWith(VirtualFiles.MARKDOWN_FILES)) {
            return VirtualFiles.RESOLVED_MARKDOWN_FILES;
        }
        if (id.startsWith(VirtualFiles.COMMANDS)) {
            return VirtualFiles.RESOLVED_COMMANDS;
        }
        if (id.startsWith('virtual:story:')) {
            return `\0${id}`;
        }
        if (id.startsWith('virtual:story-source:')) {
            return `/__resolved__${id}`;
            // @TODO
            // return `\0${id}`
        }
        if (id.startsWith('virtual:md:')) {
            return `/__resolved__${id}`;
            // @TODO
            // return `\0${id}`
        }
    },
    async load(id) {
        if (id === VirtualFiles.RESOLVED_STORIES_ID) {
            return VirtualFiles.resolvedStories(ctx);
        }
        if (id === VirtualFiles.NOOP_ID) {
            return VirtualFiles.noop();
        }
        if (id === VirtualFiles.RESOLVED_CONFIG_ID) {
            return VirtualFiles.resolvedConfig(ctx);
        }
        if (id === VirtualFiles.RESOLVED_THEME_ID) {
            return VirtualFiles.resolvedTheme(ctx);
        }
        if (id === VirtualFiles.RESOLVED_SEARCH_TITLE_DATA_ID) {
            return getSearchDataJS(await generateTitleSearchData(ctx));
        }
        if (id === VirtualFiles.RESOLVED_SEARCH_DOCS_DATA_ID) {
            return getSearchDataJS(await generateDocSearchData(ctx));
        }
        if (id === VirtualFiles.RESOLVED_GENERATED_GLOBAL_SETUP) {
            return VirtualFiles.resolvedGeneratedGlobalSetup(ctx);
        }
        if (id.startsWith(VirtualFiles.RESOLVED_GENERATED_SETUP_CODE)) {
            return VirtualFiles.resolvedGeneratedSetupCode(ctx, id);
        }
        if (id === VirtualFiles.RESOLVED_SUPPORT_PLUGINS_CLIENT) {
            return VirtualFiles.resolvedSupportPluginsClient(ctx);
        }
        if (id === VirtualFiles.RESOLVED_SUPPORT_PLUGINS_COLLECT) {
            return VirtualFiles.resolvedSupportPluginsCollect(ctx);
        }
        if (id === VirtualFiles.RESOLVED_MARKDOWN_FILES) {
            return VirtualFiles.resolvedMarkdownFiles(ctx);
        }
        if (id === VirtualFiles.RESOLVED_COMMANDS) {
            return VirtualFiles.resolvedCommands(ctx);
        }
        if (id.startsWith('\0virtual:story:')) {
            return VirtualFiles.story(ctx, id);
        }
        if (id.startsWith('/__resolved__virtual:story-source:')) {
            return VirtualFiles.storySource(ctx, id);
        }
        if (id.startsWith('/__resolved__virtual:md:')) {
            return VirtualFiles.markdown(ctx, id);
        }
    },
});
