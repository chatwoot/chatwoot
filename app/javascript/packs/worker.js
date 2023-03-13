import { DataManager } from '../worker/data-manager';

onmessage = async payload => {
  const { event, params, accountId } = payload.data;

  if (!accountId) {
    throw new Error(`Account ID is not defined`);
  }

  const dataManager = new DataManager(accountId);

  dataManager[event](params).then(result => {
    postMessage({ result });
  });
};
