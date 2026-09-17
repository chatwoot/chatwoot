import { formatBinding } from './formatBinding';

describe('formatBinding', () => {
  it('renders the current source contract without persistence details', () => {
    expect(
      formatBinding({ type: 'closure', source: '(lambda (x . rest) x)' })
    ).toBe('(lambda (x . rest) x)');
  });

  it('still renders saved traces from the previous runtime', () => {
    expect(
      formatBinding({
        type: 'closure',
        parameters: [{ type: 'symbol', value: 'x' }],
        body: [{ type: 'symbol', value: 'x' }],
      })
    ).toBe('(lambda (x) x)');
  });
});
