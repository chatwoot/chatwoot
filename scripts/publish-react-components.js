const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

/* eslint-disable no-console */

// Check for copy-only mode
const isCopyMode = process.argv.includes('--copyMode');

if (isCopyMode) {
  console.log('📋 Copy mode: Copying built files to dist/react-components...');
} else {
  console.log('🚀 Building Chatwoot React Components for NPM...');
}

async function publishReactComponents() {
  try {
    if (!isCopyMode) {
      // Step 1: Clean previous builds
      console.log('📦 Cleaning previous builds...');
      if (fs.existsSync('dist')) {
        fs.rmSync('dist', { recursive: true, force: true });
      }

      // Clean previous React component builds
      const reactFiles = [
        'public/packs/react-components.es.js',
        'public/packs/react-components.cjs.js',
        'public/packs/style.css',
      ];

      reactFiles.forEach(file => {
        if (fs.existsSync(file)) {
          fs.unlinkSync(file);
          console.log(`   🗑️  Removed ${file}`);
        }
      });

      // Step 2: Build the React components library
      console.log('🔨 Building React components...');
      execSync('pnpm build:react', { stdio: 'inherit' });
    }

    // Step 3: Create package directory
    console.log('📁 Creating package directory...');
    const packageDir = 'dist/react-components';
    fs.mkdirSync(packageDir, { recursive: true });

    // Step 4: Copy built files
    console.log('📋 Copying built files...');
    copyBuildFiles(packageDir);

    // Step 5: Generate package.json
    console.log('📄 Generating package.json...');
    generatePackageJson(packageDir);

    // Step 6: Copy additional files (README, etc.)
    console.log('📚 Copying documentation...');
    copyDocumentation(packageDir);

    console.log('✅ Package ready in dist/react-components/');
    console.log('');
    console.log('📦 Publishing options:');
    console.log('  • npm publish:     cd dist/react-components && npm publish');
    console.log('  • yalc publish:    pnpm package:react:yalc-publish');
    console.log('  • local test:      cd dist/react-components && npm pack');
  } catch (error) {
    console.error('❌ Build failed:', error.message);
    process.exit(1);
  }
}

function copyBuildFiles(packageDir) {
  // Copy main build outputs
  const files = [
    { src: 'public/packs/react-components.es.js', dest: 'index.js' }, // ES module (main)
    { src: 'public/packs/react-components.cjs.js', dest: 'index.cjs' }, // CommonJS
    { src: 'public/packs/style.css', dest: 'style.css' }, // CSS styles
  ];

  files.forEach(({ src, dest }) => {
    if (fs.existsSync(src)) {
      fs.copyFileSync(src, path.join(packageDir, dest));
      console.log(`   ✓ Copied ${dest}`);
    } else {
      console.warn(`   ⚠️  Warning: ${src} not found`);
    }
  });
}

function generatePackageJson(packageDir) {
  // Read version from main package.json
  const mainPackage = JSON.parse(fs.readFileSync('package.json', 'utf8'));

  // Get current git commit hash for development builds
  function getVersionSuffix() {
    try {
      const gitHash = execSync('git rev-parse --short HEAD', {
        encoding: 'utf8',
        stdio: 'pipe',
      }).trim();

      return `dev.${gitHash}`;
    } catch (error) {
      console.warn('   ⚠️  Could not get git hash, using beta.1');
      return 'beta.1';
    }
  }

  const versionSuffix = getVersionSuffix();
  const finalVersion = `${mainPackage.version}-${versionSuffix}`;

  console.log(
    `   📋 Package version: ${finalVersion} (suffix: ${versionSuffix})`
  );

  const packageJson = {
    name: '@chatwoot/agent-react-components',
    version: finalVersion,
    description:
      'React components for Chatwoot messaging interface with Vue Web Components',

    // Entry points for different module systems
    main: 'index.cjs', // CommonJS entry point for Node.js
    module: 'index.js', // ES module entry point for bundlers
    exports: {
      '.': {
        import: './index.js', // ES modules
        require: './index.cjs', // CommonJS
      },
      './style.css': './style.css',
    },

    // Peer dependencies - what the consuming app must provide
    peerDependencies: {
      react: '>=16.8.0', // Hooks support
      'react-dom': '>=16.8.0',
    },

    // Package metadata
    keywords: [
      'chatwoot',
      'react',
      'vue',
      'webcomponents',
      'chat',
      'messaging',
      'customer-support',
      'ui-components',
    ],
    author: 'Chatwoot',
    license: 'MIT',
    repository: {
      type: 'git',
      url: 'https://github.com/chatwoot/chatwoot.git',
      directory: 'app/javascript/react-components',
    },
    homepage: 'https://chatwoot.com',
    bugs: {
      url: 'https://github.com/chatwoot/chatwoot/issues',
    },

    // npm publish configuration
    files: ['index.js', 'index.cjs', 'style.css', 'README.md', 'package.json'],

    // Engine requirements
    engines: {
      node: '>=16.0.0',
    },
  };

  fs.writeFileSync(
    path.join(packageDir, 'package.json'),
    JSON.stringify(packageJson, null, 2)
  );
  console.log('   ✓ Generated package.json');
}

function copyDocumentation(packageDir) {
  // Create a comprehensive README for the package
  const readme = `# Chatwoot React Components

React components for embedding Chatwoot messaging interface with Vue Web Components under the hood.

## Installation

\`\`\`bash
npm install @chatwoot/agent-react-components
# or
yarn add @chatwoot/agent-react-components
# or
pnpm add @chatwoot/agent-react-components
\`\`\`

## Usage

### Basic MessageList Integration

\`\`\`jsx
import React from 'react';
import { ChatwootProvider, ChatwootConversation } from '@chatwoot/agent-react-components';
import '@chatwoot/agent-react-components/style.css';

function App() {
  return (
    <ChatwootProvider
      baseURL="https://your-chatwoot-instance.com"
      accountId="123"
      conversationId={123}
      userToken="your-auth-token"
      websocketURL="wss://your-chatwoot-instance.com"
      pubsubToken="your-pubsub-token"
    >
      <ChatwootConversation />
    </ChatwootProvider>
  );
}
\`\`\`

## Components

### ChatwootProvider

Root provider component that manages global configuration and initialization.

**Props:**
- \`baseURL\` (string, required): Your Chatwoot instance URL
- \`accountId\` (string|number, required): account identifier
- \`userToken\` (string, required): Authentication token
- \`conversationId\` (number, required): ID of the conversation to display
- \`websocketURL\` (string, optional): WebSocket endpoint, defaults to baseURL/cable
- \`pubsubToken\` (string, optional): PubSub token, defaults to userToken

### ChatwootConversation

Component that renders a specific conversation interface.

### useChatwoot

Hook to access the Chatwoot configuration within a ChatwootProvider.

\`\`\`jsx
import { useChatwoot } from '@chatwoot/agent-react-components';

function MyComponent() {
  const { baseURL, userId, userToken } = useChatwoot();
  // Use configuration as needed
}
\`\`\`
`;

  fs.writeFileSync(path.join(packageDir, 'README.md'), readme);
  console.log('   ✓ Generated README.md');
}

// Run the script
publishReactComponents();
/* eslint-enable no-console */
