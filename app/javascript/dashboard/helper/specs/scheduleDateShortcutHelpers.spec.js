import {
  SHORTCUT_KEYS,
  getTomorrowDate,
  getMondayDate,
  applyHour,
  formatShortDate,
  formatHour,
  getScheduleShortcuts,
  preProcessDateInput,
  parseNaturalDate,
  formatFullDateTime,
} from '../scheduleDateShortcutHelpers';

describe('#scheduleDateShortcutHelpers', () => {
  // Wednesday 2023-06-14
  const wednesday = new Date('2023-06-14T10:30:00');
  // Saturday 2023-06-17
  const saturday = new Date('2023-06-17T10:30:00');
  // Sunday 2023-06-18
  const sunday = new Date('2023-06-18T10:30:00');
  // Monday 2023-06-19
  const monday = new Date('2023-06-19T10:30:00');

  describe('getTomorrowDate', () => {
    it('returns the next day at midnight', () => {
      expect(getTomorrowDate(wednesday)).toEqual(
        new Date('2023-06-15T00:00:00')
      );
    });

    it('returns Monday from Sunday', () => {
      expect(getTomorrowDate(sunday)).toEqual(new Date('2023-06-19T00:00:00'));
    });

    it('returns Sunday from Saturday', () => {
      expect(getTomorrowDate(saturday)).toEqual(
        new Date('2023-06-18T00:00:00')
      );
    });
  });

  describe('getMondayDate', () => {
    it('returns next Monday from a weekday (Wednesday)', () => {
      expect(getMondayDate(wednesday)).toEqual(new Date('2023-06-19T00:00:00'));
    });

    it('returns next Monday from Saturday', () => {
      expect(getMondayDate(saturday)).toEqual(new Date('2023-06-19T00:00:00'));
    });

    it('returns Monday of NEXT week from Sunday (8 days away)', () => {
      // On Sunday, tomorrow is already Monday, so this returns the Monday after
      expect(getMondayDate(sunday)).toEqual(new Date('2023-06-26T00:00:00'));
    });

    it('returns next Monday from Monday (7 days away)', () => {
      expect(getMondayDate(monday)).toEqual(new Date('2023-06-26T00:00:00'));
    });
  });

  describe('applyHour', () => {
    const baseDate = new Date('2023-06-14T00:00:00');

    it('sets 8:00 for hour 8', () => {
      const result = applyHour(baseDate, 8);
      expect(result.getHours()).toBe(8);
      expect(result.getMinutes()).toBe(0);
      expect(result.getSeconds()).toBe(0);
    });

    it('sets 13:00 for hour 13', () => {
      const result = applyHour(baseDate, 13);
      expect(result.getHours()).toBe(13);
      expect(result.getMinutes()).toBe(0);
    });

    it('does not mutate the original date', () => {
      const original = new Date('2023-06-14T00:00:00');
      applyHour(original, 18);
      expect(original.getHours()).toBe(0);
    });
  });

  describe('formatShortDate', () => {
    const date = new Date('2023-03-15T00:00:00');

    it('formats with en locale using month name', () => {
      const result = formatShortDate(date, 'en');
      expect(result).toMatch(/Mar.*15|15.*Mar/i);
    });

    it('handles underscore locale tags like pt_BR', () => {
      expect(() => formatShortDate(date, 'pt_BR')).not.toThrow();
    });

    it('falls back to en for empty locale', () => {
      expect(() => formatShortDate(date, '')).not.toThrow();
    });
  });

  describe('formatHour', () => {
    it('formats 8 for en locale with AM', () => {
      const result = formatHour(8, 'en');
      expect(result).toMatch(/8.*AM/i);
    });

    it('formats 13 for en locale with PM', () => {
      const result = formatHour(13, 'en');
      expect(result).toMatch(/1.*PM/i);
    });

    it('handles underscore locale tags', () => {
      expect(() => formatHour(18, 'pt_BR')).not.toThrow();
    });
  });

  describe('preProcessDateInput', () => {
    it('converts PT hour format "8h" to "8:00"', () => {
      expect(preProcessDateInput('amanhã às 8h')).toBe('amanhã às 8:00');
    });

    it('converts PT hour+min format "14h30" to "14:30"', () => {
      expect(preProcessDateInput('amanhã às 14h30')).toBe('amanhã às 14:30');
    });

    it('converts PT "de manhã" to "8:00"', () => {
      expect(preProcessDateInput('amanhã de manhã')).toBe('amanhã 8:00');
    });

    it('converts PT "à tarde" to "13:00"', () => {
      expect(preProcessDateInput('amanhã à tarde')).toBe('amanhã 13:00');
    });

    it('converts PT "de noite" to "18:00"', () => {
      expect(preProcessDateInput('amanhã de noite')).toBe('amanhã 18:00');
    });

    it('normalizes "amanha" without accent to "amanhã"', () => {
      expect(preProcessDateInput('amanha as 8h')).toBe('amanhã às 8:00');
    });

    it('normalizes "as" to "às" before digits', () => {
      expect(preProcessDateInput('amanhã as 19h')).toBe('amanhã às 19:00');
    });

    it('normalizes "as" to "às" before time-of-day words', () => {
      expect(preProcessDateInput('amanhã as manha')).toBe('amanhã 8:00');
    });

    it('normalizes "sabado" to "sábado"', () => {
      expect(preProcessDateInput('sabado as 10h')).toContain('sábado');
    });

    it('normalizes "proxima" to "próxima"', () => {
      expect(preProcessDateInput('proxima segunda')).toContain('próxima');
    });

    it('converts "pela manhã" to "8:00"', () => {
      expect(preProcessDateInput('amanhã pela manhã')).toBe('amanhã 8:00');
    });

    it('converts "pela tarde" to "13:00"', () => {
      expect(preProcessDateInput('amanhã pela tarde')).toBe('amanhã 13:00');
    });

    it('converts "no período da noite" to "18:00"', () => {
      expect(preProcessDateInput('amanhã no período da noite')).toBe(
        'amanhã 18:00'
      );
    });

    it('leaves EN text with explicit times unchanged', () => {
      expect(preProcessDateInput('tomorrow at 2pm')).toBe('tomorrow at 2pm');
    });

    it('inserts "às" between PT weekday and bare number', () => {
      expect(preProcessDateInput('quarta 10')).toBe('quarta às 10');
    });

    it('inserts "às" between PT weekday and am/pm time', () => {
      expect(preProcessDateInput('sexta 2pm')).toBe('sexta às 2pm');
    });

    it('inserts "às" between PT weekday-feira and number', () => {
      expect(preProcessDateInput('quarta-feira 14h')).toBe(
        'quarta-feira às 14:00'
      );
    });

    it('does not double-insert "às" when already present', () => {
      expect(preProcessDateInput('quarta às 10')).toBe('quarta às 10');
    });
  });

  describe('parseNaturalDate', () => {
    const now = new Date('2023-06-14T10:00:00');

    it('returns null for empty string', () => {
      expect(parseNaturalDate('', 'en', now)).toBeNull();
    });

    it('returns null for whitespace-only string', () => {
      expect(parseNaturalDate('   ', 'en', now)).toBeNull();
    });

    it('parses EN "tomorrow at 8am"', () => {
      const result = parseNaturalDate('tomorrow at 8am', 'en', now);
      expect(result).toBeInstanceOf(Date);
      expect(result.getDate()).toBe(15);
      expect(result.getHours()).toBe(8);
    });

    it('parses EN "tomorrow at 1pm"', () => {
      const result = parseNaturalDate('tomorrow at 1pm', 'en', now);
      expect(result).toBeInstanceOf(Date);
      expect(result.getHours()).toBe(13);
    });

    it('parses PT "amanhã às 8h" via preprocessing', () => {
      const result = parseNaturalDate('amanhã às 8h', 'pt_BR', now);
      expect(result).toBeInstanceOf(Date);
      expect(result.getDate()).toBe(15);
      expect(result.getHours()).toBe(8);
    });

    it('parses PT "amanhã à tarde" via preprocessing', () => {
      const result = parseNaturalDate('amanhã à tarde', 'pt_BR', now);
      expect(result).toBeInstanceOf(Date);
      expect(result.getDate()).toBe(15);
      expect(result.getHours()).toBe(13);
    });

    it('parses PT "amanha as 19h" (no accents) via preprocessing', () => {
      const result = parseNaturalDate('amanha as 19h', 'pt_BR', now);
      expect(result).toBeInstanceOf(Date);
      expect(result.getDate()).toBe(15);
      expect(result.getHours()).toBe(19);
    });

    it('parses PT "amanhã pela manhã" via preprocessing', () => {
      const result = parseNaturalDate('amanhã pela manhã', 'pt_BR', now);
      expect(result).toBeInstanceOf(Date);
      expect(result.getDate()).toBe(15);
      expect(result.getHours()).toBe(8);
    });

    it('parses weekday names forward (not past) — PT "sexta"', () => {
      // now is Wednesday Jun 14; "sexta" should be upcoming Friday Jun 16
      const result = parseNaturalDate('sexta', 'pt_BR', now);
      expect(result).toBeInstanceOf(Date);
      expect(result.getDate()).toBe(16);
    });

    it('parses weekday names forward (not past) — EN "friday"', () => {
      const result = parseNaturalDate('friday', 'en', now);
      expect(result).toBeInstanceOf(Date);
      expect(result.getDate()).toBe(16);
    });

    it('returns null for unrecognizable input', () => {
      expect(parseNaturalDate('xyz abc', 'en', now)).toBeNull();
    });
  });

  describe('formatFullDateTime', () => {
    const date = new Date('2023-03-17T08:00:00');

    it('formats in EN locale', () => {
      const result = formatFullDateTime(date, 'en');
      expect(result).toMatch(/Mar.*17.*2023.*8.*00/i);
    });

    it('handles pt_BR locale without errors', () => {
      expect(() => formatFullDateTime(date, 'pt_BR')).not.toThrow();
    });
  });

  describe('getScheduleShortcuts', () => {
    it('returns 3 shortcuts on a normal weekday', () => {
      const shortcuts = getScheduleShortcuts(wednesday);
      expect(shortcuts).toHaveLength(3);
    });

    it('returns correct keys', () => {
      const shortcuts = getScheduleShortcuts(wednesday);
      const keys = shortcuts.map(s => s.key);
      expect(keys).toEqual([
        SHORTCUT_KEYS.TOMORROW_MORNING,
        SHORTCUT_KEYS.TOMORROW_AFTERNOON,
        SHORTCUT_KEYS.MONDAY_MORNING,
      ]);
    });

    it('computes correct dates for Wednesday', () => {
      const shortcuts = getScheduleShortcuts(wednesday);
      // Tomorrow = Thursday 2023-06-15
      expect(shortcuts[0].dateTime).toEqual(new Date('2023-06-15T08:00:00'));
      expect(shortcuts[1].dateTime).toEqual(new Date('2023-06-15T13:00:00'));
      // Monday = 2023-06-19
      expect(shortcuts[2].dateTime).toEqual(new Date('2023-06-19T08:00:00'));
    });

    it('on Sunday: tomorrow is Monday, Monday shortcut is next weeks Monday', () => {
      const shortcuts = getScheduleShortcuts(sunday);
      // Tomorrow = Monday 2023-06-19
      expect(shortcuts[0].dateTime).toEqual(new Date('2023-06-19T08:00:00'));
      expect(shortcuts[1].dateTime).toEqual(new Date('2023-06-19T13:00:00'));
      // Monday = next week's Monday 2023-06-26
      expect(shortcuts[2].dateTime).toEqual(new Date('2023-06-26T08:00:00'));
    });

    it('on Saturday: tomorrow is Sunday, Monday is the day after', () => {
      const shortcuts = getScheduleShortcuts(saturday);
      // Tomorrow = Sunday 2023-06-18
      expect(shortcuts[0].dateTime).toEqual(new Date('2023-06-18T08:00:00'));
      expect(shortcuts[1].dateTime).toEqual(new Date('2023-06-18T13:00:00'));
      // Monday = 2023-06-19
      expect(shortcuts[2].dateTime).toEqual(new Date('2023-06-19T08:00:00'));
    });

    it('on Monday: tomorrow is Tuesday, Monday shortcut is next Monday', () => {
      const shortcuts = getScheduleShortcuts(monday);
      // Tomorrow = Tuesday 2023-06-20
      expect(shortcuts[0].dateTime).toEqual(new Date('2023-06-20T08:00:00'));
      expect(shortcuts[1].dateTime).toEqual(new Date('2023-06-20T13:00:00'));
      // Monday = 2023-06-26
      expect(shortcuts[2].dateTime).toEqual(new Date('2023-06-26T08:00:00'));
    });

    it('includes formatted date and time', () => {
      const shortcuts = getScheduleShortcuts(wednesday, 'en');
      shortcuts.forEach(s => {
        expect(s.formattedDate).toBeTruthy();
        expect(s.formattedTime).toBeTruthy();
      });
    });

    it('handles pt_BR locale', () => {
      expect(() => getScheduleShortcuts(wednesday, 'pt_BR')).not.toThrow();
    });

    it('filters out shortcuts that are in the past', () => {
      // Late Wednesday night — tomorrow morning 08:00 is still in the future
      const lateWednesday = new Date('2023-06-14T23:59:00');
      const shortcuts = getScheduleShortcuts(lateWednesday);
      expect(shortcuts.length).toBeGreaterThanOrEqual(2);
      shortcuts.forEach(s => {
        expect(s.dateTime.getTime()).toBeGreaterThan(lateWednesday.getTime());
      });
    });
  });
});
