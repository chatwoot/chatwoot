import {
  IMPORT_SOURCES,
  importSourceConfigFor,
  importSourceFor,
} from '../importSources';

describe('importSources', () => {
  it('exposes Freshdesk as a domain-based integration source', () => {
    expect(IMPORT_SOURCES.map(source => source.value)).toEqual([
      'intercom',
      'freshdesk',
    ]);
    expect(importSourceConfigFor('freshdesk')).toMatchObject({
      label: 'Freshdesk',
      requiresDomain: true,
    });
  });

  it('resolves persisted integrations and falls back for file imports', () => {
    expect(importSourceFor({ source_provider: 'freshdesk' }).label).toBe(
      'Freshdesk'
    );
    expect(importSourceFor({ source_provider: null })).toMatchObject({
      value: 'file',
      label: 'File import',
    });
  });
});
