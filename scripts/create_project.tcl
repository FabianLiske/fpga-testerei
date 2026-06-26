source [file join [file dirname [info script]] common.tcl]
source [file join [file dirname [info script]] board_constraints.tcl]

set c [cfg]
apply_thread_settings $c
print_config $c

set root [dict get $c repo_root]
set build [dict get $c build]
set proj_dir [project_dir $c]
set proj_name [dict get $c project_name]
set part [dict get $c part]
set board_part [dict get $c board_part]
set top [dict get $c top]

ensure_dir $build
ensure_dir $proj_dir

create_project -force $proj_name $proj_dir -part $part
set_property target_language Verilog [current_project]
set_property default_lib xil_defaultlib [current_project]
set_property top $top [current_fileset]

if {[llength [get_board_parts -quiet $board_part]] > 0} {
    set_property board_part $board_part [current_project]
} else {
    puts "WARNING: Board part '$board_part' is not installed. Continuing with PART=$part."
}

set rtl_files [concat \
    [glob_or_empty [file join $root rtl *.sv]] \
    [glob_or_empty [file join $root rtl *.v]] \
    [glob_or_empty [file join $root rtl *.vhd]] \
    [glob_or_empty [file join $root rtl *.vhdl]]]
if {[llength $rtl_files] == 0} {
    fail "No RTL files found under [file join $root rtl]"
}
add_files -fileset sources_1 $rtl_files

if {[dict get $c board_constraints] ne "0"} {
    set generated_xdc [generate_as02mc04_board_xdc $c]
    add_files -fileset constrs_1 $generated_xdc
}

set xdc_files [glob_or_empty [file join $root constraints *.xdc]]
if {[llength $xdc_files] > 0} {
    add_files -fileset constrs_1 $xdc_files
}

set xci_files [glob_or_empty [file join $root ip *.xci]]
if {[llength $xci_files] > 0} {
    import_ip -files $xci_files
    generate_target all [get_ips]
}

update_compile_order -fileset sources_1
set_property top $top [current_fileset]
close_project
puts "Created project: [project_xpr $c]"
