import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { getCompanyProfile, groupByDay } from '../companyHelper';

describe('companyHelper', () => {
  describe('getCompanyProfile', () => {
    it('prefers the most specific industry and the exact employee count', () => {
      expect(
        getCompanyProfile({
          industry: 'Financials',
          sub_industry: 'Payment Processing',
          employee_count_range: '5001-10000',
          employee_count: 8500,
          city: 'South San Francisco',
          country: 'United States',
          country_code: 'US',
        })
      ).toEqual({
        industry: 'Payment Processing',
        employees: (8500).toLocaleString(),
        location: 'South San Francisco, US',
        fullLocation: 'South San Francisco, United States',
        countryCode: 'US',
      });
    });

    it('falls back to the industry and the employee range', () => {
      const profile = getCompanyProfile({
        industry: 'Financials',
        employee_count_range: '51-200',
      });

      expect(profile.industry).toBe('Financials');
      expect(profile.employees).toBe('51-200');
    });

    it('shows the country name when there is no city', () => {
      const profile = getCompanyProfile({
        country: 'India',
        country_code: 'IN',
      });

      expect(profile.location).toBe('India');
      expect(profile.fullLocation).toBe('India');
    });

    it('returns empty values when attributes are missing', () => {
      expect(getCompanyProfile(undefined)).toEqual({
        industry: undefined,
        employees: undefined,
        location: '',
        fullLocation: '',
        countryCode: undefined,
      });
    });
  });

  describe('groupByDay', () => {
    const t = key => key;
    const toUnix = value => Math.floor(new Date(value).getTime() / 1000);

    beforeEach(() => {
      vi.useFakeTimers();
      vi.setSystemTime(new Date('2026-10-03T12:00:00Z'));
    });

    afterEach(() => {
      vi.useRealTimers();
    });

    it('groups consecutive items by day with today and yesterday labels', () => {
      const items = [
        { id: 1, timestamp: toUnix('2026-10-03T10:00:00Z') },
        { id: 2, timestamp: toUnix('2026-10-03T08:00:00Z') },
        { id: 3, timestamp: toUnix('2026-10-02T09:00:00Z') },
        { id: 4, timestamp: toUnix('2026-09-27T09:00:00Z') },
      ];

      expect(groupByDay(items, 'timestamp', t)).toEqual([
        {
          label: 'COMPANIES.DETAIL.ACTIVITY.TODAY',
          items: [items[0], items[1]],
        },
        { label: 'COMPANIES.DETAIL.ACTIVITY.YESTERDAY', items: [items[2]] },
        { label: 'Sunday, Sep 27', items: [items[3]] },
      ]);
    });

    it('reads the time from the given key', () => {
      const notes = [{ id: 1, createdAt: toUnix('2026-10-03T10:00:00Z') }];

      expect(groupByDay(notes, 'createdAt', t)[0].items).toEqual(notes);
    });

    it('returns no groups for an empty list', () => {
      expect(groupByDay([], 'timestamp', t)).toEqual([]);
    });
  });
});
