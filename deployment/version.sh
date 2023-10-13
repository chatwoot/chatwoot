# # Compare two semantic versions
# compare_semantic_versions() {
#     local version1="$1"
#     local version2="$2"

#     IFS='.' read -ra v1_parts <<< "$version1"
#     IFS='.' read -ra v2_parts <<< "$version2"

#     for i in {0..2}; do
#         if [[ "${v1_parts[i]}" -lt "${v2_parts[i]}" ]]; then
#             echo "$version2 is newer than $version1"
#             return 1
#         elif [[ "${v1_parts[i]}" -gt "${v2_parts[i]}" ]]; then
#             echo "$version1 is newer than $version2"
#             return 2
#         fi
#     done

#     echo "$version1 and $version2 are equal"
#     return 0
# }

# # Example usage
# compare_semantic_versions "2.1.1" "3.1.0"


# verlte() {
#     [  "$1" = "`echo -e "$1\n$2" | sort -V | head -n1`" ]
# }

# verlt() {
#     [ "$1" = "$2" ] && return 1 || verlte $1 $2
# }

# verlte 2.5.7 2.5.6 && echo "yes" || echo "no" # no
# verlt 2.4.10 2.4.9 && echo "yes" || echo "no" # no
# verlt 2.4.8 2.4.10 && echo "yes" || echo "no" # yes
# verlte 2.5.6 2.5.6 && echo "yes" || echo "no" # yes
# verlt 2.5.6 2.5.6 && echo "yes" || echo "no" # no


#!/bin/bash

# # Function to compare semantic versions using Python
# compare_semantic_versions() {
#     local version1="$1"
#     local version2="$2"

#     python3 - <<END
# from packaging import version
# v1 = version.parse("$version1")
# v2 = version.parse("$version2")

# if v1 > v2:
#     print("$version1 is newer than $version2")
# elif v1 < v2:
#     print("$version2 is newer than $version1")
# else:
#     print("$version1 and $version2 are equal")
# END
# }

# # Example usage
# compare_semantic_versions "2.01.1999" "2.2.2"


#!/bin/bash

# Function to compare semantic versions using Python
compare_semantic_versions() {
    local version1="$1"
    local version2="$2"

    python3 -c "from packaging import version; v1 = version.parse('$version1'); v2 = version.parse('$version2'); print(1 if v2 > v1 else 0)"
}

# Example usage
CWCTL_VERSION="1.1.0"
remote_version="1.1.1"
needs_update=$(compare_semantic_versions "$CWCTL_VERSION" "$remote_version")

if [ "$needs_update" -eq 1 ]; then
    echo "A newer version is available."
else
    echo "Your version is up to date."
fi
