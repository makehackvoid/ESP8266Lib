#include "user_config.h"

#define GPIO_Pin_0              (BIT(0))  /* Pin 0 selected */
#define GPIO_Pin_1              (BIT(1))  /* Pin 1 selected */
#define GPIO_Pin_2              (BIT(2))  /* Pin 2 selected */
#define GPIO_Pin_3              (BIT(3))  /* Pin 3 selected */
#define GPIO_Pin_4              (BIT(4))  /* Pin 4 selected */
#define GPIO_Pin_5              (BIT(5))  /* Pin 5 selected */
#define GPIO_Pin_6              (BIT(6))  /* Pin 6 selected */
#define GPIO_Pin_7              (BIT(7))  /* Pin 7 selected */
#define GPIO_Pin_8              (BIT(8))  /* Pin 8 selected */
#define GPIO_Pin_9              (BIT(9))  /* Pin 9 selected */
#define GPIO_Pin_10             (BIT(10)) /* Pin 10 selected */
#define GPIO_Pin_11             (BIT(11)) /* Pin 11 selected */
#define GPIO_Pin_12             (BIT(12)) /* Pin 12 selected */
#define GPIO_Pin_13             (BIT(13)) /* Pin 13 selected */
#define GPIO_Pin_14             (BIT(14)) /* Pin 14 selected */
#define GPIO_Pin_15             (BIT(15)) /* Pin 15 selected */
#define GPIO_Pin_All            (0xFFFF)  /* All pins selected */

#define GPIO_PIN_REG_0          PERIPHS_IO_MUX_GPIO0_U
#define GPIO_PIN_REG_1          PERIPHS_IO_MUX_U0TXD_U
#define GPIO_PIN_REG_2          PERIPHS_IO_MUX_GPIO2_U
#define GPIO_PIN_REG_3          PERIPHS_IO_MUX_U0RXD_U
#define GPIO_PIN_REG_4          PERIPHS_IO_MUX_GPIO4_U
#define GPIO_PIN_REG_5          PERIPHS_IO_MUX_GPIO5_U
#define GPIO_PIN_REG_6          PERIPHS_IO_MUX_SD_CLK_U
#define GPIO_PIN_REG_7          PERIPHS_IO_MUX_SD_DATA0_U
#define GPIO_PIN_REG_8          PERIPHS_IO_MUX_SD_DATA1_U
#define GPIO_PIN_REG_9          PERIPHS_IO_MUX_SD_DATA2_U
#define GPIO_PIN_REG_10         PERIPHS_IO_MUX_SD_DATA3_U
#define GPIO_PIN_REG_11         PERIPHS_IO_MUX_SD_CMD_U
#define GPIO_PIN_REG_12         PERIPHS_IO_MUX_MTDI_U
#define GPIO_PIN_REG_13         PERIPHS_IO_MUX_MTCK_U
#define GPIO_PIN_REG_14         PERIPHS_IO_MUX_MTMS_U
#define GPIO_PIN_REG_15         PERIPHS_IO_MUX_MTDO_U

#define GPIO_PIN_REG(i) \
    (i==0) ? GPIO_PIN_REG_0:  \
    (i==1) ? GPIO_PIN_REG_1:  \
    (i==2) ? GPIO_PIN_REG_2:  \
    (i==3) ? GPIO_PIN_REG_3:  \
    (i==4) ? GPIO_PIN_REG_4:  \
    (i==5) ? GPIO_PIN_REG_5:  \
    (i==6) ? GPIO_PIN_REG_6:  \
    (i==7) ? GPIO_PIN_REG_7:  \
    (i==8) ? GPIO_PIN_REG_8:  \
    (i==9) ? GPIO_PIN_REG_9:  \
    (i==10)? GPIO_PIN_REG_10: \
    (i==11)? GPIO_PIN_REG_11: \
    (i==12)? GPIO_PIN_REG_12: \
    (i==13)? GPIO_PIN_REG_13: \
    (i==14)? GPIO_PIN_REG_14: \
    GPIO_PIN_REG_15

#define GPIO_PIN_ADDR(i)        (GPIO_PIN0_ADDRESS + i*4)

#define GPIO_ID_IS_PIN_REGISTER(reg_id) \
    ((reg_id >= GPIO_ID_PIN0) && (reg_id <= GPIO_ID_PIN(GPIO_PIN_COUNT-1)))

#define GPIO_REGID_TO_PINIDX(reg_id) ((reg_id) - GPIO_ID_PIN0)

#if 000
typedef enum {
    GPIO_PIN_INTR_DISABLE = 0,      /**< disable GPIO interrupt */
    GPIO_PIN_INTR_POSEDGE = 1,      /**< GPIO interrupt type : rising edge */
    GPIO_PIN_INTR_NEGEDGE = 2,      /**< GPIO interrupt type : falling edge */
    GPIO_PIN_INTR_ANYEDGE = 3,      /**< GPIO interrupt type : bothe rising and falling edge */
    GPIO_PIN_INTR_LOLEVEL = 4,      /**< GPIO interrupt type : low level */
    GPIO_PIN_INTR_HILEVEL = 5       /**< GPIO interrupt type : high level */
} GPIO_INT_TYPE;
#endif

typedef enum {
    GPIO_Mode_Input = 0x0,          /**< GPIO mode : Input */
    GPIO_Mode_Out_OD,               /**< GPIO mode : Output_OD */
    GPIO_Mode_Output ,              /**< GPIO mode : Output */
    GPIO_Mode_Sigma_Delta ,         /**< GPIO mode : Sigma_Delta */
} GPIOMode_TypeDef;

typedef enum {
    GPIO_PullUp_DIS = 0x0,      /**< disable GPIO pullup */
    GPIO_PullUp_EN  = 0x1,      /**< enable GPIO pullup */
} GPIO_Pullup_IF;

typedef struct {
    uint16           GPIO_Pin;      /**< GPIO pin */
    GPIOMode_TypeDef GPIO_Mode;     /**< GPIO mode */
    GPIO_Pullup_IF   GPIO_Pullup;   /**< GPIO pullup */
    GPIO_INT_TYPE    GPIO_IntrType; /**< GPIO interrupt type */
} GPIO_ConfigTypeDef;

void
pin_config(uint8 pin, uint8 dir, uint8 v)
{
	PIN_FUNC_SELECT(GPIO_PIN_REG(pin),				// configure
		((1<<pin) & (BIT0|BIT2|BIT4|BIT5)) ? 0 : 3);

	v   = !!v;	// 1 is HIGH
	dir = !!dir;	// 1 is OUTPUT
	gpio_output_set(v<<pin, (!v)<<pin, dir<<pin, (!dir)<<pin);	// enable, set
}

void
pin_output_set(uint8 pin, uint8 v)
{
	uint32	mask = 1<<pin;

	v = !!v;
	gpio_output_set(v<<pin, (!v)<<pin, mask, 0);	// enable
}

uint8_t const gpio_num[17] = /* GPIO -> PIN */
/*	 0   1  2  3  4  5  6    7   8   9  10  11 12 13 14 15 16 */
	{3, 10, 4, 9, 2, 1, 99, 99, 99, 11, 12, 99, 6, 7, 5, 8, 0};
