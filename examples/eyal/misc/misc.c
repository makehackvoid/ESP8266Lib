// Eyal's misc functions

//#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
#include "platform.h"
#include "auxmods.h"
#include "lrotable.h"

#include "c_types.h"
#include "c_string.h"

#include <osapi.h>

#include "user_version.h"

//#define RTC_USER_MEM_START		256	// bytes, as documented
//#define RTC_USER_MEM_SIZE		512	// bytes
#define RTC_USER_MEM_START		 64	// bytes, as working
#define RTC_USER_MEM_SIZE		128	// bytes

#define RTC_USER_MEM_END		(RTC_USER_MEM_START+RTC_USER_MEM_SIZE)
#define RTC_USER_MEM_BLOCK_SHIFT	2
#define RTC_USER_MEM_BLOCK_SIZE		(1 << RTC_USER_MEM_BLOCK_SHIFT)
#define RTC_USER_MEM_BLOCK_MASK		(RTC_USER_MEM_BLOCK_SIZE - 1)

#define RTC_USER_MEM_ADDR_CHECK(nargs) \
  int _nargs = (nargs); \
  if( _nargs >= 0 && _nargs != lua_gettop( L ) ) \
    return luaL_error( L, "wrong number of arguments" ); \
  uint32_t addr = luaL_checkinteger(L, 1); \
  if (addr < 0 || addr >= 768*2) \
    return luaL_error(L, "bad address [0-767*2]") \
/*if (addr < RTC_USER_MEM_START || addr >= RTC_USER_MEM_END || (addr & RTC_USER_MEM_BLOCK_MASK)) \
    return luaL_error(L, "bad address [4 aligned, 64-124]")*/

static int misc_rtc_mem_read_int(lua_State* L)
{
  uint32_t size;

  RTC_USER_MEM_ADDR_CHECK (-1);

  switch (lua_gettop( L )) {
  case 1:
    size = 4;
    break;
  case 2:
    size = luaL_checkinteger(L, 2);
    if (size < 1 || size > RTC_USER_MEM_BLOCK_SIZE)
    return luaL_error(L, "bad size [1...4]");
    break;
  default:
    return luaL_error(L, "wrong number of arguments");
    break;
  }

  unsigned char block[RTC_USER_MEM_BLOCK_SIZE];
  if (!system_rtc_mem_read((uint8)addr, (void *)block, (uint16)size)) {
//  return luaL_error(L, "rtc memory read failed");
    return 0;
  }
  int nb;
  uint32_t data = 0;
  for (nb = 0; nb < size; ++nb)
    data = (data << 8) + block[nb];

  lua_pushinteger( L, data);
  return 1;
}

static int misc_rtc_mem_write_int(lua_State* L)
{
  uint32_t size, data;

  RTC_USER_MEM_ADDR_CHECK (-1);

  switch (lua_gettop( L )) {
  case 2:
    size = 4;
    data = luaL_checkinteger(L, 2);
    break;
  case 3:
    size = luaL_checkinteger(L, 2);
    if (size < 1 || size > RTC_USER_MEM_BLOCK_SIZE)
      return luaL_error(L, "bad size");

    data = luaL_checkinteger(L, 3);
    break;
  default:
    return luaL_error(L, "wrong number of arguments");
    break;
  }

  unsigned char block[RTC_USER_MEM_BLOCK_SIZE];
  int nb;
  for (nb = size; nb-- > 0;) {
    block[nb] = data & 0x0ff;
    data >>= 8;
  }

  lua_pushboolean( L, system_rtc_mem_write(addr, block, (uint16)size));
  return 1;
}

#undef RTC_USER_MEM_START
#undef RTC_USER_MEM_SIZE
#undef RTC_USER_MEM_END
#undef RTC_USER_MEM_BLOCK_SHIFT
#undef RTC_USER_MEM_BLOCK_SIZE
#undef RTC_USER_MEM_BLOCK_MASK
#undef RTC_USER_MEM_ADDR_CHECK

// Module function map
#define MIN_OPT_LEVEL 2
#include "lrodefs.h"
const LUA_REG_TYPE misc_map[] =
{
  { LSTRKEY( "rtc_mem_read_int" ), LFUNCVAL( misc_rtc_mem_read_int) },
  { LSTRKEY( "rtc_mem_write_int" ), LFUNCVAL( misc_rtc_mem_write_int) },
#if LUA_OPTIMIZE_MEMORY > 0

#endif
  { LNILKEY, LNILVAL }
};

LUALIB_API int luaopen_misc( lua_State *L )
{
#if LUA_OPTIMIZE_MEMORY > 0
  return 0;
#else // #if LUA_OPTIMIZE_MEMORY > 0
  luaL_register( L, AUXLIB_MISC, misc_map );
  // Add constants

  return 1;
#endif // #if LUA_OPTIMIZE_MEMORY > 0
}
