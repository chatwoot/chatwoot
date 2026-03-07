import { mount } from '@vue/test-utils';
import { describe, expect, it, vi } from 'vitest';
import CannedResponse from '../CannedResponse.vue';

describe('CannedResponse.vue', () => {
  it('emits plain text metadata with selected canned response content', async () => {
    const wrapper = mount(CannedResponse, {
      props: {
        searchKey: '',
      },
      global: {
        stubs: {
          MentionBox: true,
        },
        mocks: {
          $store: {
            dispatch: vi.fn(),
            getters: {
              getCannedResponses: [
                {
                  short_code: 'test-format-check',
                  content: 'Первая строка\n\n- пункт один',
                  content_format: 'plain_text',
                },
              ],
            },
          },
        },
      },
    });

    wrapper.vm.handleMentionClick({
      description: 'Первая строка\n\n- пункт один',
      format: 'plain_text',
    });

    expect(wrapper.emitted('replace')).toEqual([
      [{ text: 'Первая строка\n\n- пункт один', format: 'plain_text' }],
    ]);
  });
});
