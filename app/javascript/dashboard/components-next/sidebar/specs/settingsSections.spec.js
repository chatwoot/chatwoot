/**
 * Guards the settings-context sidebar (the second sidebar level shown on
 * /settings/ routes) the same way sectionLayout.spec.js guards the main menu:
 * a group header must never outlive its items, a hidden item must never
 * surface, and an upstream item no group claims must fall through instead of
 * vanishing. Mirrors the pure part of Sidebar.vue's settingsSections.
 */
const GROUP_LAYOUT = [
  { name: 'Account', label: 'Account', items: ['Settings Billing'] },
  { name: 'People', label: 'People', items: ['Settings People'] },
];

const HIDDEN_ITEMS = ['Settings Macros'];

const buildSettingsSections = (settingsItems, isAllowed) => {
  const byName = new Map(settingsItems.map(item => [item.name, item]));

  const sections = GROUP_LAYOUT.map(group => ({
    name: group.name,
    label: group.label,
    items: group.items
      .map(itemName => byName.get(itemName))
      .filter(item => item && item.to && isAllowed(item.to)),
  }));

  const claimed = new Set([
    ...GROUP_LAYOUT.flatMap(group => group.items),
    ...HIDDEN_ITEMS,
  ]);
  const unclaimed = settingsItems.filter(
    item => !claimed.has(item.name) && item.to && isAllowed(item.to)
  );

  return [
    ...sections,
    ...(unclaimed.length
      ? [{ name: 'other', label: '', items: unclaimed }]
      : []),
  ].filter(section => section.items.length);
};

const items = [
  { name: 'Settings Billing', to: { name: 'billing' } },
  { name: 'Settings People', to: { name: 'people' } },
  { name: 'Settings Macros', to: { name: 'macros' } },
];

describe('sidebar settings sections', () => {
  it('drops a group header when policy hides its every item', () => {
    const sections = buildSettingsSections(items, to => to.name !== 'billing');

    expect(sections.map(section => section.name)).toEqual(['People']);
  });

  it('never surfaces a hidden item, not even as unclaimed', () => {
    const sections = buildSettingsSections(items, () => true);

    const surfaced = sections.flatMap(section =>
      section.items.map(item => item.name)
    );
    expect(surfaced).not.toContain('Settings Macros');
  });

  it('funnels an upstream newcomer into the trailing unlabelled section', () => {
    const withNewcomer = [
      ...items,
      { name: 'Settings Upstream', to: { name: 'upstream' } },
    ];
    const sections = buildSettingsSections(withNewcomer, () => true);
    const other = sections.find(section => section.name === 'other');

    expect(other.label).toBe('');
    expect(other.items.map(item => item.name)).toEqual(['Settings Upstream']);
  });

  it('renders nothing when policy hides everything', () => {
    expect(buildSettingsSections(items, () => false)).toEqual([]);
  });
});
