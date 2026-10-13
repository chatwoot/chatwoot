import {
  getImplementedInteractiveCapabilities,
  getInteractiveDraftLimits,
  isInteractiveDraftValid,
} from '../interactiveDraft';

const limitsFor = (type, overrides = {}) =>
  getInteractiveDraftLimits(type, { limits: overrides });

describe('interactiveDraft contract', () => {
  it('returns implemented capabilities in the stable composer order', () => {
    const cta = { implemented: true, available: true };
    const button = { implemented: true, available: false };
    const capabilities = getImplementedInteractiveCapabilities({
      unsupported: { implemented: true },
      cta_url: cta,
      list: { implemented: false },
      button,
    });

    expect(Object.keys(capabilities)).toEqual(['button', 'cta_url']);
    expect(capabilities).toEqual({ button, cta_url: cta });
  });

  it.each([
    [
      'button',
      { body_max_length: 12, button_min_count: 0 },
      {
        bodyMaxLength: 12,
        headerMaxLength: 60,
        footerMaxLength: 60,
        headerTypes: ['text', 'image', 'video', 'document'],
        buttonTitleMaxLength: 20,
        buttonMinCount: 0,
        buttonMaxCount: 3,
      },
    ],
    [
      'list',
      { section_max_count: 4, row_description_max_length: 0 },
      {
        bodyMaxLength: 4096,
        headerMaxLength: 60,
        footerMaxLength: 60,
        buttonMaxLength: 20,
        sectionMinCount: 1,
        sectionMaxCount: 4,
        rowMinCount: 1,
        rowMaxCount: 10,
        sectionTitleMaxLength: 24,
        rowTitleMaxLength: 24,
        rowDescriptionMaxLength: 0,
      },
    ],
    [
      'carousel',
      { card_min_count: 3, action_modes: ['url'], media: [] },
      {
        bodyMaxLength: 1024,
        cardMinCount: 3,
        cardMaxCount: 10,
        cardBodyMaxLength: 160,
        cardBodyMaxLineBreaks: 2,
        media: [],
        actionModes: ['url'],
        buttonMaxLength: 20,
        urlSchemes: ['http', 'https'],
      },
    ],
    [
      'cta_url',
      { header_types: ['image'], url_schemes: ['https'] },
      {
        bodyMaxLength: 1024,
        headerMaxLength: 60,
        footerMaxLength: 60,
        headerTypes: ['image'],
        buttonMaxLength: 20,
        urlSchemes: ['https'],
      },
    ],
  ])(
    'materializes %s limits with exact server overrides and field fallbacks',
    (type, overrides, expected) => {
      expect(limitsFor(type, overrides)).toEqual(expected);
    }
  );

  describe('reply buttons', () => {
    const limits = limitsFor('button');
    const valid = {
      body: ` ${'b'.repeat(1024)} `,
      headerType: 'text',
      headerText: ` ${'h'.repeat(60)} `,
      footer: ` ${'f'.repeat(60)} `,
      buttons: [{ title: ` ${'a'.repeat(20)} ` }, 'Second'],
    };

    it('accepts normalized boundary values and optional empty fields', () => {
      expect(isInteractiveDraftValid('button', valid, limits)).toBe(true);
      expect(
        isInteractiveDraftValid(
          'button',
          { body: 'Choose', footer: '', buttons: ['One'] },
          limits
        )
      ).toBe(true);
    });

    it.each([
      { body: ' ' },
      { body: 'x'.repeat(1025) },
      { headerType: 'text', headerText: ' ' },
      { headerType: 'text', headerText: 'x'.repeat(61) },
      { headerType: 'image', media: null },
      { headerType: 'audio' },
      { footer: ' ' },
      { footer: 'x'.repeat(61) },
      { buttons: [] },
      { buttons: ['One', 'One'] },
      { buttons: ['x'.repeat(21)] },
      { buttons: ['One', 'Two', 'Three', 'Four'] },
    ])('rejects an invalid reply-button edge: %o', invalid => {
      expect(
        isInteractiveDraftValid('button', { ...valid, ...invalid }, limits)
      ).toBe(false);
    });
  });

  describe('lists', () => {
    const limits = limitsFor('list');
    const valid = {
      header: ' ',
      body: ` ${'b'.repeat(4096)} `,
      footer: ' ',
      button: ` ${'o'.repeat(20)} `,
      sections: [
        {
          title: ' ',
          rows: [
            {
              title: ` ${'r'.repeat(24)} `,
              description: ` ${'d'.repeat(72)} `,
            },
          ],
        },
      ],
    };

    it('accepts boundary values and whitespace-only optional fields', () => {
      expect(isInteractiveDraftValid('list', valid, limits)).toBe(true);
    });

    it.each([
      { body: ' ' },
      { body: 'x'.repeat(4097) },
      { header: 'x'.repeat(61) },
      { footer: 'x'.repeat(61) },
      { button: ' ' },
      { button: 'x'.repeat(21) },
      { sections: [] },
      {
        sections: Array.from({ length: 11 }, () => ({
          title: '',
          rows: [{ title: 'Row', description: '' }],
        })),
      },
      { sections: [{ title: '', rows: [] }] },
      {
        sections: [
          { title: 'x'.repeat(25), rows: [{ title: 'Row', description: '' }] },
        ],
      },
      {
        sections: [{ title: '', rows: [{ title: ' ', description: '' }] }],
      },
      {
        sections: [
          {
            title: '',
            rows: [{ title: 'x'.repeat(25), description: '' }],
          },
        ],
      },
      {
        sections: [
          {
            title: '',
            rows: [{ title: 'Row', description: 'x'.repeat(73) }],
          },
        ],
      },
      {
        sections: [
          {
            title: '',
            rows: Array.from({ length: 11 }, () => ({
              title: 'Row',
              description: '',
            })),
          },
        ],
      },
    ])('rejects an invalid list edge: %o', invalid => {
      expect(
        isInteractiveDraftValid('list', { ...valid, ...invalid }, limits)
      ).toBe(false);
    });
  });

  describe('carousels', () => {
    const limits = limitsFor('carousel');
    const urlCard = index => ({
      body: index ? '' : ` ${'b'.repeat(160)} `,
      media: { file: `signed-${index}`, type: 'image/png' },
      action: {
        button: `Card ${index}`,
        url: `https://example.test/${index}`,
      },
    });
    const validUrl = {
      body: ` ${'b'.repeat(1024)} `,
      actionMode: 'url',
      cards: [urlCard(1), urlCard(2)],
    };

    it('accepts boundary-valid URL and uniform quick-reply cards', () => {
      expect(isInteractiveDraftValid('carousel', validUrl, limits)).toBe(true);
      const quickReplyCard = titles => ({
        body: '',
        media: { file: 'signed', type: 'image/jpeg' },
        action: { buttons: titles.map(title => ({ title })) },
      });
      expect(
        isInteractiveDraftValid(
          'carousel',
          {
            body: 'Choose',
            actionMode: 'quick_reply',
            cards: [
              quickReplyCard(['One', 'Two']),
              quickReplyCard(['One', 'Two']),
            ],
          },
          limits
        )
      ).toBe(true);
    });

    it.each([
      { body: ' ' },
      { body: 'x'.repeat(1025) },
      { actionMode: 'unsupported' },
      { cards: [urlCard(1)] },
      { cards: Array.from({ length: 11 }, (_, index) => urlCard(index)) },
      { cards: [{ ...urlCard(1), body: 'x'.repeat(161) }, urlCard(2)] },
      { cards: [{ ...urlCard(1), body: 'a\nb\nc\nd' }, urlCard(2)] },
      { cards: [{ ...urlCard(1), media: null }, urlCard(2)] },
      {
        cards: [
          { ...urlCard(1), media: { file: 'signed', type: 'video/mp4' } },
          urlCard(2),
        ],
      },
      {
        cards: [
          { ...urlCard(1), action: { button: ' ', url: 'https://valid.test' } },
          urlCard(2),
        ],
      },
      {
        cards: [
          { ...urlCard(1), action: { button: 'Open', url: 'ftp://bad.test' } },
          urlCard(2),
        ],
      },
    ])('rejects an invalid URL carousel edge: %o', invalid => {
      expect(
        isInteractiveDraftValid('carousel', { ...validUrl, ...invalid }, limits)
      ).toBe(false);
    });

    it.each([
      {
        titleSets: [
          ['Same', 'Same'],
          ['Same', 'Same'],
        ],
      },
      { titleSets: [[' '], ['One']] },
      { titleSets: [['x'.repeat(21)], ['One']] },
      { titleSets: [['One', 'Two'], ['One']] },
    ])(
      'rejects invalid or inconsistent quick replies: $titleSets',
      ({ titleSets }) => {
        const cards = titleSets.map(titles => ({
          body: '',
          media: { file: 'signed', type: 'image/png' },
          action: { buttons: titles.map(title => ({ title })) },
        }));
        expect(
          isInteractiveDraftValid(
            'carousel',
            { body: 'Choose', actionMode: 'quick_reply', cards },
            limits
          )
        ).toBe(false);
      }
    );
  });

  describe('CTA URLs', () => {
    const limits = limitsFor('cta_url');
    const valid = {
      body: ` ${'b'.repeat(1024)} `,
      footer: ` ${'f'.repeat(60)} `,
      button: ` ${'a'.repeat(20)} `,
      url: ' https://example.test/details ',
      headerType: 'text',
      headerText: ` ${'h'.repeat(60)} `,
    };

    it.each([
      {},
      { headerType: '', headerText: '' },
      { headerType: 'image', media: { file: 'signed-image' } },
      { headerType: 'video', media: { file: 'signed-video' } },
      { headerType: 'document', media: { file: 'signed-document' } },
    ])('accepts a boundary-valid CTA header: %o', header => {
      expect(
        isInteractiveDraftValid('cta_url', { ...valid, ...header }, limits)
      ).toBe(true);
    });

    it.each([
      { body: ' ' },
      { body: 'x'.repeat(1025) },
      { footer: 'x'.repeat(61) },
      { button: ' ' },
      { button: 'x'.repeat(21) },
      { url: '' },
      { url: 'ftp://example.test/file' },
      { url: 'https://example.test/a path' },
      { headerType: 'text', headerText: ' ' },
      { headerType: 'text', headerText: 'x'.repeat(61) },
      { headerType: 'image', media: null },
      { headerType: 'audio' },
    ])('rejects an invalid CTA edge: %o', invalid => {
      expect(
        isInteractiveDraftValid('cta_url', { ...valid, ...invalid }, limits)
      ).toBe(false);
    });
  });
});
