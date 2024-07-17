import { sortComparator } from '../../notifications/helpers';

const notifications = [
  {
    id: 1,
    read_at: '2024-02-07T11:42:39.988Z',
    snoozed_until: null,
    created_at: 1707328400,
  },
  {
    id: 2,
    read_at: null,
    snoozed_until: null,
    created_at: 1707233688,
  },
  {
    id: 3,
    read_at: '2024-01-07T11:42:39.988Z',
    snoozed_until: null,
    created_at: 1707233672,
  },
  {
    id: 4,
    read_at: null,
    snoozed_until: '2024-02-08T03:30:00.000Z',
    created_at: 1707233667,
  },
  {
    id: 5,
    read_at: '2024-02-07T10:42:39.988Z',
    snoozed_until: '2024-02-08T03:30:00.000Z',
    created_at: 1707233662,
  },
  {
    id: 6,
    read_at: null,
    snoozed_until: '2024-02-08T03:30:00.000Z',
    created_at: 1707233561,
  },
];

describe('#sortComparator', () => {
  it('returns the notifications sorted by newest', () => {
    const sortOrder = 'newest';
    const sortedNotifications = [...notifications].sort((a, b) =>
      sortComparator(a, b, sortOrder)
    );
    const expectedOrder = [
      notifications[0],
      notifications[1],
      notifications[2],
      notifications[3],
      notifications[4],
      notifications[5],
    ].sort((a, b) => b.created_at - a.created_at);
    expect(sortedNotifications).toEqual(expectedOrder);
  });

  it('returns the notifications sorted by oldest', () => {
    const sortOrder = 'oldest';
    const sortedNotifications = [...notifications].sort((a, b) =>
      sortComparator(a, b, sortOrder)
    );
    const expectedOrder = [
      notifications[0],
      notifications[1],
      notifications[2],
      notifications[3],
      notifications[4],
      notifications[5],
    ].sort((a, b) => a.created_at - b.created_at);
    expect(sortedNotifications).toEqual(expectedOrder);
  });
});
