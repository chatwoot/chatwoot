import { h } from 'vue';

export const QuickReplyIcon = {
  name: 'QuickReplyIcon',
  render() {
    return h(
      'svg',
      {
        width: '15',
        height: '15',
        viewBox: '0 0 15 15',
        fill: 'none',
        class: 'stroke-n-blue-11',
        xmlns: 'http://www.w3.org/2000/svg',
      },
      [
        h('path', {
          d: 'M.667 6.654 5.315.667v3.326c7.968 0 8.878 6.46 8.656 10.007l-.005-.027c-.334-1.79-.474-4.658-8.65-4.658v3.327z',
          'stroke-width': '1.333',
          'stroke-linecap': 'round',
          'stroke-linejoin': 'round',
        }),
      ]
    );
  },
};
