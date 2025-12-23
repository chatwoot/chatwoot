Puma provides three distinct kinds of restart operations, each for different use cases. This document describes "hot restarts" and "phased restarts." The third kind of restart operation is called "refork" and is described in the documentation for [`fork_worker`](fork_worker.md).

## Hot restart

To perform a "hot" restart, Puma performs an `exec` operation to start the process up again, so no memory is shared between the old process and the new process. As a result, it is safe to issue a restart at any place where you would manually stop Puma and start it again. In particular, it is safe to upgrade Puma itself using a hot restart.

If the new process is unable to load, it will simply exit. You should therefore run Puma under a process monitor when using it in production.

### How-to

Any of the following will cause a Puma server to perform a hot restart: 

* Send the `puma` process the `SIGUSR2` signal
* Issue a `GET` request to the Puma status/control server with the path `/restart`
* Issue `pumactl restart` (this uses the control server method if available, otherwise sends the `SIGUSR2` signal to the process)

### Supported configurations

* Works in cluster mode and single mode
* Supported on all platforms

### Client experience

* All platforms: clients with an in-flight request are served responses before the connection is closed gracefully. Puma gracefully disconnects any idle HTTP persistent connections before restarting.
* On MRI or TruffleRuby on Linux and BSD: Clients who connect just before the server restarts may experience increased latency while the server stops and starts again, but their connections will not be closed prematurely.
* On Windows and JRuby: Clients who connect just before a restart may experience "connection reset" errors.

### Additional notes

* The newly started Puma process changes its current working directory to the directory specified by the `directory` option. If `directory` is set to symlink, this is automatically re-evaluated, so this mechanism can be used to upgrade the application.
* Only one version of the application is running at a time.
* `on_restart` is invoked just before the server shuts down. This can be used to clean up resources (like long-lived database connections) gracefully. Since Ruby 2.0, it is not typically necessary to explicitly close file descriptors on restart. This is because any file descriptor opened by Ruby will have the `FD_CLOEXEC` flag set, meaning that file descriptors are closed on `exec`. `on_restart` is useful, though, if your application needs to perform any more graceful protocol-specific shutdown procedures before closing connections.

## Phased restart

Phased restarts replace all running workers in a Puma cluster. This is a useful way to upgrade the application that Puma is serving gracefully. A phased restart works by first killing an old worker, then starting a new worker, waiting until the new worker has successfully started before proceeding to the next worker. This process continues until all workers are replaced. The master process is not restarted.

### How-to

Any of the following will cause a Puma server to perform a phased restart: 

* Send the `puma` process the `SIGUSR1` signal
* Issue a `GET` request to the Puma status/control server with the path `/phased-restart`
* Issue `pumactl phased-restart` (this uses the control server method if available, otherwise sends the `SIGUSR1` signal to the process)

### Supported configurations

* Works in cluster mode only
* To support upgrading the application that Puma is serving, ensure `prune_bundler` is enabled and that `preload_app!` is disabled
* Supported on all platforms where cluster mode is supported

### Client experience

* In-flight requests are always served responses before the connection is closed gracefully
* Idle persistent connections are gracefully disconnected
* New connections are not lost, and clients will not experience any increase in latency (as long as the number of configured workers is greater than one)

### Additional notes

* When a phased restart begins, the Puma master process changes its current working directory to the directory specified by the `directory` option. If `directory` is set to symlink, this is automatically re-evaluated, so this mechanism can be used to upgrade the application.
* On a single server, it's possible that two versions of the application are running concurrently during a phased restart.
* `on_restart` is not invoked
* Phased restarts can be slow for Puma clusters with many workers. Hot restarts often complete more quickly, but at the cost of increased latency during the restart.
* Phased restarts cannot be used to upgrade any gems loaded by the Puma master process, including `puma` itself, anything in `extra_runtime_dependencies`, or dependencies thereof. Upgrading other gems is safe.
* If you remove the gems from old releases as part of your deployment strategy, there are additional considerations. Do not put any gems into `extra_runtime_dependencies` that have native extensions or have dependencies that have native extensions (one common example is `puma_worker_killer` and its dependency on `ffi`). Workers will fail on boot during a phased restart. The underlying issue is recorded in [an issue on the rubygems project](https://github.com/rubygems/rubygems/issues/4004). Hot restarts are your only option here if you need these dependencies.
