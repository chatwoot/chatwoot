import axios from 'axios';
import { throwErrorMessage } from '../api';
import Contacts from '../../modules/contacts';
import { actions as campaignActions } from '../../modules/campaigns';
import { actions as attributeActions } from '../../modules/attributes';
import conversationActions from '../../modules/conversations/actions';

// The dashboard builds its error toast from the request's answer (requestErrorMessage). A store
// that rethrows without it leaves every caller with "try again later", even for a 422.
const commit = vi.fn();
global.axios = axios;
vi.mock('axios');

const answer = {
  status: 422,
  data: {
    message: 'Email has already been taken',
    attributes: ['email'],
    details: { email: [{ error: 'taken' }] },
  },
};
const rejection = () =>
  Object.assign(new Error('Request failed'), { response: answer });

const rejected = async promise => {
  try {
    await promise;
  } catch (error) {
    return error;
  }
  throw new Error('expected a rejection');
};

describe('errors rethrown by the stores keep the answer', () => {
  it('throwErrorMessage, used by the store factory', () => {
    let thrown;
    try {
      throwErrorMessage(rejection());
    } catch (error) {
      thrown = error;
    }
    expect(thrown.message).toBe('Email has already been taken');
    expect(thrown.response).toBe(answer);
  });

  it.each([
    ['contacts/update', () => Contacts.actions.update({ commit }, { id: 1 })],
    ['contacts/create', () => Contacts.actions.create({ commit }, {})],
  ])('%s', async (_, run) => {
    axios.patch.mockRejectedValue(rejection());
    axios.post.mockRejectedValue(rejection());
    expect((await rejected(run())).response).toBe(answer);
  });

  it.each([
    [
      'contacts/deleteCustomAttributes',
      () =>
        Contacts.actions.deleteCustomAttributes(
          { commit },
          { id: 1, customAttributes: ['plan'] }
        ),
    ],
    [
      'contacts/merge',
      () => Contacts.actions.merge({ commit }, { childId: 1, parentId: 2 }),
    ],
    ['campaigns/create', () => campaignActions.create({ commit }, {})],
    ['campaigns/update', () => campaignActions.update({ commit }, { id: 1 })],
    ['campaigns/delete', () => campaignActions.delete({ commit }, 1)],
    ['attributes/delete', () => attributeActions.delete({ commit }, 1)],
    [
      'updateCustomAttributes',
      () =>
        conversationActions.updateCustomAttributes(
          { commit },
          { conversationId: 1, customAttributes: {} }
        ),
    ],
  ])('%s', async (_, run) => {
    axios.post.mockRejectedValue(rejection());
    axios.patch.mockRejectedValue(rejection());
    axios.delete.mockRejectedValue(rejection());
    expect((await rejected(run())).response).toBe(answer);
  });
});
