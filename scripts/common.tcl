proc env_default {name default} {
    if {[info exists ::env($name)] && $::env($name) ne ""} {
        return $::env($name)
    }
    return $default
}

proc script_dir {} {
    return [file normalize [file dirname [info script]]]
}

proc repo_root {} {
    return [file normalize [file join [script_dir] ..]]
}

proc cfg {} {
    set root [env_default REPO_ROOT [repo_root]]
    set project_name [env_default PROJECT_NAME [file tail $root]]
    set default_build [file join [env_default HOME $root] build $project_name]
    set build [env_default BUILD $default_build]
    return [dict create \
        repo_root [file normalize $root] \
        build [file normalize $build] \
        project_name $project_name \
        top [env_default TOP top] \
        part [env_default PART xcku3p-ffvb676-1-e] \
        board_part [env_default BOARD_PART tiferking.cn:as02mc04:part0:1.0] \
        board_constraints [env_default BOARD_CONSTRAINTS 1] \
        led_iostandard [env_default LED_IOSTANDARD BOARD] \
        board_auto_ports [env_default BOARD_AUTO_PORTS 1] \
        board_auto_iostandard [env_default BOARD_AUTO_IOSTANDARD NONE] \
        jobs [env_default JOBS 32] \
        hw_freq [env_default HW_FREQ 1000000] \
        stage [env_default STAGE bit] \
        confirm [env_default CONFIRM 0]]
}

proc project_dir {c} {
    return [file join [dict get $c build] project]
}

proc project_xpr {c} {
    return [file join [project_dir $c] "[dict get $c project_name].xpr"]
}

proc ensure_dir {path} {
    if {![file exists $path]} {
        file mkdir $path
    }
}

proc glob_or_empty {pattern} {
    return [glob -nocomplain $pattern]
}

proc fail {message} {
    puts stderr "ERROR: $message"
    exit 1
}

proc apply_thread_settings {c} {
    set requested [dict get $c jobs]
    if {![string is integer -strict $requested]} {
        fail "JOBS must be an integer, got '$requested'."
    }
    if {$requested < 1} {
        fail "JOBS must be >= 1, got '$requested'."
    }

    set max_supported 32
    set effective $requested
    if {$effective > $max_supported} {
        puts "WARNING: Vivado 2025.2.1 accepts general.maxThreads only up to $max_supported; using $max_supported instead of JOBS=$requested."
        set effective $max_supported
    }

    set_param general.maxThreads $effective
    puts "Vivado general.maxThreads: [get_param general.maxThreads]"
    return $effective
}

proc run_finished_ok {run_name} {
    set status [get_property STATUS [get_runs $run_name]]
    puts "$run_name status: $status"
    if {![regexp -nocase {(complete|write_bitstream Complete)} $status]} {
        fail "$run_name did not complete successfully: $status"
    }
}

proc print_config {c} {
    puts "Repository : [dict get $c repo_root]"
    puts "Build      : [dict get $c build]"
    puts "Top        : [dict get $c top]"
    puts "Part       : [dict get $c part]"
    puts "Board part : [dict get $c board_part]"
    puts "Jobs       : [dict get $c jobs]"
}
