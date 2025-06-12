# Chatwoot React Components

This module exports Chatwoot UI components as React components that can be embedded in other applications. It uses a hybrid approach combining Vue Web Components with React wrappers.

## Architecture

The system works by:
1. **Vue Components** → Compiled as custom web components using Vue's `customElement: true`
2. **React Wrappers** → Provide React-friendly interfaces to the Vue web components
3. **Vite Build** → Packages everything into distributable ES/CJS modules

## Build System

### Build Modes (vite.config.ts)
- **`BUILD_MODE=react-components`** - Builds React components library
- Entry point: `./app/javascript/react-components/src/index.jsx`
- Output: ES modules (`react-components.es.js`) and CommonJS (`react-components.cjs.js`)
- External dependencies: `react` and `react-dom` (peer dependencies)

### Available Scripts (package.json)
```bash
# Build the React components once
pnpm build:react

# Build and watch for changes during development
pnpm dev:react

# Package for NPM distribution (builds + creates dist/react-components/)
pnpm package:react
```


## Usage

In any React app, version 16+, you could use the following snippet

```jsx
import * as ChatwootComponents from '@chatwoot/agent-react-components';
import '@chatwoot/agent-react-components/style.css'

const { ChatwootProvider, ChatwootConversation } = ChatwootComponents;

function App() {
  return (
    <ChatwootProvider
      baseURL="http://localhost:3000"
      accountId="1"
      conversationId={13918}
      userToken="XLwgvCQiewUJMGuYpZqa4J3M"
      pubsubToken="HkAhoq8aWm2ecdY2tn9FV4BU"
      websocketURL="ws://localhost:3000"
    >
      <ChatwootConversation/>
    </ChatwootProvider>
  )
}

export default App
```

The `<ChatwootProvider>` component ensures all the data necessary for mounting the web component is present before rendering the ChatwootConversation.

The package also exposes a `useChatwoot` hook for accessing the config instance being used by the conversation, it can be used as a read-only source of truth for the config being used.

## Development Workflow

To test this package, you can create a separate React application where you can use the snippet from above, run the following command in your Rails App:

```bash
pnpm dev:react
```

This will start a development server that serves the React components and their dependencies.

Following this, in a separate terminal, run the following command

```bash
watchexec --restart -N --watch public/packs/react-components.es.js "pnpm package:react --copyMode"
```

This will ensure that the built files are copied correctly to the dist/react-components folder.

The `package:react` script has a copy mode, which just copies the build from the `public/` folder to the dist folder for linking purposes. It also creates a package.json file with proper entry points, ensure you run the script without copyMode once before.

Once done, in your React app, you can use `pnpm link <rails-app-dir>/dist/react-components` to link the package. Running the development server will automatically link the package and any changes to it.

## Publishing

The `scripts/package-react-components.js` handles:
- Building the components with Vite
- Copying built files to `dist/react-components/`
- Generating `package.json` with proper entry points
- Creating development versions with git hash suffixes

Once the script is packaged, you can run `npm publish` to publish the package. It will be published as `@chatwoot/agent-react-components` with a version that is the latest commit hash
