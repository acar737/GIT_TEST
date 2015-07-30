/// -*- tab-width: 4; Mode: C++; c-basic-offset: 4; indent-tabs-mode: nil -*-

#define XCENTRE 154.5f
#define YCENTRE 101
#define MXPIXCONV 0.0043f
#define CXPIXCONV 0.00f
#define MYPIXCONV 0.0042f
#define CYPIXCONV 0.00f

/// Write a Pixy packet
static void Log_Write_Pixy(int16_t signature, int16_t center_x, int16_t center_y, int16_t width, int16_t height)
{
    struct log_Pixy pkt = {
        LOG_PACKET_HEADER_INIT(LOG_PIXY_MSG),
        signature		  : signature,
		center_x		  : center_x,
		center_y          : center_y,
		width			  : width,
		height			  : height
    };
    DataFlash.WriteBlock(&pkt, sizeof(pkt));
}

static Vector3f get_irlock(uint16_t signature)
{
    static uint32_t last_of_update = 0;

    Vector3f position = {0, 0, 0};

    if (!irlock.enabled()) //remove this and add as check for init
        return position;

    irlock.update();

    if (irlock.last_update() != last_of_update) {

        last_of_update = irlock.last_update();

        irlock_block frame[IRLOCK_MAX_BLOCKS_PER_FRAME]; 
        irlock.get_current_frame(frame);

        for (int i = 0; (int)i < (int)irlock.num_blocks(); ++i) {

            if ( frame[i].signature == signature )
            {
                // Set position to Pixy output - subtract offsets to centre origin
                position.y = model_Y(frame[i].center_y, current_loc.alt);
                position.x = model_X(frame[i].center_x, current_loc.alt);
                position.z = 0.0;
				
				// Turn Output LED On
				//relay.on(0);

                hal.console->printf_P(PSTR("POSITION: %f, %f, %f\n"), position.x, position.y, position.z);
                //Log_Write_Pixy(frame[i].signature, position.x, position.y , frame[i].width, frame[i].height);
            } else{
				// Turn Output LED Off
				//relay.off(0);
			}
			Log_Write_Pixy(frame[i].signature, position.x, position.y, frame[i].width, frame[i].height); // Testing how often zeros / no position is recorded
        }
    }

    return position;
}

float model_X(int raw_x, int curr_alt)
{
    // Calculate corresponding Angle from centre of lens:
    float obj_angle = MXPIXCONV * (raw_x - XCENTRE) + CXPIXCONV;
    // Calculate lateral distance using depth and angle:
    return (curr_alt * tan(obj_angle));
}

float model_Y(int raw_y, int curr_alt)
{
    // Calculate corresponding Angle from centre of lens:
    float obj_angle = MYPIXCONV * (raw_y - YCENTRE) - CYPIXCONV;
    // Calculate lateral distance using depth and angle:
	return (curr_alt * tan(obj_angle));
}

#ifdef USERHOOK_INIT
void userhook_init()
{
    // put your initialisation code here
    // this will be called once at start-up
    init_irlock();
	
	// Initialise and Calibrate Airspeed Sensor
	airspeed.init();
	airspeed.calibrate(false);
	
}
#endif

#ifdef USERHOOK_FASTLOOP
void userhook_FastLoop()
{
    // put your 100Hz code here
}
#endif

#ifdef USERHOOK_50HZLOOP
void userhook_50Hz()
{
    // put your 50Hz code here
    pixy_error = get_irlock(1);
	
}
#endif

#ifdef USERHOOK_MEDIUMLOOP
void userhook_MediumLoop()
{
    // put your 10Hz code here
    
    //Vector3f pixy_error;   

    //get_irlock(1, pixy_error);

    //hal.console->printf("\n");

    //hal.console->printf_P(PSTR("x = %f, y = %f, z = %f\n"), pixy_error.x, pixy_error.y, pixy_error.z);
	
	airspeed.read();
	float temp_air_speed = airspeed.get_airspeed();
	hal.console->printf_P(PSTR("Air Speed = %f \n"), temp_air_speed);
	
}
#endif

#ifdef USERHOOK_SLOWLOOP
void userhook_SlowLoop()
{
    // put your 3.3Hz code here
}
#endif

#ifdef USERHOOK_SUPERSLOWLOOP
void userhook_SuperSlowLoop() 
{
    // put your 1Hz code here

    //pixycontrol_run();
}
#endif
