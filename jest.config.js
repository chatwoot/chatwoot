process.env.VUE_CLI_BABEL_TARGET_NODE = 'true';
process.env.VUE_CLI_BABEL_TRANSPILE_MODULES = 'true';

module.exports = {
  moduleDirectories: ['node_modules', 'app/javascript'],
  moduleFileExtensions: ['js', 'jsx', 'json', 'vue', 'ts', 'tsx'],
  automock: false,
  resetMocks: true,
  transform: {
    '^.+\\.vue$': '@vue/vue2-jest',
    '.+\\.(css|styl|less|sass|scss|png|jpg|ttf|woff|woff2)$':
      'jest-transform-stub',
    '^.+\\.(js|jsx)?$': 'babel-jest',
  },
  cacheDirectory: '<rootDir>/.jest-cache',
  collectCoverage: true,
  coverageDirectory: 'coverage',
  coverageReporters: ['text', 'lcov'],
  collectCoverageFrom: [
    '**/app/javascript/**/*.js',
    '!**/*.stories.js',
    '!**/i18n/locale/**/*.js',
  ],
  reporters: ['default'],
  transformIgnorePatterns: ['node_modules/*'],
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/app/javascript/$1',
    '\\.(jpg|jpeg|png|gif|eot|otf|webp|svg|ttf|woff|woff2|mp4|webm|wav|mp3|m4a|aac|oga)$':
      '<rootDir>/__mocks__/fileMock.js',
  },
  roots: ['<rootDir>/app/javascript'],
  snapshotSerializers: ['jest-serializer-vue'],
  testMatch: [
    '**/app/javascript/**/*.spec.(js|jsx|ts|tsx)|**/__tests__/*.(js|jsx|ts|tsx)',
  ],
  testEnvironmentOptions: {
    url: 'http://localhost/',
  },
  globals: {
    'vue-jest': {
      templateCompiler: {
        prettify: false,
      },
    },
  },
  globalSetup: './jest.setup.js',
  testEnvironment: 'jsdom',
  setupFiles: ['fake-indexeddb/auto'],
};
