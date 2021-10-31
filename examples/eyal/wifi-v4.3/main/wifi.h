#ifndef _WIFI_H
#define _WIFI_H

/* udp.c */
int sent;
int retry_count;
uint64_t time_wifi_us;
int rssi;
int channel;
EventGroupHandle_t event_group;
#define HAVE_WIFI       BIT0
#define NO_WIFI         BIT1

/* wifi.c */
void wifi_send_message (char * message, int mlen);
esp_err_t wifi_setup (void);
esp_err_t wifi_disconnect (void);

#endif // _WIFI_H
