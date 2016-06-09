
# PlanAhead Launch Script for Pre-Synthesis Floorplanning, created by Project Navigator

create_project -name termometr_212467 -dir "C:/Users/Student/Documents/212467/termometr_212467/planAhead_run_1" -part xc3s500efg320-4
set_param project.pinAheadLayout yes
set srcset [get_property srcset [current_run -impl]]
set_property target_constrs_file "termometr.ucf" [current_fileset -constrset]
set hdlfile [add_files [list {termometr_212467.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set_property top termometr $srcset
add_files [list {termometr.ucf}] -fileset [get_property constrset [current_run]]
open_rtl_design -part xc3s500efg320-4
