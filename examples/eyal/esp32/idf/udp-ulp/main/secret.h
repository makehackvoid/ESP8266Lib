#ifndef MY_SECRET_H
#define MY_SECRET_H

#if ESP_32g == MY_HOST || ESP_32i == MY_HOST
#define AP_SSID		"SSID1"	// Dell (with Peter)
#define AP_PASS		"PWD1"
#endif

#if 0 && ESP_32k == MY_HOST	// or ESP_32P1
#define AP_SSID		"SSID2"	// HP Compaq (here)
#define AP_PASS		"PWD2"
#endif

#ifndef AP_SSID
#define AP_SSID		"SSID"		// e7
#endif

#ifndef AP_PASS
#define AP_PASS		"PWD"
#endif

#endif	// MY_SECRET_H
