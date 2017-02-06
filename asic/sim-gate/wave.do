onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /sancus_sim/mclk
add wave -noupdate -radix hexadecimal /sancus_sim/dut/frontend_0/pc
add wave -noupdate -radix hexadecimal /sancus_sim/dut/execution_unit_0/spm_control_0/omsp_spms_0_/key
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {2621678700 ps} 0}
configure wave -namecolwidth 296
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {2620751800 ps} {2622111200 ps}
