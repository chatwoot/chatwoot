#include "prism/util/pm_string.h"

/**
 * Returns the size of the pm_string_t struct. This is necessary to allocate the
 * correct amount of memory in the FFI backend.
 */
PRISM_EXPORTED_FUNCTION size_t
pm_string_sizeof(void) {
    return sizeof(pm_string_t);
}

/**
 * Initialize a shared string that is based on initial input.
 */
void
pm_string_shared_init(pm_string_t *string, const uint8_t *start, const uint8_t *end) {
    assert(start <= end);

    *string = (pm_string_t) {
        .type = PM_STRING_SHARED,
        .source = start,
        .length = (size_t) (end - start)
    };
}

/**
 * Initialize an owned string that is responsible for freeing allocated memory.
 */
void
pm_string_owned_init(pm_string_t *string, uint8_t *source, size_t length) {
    *string = (pm_string_t) {
        .type = PM_STRING_OWNED,
        .source = source,
        .length = length
    };
}

/**
 * Initialize a constant string that doesn't own its memory source.
 */
void
pm_string_constant_init(pm_string_t *string, const char *source, size_t length) {
    *string = (pm_string_t) {
        .type = PM_STRING_CONSTANT,
        .source = (const uint8_t *) source,
        .length = length
    };
}

#ifdef _WIN32
/**
 * Represents a file handle on Windows, where the path will need to be freed
 * when the file is closed.
 */
typedef struct {
    /** The path to the file, which will become allocated memory. */
    WCHAR *path;

    /** The handle to the file, which will start as uninitialized memory. */
    HANDLE file;
} pm_string_file_handle_t;

/**
 * Open the file indicated by the filepath parameter for reading on Windows.
 * Perform any kind of normalization that needs to happen on the filepath.
 */
static pm_string_init_result_t
pm_string_file_handle_open(pm_string_file_handle_t *handle, const char *filepath) {
    int length = MultiByteToWideChar(CP_UTF8, 0, filepath, -1, NULL, 0);
    if (length == 0) return PM_STRING_INIT_ERROR_GENERIC;

    handle->path = xmalloc(sizeof(WCHAR) * ((size_t) length));
    if ((handle->path == NULL) || (MultiByteToWideChar(CP_UTF8, 0, filepath, -1, handle->path, length) == 0)) {
        xfree(handle->path);
        return PM_STRING_INIT_ERROR_GENERIC;
    }

    handle->file = CreateFileW(handle->path, GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_READONLY, NULL);
    if (handle->file == INVALID_HANDLE_VALUE) {
        pm_string_init_result_t result = PM_STRING_INIT_ERROR_GENERIC;

        if (GetLastError() == ERROR_ACCESS_DENIED) {
            DWORD attributes = GetFileAttributesW(handle->path);
            if ((attributes != INVALID_FILE_ATTRIBUTES) && (attributes & FILE_ATTRIBUTE_DIRECTORY)) {
                result = PM_STRING_INIT_ERROR_DIRECTORY;
            }
        }

        xfree(handle->path);
        return result;
    }

    return PM_STRING_INIT_SUCCESS;
}

/**
 * Close the file handle and free the path.
 */
static void
pm_string_file_handle_close(pm_string_file_handle_t *handle) {
    xfree(handle->path);
    CloseHandle(handle->file);
}
#endif

/**
 * Read the file indicated by the filepath parameter into source and load its
 * contents and size into the given `pm_string_t`. The given `pm_string_t`
 * should be freed using `pm_string_free` when it is no longer used.
 *
 * We want to use demand paging as much as possible in order to avoid having to
 * read the entire file into memory (which could be detrimental to performance
 * for large files). This means that if we're on windows we'll use
 * `MapViewOfFile`, on POSIX systems that have access to `mmap` we'll use
 * `mmap`, and on other POSIX systems we'll use `read`.
 */
PRISM_EXPORTED_FUNCTION pm_string_init_result_t
pm_string_mapped_init(pm_string_t *string, const char *filepath) {
#ifdef _WIN32
    // Open the file for reading.
    pm_string_file_handle_t handle;
    pm_string_init_result_t result = pm_string_file_handle_open(&handle, filepath);
    if (result != PM_STRING_INIT_SUCCESS) return result;

    // Get the file size.
    DWORD file_size = GetFileSize(handle.file, NULL);
    if (file_size == INVALID_FILE_SIZE) {
        pm_string_file_handle_close(&handle);
        return PM_STRING_INIT_ERROR_GENERIC;
    }

    // If the file is empty, then we don't need to do anything else, we'll set
    // the source to a constant empty string and return.
    if (file_size == 0) {
        pm_string_file_handle_close(&handle);
        const uint8_t source[] = "";
        *string = (pm_string_t) { .type = PM_STRING_CONSTANT, .source = source, .length = 0 };
        return PM_STRING_INIT_SUCCESS;
    }

    // Create a mapping of the file.
    HANDLE mapping = CreateFileMapping(handle.file, NULL, PAGE_READONLY, 0, 0, NULL);
    if (mapping == NULL) {
        pm_string_file_handle_close(&handle);
        return PM_STRING_INIT_ERROR_GENERIC;
    }

    // Map the file into memory.
    uint8_t *source = (uint8_t *) MapViewOfFile(mapping, FILE_MAP_READ, 0, 0, 0);
    CloseHandle(mapping);
    pm_string_file_handle_close(&handle);

    if (source == NULL) {
        return PM_STRING_INIT_ERROR_GENERIC;
    }

    *string = (pm_string_t) { .type = PM_STRING_MAPPED, .source = source, .length = (size_t) file_size };
    return PM_STRING_INIT_SUCCESS;
#elif defined(_POSIX_MAPPED_FILES)
    // Open the file for reading
    int fd = open(filepath, O_RDONLY);
    if (fd == -1) {
        return PM_STRING_INIT_ERROR_GENERIC;
    }

    // Stat the file to get the file size
    struct stat sb;
    if (fstat(fd, &sb) == -1) {
        close(fd);
        return PM_STRING_INIT_ERROR_GENERIC;
    }

    // Ensure it is a file and not a directory
    if (S_ISDIR(sb.st_mode)) {
        close(fd);
        return PM_STRING_INIT_ERROR_DIRECTORY;
    }

    // mmap the file descriptor to virtually get the contents
    size_t size = (size_t) sb.st_size;
    uint8_t *source = NULL;

    if (size == 0) {
        close(fd);
        const uint8_t source[] = "";
        *string = (pm_string_t) { .type = PM_STRING_CONSTANT, .source = source, .length = 0 };
        return PM_STRING_INIT_SUCCESS;
    }

    source = mmap(NULL, size, PROT_READ, MAP_PRIVATE, fd, 0);
    if (source == MAP_FAILED) {
        close(fd);
        return PM_STRING_INIT_ERROR_GENERIC;
    }

    close(fd);
    *string = (pm_string_t) { .type = PM_STRING_MAPPED, .source = source, .length = size };
    return PM_STRING_INIT_SUCCESS;
#else
    return pm_string_file_init(string, filepath);
#endif
}

/**
 * Read the file indicated by the filepath parameter into source and load its
 * contents and size into the given `pm_string_t`. The given `pm_string_t`
 * should be freed using `pm_string_free` when it is no longer used.
 */
PRISM_EXPORTED_FUNCTION pm_string_init_result_t
pm_string_file_init(pm_string_t *string, const char *filepath) {
#ifdef _WIN32
    // Open the file for reading.
    pm_string_file_handle_t handle;
    pm_string_init_result_t result = pm_string_file_handle_open(&handle, filepath);
    if (result != PM_STRING_INIT_SUCCESS) return result;

    // Get the file size.
    DWORD file_size = GetFileSize(handle.file, NULL);
    if (file_size == INVALID_FILE_SIZE) {
        pm_string_file_handle_close(&handle);
        return PM_STRING_INIT_ERROR_GENERIC;
    }

    // If the file is empty, then we don't need to do anything else, we'll set
    // the source to a constant empty string and return.
    if (file_size == 0) {
        pm_string_file_handle_close(&handle);
        const uint8_t source[] = "";
        *string = (pm_string_t) { .type = PM_STRING_CONSTANT, .source = source, .length = 0 };
        return PM_STRING_INIT_SUCCESS;
    }

    // Create a buffer to read the file into.
    uint8_t *source = xmalloc(file_size);
    if (source == NULL) {
        pm_string_file_handle_close(&handle);
        return PM_STRING_INIT_ERROR_GENERIC;
    }

    // Read the contents of the file
    DWORD bytes_read;
    if (!ReadFile(handle.file, source, file_size, &bytes_read, NULL)) {
        pm_string_file_handle_close(&handle);
        return PM_STRING_INIT_ERROR_GENERIC;
    }

    // Check the number of bytes read
    if (bytes_read != file_size) {
        xfree(source);
        pm_string_file_handle_close(&handle);
        return PM_STRING_INIT_ERROR_GENERIC;
    }

    pm_string_file_handle_close(&handle);
    *string = (pm_string_t) { .type = PM_STRING_OWNED, .source = source, .length = (size_t) file_size };
    return PM_STRING_INIT_SUCCESS;
#elif defined(PRISM_HAS_FILESYSTEM)
    // Open the file for reading
    int fd = open(filepath, O_RDONLY);
    if (fd == -1) {
        return PM_STRING_INIT_ERROR_GENERIC;
    }

    // Stat the file to get the file size
    struct stat sb;
    if (fstat(fd, &sb) == -1) {
        close(fd);
        return PM_STRING_INIT_ERROR_GENERIC;
    }

    // Ensure it is a file and not a directory
    if (S_ISDIR(sb.st_mode)) {
        close(fd);
        return PM_STRING_INIT_ERROR_DIRECTORY;
    }

    // Check the size to see if it's empty
    size_t size = (size_t) sb.st_size;
    if (size == 0) {
        close(fd);
        const uint8_t source[] = "";
        *string = (pm_string_t) { .type = PM_STRING_CONSTANT, .source = source, .length = 0 };
        return PM_STRING_INIT_SUCCESS;
    }

    size_t length = (size_t) size;
    uint8_t *source = xmalloc(length);
    if (source == NULL) {
        close(fd);
        return PM_STRING_INIT_ERROR_GENERIC;
    }

    long bytes_read = (long) read(fd, source, length);
    close(fd);

    if (bytes_read == -1) {
        xfree(source);
        return PM_STRING_INIT_ERROR_GENERIC;
    }

    *string = (pm_string_t) { .type = PM_STRING_OWNED, .source = source, .length = length };
    return PM_STRING_INIT_SUCCESS;
#else
    (void) string;
    (void) filepath;
    perror("pm_string_file_init is not implemented for this platform");
    return PM_STRING_INIT_ERROR_GENERIC;
#endif
}

/**
 * Ensure the string is owned. If it is not, then reinitialize it as owned and
 * copy over the previous source.
 */
void
pm_string_ensure_owned(pm_string_t *string) {
    if (string->type == PM_STRING_OWNED) return;

    size_t length = pm_string_length(string);
    const uint8_t *source = pm_string_source(string);

    uint8_t *memory = xmalloc(length);
    if (!memory) return;

    pm_string_owned_init(string, memory, length);
    memcpy((void *) string->source, source, length);
}

/**
 * Compare the underlying lengths and bytes of two strings. Returns 0 if the
 * strings are equal, a negative number if the left string is less than the
 * right string, and a positive number if the left string is greater than the
 * right string.
 */
int
pm_string_compare(const pm_string_t *left, const pm_string_t *right) {
    size_t left_length = pm_string_length(left);
    size_t right_length = pm_string_length(right);

    if (left_length < right_length) {
        return -1;
    } else if (left_length > right_length) {
        return 1;
    }

    return memcmp(pm_string_source(left), pm_string_source(right), left_length);
}

/**
 * Returns the length associated with the string.
 */
PRISM_EXPORTED_FUNCTION size_t
pm_string_length(const pm_string_t *string) {
    return string->length;
}

/**
 * Returns the start pointer associated with the string.
 */
PRISM_EXPORTED_FUNCTION const uint8_t *
pm_string_source(const pm_string_t *string) {
    return string->source;
}

/**
 * Free the associated memory of the given string.
 */
PRISM_EXPORTED_FUNCTION void
pm_string_free(pm_string_t *string) {
    void *memory = (void *) string->source;

    if (string->type == PM_STRING_OWNED) {
        xfree(memory);
#ifdef PRISM_HAS_MMAP
    } else if (string->type == PM_STRING_MAPPED && string->length) {
#if defined(_WIN32)
        UnmapViewOfFile(memory);
#elif defined(_POSIX_MAPPED_FILES)
        munmap(memory, string->length);
#endif
#endif /* PRISM_HAS_MMAP */
    }
}
