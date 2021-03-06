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
# This set of menubar routines is usable with Tk 4.2
# It is included with bootstrap.tcl at compile-time.
#

proc unameit_set_menubar_type {toplevel_p type} {
    upvar #0 $toplevel_p toplevel_s
    if {[info exists toplevel_s(menubar_type^)]} {
	set old_type $toplevel_s(menubar_type^)
	if {[cequal $old_type $type]} return
	catch {pack forget $toplevel_p.${old_type}_menubar^}
    }
    switch -- $type normal - schema - login {
	pack $toplevel_p.${type}_menubar^ -side top -fill x
    }
    set toplevel_s(menubar_type^) $type
}


### This is a recursive routine that builds up (possibly cascading) menus
proc unameit_add_menu_entry {prefix tree_var id menu_level class2window_var\
	menu_count_var label2class_var id2tuple_var} {
    upvar 1 $class2window_var class2window
    upvar 1 $menu_count_var menu_count
    upvar 1 $tree_var tree
    upvar 1 $id2tuple_var id2tuple
    upvar 1 $label2class_var label2class

    set group [lindex $id2tuple($id) end]
    set group_var [s2w $group]

    ## The top level creates a menubutton. Cascading levels don't.
    if {$menu_level == 0} {
	# Check to see the the menubutton is already created.
	if {![winfo exists $prefix.${group_var}button]} {
	    set menubutton [menubutton $prefix.${group_var}button -text $group\
		    -menu $prefix.${group_var}button.$group_var]
	    unameit_add_wrapper_binding $menubutton
	    # If there is no Special button or we are processing the
	    # Special button, just insert it; otherwise, insert the
	    # button before the Special button.
	    if {[empty [info command $prefix.specialbutton]] ||
	    [cequal ${group_var}button specialbutton]} {
		pack $prefix.${group_var}button -side left
	    } else {
		pack $prefix.${group_var}button -before $prefix.specialbutton\
			-side left
	    }
	}
	# Append the menubutton on the prefix if at the top level.
	set prefix $prefix.${group_var}button
    }

    ## Create the menu if it hasn't been created.
    if {![winfo exists $prefix.$group_var]} {
	menu $prefix.$group_var
    }

    foreach child_id $tree($id) {
	if {[llength $tree($child_id)] == 0} {
	    # No more cascading menus. Create the entry.
	    set label [lindex $id2tuple($child_id) end]

	    set class $label2class($label)
	    set menu_label $label
	    if {[unameit_class_exists $class] &&
	    [unameit_is_readonly $class]} {
		set menu_label <$label>
	    }

	    $prefix.$group_var add command -label $menu_label
	    if {![info exists menu_count($prefix.$group_var)]} {
		set menu_count($prefix.$group_var) 0
	    } else {
		incr menu_count($prefix.$group_var)
	    }
	    set class2window($class)\
		    [list $prefix.$group_var $menu_count($prefix.$group_var)]
	    switch $class {
		Login^ -
		About^ -
		Save^ -
		Preview^ {
		    $prefix.$group_var entryconfigure\
			    $menu_count($prefix.$group_var) -underline 0
		}
	    }
	} else {
	    # Cascading menu. Create the cascade entry and recurse.
	    set next_group [lindex $id2tuple($child_id) end]
	    set next_group_var [s2w $next_group]
	    if {![winfo exists $prefix.$group_var.$next_group_var]} {
		$prefix.$group_var add cascade -label $next_group\
			-menu $prefix.$group_var.$next_group_var
		if {![info exists menu_count($prefix.$group_var)]} {
		    set menu_count($prefix.$group_var) 0
		} else {
		    incr menu_count($prefix.$group_var)
		}
	    }
	    unameit_add_menu_entry $prefix.$group_var tree $child_id\
		    [expr $menu_level+1] class2window menu_count label2class\
		    id2tuple
	}
    }
}

proc unameit_build_menubar {toplevel bar_name menu_data_var class2window_var\
	saved_menu_state_var type} {
    global unameitPriv
    upvar #0 $toplevel toplevel_s
    upvar 1 $menu_data_var menu_data
    upvar 1 $class2window_var class2window
    upvar 1 $saved_menu_state_var saved_menu_state

    set add_schema_menu [cequal schema $type]

    ## Create the top frame for all the menubuttons.
    set menubar [frame $toplevel.$bar_name -relief raised -bd .02i]

    unameit_add_wrapper_binding $menubar

    if {![info exists saved_menu_state]} {
	## Create a path list containing the group and label
	## concatenated together.
	set path_list {}
	foreach class [array names menu_data] {
	    lassign $menu_data($class) group_list label
	    lappend path_list [concat $group_list [list $label]]
	    set label2class($label) $class
	}

	## Sort the paths.
	set ordered_path_list\
		[lsort -command unameit_sort_path_lists $path_list]
	
	set id_counter 0

	## Create a forest of trees
	set saved_menu_state(var_list)\
		[unameit_create_compressed_menu_forest $ordered_path_list\
		id2tuple tuple2id id_counter]

	## Save the menubar information
	set saved_menu_state(id2tuple) [array get id2tuple]
	set saved_menu_state(tuple2id) [array get tuple2id]
	set saved_menu_state(label2class) [array get label2class]
	foreach var $saved_menu_state(var_list) {
	    set saved_menu_state($var) [array get $var]
	}
    }

    ## Restore id2tuple and tuple2id state
    catch {unset id2tuple}
    catch {unset tuple2id}
    catch {unset label2class}
    array set id2tuple $saved_menu_state(id2tuple)
    array set tuple2id $saved_menu_state(tuple2id)
    array set label2class $saved_menu_state(label2class)

    ## Create the menu entries.
    foreach var [lsort -command unameit_sort_top_level_menus\
	    $saved_menu_state(var_list)] {
	# Restore variable state.
	array set $var $saved_menu_state($var)

	if {[cequal $var Schema] && !$add_schema_menu} {
	    continue
	}
	
	unameit_add_menu_entry $menubar $var\
		[unameit_tuple_to_id $var id2tuple tuple2id id_counter]\
		0 class2window menu_count label2class id2tuple
    }
    return $menubar
}

