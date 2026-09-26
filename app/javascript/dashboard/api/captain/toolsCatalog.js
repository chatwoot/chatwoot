// Uses fetch instead of the axios client so the user's auth headers are never sent to the catalog host
const fetchCatalogJson = async (url, { signal } = {}) => {
  const response = await fetch(url, { signal, credentials: 'omit' });
  if (!response.ok) {
    throw new Error(`Could not load the tools catalog: ${response.status}`);
  }
  return response.json();
};

export const fetchToolsCatalog = (baseUrl, options) => {
  if (!baseUrl) throw new Error('The tools catalog URL is not configured');

  return fetchCatalogJson(`${baseUrl.replace(/\/+$/, '')}.json`, options);
};

// The catalog list links each toolset to its details, which carry the readme and tools
export const fetchToolsetDetails = (detailUrl, options) =>
  fetchCatalogJson(detailUrl, options);

// GitHub owners are case-insensitive, so Chatwoot/... and chatwoot/... are the same org
export const isVerifiedOwner = owner => owner?.toLowerCase() === 'chatwoot';
