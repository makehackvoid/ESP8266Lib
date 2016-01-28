// Common code for all backends

#include "user_config.h"
#include "common.h"

void cmn_platform_init(void)
{

}

// ****************************************************************************
// GPIO functions

int platform_gpio_exists( unsigned pin )
{
  return pin < NUM_GPIO;
}

// ****************************************************************************
// OneWire functions

int platform_ow_exists( unsigned id )
{
  return ((id < NUM_OW) && (id > 0));
}
