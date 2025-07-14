import { ViteNodeServer } from 'vite-node/server';
import { ViteNodeRunner } from 'vite-node/client';
import pc from 'picocolors';
import { resolve } from 'pathe';
let _load;
export function useModuleLoader(options) {
    const { server } = options;
    const node = new ViteNodeServer(server);
    const runner = new ViteNodeRunner({
        root: server.config.root,
        base: server.config.base,
        fetchModule: async (id) => node.fetchModule(id),
        resolveId: (id, importer) => node.resolveId(id, importer),
    });
    function clearCache() {
        server.moduleGraph.invalidateAll();
        node.fetchCache.clear();
        runner.moduleCache.clear();
    }
    async function loadModule(file) {
        try {
            const result = await runner.executeFile(resolve(file));
            return result;
        }
        catch (e) {
            console.error(pc.red(`Error while loading module ${file}:\n${e.frame ? `${pc.bold(e.message)}\n${e.frame}` : e.stack}`));
            if (options.throws) {
                throw e;
            }
        }
    }
    _load = loadModule;
    async function destroy() {
        // Noop
    }
    return {
        clearCache,
        loadModule,
        destroy,
    };
}
export const loadModule = (...args) => _load?.(...args);
