import { defineConfig } from 'vite'
import fs from 'node:fs'
import { globbySync } from 'globby'

export default defineConfig({
  plugins: [
    {
      name: 'histoire:preserve:import.dynamic',
      enforce: 'pre',
      transform (code) {
        if (code.includes('import(')) {
          return {
            code: code.replace(/import\(/g, 'import__dyn('),
          }
        }
      },
      closeBundle () {
        try {
          const files = globbySync('./dist/**/*.js')
          for (const file of files) {
            const content = fs.readFileSync(file, 'utf-8')
            if (content.includes('import__dyn')) {
              fs.writeFileSync(file, content.replace(/import__dyn\(/g, 'import(/* @vite-ignore */'), 'utf-8')
            }
          }
        } catch (e) {
          console.error(e)
        }
      },
    },
  ],

  build: {
    emptyOutDir: false,
    outDir: 'dist/bundled',
    lib: {
      entry: '',
      formats: ['es'],
    },
    rollupOptions: {
      external: [
        /\$histoire/,
        /@histoire/,
        'vue',
      ],

      input: [
        'src/client/client.ts',
        'src/client/server.ts',
      ],

      output: {
        // manualChunks (id) {
        //   if (id.includes('node_modules')) {
        //     return 'vendor'
        //   }
        // },
        entryFileNames: '[name].js',
        chunkFileNames: '[name].js',
        assetFileNames: '[name][extname]',
        // hoistTransitiveImports: false,
        preserveModules: true,
        preserveModulesRoot: 'src',
      },
      treeshake: false,
      preserveEntrySignatures: 'strict',
    },
  },
})
