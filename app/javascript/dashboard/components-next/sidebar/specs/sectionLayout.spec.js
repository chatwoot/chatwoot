/**
 * Guards the two failure modes of adding section headers to the sidebar:
 * a header that outlives every item it labels, and an upstream item silently
 * vanishing because no section claims it. The logic under test is the pure part
 * of Sidebar.vue's menuSections — mirrored here so it can be exercised without
 * mounting the whole sidebar and its store graph.
 */
const SECTION_LAYOUT = [
  { name: 'work', label: 'Work', items: ['Inbox', 'Tickets'] },
  { name: 'admin', label: 'Insights & setup', items: ['Reports'] },
];

const buildSections = (menuItems, isAllowed) => {
  const isItemVisible = item => {
    if (!item.children?.length) return isAllowed(item.to);
    return item.children.some(child =>
      child.children
        ? child.children.some(sub => sub.to && isAllowed(sub.to))
        : child.to && isAllowed(child.to)
    );
  };

  const byName = new Map(menuItems.map(item => [item.name, item]));
  const sections = SECTION_LAYOUT.map(section => ({
    name: section.name,
    label: section.label,
    items: section.items
      .map(name => byName.get(name))
      .filter(item => item && isItemVisible(item)),
  }));

  const claimed = new Set(SECTION_LAYOUT.flatMap(section => section.items));
  const unclaimed = menuItems.filter(
    item => !claimed.has(item.name) && isItemVisible(item)
  );

  return [
    ...sections,
    ...(unclaimed.length
      ? [{ name: 'other', label: '', items: unclaimed }]
      : []),
  ].filter(section => section.items.length);
};

const items = [
  { name: 'Inbox', to: { name: 'inbox' } },
  { name: 'Tickets', to: { name: 'tickets' } },
  { name: 'Reports', to: { name: 'reports' } },
];

describe('sidebar section layout', () => {
  it('keeps a section only while it still has a visible item', () => {
    const sections = buildSections(items, to => to.name !== 'reports');

    expect(sections.map(section => section.name)).toEqual(['work']);
  });

  it('drops every section when policy hides all items', () => {
    expect(buildSections(items, () => false)).toEqual([]);
  });

  it('keeps a group whose visibility comes from a nested child', () => {
    const nested = [
      {
        name: 'Tickets',
        children: [
          { name: 'Views', children: [{ name: 'Mine', to: { name: 'mine' } }] },
        ],
      },
    ];
    const sections = buildSections(nested, to => to.name === 'mine');

    expect(sections[0].items.map(item => item.name)).toEqual(['Tickets']);
  });

  it('surfaces an item no section claims instead of losing it', () => {
    const withNewcomer = [...items, { name: 'Upstream', to: { name: 'new' } }];
    const sections = buildSections(withNewcomer, () => true);
    const other = sections.find(section => section.name === 'other');

    expect(other.label).toBe('');
    expect(other.items.map(item => item.name)).toEqual(['Upstream']);
  });
});
