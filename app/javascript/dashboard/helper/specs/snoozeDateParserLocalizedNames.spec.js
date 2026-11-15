import { generateDateSuggestions } from '../snoozeDateParser';
import ptBR from '../../i18n/locale/pt_BR/snooze.json';
import es from '../../i18n/locale/es/snooze.json';

// A Wednesday, so "friday" is two days ahead and "tomorrow" is Thursday.
const now = new Date(2026, 10, 11, 10, 0);

const first = (text, translations, locale) =>
  generateDateSuggestions(text, now, { translations, locale })[0]?.date;

const english = text => first(text, undefined, 'en');

describe('snooze parser with the names people actually type', () => {
  describe('pt-BR', () => {
    const pt = text => first(text, ptBR.SNOOZE_PARSER, 'pt-BR');

    it.each([
      ['sexta-feira 9h', 'friday 9am'],
      ['sexta 9h', 'friday 9am'],
      ['sexta às 9h', 'friday at 9am'],
      ['sexta 9:00', 'friday 9:00'],
      ['sex 9h', 'friday 9am'],
      ['próxima sexta 9h', 'next friday 9am'],
      ['proxima sexta 9h', 'next friday 9am'],
      ['sábado 14h', 'saturday 2pm'],
      ['sabado 14h', 'saturday 2pm'],
      ['20 fev 9h', 'feb 20 9am'],
      // "dez" is both ten and December.
      ['20 dez 9h', 'dec 20 9am'],
      // A word that only starts like a short name is not a misspelled date.
      ['marcar amanhã 9h', 'tomorrow 9am'],
      ['em dez minutos', 'in 10 minutes'],
    ])('reads "%s" as "%s"', (local, en) => {
      expect(english(en)).toBeInstanceOf(Date);
      expect(pt(local)).toEqual(english(en));
    });

    it('labels the match with the words the user typed', () => {
      const [match] = generateDateSuggestions('próxima sexta 9h', now, {
        translations: ptBR.SNOOZE_PARSER,
        locale: 'pt-BR',
      });
      expect(match.label).toBe('próxima sexta 9h');
    });

    it('does not turn a day it cannot read into another date', () => {
      expect(pt('sextaa 9h')).toBeUndefined();
      expect(pt('dezembroo 20 9h')).toBeUndefined();
      expect(pt('sext 9h')).toBeUndefined();
    });
  });

  describe('es', () => {
    const spanish = text => first(text, es.SNOOZE_PARSER, 'es');

    it.each([
      ['viernes 9h', 'friday 9am'],
      ['vie 9h', 'friday 9am'],
      ['sábado 14h', 'saturday 2pm'],
      ['20 dic 9h', 'dec 20 9am'],
      // "mar" is both Tuesday and March; the one that makes a date wins.
      ['20 mar 9h', 'mar 20 9am'],
      ['mar 9h', 'tuesday 9am'],
      ['marcar mañana 9h', 'tomorrow 9am'],
    ])('reads "%s" as "%s"', (local, en) => {
      expect(spanish(local)).toEqual(english(en));
    });
  });

  describe('en', () => {
    it.each([
      ['fri 9am', 'friday 9am'],
      ['next fri 9am', 'next friday 9am'],
    ])('reads "%s" as "%s"', (short, long) => {
      expect(english(short)).toEqual(english(long));
    });
  });
});

describe('snooze month names in a language with another calendar', () => {
  it('reads a Gregorian month name as that month', () => {
    const march = new Intl.DateTimeFormat('fa', {
      calendar: 'gregory',
      month: 'long',
    }).format(new Date(2024, 2, 1));
    const [match] = generateDateSuggestions(`${march} 20 9am`, now, {
      locale: 'fa',
    });
    expect(match?.date.getMonth()).toBe(2);
  });
});
