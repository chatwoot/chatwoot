declare module 'ansi-to-html';
declare module '@storybook/preview-web/dist/cjs/PreviewWeb.mockdata';

declare class AnsiToHtml {
  constructor(options: { escapeHtml: boolean });

  toHtml: (ansi: string) => string;
}
