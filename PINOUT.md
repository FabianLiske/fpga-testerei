# AS02MC04 Pinout

Source for `Pin Index`, `Name`, `IO Standard`, `Location`, `DRIVE`, `SLEW`, and
`DQS_BIAS`:
`/home/faba/.local/share/vivado/board-files/as02mc04_hack/as02mc04/1.0/part0_pins.xml`

Source for `Bank`: Vivado 2025.2.1 device database for `xcku3p-ffvb676-1-e`.

| Pin Index | Name | IO Standard | Location | Bank | Technical Notes | Usage Notes |
| --- | --- | --- | --- | --- | --- | --- |
| 0 | diff_100mhz_clk_p | LVDS | E18 | BANK67 | DQS_BIAS TRUE | - |
| 1 | diff_100mhz_clk_n | LVDS | D18 | BANK67 | DQS_BIAS TRUE | - |
| 2 | SW_RESET | LVCMOS18 | F12 | BANK87 | - | - |
| 10 | sfp_mgt_clk_p | LVDS | K7 | BANK227 | DQS_BIAS TRUE | - |
| 11 | sfp_mgt_clk_n | LVDS | K6 | BANK227 | DQS_BIAS TRUE | - |
| 12 | sfp_1_txn | - | B6 | BANK227 | - | - |
| 13 | sfp_1_txp | - | B7 | BANK227 | - | - |
| 14 | sfp_1_rxn | - | A3 | BANK227 | - | - |
| 15 | sfp_1_rxp | - | A4 | BANK227 | - | - |
| 16 | sfp_2_txn | - | D6 | BANK227 | - | - |
| 17 | sfp_2_txp | - | D7 | BANK227 | - | - |
| 18 | sfp_2_rxn | - | B1 | BANK227 | - | - |
| 19 | sfp_2_rxp | - | B2 | BANK227 | - | - |
| 20 | SFP_1_MOD_DEF_0 | LVCMOS18 | D14 | BANK87 | SLEW SLOW DRIVE 8 | - |
| 21 | SFP_1_TX_FAULT | LVCMOS18 | B14 | BANK87 | SLEW SLOW DRIVE 8 | - |
| 22 | SFP_1_LOS | LVCMOS18 | D13 | BANK87 | SLEW SLOW DRIVE 8 | - |
| 23 | SFP_1_LED | LVCMOS18 | B12 | BANK87 | SLEW SLOW DRIVE 8 | NIC1 LED; green; active-low |
| 24 | SFP_2_MOD_DEF_0 | LVCMOS18 | E11 | BANK86 | SLEW SLOW DRIVE 8 | - |
| 25 | SFP_2_TX_FAULT | LVCMOS18 | F9 | BANK86 | SLEW SLOW DRIVE 8 | - |
| 26 | SFP_2_LOS | LVCMOS18 | E10 | BANK86 | SLEW SLOW DRIVE 8 | - |
| 27 | SFP_2_LED | LVCMOS18 | C12 | BANK87 | SLEW SLOW DRIVE 8 | NIC2 LED; green; active-low |
| 28 | IIC_SDA_SFP_1 | LVCMOS18 | C14 | BANK87 | SLEW SLOW DRIVE 8 | - |
| 29 | IIC_SCL_SFP_1 | LVCMOS18 | C13 | BANK87 | SLEW SLOW DRIVE 8 | - |
| 30 | IIC_SDA_SFP_2 | LVCMOS18 | D11 | BANK86 | SLEW SLOW DRIVE 8 | - |
| 31 | IIC_SCL_SFP_2 | LVCMOS18 | D10 | BANK86 | SLEW SLOW DRIVE 8 | - |
| 40 | IIC_SDA_EEPROM_0 | LVCMOS18 | G10 | BANK86 | SLEW SLOW DRIVE 8 | - |
| 41 | IIC_SCL_EEPROM_0 | LVCMOS18 | G9 | BANK86 | SLEW SLOW DRIVE 8 | - |
| 42 | IIC_SDA_EEPROM_1 | LVCMOS18 | J15 | BANK87 | SLEW SLOW DRIVE 8 | - |
| 43 | IIC_SCL_EEPROM_1 | LVCMOS18 | J14 | BANK87 | SLEW SLOW DRIVE 8 | - |
| 50 | GPIO_LED_R | LVCMOS18 | A13 | BANK87 | SLEW SLOW DRIVE 8 | Heartbeat red LED; active-low |
| 51 | GPIO_LED_G | LVCMOS18 | A12 | BANK87 | SLEW SLOW DRIVE 8 | Heartbeat green LED; active-low |
| 52 | GPIO_LED_H | LVCMOS18 | B9 | BANK86 | SLEW SLOW DRIVE 8 | Second LED from right; green; active-low |
| 53 | GPIO_LED_1 | LVCMOS18 | B11 | BANK86 | SLEW SLOW DRIVE 8 | DEBUG_LED1; green; active-low |
| 54 | GPIO_LED_2 | LVCMOS18 | C11 | BANK86 | SLEW SLOW DRIVE 8 | DEBUG_LED2; green; active-low |
| 55 | GPIO_LED_3 | LVCMOS18 | A10 | BANK86 | SLEW SLOW DRIVE 8 | DEBUG_LED3; green; active-low |
| 56 | GPIO_LED_4 | LVCMOS18 | B10 | BANK86 | SLEW SLOW DRIVE 8 | DEBUG_LED4; green; active-low |
| 60 | pcie_mgt_clkn | - | T6 | BANK225 | - | - |
| 61 | pcie_mgt_clkp | - | T7 | BANK225 | - | - |
| 62 | pcie_tx0_n | - | R4 | BANK225 | - | - |
| 63 | pcie_tx1_n | - | U4 | BANK225 | - | - |
| 64 | pcie_tx2_n | - | W4 | BANK225 | - | - |
| 65 | pcie_tx3_n | - | AA4 | BANK225 | - | - |
| 66 | pcie_tx4_n | - | AC4 | BANK224 | - | - |
| 67 | pcie_tx5_n | - | AD6 | BANK224 | - | - |
| 68 | pcie_tx6_n | - | AE8 | BANK224 | - | - |
| 69 | pcie_tx7_n | - | AF6 | BANK224 | - | - |
| 70 | pcie_rx0_n | - | P1 | BANK225 | - | - |
| 71 | pcie_rx1_n | - | T1 | BANK225 | - | - |
| 72 | pcie_rx2_n | - | V1 | BANK225 | - | - |
| 73 | pcie_rx3_n | - | Y1 | BANK225 | - | - |
| 74 | pcie_rx4_n | - | AB1 | BANK224 | - | - |
| 75 | pcie_rx5_n | - | AD1 | BANK224 | - | - |
| 76 | pcie_rx6_n | - | AE3 | BANK224 | - | - |
| 77 | pcie_rx7_n | - | AF1 | BANK224 | - | - |
| 78 | pcie_tx0_p | - | R5 | BANK225 | - | - |
| 79 | pcie_tx1_p | - | U5 | BANK225 | - | - |
| 80 | pcie_tx2_p | - | W5 | BANK225 | - | - |
| 81 | pcie_tx3_p | - | AA5 | BANK225 | - | - |
| 82 | pcie_tx4_p | - | AC5 | BANK224 | - | - |
| 83 | pcie_tx5_p | - | AD7 | BANK224 | - | - |
| 84 | pcie_tx6_p | - | AE9 | BANK224 | - | - |
| 85 | pcie_tx7_p | - | AF7 | BANK224 | - | - |
| 86 | pcie_rx0_p | - | P2 | BANK225 | - | - |
| 87 | pcie_rx1_p | - | T2 | BANK225 | - | - |
| 88 | pcie_rx2_p | - | V2 | BANK225 | - | - |
| 89 | pcie_rx3_p | - | Y2 | BANK225 | - | - |
| 90 | pcie_rx4_p | - | AB2 | BANK224 | - | - |
| 91 | pcie_rx5_p | - | AD2 | BANK224 | - | - |
| 92 | pcie_rx6_p | - | AE4 | BANK224 | - | - |
| 93 | pcie_rx7_p | - | AF2 | BANK224 | - | - |
| 94 | pcie_perstn_rst | LVCMOS18 | A9 | BANK86 | - | - |
