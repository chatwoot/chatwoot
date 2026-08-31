import config from '../../../../config/markdown_embeds.yml';

// Gists rely on document.write() and can't render inline in the editor.
const NON_PREVIEWABLE_EMBEDS = new Set(['github_gist']);

export const embeds = Object.entries(config)
  .filter(([key]) => !NON_PREVIEWABLE_EMBEDS.has(key))
  .map(([, { regex, template }]) => ({
    regex: new RegExp(regex),
    template,
  }));
