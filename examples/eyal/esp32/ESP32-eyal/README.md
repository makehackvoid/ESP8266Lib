I decided to make a PCB for my ESP32 things. I have many installed, each made differently. It is time to standardise them, hence this KiCAD (6) project.
======

I had the boards made by JLCPCB on 29/Feb/24, see the gerbers: gerbers-20240229-1703.zip

WARNING: Two issues with this version:
```
    1 - Solar charger requires a cap on the input.
    2 - The I2C lines incorrectly connect to pins 21/22, should be GPIO 21/22 (pins 33[SDA]/36[SCL]).
```

