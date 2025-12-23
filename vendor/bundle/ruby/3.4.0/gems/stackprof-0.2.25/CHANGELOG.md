# 0.2.25

* Fix GC marking

# 0.2.16

* [flamegraph.pl] Update to latest version
* Add option to ignore GC frames
* Handle source code not being available
* Freeze strings in report.rb
* Use a cursor object instead of array slicing
* ArgumentError on interval <1 or >1m
* fix variable name.
* Fix default mode comment in readme

# 0.2.15

* Mark the metadata object before the GC is invoked to prevent it from being garbage collected.
