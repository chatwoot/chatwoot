### 0.6.5 / 2023-07-03

* Corrected the implementation of {Digest::CRC5}.
* Make `digest-crc` Ractor-safe.

### 0.6.4 / 2021-07-14

* Silence potential method redefinition warnings when loading the C extensions.
  (@ojab)

### 0.6.3 / 2020-12-19

* Broaden rake dependency to >= 12.0.0, < 14.0.0` for ruby 2.7, which includes
  rake 13.x.

### 0.6.2 / 2020-12-03

* Lower the rake dependency to `~> 12.0` for ruby 2.6.
* Fixed a bug in `ext/digest/Rakefile` which prevented digest-crc from being
  installed on systems where C extensions could not be successfully compiled.
  * Rake's `ruby` method, which in turn calls rake's `sh` method, raises
    a `RuntimeError` exception when the ruby command fails, causing rake to
    exit with an error code. Instead, rescue any `RuntimeError` exceptions and
    fail gracefully.

### 0.6.1 / 2020-07-02

* Fix installation issues under bundler by adding rake as an explicit dependency
  (@rogerluan).

### 0.6.0 / 2020-07-01

* Implement _optional_ C extensions for all CRC algorithms, resulting in an
  average performance improvement of ~40x. Note, if for whatever reason the
  C extensions cannot be compiled, they will be skipped and the pure-Ruby
  CRC algorithms will be used instead. If the C extensions were successfully
  compiled, then they will be loaded and override the pure-Ruby CRC methods with
  the C equivalents.
* Alias {Digest::CRC16QT} to {Digest::CRC16X25}, since they are effectively the same (@dearblue).
* Fix {Digest::CRC32::WIDTH} (@dearblue).

#### pure-Ruby (ruby 2.7.1)

    Loading Digest::CRC classes ...
    Generating 1000 8Kb lengthed strings ...
    Benchmarking Digest::CRC classes ...
           user     system      total        real
    Digest::CRC1#update  0.412953   0.000000   0.412953 (  0.414688)
    Digest::CRC5#update  1.116375   0.000003   1.116378 (  1.120741)
    Digest::CRC8#update  0.994263   0.000013   0.994276 (  1.001079)
    Digest::CRC8_1Wire#update  0.974115   0.000004   0.974119 (  0.978186)
    Digest::CRC15#update  1.139402   0.000927   1.140329 (  1.146608)
    Digest::CRC16#update  0.967836   0.000000   0.967836 (  0.971792)
    Digest::CRC16CCITT#update  1.118851   0.000000   1.118851 (  1.123217)
    Digest::CRC16DNP#update  0.922211   0.000000   0.922211 (  0.925739)
    Digest::CRC16Genibus#update  1.120580   0.000000   1.120580 (  1.124771)
    Digest::CRC16Modbus#update  0.955612   0.000000   0.955612 (  0.959463)
    Digest::CRC16QT#update  8.153403   0.000012   8.153415 (  8.189977)
    Digest::CRC16USB#update  0.952557   0.000000   0.952557 (  0.956145)
    Digest::CRC16X25#update  0.962295   0.000000   0.962295 (  0.970401)
    Digest::CRC16XModem#update  1.120531   0.000000   1.120531 (  1.124494)
    Digest::CRC16ZModem#update  1.124226   0.000000   1.124226 (  1.128632)
    Digest::CRC24#update  1.126317   0.000000   1.126317 (  1.130794)
    Digest::CRC32#update  0.960015   0.000000   0.960015 (  0.964803)
    Digest::CRC32BZip2#update  1.128626   0.000000   1.128626 (  1.133641)
    Digest::CRC32c#update  0.964047   0.000000   0.964047 (  0.967456)
    Digest::CRC32Jam#update  0.959141   0.000972   0.960113 (  0.967444)
    Digest::CRC32MPEG#update  1.131119   0.000002   1.131121 (  1.137440)
    Digest::CRC32POSIX#update  1.126019   0.000000   1.126019 (  1.130549)
    Digest::CRC32XFER#update  1.116598   0.000000   1.116598 (  1.120595)
    Digest::CRC64#update  2.665880   0.000928   2.666808 (  2.680942)
    Digest::CRC64Jones#update  2.678003   0.000000   2.678003 (  2.691390)
    Digest::CRC64XZ#update  2.671395   0.000000   2.671395 (  2.682684)

#### pure-Ruby (jruby 9.2.11.1)

    Loading Digest::CRC classes ...
    Generating 1000 8Kb lengthed strings ...
    Benchmarking Digest::CRC classes ...
           user     system      total        real
    Digest::CRC1#update  0.700000   0.070000   0.770000 (  0.436112)
    Digest::CRC5#update  1.930000   0.050000   1.980000 (  1.084749)
    Digest::CRC8#update  1.510000   0.060000   1.570000 (  0.979123)
    Digest::CRC8_1Wire#update  0.730000   0.030000   0.760000 (  0.761309)
    Digest::CRC15#update  1.760000   0.080000   1.840000 (  1.061413)
    Digest::CRC16#update  1.560000   0.030000   1.590000 (  0.951273)
    Digest::CRC16CCITT#update  1.700000   0.010000   1.710000 (  1.046854)
    Digest::CRC16DNP#update  1.490000   0.000000   1.490000 (  0.902434)
    Digest::CRC16Genibus#update  1.820000   0.020000   1.840000 (  1.030269)
    Digest::CRC16Modbus#update  0.740000   0.010000   0.750000 (  0.738604)
    Digest::CRC16QT#update  7.280000   0.040000   7.320000 (  6.399987)
    Digest::CRC16USB#update  0.930000   0.000000   0.930000 (  0.801541)
    Digest::CRC16X25#update  0.870000   0.000000   0.870000 (  0.805130)
    Digest::CRC16XModem#update  1.320000   0.010000   1.330000 (  0.968956)
    Digest::CRC16ZModem#update  1.300000   0.010000   1.310000 (  0.928303)
    Digest::CRC24#update  1.550000   0.020000   1.570000 (  1.024450)
    Digest::CRC32#update  1.260000   0.000000   1.260000 (  0.913814)
    Digest::CRC32BZip2#update  1.210000   0.010000   1.220000 (  0.919086)
    Digest::CRC32c#update  0.770000   0.010000   0.780000 (  0.761726)
    Digest::CRC32Jam#update  0.930000   0.000000   0.930000 (  0.800468)
    Digest::CRC32MPEG#update  1.240000   0.010000   1.250000 (  0.933962)
    Digest::CRC32POSIX#update  1.290000   0.010000   1.300000 (  0.925254)
    Digest::CRC32XFER#update  1.270000   0.000000   1.270000 (  0.920521)
    Digest::CRC64#update  3.480000   0.020000   3.500000 (  2.883794)
    Digest::CRC64Jones#update  2.740000   0.000000   2.740000 (  2.738251)
    Digest::CRC64XZ#update  2.780000   0.010000   2.790000 (  2.715833)


#### C extensions (ruby 2.7.1)

    Loading Digest::CRC classes ...
    Generating 1000 8Kb lengthed strings ...
    Benchmarking Digest::CRC classes ...
           user     system      total        real
    Digest::CRC1#update  0.407438   0.000000   0.407438 (  0.410495)
    Digest::CRC5#update  0.022873   0.000000   0.022873 (  0.023796)
    Digest::CRC8#update  0.020129   0.000000   0.020129 (  0.020887)
    Digest::CRC8_1Wire#update  0.020106   0.000000   0.020106 (  0.020897)
    Digest::CRC15#update  0.028765   0.000003   0.028768 (  0.029549)
    Digest::CRC16#update  0.022176   0.000856   0.023032 (  0.023153)
    Digest::CRC16CCITT#update  0.028570   0.000000   0.028570 (  0.028691)
    Digest::CRC16DNP#update  0.023240   0.000001   0.023241 (  0.024008)
    Digest::CRC16Genibus#update  0.028692   0.000000   0.028692 (  0.029575)
    Digest::CRC16Modbus#update  0.023928   0.000000   0.023928 (  0.024859)
    Digest::CRC16QT#update  7.965822   0.000968   7.966790 (  8.001781)
    Digest::CRC16USB#update  0.023448   0.000001   0.023449 (  0.024420)
    Digest::CRC16X25#update  0.023061   0.000000   0.023061 (  0.023861)
    Digest::CRC16XModem#update  0.029407   0.000000   0.029407 (  0.030583)
    Digest::CRC16ZModem#update  0.029522   0.000000   0.029522 (  0.030438)
    Digest::CRC24#update  0.029528   0.000000   0.029528 (  0.030504)
    Digest::CRC32#update  0.023306   0.000000   0.023306 (  0.024278)
    Digest::CRC32BZip2#update  0.026346   0.000000   0.026346 (  0.027293)
    Digest::CRC32c#update  0.023525   0.000000   0.023525 (  0.024489)
    Digest::CRC32Jam#update  0.023348   0.000000   0.023348 (  0.023477)
    Digest::CRC32MPEG#update  0.026287   0.000000   0.026287 (  0.027394)
    Digest::CRC32POSIX#update  0.026063   0.000000   0.026063 (  0.026986)
    Digest::CRC32XFER#update  0.026374   0.000000   0.026374 (  0.027314)
    Digest::CRC64#update  0.023523   0.000000   0.023523 (  0.024484)
    Digest::CRC64Jones#update  0.023479   0.000000   0.023479 (  0.024432)
    Digest::CRC64XZ#update  0.024146   0.000000   0.024146 (  0.025129)

### 0.5.1 / 2020-03-03

* Fixed XOR logic in {Digest::CRC16Genibus}.
* Freeze all `TABLE` constants.
* Added missing documentation.

### 0.5.0 / 2020-03-01

* Added {Digest::CRC15}.
* Added {Digest::CRC16Genibus}.
* Added {Digest::CRC16Kermit}.
* Added {Digest::CRC16X25}.
* Added {Digest::CRC32BZip2}.
* Added {Digest::CRC32Jam}.
* Added {Digest::CRC32POSIX}.
* Added {Digest::CRC32XFER}.
* Added {Digest::CRC64Jones}.
* Added {Digest::CRC64XZ}.
* Renamed `Digest::CRC32Mpeg` to {Digest::CRC32MPEG}.
* Renamed `Digest::CRC81Wire` to {Digest::CRC8_1Wire}.

### 0.4.2 / 2020-03-01

* Corrected the logic in {Digest::CRC32#update}.
* Added missing {Digest::CRC5.pack} method.
* Fixed a require in `digest/crc8_1wire.rb`.

### 0.4.1 / 2014-04-16

* Allow Digest CRC classes to be extended and their constants overriden.
* Allow {Digest::CRC5::CRC_MASK} to be overriden by subclasses.
* {Digest::CRC81Wire} now inherites from {Digest::CRC8}.

### 0.4.0 / 2013-02-13

* Added {Digest::CRC16QT}.

### 0.3.0 / 2011-09-24

* Added {Digest::CRC81Wire} (Henry Garner).

### 0.2.0 / 2011-05-10

* Added {Digest::CRC32c}.
* Opted into [test.rubygems.org](http://test.rubygems.org/)
* Switched from using Jeweler and Bundler, to using
  [Ore::Tasks](http://github.com/ruby-ore/ore-tasks).

### 0.1.0 / 2010-06-01

* Initial release.
  * CRC1
  * CRC5
  * CRC8
  * CRC16
  * CRC16 CCITT
  * CRC16 DNP
  * CRC16 Modbus
  * CRC16 USB
  * CRC16 XModem
  * CRC16 ZModem
  * CRC24
  * CRC32
  * CRC32 Mpeg
  * CRC64
