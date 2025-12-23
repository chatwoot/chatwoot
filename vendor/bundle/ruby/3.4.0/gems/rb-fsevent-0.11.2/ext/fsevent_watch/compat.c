#include "compat.h"


#if (defined(MAC_OS_X_VERSION_MAX_ALLOWED) && MAC_OS_X_VERSION_MAX_ALLOWED < __MAC_10_6) || \
    (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_6_0)
FSEventStreamCreateFlags  kFSEventStreamCreateFlagIgnoreSelf        = 0x00000008;
#endif

#if (defined(MAC_OS_X_VERSION_MAX_ALLOWED) && MAC_OS_X_VERSION_MAX_ALLOWED < __MAC_10_7) || \
    (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_6_0)
FSEventStreamCreateFlags  kFSEventStreamCreateFlagFileEvents        = 0x00000010;
FSEventStreamEventFlags   kFSEventStreamEventFlagItemCreated        = 0x00000100;
FSEventStreamEventFlags   kFSEventStreamEventFlagItemRemoved        = 0x00000200;
FSEventStreamEventFlags   kFSEventStreamEventFlagItemInodeMetaMod   = 0x00000400;
FSEventStreamEventFlags   kFSEventStreamEventFlagItemRenamed        = 0x00000800;
FSEventStreamEventFlags   kFSEventStreamEventFlagItemModified       = 0x00001000;
FSEventStreamEventFlags   kFSEventStreamEventFlagItemFinderInfoMod  = 0x00002000;
FSEventStreamEventFlags   kFSEventStreamEventFlagItemChangeOwner    = 0x00004000;
FSEventStreamEventFlags   kFSEventStreamEventFlagItemXattrMod       = 0x00008000;
FSEventStreamEventFlags   kFSEventStreamEventFlagItemIsFile         = 0x00010000;
FSEventStreamEventFlags   kFSEventStreamEventFlagItemIsDir          = 0x00020000;
FSEventStreamEventFlags   kFSEventStreamEventFlagItemIsSymlink      = 0x00040000;
#endif

#if (defined(MAC_OS_X_VERSION_MAX_ALLOWED) && MAC_OS_X_VERSION_MAX_ALLOWED < __MAC_10_9) || \
    (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_7_0)
FSEventStreamCreateFlags  kFSEventStreamCreateFlagMarkSelf          = 0x00000020;
FSEventStreamEventFlags   kFSEventStreamEventFlagOwnEvent           = 0x00080000;
#endif

#if (defined(MAC_OS_X_VERSION_MAX_ALLOWED) && MAC_OS_X_VERSION_MAX_ALLOWED < __MAC_10_10) || \
    (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_9_0)
FSEventStreamEventFlags   kFSEventStreamEventFlagItemIsHardlink     = 0x00100000;
FSEventStreamEventFlags   kFSEventStreamEventFlagItemIsLastHardlink = 0x00200000;
#endif

#if (defined(MAC_OS_X_VERSION_MAX_ALLOWED) && MAC_OS_X_VERSION_MAX_ALLOWED < __MAC_10_13) || \
    (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_11_0)
FSEventStreamCreateFlags  kFSEventStreamCreateFlagUseExtendedData   = 0x00000040;
FSEventStreamEventFlags   kFSEventStreamEventFlagItemCloned         = 0x00400000;
#endif
