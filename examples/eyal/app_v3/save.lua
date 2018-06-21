local tmr = tmr
local time_Save = done_file (tmr.now())
local mLog = mLog
local sta = wifi.sta
local Rr = rtcmem.read32
local function Log (...) if print_log then mLog ("save", unpack(arg)) end end
local function Trace(n, new) mTrace(7, n, new) end Trace (0, true)
used ()
out_bleep()

local function format_message()
	local failSoft, failHard, failRead, timeLast, timeTotal, timeLeft
		= 0, 0, 0, 0, 0, 0
	if have_rtc_mem then
		failSoft  = Rr(RfailSoft)	-- count
		failHard  = Rr(RfailHard)	-- count
		failRead  = Rr(RfailRead)	-- count
		-- data from prev cycle:
		timeLast  = Rr(RlastTime)	-- us
		timeTotal = Rr(RtotalTime)	-- ms
		timeLeft  = Rr(RtimeLeft)	-- us
		-- also last_trace
	end

	local command = 'store '
	if "mqtt" == save_proto then command = '' end

	local times = ""
	if send_times then
		time_Save = tmr.now() - time_Save
		times = 
(" times=s%.3f,u%.3f,r%.3f,W%.3f,w%.3f,F%.3f,S%.3f,d%.3f,t%.3f prev=L%.3f,l%.3f,T%d,t%x%08x"):format(
			time_start / 1000000,
			time_setup / 1000000,
			time_read / 1000000,
			(time_wifi_ready - time_start) / 1000000,
			time_wifi / 1000000,
			time_First / 1000000,
			time_Save / 1000000,
			time_dofile / 1000000,
			(tmr.now() - time_start) / 1000000,
			-- prev=
			timeLast / 1000000,	-- from prev cycle
			timeLeft / 1000000,	-- from prev cycle
			timeTotal / 1000,	-- from prev cycle
			last_trace_h, last_trace_l)
		if nil ~= rtc_start_s then
			times = ("%s,R%d.%06d"):format(
				times,
				rtc_start_s, rtc_start_u)
		end
	end

	local stats = ""
	if send_stats then
		local reasons = ""
		if send_reason then
--[[
code:
    1 power-on
    2 reset (software?)
    3 hardware reset via reset pin
    4 WDT reset (watchdog timeout)

struct rst_info* ri = system_get_rst_info();
struct rst_info {
	uint32 reason; // enum rst_reason
	uint32 exccause;
	uint32 epc1;  // the address that error occurred
	uint32 epc2;
	uint32 epc3;
	uint32 excvaddr;
	uint32 depc;
};
enum rst_reason {
	REASON_DEFAULT_RST      = 0, // normal startup by power on
	REASON_WDT_RST	        = 1, // hardware watch dog reset 
	// exception reset, GPIO status won't change 
	REASON_EXCEPTION_RST    = 2, 
	// software watch dog reset, GPIO status won't change 
	REASON_SOFT_WDT_RST     = 3, 
	// software restart, system_restart , GPIO status won't change
	REASON_SOFT_RESTART     = 4, 
	REASON_DEEP_SLEEP_AWAKE = 5, // wake up from deep-sleep 
	REASON_EXT_SYS_RST      = 6, // external system reset
};

from esp-open-sdk/xtensa-lx106-elf/xtensa-lx106-elf/sysroot/usr/include/xtensa/corebits.h
/*
 *  General Exception Causes
 *  (values of EXCCAUSE special register set by general exceptions,
 *   which vector to the user, kernel, or double-exception vectors).
 */
#define EXCCAUSE_ILLEGAL		0	/* Illegal Instruction */
#define EXCCAUSE_SYSCALL		1	/* System Call (SYSCALL instruction) */
#define EXCCAUSE_INSTR_ERROR		2	/* Instruction Fetch Error */
#define EXCCAUSE_LOAD_STORE_ERROR	3	/* Load Store Error */
#define EXCCAUSE_LEVEL1_INTERRUPT	4	/* Level 1 Interrupt */
#define EXCCAUSE_ALLOCA			5	/* Stack Extension Assist (MOVSP instruction) for alloca */
#define EXCCAUSE_DIVIDE_BY_ZERO		6	/* Integer Divide by Zero */
#define EXCCAUSE_SPECULATION		7	/* Use of Failed Speculative Access (not implemented) */
#define EXCCAUSE_PRIVILEGED		8	/* Privileged Instruction */
#define EXCCAUSE_UNALIGNED		9	/* Unaligned Load or Store */
/* Reserved				10..11 */
#define EXCCAUSE_INSTR_DATA_ERROR	12	/* PIF Data Error on Instruction Fetch (RB-200x and later) */
#define EXCCAUSE_LOAD_STORE_DATA_ERROR	13	/* PIF Data Error on Load or Store (RB-200x and later) */
#define EXCCAUSE_INSTR_ADDR_ERROR	14	/* PIF Address Error on Instruction Fetch (RB-200x and later) */
#define EXCCAUSE_LOAD_STORE_ADDR_ERROR	15	/* PIF Address Error on Load or Store (RB-200x and later) */
#define EXCCAUSE_ITLB_MISS		16	/* ITLB Miss (no ITLB entry matches, hw refill also missed) */
#define EXCCAUSE_ITLB_MULTIHIT		17	/* ITLB Multihit (multiple ITLB entries match) */
#define EXCCAUSE_INSTR_RING		18	/* Ring Privilege Violation on Instruction Fetch */
/* Reserved				19 */	/* Size Restriction on IFetch (not implemented) */
#define EXCCAUSE_INSTR_PROHIBITED	20	/* Cache Attribute does not allow Instruction Fetch */
/* Reserved				21..23 */
#define EXCCAUSE_DTLB_MISS		24	/* DTLB Miss (no DTLB entry matches, hw refill also missed) */
#define EXCCAUSE_DTLB_MULTIHIT		25	/* DTLB Multihit (multiple DTLB entries match) */
#define EXCCAUSE_LOAD_STORE_RING	26	/* Ring Privilege Violation on Load or Store */
/* Reserved				27 */	/* Size Restriction on Load/Store (not implemented) */
#define EXCCAUSE_LOAD_PROHIBITED	28	/* Cache Attribute does not allow Load */
#define EXCCAUSE_STORE_PROHIBITED	29	/* Cache Attribute does not allow Store */
/* Reserved				30..31 */
#define EXCCAUSE_CP_DISABLED(n)		(32+(n))	/* Access to Coprocessor 'n' when disabled */
#define EXCCAUSE_CP0_DISABLED		32	/* Access to Coprocessor 0 when disabled */
#define EXCCAUSE_CP1_DISABLED		33	/* Access to Coprocessor 1 when disabled */
#define EXCCAUSE_CP2_DISABLED		34	/* Access to Coprocessor 2 when disabled */
#define EXCCAUSE_CP3_DISABLED		35	/* Access to Coprocessor 3 when disabled */
#define EXCCAUSE_CP4_DISABLED		36	/* Access to Coprocessor 4 when disabled */
#define EXCCAUSE_CP5_DISABLED		37	/* Access to Coprocessor 5 when disabled */
#define EXCCAUSE_CP6_DISABLED		38	/* Access to Coprocessor 6 when disabled */
#define EXCCAUSE_CP7_DISABLED		39	/* Access to Coprocessor 7 when disabled */
/*#define EXCCAUSE_FLOATING_POINT	40*/	/* Floating Point Exception (not implemented) */
/* Reserved				40..63 */

code   = rtc_get_reset_reason();
reason = ri.reason;
cause  = ri.exccause;
--]]
			local code, reason, cause = node.bootreason()
			reasons = (",c%d,r%d,C%02d"):format(
				code, reason,
				cause or 99)
		end

		local mems = ""
		if send_mem then
			local mu = mem_used or 0
			local mh = mem_heap or 0
			mems = (",mu%d,mh%d"):format(
				mu,
				mh)
		end

		stats = (" stats=fs%d,fh%d,fr%d%s%s"):format(
			failSoft,
			failHard,
			failRead,
			reasons,
			mems)
	end

	local radio = ""
	if send_radio then
		radio = (" radio=s%d,c%d"):format(
			-sta.getrssi(), wifi.getchannel())
	end

	if not weather then weather = "" end

	local vbat, vdd33
	if adc_factor then	-- cannot read vdd with adc anymore
		if adc_en_pin > 0 then
Log ("reading adc")
			gpio.write(adc_en_pin, gpio.HIGH)
			tmr.delay(1000)	-- 1ms
			vbat = adc.read(0)*adc_factor
			gpio.write(adc_en_pin, gpio.LOW)
		else
			vbat = adc.read(0)*adc_factor
		end
		vdd33 = Rr(RvddLastRead)
	else
		vbat = 0			-- dummy
		vdd33 = adc.readvdd33()*vdd_factor
	end

	local noTemp = 0			-- or 85?
	local tCs
	if 0 == #temp then
		tCs = ("%.4f"):format(noTemp)
	else
		tCs = ""
		local tSep = ""
		for n = 1,#temp do
			tCs = ("%s%s%.4f"):format(tCs, tSep, (temp[n] or noTemp))
			tSep = ","
		end
	end

	return ("%s%s %3d%s%s%s%s adc=%.3f vdd=%.3f %s%s"):format(
		command,
		clientID,
		runCount,
		times,
		stats,
		radio,
		weather,
		vbat / 1000,
		vdd33 / 1000,
		tCs,
		save_eom)
end

if have_rtc_mem then
	rtcmem.write32(RrunCount, runCount)
end

message = format_message()
format_message = nil

if not do_Save then
	Trace (1)
	print_log = true
	Log (message)
	message = nil
	doSleep()
elseif "udp" == save_proto then
	Trace (2)
	do_file("save-udp")
elseif "tcp" == save_proto then
	Trace (3)
	do_file("save-tcp")
elseif "mqtt" == save_proto then
	Trace (4)
	do_file("save-mqtt")
else
	Trace (5)
	pgm = ("save-%s"):format(save_proto)
	if not pcall (function() do_file(pgm, true) end) then
		Trace (6)
		Log ("missing or failing '%s'", pgm)
		Log ("message='%s'", message)
		message = nil
		doSleep()
	end
end

