import DOMPurify from 'dompurify';
import { domPurifyConfig } from '../HTMLSanitizer';

describe('domPurifyConfig', () => {
  const toolLinksConfig = domPurifyConfig.namedConfigurations.toolLinks;

  it('allows tool links in the named configuration', () => {
    const output = DOMPurify.sanitize(
      '<a href="tool://add_private_note">Add private note</a>',
      toolLinksConfig
    );

    expect(output).toContain('href="tool://add_private_note"');
  });

  it('continues to block unsafe links', () => {
    const output = DOMPurify.sanitize(
      '<a href="javascript:alert(1)">Run script</a>',
      toolLinksConfig
    );

    expect(output).toBe('<a>Run script</a>');
  });

  it('does not allow tool links in the default configuration', () => {
    const output = DOMPurify.sanitize(
      '<a href="tool://add_private_note">Add private note</a>'
    );

    expect(output).toBe('<a>Add private note</a>');
  });
});
