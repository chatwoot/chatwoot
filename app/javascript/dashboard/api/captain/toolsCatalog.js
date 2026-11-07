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

// Matches a catalog toolset to its installed tools. Installs lowercase the owner and repository but keep the folder's case.
export const installedToolsetKey = source => {
  const [owner, repository, ...folder] = source.split('/');
  return `${owner}/${repository}`.toLowerCase() + `/${folder.join('/')}`;
};

// Every catalog toolset lives in chatwoot/tools; the author is who wrote it. GitHub logins are case-insensitive
export const isChatwootAuthor = author => author?.toLowerCase() === 'chatwoot';
