import { API } from 'widget/helpers/axios';
import { actions } from '../../message';

const commit = jest.fn();
jest.mock('widget/helpers/axios');

describe('#actions', () => {
  describe('#update', () => {
    it('sends correct actions', async () => {
      const user = {
        email: 'john@acme.inc',
        messageId: 10,
        submittedValues: {
          email: 'john@acme.inc',
        },
      };
      API.patch.mockResolvedValue({
        data: { contact: { pubsub_token: '8npuMUfDgizrwVoqcK1t7FMY' } },
      });
      await actions.update({ commit }, user);
      expect(commit.mock.calls).toEqual([
        ['toggleUpdateStatus', true],
        [
          'conversation/updateMessage',
          {
            id: 10,
            content_attributes: {
              submitted_email: 'john@acme.inc',
              submitted_values: null,
            },
          },
          { root: true },
        ],
        ['toggleUpdateStatus', false],
      ]);
    });
  });
});
