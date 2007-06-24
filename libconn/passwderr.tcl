#
# Copyright (c) 1997 Enterprise Systems Management Corp.
#
# This file is part of UName*It.
#
# UName*It is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 2, or (at your option) any later
# version.
#
# UName*It is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License
# along with UName*It; see the file COPYING.  If not, write to the Free
# Software Foundation, 59 Temple Place - Suite 330, Boston, MA
# 02111-1307, USA.
#

#
# This routine formats an error message in the variable named by vtext.
# The return value indicates whether the error was:
#
#	normal		a user error that has been formatted
#	internal	a unameit error (bug) that has been formatted
#	unknown		a unameit error that could not be handled
#	other		not a unameit error - try another package
#
# The input in arglist is usually the global errorCode.
# The arglist will be:
#
#	UNAMEIT AUTH upasswd symbol args
#
# where error_message is the error text.
#
proc unameit_authorize_errtext_upasswd {vtext arglist} {
    upvar 1 $vtext text

    set arglist [lassign $arglist system subsystem module symbol]
    switch -exact -- $symbol {
	EBADARGS {
	    set text "wrong number of arguments"
	    return internal
	}
	ENOLOGIN {
	    lassign $arglist login
	    set text "Login name or password incorrect.\n"
	    append text "login: $login"
	    return normal
	}
	NOPASSWORD {
	    set text "You must enter a password."
	    return normal
	}
	NONAME {
	    set text "Your login name has not been specified."
	    return normal
	}
    }
    return unknown
}
