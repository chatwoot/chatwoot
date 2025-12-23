#include "common.h"
#include "signal_handlers.h"
#include "cli.h"
#include "FSEventsFix.h"

// TODO: set on fire. cli.{h,c} handle both parsing and defaults, so there's
//       no need to set those here. also, in order to scope metadata by path,
//       each stream will need its own configuration... so this won't work as
//       a global any more. In the end the goal is to make the output format
//       able to declare not just that something happened and what flags were
//       attached, but what path it was watching that caused those events (so
//       that the path itself can be used for routing that information to the
//       relevant callback).
//
// Structure for storing metadata parsed from the commandline
static struct {
  FSEventStreamEventId            sinceWhen;
  CFTimeInterval                  latency;
  FSEventStreamCreateFlags        flags;
  CFMutableArrayRef               paths;
  enum FSEventWatchOutputFormat   format;
} config = {
  (UInt64) kFSEventStreamEventIdSinceNow,
  (double) 0.3,
  (CFOptionFlags) kFSEventStreamCreateFlagNone,
  NULL,
  kFSEventWatchOutputFormatOTNetstring
};

// Prototypes
static void         append_path(const char* path);
static inline void  parse_cli_settings(int argc, const char* argv[]);
static void         callback(FSEventStreamRef streamRef,
                             void* clientCallBackInfo,
                             size_t numEvents,
                             void* eventPaths,
                             const FSEventStreamEventFlags eventFlags[],
                             const FSEventStreamEventId eventIds[]);
static bool needs_fsevents_fix = false;

// Resolve a path and append it to the CLI settings structure
// The FSEvents API will, internally, resolve paths using a similar scheme.
// Performing this ahead of time makes things less confusing, IMHO.
static void append_path(const char* path)
{
#ifdef DEBUG
  fprintf(stderr, "\n");
  fprintf(stderr, "append_path called for: %s\n", path);
#endif

#if MAC_OS_X_VERSION_MIN_REQUIRED >= 1060

#ifdef DEBUG
  fprintf(stderr, "compiled against 10.6+, using CFURLCreateFileReferenceURL\n");
#endif

  CFURLRef url = CFURLCreateFromFileSystemRepresentation(NULL, (const UInt8*)path, (CFIndex)strlen(path), false);
  CFURLRef placeholder = CFURLCopyAbsoluteURL(url);
  CFRelease(url);

  CFMutableArrayRef imaginary = NULL;

  // if we don't have an existing url, spin until we get to a parent that
  // does exist, saving any imaginary components for appending back later
  while(!CFURLResourceIsReachable(placeholder, NULL)) {
#ifdef DEBUG
    fprintf(stderr, "path does not exist\n");
#endif

    CFStringRef child;

    if (imaginary == NULL) {
      imaginary = CFArrayCreateMutable(NULL, 0, &kCFTypeArrayCallBacks);
    }

    child = CFURLCopyLastPathComponent(placeholder);
    CFArrayInsertValueAtIndex(imaginary, 0, child);
    CFRelease(child);

    url = CFURLCreateCopyDeletingLastPathComponent(NULL, placeholder);
    CFRelease(placeholder);
    placeholder = url;

#ifdef DEBUG
    fprintf(stderr, "parent: ");
    CFShow(placeholder);
#endif
  }

#ifdef DEBUG
  fprintf(stderr, "path exists\n");
#endif

  // realpath() doesn't always return the correct case for a path, so this
  // is a funky workaround that converts a path into a (volId/inodeId) pair
  // and asks what the path should be for that. since it looks at the actual
  // inode instead of returning the same case passed in like realpath()
  // appears to do for HFS+, it should always be correct.
  url = CFURLCreateFileReferenceURL(NULL, placeholder, NULL);
  CFRelease(placeholder);
  placeholder = CFURLCreateFilePathURL(NULL, url, NULL);
  CFRelease(url);

#ifdef DEBUG
  fprintf(stderr, "path resolved to: ");
  CFShow(placeholder);
#endif

  // if we stripped off any imaginary path components, append them back on
  if (imaginary != NULL) {
    CFIndex count = CFArrayGetCount(imaginary);
    for (CFIndex i = 0; i<count; i++) {
      CFStringRef component = CFArrayGetValueAtIndex(imaginary, i);
#ifdef DEBUG
      fprintf(stderr, "appending component: ");
      CFShow(component);
#endif
      url = CFURLCreateCopyAppendingPathComponent(NULL, placeholder, component, false);
      CFRelease(placeholder);
      placeholder = url;
    }
    CFRelease(imaginary);
  }

#ifdef DEBUG
  fprintf(stderr, "result: ");
  CFShow(placeholder);
#endif

  CFStringRef cfPath = CFURLCopyFileSystemPath(placeholder, kCFURLPOSIXPathStyle);
  CFRelease(placeholder);

  char cPath[PATH_MAX];
  if (CFStringGetCString(cfPath, cPath, PATH_MAX, kCFStringEncodingUTF8)) {
    FSEventsFixRepairStatus status = FSEventsFixRepairIfNeeded(cPath);
    if (status == FSEventsFixRepairStatusFailed) {
      needs_fsevents_fix = true;
    }
  }

  CFArrayAppendValue(config.paths, cfPath);
  CFRelease(cfPath);

#else

#ifdef DEBUG
  fprintf(stderr, "compiled against 10.5, using realpath()\n");
#endif

  char fullPath[PATH_MAX + 1];

  if (realpath(path, fullPath) == NULL) {
#ifdef DEBUG
    fprintf(stderr, "  realpath not directly resolvable from path\n");
#endif

    if (path[0] != '/') {
#ifdef DEBUG
      fprintf(stderr, "  passed path is not absolute\n");
#endif
      size_t len;
      getcwd(fullPath, sizeof(fullPath));
#ifdef DEBUG
      fprintf(stderr, "  result of getcwd: %s\n", fullPath);
#endif
      len = strlen(fullPath);
      fullPath[len] = '/';
      strlcpy(&fullPath[len + 1], path, sizeof(fullPath) - (len + 1));
    } else {
#ifdef DEBUG
      fprintf(stderr, "  assuming path does not YET exist\n");
#endif
      strlcpy(fullPath, path, sizeof(fullPath));
    }
  }

#ifdef DEBUG
  fprintf(stderr, "  resolved path to: %s\n", fullPath);
  fprintf(stderr, "\n");
#endif

  CFStringRef pathRef = CFStringCreateWithCString(kCFAllocatorDefault,
                                                  fullPath,
                                                  kCFStringEncodingUTF8);
  CFArrayAppendValue(config.paths, pathRef);
  CFRelease(pathRef);

#endif
}

// Parse commandline settings
static inline void parse_cli_settings(int argc, const char* argv[])
{
  // runtime os version detection
  SInt32 osMajorVersion, osMinorVersion;
  if (!(Gestalt(gestaltSystemVersionMajor, &osMajorVersion) == noErr)) {
    osMajorVersion = 0;
  }
  if (!(Gestalt(gestaltSystemVersionMinor, &osMinorVersion) == noErr)) {
    osMinorVersion = 0;
  }

  if ((osMajorVersion == 10) & (osMinorVersion < 5)) {
    fprintf(stderr, "The FSEvents API is unavailable on this version of macos!\n");
    exit(EXIT_FAILURE);
  }

  struct cli_info args_info;
  cli_parser_init(&args_info);

  if (cli_parser(argc, argv, &args_info) != 0) {
    exit(EXIT_FAILURE);
  }

  config.paths = CFArrayCreateMutable(NULL,
                                      (CFIndex)0,
                                      &kCFTypeArrayCallBacks);

  config.sinceWhen = args_info.since_when_arg;
  config.latency = args_info.latency_arg;
  config.format = args_info.format_arg;

  if (args_info.no_defer_flag) {
    config.flags |= kFSEventStreamCreateFlagNoDefer;
  }
  if (args_info.watch_root_flag) {
    config.flags |= kFSEventStreamCreateFlagWatchRoot;
  }

  if (args_info.ignore_self_flag) {
    if ((osMajorVersion == 10) & (osMinorVersion >= 6)) {
      config.flags |= kFSEventStreamCreateFlagIgnoreSelf;
    } else {
      fprintf(stderr, "MacOSX 10.6 or later is required for --ignore-self\n");
      exit(EXIT_FAILURE);
    }
  }

  if (args_info.file_events_flag) {
    if ((osMajorVersion == 10) & (osMinorVersion >= 7)) {
      config.flags |= kFSEventStreamCreateFlagFileEvents;
    } else {
      fprintf(stderr, "MacOSX 10.7 or later required for --file-events\n");
      exit(EXIT_FAILURE);
    }
  }

  if (args_info.mark_self_flag) {
    if ((osMajorVersion == 10) & (osMinorVersion >= 9)) {
      config.flags |= kFSEventStreamCreateFlagMarkSelf;
    } else {
      fprintf(stderr, "MacOSX 10.9 or later required for --mark-self\n");
      exit(EXIT_FAILURE);
    }
  }

  if (args_info.inputs_num == 0) {
    append_path(".");
  } else {
    for (unsigned int i=0; i < args_info.inputs_num; ++i) {
      append_path(args_info.inputs[i]);
    }
  }

  cli_parser_free(&args_info);

#ifdef DEBUG
  fprintf(stderr, "config.sinceWhen    %llu\n", config.sinceWhen);
  fprintf(stderr, "config.latency      %f\n", config.latency);

// STFU clang
#if defined(__LP64__)
  fprintf(stderr, "config.flags        %#.8x\n", config.flags);
#else
  fprintf(stderr, "config.flags        %#.8lx\n", config.flags);
#endif

  FLAG_CHECK_STDERR(config.flags, kFSEventStreamCreateFlagUseCFTypes,
                    "  Using CF instead of C types");
  FLAG_CHECK_STDERR(config.flags, kFSEventStreamCreateFlagNoDefer,
                    "  NoDefer latency modifier enabled");
  FLAG_CHECK_STDERR(config.flags, kFSEventStreamCreateFlagWatchRoot,
                    "  WatchRoot notifications enabled");
  FLAG_CHECK_STDERR(config.flags, kFSEventStreamCreateFlagIgnoreSelf,
                    "  IgnoreSelf enabled");
  FLAG_CHECK_STDERR(config.flags, kFSEventStreamCreateFlagFileEvents,
                    "  FileEvents enabled");

  fprintf(stderr, "config.paths\n");

  long numpaths = CFArrayGetCount(config.paths);

  for (long i = 0; i < numpaths; i++) {
    char path[PATH_MAX];
    CFStringGetCString(CFArrayGetValueAtIndex(config.paths, i),
                       path,
                       PATH_MAX,
                       kCFStringEncodingUTF8);
    fprintf(stderr, "  %s\n", path);
  }

  fprintf(stderr, "\n");
#endif
}

// original output format for rb-fsevent
static void classic_output_format(size_t numEvents,
                                  char** paths)
{
  for (size_t i = 0; i < numEvents; i++) {
    fprintf(stdout, "%s:", paths[i]);
  }
  fprintf(stdout, "\n");
}

// output format used in the Yoshimasa Niwa branch of rb-fsevent
static void niw_output_format(size_t numEvents,
                              char** paths,
                              const FSEventStreamEventFlags eventFlags[],
                              const FSEventStreamEventId eventIds[])
{
  for (size_t i = 0; i < numEvents; i++) {
    fprintf(stdout, "%lu:%llu:%s\n",
            (unsigned long)eventFlags[i],
            (unsigned long long)eventIds[i],
            paths[i]);
  }
  fprintf(stdout, "\n");
}

static void tstring_output_format(size_t numEvents,
                                  char** paths,
                                  const FSEventStreamEventFlags eventFlags[],
                                  const FSEventStreamEventId eventIds[],
                                  TSITStringFormat format)
{
  CFMutableArrayRef events = CFArrayCreateMutable(kCFAllocatorDefault,
                             0, &kCFTypeArrayCallBacks);

  for (size_t i = 0; i < numEvents; i++) {
    CFMutableDictionaryRef event = CFDictionaryCreateMutable(kCFAllocatorDefault,
                                   0,
                                   &kCFTypeDictionaryKeyCallBacks,
                                   &kCFTypeDictionaryValueCallBacks);

    CFStringRef path = CFStringCreateWithBytes(kCFAllocatorDefault,
                       (const UInt8*)paths[i],
                       (CFIndex)strlen(paths[i]),
                       kCFStringEncodingUTF8,
                       false);
    CFDictionarySetValue(event, CFSTR("path"), path);

    CFNumberRef ident = CFNumberCreate(kCFAllocatorDefault, kCFNumberLongLongType, &eventIds[i]);
    CFDictionarySetValue(event, CFSTR("id"), ident);

    CFNumberRef cflags = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &eventFlags[i]);
    CFDictionarySetValue(event, CFSTR("cflags"), cflags);

    CFMutableArrayRef flags = CFArrayCreateMutable(kCFAllocatorDefault,
                              0, &kCFTypeArrayCallBacks);

#define FLAG_ADD_NAME(flagsnum, flagnum, flagname, flagarray)   \
  do {                                                          \
    if (FLAG_CHECK(flagsnum, flagnum)) {                        \
      CFArrayAppendValue(flagarray, CFSTR(flagname)); } }       \
  while(0)

    FLAG_ADD_NAME(eventFlags[i], kFSEventStreamEventFlagMustScanSubDirs,     "MustScanSubDirs", flags);
    FLAG_ADD_NAME(eventFlags[i], kFSEventStreamEventFlagUserDropped,         "UserDropped", flags);
    FLAG_ADD_NAME(eventFlags[i], kFSEventStreamEventFlagKernelDropped,       "KernelDropped", flags);
    FLAG_ADD_NAME(eventFlags[i], kFSEventStreamEventFlagEventIdsWrapped,     "EventIdsWrapped", flags);
    FLAG_ADD_NAME(eventFlags[i], kFSEventStreamEventFlagHistoryDone,         "HistoryDone", flags);
    FLAG_ADD_NAME(eventFlags[i], kFSEventStreamEventFlagRootChanged,         "RootChanged", flags);
    FLAG_ADD_NAME(eventFlags[i], kFSEventStreamEventFlagMount,               "Mount", flags);
    FLAG_ADD_NAME(eventFlags[i], kFSEventStreamEventFlagUnmount,             "Unmount", flags);
    FLAG_ADD_NAME(eventFlags[i], kFSEventStreamEventFlagItemCreated,         "ItemCreated", flags);
    FLAG_ADD_NAME(eventFlags[i], kFSEventStreamEventFlagItemRemoved,         "ItemRemoved", flags);
    FLAG_ADD_NAME(eventFlags[i], kFSEventStreamEventFlagItemInodeMetaMod,    "ItemInodeMetaMod", flags);
    FLAG_ADD_NAME(eventFlags[i], kFSEventStreamEventFlagItemRenamed,         "ItemRenamed", flags);
    FLAG_ADD_NAME(eventFlags[i], kFSEventStreamEventFlagItemModified,        "ItemModified", flags);
    FLAG_ADD_NAME(eventFlags[i], kFSEventStreamEventFlagItemFinderInfoMod,   "ItemFinderInfoMod", flags);
    FLAG_ADD_NAME(eventFlags[i], kFSEventStreamEventFlagItemChangeOwner,     "ItemChangeOwner", flags);
    FLAG_ADD_NAME(eventFlags[i], kFSEventStreamEventFlagItemXattrMod,        "ItemXattrMod", flags);
    FLAG_ADD_NAME(eventFlags[i], kFSEventStreamEventFlagItemIsFile,          "ItemIsFile", flags);
    FLAG_ADD_NAME(eventFlags[i], kFSEventStreamEventFlagItemIsDir,           "ItemIsDir", flags);
    FLAG_ADD_NAME(eventFlags[i], kFSEventStreamEventFlagItemIsSymlink,       "ItemIsSymlink", flags);
    FLAG_ADD_NAME(eventFlags[i], kFSEventStreamEventFlagOwnEvent,            "OwnEvent", flags);
    FLAG_ADD_NAME(eventFlags[i], kFSEventStreamEventFlagItemIsHardlink,      "ItemIsHardLink", flags);
    FLAG_ADD_NAME(eventFlags[i], kFSEventStreamEventFlagItemIsLastHardlink,  "ItemIsLastHardLink", flags);

    CFDictionarySetValue(event, CFSTR("flags"), flags);


    CFArrayAppendValue(events, event);

    CFRelease(event);
    CFRelease(path);
    CFRelease(ident);
    CFRelease(cflags);
    CFRelease(flags);
  }

  CFMutableDictionaryRef meta = CFDictionaryCreateMutable(kCFAllocatorDefault,
                                0,
                                &kCFTypeDictionaryKeyCallBacks,
                                &kCFTypeDictionaryValueCallBacks);
  CFDictionarySetValue(meta, CFSTR("events"), events);

  CFNumberRef num = CFNumberCreate(kCFAllocatorDefault, kCFNumberCFIndexType, &numEvents);
  CFDictionarySetValue(meta, CFSTR("numEvents"), num);

  CFDataRef data = TSICTStringCreateRenderedDataFromObjectWithFormat(meta, format);
  fprintf(stdout, "%s", CFDataGetBytePtr(data));

  CFRelease(events);
  CFRelease(num);
  CFRelease(meta);
  CFRelease(data);
}

static void callback(__attribute__((unused)) FSEventStreamRef streamRef,
                     __attribute__((unused)) void* clientCallBackInfo,
                     size_t numEvents,
                     void* eventPaths,
                     const FSEventStreamEventFlags eventFlags[],
                     const FSEventStreamEventId eventIds[])
{
  char** paths = eventPaths;


#ifdef DEBUG
  fprintf(stderr, "\n");
  fprintf(stderr, "FSEventStreamCallback fired!\n");
  fprintf(stderr, "  numEvents: %lu\n", numEvents);

  for (size_t i = 0; i < numEvents; i++) {
    fprintf(stderr, "\n");
    fprintf(stderr, "  event ID: %llu\n", eventIds[i]);

// STFU clang
#if defined(__LP64__)
    fprintf(stderr, "  event flags: %#.8x\n", eventFlags[i]);
#else
    fprintf(stderr, "  event flags: %#.8lx\n", eventFlags[i]);
#endif

    FLAG_CHECK_STDERR(eventFlags[i], kFSEventStreamEventFlagMustScanSubDirs,
                      "    Recursive scanning of directory required");
    FLAG_CHECK_STDERR(eventFlags[i], kFSEventStreamEventFlagUserDropped,
                      "    Buffering problem: events dropped user-side");
    FLAG_CHECK_STDERR(eventFlags[i], kFSEventStreamEventFlagKernelDropped,
                      "    Buffering problem: events dropped kernel-side");
    FLAG_CHECK_STDERR(eventFlags[i], kFSEventStreamEventFlagEventIdsWrapped,
                      "    Event IDs have wrapped");
    FLAG_CHECK_STDERR(eventFlags[i], kFSEventStreamEventFlagHistoryDone,
                      "    All historical events have been processed");
    FLAG_CHECK_STDERR(eventFlags[i], kFSEventStreamEventFlagRootChanged,
                      "    Root path has changed");
    FLAG_CHECK_STDERR(eventFlags[i], kFSEventStreamEventFlagMount,
                      "    A new volume was mounted at this path");
    FLAG_CHECK_STDERR(eventFlags[i], kFSEventStreamEventFlagUnmount,
                      "    A volume was unmounted from this path");
    FLAG_CHECK_STDERR(eventFlags[i], kFSEventStreamEventFlagItemCreated,
                      "    Item created");
    FLAG_CHECK_STDERR(eventFlags[i], kFSEventStreamEventFlagItemRemoved,
                      "    Item removed");
    FLAG_CHECK_STDERR(eventFlags[i], kFSEventStreamEventFlagItemInodeMetaMod,
                      "    Item metadata modified");
    FLAG_CHECK_STDERR(eventFlags[i], kFSEventStreamEventFlagItemRenamed,
                      "    Item renamed");
    FLAG_CHECK_STDERR(eventFlags[i], kFSEventStreamEventFlagItemModified,
                      "    Item modified");
    FLAG_CHECK_STDERR(eventFlags[i], kFSEventStreamEventFlagItemFinderInfoMod,
                      "    Item Finder Info modified");
    FLAG_CHECK_STDERR(eventFlags[i], kFSEventStreamEventFlagItemChangeOwner,
                      "    Item changed ownership");
    FLAG_CHECK_STDERR(eventFlags[i], kFSEventStreamEventFlagItemXattrMod,
                      "    Item extended attributes modified");
    FLAG_CHECK_STDERR(eventFlags[i], kFSEventStreamEventFlagItemIsFile,
                      "    Item is a file");
    FLAG_CHECK_STDERR(eventFlags[i], kFSEventStreamEventFlagItemIsDir,
                      "    Item is a directory");
    FLAG_CHECK_STDERR(eventFlags[i], kFSEventStreamEventFlagItemIsSymlink,
                      "    Item is a symbolic link");
    FLAG_CHECK_STDERR(eventFlags[i], kFSEventStreamEventFlagItemIsHardlink,
                      "    Item is a hard link");
    FLAG_CHECK_STDERR(eventFlags[i], kFSEventStreamEventFlagItemIsLastHardlink,
                      "    Item is the last hard link");
    fprintf(stderr, "  event path: %s\n", paths[i]);
    fprintf(stderr, "\n");
  }

  fprintf(stderr, "\n");
#endif

  if (config.format == kFSEventWatchOutputFormatClassic) {
    classic_output_format(numEvents, paths);
  } else if (config.format == kFSEventWatchOutputFormatNIW) {
    niw_output_format(numEvents, paths, eventFlags, eventIds);
  } else if (config.format == kFSEventWatchOutputFormatTNetstring) {
    tstring_output_format(numEvents, paths, eventFlags, eventIds,
                          kTSITStringFormatTNetstring);
  } else if (config.format == kFSEventWatchOutputFormatOTNetstring) {
    tstring_output_format(numEvents, paths, eventFlags, eventIds,
                          kTSITStringFormatOTNetstring);
  }

  fflush(stdout);
}

int main(int argc, const char* argv[])
{
  install_signal_handlers();
  parse_cli_settings(argc, argv);

  if (needs_fsevents_fix) {
    FSEventsFixEnable();
  }

  FSEventStreamContext context = {0, NULL, NULL, NULL, NULL};
  FSEventStreamRef stream;
  stream = FSEventStreamCreate(kCFAllocatorDefault,
                               (FSEventStreamCallback)&callback,
                               &context,
                               config.paths,
                               config.sinceWhen,
                               config.latency,
                               config.flags);

#ifdef DEBUG
  FSEventStreamShow(stream);
  fprintf(stderr, "\n");
#endif

  if (needs_fsevents_fix) {
    FSEventsFixDisable();
  }

  FSEventStreamScheduleWithRunLoop(stream,
                                   CFRunLoopGetCurrent(),
                                   kCFRunLoopDefaultMode);
  FSEventStreamStart(stream);
  CFRunLoopRun();
  FSEventStreamFlushSync(stream);
  FSEventStreamStop(stream);

  return 0;
}
