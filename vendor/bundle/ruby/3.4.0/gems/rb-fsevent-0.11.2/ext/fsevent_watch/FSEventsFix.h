/*
 * FSEventsFix
 *
 * Works around a long-standing bug in realpath() that prevents FSEvents API from
 * monitoring certain folders on a wide range of OS X releases (10.6-10.10 at least).
 *
 * The underlying issue is that for some folders, realpath() call starts returning
 * a path with incorrect casing (e.g. "/users/smt" instead of "/Users/smt").
 * FSEvents is case-sensitive and calls realpath() on the paths you pass in, so
 * an incorrect value returned by realpath() prevents FSEvents from seeing any
 * change events.
 *
 * See the discussion at https://github.com/thibaudgg/rb-fsevent/issues/10 about
 * the history of this bug and how this library came to exist.
 *
 * This library uses Facebook's fishhook to replace a custom implementation of
 * realpath in place of the system realpath; FSEvents will then invoke our custom
 * implementation (which does not screw up the names) and will thus work correctly.
 *
 * Our implementation of realpath is based on the open-source implementation from
 * OS X 10.10, with a single change applied (enclosed in "BEGIN WORKAROUND FOR
 * OS X BUG" ... "END WORKAROUND FOR OS X BUG").
 *
 * Include FSEventsFix.{h,c} into your project and call FSEventsFixInstall().
 *
 * It is recommended that you install FSEventsFix on demand, using FSEventsFixIsBroken
 * to check if the folder you're about to pass to FSEventStreamCreate needs the fix.
 * Note that the fix must be applied before calling FSEventStreamCreate.
 *
 * FSEventsFixIsBroken requires a path that uses the correct case for all folder names,
 * i.e. a path provided by the system APIs or constructed from folder names provided
 * by the directory enumeration APIs.
 *
 * See .c file for license & copyrights, but basically this is available under a mix
 * of MIT and BSD licenses.
 */

#ifndef __FSEventsFix__
#define __FSEventsFix__

#include <CoreFoundation/CoreFoundation.h>

/// A library version string (e.g. 1.2.3) for displaying and logging purposes
extern const char *const FSEventsFixVersionString;

/// See FSEventsFixDebugOptionSimulateBroken
#define FSEventsFixSimulatedBrokenFolderMarker  "__!FSEventsBroken!__"

typedef CF_OPTIONS(unsigned, FSEventsFixDebugOptions) {
    /// Always return an uppercase string from realpath
    FSEventsFixDebugOptionUppercaseReturn  = 0x01,
    
    /// Log all calls to realpath using the logger configured via FSEventsFixConfigure
    FSEventsFixDebugOptionLogCalls         = 0x02,

    /// In addition to the logging block (if any), log everything to stderr
    FSEventsFixDebugOptionLogToStderr      = 0x08,
    
    /// Report paths containing FSEventsFixSimulatedBrokenFolderMarker as broken
    FSEventsFixDebugOptionSimulateBroken   = 0x10,
    
    /// Repair paths containing FSEventsFixSimulatedBrokenFolderMarker by renaming them
    FSEventsFixDebugOptionSimulateRepair   = 0x20,
};

typedef CF_ENUM(int, FSEventsFixMessageType) {
    /// Call logging requested via FSEventsFixDebugOptionLogCalls
    FSEventsFixMessageTypeCall,
    
    /// Results of actions like repair, and other pretty verbose, but notable, stuff.
    FSEventsFixMessageTypeResult,

    /// Enabled/disabled status change
    FSEventsFixMessageTypeStatusChange,

    /// Expected failure (treat as a warning)
    FSEventsFixMessageTypeExpectedFailure,

    /// Severe failure that most likely means that the library won't work
    FSEventsFixMessageTypeFatalError
};

typedef CF_ENUM(int, FSEventsFixRepairStatus) {
    FSEventsFixRepairStatusNotBroken,
    FSEventsFixRepairStatusRepaired,
    FSEventsFixRepairStatusFailed,
};

/// Note that the logging block can be called on any dispatch queue.
void FSEventsFixConfigure(FSEventsFixDebugOptions debugOptions, void(^loggingBlock)(FSEventsFixMessageType type, const char *message));

void FSEventsFixEnable();
void FSEventsFixDisable();

bool FSEventsFixIsOperational();

bool FSEventsFixIsBroken(const char *path);

/// If the path is broken, returns a string identifying the root broken folder,
/// otherwise, returns NULL. You need to free() the returned string.
char *FSEventsFixCopyRootBrokenFolderPath(const char *path);

FSEventsFixRepairStatus FSEventsFixRepairIfNeeded(const char *path);

#endif
