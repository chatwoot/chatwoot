import {
  filterByStatus,
  filterByType,
  filterByTypeAndStatus,
  applyInboxPageFilters,
  sortComparator,
} from '../../notifications/helpers';

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

describe('#filterByStatus', () => {
  it('returns the notifications with snoozed status', () => {
    const filters = { status: 'snoozed' };
    notifications.forEach(notification => {
      expect(
        filterByStatus(notification.snoozed_until, filters.status)
      ).toEqual(notification.snoozed_until !== null);
    });
  });
  it('returns true if the notification is snoozed', () => {
    const filters = { status: 'snoozed' };
    expect(
      filterByStatus(notifications[3].snoozed_until, filters.status)
    ).toEqual(true);
  });
  it('returns false if the notification is not snoozed', () => {
    const filters = { status: 'snoozed' };
    expect(
      filterByStatus(notifications[2].snoozed_until, filters.status)
    ).toEqual(false);
  });
});

describe('#filterByType', () => {
  it('returns the notifications with read status', () => {
    const filters = { type: 'read' };
    notifications.forEach(notification => {
      expect(filterByType(notification.read_at, filters.type)).toEqual(
        notification.read_at !== null
      );
    });
  });
  it('returns true if the notification is read', () => {
    const filters = { type: 'read' };
    expect(filterByType(notifications[0].read_at, filters.type)).toEqual(true);
  });
  it('returns false if the notification is not read', () => {
    const filters = { type: 'read' };
    expect(filterByType(notifications[1].read_at, filters.type)).toEqual(false);
  });
});

describe('#filterByTypeAndStatus', () => {
  it('returns the notifications with type and status', () => {
    const filters = { type: 'read', status: 'snoozed' };
    notifications.forEach(notification => {
      expect(
        filterByTypeAndStatus(
          notification.read_at,
          notification.snoozed_until,
          filters.type,
          filters.status
        )
      ).toEqual(
        notification.read_at !== null && notification.snoozed_until !== null
      );
    });
  });
  it('returns true if the notification is read and snoozed', () => {
    const filters = { type: 'read', status: 'snoozed' };
    expect(
      filterByTypeAndStatus(
        notifications[4].read_at,
        notifications[4].snoozed_until,
        filters.type,
        filters.status
      )
    ).toEqual(true);
  });
  it('returns false if the notification is not read and snoozed', () => {
    const filters = { type: 'read', status: 'snoozed' };
    expect(
      filterByTypeAndStatus(
        notifications[3].read_at,
        notifications[3].snoozed_until,
        filters.type,
        filters.status
      )
    ).toEqual(false);
  });
});

describe('#applyInboxPageFilters', () => {
  it('returns the notifications with type and status', () => {
    const filters = { type: 'read', status: 'snoozed' };
    notifications.forEach(notification => {
      expect(applyInboxPageFilters(notification, filters)).toEqual(
        filterByTypeAndStatus(
          notification.read_at,
          notification.snoozed_until,
          filters.type,
          filters.status
        )
      );
    });
  });
  it('returns the notifications with type only', () => {
    const filters = { type: 'read', status: null };
    notifications.forEach(notification => {
      expect(applyInboxPageFilters(notification, filters)).toEqual(
        filterByType(notification.read_at, filters.type)
      );
    });
  });
  it('returns the notifications with status only', () => {
    const filters = { type: null, status: 'snoozed' };
    notifications.forEach(notification => {
      expect(applyInboxPageFilters(notification, filters)).toEqual(
        filterByStatus(notification.snoozed_until, filters.status)
      );
    });
  });
  it('returns true if there are no filters', () => {
    const filters = { type: null, status: null };
    notifications.forEach(notification => {
      expect(applyInboxPageFilters(notification, filters)).toEqual(true);
    });
  });
});

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
