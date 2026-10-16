import { picoSearch } from '@chatwoot/pico-search';
import {
  removeAccents,
  searchIgnoringAccents,
  indexOfIgnoringAccents,
} from '../searchHelper';

describe('removeAccents', () => {
  it('strips accents', () => {
    expect(removeAccents('Olá, ação, Ñandú, Tiếng Việt')).toBe(
      'Ola, acao, Nandu, Tieng Viet'
    );
  });

  it('keeps every character at its index', () => {
    ['안녕하세요 order', 'नमस्ते किताब', 'İstanbul 🎉'].forEach(text => {
      expect(removeAccents(text)).toHaveLength(text.length);
    });
  });
});

describe('searchIgnoringAccents', () => {
  const records = [
    { id: 1, name: 'Olá, tudo bem?' },
    { id: 2, name: 'Hola' },
    { id: 3, name: 'Refund', email: null },
  ];

  it('matches with or without accents', () => {
    expect(searchIgnoringAccents(records, 'ola', ['name'])).toEqual([
      records[0],
      records[1],
    ]);
    expect(searchIgnoringAccents(records, 'olá', ['name'])).toEqual([
      records[0],
      records[1],
    ]);
  });

  it('returns the original records, not folded copies', () => {
    expect(searchIgnoringAccents(records, 'ola', ['name'])[0]).toBe(records[0]);
  });

  it('takes the same keys as picoSearch, including weights and non-string fields', () => {
    const responses = [
      { id: 1, code: 'olá', body: 'thanks' },
      { id: 2, code: 'thanks', body: 'olá' },
    ];

    const idsFor = keys =>
      searchIgnoringAccents(responses, 'ola', keys).map(({ id }) => id);

    expect(idsFor(['code', 'body'])).toEqual([1, 2]);
    expect(idsFor(['code', { name: 'body', weight: 4 }])).toEqual([2]);
    expect(searchIgnoringAccents(records, 'refund', ['name', 'email'])).toEqual(
      [records[2]]
    );
  });

  it('returns what picoSearch returns when nothing has accents', () => {
    const plain = [
      { name: 'Hola' },
      { name: 'Solar' },
      { name: 'Collaboration' },
      { name: 'Refund' },
    ];

    expect(searchIgnoringAccents(plain, 'ola', ['name'])).toEqual(
      picoSearch(plain, 'ola', ['name'])
    );
  });
});

describe('indexOfIgnoringAccents', () => {
  it('finds the term ignoring accents and case', () => {
    expect(indexOfIgnoringAccents('Obrigado! Olá', 'ola')).toBe(10);
    expect(indexOfIgnoringAccents('Hola', 'OLÁ')).toBe(1);
    expect(indexOfIgnoringAccents('Refund', 'ola')).toBe(-1);
  });
});
