import { fileURLToPath } from 'node:url';
import { parentPort } from 'node:worker_threads';
import { performance } from 'node:perf_hooks';
import { ModuleCacheMap, ViteNodeRunner } from 'vite-node/client';
import { createBirpc } from 'birpc';
import { dirname, resolve } from 'pathe';
import pc from 'picocolors';
import { createDomEnv } from '../dom/env.js';
const __dirname = dirname(fileURLToPath(import.meta.url));
const _moduleCache = new ModuleCacheMap();
let _runner;
let _rpc;
// Cleanup module cache
parentPort.on('message', message => {
    if (message?.kind === 'hst:invalidate') {
        _moduleCache.delete(message.file);
    }
});
export default async (payload) => {
    const startTime = performance.now();
    process.env.HST_COLLECT = 'true';
    _rpc = createBirpc({}, {
        post: data => payload.port.postMessage(data),
        on: data => payload.port.on('message', data),
    });
    const runner = _runner ?? (_runner = new ViteNodeRunner({
        root: payload.root,
        base: payload.base,
        moduleCache: _moduleCache,
        fetchModule(id) {
            return _rpc.fetchModule(id);
        },
        resolveId(id, importer) {
            return _rpc.resolveId(id, importer);
        },
    }));
    const { destroy: destroyDomEnv } = createDomEnv();
    const el = window.document.createElement('div');
    const beforeExectureTime = performance.now();
    // Mount app to collect stories/variants
    const { run } = (await runner.executeFile(resolve(__dirname, './run.js')));
    const afterExectureTime = performance.now();
    const storyData = [];
    await run({
        file: payload.storyFile,
        storyData,
        el,
    });
    const afterRunTime = performance.now();
    if (payload.storyFile.markdownFile) {
        const el = document.createElement('div');
        el.innerHTML = payload.storyFile.markdownFile.html;
        const text = el.textContent;
        storyData.forEach(s => {
            s.docsText = text;
        });
    }
    destroyDomEnv();
    const endTime = performance.now();
    console.log(pc.dim(`${payload.storyFile.relativePath} ${Math.round(endTime - startTime)}ms (setup:${Math.round(beforeExectureTime - startTime)}ms, execute:${Math.round(afterExectureTime - beforeExectureTime)}ms, run:${Math.round(afterRunTime - afterExectureTime)}ms)`));
    return {
        storyData,
    };
};
