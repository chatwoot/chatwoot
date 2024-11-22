export const label = {
  id: 1,
  title: 'delivery',
  color: '#A2FDD5',
};

const labelsData = [
  { label: 'delivery', id: 3, color: '#A2FDD5' },
  { label: 'lead', id: 6, color: '#F161C8' },
  { label: 'ops-handover', id: 4, color: '#A53326' },
  { label: 'billing', id: 1, color: '#28AD21' },
  { label: 'premium-customer', id: 5, color: '#6FD4EF' },
  { label: 'software', id: 2, color: '#8F6EF2' },
];

export const labelMenuItems = labelsData.map(item => ({
  label: item.label,
  value: item.id,
  thumbnail: {
    color: item.color,
  },
  isSelected: item.label === 'delivery',
  action: 'addLabel',
}));
