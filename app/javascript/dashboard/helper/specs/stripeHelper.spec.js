import { formatStripeAmount } from '../stripeHelper';

describe('formatStripeAmount', () => {
  it('preserves fractional minor units for subscription prices', () => {
    expect(formatStripeAmount('0.05', 'USD', { preservePrecision: true })).toBe(
      '$0.0005'
    );
    expect(
      formatStripeAmount('0.000000000001', 'USD', { preservePrecision: true })
    ).toBe('$0.00000000000001');
  });

  it('keeps standard invoice precision and trims insignificant price zeros', () => {
    expect(formatStripeAmount(1000, 'USD')).toBe('$10.00');
    expect(
      formatStripeAmount('1000.00', 'USD', { preservePrecision: true })
    ).toBe('$10.00');
  });

  it('uses two-decimal API units for UGX', () => {
    expect(formatStripeAmount(5000, 'UGX')).toBe(
      new Intl.NumberFormat(undefined, {
        style: 'currency',
        currency: 'UGX',
        minimumFractionDigits: 2,
        maximumFractionDigits: 2,
      }).format(50)
    );
  });
});
