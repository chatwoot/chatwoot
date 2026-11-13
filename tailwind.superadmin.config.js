// The super admin stylesheet is built from its own files only; the shared theme comes from the root config.
const base = require('./tailwind.config');

module.exports = {
  ...base,
  content: [
    './app/views/layouts/super_admin/**/*.erb',
    './app/views/super_admin/**/*.erb',
    './app/views/fields/**/*.erb',
    './app/views/installation/**/*.erb',
    './enterprise/app/views/super_admin/**/*.erb',
    './enterprise/app/views/fields/**/*.erb',
    './app/helpers/super_admin/*.{rb,yml}',
    './app/javascript/entrypoints/superadmin.js',
    './app/javascript/superadmin_pages/**/*.{vue,js}',
    './app/javascript/shared/components/charts/BarChart.vue',
  ],
};
