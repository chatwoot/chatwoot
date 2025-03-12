import {
  findPendingMessageIndex,
  applyPageFilters,
  filterByInbox,
  filterByTeam,
  filterByLabel,
  filterByUnattended,
  deepObjectDiff,
} from '../../conversations/helpers';

const conversationList = [
  {
    id: 1,
    inbox_id: 2,
    status: 'open',
    meta: {},
    labels: ['sales', 'dev'],
  },
  {
    id: 2,
    inbox_id: 2,
    status: 'open',
    meta: {},
    labels: ['dev'],
  },
  {
    id: 11,
    inbox_id: 3,
    status: 'resolved',
    meta: { team: { id: 5 } },
    labels: [],
  },
  {
    id: 22,
    inbox_id: 4,
    status: 'pending',
    meta: { team: { id: 5 } },
    labels: ['sales'],
  },
];

describe('#findPendingMessageIndex', () => {
  it('returns the correct index of pending message with id', () => {
    const chat = {
      messages: [{ id: 1, status: 'progress' }],
    };
    const message = { echo_id: 1 };
    expect(findPendingMessageIndex(chat, message)).toEqual(0);
  });

  it('returns -1 if pending message with id is not present', () => {
    const chat = {
      messages: [{ id: 1, status: 'progress' }],
    };
    const message = { echo_id: 2 };
    expect(findPendingMessageIndex(chat, message)).toEqual(-1);
  });
});

describe('#applyPageFilters', () => {
  describe('#filter-team', () => {
    it('returns true if conversation has team and team filter is active', () => {
      const filters = {
        status: 'resolved',
        teamId: 5,
      };
      expect(applyPageFilters(conversationList[2], filters)).toEqual(true);
    });
    it('returns true if conversation has no team and team filter is active', () => {
      const filters = {
        status: 'open',
        teamId: 5,
      };
      expect(applyPageFilters(conversationList[0], filters)).toEqual(false);
    });
  });

  describe('#filter-inbox', () => {
    it('returns true if conversation has inbox and inbox filter is active', () => {
      const filters = {
        status: 'pending',
        inboxId: 4,
      };
      expect(applyPageFilters(conversationList[3], filters)).toEqual(true);
    });
    it('returns true if conversation has no inbox and inbox filter is active', () => {
      const filters = {
        status: 'open',
        inboxId: 5,
      };
      expect(applyPageFilters(conversationList[0], filters)).toEqual(false);
    });
  });

  describe('#filter-labels', () => {
    it('returns true if conversation has labels and labels filter is active', () => {
      const filters = {
        status: 'open',
        labels: ['dev'],
      };
      expect(applyPageFilters(conversationList[0], filters)).toEqual(true);
    });
    it('returns true if conversation has no inbox and inbox filter is active', () => {
      const filters = {
        status: 'open',
        labels: ['dev'],
      };
      expect(applyPageFilters(conversationList[2], filters)).toEqual(false);
    });
  });

  describe('#filter-status', () => {
    it('returns true if conversation has status and status filter is active', () => {
      const filters = {
        status: 'open',
      };
      expect(applyPageFilters(conversationList[1], filters)).toEqual(true);
    });
    it('returns true if conversation has status and status filter is all', () => {
      const filters = {
        status: 'all',
      };
      expect(applyPageFilters(conversationList[1], filters)).toEqual(true);
    });
  });
});

describe('#filterByInbox', () => {
  it('returns true if conversation has inbox filter active', () => {
    const inboxId = '1';
    const chatInboxId = 1;
    expect(filterByInbox(true, inboxId, chatInboxId)).toEqual(true);
  });
  it('returns false if inbox filter is not active', () => {
    const inboxId = '1';
    const chatInboxId = 13;
    expect(filterByInbox(true, inboxId, chatInboxId)).toEqual(false);
  });
});

describe('#filterByTeam', () => {
  it('returns true if conversation has team and team filter is active', () => {
    const [teamId, chatTeamId] = ['1', 1];
    expect(filterByTeam(true, teamId, chatTeamId)).toEqual(true);
  });
  it('returns false if team filter is not active', () => {
    const [teamId, chatTeamId] = ['1', 12];
    expect(filterByTeam(true, teamId, chatTeamId)).toEqual(false);
  });
});

describe('#filterByLabel', () => {
  it('returns true if conversation has labels and labels filter is active', () => {
    const labels = ['dev', 'cs'];
    const chatLabels = ['dev', 'cs', 'sales'];
    expect(filterByLabel(true, labels, chatLabels)).toEqual(true);
  });
  it('returns false if conversation has not all labels', () => {
    const labels = ['dev', 'cs', 'sales'];
    const chatLabels = ['cs', 'sales'];
    expect(filterByLabel(true, labels, chatLabels)).toEqual(false);
  });
});

describe('#filterByUnattended', () => {
  it('returns true if conversation type is unattended and has no first reply', () => {
    expect(filterByUnattended(true, 'unattended', undefined)).toEqual(true);
  });
  it('returns false if conversation type is not unattended and has no first reply', () => {
    expect(filterByUnattended(false, 'mentions', undefined)).toEqual(false);
  });
  it('returns true if conversation type is unattended and has first reply', () => {
    expect(filterByUnattended(true, 'mentions', 123)).toEqual(true);
  });
});

describe('#deepObjectDiff', () => {
  it('should detect added properties', () => {
    const original = { name: 'John', age: 30 };
    const updated = { name: 'John', age: 30, email: 'john@example.com' };

    const result = deepObjectDiff(original, updated);

    expect(result.added).toEqual({ email: 'john@example.com' });
    expect(result.removed).toEqual({});
    expect(result.modified).toEqual({});
  });

  it('should detect removed properties', () => {
    const original = { name: 'John', age: 30, email: 'john@example.com' };
    const updated = { name: 'John', age: 30 };

    const result = deepObjectDiff(original, updated);

    expect(result.added).toEqual({});
    expect(result.removed).toEqual({ email: 'john@example.com' });
    expect(result.modified).toEqual({});
  });

  it('should detect modified properties', () => {
    const original = { name: 'John', age: 30 };
    const updated = { name: 'John', age: 31 };

    const result = deepObjectDiff(original, updated);

    expect(result.added).toEqual({});
    expect(result.removed).toEqual({});
    expect(result.modified).toEqual({ age: { from: 30, to: 31 } });
  });

  it('should handle nested objects', () => {
    const original = {
      name: 'John',
      address: { city: 'New York', country: 'USA' },
    };
    const updated = {
      name: 'John',
      address: { city: 'Boston', country: 'USA' },
    };

    const result = deepObjectDiff(original, updated);

    expect(result.added).toEqual({});
    expect(result.removed).toEqual({});
    expect(result.modified).toEqual({
      'address.city': { from: 'New York', to: 'Boston' },
    });
  });

  it('should respect maxDepth parameter', () => {
    const original = {
      user: {
        details: {
          address: { city: 'New York', country: 'USA' },
        },
      },
    };
    const updated = {
      user: {
        details: {
          address: { city: 'Boston', country: 'USA' },
        },
      },
    };

    // With maxDepth of 2
    const result2 = deepObjectDiff(original, updated, 2);
    expect(result2.modified).toEqual({
      'user.details': {
        from: {
          address: { city: 'New York', country: 'USA' },
        },
        to: {
          address: { city: 'Boston', country: 'USA' },
        },
      },
    });

    // With maxDepth of 4 (enough to reach the deepest level)
    const result4 = deepObjectDiff(original, updated, 4);
    expect(result4.modified).toEqual({
      'user.details.address.city': { from: 'New York', to: 'Boston' },
    });
  });

  it('should handle arrays correctly', () => {
    const original = { tags: ['important', 'urgent'] };
    const updated = { tags: ['important', 'normal'] };

    const result = deepObjectDiff(original, updated);

    expect(result.modified).toEqual({
      tags: {
        from: ['important', 'urgent'],
        to: ['important', 'normal'],
      },
    });
  });

  it('should handle empty objects', () => {
    const original = {};
    const updated = {};

    const result = deepObjectDiff(original, updated);

    expect(result.added).toEqual({});
    expect(result.removed).toEqual({});
    expect(result.modified).toEqual({});
  });

  it('should handle completely different objects', () => {
    const original = { a: 1, b: 2 };
    const updated = { c: 3, d: 4 };

    const result = deepObjectDiff(original, updated);

    expect(result.added).toEqual({ c: 3, d: 4 });
    expect(result.removed).toEqual({ a: 1, b: 2 });
    expect(result.modified).toEqual({});
  });
});
