# Fork-Worker Cluster Mode [Experimental]

Puma 5 introduces an experimental new cluster-mode configuration option, `fork_worker` (`--fork-worker` from the CLI). This mode causes Puma to fork additional workers from worker 0, instead of directly from the master process:

```
10000   \_ puma 4.3.3 (tcp://0.0.0.0:9292) [puma]
10001       \_ puma: cluster worker 0: 10000 [puma]
10002           \_ puma: cluster worker 1: 10000 [puma]
10003           \_ puma: cluster worker 2: 10000 [puma]
10004           \_ puma: cluster worker 3: 10000 [puma]
```

The `fork_worker` option allows your application to be initialized only once for copy-on-write memory savings, and it has two additional advantages:

1. **Compatible with phased restart.** Because the master process itself doesn't preload the application, this mode works with phased restart (`SIGUSR1` or `pumactl phased-restart`). When worker 0 reloads as part of a phased restart, it initializes a new copy of your application first, then the other workers reload by forking from this new worker already containing the new preloaded application.

   This allows a phased restart to complete as quickly as a hot restart (`SIGUSR2` or `pumactl restart`), while still minimizing downtime by staggering the restart across cluster workers.

2. **'Refork' for additional copy-on-write improvements in running applications.** Fork-worker mode introduces a new `refork` command that re-loads all nonzero workers by re-forking them from worker 0.

   This command can potentially improve memory utilization in large or complex applications that don't fully pre-initialize on startup, because the re-forked workers can share copy-on-write memory with a worker that has been running for a while and serving requests.

   You can trigger a refork by sending the cluster the `SIGURG` signal or running the `pumactl refork` command at any time. A refork will also automatically trigger once, after a certain number of requests have been processed by worker 0 (default 1000). To configure the number of requests before the auto-refork, pass a positive integer argument to `fork_worker` (e.g., `fork_worker 1000`), or `0` to disable.

### Limitations

- This mode is still very experimental so there may be bugs or edge-cases, particularly around expected behavior of existing hooks. Please open a [bug report](https://github.com/puma/puma/issues/new?template=bug_report.md) if you encounter any issues.

- In order to fork new workers cleanly, worker 0 shuts down its server and stops serving requests so there are no open file descriptors or other kinds of shared global state between processes, and to maximize copy-on-write efficiency across the newly-forked workers. This may temporarily reduce total capacity of the cluster during a phased restart / refork.

  In a cluster with `n` workers, a normal phased restart stops and restarts workers one by one while the application is loaded in each process, so `n-1` workers are available serving requests during the restart. In a phased restart in fork-worker mode, the application is first loaded in worker 0 while `n-1` workers are available, then worker 0 remains stopped while the rest of the workers are reloaded one by one, leaving only `n-2` workers to be available for a brief period of time. Reloading the rest of the workers should be quick because the application is preloaded at that point, but there may be situations where it can take longer (slow clients, long-running application code, slow worker-fork hooks, etc).
