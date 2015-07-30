/// -*- tab-width: 4; Mode: C++; c-basic-offset: 4; indent-tabs-mode: nil -*-

// user defined variables

// example variables used in Wii camera testing - replace with your own
// variables
#ifdef USERHOOK_VARIABLES

#if WII_CAMERA == 1
WiiCamera           ircam;
int                 WiiRange=0;
int                 WiiRotation=0;
int                 WiiDisplacementX=0;
int                 WiiDisplacementY=0;
#endif  // WII_CAMERA

#define LOG_PIXY_MSG 0x20

struct PACKED log_Pixy {
    LOG_PACKET_HEADER;
    int16_t signature;
    int16_t center_x;
    int16_t center_y;
    int16_t width;
    int16_t height;  
};

Vector3f pixy_error;

#endif  // USERHOOK_VARIABLES


