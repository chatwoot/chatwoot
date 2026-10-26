import { shallowMount } from '@vue/test-utils';
import VueDOMPurifyHTML from 'vue-dompurify-html';
import { domPurifyConfig } from 'shared/helpers/HTMLSanitizer';
import CopilotAssistantMessage from '../CopilotAssistantMessage.vue';

const { push } = vi.hoisted(() => ({ push: vi.fn() }));
vi.mock('vue-router', () => ({
  useRoute: () => ({ params: { accountId: '1' } }),
  useRouter: () => ({ push }),
}));
vi.mock('dashboard/composables', () => ({
  useTrack: () => {},
}));

const mountMessage = () =>
  shallowMount(CopilotAssistantMessage, {
    props: {
      message: {
        content:
          '| Conversation | Finding |\n| --- | --- |\n| [#42](/app/accounts/1/conversations/42) | Needs attention |\n\n[Source](https://example.com)',
      },
    },
    global: { plugins: [[VueDOMPurifyHTML, domPurifyConfig]] },
  });

describe('CopilotAssistantMessage conversation links', () => {
  it('opens a sanitized table link in the current dashboard', () => {
    const wrapper = mountMessage();
    const link = wrapper.get('td a');
    expect(link.attributes('href')).toBe('/app/accounts/1/conversations/42');
    expect(link.attributes('target')).toBe('_blank');

    const click = new MouseEvent('click', { bubbles: true, cancelable: true });
    link.element.dispatchEvent(click);

    expect(click.defaultPrevented).toBe(true);
    expect(push).toHaveBeenCalledWith('/app/accounts/1/conversations/42');
    wrapper.unmount();
  });

  it('preserves external links and modified clicks', () => {
    const wrapper = mountMessage();
    const external = new MouseEvent('click', {
      bubbles: true,
      cancelable: true,
    });
    wrapper
      .get('a[href="https://example.com"]')
      .element.dispatchEvent(external);
    const modified = new MouseEvent('click', {
      bubbles: true,
      cancelable: true,
      metaKey: true,
    });
    wrapper.get('td a').element.dispatchEvent(modified);

    expect(external.defaultPrevented).toBe(false);
    expect(modified.defaultPrevented).toBe(false);
    expect(push).not.toHaveBeenCalled();
    wrapper.unmount();
  });
});
