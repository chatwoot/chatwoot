# Extended Features

This directory contains original implementations of advanced features for Chatwoot Community Edition.

## Legal Compliance Statement

All code in this directory was developed as **original work** by NightTech Services Inc.

### Key Points:

- **Original Implementation**: While these features model functionality similar to Chatwoot Enterprise, all code has been written from scratch without copying any proprietary enterprise source code.

- **MIT-Licensed Foundation**: These implementations are built upon and use only the MIT-licensed portions of Chatwoot (code outside the original `enterprise/` directory).

- **No Enterprise Code**: No code from the Chatwoot Enterprise directory (`enterprise/LICENSE`) has been copied, moved, or used in production. The enterprise codebase was used only as a reference during development to understand functionality.

- **Fully Compliant**: This approach is fully compliant with the MIT license, which permits modification, redistribution, and creation of derivative works from MIT-licensed code.

### License

This code is licensed under the MIT License. See [LICENSE](./LICENSE) for details.

## Development Process

1. **Reference Phase**: Study the functionality and behavior of enterprise features in the `enterprise/` directory
2. **Rewrite Phase**: Create original implementations from scratch in `extended/`
3. **Testing Phase**: Verify functionality matches expected behavior
4. **Compliance Review**: Ensure no enterprise code was copied

### Workflow

The original `enterprise/` directory is **retained as a reference** to:
- Track upstream changes from Chatwoot
- Understand new feature implementations
- Model rewrites after the latest functionality
- Compare implementations during development

**Important**: The `enterprise/` directory code is **never deployed** to production. Only the rewritten code in `extended/` is used by the application.

## Continuous Updates

As upstream Chatwoot Enterprise evolves, we may model new features by:
- Observing functionality changes in MIT-licensed portions
- Understanding new behaviors and requirements
- Writing our own original implementations

This is legal under MIT as we continue to create original work without copying proprietary code.

## Features Included

This directory includes original implementations of:
- Audit logs
- SLA management
- Custom roles and permissions
- Response bot enhancements
- Integration connectors
- And other advanced capabilities

All features are available without license restrictions as part of Chatwoot Community Edition.

---

**Copyright © 2025 NightTech Services Inc.**  
Licensed under MIT License
