/// -*- tab-width: 4; Mode: C++; c-basic-offset: 4; indent-tabs-mode: nil -*-

/*
 * control_pixycontrol.pde - init and run calls for Pixy Sensor Station Keeping flight mode
 */

// pixycontrol_init - initialise controller
static bool pixycontrol_init(bool ignore_checks)
{

    if (true) {						// Check for PIXY is Healthy - or ignore checks?
        // set target to current position
        wp_nav.init_pixycontrol_target(pixy_error, true);		

        // initialize vertical speed and acceleration
        pos_control.set_speed_z(-g.pilot_velocity_z_max, g.pilot_velocity_z_max);
        pos_control.set_accel_z(g.pilot_accel_z);

        // initialise altitude target to stopping point
        pos_control.set_target_to_stopping_point_z();

        return true;
    }else{
        return false;
    }
}

// pixycontrol_run - runs the loiter controller
// should be called at 100hz or more
static void pixycontrol_run()
{
    float target_yaw_rate = 0;
    float target_climb_rate = 0;

    // if not auto armed set throttle to zero and exit immediately
    if(!ap.auto_armed || !inertial_nav.position_ok()) {
        // set target to current position
        wp_nav.init_pixycontrol_target(pixy_error, true);
		
        attitude_control.relax_bf_rate_controller();
        attitude_control.set_yaw_target_to_current_heading();
        attitude_control.set_throttle_out(0, false);
        pos_control.set_alt_target_to_current_alt();
        return;
    }

    // process pilot inputs
    if (!failsafe.radio) {
        // apply SIMPLE mode transform to pilot inputs
        update_simple_mode();

        // process pilot's roll and pitch input
        wp_nav.set_pilot_desired_acceleration(g.rc_1.control_in, g.rc_2.control_in);

        // get pilot's desired yaw rate
        target_yaw_rate = get_pilot_desired_yaw_rate(g.rc_4.control_in);

        // get pilot desired climb rate
        target_climb_rate = get_pilot_desired_climb_rate(g.rc_3.control_in);

        // check for pilot requested take-off
        if (ap.land_complete && target_climb_rate > 0) {
            // indicate we are taking off
            set_land_complete(false);
            // clear i term when we're taking off
            set_throttle_takeoff();
        }
    } else {
        // clear out pilot desired acceleration in case radio failsafe event occurs and we do not switch to RTL for some reason
        wp_nav.clear_pilot_desired_acceleration();
    }

	// Have removed checks for land complete / maybe landed, should not be landing in this mode

    // run loiter controller
	wp_nav.update_pixycontrol(pixy_error);

    //hal.console->printf_P(PSTR("Roll: %f, Pitch: %f, Yaw: %f\n"), wp_nav.get_roll(), wp_nav.get_pitch(), target_yaw_rate);

    // call attitude controller
    attitude_control.angle_ef_roll_pitch_rate_ef_yaw(wp_nav.get_roll(), wp_nav.get_pitch(), target_yaw_rate);

    // body-frame rate controller is run directly from 100hz loop

    // run altitude controller
    if (sonar_alt_health >= SONAR_ALT_HEALTH_MAX) {
        // if sonar is ok, use surface tracking
        target_climb_rate = get_throttle_surface_tracking(target_climb_rate, pos_control.get_alt_target(), G_Dt);
    }

    // update altitude target and call position controller
    pos_control.set_alt_target_from_climb_rate(target_climb_rate, G_Dt);
    pos_control.update_z_controller();
    
}