#ifndef fsevent_watch_common_h
#define fsevent_watch_common_h

#include <CoreFoundation/CoreFoundation.h>
#ifdef __OBJC__
#import <Foundation/Foundation.h>
#endif

#include <CoreServices/CoreServices.h>
#include <unistd.h>
#include "compat.h"
#include "defines.h"
#include "TSICTString.h"

enum FSEventWatchOutputFormat {
  kFSEventWatchOutputFormatClassic,
  kFSEventWatchOutputFormatNIW,
  kFSEventWatchOutputFormatTNetstring,
  kFSEventWatchOutputFormatOTNetstring
};

#endif /* fsevent_watch_common_h */
