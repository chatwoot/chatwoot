export const parameters = {
  docs: {
    getContainer: async () => (await import('./blocks')).DocsContainer,
    getPage: async () => (await import('./blocks')).DocsPage
  }
};