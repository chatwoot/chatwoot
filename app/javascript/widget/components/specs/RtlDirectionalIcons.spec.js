import { mount, shallowMount } from '@vue/test-utils';
import { createStore } from 'vuex';
import FluentIcon from 'shared/components/FluentIcon/Index.vue';
import CustomerSatisfaction from 'shared/components/CustomerSatisfaction.vue';
import ChatHeader from '../ChatHeader.vue';
import ChatSendButton from '../ChatSendButton.vue';
import EmailInput from '../template/EmailInput.vue';
import ArticleListItem from '../pageComponents/Home/Article/ArticleListItem.vue';

vi.mock('vue-router', () => ({
  useRouter: () => ({ replace: vi.fn() }),
}));

const store = createStore({
  modules: {
    appConfig: {
      namespaced: true,
      getters: { getWidgetColor: () => '#1f93ff' },
    },
  },
});

describe('widget directional icons in RTL', () => {
  it('mirrors the header back chevron', () => {
    const wrapper = shallowMount(ChatHeader, {
      props: { showBackButton: true },
    });

    expect(wrapper.findComponent(FluentIcon).classes()).toContain(
      'rtl:rotate-180'
    );
  });

  it('mirrors the composer send icon', () => {
    const wrapper = shallowMount(ChatSendButton);

    expect(wrapper.findComponent(FluentIcon).classes()).toContain(
      'rtl:-scale-x-100'
    );
  });

  it('mirrors the CSAT submit chevron', () => {
    const wrapper = shallowMount(CustomerSatisfaction, {
      props: { messageId: 1 },
      global: {
        plugins: [store],
        directives: {
          dompurifyHtml: (element, binding) => {
            element.textContent = binding.value;
          },
        },
      },
    });

    expect(wrapper.findComponent(FluentIcon).classes()).toContain(
      'rtl:rotate-180'
    );
  });

  it('mirrors the email input submit chevron', () => {
    const wrapper = shallowMount(EmailInput, {
      props: { messageId: 1 },
      global: { plugins: [store] },
    });

    expect(wrapper.findComponent(FluentIcon).classes()).toContain(
      'rtl:rotate-180'
    );
  });

  it('mirrors the article list item chevron', () => {
    const wrapper = mount(ArticleListItem, {
      props: { title: 'Article', link: '/article' },
    });

    expect(wrapper.find('.i-lucide-chevron-right').classes()).toContain(
      'rtl:rotate-180'
    );
  });
});
