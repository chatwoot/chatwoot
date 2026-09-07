export const fetchToolsetCatalog = async (url, { signal } = {}) => {
  const response = await fetch(url, { signal, credentials: 'omit' });
  if (!response.ok) {
    throw new Error(`Could not fetch toolset catalog: ${response.status}`);
  }
  return response.json();
};
