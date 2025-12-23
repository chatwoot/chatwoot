#include "signal_handlers.h"
#include <fcntl.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
#include <unistd.h>


#define PPID_ALARM_INTERVAL 2 // send SIGALRM every this seconds


static pid_t orig_ppid;


static void signal_handler(int _) {
  exit(EXIT_FAILURE);
}

static void check_ppid(void) {
  if (getppid() != orig_ppid) {
    exit(EXIT_FAILURE);
  }
}

static void check_stdout_open(void) {
  if (fcntl(STDOUT_FILENO, F_GETFD) < 0) {
    exit(EXIT_FAILURE);
  }
}

static void alarm_handler(int _) {
  check_ppid();
  check_stdout_open();
  alarm(PPID_ALARM_INTERVAL);
  signal(SIGALRM, alarm_handler);
}

static void die(const char *msg) {
  fprintf(stderr, "\nFATAL: %s\n", msg);
  abort();
}

static void install_signal_handler(int sig, void (*handler)(int)) {
  if (signal(sig, handler) == SIG_ERR) {
    die("Could not install signal handler");
  }
}

void install_signal_handlers(void) {
  // check pipe is still connected
  check_stdout_open();

  // watch getppid() every PPID_ALARM_INTERVAL seconds 
  orig_ppid = getppid();
  if (orig_ppid <= 1) {
    die("prematurely zombied");
  }
  install_signal_handler(SIGALRM, alarm_handler);
  alarm(PPID_ALARM_INTERVAL);

  // be sure to exit on SIGHUP, SIGPIPE
  install_signal_handler(SIGHUP,  signal_handler);
  install_signal_handler(SIGPIPE, signal_handler);
}

