
# Using TypeScript Project References with ts-loader and webpack

Project References were added to TypeScript in 3.0. The benefits of using project references include:

* Better code organisation
* Logical separation between components
* Faster build times

If you are using TypeScript in your web project you can also use project references to improve your code and build workflow. This article describes some of the ways to set up your project to use references. I am using ts-loader to transpile the TypeScript code to JavaScript and webpack to bundle code.

An example repo using the configuration above is available at the link below:

[https://github.com/appzuka/project-references-example](https://github.com/appzuka/project-references-example)

There are 2 stages to using project references in your project:

1. Configure and build the project references
1. Setup your codebase to consume the compiled projects

To gain an understanding of how project references work, for the first part of this guide we will use <code>tsc</code> to build the project references.  Later on, we will configure ts-loader to do this automatically.

### Configure and build the project references

This stage just involves following the directions from the TypeScript documentation:
[https://www.typescriptlang.org/docs/handbook/project-references.html](https://www.typescriptlang.org/docs/handbook/project-references.html)

There are a few points to note:

1. Referenced projects must have the new composite setting enabled.
1. Each referenced project has its own <code>tsconfig.json</code>
1. There will be a root level <code>tsconfig.json</code> which includes the lower level projects as references. Building this will build all subprojects.
1. You should be using configuration file inheritance (<code>{ “extends”: …}</code>) to avoid duplication in your config.
1. You need to use <code>tsc --build</code> to compile the project.
1. When you compile the project <code>tsc --build</code> will create a file called tsconfig.tsbuildinfo that contains the signatures and timestamps of all files required to build the project. On subsequent builds TypeScript will use that information to detect the least costly way to type-check and emit changes to your project.
1. There is no need to use the incremental compiler option. <code>tsc --build</code> will generate and use tsconfig.tsbuildinfo anyway.
1. If you delete your compiled code and re-run <code>tsc --build</code> the code will **not **be rebuilt unless you also delete the <code>tsconfig.tsbuildinfo</code> file. Use the <code>tsc --build --clean</code> command to do this for you.

1. If you set the <code>declaration</code> and <code>declarationMap</code> settings in <code>tsconfig.json</code> the <code>outDir</code> folder will contain <code>.d.ts</code> and <code>.d.ts.map</code> files alongside the transpiled JavaScript. When you consume the compiled project you should consume the <code>outDir</code> folder, not the <code>src</code>. Even though your root project is in TypeScript it can use full syntax checking without the subproject’s TypeScript source because the <code>outDir</code> folder contains the definitions in the <code>.d.ts</code> file. Vscode (and many other code editors and IDEs) will be able to find the definitions and perform syntax checking in the editor just as if you were not using project references and importing the TypeScript source directly.

### Project Structure

The TypeScript implementation of project references allows you to structure the project in almost any way you wish. Just configure the input and output folders in tsconfig.json to your needs and TypeScript will build it for you.

For a web project you might like a structure similar to the one below. You could put all your project references in a packages folder with the top-level project code in src:
```
    tsconfig.json
    tsconfig-base.json
    src
     - (source code for the main project)
    dist
     - main.js (final bundle produced by webpack)
    packages
     - reference1
       - tsconfig.json (inherits from tsconfig-base.json)
       - src
       - lib
     - reference2
       - tsconfig.json (inherits from tsconfig-base.json)
       - src
       - lib
```
Each project reference has its own <code>tsconfig.json</code> with the source code for each package in a <code>src</code> subfolder. When the project is built the compiled JavaScript for each project will be in its <code>lib</code> subfolder.

The source code for your main project is in a top-level <code>src</code> folder and the final bundle will be in a top-level <code>dist</code> folder. The top-level <code>src</code> folder is not a referenced project — it is normal TypeScript source that webpack will bundle. It imports from the <code>lib</code> folders of the referenced projects built by <code>tsc</code>.

This structure works well because:

* Having packages grouped together under a packages folder organises your codebase nicely.
* Other tools such as yarn workspaces and lerna use and understand this organisation.
* Each package is fully self-contained in its own folder. It contains the source, compiled code, tsconfig.json and (optionally) its own <code>package.json</code> which describes how the package is used.
* You can drop the package into another project, import it with a simple statement and everything will be linked up.

This is just one way to structure your project. Some other options include:

* Not putting the projects references in a packages folder. They could all be at the top level, or a different folder, or nested folders.
* The output folder of each project does not have to be in a lib folder of that project. You could have a top-level lib folder which contains the output of all projects.

Almost any structure is compatible with project references. You have freedom to specify the paths of the referenced projects and their outputs in the <code>tsconfig.json</code> files. You will import the compiled JavaScript files into the main project and some structures make this easier than others, but you have the freedom to choose what works for you.

### Test Build your Projects

You should now check that the building of the projects is successful and produces the code you expect.

In each project reference folder execute <code>tsc --build</code>, check there are no errors and the output is as you expect. Use <code>tsc --build --clean</code> to remove the output and repeat. You can use <code>tsc --build --verbose</code> to see what <code>tsc</code> is doing.

If you have a top-level <code>tsconfig.json</code> similar to:
```
    {
      "files": ["src/index.ts"],
      "references": [
        { "path": "./reference1" },
        { "path": "./reference2" }
      ]
    }
```
Then executing <code>tsc --build</code> in the top-level will compile all of your subprojects with one command. The build process is smart and can manage dependencies between subprojects.

In the final step of this guide we will get ts-loader to do the build automatically when called from webpack, but for now, just make sure that the build process works when using <code>tsc --build</code> manually.

### Setup your codebase to consume the project

Now your subprojects are built you can use them in your root project. Let’s say your reference1 project exports a number:
```
    // packages/reference1/src/index.ts

    export const Meaning = 42;
```
After building the reference with <code>tsc --build</code> the compiled JavaScript will be found in <code>packages/reference1/lib/index.js</code>. In your root project you need to import this. There are several ways you can do this. Let’s start with a naive approach that will work but has severe downsides:
```
    // src/index.ts

    // Don't do this!
    import { Meaning } from '../packages/reference1/lib';
```
This will work because TypeScript and webpack will both find the file. The downsides are:

* The organisation of your root project and components are now intertwined. If you change the internal structure of your subproject you will need to update every import statement in the entire project.

* The import location will depend on the location on the source file. For example, if you want to do the same import from a subfolder in your root project you will need to replace <code>../packages/reference1/lib</code> with <code>../../packages/reference1/lib</code>. If you re-organise your project structure you will need to fix every import.

The solution to this is module resolution — how TypeScript and webpack resolve the targets of import statements. You can read about this at the links below:

* [https://www.typescriptlang.org/docs/handbook/module-resolution.html](https://www.typescriptlang.org/docs/handbook/module-resolution.html)
* [https://webpack.js.org/concepts/module-resolution](https://webpack.js.org/concepts/module-resolution)

Module resolution is nothing new and it is not part of project references, but understanding it will be a huge help getting everything working. Some points to note:

* TypeScript and webpack can use different methods to resolve modules. It will help if you can set them up so they are using the same method. (See the example below using alias in webpack and/or tsconfig-paths-webpack-plugin.)
* Resolution works differently for relative (<code>./reference1</code>) and absolute (<code>reference1</code>) imports.
* TypeScript has 2 strategies for module resolution: <code>classic</code> and <code>node</code>. You probably want to use <code>node</code>.
* You can use a webpack plugin <code>tsconfig-paths-webpack-plugin</code> so that you just need to define paths in your <code>tsconfig.json</code> and then don’t need to repeat these in your webpack config.

Using the example above, we would like to just import from <code>packages/reference</code> and have TypeScript and webpack both know that this refers to the actual location.
```
    // src/index.ts

    // Better!
    import { Meaning } from 'packages/reference1/lib';
```
We can achieve this using the paths configuration in <code>tsconfig.json</code> (or better, in <code>tsconfig-base.json</code> so the settings are made once and inherited by all projects):
```
    {
      "compilerOptions": {
        "baseUrl": ".", // This must be specified if "paths" is.
        "paths": {
          "packages/*": ["packages/*"]
        }
      }
    }
```
Now TypeScript understands that when it sees <code>packages/reference1</code> in an import statement, it should look in <code>./packages/reference1</code>. The path is relative to the root <code>tsconfig.json</code> so it does not matter where the source file which imports this is located.

Unless you are using tsconfig-paths-webpack-plugin you may need to include a corresponding resolve-alias setting in your <code>webpack.config.js</code>:
```
    const path = require('path');
    
    module.exports = {
      modules: [
        "node_modules",
        path.resolve(__dirname)
      ],
      resolve: {
        alias: {
          packages: path.resolve(__dirname, 'packages/'),
        }
      }
    };
```
(In this case the <code>path.resolve(__dirname)</code> in the modules section accomplishes the same thing, but depending on your project structure you may need an alias.)

If you are getting module not found errors when you build, knowing whether these are coming from TypeScript or webpack will help you to resolve the issue.

Errors which come from TypeScript when you build the project look similar to the following:
```
    ERROR in ...project-references-demo/src/index.tsx
    ./src/index.tsx
    [tsl] ERROR in ...project-references-demo/src/index.tsx(1,27)
          TS2307: Cannot find module 'mypackages/zoo' or its corresponding type declarations.
```
Note the <code>[tsl]</code> in the message and also the TypeScript error code <code>TS2307</code>. This indicates that the error was passed to webpack by ts-loader when it tried to transpile the file. You can also check whether errors are coming from TypeScript by building your project manually with <code>tsc</code> and checking whether it reports errors.

Errors from webpack look similar to the following:
```
    ERROR in ./src/index.tsx
    Module not found: Error: Can't resolve 'mypackages/zoo' in '...project-references-demo/src'
     @ ./src/index.tsx 6:12-37
```
If you just get these errors it indicates that <code>tsconfig.json</code> is correctly configured and TypeScript is able to resolve your modules, but webpack is not. Look into the resolve section of <code>webpack.config.js</code> and check whether you need to add an alias.

You can use module resolution to make your project work with project references even if your structure is very different from that outlined here. As long as webpack and TypeScript can find the built code it will work.

### Can you import the TypeScript Source instead of the JavaScript?

You can import the TypeScript source from your projects, but you probably should not. If you do set up your project to import the TypeScript, webpack will bundle your project just fine, but then you are not using project references. You have succeeded in organising your codebase but you are not getting the advantage of reducing build time by using the compiled files in <code>lib</code>. In fact, you are slowing down your build by requiring tsc or ts-loader to build the reference and then not using it.

If your project is large you could see a significant benefit from pre-building large sections of code. If your project is not so large you may prefer to just structure your codebase and skip project references.

### Using ts-loader to build project references

Up to this point, we ran <code>tsc --build</code> on its own and then used webpack and ts-loader to build the whole project, importing the references. You can configure ts-loader to build the references for you, which simplifies the build process.

The top-level project in <code>src</code> is TypeScript code, so you will already be using ts-loader to load the TypeScript source into webpack. Just add <code>projectReferences: true</code> to the ts-loader configuration and you no longer need to run <code>tsc</code> in a separate process:
```
    // webpack.config.js

    "module": {
      "rules": [
        {
          "test": /\.tsx?$/,
          "exclude": /node_modules/,
          "use": {
            "loader": "ts-loader",
            "options": {
              "projectReferences": true
            }
          }
        }
      ]
    }
```
When webpack uses ts-loader to process a TypeScript file ts-loader will now check whether any of your project references need rebuilding and rebuild them before webpack proceeds if necessary. This includes when webpack is in watch mode as used by webpack-dev-server.

Setting <code>projectReferences: true</code> in ts-loader alone will not magically convert your code to use project references. All it does is to run <code>tsc --build</code> as part of the build process. You need to configure project references and structure your project to use them as described here.

If you have come this far congratulations — you are now using TypeScript project references in your web project. You can stop here, but in the next section of this guide there are some tips to clean up the project further and create a library of reusable, version-controlled components.

### Using package.json

We can clean this up further by including a <code>package.json</code> in the project reference subfolder. If this contains the following:
```
    //packages/reference1/package.json

    {
      "name": "reference1",
      "version": "1.0.0",
      "description": "Project Reference1",
      "main": "lib/index.js",
      "directories": {
        "lib": "lib"
      },
      "license": "ISC"
    }
```
then you can just import as follows:
```
    // src/index.ts

    import { Meaning } from 'packages/reference1';
```
The module setting in <code>package.json</code> tells the bundler to import from <code>lib/index.js</code> when it sees the import statement above.

### Using node_modules

In the above approach we need to add paths to <code>tsconfig.json</code> so that the module resolution knows where to find our package. But the module resolution system automatically looks in <code>node_modules</code>, so if we link our reference in <code>node_modules</code> we won’t need the paths and aliases:
```
    ln -s ../packages/reference1 node_modules/reference1
    node_modules/reference1 -> packages/reference1
```
It probably makes sense to use npm scopes:
```
    ln -f ../../packages/reference1 node_modules/@myscope/reference1
    node_modules/@myscope/reference1 -> packages/reference1
````
then you can consume the code with:
```
    // src/index.ts

    import { Meaning } from '@myscope/reference1';
```
So you benefit from not having to configure paths and aliases, but you need to create the links in node_modules after cloning the project, unless you use Yarn workspaces.

### Using Yarn Workspaces

If you use yarn workspaces the <code>node_modules</code> links will automatically be created for you when you execute <code>yarn install</code>. Simply include the following in your root level <code>package.json</code>:
``
    {
      "private": true,
      "workspaces": ["packages/*"]
    }
``
In the subproject’s <code>package.json</code> you should use the name of the package you want to be linked in node_modules:
```
    //packages/reference1/package.json

    {
      "name": "@myscope/reference1",
      "version": "1.0.0",
      "module": "lib/index.js
    }
```
When you run yarn install the links in <code>node_modules</code> will be created for you.

You can now use your project references anywhere in your codebase with a simple import statement, exactly like you import npm modules. If you have a more complex application, for example with client and server applications, you can share modules easily.

### Building a Component Library

A common problem in code organisation is how to re-use code in multiple projects. Project references help toward this goal by providing a logical separation between components. This will mean you can drop a component into another project and use it. But there is still the matter of how you do this:

* You could copy the project reference folder into all top-level projects you want to use it in. This has the disadvantage that you end up with multiple copies of code. If you patch or enhance a component you need to copy the patch to all the other projects, rebuild them and test.
* Another approach would be to symlink the component into each top-level project. The downside of this is that once you amend the component you could break all of the projects which depend on it.

A smarter solution is to publish the components as npm packages. You can use semantic versioning each time you publish using a version in the format major.minor.patch. You then add the components to other projects using <code>yarn add @myscope/reference1</code>.

Versioning works exactly the same as any other npm package. You specify in the consuming project’s <code>tsconfig.json</code> what version changes are acceptable:
```
    "@myscope/reference1": "1.0.1",   // Only version 1.0.1 can be used
    "@myscope/reference1": "~1.0.1",  // Patch updates are acceptable
    "@myscope/reference1": "^1.0.1",  // Minor version changes are OK
```
You can then update and publish new versions of the component with new version numbers. The other project will not be broken as it will continue to use the version specified in its <code>package.json</code>. When you are ready to update you can use the same yarn tools you would use to update any package (<code>yarn outdated / upgrade / upgrade-interactive</code> or the npm equivalents).

If you want to keep your packages private you can set up your own private npm repository with [Verdaccio](https://verdaccio.org/) or you can use [Github Packages](https://github.com/features/packages)

### Lerna

If your project references are complex and have their own scripts for testing and building you could use [Lerna](https://lerna.js.org/). This works well with yarn workspaces and the project structure outlined above. If you have a test script in reference1 you could use the following command to execute it:
```
    lerna run --scope=reference1 test
```
The same command without the <code>--scope</code> argument would execute the test scripts in all subprojects.

Yarn workspaces and Lerna introduce more power but also more complexity in the workflow. They are not required to use project references so it is up to you whether the extra learning curve they introduce is worthwhile.

### Build Times in Development

Using ts-loader and webpack-dev-server, when you change a file in one of the project references ts-loader will automatically rebuild the reference and include the change in the new bundle. Rebuilding the reference may take a few seconds. By comparison, when you change a file in the root source (non-reference) webpack will get ts-loader to rebuild just that file and create a new bundle very quickly, typically less than 1 second.

So if you are developing code in a reference and find the few seconds it takes to rebuild the reference too much, you could benefit from importing from the TypeScript source directly. This will be at the expense of longer warm start times as you will not be using the pre-built code for that referenced project.


