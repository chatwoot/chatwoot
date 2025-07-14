import path from 'pathe';
import { createDefu } from 'defu';
import { resolveConfig as resolveViteConfig, mergeConfig as mergeViteConfig, } from 'vite';
import jiti from 'jiti';
import { fileURLToPath } from 'node:url';
import pc from 'picocolors';
import fs from 'node:fs';
import { defaultColors } from './colors.js';
import { findUp } from './util/find-up.js';
import { tailwindTokens } from './builtin-plugins/tailwind-tokens.js';
import { vanillaSupport } from './builtin-plugins/vanilla-support/plugin.js';
const __filename = fileURLToPath(import.meta.url);
export function getDefaultConfig() {
    return {
        plugins: [
            vanillaSupport(),
            tailwindTokens(),
        ],
        outDir: '.histoire/dist',
        storyMatch: [
            '**/*.story.vue',
            '**/*.story.svelte',
        ],
        storyIgnored: [
            '**/node_modules/**',
            '**/dist/**',
        ],
        supportMatch: [],
        tree: {
            file: 'title',
            order: 'asc',
        },
        theme: {
            title: 'Histoire',
            colors: {
                primary: defaultColors.emerald,
                gray: defaultColors.zinc,
            },
            defaultColorScheme: 'auto',
            storeColorScheme: true,
            darkClass: 'dark',
        },
        responsivePresets: [
            {
                label: 'Mobile (Small)',
                width: 320,
                height: 560,
            },
            {
                label: 'Mobile (Medium)',
                width: 360,
                height: 640,
            },
            {
                label: 'Mobile (Large)',
                width: 414,
                height: 896,
            },
            {
                label: 'Tablet',
                width: 768,
                height: 1024,
            },
            {
                label: 'Laptop (Small)',
                width: 1024,
                height: null,
            },
            {
                label: 'Laptop (Large)',
                width: 1366,
                height: null,
            },
            {
                label: 'Desktop',
                width: 1920,
                height: null,
            },
            {
                label: '4K',
                width: 3840,
                height: null,
            },
        ],
        backgroundPresets: [
            {
                label: 'Transparent',
                color: 'transparent',
                contrastColor: '#333',
            },
            {
                label: 'White',
                color: '#fff',
                contrastColor: '#333',
            },
            {
                label: 'Light gray',
                color: '#aaa',
                contrastColor: '#000',
            },
            {
                label: 'Dark gray',
                color: '#333',
                contrastColor: '#fff',
            },
            {
                label: 'Black',
                color: '#000',
                contrastColor: '#eee',
            },
        ],
        sandboxDarkClass: 'dark',
        routerMode: 'history',
        build: {
            excludeFromVendorsChunk: [],
        },
        vite: (config) => {
            // Remove vite:legacy plugins https://github.com/histoire-dev/histoire/issues/156
            const index = config.plugins?.findIndex(plugin => Array.isArray(plugin) &&
                typeof plugin[0] === 'object' &&
                !Array.isArray(plugin[0]) &&
                // @ts-expect-error could have no property 'name'
                plugin[0].name?.startsWith('vite:legacy'));
            if (index !== -1) {
                config.plugins?.splice(index, 1);
            }
            return {
                build: {
                    lib: false,
                },
            };
        },
        viteIgnorePlugins: [],
    };
}
export const configFileNames = [
    'histoire.config.ts',
    'histoire.config.js',
    '.histoire.ts',
    '.histoire.js',
];
export function resolveConfigFile(cwd = process.cwd(), configFile) {
    if (configFile) {
        // explicit config path is always resolved from cwd
        return path.resolve(configFile);
    }
    else {
        return findUp(cwd, configFileNames);
    }
}
export async function loadConfigFile(configFile) {
    try {
        const result = jiti(__filename, {
            esmResolve: true,
            requireCache: false,
        })(configFile);
        if (!result.default) {
            throw new Error(`Expected default export in ${configFile}`);
        }
        return result.default;
    }
    catch (e) {
        console.error(pc.red(`Error while loading ${configFile}`));
        throw e;
    }
}
export const mergeBuildConfig = createDefu((obj, key, value) => {
    if (obj[key] && key === 'excludeFromVendorsChunk') {
        obj[key] = [...obj[key], ...value];
        return true;
    }
});
export const mergeConfig = createDefu((obj, key, value) => {
    if (obj[key] && key === 'vite') {
        const initialValue = obj[key];
        // Convert to functions
        const initialFn = typeof initialValue === 'function' ? initialValue : async () => initialValue;
        const valueFn = typeof value === 'function' ? value : async () => value;
        obj[key] = async (...args) => {
            // `mergeViteConfig` doesn't accept functions so we need to call them
            const initialResult = await initialFn(...args);
            const valueResult = await valueFn(...args);
            return mergeViteConfig(initialResult, valueResult);
        };
        return true;
    }
    if (obj[key] && key === 'plugins') {
        const initialValue = obj[key];
        const newValue = obj[key] = [...value];
        const nameMap = newValue.reduce((map, plugin) => {
            map[plugin.name] = true;
            return map;
        }, {});
        for (const plugin of initialValue) {
            if (!nameMap[plugin.name]) {
                newValue.unshift(plugin);
            }
        }
        return true;
    }
    if (obj[key] && key === 'setupCode') {
        obj[key] = [...obj[key], ...value];
        return true;
    }
    if (obj[key] && key === 'supportMatch') {
        for (const item of value) {
            const existing = obj[key].find(p => p.id === item.id);
            if (existing) {
                existing.patterns = [...existing.patterns, ...item.patterns];
                existing.pluginIds = [...existing.pluginIds, ...item.pluginIds];
            }
            else {
                obj[key].push(item);
            }
        }
        return true;
    }
    if (obj[key] && key === 'build') {
        obj[key] = mergeBuildConfig(obj[key], value);
        return true;
    }
    // By default, arrays should be replaced
    if (obj[key] && Array.isArray(obj[key])) {
        obj[key] = value;
        return true;
    }
});
export async function resolveConfig(cwd = process.cwd(), mode, configFile) {
    let result;
    const resolvedConfigFile = resolveConfigFile(cwd, configFile);
    if (resolvedConfigFile) {
        result = await loadConfigFile(resolvedConfigFile);
    }
    const viteConfig = await resolveViteConfig({}, 'serve');
    const viteHistoireConfig = (viteConfig.histoire ?? {});
    const preUserConfig = mergeConfig(result, viteHistoireConfig);
    const processedDefaultConfig = await processDefaultConfig(getDefaultConfig(), preUserConfig, mode, cwd);
    return resolveConfigPlugins(mergeConfig(preUserConfig, processedDefaultConfig), mode);
}
async function resolveConfigPlugins(config, mode) {
    for (const plugin of config.plugins) {
        if (plugin.config) {
            const result = await plugin.config(config, mode);
            if (result) {
                config = mergeConfig(result, config);
            }
        }
    }
    return config;
}
async function processDefaultConfig(defaultConfig, preUserConfig, mode, cwd) {
    // Apply plugins
    for (const plugin of [...defaultConfig.plugins, ...preUserConfig.plugins ?? []]) {
        if (plugin.defaultConfig) {
            const result = await plugin.defaultConfig(defaultConfig, mode);
            if (result) {
                defaultConfig = mergeConfig(result, defaultConfig);
            }
        }
    }
    return defaultConfig;
}
export async function processConfig(ctx) {
    const { config, root } = ctx;
    // Resolve files paths
    const resolveFsPath = (file, force = false) => {
        if (force || file.startsWith('./') || file.startsWith('../')) {
            return path.resolve(root, file);
        }
        return file;
    };
    const fileCheck = (file, resolvedFile, configPathForError) => {
        if (!file.startsWith('http') && !file.startsWith('@') && !fs.existsSync(resolvedFile)) {
            console.warn(pc.yellow(`Histoire config: ${configPathForError} file ${file} does not exist (resolved to ${resolvedFile}), check for typos in the path`));
        }
    };
    config.outDir = resolveFsPath(config.outDir, true);
    // Theme
    if (config.theme?.logo?.square) {
        const file = config.theme.logo.square;
        config.theme.logo.square = resolveFsPath(file);
        fileCheck(file, config.theme.logo.square, 'theme.logo.square');
    }
    if (config.theme?.logo?.light) {
        const file = config.theme.logo.light;
        config.theme.logo.light = resolveFsPath(file);
        fileCheck(file, config.theme.logo.light, 'theme.logo.light');
    }
    if (config.theme?.logo?.dark) {
        const file = config.theme.logo.dark;
        config.theme.logo.dark = resolveFsPath(file);
        fileCheck(file, config.theme.logo.dark, 'theme.logo.dark');
    }
    if (config.theme?.favicon) {
        let file = config.theme.favicon;
        if (file.startsWith('/')) {
            file = file.slice(1);
        }
        if (!file.startsWith('http')) {
            const publicDir = path.resolve(ctx.resolvedViteConfig.root, ctx.resolvedViteConfig.publicDir);
            // Resolve URL path
            if (file.startsWith('./') || file.startsWith('../')) {
                const resolvedFile = resolveFsPath(file, true);
                const relativeFile = path.relative(publicDir, resolvedFile);
                if (relativeFile.startsWith('..')) {
                    throw new Error(pc.red(`Histoire config: theme.favicon seems to target a file that is not in the vite 'public' directory: ${file} (resolved as ${resolvedFile})`));
                }
                if (!fs.existsSync(resolvedFile)) {
                    throw new Error(pc.red(`Histoire config: theme.favicon seems to target a file that does not exist: ${file} (resolved as ${resolvedFile})`));
                }
                config.theme.favicon = relativeFile;
            }
            else {
                // Check if URL path is valid
                const resolvedFile = path.resolve(publicDir, file);
                if (!fs.existsSync(resolvedFile)) {
                    throw new Error(pc.red(`Histoire config: theme.favicon seems to target a file that does not exist: ${file} (resolved as ${resolvedFile}).\nThe favicon file should be placed in the vite 'public' directory.\nExample: if the file is in <project>/public/img/favicon.ico, you can put 'img/favicon.ico' or './public/img/favicon.ico'.`));
                }
            }
        }
    }
}
export function defineConfig(config) {
    return config;
}
