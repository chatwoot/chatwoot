import { describe, it, expect, beforeEach, vi } from 'vitest';
import { mount, flushPromises } from '@vue/test-utils';
import ReopenTeamAssigneeToggle from '../ReopenTeamAssigneeToggle.vue';

const mockDispatch = vi.fn();
vi.mock('vuex', () => ({ useStore: () => ({ dispatch: mockDispatch }) }));

vi.mock('vue-i18n', async () => {
  const actual = await vi.importActual('vue-i18n');
  return { ...actual, useI18n: () => ({ t: key => key }) };
});

const mockAlert = vi.fn();
vi.mock('dashboard/composables', () => ({
  useAlert: (...args) => mockAlert(...args),
}));

const mountToggle = inbox =>
  mount(ReopenTeamAssigneeToggle, {
    props: { inbox },
    global: { mocks: { $t: key => key } },
  });

const toggle = wrapper => wrapper.find('button[role="switch"]');

describe('ReopenTeamAssigneeToggle', () => {
  beforeEach(() => vi.clearAllMocks());

  it('shows the saved setting', () => {
    const on = mountToggle({
      id: 1,
      drop_assignee_outside_team_on_reopen: true,
    });
    const off = mountToggle({
      id: 1,
      drop_assignee_outside_team_on_reopen: false,
    });

    expect(toggle(on).attributes('aria-checked')).toBe('true');
    expect(toggle(off).attributes('aria-checked')).toBe('false');
  });

  it('saves the setting as a boolean', async () => {
    const wrapper = mountToggle({
      id: 1,
      drop_assignee_outside_team_on_reopen: false,
    });

    await toggle(wrapper).trigger('click');
    await flushPromises();

    expect(mockDispatch).toHaveBeenCalledWith('inboxes/updateInbox', {
      id: 1,
      formData: false,
      drop_assignee_outside_team_on_reopen: true,
    });
    expect(mockAlert).toHaveBeenCalledWith(
      'INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'
    );
  });

  it('goes back to the saved setting when the server refuses the change', async () => {
    mockDispatch.mockRejectedValueOnce(new Error('422'));
    const wrapper = mountToggle({
      id: 1,
      drop_assignee_outside_team_on_reopen: false,
    });

    await toggle(wrapper).trigger('click');
    await flushPromises();

    expect(toggle(wrapper).attributes('aria-checked')).toBe('false');
    expect(mockAlert).toHaveBeenCalledWith('INBOX_MGMT.EDIT.API.ERROR_MESSAGE');
  });

  it('follows the inbox when another one is loaded', async () => {
    const wrapper = mountToggle({
      id: 1,
      drop_assignee_outside_team_on_reopen: false,
    });

    await wrapper.setProps({
      inbox: { id: 2, drop_assignee_outside_team_on_reopen: true },
    });

    expect(toggle(wrapper).attributes('aria-checked')).toBe('true');
  });
});
