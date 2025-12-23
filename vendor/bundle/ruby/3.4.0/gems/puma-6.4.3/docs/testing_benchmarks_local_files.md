# Testing - benchmark/local files

These files generate data that shows request-per-second (RPS), etc. Typically, files are in 
pairs, a shell script and a Ruby script. The shell script starts the server, then runs the 
Ruby file, which starts client request stream(s), then collects and logs metrics.

## response_time_wrk.sh

This uses [wrk] for generating data. One or more wrk runs are performed. Summarizes RPS and 
wrk latency times. The default for the `-b` argument runs 28 different client request streams, 
and takes a bit over 5 minutes.  See 'Request Stream Configuration' below for `-b` argument
description.

<details>
  <summary>Summary output for<br/><code>benchmarks/local/response_time_wrk.sh -w2 -t5:5 -s tcp6</code>:</summary>

```
Type   req/sec    50%     75%     90%     99%    100%  Resp Size
─────────────────────────────────────────────────────────────────    1kB
array   13710    0.74    2.52    5.23    7.76   37.45      1024
chunk   13502    0.76    2.55    5.28    7.84   11.23      1042
string  13794    0.74    2.51    5.20    7.75   14.07      1024
io       9615    1.16    3.45    7.13   10.57   15.75      1024
─────────────────────────────────────────────────────────────────   10kB
array   13458    0.76    2.57    5.31    7.93   13.94     10239
chunk   13066    0.78    2.64    5.46    8.18   38.48     10320
string  13500    0.76    2.55    5.29    7.88   11.42     10240
io       9293    1.18    3.59    7.39   10.94   16.99     10240
─────────────────────────────────────────────────────────────────  100kB
array   11315    0.96    3.06    6.33    9.49   17.69    102424
chunk    9916    1.10    3.48    7.20   10.73   15.14    103075
string  10948    1.00    3.17    6.57    9.83   17.88    102378
io       8901    1.21    3.72    7.48   11.27   59.98    102407
─────────────────────────────────────────────────────────────────  256kB
array    9217    1.15    3.82    7.88   11.74   17.12    262212
chunk    7339    1.45    4.76    9.81   14.63   22.70    264007
string   8574    1.19    3.81    7.73   11.21   15.80    262147
io       8911    1.19    3.80    7.55   15.25   60.01    262183
─────────────────────────────────────────────────────────────────  512kB
array    6951    1.49    5.03   10.28   15.90   25.08    524378
chunk    5234    2.03    6.56   13.57   20.46   32.15    527862
string   6438    1.55    5.04   10.12   16.28   72.87    524275
io       8533    1.15    4.62    8.79   48.15   70.51    524327
───────────────────────────────────────────────────────────────── 1024kB
array    4122    1.80   15.59   41.87   67.79  121.00   1048565
chunk    3158    2.82   15.22   31.00   71.39   99.90   1055654
string   4710    2.24    6.66   13.65   20.38   70.44   1048575
io       8355    1.23    3.95    7.94   14.08   68.54   1048498
───────────────────────────────────────────────────────────────── 2048kB
array    2454    4.12   14.02   27.70   43.48   88.89   2097415
chunk    1743    6.26   17.65   36.98   55.78   92.10   2111358
string   2479    4.38   12.52   25.65   38.44   95.62   2097502
io       8264    1.25    3.83    7.76   11.73   65.69   2097090

Body    ────────── req/sec ──────────   ─────── req 50% times ───────
 KB     array   chunk  string      io   array   chunk  string      io
1       13710   13502   13794    9615   0.745   0.757   0.741   1.160
10      13458   13066   13500    9293   0.760   0.784   0.759   1.180
100     11315    9916   10948    8901   0.960   1.100   1.000   1.210
256      9217    7339    8574    8911   1.150   1.450   1.190   1.190
512      6951    5234    6438    8533   1.490   2.030   1.550   1.150
1024     4122    3158    4710    8355   1.800   2.820   2.240   1.230
2048     2454    1743    2479    8264   4.120   6.260   4.380   1.250
─────────────────────────────────────────────────────────────────────
wrk -t8 -c16 -d10s
benchmarks/local/response_time_wrk.sh -w2 -t5:5 -s tcp6 -Y
Server cluster mode -w2 -t5:5, bind: tcp6
Puma repo branch 00-response-refactor
ruby 3.2.0dev (2022-06-14T01:21:55Z master 048f14221c) +YJIT [x86_64-linux]

[2136] - Gracefully shutting down workers...
[2136] === puma shutdown: 2022-06-13 21:16:13 -0500 ===
[2136] - Goodbye!

 5:15 Total Time
```
</details><br/>

## bench_base.sh, bench_base.rb

These two files setup parameters for the Puma server, which is normally started in a shell 
script. It then starts a Ruby file (a subclass of BenchBase), passing arguments to it. The 
Ruby file is normally used to generate a client request stream(s).

### Puma Configuration

The following arguments are used for the Puma server:

* **`-C`** - configuration file
* **`-d`** - app delay
* **`-r`** - rackup file, often defaults to test/rackup/ci_select.ru
* **`-s`** - bind socket type, default is tcp/tcp4, also tcp6, ssl/ssl4, ssl6, unix, or aunix
  (unix & abstract unix are not available with wrk).
* **`-t`** - threads, expressed as '5:5', same as Puma --thread
* **`-w`** - workers, same as Puma --worker
* **`-Y`** - enable Ruby YJIT

### Request Stream Configuration

The following arguments are used for request streams:

* **`-b`** - response body configuration. Body type options are a array, c chunked, s string,
  and i for File/IO. None or any combination can be specified, they should start the option.
  Then, any combination of comma separated integers can be used for the response body size
  in kB. The string 'ac50,100' would create four runs, 50kb array, 50kB chunked, 100kB array,
  and 100kB chunked. See 'Testing - test/rackup/ci-*.ru files' for more info.
* **`-c`** - connections per client request stream thread, defaults to 2 for wrk.
* **`-D`** - duration of client request stream in seconds.
* **`-T`** - number of threads in the client request stream. For wrk, this defaults to
  80% of Puma workers * max_threads.

### Notes - Configuration

The above lists script arguments.

`bench_base.sh` contains most server defaults. Many can be set via ENV variables.

`bench_base.rb` contains the client request stream defaults. The default value for
`-b` is `acsi1,10,100,256,512,1024,2048`, which is a 4 x 7 matrix, and hence, runs
28 jobs. Also, the i body type (File/IO) generates files, they are placed in the
`"#{Dir.tmpdir}/.puma_response_body_io"` directory, which is created.

### Notes - wrk

The shell scripts use `-T` for wrk's thread count, since `-t` is used for Puma
server threads.  Regarding the `-c` argument, wrk has an interesting behavior.
The total number of connections is set by `(connections/threads).to_i`. The scripts
here use `-c` as connections per thread.  Hence, using `-T4 -c2` will yield a total
of eight wrk connections, two per thread. The equivalent wrk arguments would be `-t4 -c8`.

Puma can only process so many requests, and requests will queue in the backlog
until Puma can respond to them. With wrk, if the number of total connections is
too high, one will see the upper latency times increase, pushing into the lower
latency times as the connections are increased. The default values for wrk's
threads and connections were chosen to minimize requests' time in the backlog.

An example with four wrk runs using `-b s10`.  Notice that `req/sec` varies by
less than 1%, but the `75%` times increase by an order of magnitude:
```
req/sec    50%     75%     90%     99%    100%  Resp Size   wrk cmd line
─────────────────────────────────────────────────────────────────────────────
 13597   0.755   2.550   5.260   7.800  13.310     12040    wrk -t8  -c16 -d10
 13549   0.793   4.430   8.140  11.220  16.600     12002    wrk -t10 -c20 -d10
 13570   1.040  25.790  40.010  49.070  58.300     11982    wrk -t8  -c64 -d10
 13684   1.050  25.820  40.080  49.160  66.190     12033    wrk -t16 -c64 -d10
```
Finally, wrk's output may cause rounding errors, so the response body size calculation is
imprecise.

[wrk]: <https://github.com/ioquatix/wrk>
