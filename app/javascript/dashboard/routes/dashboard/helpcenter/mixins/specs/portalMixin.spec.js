import { shallowMount } from '@vue/test-utils';
import { createStore } from 'vuex';
import { createRouter, createWebHistory } from 'vue-router';
import portalMixin from '../portalMixin';

// Create a dummy component
const DummyComponent = { template: '<div>Dummy Component</div>' };

// Create router instance
const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: '/',
      name: 'home',
      component: DummyComponent,
    },
    {
      path: '/:portalSlug/:locale/articles',
      name: 'list_all_locale_articles',
      component: DummyComponent,
    },
  ],
});

describe('portalMixin', () => {
  let getters;
  let store;
  let wrapper;

  beforeEach(() => {
    getters = {
      getCurrentAccountId: () => 1,
    };
    const Component = {
      render() {},
      title: 'TestComponent',
      mixins: [portalMixin],
    };
    store = createStore({ getters });
    wrapper = shallowMount(Component, {
      global: {
        plugins: [store, router],
      },
    });
    router.push('/');
  });

  it('returns account id', () => {
    expect(wrapper.vm.accountId).toBe(1);
  });

  it('returns article url', async () => {
    await router.push({
      name: 'list_all_locale_articles',
      params: { portalSlug: 'fur-rent', locale: 'en' },
    });
    expect(wrapper.vm.articleUrl(1)).toBe(
      '/app/accounts/1/portals/fur-rent/en/articles/1'
    );
  });

  it('returns portal locale', async () => {
    await router.push({
      name: 'list_all_locale_articles',
      params: { portalSlug: 'fur-rent', locale: 'es' },
    });
    expect(wrapper.vm.portalSlug).toBe('fur-rent');
  });

  it('returns portal slug', async () => {
    await router.push({
      name: 'list_all_locale_articles',
      params: { portalSlug: 'campaign', locale: 'es' },
    });
    expect(wrapper.vm.portalSlug).toBe('campaign');
  });

  it('returns locale name', async () => {
    await router.push({
      name: 'list_all_locale_articles',
      params: { portalSlug: 'fur-rent', locale: 'es' },
    });
    expect(wrapper.vm.localeName('es')).toBe('Spanish');
  });
});
