import { mount, flushPromises } from '@vue/test-utils';
import { createRouter, createMemoryHistory } from 'vue-router';
import SummaryReportLink from '../SummaryReportLink.vue';

describe('SummaryReportLink', () => {
  it.each(['team', 'agent', 'inbox', 'label'])(
    'preserves the current query when opening a %s report',
    async type => {
      const router = createRouter({
        history: createMemoryHistory(),
        routes: [
          { path: '/accounts/:accountId/reports', component: {} },
          {
            path: `/accounts/:accountId/reports/${type}/:id`,
            name: `${type}_reports_show`,
            component: {},
          },
        ],
      });
      const query = {
        from: '1786147200',
        to: '1788739199',
        range: 'last30days',
        business_hours: 'true',
        group_by: '2',
        unrelated: 'keep',
      };
      await router.push({ path: '/accounts/1/reports', query });
      const wrapper = mount(SummaryReportLink, {
        props: { row: { original: { id: 7, name: 'Support', type } } },
        global: { plugins: [router] },
      });

      await wrapper.get('a').trigger('click');
      await flushPromises();

      expect(router.currentRoute.value).toMatchObject({
        name: `${type}_reports_show`,
        params: { accountId: '1', id: '7' },
        query,
      });
      wrapper.unmount();
    }
  );
});
