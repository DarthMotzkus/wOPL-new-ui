/*
  Copyright 2009, Volca
  Licenced under Academic Free License version 3.0
  Review OpenUsbLd README & LICENSE files for further details.
*/

#include "include/common.h"
#include "include/ioman.h"
#include "include/gui.h"
#include "include/lang.h"
#include "include/pad.h"
#include "include/system.h"
#include "include/extern_irx.h"

#include "include/sound.h"

#include <libpad.h>
#include <libmc.h>

// frame counter
unsigned int frameCounter;

// Global data

int gPS2Logo;
int gDefaultDevice;
int gEnableWrite;
int gRememberLastPlayed;

void reset(void)
{
    sysReset();

    mcInit(MC_TYPE_XMC);
}

void setDefaultColors(void)
{
    gDefaultBgColor[0] = 0x00;
    gDefaultBgColor[1] = 0x00;
    gDefaultBgColor[2] = 0x00;

    gDefaultTextColor[0] = 0xFF;
    gDefaultTextColor[1] = 0xFF;
    gDefaultTextColor[2] = 0xFF;

    gDefaultSelTextColor[0] = 0x00;
    gDefaultSelTextColor[1] = 0x79;
    gDefaultSelTextColor[2] = 0xF5;

    gDefaultUITextColor[0] = 0xB0;
    gDefaultUITextColor[1] = 0xB3;
    gDefaultUITextColor[2] = 0x00;

    gDefaultPlasmaBlendColor[0] = 0x00;
    gDefaultPlasmaBlendColor[1] = 0x00;
    gDefaultPlasmaBlendColor[2] = 0x00;
}