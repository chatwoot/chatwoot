module.exports = {
  '*.ts': [
    'eslint --fix',
    'prettier --write',
    () => 'pnpm type-check',
  ],
  '*.{json,md,yml,yaml}': ['prettier --write'],
};
