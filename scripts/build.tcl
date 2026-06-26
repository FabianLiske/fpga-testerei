source [file join [file dirname [info script]] common.tcl]

proc open_template_project {c} {
    set xpr [project_xpr $c]
    if {![file exists $xpr]} {
        fail "Project does not exist: $xpr. Run make project first."
    }
    open_project $xpr
    set_property top [dict get $c top] [current_fileset]
    update_compile_order -fileset sources_1
}

proc report_synth {c} {
    set reports [file join [dict get $c build] reports synth]
    ensure_dir $reports
    report_utilization -file [file join $reports utilization_synth.rpt]
    report_timing_summary -file [file join $reports timing_synth.rpt]
    report_drc -file [file join $reports drc_synth.rpt]
    write_checkpoint -force [file join [dict get $c build] checkpoints "[dict get $c top]_synth.dcp"]
}

proc report_impl {c} {
    set reports [file join [dict get $c build] reports impl]
    ensure_dir $reports
    report_timing_summary -file [file join $reports timing_impl.rpt]
    report_drc -file [file join $reports drc_impl.rpt]
    report_utilization -file [file join $reports utilization_impl.rpt]
    report_power -file [file join $reports power_impl.rpt]
    write_checkpoint -force [file join [dict get $c build] checkpoints "[dict get $c top]_impl.dcp"]
}

proc fail_on_drc {c} {
    set reports [file join [dict get $c build] reports impl]
    ensure_dir $reports
    report_drc -file [file join $reports drc_impl.rpt]
    set bad {}
    foreach violation [get_drc_violations -quiet] {
        set severity [get_property SEVERITY $violation]
        if {$severity eq "Error" || $severity eq "Critical Warning"} {
            lappend bad "$violation ($severity)"
        }
    }
    if {[llength $bad] > 0} {
        puts stderr "DRC violations:"
        foreach item $bad {
            puts stderr "  $item"
        }
        fail "Implementation has DRC violations. See [file join $reports drc_impl.rpt]."
    }
}

proc fail_on_timing {c} {
    set reports [file join [dict get $c build] reports impl]
    ensure_dir $reports
    report_timing_summary -file [file join $reports timing_impl.rpt]
    set paths [get_timing_paths -max_paths 1 -quiet]
    if {[llength $paths] == 0} {
        puts "WARNING: No timing paths found. Continuing for designs without clocked timing paths. See [file join $reports timing_impl.rpt]."
        return
    }
    set worst_slack [get_property SLACK [lindex $paths 0]]
    puts "Worst setup slack: $worst_slack ns"
    if {$worst_slack < 0} {
        fail "Timing failed with worst setup slack $worst_slack ns. See [file join $reports timing_impl.rpt]."
    }
}

proc synth_design_from_project {c} {
    reset_run synth_1
    launch_runs synth_1 -jobs [dict get $c jobs]
    wait_on_run synth_1
    run_finished_ok synth_1
    open_run synth_1 -name synth_1
    report_synth $c
}

proc implement_current_project {c} {
    reset_run impl_1
    launch_runs impl_1 -to_step route_design -jobs [dict get $c jobs]
    wait_on_run impl_1
    run_finished_ok impl_1
    open_run impl_1 -name impl_1
    report_impl $c
    fail_on_drc $c
    fail_on_timing $c
}

proc write_template_bitstream {c} {
    implement_current_project $c
    set output [file join [dict get $c build] output]
    ensure_dir $output
    set dst [file join $output "[dict get $c top].bit"]
    write_bitstream -force $dst
    puts "Bitstream: $dst"
}

proc regenerate_reports {c} {
    set synth_dcp [file join [dict get $c build] checkpoints "[dict get $c top]_synth.dcp"]
    set impl_dcp [file join [dict get $c build] checkpoints "[dict get $c top]_impl.dcp"]

    if {[file exists $synth_dcp]} {
        open_checkpoint $synth_dcp
        report_synth $c
        close_design
    }
    if {[file exists $impl_dcp]} {
        open_checkpoint $impl_dcp
        report_impl $c
        close_design
    }
    if {![file exists $synth_dcp] && ![file exists $impl_dcp]} {
        fail "No checkpoints found under [file join [dict get $c build] checkpoints]. Run make synth or make impl first."
    }
}

set c [cfg]
apply_thread_settings $c
print_config $c
ensure_dir [file join [dict get $c build] checkpoints]
ensure_dir [file join [dict get $c build] reports]
ensure_dir [file join [dict get $c build] output]
open_template_project $c

set stage [dict get $c stage]
switch -- $stage {
    synth { synth_design_from_project $c }
    impl { implement_current_project $c }
    bit { write_template_bitstream $c }
    reports { regenerate_reports $c }
    default { fail "Unknown STAGE=$stage" }
}

close_project
