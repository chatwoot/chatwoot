import {
  isProviderOffline,
  isReachoutRestricted,
  isSendStalled,
  reachoutRestrictionDeadline,
  isMessageCapped,
  isMessageCapReached,
  messageCapQuota,
} from '../whatsapp';

describe('#isReachoutRestricted', () => {
  const now = new Date('2026-06-16T12:00:00.000Z').getTime();

  it('returns false when there is no lock', () => {
    expect(isReachoutRestricted(undefined, 'open', now)).toBe(false);
    expect(isReachoutRestricted(null, 'open', now)).toBe(false);
  });

  it('returns false when the lock is not active', () => {
    expect(isReachoutRestricted({ is_active: false }, 'open', now)).toBe(false);
  });

  it('returns false when the inbox is not connected (offline banner wins)', () => {
    const lock = { is_active: true };
    expect(isReachoutRestricted(lock, 'close', now)).toBe(false);
    expect(isReachoutRestricted(lock, 'connecting', now)).toBe(false);
  });

  it('returns true when active without a deadline', () => {
    expect(isReachoutRestricted({ is_active: true }, 'open', now)).toBe(true);
  });

  it('returns true when active and the deadline is in the future', () => {
    const lock = {
      is_active: true,
      time_enforcement_ends: '2026-06-19T21:52:39.000Z',
    };
    expect(isReachoutRestricted(lock, 'open', now)).toBe(true);
  });

  it('returns false when the deadline has already passed', () => {
    const lock = {
      is_active: true,
      time_enforcement_ends: '2026-06-15T21:52:39.000Z',
    };
    expect(isReachoutRestricted(lock, 'open', now)).toBe(false);
  });

  it('keeps the restriction visible when the deadline is malformed (fail safe)', () => {
    const lock = { is_active: true, time_enforcement_ends: 'not-a-date' };
    expect(isReachoutRestricted(lock, 'open', now)).toBe(true);
  });
});

describe('#isSendStalled', () => {
  const stall = { consecutive_timeouts: 3, action: 'suppressed' };

  // The pairing that IS the fault: everything else in the view reports a healthy inbox.
  it('warns while the connection still reads open', () => {
    expect(isSendStalled(stall, 'open')).toBe(true);
  });

  it('stays quiet with no stall recorded', () => {
    expect(isSendStalled(undefined, 'open')).toBe(false);
    expect(isSendStalled(null, 'open')).toBe(false);
  });

  // The stored stall outlives the episode on purpose (only a new socket reaching 'open'
  // clears it), so a closed connection would otherwise show both banners at once — and
  // the offline one is the accurate one.
  it('yields to the offline banner once the connection is down', () => {
    expect(isSendStalled(stall, 'close')).toBe(false);
    expect(isSendStalled(stall, 'connecting')).toBe(false);
    expect(isSendStalled(stall, undefined)).toBe(false);
  });
});

describe('#reachoutRestrictionDeadline', () => {
  it('returns an empty string when there is no deadline', () => {
    expect(reachoutRestrictionDeadline(undefined)).toBe('');
    expect(reachoutRestrictionDeadline({ is_active: true })).toBe('');
  });

  it('formats the deadline as a numeric date and time in the app language', () => {
    const formatted = reachoutRestrictionDeadline({
      time_enforcement_ends: '2026-06-19T21:52:39.000Z',
    });
    // English, the default when no i18n instance is bound.
    expect(formatted).toMatch(/^\d{2}\/\d{2}\/\d{4} \d{1,2}:\d{2} (AM|PM)$/);
  });

  it('returns an empty string when the deadline is malformed', () => {
    expect(reachoutRestrictionDeadline({ time_enforcement_ends: 'nope' })).toBe(
      ''
    );
  });
});

describe('#isMessageCapped', () => {
  it('returns false when offline regardless of status', () => {
    expect(isMessageCapped({ capping_status: 'CAPPED' }, 'connecting')).toBe(
      false
    );
  });

  it('returns false for NONE / missing / unknown status', () => {
    expect(isMessageCapped({ capping_status: 'NONE' }, 'open')).toBe(false);
    expect(isMessageCapped(undefined, 'open')).toBe(false);
    expect(isMessageCapped({}, 'open')).toBe(false);
  });

  it('returns true for warning and capped statuses when open', () => {
    expect(isMessageCapped({ capping_status: 'FIRST_WARNING' }, 'open')).toBe(
      true
    );
    expect(isMessageCapped({ capping_status: 'SECOND_WARNING' }, 'open')).toBe(
      true
    );
    expect(isMessageCapped({ capping_status: 'CAPPED' }, 'open')).toBe(true);
  });
});

describe('#isMessageCapReached', () => {
  it('is true only for CAPPED', () => {
    expect(isMessageCapReached({ capping_status: 'CAPPED' })).toBe(true);
    expect(isMessageCapReached({ capping_status: 'FIRST_WARNING' })).toBe(
      false
    );
    expect(isMessageCapReached(undefined)).toBe(false);
  });
});

describe('#messageCapQuota', () => {
  it('returns null when total_quota is missing or zero (placeholder)', () => {
    expect(messageCapQuota(undefined)).toBeNull();
    expect(messageCapQuota({ total_quota: 0, used_quota: 0 })).toBeNull();
  });

  it('returns used/total when a real quota is present', () => {
    expect(messageCapQuota({ total_quota: 100, used_quota: 80 })).toEqual({
      used: 80,
      total: 100,
    });
  });

  it('coerces string numbers and defaults missing used to 0', () => {
    expect(messageCapQuota({ total_quota: '100' })).toEqual({
      used: 0,
      total: 100,
    });
  });
});

describe('#isProviderOffline', () => {
  it('is false while the connection is open', () => {
    expect(isProviderOffline({ connection: 'open' })).toBe(false);
  });

  // A proxy change: the connector redials through the new proxy and is back within a
  // couple of seconds. Telling the agent to link the device again is wrong advice.
  it('is false for a reconnect the connector is making on purpose', () => {
    expect(
      isProviderOffline({ connection: 'reconnecting', rerouting: true })
    ).toBe(false);
  });

  // The redial that follows: `connecting`, still marked, for the second it takes.
  it('is false for the connecting of that reconnect', () => {
    expect(
      isProviderOffline({ connection: 'connecting', rerouting: true })
    ).toBe(false);
  });

  // What an agent receives for a real outage: no error string, which is admin-only.
  it('is true for a reconnect that is not deliberate, with or without an error', () => {
    expect(isProviderOffline({ connection: 'reconnecting' })).toBe(true);
    expect(
      isProviderOffline({
        connection: 'reconnecting',
        error: 'The proxy is not answering.',
      })
    ).toBe(true);
  });

  it('is true for every other state, and for no record at all', () => {
    expect(isProviderOffline({ connection: 'close' })).toBe(true);
    expect(isProviderOffline({ connection: 'connecting' })).toBe(true);
    expect(isProviderOffline({ connection: 'close', rerouting: true })).toBe(
      true
    );
    expect(isProviderOffline(undefined)).toBe(true);
    expect(isProviderOffline(null)).toBe(true);
  });
});
