#include "deepSleep.h"

void
show_state(void)
{
  return;     // disabled

  static char *resetReason_s[] = {
    "REASON_DEFAULT_RST",
    "REASON_WDT_RST",
    "REASON_EXCEPTION_RST",
    "REASON_SOFT_WDT_RST",
    "REASON_SOFT_RESTART",
    "REASON_DEEP_SLEEP_AWAKE",
    "REASON_EXT_SYS_RST"
  };
  static char *wakeMode_s[] = {
    "WAKE_RF_DEFAULT",
    "WAKE_RF_CAL",
    "WAKE_RF_NO_CAL",
    "WAKE_3?",
    "WAKE_RF_DISABLED"
  };
  static char *WiFiMode_s[] = {
    "WIFI_OFF", "WIFI_STA",
    "WIFI_AP", "WIFI_AP_STA"
  };
  static char *WiFiSleepType_s[] = {
    "WIFI_NONE_SLEEP", "1?",
    "WIFI_LIGHT_SLEEP",
    "WIFI_MODEM_SLEEP"
  };
  static char *WiFiPhyMode_s[] = {
    "0?",
    "WIFI_PHY_MODE_11B", 
    "WIFI_PHY_MODE_11G",
    "WIFI_PHY_MODE_11N"
  };
  static char *WiFiStatus_s[] = {
    "WL_IDLE_STATUS",
    "WL_NO_SSID_AVAIL",
    "WL_SCAN_COMPLETED",
    "WL_CONNECTED",
    "WL_CONNECT_FAILED",
    "WL_CONNECTION_LOST",
    "WL_DISCONNECTED"
  };
  static char *stationStatus_s[] = {
    "STATION_IDLE",
    "STATION_CONNECTING",
    "STATION_WRONG_PASSWORD",
    "STATION_NO_AP_FOUND",
    "STATION_CONNECT_FAIL",
    "STATION_GOT_IP"
  };

  uint32_t n;
  const char *s;

  Serial.print("reset_reason=");
    n = system_get_rst_info()->reason; s = n<rangeof(resetReason_s) ? resetReason_s[n] : "";
    Serial.println(s);
  Serial.print(" wakeType=");
    n = rtcMem.wakeType; s = n<rangeof(wakeMode_s) ? wakeMode_s[n] : "";
    Serial.println(s);
  Serial.print(" getMode=");
    n = WiFi.getMode(); s = n<rangeof(WiFiMode_s) ? WiFiMode_s[n] : "";
    Serial.println(s);
  Serial.print(" getSleepMode=");
    n = WiFi.getSleepMode(); s = n<rangeof(WiFiSleepType_s) ? WiFiSleepType_s[n] : "";
    Serial.println(s);
  Serial.print(" getPhyMode=");
    n = WiFi.getPhyMode(); s = n<rangeof(WiFiPhyMode_s) ? WiFiPhyMode_s[n] : "";
    Serial.println(s);
  Serial.print(" wifi status=");
    n = WiFi.status(); s = n<rangeof(WiFiStatus_s) ? WiFiStatus_s[n] : "";
    Serial.println(s);
  Serial.print(" station status=");
    n = wifi_station_get_connect_status(); s = n<rangeof(stationStatus_s) ? stationStatus_s[n] : "";
    Serial.println(s);
}
