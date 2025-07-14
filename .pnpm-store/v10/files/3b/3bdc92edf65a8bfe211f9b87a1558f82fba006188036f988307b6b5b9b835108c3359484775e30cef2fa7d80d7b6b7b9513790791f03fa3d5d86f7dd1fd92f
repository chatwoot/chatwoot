import { performance } from 'node:perf_hooks';
import { createServer as createViteServer } from 'vite';
import pc from 'picocolors';
import { getViteConfigWithPlugins } from './vite.js';
import * as VirtualFiles from './virtual/index.js';
import { onStoryChange, onStoryListChange, watchStories } from './stories.js';
import { useCollectStories } from './collect/index.js';
import { DevPluginApi, DevEventPluginApi } from './plugin.js';
import { useModuleLoader } from './load.js';
import { wrapLogError } from './util/log.js';
import { createMarkdownFilesWatcher, onMarkdownListChange } from './markdown.js';
export async function createServer(ctx, options = {}) {
    const getViteServer = async (collecting) => {
        const { viteConfig, viteConfigFile } = await getViteConfigWithPlugins(collecting, ctx);
        if (!collecting && options.open) {
            viteConfig.server.open = true;
        }
        const server = await createViteServer(viteConfig);
        await server.pluginContainer.buildStart({});
        return {
            server,
            viteConfigFile,
        };
    };
    // Should be run sequentially to get a fresh vite.config.js each time
    const { server: nodeServer } = await getViteServer(true); // Run before normal vite to prevent breaking HMR in Nuxt
    const { server, viteConfigFile } = await getViteServer(false);
    await watchStories(ctx);
    const { stop: stopMdFileWatcher } = await createMarkdownFilesWatcher(ctx);
    const moduleLoader = useModuleLoader({
        server: nodeServer,
    });
    const pluginOnCleanups = [];
    for (const plugin of ctx.config.plugins) {
        if (plugin.onDev) {
            const api = new DevPluginApi(ctx, plugin, moduleLoader);
            const onCleanup = (cb) => {
                pluginOnCleanups.push(cb);
            };
            await plugin.onDev(api, onCleanup);
        }
    }
    // Custom dev events
    server.ws.on(`histoire:dev-event`, async ({ event, payload }) => {
        for (const plugin of ctx.config.plugins) {
            if (plugin.onDevEvent) {
                const api = new DevEventPluginApi(ctx, plugin, moduleLoader, event, payload);
                const result = await plugin.onDevEvent(api);
                if (!event.startsWith('on') && result !== undefined) {
                    server.ws.send(`histoire:dev-event-result`, { event, result });
                    break;
                }
            }
        }
    });
    // Wait for pre-bundling (in `listen()`)
    await server.listen(options.port ?? server.config.server?.port);
    const { clearCache, executeStoryFile, destroy: destroyCollectStories, } = useCollectStories({
        server: nodeServer,
        mainServer: server,
    }, ctx);
    // onStoryChange debouncing
    let queued = false;
    let queuedFiles = [];
    let currentFiles = [];
    let queueTimer;
    let collecting = false;
    let didAllStoriesYet = false;
    // Invalidate modules
    const invalidateModule = (id) => {
        const mod = server.moduleGraph.getModuleById(id);
        if (!mod) {
            return;
        }
        server.moduleGraph.invalidateModule(mod);
        // Send HMR update
        const timestamp = Date.now();
        mod.lastHMRTimestamp = timestamp;
        server.ws.send({
            type: 'update',
            updates: [
                {
                    type: 'js-update',
                    acceptedPath: mod.url,
                    path: mod.url,
                    timestamp: timestamp,
                },
            ],
        });
    };
    onStoryChange(async (changedFile) => {
        if (changedFile && !didAllStoriesYet) {
            return;
        }
        if (changedFile) {
            if (!queuedFiles.includes(changedFile)) {
                queuedFiles.push(changedFile);
            }
        }
        else {
            queuedFiles = [];
        }
        if (!queued) {
            queued = true;
            if (!collecting) {
                clearTimeout(queueTimer);
                // Debounce
                queueTimer = setTimeout(collect, 100);
            }
            else if (!changedFile && !currentFiles.length) {
                // Full collect in progress
                queued = false;
            }
        }
    });
    async function collect() {
        collecting = true;
        clearCache();
        currentFiles = queuedFiles.slice();
        queuedFiles = [];
        queued = false;
        console.log('Collect stories start', currentFiles.length ? currentFiles.map(f => f.fileName).join(', ') : 'all');
        const time = performance.now();
        if (currentFiles.length) {
            await Promise.all(currentFiles.map(async (storyFile) => {
                await executeStoryFile(storyFile);
                if (storyFile.story) {
                    await invalidateModule(`/__resolved__virtual:story-source:${storyFile.story.id}`);
                }
            }));
        }
        else {
            // Full update
            // Progress tracking
            const fileCount = ctx.storyFiles.length;
            let loadedFilesCount = 0;
            const sendProgress = () => {
                server.ws.send('histoire:stories-loading-progress', {
                    loadedFileCount: loadedFilesCount,
                    totalFileCount: fileCount,
                });
            };
            sendProgress();
            await Promise.all(ctx.storyFiles.map(async (storyFile) => {
                await executeStoryFile(storyFile);
                loadedFilesCount++;
                sendProgress();
            }));
            didAllStoriesYet = true;
            server.ws.send('histoire:all-stories-loaded', {});
        }
        console.log(`Collect stories end ${pc.bold(pc.blue(Math.round(performance.now() - time)))}ms`);
        invalidateModule(VirtualFiles.RESOLVED_STORIES_ID);
        invalidateModule(VirtualFiles.RESOLVED_SEARCH_TITLE_DATA_ID);
        collecting = false;
        if (queued) {
            await collect();
        }
    }
    onStoryListChange(() => {
        invalidateModule(VirtualFiles.RESOLVED_STORIES_ID);
        invalidateModule(VirtualFiles.RESOLVED_SEARCH_TITLE_DATA_ID);
    });
    onMarkdownListChange(() => {
        invalidateModule(VirtualFiles.RESOLVED_MARKDOWN_FILES);
    });
    async function close() {
        for (const cb of pluginOnCleanups) {
            await wrapLogError('plugin.onDev.onCleanup', () => cb());
        }
        await wrapLogError('server.close', () => server.close());
        await wrapLogError('nodeServer', () => nodeServer.close());
        await wrapLogError('destroyCollectStories', () => destroyCollectStories());
        await wrapLogError('stopMdFileWatcher', () => stopMdFileWatcher());
    }
    collect();
    return {
        server,
        viteConfigFile,
        close,
    };
}
