import {
  findPendingMessageIndex,
  applyPageFilters,
} from '../../conversations/helpers';

const chatList = [
  {
    id: 1,
    inbox_id: 2,
    status: 1,
    meta: {},
    labels: ['sales', 'dev'],
  },
  {
    id: 2,
    inbox_id: 2,
    status: 1,
    meta: {},
    labels: ['dev'],
  },
  {
    id: 11,
    inbox_id: 3,
    status: 1,
    meta: { team: { id: 5 } },
    labels: [],
  },
  {
    id: 22,
    inbox_id: 4,
    status: 1,
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
    it('returns true if chat has team and team filter is active', () => {
      const filters = {
        status: 1,
        teamId: 5,
      };
      expect(applyPageFilters(chatList[3], filters)).toEqual(true);
    });
    it('returns true if chat has no team and team filter is active', () => {
      const filters = {
        status: 1,
        teamId: 5,
      };
      expect(applyPageFilters(chatList[0], filters)).toEqual(false);
    });
  });

  describe('#filter-inbox', () => {
    it('returns true if chat has inbox and inbox filter is active', () => {
      const filters = {
        status: 1,
        inboxId: 4,
      };
      expect(applyPageFilters(chatList[3], filters)).toEqual(true);
    });
    it('returns true if chat has no inbox and inbox filter is active', () => {
      const filters = {
        status: 1,
        inboxId: 5,
      };
      expect(applyPageFilters(chatList[0], filters)).toEqual(false);
    });
  });

  describe('#filter-labels', () => {
    it('returns true if chat has labels and labels filter is active', () => {
      const filters = {
        status: 1,
        labels: ['dev'],
      };
      expect(applyPageFilters(chatList[0], filters)).toEqual(true);
    });
    it('returns true if chat has no inbox and inbox filter is active', () => {
      const filters = {
        status: 1,
        labels: ['dev'],
      };
      expect(applyPageFilters(chatList[2], filters)).toEqual(false);
    });
  });

  describe('#filter-status', () => {
    it('returns true if chat has status and status filter is active', () => {
      const filters = {
        status: 1,
      };
      expect(applyPageFilters(chatList[1], filters)).toEqual(true);
    });
  });
});
