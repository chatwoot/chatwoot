import { once } from '@storybook/client-logger';
import './manager';

once.warn(
  'register.js is deprecated see https://github.com/storybookjs/storybook/blob/next/MIGRATION.md#deprecated-registerjs'
);
