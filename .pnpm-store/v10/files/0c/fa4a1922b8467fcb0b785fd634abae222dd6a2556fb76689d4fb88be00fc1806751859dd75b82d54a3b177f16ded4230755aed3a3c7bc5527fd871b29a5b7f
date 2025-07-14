import { resolveConfig as resolveViteConfig } from 'vite';
import { processConfig, resolveConfig } from './config.js';
import { mergeHistoireViteConfig } from './vite.js';
export async function createContext(options) {
    const config = await resolveConfig(process.cwd(), options.mode, options.configFile);
    const command = options.mode === 'dev' ? 'serve' : 'build';
    const viteConfig = await resolveViteConfig({}, command);
    const supportPlugins = config.plugins.map(p => p.supportPlugin).filter(Boolean);
    const ctx = {
        root: viteConfig.root,
        config,
        resolvedViteConfig: null,
        mode: options.mode,
        storyFiles: [],
        supportPlugins,
        markdownFiles: [],
        registeredCommands: [],
    };
    ctx.resolvedViteConfig = await mergeHistoireViteConfig(viteConfig, ctx);
    await processConfig(ctx);
    // List commands
    for (const plugin of ctx.config.plugins) {
        if (plugin.commands?.length) {
            ctx.registeredCommands.push(...plugin.commands);
        }
    }
    return ctx;
}
