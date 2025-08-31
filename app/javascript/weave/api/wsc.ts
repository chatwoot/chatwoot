export type FeatureMap = Record<string, boolean>;

export async function getAccountFeatures(accountId: number) {
  const { data } = await (window as any).axios.get(`/wsc/api/accounts/${accountId}/features`);
  return data as { account_id: number; plan: string; features: FeatureMap };
}

export async function updateAccountFeatures(accountId: number, features: FeatureMap) {
  const { data } = await (window as any).axios.patch(`/wsc/api/accounts/${accountId}/features`, {
    features,
  });
  return data as { account_id: number; plan: string; features: FeatureMap };
}

