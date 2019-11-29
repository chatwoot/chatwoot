process.env.VUE_CLI_BABEL_TARGET_NODE = true;
process.env.VUE_CLI_BABEL_TRANSPILE_MODULES = true;

module.exports = {
  moduleDirectories: ['node_modules', 'app/javascript'],
  moduleFileExtensions: ['js', 'jsx', 'json', 'vue', 'ts', 'tsx'],
  automock: false,
  resetMocks: true,
  transform: {
    '^.+\\.vue$': 'vue-jest',
    '.+\\.(css|styl|less|sass|scss|png|jpg|ttf|woff|woff2)$':
      'jest-transform-stub',
    '^.+\\.(js|jsx)?$': 'babel-jest',
  },
  cacheDirectory: '<rootDir>/.jest-cache',
  collectCoverage: false,
  coverageDirectory: 'buildreports',
  collectCoverageFrom: ['**/app/javascript/**/*.js'],
  reporters: ['default'],
  // setupTestFrameworkScriptFile: './tests/setup.ts',
  transformIgnorePatterns: ['node_modules/*'],
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/app/javascript/$1',
  },
  roots: ['<rootDir>/app/javascript'],
  snapshotSerializers: ['jest-serializer-vue'],
  testMatch: [
    '**/app/javascript/**/*.spec.(js|jsx|ts|tsx)|**/__tests__/*.(js|jsx|ts|tsx)',
  ],
  testURL: 'http://localhost/',
};
