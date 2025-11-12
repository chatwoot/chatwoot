export const markdown = (ctx, id) => {
    const fileId = id.slice('/__resolved__virtual:md:'.length);
    const file = ctx.markdownFiles.find(f => f.id === fileId);
    if (!file) {
        throw new Error(`Markdown file not found: ${fileId}`);
    }
    const { html, frontmatter, relativePath } = file;
    return `export const html = ${JSON.stringify(html)}
export const frontmatter = ${JSON.stringify(frontmatter)}
export const relativePath = ${JSON.stringify(relativePath)}

if (import.meta.hot) {
  import.meta.hot.accept(newModule => {
    if (newModule) {
      window.__hst_md_hmr(newModule)
    }
  })
}`;
};
