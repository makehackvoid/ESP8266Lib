rtc_magic_address = 188
rtc_magic = 0xbadad0da

misc.rtc_mem_write_int(rtc_magic_address, rtc_magic)
print (string.format("write %08x", rtc_magic))
print (string.format("read %08x", misc.rtc_mem_read_int(rtc_magic_address)))
