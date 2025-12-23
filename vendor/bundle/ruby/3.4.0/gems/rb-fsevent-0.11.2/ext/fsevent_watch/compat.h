/**
 * @headerfile compat.h
 * FSEventStream flag compatibility shim
 *
 * In order to compile a binary against an older SDK yet still support the
 * features present in later OS releases, we need to define any missing enum
 * constants not present in the older SDK. This allows us to safely defer
 * feature detection to runtime (and avoid recompilation).
 */


#ifndef listen_fsevents_compat_h
#define listen_fsevents_compat_h

#ifndef __CORESERVICES__
#include <CoreServices/CoreServices.h>
#endif // __CORESERVICES__

#ifndef __AVAILABILITY__
#include <Availability.h>
#endif // __AVAILABILITY__

#ifndef __MAC_10_6
#define __MAC_10_6            1060
#endif
#ifndef __MAC_10_7
#define __MAC_10_7            1070
#endif
#ifndef __MAC_10_9
#define __MAC_10_9            1090
#endif
#ifndef __MAC_10_10
#define __MAC_10_10         101000
#endif
#ifndef __MAC_10_13
#define __MAC_10_13         101300
#endif
#ifndef __IPHONE_6_0
#define __IPHONE_6_0         60000
#endif
#ifndef __IPHONE_7_0
#define __IPHONE_7_0         70000
#endif
#ifndef __IPHONE_9_0
#define __IPHONE_9_0         90000
#endif
#ifndef __IPHONE_11_0
#define __IPHONE_11_0       110000
#endif

#ifdef __cplusplus
extern "C" {
#endif


#if (defined(MAC_OS_X_VERSION_MAX_ALLOWED) && MAC_OS_X_VERSION_MAX_ALLOWED < __MAC_10_6) || \
    (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_6_0)
extern FSEventStreamCreateFlags kFSEventStreamCreateFlagIgnoreSelf;
#endif

#if (defined(MAC_OS_X_VERSION_MAX_ALLOWED) && MAC_OS_X_VERSION_MAX_ALLOWED < __MAC_10_7) || \
    (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_6_0)
extern FSEventStreamCreateFlags kFSEventStreamCreateFlagFileEvents;
extern FSEventStreamEventFlags  kFSEventStreamEventFlagItemCreated,
                                kFSEventStreamEventFlagItemRemoved,
                                kFSEventStreamEventFlagItemInodeMetaMod,
                                kFSEventStreamEventFlagItemRenamed,
                                kFSEventStreamEventFlagItemModified,
                                kFSEventStreamEventFlagItemFinderInfoMod,
                                kFSEventStreamEventFlagItemChangeOwner,
                                kFSEventStreamEventFlagItemXattrMod,
                                kFSEventStreamEventFlagItemIsFile,
                                kFSEventStreamEventFlagItemIsDir,
                                kFSEventStreamEventFlagItemIsSymlink;
#endif

#if (defined(MAC_OS_X_VERSION_MAX_ALLOWED) && MAC_OS_X_VERSION_MAX_ALLOWED < __MAC_10_9) || \
    (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_7_0)
extern FSEventStreamCreateFlags kFSEventStreamCreateFlagMarkSelf;
extern FSEventStreamEventFlags  kFSEventStreamEventFlagOwnEvent;
#endif

#if (defined(MAC_OS_X_VERSION_MAX_ALLOWED) && MAC_OS_X_VERSION_MAX_ALLOWED < __MAC_10_10) || \
    (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_9_0)
extern FSEventStreamEventFlags  kFSEventStreamEventFlagItemIsHardlink,
                                kFSEventStreamEventFlagItemIsLastHardlink;
#endif

#if (defined(MAC_OS_X_VERSION_MAX_ALLOWED) && MAC_OS_X_VERSION_MAX_ALLOWED < __MAC_10_13) || \
    (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_11_0)
extern FSEventStreamCreateFlags kFSEventStreamCreateFlagUseExtendedData;
extern FSEventStreamEventFlags  kFSEventStreamEventFlagItemCloned;
#endif


#ifdef __cplusplus
}
#endif

#endif // listen_fsevents_compat_h
