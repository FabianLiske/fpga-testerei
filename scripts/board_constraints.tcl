proc xml_attr {text name {default ""}} {
    set pattern [format {%s="([^"]*)"} $name]
    if {[regexp $pattern $text -> value]} {
        return $value
    }
    return $default
}

proc board_part_file {board_part} {
    set parts [get_board_parts -quiet $board_part]
    if {[llength $parts] == 0} {
        fail "Board part '$board_part' is not installed. Install the board files or set BOARD_CONSTRAINTS=0."
    }
    set file_name [get_property FILE_NAME [lindex $parts 0]]
    if {$file_name eq "" || ![file exists $file_name]} {
        fail "Could not resolve board.xml for board part '$board_part'."
    }
    return [file normalize $file_name]
}

proc board_part_pin_file {board_xml} {
    set fh [open $board_xml r]
    set data [read $fh]
    close $fh

    foreach line [split $data "\n"] {
        if {[string match {*<component*name="part0"*type="fpga"*} $line] ||
            [string match {*<component*type="fpga"*name="part0"*} $line]} {
            set pin_file [xml_attr $line pin_map_file]
            if {$pin_file ne ""} {
                return [file normalize [file join [file dirname $board_xml] $pin_file]]
            }
        }
    }

    set fallback [file normalize [file join [file dirname $board_xml] part0_pins.xml]]
    if {[file exists $fallback]} {
        return $fallback
    }
    fail "Could not find part0 pin map referenced by $board_xml."
}

proc board_clock_frequency {board_xml interface_name default_frequency} {
    set fh [open $board_xml r]
    set data [read $fh]
    close $fh

    set in_interface 0
    foreach line [split $data "\n"] {
        if {[string match "*<interface*name=\"$interface_name\"*" $line]} {
            set in_interface 1
        }
        if {$in_interface && [string match {*<parameter*name="frequency"*} $line]} {
            set value [xml_attr $line value]
            if {$value ne ""} {
                return $value
            }
        }
        if {$in_interface && [string match {*</interface>*} $line]} {
            set in_interface 0
        }
    }
    return $default_frequency
}

proc board_pin_db {pin_xml} {
    if {![file exists $pin_xml]} {
        fail "Board pin map not found: $pin_xml"
    }

    set pins [dict create]
    set fh [open $pin_xml r]
    set data [read $fh]
    close $fh

    foreach line [split $data "\n"] {
        if {![regexp {<pin[[:space:]]} $line]} {
            continue
        }
        set name [xml_attr $line name]
        if {$name eq ""} {
            continue
        }
        set props [dict create]
        set index [xml_attr $line index]
        if {$index ne ""} {
            dict set props index $index
        }
        foreach attr {loc iostandard drive slew dqs_bias} {
            set value [xml_attr $line $attr]
            if {$value ne ""} {
                dict set props $attr $value
            }
        }
        dict set pins $name $props
    }

    return $pins
}

proc require_board_pin {pins name} {
    if {![dict exists $pins $name]} {
        fail "Board pin '$name' is missing from installed board pin map."
    }
    return [dict get $pins $name]
}

proc regexp_escape {text} {
    if {![regexp {^[A-Za-z_][A-Za-z0-9_$]*$} $text]} {
        fail "TOP must be a plain HDL identifier for automatic port detection, got '$text'."
    }
    return $text
}

proc strip_hdl_comments {text} {
    regsub -all {//[^\n\r]*} $text "" text
    regsub -all {/\*([^*]|\*+[^*/])*\*+/} $text "" text
    return $text
}

proc rtl_files_for_ports {root} {
    return [concat \
        [glob_or_empty [file join $root rtl *.sv]] \
        [glob_or_empty [file join $root rtl *.v]]]
}

proc mark_rtl_port {ports_var name range direction} {
    upvar $ports_var ports
    dict set ports $name $direction

    if {[regexp {\[\s*([0-9]+)\s*:\s*([0-9]+)\s*\]} $range -> left right]} {
        set lo [expr {$left < $right ? $left : $right}]
        set hi [expr {$left > $right ? $left : $right}]
        for {set i $lo} {$i <= $hi} {incr i} {
            dict set ports "${name}\[$i\]" $direction
        }
    }
}

proc find_matching_paren {text open_idx} {
    set depth 0
    set len [string length $text]
    for {set i $open_idx} {$i < $len} {incr i} {
        set ch [string index $text $i]
        if {$ch eq "("} {
            incr depth
        } elseif {$ch eq ")"} {
            incr depth -1
            if {$depth == 0} {
                return $i
            }
        }
    }
    return -1
}

proc skip_spaces {text idx} {
    set len [string length $text]
    while {$idx < $len && [string is space [string index $text $idx]]} {
        incr idx
    }
    return $idx
}

proc parse_ansi_module_ports {text top} {
    set ports [dict create]
    set escaped_top [regexp_escape $top]
    set flat [string map {"\n" " " "\r" " " "\t" " "} $text]

    if {![regexp -indices "module\\s+$escaped_top\\s*" $flat match_range]} {
        return $ports
    }
    set search_from [expr {[lindex $match_range 1] + 1}]
    set header_from [skip_spaces $flat $search_from]

    if {[string index $flat $header_from] eq "#"} {
        set param_open [string first "(" $flat $header_from]
        if {$param_open < 0} {
            return $ports
        }
        set param_close [find_matching_paren $flat $param_open]
        if {$param_close < 0} {
            return $ports
        }
        set header_from [skip_spaces $flat [expr {$param_close + 1}]]
    }

    set open_idx [string first "(" $flat $header_from]
    if {$open_idx < 0} {
        return $ports
    }
    set close_idx [find_matching_paren $flat $open_idx]
    set semicolon_idx [skip_spaces $flat [expr {$close_idx + 1}]]
    if {$open_idx < 0 || $close_idx < 0 || $close_idx <= $open_idx || [string index $flat $semicolon_idx] ne ";"} {
        return $ports
    }
    set header [string range $flat [expr {$open_idx + 1}] [expr {$close_idx - 1}]]

    foreach decl [split $header ,] {
        set decl [string trim $decl " ;"]
        if {$decl eq ""} {
            continue
        }
        regsub -all {\(\*.*?\*\)} $decl "" decl
        regsub -all {=} $decl " = " decl
        if {![regexp {^(input|output|inout)(.*)$} $decl -> direction rest]} {
            continue
        }
        set rest [string trim [lindex [split $rest =] 0]]
        set range ""
        if {[regexp {(\[[^]]+\])} $rest -> found_range]} {
            set range $found_range
        }
        if {[regexp {([A-Za-z_][A-Za-z0-9_$]*)\s*$} $rest -> name]} {
            mark_rtl_port ports $name $range $direction
        }
    }

    return $ports
}

proc rtl_top_ports {root top} {
    set ports [dict create]
    foreach file_name [rtl_files_for_ports $root] {
        set fh [open $file_name r]
        set data [strip_hdl_comments [read $fh]]
        close $fh

        set found [parse_ansi_module_ports $data $top]
        if {[dict size $found] > 0} {
            return $found
        }
    }
    return $ports
}

proc port_exists {port} {
    if {[info exists ::as02mc04_top_ports]} {
        return [dict exists $::as02mc04_top_ports $port]
    }
    return [expr {[llength [get_ports -quiet $port]] > 0}]
}

proc port_direction {port} {
    if {[info exists ::as02mc04_top_ports] && [dict exists $::as02mc04_top_ports $port]} {
        return [dict get $::as02mc04_top_ports $port]
    }

    set obj [get_ports -quiet $port]
    if {[llength $obj] > 0} {
        set direction [get_property DIRECTION $obj]
        if {$direction ne ""} {
            return [string tolower $direction]
        }
    }
    return ""
}

proc emit_port_pin_constraint {fh pins board_pin port {iostandard_mode BOARD}} {
    set props [require_board_pin $pins $board_pin]
    if {![dict exists $props loc]} {
        fail "Board pin '$board_pin' has no loc property."
    }
    set direction [port_direction $port]

    puts $fh "## $port <= $board_pin"
    puts $fh "set_property PACKAGE_PIN [dict get $props loc] \[get_ports {$port}\]"

    set io ""
    if {$iostandard_mode eq "BOARD"} {
        if {[dict exists $props iostandard]} {
            set io [dict get $props iostandard]
        }
    } elseif {$iostandard_mode ne "" && $iostandard_mode ne "NONE"} {
        set io $iostandard_mode
    }
    if {$io ne ""} {
        puts $fh "set_property IOSTANDARD $io \[get_ports {$port}\]"
    }

    if {$direction ne "input" && [dict exists $props drive]} {
        puts $fh "set_property DRIVE [dict get $props drive] \[get_ports {$port}\]"
    }
    if {$direction ne "input" && [dict exists $props slew]} {
        puts $fh "set_property SLEW [dict get $props slew] \[get_ports {$port}\]"
    }
    puts $fh ""
}

proc mark_emitted_board_port {emitted_ports_var board_pin port} {
    upvar $emitted_ports_var emitted
    dict set emitted "pin:$board_pin" 1
    dict set emitted "port:$port" 1
}

proc emit_optional_board_port_constraint {fh pins board_pin port {iostandard_mode BOARD} emitted_ports_var} {
    upvar 1 $emitted_ports_var emitted_ports

    if {![port_exists $port]} {
        puts $fh "## Skipped $board_pin => $port; top-level port does not exist in this design."
        puts $fh ""
        return 0
    }

    emit_port_pin_constraint $fh $pins $board_pin $port $iostandard_mode
    mark_emitted_board_port emitted_ports $board_pin $port
    return 1
}

proc emit_optional_clock_constraint {fh port period name} {
    if {![port_exists $port]} {
        puts $fh "## Skipped clock '$name'; top-level port '$port' does not exist in this design."
        puts $fh ""
        return 0
    }

    puts $fh "create_clock -period $period -name $name \[get_ports {$port}\]"
    puts $fh ""
    return 1
}

proc board_pin_sort_key {pins pin_name} {
    set props [dict get $pins $pin_name]
    if {[dict exists $props index] && [string is integer -strict [dict get $props index]]} {
        return [format "%06d:%s" [dict get $props index] $pin_name]
    }
    return "999999:$pin_name"
}

proc sorted_board_pins {pins} {
    set keyed {}
    foreach pin_name [dict keys $pins] {
        lappend keyed [list [board_pin_sort_key $pins $pin_name] $pin_name]
    }

    set names {}
    foreach item [lsort -dictionary -index 0 $keyed] {
        lappend names [lindex $item 1]
    }
    return $names
}

proc emit_pinout_catalog {fh pins} {
    puts $fh "## Board pinout catalog from installed board pin map."
    puts $fh "## Name | Location | IOSTANDARD | DRIVE | SLEW"
    foreach pin_name [sorted_board_pins $pins] {
        set props [dict get $pins $pin_name]
        set loc [expr {[dict exists $props loc] ? [dict get $props loc] : "-"}]
        set io [expr {[dict exists $props iostandard] ? [dict get $props iostandard] : "-"}]
        set drive [expr {[dict exists $props drive] ? [dict get $props drive] : "-"}]
        set slew [expr {[dict exists $props slew] ? [dict get $props slew] : "-"}]
        puts $fh "## $pin_name | $loc | $io | $drive | $slew"
    }
    puts $fh ""
}

proc emit_matching_board_port_constraints {fh pins emitted_ports iostandard_mode} {
    upvar $emitted_ports emitted
    set matched 0

    puts $fh "## Auto constraints for top-level ports named exactly like board pins."
    puts $fh "## BOARD_AUTO_IOSTANDARD=$iostandard_mode; default NONE only emits PACKAGE_PIN/DRIVE/SLEW."
    foreach pin_name [sorted_board_pins $pins] {
        if {[dict exists $emitted "pin:$pin_name"] || [dict exists $emitted "port:$pin_name"]} {
            continue
        }
        if {![port_exists $pin_name]} {
            continue
        }
        emit_port_pin_constraint $fh $pins $pin_name $pin_name $iostandard_mode
        mark_emitted_board_port emitted $pin_name $pin_name
        incr matched
    }
    if {$matched == 0} {
        puts $fh "## No exact board-pin top-level port names found."
        puts $fh ""
    }
}

proc generate_as02mc04_board_xdc {c} {
    set board_xml [board_part_file [dict get $c board_part]]
    set pin_xml [board_part_pin_file $board_xml]
    set pins [board_pin_db $pin_xml]
    set c [dict replace $c board_xml $board_xml pin_xml $pin_xml]
    set ::as02mc04_top_ports [rtl_top_ports [dict get $c repo_root] [dict get $c top]]

    set out_dir [file join [dict get $c build] generated]
    ensure_dir $out_dir
    set xdc [file join $out_dir as02mc04_board.xdc]

    set board_auto_ports [dict get $c board_auto_ports]
    set board_auto_iostandard [dict get $c board_auto_iostandard]
    set emitted_ports [dict create]

    set fh [open $xdc w]
    puts $fh "## Generated by scripts/board_constraints.tcl."
    puts $fh "## Source board file: $board_xml"
    puts $fh "## Source pin map: $pin_xml"
    puts $fh "## Do not edit this file; edit board files or Tcl mapping instead."
    puts $fh ""

    set project_mapping [file join [dict get $c repo_root] constraints board_ports.tcl]
    if {[file exists $project_mapping]} {
        puts $fh "## Project board-port mapping from: $project_mapping"
        puts $fh ""
        source $project_mapping
        if {[info procs emit_project_board_constraints] ne ""} {
            emit_project_board_constraints $fh $pins $c emitted_ports
        } else {
            puts $fh "## No emit_project_board_constraints proc found in $project_mapping."
            puts $fh ""
        }
    } else {
        puts $fh "## No project board-port mapping found at: $project_mapping"
        puts $fh ""
    }

    if {$board_auto_ports ne "0"} {
        emit_matching_board_port_constraints $fh $pins emitted_ports $board_auto_iostandard
    }

    emit_pinout_catalog $fh $pins
    close $fh

    puts "Generated board constraints: $xdc"
    return $xdc
}
