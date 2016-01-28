// Platform-specific functions

#ifndef __PLATFORM_H__
#define __PLATFORM_H__

#include "pin_map.h"

// Error / status codes
enum
{
  PLATFORM_ERR,
  PLATFORM_OK,
  PLATFORM_UNDERFLOW = -1
};

#define PLATFORM_GPIO_FLOAT 0
#define PLATFORM_GPIO_PULLUP 1

#define PLATFORM_GPIO_INT 2
#define PLATFORM_GPIO_OUTPUT 1
#define PLATFORM_GPIO_INPUT 0

#define PLATFORM_GPIO_HIGH 1
#define PLATFORM_GPIO_LOW 0

#endif /*__PLATFORM_H__*/
