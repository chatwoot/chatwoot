/*
 * gvl_wrappers.c - Wrapper functions for locking/unlocking the Ruby GVL
 *
 */

#include "pg.h"

#ifndef HAVE_PQENCRYPTPASSWORDCONN
char *PQencryptPasswordConn(PGconn *conn, const char *passwd, const char *user, const char *algorithm){return NULL;}
#endif

#ifdef ENABLE_GVL_UNLOCK
FOR_EACH_BLOCKING_FUNCTION( DEFINE_GVL_WRAPPER_STRUCT );
FOR_EACH_BLOCKING_FUNCTION( DEFINE_GVL_SKELETON );
#endif
FOR_EACH_BLOCKING_FUNCTION( DEFINE_GVL_STUB );
#ifdef ENABLE_GVL_UNLOCK
FOR_EACH_CALLBACK_FUNCTION( DEFINE_GVL_WRAPPER_STRUCT );
FOR_EACH_CALLBACK_FUNCTION( DEFINE_GVLCB_SKELETON );
#endif
FOR_EACH_CALLBACK_FUNCTION( DEFINE_GVLCB_STUB );
