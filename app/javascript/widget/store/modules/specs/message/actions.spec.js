import { API } from 'widget/helpers/axios';
import { actions } from '../../message';

const commit = vi.fn();
vi.mock('widget/helpers/axios');

describe('#actions', () => {
  describe('#update', () => {
    it('sends correct actions', async () => {
      const user = {
        email: 'admin@example.com',
        messageId: 10,
        submittedValues: {
          email: 'admin@example.com',
        },
      };
      API.patch.mockResolvedValue({
        data: { contact: { pubsub_token: '8npuMUfDgizrwVoqcK1t7FMY' } },
      });
      await actions.update(
        {
          commit,
          getters: {
            getUIFlags: {
              isUpdating: false,
            },
          },
        },
        user
      );
      expect(commit.mock.calls).toEqual([
        ['toggleUpdateStatus', true],
        [
          'conversation/updateMessage',
          {
            id: 10,
            content_attributes: {
              submitted_email: 'admin@example.com',
              submitted_values: null,
            },
          },
          { root: true },
        ],
        ['toggleUpdateStatus', false],
      ]);
    });

    it('blocks all new action calls when isUpdating', async () => {
      await actions.update(
        {
          commit,
          getters: {
            getUIFlags: {
              isUpdating: true,
            },
          },
        },
        {}
      );

      expect(commit.mock.calls).toEqual([]);
    });
  });
});
