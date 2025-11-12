# Troubleshooting Guide

## Common Issues & Solutions

---

## Installation Issues

### npm/pnpm install fails

**Symptoms**: Package installation errors

**Solutions**:
```bash
# Clear cache
pnpm store prune
rm -rf node_modules pnpm-lock.yaml

# Reinstall
pnpm install

# If still fails, check Node version
node --version  # Should be 23.x
```

---

## Database Issues

### Cannot connect to database

**Symptoms**: `ECONNREFUSED` or `connection refused`

**Solutions**:
```bash
# Check PostgreSQL is running
pg_isready

# Start PostgreSQL (Mac)
brew services start postgresql

# Start PostgreSQL (Linux)
sudo systemctl start postgresql

# Check connection manually
psql -U postgres -h localhost
```

### Database doesn't exist

**Symptoms**: `database "chatwoot_development" does not exist`

**Solution**:
```bash
createdb chatwoot_development
pnpm migration:run
```

### Migration fails

**Symptoms**: Migration errors

**Solutions**:
```bash
# Check migration status
pnpm migration:show

# Revert last migration
pnpm migration:revert

# Re-run migrations
pnpm migration:run
```

---

## Redis Issues

### Cannot connect to Redis

**Symptoms**: `ECONNREFUSED localhost:6379`

**Solutions**:
```bash
# Check Redis is running
redis-cli ping
# Should return: PONG

# Start Redis (Mac)
brew services start redis

# Start Redis (Linux)
sudo systemctl start redis
```

---

## Test Issues

### Tests failing

**Symptoms**: Test errors

**Solutions**:
```bash
# Clear test database
NODE_ENV=test pnpm migration:revert --all
NODE_ENV=test pnpm migration:run

# Run tests with verbose output
pnpm test --reporter=verbose

# Run single test
pnpm test path/to/test.spec.ts
```

### Test database issues

**Symptoms**: "Table doesn't exist" in tests

**Solution**:
```bash
# Reset test database
createdb chatwoot_test
NODE_ENV=test pnpm migration:run
```

---

## TypeScript Issues

### Type errors

**Symptoms**: `TS2345: Argument of type 'X' is not assignable to parameter of type 'Y'`

**Solutions**:
- Check types are correct
- Use proper TypeScript types (not `any`)
- Check imports are correct
- Restart TypeScript server in IDE

### Module not found

**Symptoms**: `Cannot find module '@/models/User'`

**Solutions**:
```bash
# Check tsconfig.json paths are correct
# Restart TypeScript server
# Clear build cache
rm -rf dist
pnpm build
```

---

## Lint/Format Issues

### ESLint errors

**Symptoms**: Linting fails

**Solutions**:
```bash
# Auto-fix issues
pnpm lint:fix

# If can't auto-fix, manual fixes needed
# Check .eslintrc.js for rules
```

### Prettier formatting issues

**Symptoms**: Code not formatted

**Solutions**:
```bash
# Format all files
pnpm format

# Check formatting
pnpm format -- --check
```

---

## Runtime Issues

### Port already in use

**Symptoms**: `Error: listen EADDRINUSE: address already in use :::3000`

**Solutions**:
```bash
# Find process using port 3000
lsof -i :3000

# Kill process
kill -9 <PID>

# Or use different port
PORT=3001 pnpm start:dev
```

### Out of memory

**Symptoms**: `JavaScript heap out of memory`

**Solutions**:
```bash
# Increase Node memory
NODE_OPTIONS="--max-old-space-size=4096" pnpm start:dev
```

---

## API Issues

### API returns 401 Unauthorized

**Symptoms**: API calls fail with 401

**Solutions**:
- Check JWT token is valid
- Check token not expired
- Check Authorization header format: `Bearer <token>`
- Regenerate token

### API returns 404 Not Found

**Symptoms**: Endpoint not found

**Solutions**:
- Check endpoint URL is correct
- Check controller route decorator
- Check module imports controller
- Restart server

### API returns 422 Validation Error

**Symptoms**: Request validation fails

**Solutions**:
- Check request body matches DTO
- Check all required fields present
- Check field types are correct
- Check DTO validators

---

## Performance Issues

### Slow queries

**Symptoms**: API responses slow

**Solutions**:
- Check for N+1 queries
- Add eager loading (`relations` in find())
- Add database indexes
- Use query profiling

### High memory usage

**Symptoms**: Memory grows over time

**Solutions**:
- Check for memory leaks
- Profile with Chrome DevTools
- Check unclosed database connections
- Check event listener cleanup

---

## Integration Issues

### Webhook signature verification fails

**Symptoms**: Webhook rejected

**Solutions**:
- Check signature algorithm (HMAC-SHA256, etc.)
- Check secret key is correct
- Check payload format
- Log raw payload for debugging

### Third-party API fails

**Symptoms**: Integration API returns errors

**Solutions**:
- Check API credentials
- Check rate limits
- Check API version
- Check error response format
- Add retry logic

---

## Git Issues

### Merge conflicts

**Symptoms**: Git merge conflicts

**Solutions**:
```bash
# Pull latest
git pull origin develop

# Resolve conflicts manually
# Then:
git add .
git commit -m "Resolve merge conflicts"
```

### Commit signature fails

**Symptoms**: Commit signing error

**Solutions**:
- Check GPG key configured
- Check Git config has signing key
- Try commit without signing (dev only)

---

## IDE Issues

### VS Code IntelliSense not working

**Symptoms**: No autocomplete

**Solutions**:
- Restart TypeScript server: `Cmd+Shift+P` → "Restart TS Server"
- Check `tsconfig.json` is valid
- Reload VS Code window
- Check TypeScript extension is enabled

---

## Build Issues

### Build fails

**Symptoms**: `pnpm build` fails

**Solutions**:
```bash
# Clear dist folder
rm -rf dist

# Clear node_modules
rm -rf node_modules pnpm-lock.yaml
pnpm install

# Rebuild
pnpm build
```

---

## Need More Help?

1. Check [DEVELOPMENT.md](./DEVELOPMENT.md)
2. Check [FAQ.md](./FAQ.md)
3. Search GitHub issues
4. Ask in team channel
5. Pair program with teammate
6. Escalate to tech lead

---

**Pro Tip**: When asking for help, include:
- Error message (full stack trace)
- Steps to reproduce
- What you've tried
- Environment details (OS, Node version, etc.)
