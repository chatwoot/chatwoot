/* eslint-disable global-require */
const plugins = () => [
  require('babel-plugin-macros'),
  [
    '@babel/plugin-proposal-class-properties',
    {
      loose: true,
    },
  ],
  [require('babel-plugin-transform-vue-jsx')],
  [
    '@babel/plugin-transform-runtime',
    {
      helpers: false,
      regenerator: true,
      corejs: false,
    },
  ],
  ['@babel/plugin-proposal-private-property-in-object', { loose: true }],
  ['@babel/plugin-proposal-private-methods', { loose: true }],
];

module.exports = api => {
  const validEnv = ['development', 'test', 'production'];
  const currentEnv = api.env();

  if (!validEnv.includes(currentEnv)) {
    throw new Error(
      `${'Please specify a valid `NODE_ENV` or ' +
        '`BABEL_ENV` environment variables. Valid values are "development", ' +
        '"test", and "production". Instead, received: '}${JSON.stringify(
        currentEnv
      )}.`
    );
  }

  return {
    presets: [
      ['@babel/preset-env', { useBuiltIns: 'usage', corejs: 3, loose: true }],
    ],
    plugins: plugins(),
  };
};
