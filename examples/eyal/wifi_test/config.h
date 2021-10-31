#ifndef MY_CONFIG_H
#define MY_CONFIG_H

// Access Point details
#define AP_SSID     "SSID"
#define AP_PASS     "PASS"
#define AP_BSSID    {0x00,0x00,0x00,0x00,0x00,0x00}

// Server to send the UDP packet to
#define SVR_IP      "192.168.3.7"
#define SVR_PORT    41883   // no listener on this port
#define SVR_GW      IPAddress(192, 168, 2, 7)
#define SVR_SUB     IPAddress(255, 255, 255, 0)

// This is what this esp32 will be:
#define CL_IP       IPAddress(192, 168, 2, 91)
#define CL_NAME     "esp-32f"

#endif  // MY_CONFIG_H
