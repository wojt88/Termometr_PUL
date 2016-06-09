
# PlanAhead Launch Script for Post-Synthesis pin planning, created by Project Navigator

create_project -name termometr_212467 -dir "F:/termometr_212467/planAhead_run_1" -part xc3s500efg320-4
set_property design_mode GateLvl [get_property srcset [current_run -impl]]
set_property edif_top_file "F:/termometr_212467/termometr.ngc" [ get_property srcset [ current_run ] ]
add_files -norecurse { {F:/termometr_212467} }
set_param project.pinAheadLayout  yes
set_property target_constrs_file "termometr.ucf" [current_fileset -constrset]
add_files [list {termometr.ucf}] -fileset [get_property constrset [current_run]]
link_design
