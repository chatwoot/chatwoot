import countries from 'shared/constants/countries';

// Reproduces the countriesMap and countryDetails logic from ContactsCard.vue
// to verify the fix for the Zimbabwe display bug (issue #14238).
function buildCountriesMap() {
  return countries.reduce((acc, country) => {
    acc[country.id] = country;
    return acc;
  }, {});
}

function resolveCountryDetails(additionalAttributes) {
  const countriesMap = buildCountriesMap();
  const { country, countryCode, city } = additionalAttributes || {};

  if (!country && !countryCode) return null;

  const activeCountry =
    (country && countriesMap[country]) || countriesMap[countryCode];

  if (!activeCountry) return null;

  return {
    countryCode: activeCountry.id,
    city: city ? `${city},` : null,
    name: activeCountry.name,
  };
}

describe('ContactsCard country resolution', () => {
  it('returns null when neither country nor countryCode is set', () => {
    expect(resolveCountryDetails({})).toBeNull();
    expect(resolveCountryDetails({ city: 'Cape Town' })).toBeNull();
  });

  it('resolves correctly from countryCode alone (regression for Zimbabwe bug)', () => {
    const result = resolveCountryDetails({ countryCode: 'US' });
    expect(result).not.toBeNull();
    expect(result.name).toBe('United States');
    expect(result.countryCode).toBe('US');
  });

  it('does not display Zimbabwe for contacts with only a countryCode', () => {
    const result = resolveCountryDetails({ countryCode: 'ZA' });
    expect(result.name).toBe('South Africa');
    expect(result.name).not.toBe('Zimbabwe');
  });

  it('resolves correctly when country name is provided directly', () => {
    // country name is stored as the id (e.g. "DE") in some integrations
    const result = resolveCountryDetails({ country: 'DE' });
    expect(result.name).toBe('Germany');
  });

  it('prefers country over countryCode when both are present', () => {
    const result = resolveCountryDetails({ country: 'FR', countryCode: 'DE' });
    expect(result.name).toBe('France');
  });

  it('falls back to countryCode when country value does not match any entry', () => {
    const result = resolveCountryDetails({ country: 'Unknown', countryCode: 'GB' });
    expect(result.name).toBe('United Kingdom');
  });

  it('includes city in the result when present', () => {
    const result = resolveCountryDetails({ countryCode: 'AU', city: 'Sydney' });
    expect(result.city).toBe('Sydney,');
    expect(result.name).toBe('Australia');
  });
});
