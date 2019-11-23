---
path: "/docs/common-errors"
title: "Common Errors"
---

### Errors you might encounter while setting up the project

```bash
ArgumentError: invalid uri scheme
```

This is an error thrown from redis connector. You might not have setup the redis environment variables properly. Please refer to dependencies section to install redis-server and [Configure Redis URL](https://www.chatwoot.com/docs/environment-variables) in the environment-variables section.
