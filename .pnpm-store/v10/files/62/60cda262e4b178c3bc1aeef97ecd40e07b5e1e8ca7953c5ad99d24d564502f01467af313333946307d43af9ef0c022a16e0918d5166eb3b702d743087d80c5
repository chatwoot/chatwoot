import { makeTree } from '../tree.js';
export const resolvedStories = (ctx) => {
    const resolvedStories = ctx.storyFiles.filter(s => !!s.story);
    const files = resolvedStories.map((file, index) => {
        return {
            id: file.id,
            path: file.treePath,
            filePath: file.relativePath,
            story: {
                ...file.story,
                docsText: undefined,
            },
            supportPluginId: file.supportPluginId,
            docsFilePath: file.markdownFile?.relativePath,
            index,
        };
    });
    return `${ctx.supportPlugins.map(p => p.importStoriesPrepend).filter(Boolean).join('\n')}
${resolvedStories.map((file, index) => {
        const supportPlugin = ctx.supportPlugins.find(p => p.id === file.supportPluginId);
        if (!supportPlugin) {
            throw new Error(`Could not find support plugin for story ${file.path}: ${file.supportPluginId}`);
        }
        return supportPlugin.importStoryComponent(file, index);
    }).filter(Boolean).join('\n')}
export let files = [${files.map((file) => `{${JSON.stringify(file).slice(1, -1)}, component: Comp${file.index}, source: () => import('virtual:story-source:${file.story.id}')}`).join(',\n')}]
export let tree = ${JSON.stringify(makeTree(ctx.config, resolvedStories))}
const handlers = []
export function onUpdate (cb) {
  handlers.push(cb)
}
if (import.meta.hot) {
  import.meta.hot.accept(newModule => {
    files = newModule.files
    tree = newModule.tree
    handlers.forEach(h => {
      h(newModule.files, newModule.tree)
      newModule.onUpdate(h)
    })
  })
}`;
};
