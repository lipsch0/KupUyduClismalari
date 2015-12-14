
Device 18F24K20
'Device 18F24K22
'Device 18F2550


Xtal 4  '20 olacak

Config_Start
FOSC = xt 'HSHP ' Oscillator Selection HS
'OSCS = Off ' Osc. Switch Enable Disabled

'bunlar k20 de yok k22 icin acilacak
'PLLCFG = OFF
'PRICLKEN = On

FCMEN = Off
IESO = OFF

''bunu 22 icin acacagim PWRTEN = On ' Power-up Timer Enabled
'BOR = Off ' Brown-out Reset Disabled
BOREN = SBORDIS
''bunu 22 icin cacagim BORV = 190 ' Brown-out Voltage 2.5V
WDTEN = Off ' Watchdog Timer Disabled
WDTPS = 128 ' Watchdog Postscaler 1:128
'bunu 22 icin acaccagim CCP2MX = PORTC1 ' CCP2 MUX Enable (RC1)
STVREN = OFF ' Stack Overflow Reset Disabled
LVP = Off ' Low Voltage ICSP Disabled
'DEBUG = Off ' Background Debugger Enable Disabled
'bunu 222 icin acacagim MCLRE = INTMCLR

CP0 = Off ' Code Protection Block 0 Disabled
CP1 = Off ' Code Protection Block 1 Disabled
CPB = Off ' Boot Block Code Protection Disabled
CPD = Off ' Data EEPROM Code Protection Disabled
WRT0 = Off ' Write Protection Block 0 Disabled
WRT1 = Off ' Write Protection Block 1Disabled
WRTB = Off ' Boot Block Write Protection Disabled
WRTC = Off ' Configuration Register Write Protection Disabled
WRTD = Off ' Data EEPROM Write Protection Disabled
EBTR0 = Off ' Table Read Protection Block 0 Disabled
EBTR1 = Off ' Table Read Protection Block 1 Disabled
EBTRB = Off ' Boot Block Table Read Protection Disabled
Config_End
 



'MCLRE = EXTMCLR




All_Digital   = true
'portb_pullups = true

Declare CCP1_Pin PORTC.2 'AD8317AGCset pin


TRISA.0 = 1 'ad8317 uzerinden power okuma (final kati)
TRISA.1 = 1 'ad8317 uzerinden power okuma (AGC kati)
TRISA.2 = 1 'ACS714LLCTR'nin 5V cikisi
TRISA.3 = 1 'MB1503 Lock Detect
TRISA.4 = 0 'TPS2421 Enable bacagi
TRISA.5 = 0 'bos.. LED ile test icin OUT yapildi.. !!!INPUT YAPMAYI UNUTMA EN SON!!!

TRISB.0 = 1 'bos
TRISB.1 = 1 'SCL2
TRISB.2 = 1 'SDA2
TRISB.3 = 0 'MB1503 Clock
TRISB.4 = 0 'MB1503 Data
TRISB.5 = 0 'MB1503 LE
TRISB.6 = 0 'MB1503 PSRF  High=normal Low=powersave
TRISB.7 = 0 'MB1503 PSIF  High=normal Low=powersave

TRISC.0 = 0 'LD29300 enable (high=enable)
TRISC.1 = 0 'TPS3823 WDI
TRISC.2 = 0 'AD8317 AGC Vset
TRISC.3 = 1 'SCL1
TRISC.4 = 1 'SDA1
TRISC.5 = 1 'bos
TRISC.6 = 1 'bos
TRISC.7 = 0 'AD8317 Vset Final

Symbol AGC8317in = PORTA.1
Symbol ACS714_5V = PORTA.2
Symbol pllLD     = PORTA.3
Symbol TPS2421en = PORTA.4
Symbol PWRled    = PORTA.5

Symbol mySCL2  = PORTB.1
Symbol mySDA2  = PORTB.2
Symbol pllCLK  = PORTB.3
Symbol pllDATA = PORTB.4
Symbol pllLE   = PORTB.5
Symbol pllPSRF = PORTB.6
Symbol pllPSIF = PORTB.7

Symbol LD29300enable = PORTC.0
Symbol TPS3823WDI    = PORTC.1
Symbol AD8317AGCset  = PORTC.2
Symbol mySCL1        = PORTC.3
Symbol mySDA1        = PORTC.4
Symbol AD8317final   = PORTC.7


Dim FREK1 As Word                            ' VCO Frekansi ( MHz )
Dim FREK2 As Word                            ' VCO Frekansi ( KHz )
Dim STP   As Word                            ' Step Frekansi ( KHz )
Dim REF   As Word                            ' Referanz Frekansi ( KHz )
Dim A     As Word                            ' A degeri
Dim N     As Word                            ' N degeri
Dim R     As Word                            ' R degeri
Dim X     As Word                            '
Dim PRE   As Byte                            '
Dim PRE2  As Byte                            '

Dim DataOut As Dword
Dim sayac   As Byte

'regulatorleri ve diger bilesenleri aktif hale getir
Low pllPSRF
Low pllPSIF
Low  TPS2421en
High LD29300enable
Low pllLE
High pllPSRF 'low power mode kapali
High pllPSIF 'low power mode kapali



Dim DutyCycle As Byte
DutyCycle = 0


'Initialise I2C slave mode
Dim Slave_Address As Byte
    Slave_Address = $33
SSPADD = Slave_Address                  ' Set our Address
SSPCON2 = 0                             ' General call address disabled
SSPCON1 = $36                           ' Set to I2C slave with 7-bit address
            
'I2C Declares
Symbol SCL = PORTC.3                     ' I2C clock input
Symbol SDA = PORTC.4                     ' I2C data input


'Define used register flags
Symbol SSPIF = PIR1.3                   ' SSP (I2C) interrupt flag
Symbol BF = SSPSTAT.0                   ' SSP (I2C) Buffer Full
Symbol R_W = SSPSTAT.2                  ' SSP (I2C) Read/Write
Symbol D_A = SSPSTAT.5                  ' SSP (I2C) Data/Address
Symbol CKP = SSPCON1.4                  ' SSP (I2C) SCK Release Control
Symbol SSPEN = SSPCON1.5                ' SSP (I2C) Enable
Symbol SSPOV = SSPCON1.6                ' SSP (I2C) Receive Overflow Indicator
Symbol WCOL = SSPCON1.7                 ' SSP (I2C) Write Collision Detect
Symbol SMP = SSPSTAT.7                  ' SSP (I2C) Rate Control
            
SMP = 1 'set the rate to 100KHz
            
'Declare Interrupt Enable bits
Symbol SSP1IE = PIE1.3                  'SSP1 Interrupt enable
Symbol SSP1IF = PIR1.3                  'SSP1 Interrupt Flag 1
Symbol SSP1IP = IPR1.3                  'SSP1 Interrupt Priority bit 1 = High priority
Symbol PEIE = INTCON.6                  'Peripheral Interrupt Enable same as GIEL
Symbol GIE = INTCON.7                   'Global Interrupt Enable
Symbol IPEN = RCON.7                    'Interrupt Priority Enable bit

'IPEN = 1 ' Enable Priorities for interrupts
PEIE = 1 ' Enable Peripheral interrupts
GIE = 1 ' Global Interrupt Enable     
SSP1IF = 0 ' clear SSP1 flag 
SSP1IE = 1 ' enable the Interrupt     
'SSP1IP = 1 ' High Priority interrupt for SSP1

'I2C SLAVE Data Variables
Dim I2C_Data As Byte                  'Our I2C Data
Dim SW_Data[10] As Byte               'The Switch Data (5 Bytes for Switches and 4 for Analog Data)
Dim i As Byte                         'Byte count
    i = 0                             'Clear the byte count
                           
'*************************************            
'*       Interrupt Rutine            *
'*************************************

On_Interrupt GoTo I2C_Interrupt
        
'Jump over the subroutines
GoTo StartHere
    
I2C_Interrupt:
        Context Save 
        High AD8317final
        If SSPIF = 1 Then
            SSPIF = 0                           ' Clear interrupt flag
            If BF = 1 Then                     ' Write Data
                I2C_Data = SW_Data[i]
                SSPBUF = I2C_Data
                CKP = 1
                Inc i
                If i = 10 Then Clear i
                EndIf
            'If BF = 0 Then End_Interrupt         ' Nothing in buffer so exit
            'If D_A = 1 Then I2C_Data = SSPBUF      ' Read Data (not address)
            'If SSPBUF != Slave_Address Then End_Interrupt  ' Clear the address from the buffer
        EndIf
        
        GoTo End_Interrupt    
                
End_Interrupt:
            'Clear any I2C collisions or errors
            If R_W = 0 And SSPOV = 1 Then SSPOV = 0 
            If R_W = 1 And WCOL = 1 Then WCOL = 0
            'SSPOV = 0
            'WCOL = 0

            Context Restore                   


StartHere:

'test icin AD8317AGCset portuna %5 duty cycle ile 2Khz veriyorum, maximum kazanc
HPWM 1,10,2000
   
Main:

    SW_Data[0] = 34
    SW_Data[1] = 92
    SW_Data[2] = 76



    'bu kismin hesaplamasini kod icine koyup, disardan frekansi parametre olarak alacagim
    'IF icin parametrelerim
    'OSC =4Mhz, Freq Range 230-235Mhz, M=16, ChSpacing=10Khz, FRQ=232.810Mhz (Ch 281) //DIKKAT 815 olmali
    'IF reference clock degerini PLL'e gonder
                      '12345678901234567890123
    DataOut =  %000000000000000100110000010000
    GoSub Pllgonder
    'IF swallow counter degrlerini PLL'e gonder
                      '12345678901234567890123
    DataOut =  %000000001101100000011110101101
    GoSub     Pllgonder
    'RF icin parametrelerim
    'OSC =4Mhz, Freq Range 348-349Mhz, M=64, ChSpacing=25Khz, FRQ=348.375Mhz (Ch 15) A:47 N:217  R:160  FC:1 LDS:0 Bit19:1
    'RF reference clock degerini PLL'e gonder
                      '12345678901234567890123
    DataOut =  %000000010000000010100000010000
    GoSub Pllgonder
    'RF swallow counter degrlerini PLL'e gonder
                      '12345678901234567890123
    DataOut =  %000000011011111101010011011000
    GoSub     Pllgonder



    DelayMS 1000
    Dim Sayi As Byte
    For Sayi = 1 To 5
        DelayMS 1000
    Next Sayi
    Toggle TPS3823WDI  'WatchDog u bilgilendir

GoTo Main





Pllgonder:
'Data ve CLK ucundan PLL'e veri gonderir
'In: DataOut degiskenindeki veri
'Out: plldata, pllclk ucundan seri data
' IF/RF reference counter icin CN1-CN2-T1-T2-R1-R2-R3-R4-R5-R6-R7-R8-R9-R10-R11-R12-R13-R14-CS--X-X-X-X
' IF/RF swallow counter icin   CN1-CN2-LDS-SW-FC-A1-A2-A3-A4-A5-A6-A7-N1-N2-N3-N4-N5-N6-N7-N8-N9-N10-N11

    For sayac = 1 To 23
        Low pllDATA
        If (DataOut & 1) = 1 Then High pllDATA
        DataOut = DataOut >> 1
        DelayUS 10
        High pllCLK
        DelayUS 10
        Low pllCLK
        DelayUS 10
    Next sayac

    High pllLE
    DelayUS 10
    Low pllLE                                 ' enable'yi 0 yap
    DelayUS 10

Return


'I2C interruptini buraya yazacagim
' I2C base address 14
' acma komutu 0x15
' kapama komutu 0x16
'
 
' I2C adresi read write biti dahil olmadan 0x14 (7-bit).
' I2C bus hizimiz 100kHz.
' Biz size a�ma-kapama komutu g�nderdikten sonra sizden OK (0x0A) ya da ERROR (0xFF) bekleyecegiz.

'�rnek Haberlesme:
'OBC: I2C START
'OBC: I2C Adresi (0x15) + Read-Write biti (WRITE)
'TAMSAT: ACK
'OBC: 0x15 (Transponder A�ma Komutu) veya 0x16 (Transponder Kapama Komutu)
'TAMSAT: ACK
'OBC: I2C STOP 
'
'100 milisaniye bekleme.
'
'OBC: I2C START
'OBC: I2C Adresi (0x15) + Read-Write biti (READ)
'TAMSAT: 0x0A (Eger Komut alinmissa), 0xFF (Eger  Komut alinmamissa)
'OBC: I2C STOP
'
'
'Biz komut g�ndermeden veri istedigimizde 0xFF d�nmesi lazim. 0x0A ve 0xFF sadece komut alindi mi emin olmak i�in.










            




