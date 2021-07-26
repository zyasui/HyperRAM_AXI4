# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "FIXED_LATENCY_MODE" -parent ${Page_0} -widget comboBox
  ipgui::add_param $IPINST -name "LATENCY" -parent ${Page_0} -widget comboBox
  ipgui::add_param $IPINST -name "POWERUP_WAIT_COUNT" -parent ${Page_0}
  ipgui::add_param $IPINST -name "WRAP_BURST_LEN" -parent ${Page_0} -widget comboBox


}

proc update_PARAM_VALUE.ARID_WIDTH { PARAM_VALUE.ARID_WIDTH } {
	# Procedure called to update ARID_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ARID_WIDTH { PARAM_VALUE.ARID_WIDTH } {
	# Procedure called to validate ARID_WIDTH
	return true
}

proc update_PARAM_VALUE.AWID_WIDTH { PARAM_VALUE.AWID_WIDTH } {
	# Procedure called to update AWID_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.AWID_WIDTH { PARAM_VALUE.AWID_WIDTH } {
	# Procedure called to validate AWID_WIDTH
	return true
}

proc update_PARAM_VALUE.FIXED_LATENCY_MODE { PARAM_VALUE.FIXED_LATENCY_MODE } {
	# Procedure called to update FIXED_LATENCY_MODE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.FIXED_LATENCY_MODE { PARAM_VALUE.FIXED_LATENCY_MODE } {
	# Procedure called to validate FIXED_LATENCY_MODE
	return true
}

proc update_PARAM_VALUE.LATENCY { PARAM_VALUE.LATENCY } {
	# Procedure called to update LATENCY when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.LATENCY { PARAM_VALUE.LATENCY } {
	# Procedure called to validate LATENCY
	return true
}

proc update_PARAM_VALUE.POWERUP_WAIT_COUNT { PARAM_VALUE.POWERUP_WAIT_COUNT } {
	# Procedure called to update POWERUP_WAIT_COUNT when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.POWERUP_WAIT_COUNT { PARAM_VALUE.POWERUP_WAIT_COUNT } {
	# Procedure called to validate POWERUP_WAIT_COUNT
	return true
}

proc update_PARAM_VALUE.WRAP_BURST_LEN { PARAM_VALUE.WRAP_BURST_LEN } {
	# Procedure called to update WRAP_BURST_LEN when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.WRAP_BURST_LEN { PARAM_VALUE.WRAP_BURST_LEN } {
	# Procedure called to validate WRAP_BURST_LEN
	return true
}


proc update_MODELPARAM_VALUE.POWERUP_WAIT_COUNT { MODELPARAM_VALUE.POWERUP_WAIT_COUNT PARAM_VALUE.POWERUP_WAIT_COUNT } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.POWERUP_WAIT_COUNT}] ${MODELPARAM_VALUE.POWERUP_WAIT_COUNT}
}

proc update_MODELPARAM_VALUE.LATENCY { MODELPARAM_VALUE.LATENCY PARAM_VALUE.LATENCY } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.LATENCY}] ${MODELPARAM_VALUE.LATENCY}
}

proc update_MODELPARAM_VALUE.FIXED_LATENCY_MODE { MODELPARAM_VALUE.FIXED_LATENCY_MODE PARAM_VALUE.FIXED_LATENCY_MODE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.FIXED_LATENCY_MODE}] ${MODELPARAM_VALUE.FIXED_LATENCY_MODE}
}

proc update_MODELPARAM_VALUE.WRAP_BURST_LEN { MODELPARAM_VALUE.WRAP_BURST_LEN PARAM_VALUE.WRAP_BURST_LEN } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.WRAP_BURST_LEN}] ${MODELPARAM_VALUE.WRAP_BURST_LEN}
}

proc update_MODELPARAM_VALUE.AWID_WIDTH { MODELPARAM_VALUE.AWID_WIDTH PARAM_VALUE.AWID_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.AWID_WIDTH}] ${MODELPARAM_VALUE.AWID_WIDTH}
}

proc update_MODELPARAM_VALUE.ARID_WIDTH { MODELPARAM_VALUE.ARID_WIDTH PARAM_VALUE.ARID_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ARID_WIDTH}] ${MODELPARAM_VALUE.ARID_WIDTH}
}

