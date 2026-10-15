import {
  CATALOG_ERRORS,
  CATALOG_ITEM_LIMITS,
  CATALOG_KINDS,
  CATALOG_MAX_SELECTION,
  CATALOG_TEXT_LIMITS,
  getAvailableFormats,
  groupProductsBySection,
  validateCatalogForm,
} from '../whatsappCatalog';

const items = count => Array.from({ length: count }, (_, i) => ({ id: i }));

describe('whatsappCatalog limits', () => {
  it('exposes limits per format and text', () => {
    expect(CATALOG_ITEM_LIMITS.carousel).toEqual({ min: 2, max: 10 });
    expect(CATALOG_ITEM_LIMITS.product).toEqual({ min: 1, max: 1 });
    expect(CATALOG_ITEM_LIMITS.product_list).toEqual({ min: 1, max: 30 });
    expect(CATALOG_TEXT_LIMITS).toEqual({
      body: 1024,
      header: 60,
      footer: 60,
      section: 24,
    });
  });
});

describe('validateCatalogForm item bounds', () => {
  const cases = [
    [CATALOG_KINDS.CAROUSEL, 0, CATALOG_ERRORS.MIN_ITEMS],
    [CATALOG_KINDS.CAROUSEL, 1, CATALOG_ERRORS.MIN_ITEMS],
    [CATALOG_KINDS.CAROUSEL, 2, undefined],
    [CATALOG_KINDS.CAROUSEL, 10, undefined],
    [CATALOG_KINDS.CAROUSEL, 11, CATALOG_ERRORS.MAX_ITEMS],
    [CATALOG_KINDS.PRODUCT, 0, CATALOG_ERRORS.MIN_ITEMS],
    [CATALOG_KINDS.PRODUCT, 1, undefined],
    [CATALOG_KINDS.PRODUCT, 2, CATALOG_ERRORS.MAX_ITEMS],
    [CATALOG_KINDS.PRODUCT_LIST, 0, CATALOG_ERRORS.MIN_ITEMS],
    [CATALOG_KINDS.PRODUCT_LIST, 1, undefined],
    [CATALOG_KINDS.PRODUCT_LIST, 30, undefined],
    [CATALOG_KINDS.PRODUCT_LIST, 31, CATALOG_ERRORS.MAX_ITEMS],
  ];

  it.each(cases)('%s with %i items -> %s', (kind, count, expected) => {
    const errors = validateCatalogForm({
      kind,
      items: items(count),
      body: 'Hello',
      header: 'Header',
    });
    expect(errors.items).toBe(expected);
  });
});

describe('validateCatalogForm fields', () => {
  it('requires body for carousel', () => {
    const errors = validateCatalogForm({
      kind: 'carousel',
      items: items(2),
      body: '  ',
    });
    expect(errors).toEqual({ body: CATALOG_ERRORS.REQUIRED });
  });

  it('requires body and header for product_list', () => {
    const errors = validateCatalogForm({
      kind: 'product_list',
      items: items(1),
    });
    expect(errors).toEqual({
      body: CATALOG_ERRORS.REQUIRED,
      header: CATALOG_ERRORS.REQUIRED,
    });
  });

  it('does not require texts for a single product', () => {
    expect(validateCatalogForm({ kind: 'product', items: items(1) })).toEqual(
      {}
    );
  });

  it('flags texts over the limit and accepts the exact limit', () => {
    const errors = validateCatalogForm({
      kind: 'product_list',
      items: items(1),
      body: 'a'.repeat(1025),
      header: 'a'.repeat(61),
      footer: 'a'.repeat(61),
    });
    expect(errors).toEqual({
      body: CATALOG_ERRORS.TOO_LONG,
      header: CATALOG_ERRORS.TOO_LONG,
      footer: CATALOG_ERRORS.TOO_LONG,
    });
    expect(
      validateCatalogForm({
        kind: 'product_list',
        items: items(1),
        body: 'a'.repeat(1024),
        header: 'a'.repeat(60),
        footer: 'a'.repeat(60),
      })
    ).toEqual({});
  });
});

describe('groupProductsBySection', () => {
  it('groups by section keeping order and cuts long titles', () => {
    const long = 'x'.repeat(30);
    const result = groupProductsBySection([
      { retailer_id: 'a', section: 'Shoes' },
      { retailer_id: 'b', section: long },
      { retailer_id: 'c', section: 'Shoes' },
    ]);
    expect(result).toEqual([
      {
        title: 'Shoes',
        products: [
          { retailer_id: 'a', section: 'Shoes' },
          { retailer_id: 'c', section: 'Shoes' },
        ],
      },
      {
        title: 'x'.repeat(24),
        products: [{ retailer_id: 'b', section: long }],
      },
    ]);
  });
});

describe('getAvailableFormats', () => {
  const availability = count =>
    Object.fromEntries(
      getAvailableFormats(count).map(f => [f.kind, f.available])
    );

  it('exposes the global selection cap', () => {
    expect(CATALOG_MAX_SELECTION).toBe(30);
  });

  it('marks every format unavailable by minimum with 0', () => {
    getAvailableFormats(0).forEach(format => {
      expect(format.available).toBe(false);
      expect(format.reason.key).toBe(CATALOG_ERRORS.MIN_ITEMS);
    });
  });

  it.each([
    [1, { carousel: false, product: true, product_list: true }],
    [2, { carousel: true, product: false, product_list: true }],
    [10, { carousel: true, product: false, product_list: true }],
    [11, { carousel: false, product: false, product_list: true }],
    [30, { carousel: false, product: false, product_list: true }],
    [31, { carousel: false, product: false, product_list: false }],
  ])('with %i selected', (count, expected) => {
    expect(availability(count)).toEqual(expected);
  });

  it('explains why with the number', () => {
    const [carousel, product, list] = getAvailableFormats(31);
    expect(carousel.reason).toEqual({
      key: CATALOG_ERRORS.MAX_ITEMS,
      params: { max: 10 },
    });
    expect(product.reason.params).toEqual({ max: 1 });
    expect(list.reason.params).toEqual({ max: 30 });
    expect(getAvailableFormats(1)[0].reason.params).toEqual({ min: 2 });
  });
});
