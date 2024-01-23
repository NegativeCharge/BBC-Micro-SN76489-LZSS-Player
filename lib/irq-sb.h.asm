IRQ_VECTOR_LO = $204
IRQ_VECTOR_HI = $205

; 6522 - System VIA

SHEILA_SYS_VIA_PORT_B           = $FE40 
SHEILA_SYS_VIA_PORT_A_HANDSHAKE = $FE41

SHEILA_SYS_VIA_R3_DDRA          = $FE43   

; Sheila Sys VIA Timer 1 counter (low)
SHEILA_SYS_VIA_R4_T1C_L = $FE44
; Sheila Sys VIA Timer 1 counter (high)
SHEILA_SYS_VIA_R5_T1C_H = $FE45
; Sheila Sys VIA Timer 1 latch (low)
SHEILA_SYS_VIA_R6_T1L_L = $FE46
; Sheila Sys VIA Timer 1 latch (high)
SHEILA_SYS_VIA_R7_T1L_H = $FE47

; Sheila Sys VIA Timer 2 counter (low)
SHEILA_SYS_VIA_R4_T2C_L = $FE48
; Sheila Sys VIA Timer 2 counter (high)
SHEILA_SYS_VIA_R5_T2C_H = $FE49

; Sheila Sys VIA Auxiliary Control Register
SHEILA_SYS_VIA_R11_ACR = $FE4B

; Sheila Sys VIA Interrupt Flag Register
SHEILA_SYS_VIA_R13_IFR = $FE4D

; Sheila Sys VIA Interrupt Enable Register
SHEILA_SYS_VIA_R14_IER = $FE4E

SHEILA_SYS_VIA_PORT_A  = $FE4F


; Sheila User VIA Timer 1 counter (low)
SHEILA_USER_VIA_R4_T1C_L = $FE64
; Sheila User VIA Timer 1 counter (high)
SHEILA_USER_VIA_R5_T1C_H = $FE65
; Sheila User VIA Timer 1 latch (low)
SHEILA_USER_VIA_R6_T1L_L = $FE66
; Sheila User VIA Timer 1 latch (high)
SHEILA_USER_VIA_R7_T1L_H = $FE67

; Sheila User VIA Timer 2 counter (low)
SHEILA_USER_VIA_R4_T2C_L = $FE68
; Sheila User VIA Timer 2 counter (high)
SHEILA_USER_VIA_R5_T2C_H = $FE69

; Sheila User VIA Auxiliary Control Register
SHEILA_USER_VIA_R11_ACR = $FE6B

; Sheila User VIA Interrupt Flag Register
SHEILA_USER_VIA_R13_IFR = $FE6D

; Sheila User VIA Interrupt Enable Register
SHEILA_USER_VIA_R14_IER = $FE6E