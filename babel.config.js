/* eslint-disable global-require */

module.exports = api => {
  const validEnv = ['development', 'test', 'production'];
  const currentEnv = api.env();
  const isDevelopmentEnv = api.env('development');
  const isProductionEnv = api.env('production');
  const isTestEnv = api.env('test');

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
      isTestEnv && [
        require('@babel/preset-env').default,
        {
          targets: {
            node: 'current',
          },
        },
      ],
      (isProductionEnv || isDevelopmentEnv) && [
        require('@babel/preset-env').default,
        {
          forceAllTransforms: true,
          useBuiltIns: 'entry',
          corejs: 3,
          modules: false,
          exclude: ['transform-typeof-symbol'],
        },
      ],
    ].filter(Boolean),
    plugins: [
      require('babel-plugin-macros'),
      require('@babel/plugin-syntax-dynamic-import').default,
      isTestEnv && require('babel-plugin-dynamic-import-node'),
      require('@babel/plugin-transform-destructuring').default,
      [
        require('@babel/plugin-proposal-class-properties').default,
        {
          loose: true,
        },
      ],
      [
        require('@babel/plugin-proposal-object-rest-spread').default,
        {
          useBuiltIns: true,
        },
      ],
      [
        require('@babel/plugin-transform-runtime').default,
        {
          helpers: false,
          regenerator: true,
          corejs: false,
        },
      ],
      [
        require('@babel/plugin-transform-regenerator').default,
        {
          async: false,
        },
      ],
      [require('babel-plugin-transform-vue-jsx')],
    ].filter(Boolean),
  };
};
