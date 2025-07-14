export const story = (ctx, id) => {
    const moduleId = id.replace('\0', '');
    const storyFile = ctx.storyFiles.find(f => f.moduleId === moduleId && f.virtual);
    if (storyFile) {
        return storyFile.moduleCode;
    }
};
