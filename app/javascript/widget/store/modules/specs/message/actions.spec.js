import { API } from 'widget/helpers/axios';
import { actions } from '../../message';

const commit = vi.fn();
const dispatch = vi.fn();
vi.mock('widget/helpers/axios');

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
      await actions.update(
        {
          commit,
          dispatch,
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
              submitted_email: 'john@acme.inc',
              submitted_values: null,
            },
          },
          { root: true },
        ],
        ['toggleUpdateStatus', false],
      ]);
    });

    it('rethrows API errors and resets the updating flag', async () => {
      const error = { response: { status: 422 } };
      API.patch.mockRejectedValue(error);
      commit.mockClear();

      await expect(
        actions.update(
          {
            commit,
            getters: {
              getUIFlags: {
                isUpdating: false,
              },
            },
          },
          { messageId: 10, submittedValues: { csat_survey_response: {} } }
        )
      ).rejects.toBe(error);

      expect(commit.mock.calls).toEqual([
        ['toggleUpdateStatus', true],
        ['toggleUpdateStatus', false],
      ]);
      commit.mockClear();
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
