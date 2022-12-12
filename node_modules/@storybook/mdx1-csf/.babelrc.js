const ignore = process.env.IGNORE_FILES ? ['**/*.test.ts', '**/*.d.ts'] : [];

module.exports = {
  presets: [
    ['@babel/preset-env', { targets: { node: 'current' } }],
    '@babel/preset-typescript',
    '@babel/preset-react',
  ],
  env: {
    esm: {
      presets: [
        [
          '@babel/preset-env',
          {
            modules: false,
            targets: { node: 'current' },
          },
        ],
      ],
    },
  },
  ignore,
};
