import 'chart.js';
import { createApp, h } from 'vue';
import VueDOMPurifyHTML from 'vue-dompurify-html';

import PlaygroundIndex from '../superadmin_pages/views/playground/Index.vue';
import DashboardIndex from '../superadmin_pages/views/dashboard/Index.vue';

import * as Sentry from '@sentry/vue';

const ComponentMapping = {
  PlaygroundIndex: PlaygroundIndex,
  DashboardIndex: DashboardIndex,
};

const renderComponent = (componentName, props) => {
  const app = createApp({
    data() {
      return { props: props };
    },
    render() {
      return h(ComponentMapping[componentName], { componentData: this.props });
    },
  });

  Sentry.init({
    app,
    dsn: 'https://db65c8821fe1ce0f7315a1d36895cc5d@o4509088540262400.ingest.de.sentry.io/4510198682615888',
    sendDefaultPii: true,
    tracesSampleRate: 0.2,
    ignoreErrors: [
      'ResizeObserver loop completed with undelivered notifications',
    ],
  });

  app.use(VueDOMPurifyHTML);
  app.mount('#app');
};

document.addEventListener('DOMContentLoaded', () => {
  const element = document.getElementById('app');
  if (element) {
    const componentName = element.dataset.componentName;
    const props = JSON.parse(element.dataset.props);
    renderComponent(componentName, props);
  }
});
