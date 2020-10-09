---
path: "/docs/contributing-guide"
title: "Contributing Guide"
---

Thank you for taking an interest in contributing to Chatwoot. Before submitting your contribution, please make sure to take a moment and read through the following guidelines:

- [Code of Conduct](https://www.chatwoot.com/docs/code-of-conduct)
- [Development Setup](https://www.chatwoot.com/docs/installation-guide-ubuntu)
- [Environment Setup](https://www.chatwoot.com/docs/quick-setup)

## Pull Request Guidelines

### General Guidelines

- We use [git-flow](https://nvie.com/posts/a-successful-git-branching-model/) branching model. The base branch is `develop`

- Please raise your PRs against `develop` branch

- It's okay and encouraged to have multiple small commits as you work on the PR - we will squash the commits before merging.

### Getting Started 

- Before starting your work, ensure an [issue](https://github.com/chatwoot/chatwoot/issues) exist for it. If not feel free to create one.
- Add a comment on the issue and wait for the issue to be assigned before you start working on it. 
  - This helps to avoid multiple people working on similar issues. 
- If the solution is complex, propose the solution on the issue and wait for one of the core contributors to approve before going into the implementation. 
  - This helps in shorter turn around times in merging PRs
- For new feature requests, Provide a convincing reason to add this feature. Real-life business use-cases will be super helpful. 
- Feel free to join our [discord community](https://discord.gg/cJXdrwS), if you need further discussions with the core team. 

### Developing a new feature:

- Please create the branch in the format `feature/<issue-id>-<issue-name>` (eg: `feature/235-contact-panel`)
- Add accompanying test cases.

### Bug fixes or chores:
- If you are resolving a particular issue, add `Bug: Fix xxxx` (#xxxx is the issue) in your PR title.
- Provide a detailed description of the bug in the PR.
- Add appropriate test coverage if applicable.
  
### Translations: 
- When you are introducing new text copies, you only need to worry about making changes to english language files. 
- We accept language translations / updates for existing translations through [crowdin](https://translate.chatwoot.com/)
  - If a language doesn't exist in our crowdin, please feel free to create an [issue](https://github.com/chatwoot/chatwoot/issues) to get it enabled. 
  
