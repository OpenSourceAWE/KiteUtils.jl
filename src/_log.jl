"""
    log!(logger::Logger, state::SysState)

Log a state in a logger object. Do nothing if the preallocated size would be exceeded.
Returns the current number of elements of the log.
"""
function log!(logger::Logger, state::SysState)
    i = logger.index
    if i > length(logger.time_vec)
        return length(logger.time_vec)
    end
    logger.time_vec[i] = state.time
    logger.t_sim_vec[i] = state.t_sim
    logger.sys_state_vec[i] = state.sys_state
    logger.e_mech_vec[i] = state.e_mech
    logger.orient_vec[i] .= state.orient
    logger.elevation_vec[i] = state.elevation
    logger.azimuth_vec[i] = state.azimuth
    logger.l_tether_vec[i] = state.l_tether
    logger.v_reelout_vec[i] = state.v_reelout
    logger.force_vec[i] = state.force
    logger.depower_vec[i] = state.depower
    logger.steering_vec[i] = state.steering
    logger.heading_vec[i] = state.heading
    logger.course_vec[i] = state.course
    logger.v_app_vec[i] = state.v_app
    logger.v_wind_gnd_vec[i] .= state.v_wind_gnd
    logger.v_wind_200m_vec[i] .= state.v_wind_200m
    logger.v_wind_kite_vec[i] .= state.v_wind_kite
    logger.vel_kite_vec[i] .= state.vel_kite
    logger.X_vec[i] .= state.X
    logger.Y_vec[i] .= state.Y
    logger.Z_vec[i] .= state.Z
    logger.var_01_vec[i] = state.var_01
    logger.var_02_vec[i] = state.var_02
    logger.var_03_vec[i] = state.var_03
    logger.var_04_vec[i] = state.var_04
    logger.var_05_vec[i] = state.var_05
    logger.var_06_vec[i] = state.var_06
    logger.var_07_vec[i] = state.var_07
    logger.var_08_vec[i] = state.var_08
    logger.var_09_vec[i] = state.var_09
    logger.var_10_vec[i] = state.var_10
    logger.var_11_vec[i] = state.var_11
    logger.var_12_vec[i] = state.var_12
    logger.var_13_vec[i] = state.var_13
    logger.var_14_vec[i] = state.var_14
    logger.var_15_vec[i] = state.var_15
    logger.var_16_vec[i] = state.var_16
    logger.index+=1
    return i
end