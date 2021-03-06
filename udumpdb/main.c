/*
 * Copyright (c) 1997 Enterprise Systems Management Corp.
 *
 * This file is part of UName*It.
 *
 * UName*It is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free
 * Software Foundation; either version 2, or (at your option) any later
 * version.
 *
 * UName*It is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
 * for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with UName*It; see the file COPYING.  If not, write to the Free
 * Software Foundation, 59 Temple Place - Suite 330, Boston, MA
 * 02111-1307, USA.
 */
static char rcsid[] = "$Id: main.c,v 1.13.20.3 1997/09/21 23:43:01 viktor Exp $";

#include <uconfig.h>
#include <unameit_init.h>
#include "bootstrap.h"

/*
 * All the packages that are statically linked against unameitd should
 * go in the list below.
 */
static struct Inits
    {
	char			*pkg;
	Tcl_PackageInitProc	*pkg_init;
	Tcl_PackageInitProc	*pkg_safe_init;
	int			init_now;
    }
    inits[] =
    {
	{"Tclx", Tclx_Init, Tclx_SafeInit, 1},
	{"Uclient", Uclient_Init, NULL, 1},
	{"Auth", Auth_Init, Auth_Init, 1},
	{NULL, NULL, NULL, 0}
    };


static int
AppInit(Tcl_Interp *interp)
{
    struct Inits	*initPtr;
    char		**procdef;

    assert(interp);

    /*
     * The "Tcl" Package is special.  It should not be registered as
     * a loadable package.
     */
    if (Tcl_Init(interp) != TCL_OK)
    {
	return TCL_ERROR;
    }

    for (initPtr = inits; initPtr->pkg; initPtr++)
    {
	if (initPtr->init_now && initPtr->pkg_init(interp) != TCL_OK)
	{
	    return TCL_ERROR;
	}
	Tcl_StaticPackage(initPtr->init_now ? interp : NULL,
			  initPtr->pkg,
			  initPtr->pkg_init,
			  initPtr->pkg_safe_init);
    }

    for (procdef = bootstrap; *procdef; ++procdef)
    {
	if (Tcl_Eval(interp, *procdef) != TCL_OK)
	    return TCL_ERROR;
    }
    return TCL_OK;
}


int
main(int argc, char *argv[])
{
    int  new_argc;
    char **new_argv;
    char **sp;

    new_argc = argc + 2;
    new_argv = (char **)ckalloc((new_argc+1) * sizeof(char *));
    new_argv[0] = argv[0];
    new_argv[1] = "-nc";
    new_argv[2] = "unameit_start";

    for(sp = &new_argv[2]; argc--;)
    {
	*++sp = *++argv;
    }
    TclX_Main(new_argc, new_argv, AppInit);
    /*
     * We should not really get here
     */
    ckfree((char *)new_argv);
    exit(1);
}
