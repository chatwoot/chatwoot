import { describe, it, expect, beforeEach, vi } from 'vitest';
import { mount, flushPromises } from '@vue/test-utils';
import ReopenOwnerSetting from '../ReopenOwnerSetting.vue';

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

const mountSetting = inbox =>
  mount(ReopenOwnerSetting, {
    props: { inbox },
    global: { mocks: { $t: key => key } },
  });

const select = wrapper => wrapper.find('select');
const hoursInput = wrapper => wrapper.find('input[type="number"]');
const saveButton = wrapper => wrapper.find('button');

describe('ReopenOwnerSetting', () => {
  beforeEach(() => vi.clearAllMocks());

  it('shows the saved mode, and the hours only for the window', () => {
    const bot = mountSetting({ id: 1, reopen_owner: 'agent_bot' });
    const window = mountSetting({
      id: 1,
      reopen_owner: 'assignee_within_window',
      reopen_owner_window_hours: 6,
    });

    expect(select(bot).element.value).toBe('agent_bot');
    expect(hoursInput(bot).exists()).toBe(false);
    expect(select(window).element.value).toBe('assignee_within_window');
    expect(hoursInput(window).element.value).toBe('6');
  });

  it('saves a mode without hours', async () => {
    const wrapper = mountSetting({ id: 1, reopen_owner: 'agent_bot' });

    await select(wrapper).setValue('assignee');
    await saveButton(wrapper).trigger('click');
    await flushPromises();

    expect(mockDispatch).toHaveBeenCalledWith('inboxes/updateInbox', {
      id: 1,
      formData: false,
      reopen_owner: 'assignee',
    });
  });

  it('saves the window with its hours as a number', async () => {
    const wrapper = mountSetting({ id: 1, reopen_owner: 'agent_bot' });

    await select(wrapper).setValue('assignee_within_window');
    await hoursInput(wrapper).setValue('4');
    await saveButton(wrapper).trigger('click');
    await flushPromises();

    expect(mockDispatch).toHaveBeenCalledWith('inboxes/updateInbox', {
      id: 1,
      formData: false,
      reopen_owner: 'assignee_within_window',
      reopen_owner_window_hours: 4,
    });
  });

  it('does not save a window without a valid number of hours', async () => {
    const wrapper = mountSetting({ id: 1, reopen_owner: 'agent_bot' });

    await select(wrapper).setValue('assignee_within_window');
    await ['', '0', '-1', '1.5', '8761'].reduce(async (previous, value) => {
      await previous;
      await hoursInput(wrapper).setValue(value);
      expect(saveButton(wrapper).attributes('disabled')).toBeDefined();
    }, Promise.resolve());
    await saveButton(wrapper).trigger('click');

    expect(mockDispatch).not.toHaveBeenCalled();
    expect(wrapper.text()).toContain(
      'INBOX_MGMT.ASSIGNMENT.REOPEN_OWNER.HOURS_ERROR'
    );
  });

  it('shows the help, not the error, while the hours are still empty', async () => {
    const wrapper = mountSetting({ id: 1, reopen_owner: 'agent_bot' });

    await select(wrapper).setValue('assignee_within_window');

    expect(wrapper.text()).toContain(
      'INBOX_MGMT.ASSIGNMENT.REOPEN_OWNER.HOURS_HELP'
    );
    expect(wrapper.text()).not.toContain(
      'INBOX_MGMT.ASSIGNMENT.REOPEN_OWNER.HOURS_ERROR'
    );
    expect(saveButton(wrapper).attributes('disabled')).toBeDefined();
  });

  it('goes back to the saved setting when the server refuses the change', async () => {
    mockDispatch.mockRejectedValueOnce(new Error('422'));
    const wrapper = mountSetting({ id: 1, reopen_owner: 'agent_bot' });

    await select(wrapper).setValue('assignee');
    await saveButton(wrapper).trigger('click');
    await flushPromises();

    expect(select(wrapper).element.value).toBe('agent_bot');
    expect(mockAlert).toHaveBeenCalledWith('INBOX_MGMT.EDIT.API.ERROR_MESSAGE');
  });
});
