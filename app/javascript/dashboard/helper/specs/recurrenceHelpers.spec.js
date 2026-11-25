import { createI18n } from 'vue-i18n';
import en from '../../i18n/fazer-ai/locale/en/scheduledMessages.json';
import ptBR from '../../i18n/fazer-ai/locale/pt_BR/scheduledMessages.json';
import es from '../../i18n/fazer-ai/locale/es/scheduledMessages.json';
import { bindDateLocale } from 'shared/helpers/localizedDate';
import {
  buildRecurrenceDescription,
  formatShortcutLabel,
} from '../recurrenceHelpers';

const i18n = createI18n({
  legacy: false,
  locale: 'en',
  messages: { en, pt_BR: ptBR, es },
});
bindDateLocale(i18n);

const describeIn = (locale, rule) => {
  i18n.global.locale.value = locale;
  return buildRecurrenceDescription(rule, i18n.global.t, locale);
};

const monthlyFirstFriday = {
  frequency: 'monthly',
  interval: 1,
  monthly_type: 'day_of_week',
  monthly_week: 1,
  monthly_weekday: 5,
  end_type: 'on_date',
  end_date: '2026-12-20',
};

const weeklyMonWed = { frequency: 'weekly', interval: 1, week_days: [3, 1] };

describe('recurrence descriptions', () => {
  it('keeps English as it was, with a readable end date', () => {
    expect(describeIn('en', weeklyMonWed)).toContain('Mon, Wed');
    expect(describeIn('en', monthlyFirstFriday)).toBe(
      'Monthly on the first Friday · until Dec 20, 2026'
    );
  });

  it('names days, ordinals and the end date in Portuguese', () => {
    expect(describeIn('pt_BR', weeklyMonWed)).toContain('seg, qua');
    const text = describeIn('pt_BR', monthlyFirstFriday);
    expect(text).toContain('1º sexta-feira');
    expect(text).toContain('20 de dez. de 2026');
  });

  it('names days, ordinals and the end date in Spanish, not English', () => {
    expect(describeIn('es', weeklyMonWed)).toContain('lun, mié');
    const text = describeIn('es', monthlyFirstFriday);
    expect(text).toContain('primer viernes');
    expect(text).toContain('20 dic 2026');
    expect(text).not.toMatch(/first|Friday|2026-12-20/);
  });

  it('labels the yearly shortcut with the month in the language shown', () => {
    i18n.global.locale.value = 'es';
    const label = formatShortcutLabel(
      { label: 'YEARLY', labelParams: { month: 11, dayNum: 20 } },
      i18n.global.t,
      'es'
    );
    expect(label).toBe('Cada año el 20 de diciembre');
  });
});

describe('recurrence names in a language with another calendar', () => {
  it('names the Gregorian month that the day number belongs to', () => {
    const month = formatShortcutLabel(
      { label: 'YEARLY', labelParams: { month: 0, dayNum: 1 } },
      (key, params) => params.month,
      'fa'
    );
    // Persian's own calendar would call early January "دی" (Dey).
    expect(month).not.toBe('دی');
    expect(month).toBe(
      new Intl.DateTimeFormat('fa', {
        calendar: 'gregory',
        month: 'long',
      }).format(new Date(2024, 0, 1))
    );
  });
});
