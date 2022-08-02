import { shallowMount, createLocalVue } from '@vue/test-utils';
import portalMixin from '../portalMixin';
import Vuex from 'vuex';
import VueRouter from 'vue-router';
const localVue = createLocalVue();
localVue.use(Vuex);
localVue.use(VueRouter);
import ListAllArticles from '../../pages/portals/ListAllPortals.vue';

const router = new VueRouter({
  routes: [
    {
      path: ':portalSlug/:locale/articles',
      name: 'list_all_locale_articles',
      component: ListAllArticles,
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
      router,
    };
    store = new Vuex.Store({ getters });
    wrapper = shallowMount(Component, { store, localVue });
  });

  it('return account id', () => {
    expect(wrapper.vm.accountId).toBe(1);
  });

  it('returns portal url', () => {
    router.push({
      name: 'list_all_locale_articles',
      params: { portalSlug: 'fur-rent', locale: 'en' },
    });
    expect(wrapper.vm.articleUrl(1)).toBe(
      '/app/accounts/1/portals/fur-rent/en/articles/1'
    );
  });

  it('returns portal locale', () => {
    router.push({
      name: 'list_all_locale_articles',
      params: { portalSlug: 'fur-rent', locale: 'es' },
    });
    expect(wrapper.vm.portalSlug).toBe('fur-rent');
  });

  it('returns portal slug', () => {
    router.push({
      name: 'list_all_locale_articles',
      params: { portalSlug: 'campaign', locale: 'es' },
    });
    expect(wrapper.vm.portalSlug).toBe('campaign');
  });
});
