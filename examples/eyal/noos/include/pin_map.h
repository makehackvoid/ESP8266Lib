#ifndef __PIN_MAP_H__
#define __PIN_MAP_H__

#define GPIO_PIN_NUM 13

extern const uint8_t pin_num[GPIO_PIN_NUM];
extern const uint8_t pin_func[GPIO_PIN_NUM];
extern const uint32_t pin_mux[GPIO_PIN_NUM];

// Number of resources (0 if not available/not implemented)
#define NUM_GPIO              GPIO_PIN_NUM
#define NUM_SPI               2
#define NUM_UART              1
#define NUM_PWM               GPIO_PIN_NUM
#define NUM_ADC               1
#define NUM_CAN               0
#define NUM_I2C               1
#define NUM_OW                GPIO_PIN_NUM
#define NUM_TMR               7

#endif // #ifndef __PIN_MAP_H__
