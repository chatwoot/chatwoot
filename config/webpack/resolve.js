const path = require('path');

const resolve = {
  extensions: ['.js', '.vue'],
  alias: {
    vue$: 'vue/dist/vue.common.js',
    dashboard: path.resolve('./app/javascript/dashboard'),
    widget: path.resolve('./app/javascript/widget'),
    assets: path.resolve('./app/javascript/dashboard/assets'),
    components: path.resolve('./app/javascript/dashboard/components'),
  },
};

module.exports = resolve;
