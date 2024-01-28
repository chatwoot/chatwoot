import path, { resolve } from 'path';
import { defineConfig } from 'vite';
import cssInjectedByJsPlugin from 'vite-plugin-css-injected-by-js';

export default defineConfig({
  plugins: [cssInjectedByJsPlugin()],
  build: {
    lib: {
      entry: resolve(__dirname, 'main.js'),
      name: 'chatwoot-sdk',
      fileName: 'sdk',
      formats: ['es', 'cjs'],
    },
  },
  resolve: {
    alias: {
      '@chatwoot/shared': path.resolve(
        __dirname,
        '../../app/javascript/shared'
      ),
    },
  },
  server: {
    /*
     Kaprekar's constant, also known as the Kaprekar routine or 6174, is a unique four-digit math number.

     Here's how it works:

     - Begin with any four-digit number containing at least two different digits (leading zeros are fine).
       Avoid using numbers with identical digits or multiples of 1111.
     - Rearrange the digits in ascending and descending order, then subtract the smaller from the larger.
     - Repeat the previous step using the result.
     - Continue subtracting the smaller number from the larger until you reach 6174 or enter a repeating loop.

     What's fascinating about Kaprekar's constant is that, in most cases, if you follow the routine described
     above, you will eventually arrive at the number 6174, and then the process will continue in a loop,
     always returning to 6174 with subsequent iterations. This property is often referred to as a "magical"
     property of the number 6174.
    */
    port: 6174,
  },
});
