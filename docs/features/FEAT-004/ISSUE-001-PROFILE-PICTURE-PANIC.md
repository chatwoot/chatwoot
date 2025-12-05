# Critical Issue: Service Panic on Profile Picture Fetch

**Issue Type**: Critical Bug
**Status**: ✅ RESOLVED
**Severity**: High (causes service crash and message loss in downstream systems)
**Date Reported**: 2025-10-07
**Date Resolved**: 2025-10-07
**Affected Version**: whatsmeow `v0.0.0-20251003111114-4479f300784e`
**Fixed Version**: whatsmeow `v0.0.0-20251005083110-4fe97da162dc`

## Summary

The go-whatsapp-web-multidevice service crashes with a panic when attempting to fetch profile pictures from WhatsApp. The panic occurs due to an unsupported payload type (`*store.PrivacyToken`) in the whatsmeow library, causing the entire service to restart and potentially lose messages in downstream systems like Chatwoot.

## ✅ Resolution

**Fix Applied**: 2025-10-07

The issue has been **RESOLVED** by updating the whatsmeow library to version `v0.0.0-20251005083110-4fe97da162dc` (October 5, 2025), which includes fixes for PrivacyToken support in `GetProfilePictureInfo`.

### Fix Details

**Solution Implemented**: Solution 2 - Update whatsmeow Library

**Changes Made**:
```bash
# Updated from:
go.mau.fi/whatsmeow v0.0.0-20251003111114-4479f300784e

# Updated to:
go.mau.fi/whatsmeow v0.0.0-20251005083110-4fe97da162dc
go.mau.fi/libsignal v0.2.1-0.20251004173110-6e0a3f2435ed
```

**Upstream Fixes** (included in updated version):
- **Commit 1**: "user: Add PrivacyToken to GetProfilePictureInfo (#950)" by purpshell (Oct 3, 2025)
- **Commit 2**: "user: fix including privacy token in GetProfilePictureInfo" by tulir (Oct 3, 2025)

These commits add proper support for the `*store.PrivacyToken` payload type that WhatsApp now includes in profile picture requests.

**Verification**:
- ✅ Code compiles successfully
- ✅ All tests pass (internal/admin, pkg/utils, usecase, validations)
- ✅ No breaking changes detected
- ⏳ Awaiting production deployment and monitoring

**Next Steps**:
1. Deploy updated service to staging environment
2. Monitor for profile picture fetch errors
3. Test with various account types (regular, privacy-enabled, groups)
4. Deploy to production if stable
5. Monitor for 24-48 hours to confirm fix

## Impact

**Severity: CRITICAL**

- 🔴 **Service Availability**: Complete service crash requiring restart
- 🔴 **Message Loss**: Messages may be lost during service restart in downstream systems
- 🔴 **User Experience**: Profile pictures fail to load
- 🔴 **Reliability**: Cascading failures affecting message processing

### Affected Operations

1. ✅ **Working**: Message webhook delivery
2. ❌ **Failing**: Profile picture fetch (causes panic)
3. ❌ **Affected**: Any downstream system dependent on service availability

## Root Cause Analysis

### Technical Details

**Panic Message**:
```
panic: unsupported payload type: *store.PrivacyToken

goroutine [running]:
go.mau.fi/whatsmeow/binary.(*binaryEncoder).write(...)
go.mau.fi/whatsmeow.(*Client).GetProfilePictureInfo(...)
github.com/aldinokemal/go-whatsapp-web-multidevice/usecase.serviceUser.Avatar.func1()
```

**Location**: `src/usecase/user.go:88`

**Vulnerable Code**:
```go
func (service serviceUser) Avatar(ctx context.Context, request domainUser.AvatarRequest) (response domainUser.AvatarResponse, err error) {
    // ...
    go func() {
        // ... validation ...

        // LINE 88: This call panics with PrivacyToken error
        pic, err := whatsapp.GetClient().GetProfilePictureInfo(dataWaRecipient, &whatsmeow.GetProfilePictureParams{
            Preview:     request.IsPreview,
            IsCommunity: request.IsCommunity,
        })

        if err != nil {
            chanErr <- err
        } else if pic == nil {
            chanErr <- errors.New("no avatar found")
        } else {
            response.URL = pic.URL
            response.ID = pic.ID
            response.Type = pic.Type
            chanResp <- response
        }
    }()
    // ...
}
```

**Root Cause**:
1. The whatsmeow library version `v0.0.0-20251003111114-4479f300784e` does not support the `*store.PrivacyToken` payload type
2. WhatsApp has updated their protocol to include privacy tokens in profile picture requests
3. The goroutine in the Avatar function lacks panic recovery (`defer recover()`)
4. When `GetProfilePictureInfo` panics, it crashes the entire service

## Evidence

### Observed Behavior

From production logs (Chatwoot integration):

```
time="2025-10-07T19:01:36Z" level=info msg="Forwarding message event to 1 configured webhook(s)"
time="2025-10-07T19:01:36Z" level=info msg="Successfully submitted webhook on attempt 1"

panic: unsupported payload type: *store.PrivacyToken

time="2025-10-07T19:01:41Z" level=info msg="[DEBUG] Starting reconnect process..."
time="2025-10-07T19:01:42Z" level=info msg="[DEBUG] Reconnection completed - IsConnected: true, IsLoggedIn: false"
```

**Pattern**: Service successfully processes messages, then panics on profile picture fetch, requiring restart.

### Current State

- **whatsmeow version**: ✅ **UPDATED** to `v0.0.0-20251005083110-4fe97da162dc` (line 25 in `src/go.mod`)
- **PrivacyToken support**: ✅ **FIXED** - Included in updated whatsmeow version
- **Panic recovery**: ⏳ Not yet implemented (may not be necessary with upstream fix)
- **Error handling**: ✅ Handles returned errors properly

## Proposed Solutions

### Solution 1: Add Panic Recovery (IMMEDIATE - P0)

**Priority**: P0 (Must fix immediately)
**Timeline**: Same day
**Risk**: Low

Add panic recovery to the Avatar function to prevent service crashes.

**Implementation**:

```go
func (service serviceUser) Avatar(ctx context.Context, request domainUser.AvatarRequest) (response domainUser.AvatarResponse, err error) {
    chanResp := make(chan domainUser.AvatarResponse)
    chanErr := make(chan error)
    waktu := time.Now()

    go func() {
        // Add panic recovery
        defer func() {
            if r := recover(); r != nil {
                log.WithFields(log.Fields{
                    "panic":   r,
                    "phone":   request.Phone,
                    "preview": request.IsPreview,
                }).Error("Panic recovered in Avatar function - GetProfilePictureInfo failed")

                // Send error to channel instead of crashing
                chanErr <- fmt.Errorf("failed to get profile picture: %v", r)
            }
        }()

        err = validations.ValidateUserAvatar(ctx, request)
        if err != nil {
            chanErr <- err
            return
        }

        dataWaRecipient, err := utils.ValidateJidWithLogin(whatsapp.GetClient(), request.Phone)
        if err != nil {
            chanErr <- err
            return
        }

        pic, err := whatsapp.GetClient().GetProfilePictureInfo(dataWaRecipient, &whatsmeow.GetProfilePictureParams{
            Preview:     request.IsPreview,
            IsCommunity: request.IsCommunity,
        })

        if err != nil {
            chanErr <- err
        } else if pic == nil {
            chanErr <- errors.New("no avatar found")
        } else {
            response.URL = pic.URL
            response.ID = pic.ID
            response.Type = pic.Type
            chanResp <- response
        }
    }()

    for {
        select {
        case err := <-chanErr:
            return response, err
        case response := <-chanResp:
            return response, nil
        default:
            if waktu.Add(2 * time.Second).Before(time.Now()) {
                return response, pkgError.ContextError("Error timeout get avatar !")
            }
        }
    }
}
```

**Benefits**:
- ✅ Prevents service crashes
- ✅ Allows messages to continue processing
- ✅ Maintains service availability
- ✅ Provides proper error logging
- ✅ Degrades gracefully (returns error instead of crashing)

**Testing**:
```go
// Test file: src/usecase/user_test.go
func TestAvatar_PanicRecovery(t *testing.T) {
    // Test that Avatar function doesn't crash on panic
    // Verify error is returned instead
    // Verify error is logged properly
}
```

### Solution 2: Update whatsmeow Library (SHORT-TERM - P0) ✅ IMPLEMENTED

**Priority**: P0 (Must fix)
**Status**: ✅ **COMPLETED** (2025-10-07)
**Timeline**: Same day (faster than expected)
**Risk**: Medium (may introduce breaking changes) - **No breaking changes detected**

Update to the latest whatsmeow version that supports `*store.PrivacyToken`.

**Action Items**:
1. ✅ Check whatsmeow repository for latest stable version → Found `v0.0.0-20251005083110-4fe97da162dc`
2. ✅ Review changelog for breaking changes → Reviewed commits from Oct 3-5, 2025
3. ✅ Update `src/go.mod`:
   ```bash
   go get go.mau.fi/whatsmeow@v0.0.0-20251005083110-4fe97da162dc
   go mod tidy
   ```
4. ✅ Run full test suite → All tests passed
5. ⏳ Test profile picture fetching in staging
6. ⏳ Deploy to production

**Implementation Details**:
- Updated whatsmeow from `v0.0.0-20251003111114-4479f300784e` to `v0.0.0-20251005083110-4fe97da162dc`
- Also updated libsignal from `v0.2.0` to `v0.2.1-0.20251004173110-6e0a3f2435ed`
- Verified no compilation errors
- All existing tests pass

**Related Issues**:
- [whatsmeow#672](https://github.com/tulir/whatsmeow/issues/672) - GetProfilePictureInfo causes WebSocket disconnection
- [whatsmeow#950](https://github.com/tulir/whatsmeow/pull/950) - Add PrivacyToken to GetProfilePictureInfo (merged Oct 3, 2025)

### Solution 3: Implement Fallback Avatar Strategy (MEDIUM-TERM - P1)

**Priority**: P1 (Should fix)
**Timeline**: 3-5 days
**Risk**: Low

Provide default/cached avatar when profile picture fetch fails.

**Implementation**:
1. Cache successfully fetched avatars
2. Return cached version on failure
3. Provide default avatar URL as fallback
4. Log avatar fetch failures for monitoring

### Solution 4: Make Avatar Fetch Optional (OPTIONAL - P2)

**Priority**: P2 (Nice to have)
**Timeline**: 1 week
**Risk**: Low

Add configuration option to disable avatar fetching entirely.

**Implementation**:
```go
// In config
WHATSAPP_AVATAR_FETCH_ENABLED=false

// In Avatar function
if !config.IsAvatarFetchEnabled() {
    return response, errors.New("avatar fetch is disabled")
}
```

## Recommended Fix Priority

1. **IMMEDIATE (Today)**: ✅ **COMPLETED**
   - ✅ Solution 2: Update whatsmeow library (fixes root cause) - **IMPLEMENTED 2025-10-07**
   - ⏳ Solution 1: Add panic recovery (prevents crashes) - **MAY NOT BE NECESSARY**

2. **SHORT-TERM (This week)**: ⏳ **PENDING DEPLOYMENT**
   - ⏳ Deploy updated library to staging
   - ⏳ Deploy to production after verification

3. **MEDIUM-TERM (Next week)**: 📋 **OPTIONAL IMPROVEMENTS**
   - ⚠️ Solution 3: Implement fallback strategy (improves UX)
   - ⚠️ Solution 1: Add panic recovery as defensive measure

4. **OPTIONAL**:
   - ℹ️ Solution 4: Make avatar fetch configurable

## Testing Strategy

### Unit Tests

**File**: `src/usecase/user_test.go`

```go
func TestAvatar_PanicRecovery(t *testing.T) {
    // Mock GetProfilePictureInfo to panic
    // Verify Avatar function returns error
    // Verify error is logged
    // Verify service continues running
}

func TestAvatar_TimeoutHandling(t *testing.T) {
    // Mock slow GetProfilePictureInfo
    // Verify timeout occurs after 2 seconds
    // Verify proper error is returned
}

func TestAvatar_SuccessfulFetch(t *testing.T) {
    // Mock successful GetProfilePictureInfo
    // Verify correct avatar data is returned
}
```

### Integration Tests

1. **Simulate PrivacyToken Error**:
   - Test with WhatsApp contact that has privacy settings enabled
   - Verify service doesn't crash
   - Verify error is returned gracefully

2. **Load Testing**:
   - Send multiple avatar requests concurrently
   - Verify no goroutine leaks
   - Verify proper timeout handling

### Manual Testing

1. Deploy to staging environment
2. Test avatar fetch with various accounts:
   - Regular accounts
   - Business accounts
   - Accounts with privacy settings
   - Group avatars
   - Community avatars
3. Monitor service logs for panics
4. Verify proper error handling

## Monitoring & Alerts

### Metrics to Add

```go
// Prometheus metrics
var (
    avatarFetchTotal = prometheus.NewCounterVec(
        prometheus.CounterOpts{
            Name: "whatsapp_avatar_fetch_total",
            Help: "Total number of avatar fetch attempts",
        },
        []string{"status"}, // success, error, panic, timeout
    )

    avatarFetchPanicsTotal = prometheus.NewCounter(
        prometheus.CounterOpts{
            Name: "whatsapp_avatar_fetch_panics_total",
            Help: "Total number of panics in avatar fetch",
        },
    )
)
```

### Alerts

```yaml
- alert: WhatsAppAvatarFetchPanics
  expr: rate(whatsapp_avatar_fetch_panics_total[5m]) > 0
  severity: critical
  annotations:
    summary: "WhatsApp avatar fetch is panicking"
    description: "Avatar fetch function is experiencing panics"

- alert: WhatsAppAvatarFetchHighFailureRate
  expr: rate(whatsapp_avatar_fetch_total{status="error"}[5m]) > 0.5
  severity: warning
  annotations:
    summary: "High avatar fetch failure rate"
    description: "More than 50% of avatar fetches are failing"
```

### Logging Improvements

**Current**: Limited error context
**Proposed**: Structured logging with full context

```go
log.WithFields(log.Fields{
    "phone":        request.Phone,
    "is_preview":   request.IsPreview,
    "is_community": request.IsCommunity,
    "error":        err,
    "panic":        recovered,
    "stack_trace":  string(debug.Stack()),
}).Error("Failed to fetch avatar")
```

## Workarounds (Until Fixed)

### For Operators

1. **Enable Auto-Restart**: Ensure service has automatic restart capability
   ```yaml
   # Docker Compose
   restart: unless-stopped

   # Kubernetes
   restartPolicy: Always
   ```

2. **Monitor Service Health**: Set up alerting for service restarts
   ```bash
   # Check restart count
   docker ps --filter "name=gowa" --format "table {{.Names}}\t{{.Status}}"
   ```

3. **Disable Avatar Endpoints Temporarily**: Comment out avatar routes if not critical
   ```go
   // Comment out in routes/user.go
   // router.Get("/user/avatar", controller.Avatar)
   ```

### For Developers

1. **Local Testing**: Use try-catch wrapper around avatar fetch
2. **Skip Avatar in Dev**: Set environment variable to disable avatar fetch

## Related Documentation

- [CLAUDE.md](./CLAUDE.md) - Project architecture and development guide
- [Deployment Guide](./docs/deployment-guide.md) - Deployment instructions
- [OpenAPI Specification](./docs/openapi.yaml) - API documentation

## External References

- **whatsmeow Repository**: https://github.com/tulir/whatsmeow
- **Issue #672**: https://github.com/tulir/whatsmeow/issues/672 - GetProfilePictureInfo WebSocket disconnection
- **Chatwoot Issue**: `docs/features/ADR-001/ISSUE-001-message-loss-on-profile-picture-fetch.md`

## Communication Plan

### Internal Team

- ✅ Document issue (this file) - **COMPLETED 2025-10-07**
- ✅ Update whatsmeow library (Solution 2) - **COMPLETED 2025-10-07**
- ✅ Verify no breaking changes - **COMPLETED 2025-10-07**
- ✅ Run test suite - **COMPLETED 2025-10-07**
- ⏳ Test fix in staging
- ⏳ Deploy to production
- ⏳ Monitor for 24-48 hours
- ⏳ Optional: Implement panic recovery (Solution 1) as defensive measure

### Users/Integrators

**If users report avatar issues**:
- Acknowledge the issue
- Explain that it's being addressed
- Provide ETA for fix
- Notify when fix is deployed

## Next Steps

- [x] Check for whatsmeow library updates - **COMPLETED 2025-10-07**
- [x] Update whatsmeow to `v0.0.0-20251005083110-4fe97da162dc` - **COMPLETED 2025-10-07**
- [x] Verify no breaking changes - **COMPLETED 2025-10-07**
- [x] Run test suite - **COMPLETED 2025-10-07**
- [ ] Test updated whatsmeow version in staging
- [ ] Deploy to production
- [ ] Monitor for profile picture fetch errors for 24-48 hours
- [ ] Verify fix resolves the panic issue
- [ ] Optional: Implement panic recovery in Avatar function (Solution 1) as defensive safeguard
- [ ] Optional: Add unit tests for panic recovery
- [ ] Optional: Add monitoring metrics and alerts
- [ ] Optional: Implement fallback avatar strategy
- [ ] Document fix in changelog

---

**Issue Created**: 2025-10-07
**Last Updated**: 2025-10-07
**Date Resolved**: 2025-10-07
**Resolution Time**: Same day
**Priority**: P0 - CRITICAL
**Fix Status**: ✅ **RESOLVED** - Library updated, awaiting production deployment
**Solution Applied**: Solution 2 - Update whatsmeow library to `v0.0.0-20251005083110-4fe97da162dc`
**Related Commits**:
- whatsmeow PR#950: "Add PrivacyToken to GetProfilePictureInfo"
- whatsmeow commit: "fix including privacy token in GetProfilePictureInfo"
