import SessionStorage from 'shared/helpers/sessionStorage';

const KEY_PREFIX = 'captainToolCatalogFlow';

const storageKey = (accountId, providerKey) =>
  `${KEY_PREFIX}:${accountId}:${providerKey}`;

export const saveCatalogFlow = flow => {
  SessionStorage.set(storageKey(flow.accountId, flow.providerKey), flow);
};

export const getCatalogFlow = (accountId, providerKey) =>
  SessionStorage.get(storageKey(accountId, providerKey));

export const clearCatalogFlow = (accountId, providerKey) => {
  SessionStorage.remove(storageKey(accountId, providerKey));
};

export const catalogReturnLocation = ({
  accountId,
  providerKey,
  installationId,
}) => {
  const flow = getCatalogFlow(accountId, providerKey);
  if (
    !flow ||
    String(flow.accountId) !== String(accountId) ||
    String(flow.installationId) !== String(installationId)
  ) {
    return null;
  }

  return {
    name: 'captain_tools_catalog_provider',
    params: {
      accountId,
      assistantId: flow.assistantId,
      providerKey,
    },
    query: { installation_id: installationId },
  };
};
