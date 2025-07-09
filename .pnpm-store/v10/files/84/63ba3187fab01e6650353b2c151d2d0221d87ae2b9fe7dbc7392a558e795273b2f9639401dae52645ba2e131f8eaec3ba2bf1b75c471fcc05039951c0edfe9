export function getSerializedStoryData(ctx) {
    const data = {
        stories: [],
        markdownFiles: [],
    };
    for (const storyFile of ctx.storyFiles) {
        if (storyFile.story) {
            data.stories.push({
                ...Object.assign({}, storyFile.story, {
                    docsText: undefined,
                }),
                relativePath: storyFile.relativePath,
                supportPluginId: storyFile.supportPluginId,
                treePath: storyFile.treePath,
                virtual: storyFile.virtual,
                markdownFile: storyFile.markdownFile
                    ? {
                        id: storyFile.markdownFile.id,
                        relativePath: storyFile.markdownFile.relativePath,
                        isRelatedToStory: storyFile.markdownFile.isRelatedToStory,
                        frontmatter: storyFile.markdownFile.frontmatter,
                    }
                    : null,
            });
        }
    }
    for (const markdownFile of ctx.markdownFiles) {
        data.markdownFiles.push({
            id: markdownFile.id,
            relativePath: markdownFile.relativePath,
            isRelatedToStory: markdownFile.isRelatedToStory,
            frontmatter: markdownFile.frontmatter,
        });
    }
    return data;
}
