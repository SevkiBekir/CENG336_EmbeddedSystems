#include "p18f8722.inc"
; CONFIG1H
  CONFIG  OSC = HSPLL, FCMEN = OFF, IESO = OFF
; CONFIG2L
  CONFIG  PWRT = OFF, BOREN = OFF, BORV = 3
; CONFIG2H
  CONFIG  WDT = OFF, WDTPS = 32768
; CONFIG3L
  CONFIG  MODE = MC, ADDRBW = ADDR20BIT, DATABW = DATA16BIT, WAIT = OFF
; CONFIG3H
  CONFIG  CCP2MX = PORTC, ECCPMX = PORTE, LPT1OSC = OFF, MCLRE = ON
; CONFIG4L
  CONFIG  STVREN = ON, LVP = OFF, BBSIZ = BB2K, XINST = OFF
; CONFIG5L
  CONFIG  CP0 = OFF, CP1 = OFF, CP2 = OFF, CP3 = OFF, CP4 = OFF, CP5 = OFF
  CONFIG  CP6 = OFF, CP7 = OFF
; CONFIG5H
  CONFIG  CPB = OFF, CPD = OFF
; CONFIG6L
  CONFIG  WRT0 = OFF, WRT1 = OFF, WRT2 = OFF, WRT3 = OFF, WRT4 = OFF
  CONFIG  WRT5 = OFF, WRT6 = OFF, WRT7 = OFF
; CONFIG6H
  CONFIG  WRTC = OFF, WRTB = OFF, WRTD = OFF
; CONFIG7L
  CONFIG  EBTR0 = OFF, EBTR1 = OFF, EBTR2 = OFF, EBTR3 = OFF, EBTR4 = OFF
  CONFIG  EBTR5 = OFF, EBTR6 = OFF, EBTR7 = OFF
; CONFIG7H
  CONFIG  EBTRB = OFF

;*******************************************************************************
; Variables & Constants
;*******************************************************************************
UDATA_ACS
  t1	res 1	; used in delay
  t2	res 1	; used in delay
  t3	res 1	; used in delay
  headPosition res 1; position of head of snake
  isCW res 1; position of head of snake
  isCorner res 1; check corner
  flag res 1; check loop
  isPressedOnRB5 res 1; rb5 flag
;*******************************************************************************
; Reset Vector
;*******************************************************************************

RES_VECT  CODE    0x0000            ; processor reset vector
    GOTO    START                   ; go to beginning of program

;*******************************************************************************
; MAIN PROGRAM
;*******************************************************************************

MAIN_PROG CODE	; let linker place main program


START
    call INIT	; initialize variables and ports


MAIN_LOOP

call CORNER_CHECK
call RA4_BUTTON
BTFSC isCorner, 0
goto _buttonLoop
goto _jumpIt
_buttonLoop:
    call RA4_BUTTON  
    call RB5_BUTTON  
    MOVLW 0x1
    CPFSEQ  flag
    goto    _buttonLoop
    goto _jumpIt1
_jumpIt1:
    CLRF    isCorner
_jumpIt:
    CLRF flag
    call ONE_STEP_FORWARD
    call CHECK_DELEY

    GOTO MAIN_LOOP  ; loop forever


CHECK_DELEY
    MOVLW 0x01
    CPFSEQ isCW
    goto _delayCCW
    goto _delayCW
    _delayCCW:
	call DELAY_CCW
	return
    _delayCW:
	call DELAY_CW
	return
    
DELAY	; Time Delay Routine with 3 nested loops
    MOVLW 82	; Copy desired value to W
    MOVWF t3	; Copy W into t3
    _loop3:
	MOVLW 0xA0  ; Copy desired value to W
	MOVWF t2    ; Copy W into t2
	_loop2:
	    MOVLW 0x9F	; Copy desired value to W
	    MOVWF t1	; Copy W into t1
	    _loop1:
		decfsz t1,F ; Decrement t1. If 0 Skip next instruction
		GOTO _loop1 ; ELSE Keep counting down
		decfsz t2,F ; Decrement t2. If 0 Skip next instruction
		GOTO _loop2 ; ELSE Keep counting down
		decfsz t3,F ; Decrement t3. If 0 Skip next instruction
		GOTO _loop3 ; ELSE Keep counting down
		return

DELAY_CCW	; Time Delay Routine with 3 nested loops
    MOVLW 34	; Copy desired value to W
    MOVWF t3	; Copy W into t3
    _loop3_ccw:
	MOVLW 0xA0  ; Copy desired value to W
	MOVWF t2    ; Copy W into t2
	_loop2_ccw:
	    MOVLW 0x9F	; Copy desired value to W
	    MOVWF t1	; Copy W into t1
	    _loop1_ccw:
		decfsz t1,F ; Decrement t1. If 0 Skip next instruction
		GOTO _loop1_ccw ; ELSE Keep counting down
		decfsz t2,F ; Decrement t2. If 0 Skip next instruction
		GOTO _loop2_ccw ; ELSE Keep counting down
		decfsz t3,F ; Decrement t3. If 0 Skip next instruction
		GOTO _loop3_ccw ; ELSE Keep counting down
		return

DELAY_CW	; Time Delay Routine with 3 nested loops
    MOVLW 61	; Copy desired value to W
    MOVWF t3	; Copy W into t3
    _loop3_cw:
	MOVLW 0xA0  ; Copy desired value to W
	MOVWF t2    ; Copy W into t2
	_loop2_cw:
	    MOVLW 0x9F	; Copy desired value to W
	    MOVWF t1	; Copy W into t1
	    _loop1_cw:
		decfsz t1,F ; Decrement t1. If 0 Skip next instruction
		GOTO _loop1_cw ; ELSE Keep counting down
		decfsz t2,F ; Decrement t2. If 0 Skip next instruction
		GOTO _loop2_cw ; ELSE Keep counting down
		decfsz t3,F ; Decrement t3. If 0 Skip next instruction
		GOTO _loop3_cw ; ELSE Keep counting down
		return

CORNER_CHECK
    MOVLW 0x00
    CPFSEQ headPosition
    goto _nextCheck1
    goto _doCorner
    _nextCheck1:
        MOVLW 0x03
        CPFSEQ headPosition
        goto _nextCheck2
        goto _doCorner
    _nextCheck2:
        MOVLW 0x06
        CPFSEQ headPosition
        goto _nextCheck3
        goto _doCorner
    _nextCheck3:
        MOVLW 0x09
        CPFSEQ headPosition
        return
        goto _doCorner

    _doCorner:
        MOVLW 0x01
        MOVWF isCorner
        return

TURN_ON_LIGHT
    MOVLW   b'00001111'
    MOVWF   LATA
    MOVWF   LATB
    MOVWF   LATC
    MOVWF   LATD
    return


TURN_OFF_LIGHT
    CLRF   LATA
    CLRF   LATB
    CLRF   LATC
    CLRF   LATD
    return

LIGHT_CONF
    MOVLW   b'0100000'
    MOVWF   TRISB
    MOVLW   b'0010000'
    MOVWF   TRISA
    MOVLW   0x00
    MOVWF   TRISC
    MOVWF   TRISD
    return

INITIAL_LIGHTS
    call LIGHT_CONF
    call TURN_ON_LIGHT
    call DELAY
    call DELAY
    call TURN_OFF_LIGHT
    return

INIT
    CLRF    headPosition
    CLRF    isCW
    CLRF    isCorner
    CLRF    flag
    CLRF    isPressedOnRB5
    MOVLW 0FH
    MOVWF ADCON1

    call INITIAL_LIGHTS ; inital lights

    call INITIAL_START_SNAKE

    MOVLW 0x01
    MOVWF isCW

    return



INITIAL_START_SNAKE
    MOVLW 0x01
    MOVWF LATA
    MOVWF LATB
    MOVWF headPosition
    return

HEAD_OF_SNAKE_AT_BO
    MOVLW 0x01
    CPFSEQ isCW
    goto _CCW_B0
    goto _CW_B0
    _CCW_B0:
        MOVLW 0x01
        MOVWF LATA
        CLRF  LATC
        MOVLW 0x00
        MOVWF headPosition
        return
    _CW_B0:
        MOVLW 0x01
        MOVWF LATC
        CLRF  LATA
        MOVLW 0x02
        MOVWF headPosition
        return

HEAD_OF_SNAKE_AT_CO
    MOVLW 0x01
    CPFSEQ isCW
    goto _CCW_C0
    goto _CW_C0
    _CCW_C0:
        MOVLW 0x01
        MOVWF LATB
        CLRF  LATD
        MOVLW 0x01
        MOVWF headPosition
        return
    _CW_C0:
        MOVLW 0x01
        MOVWF LATD
        CLRF  LATB
        MOVLW 0x03
        MOVWF headPosition
        return

HEAD_OF_SNAKE_AT_DO
    MOVLW 0x01
    CPFSEQ isCW
    goto _CCW_D0
    goto _CW_D0
    _CCW_D0:
        MOVLW 0x01
        MOVWF LATC
        MOVWF LATD
        MOVLW 0x02
        MOVWF headPosition
        return
    _CW_D0:
        MOVLW 0x01
        CLRF  LATC
        MOVLW 0x03
        MOVWF LATD
        MOVLW 0x04
        MOVWF headPosition
        return

HEAD_OF_SNAKE_AT_D1
    MOVLW 0x01
    CPFSEQ isCW
    goto _CCW_D1
    goto _CW_D1
    _CCW_D1:
        MOVLW 0x03
        MOVWF LATD
        MOVLW 0x03
        MOVWF headPosition
        return
    _CW_D1:
        MOVLW 0x06
        MOVWF LATD
        MOVLW 0x05
        MOVWF headPosition
        return

HEAD_OF_SNAKE_AT_D2
    MOVLW 0x01
    CPFSEQ isCW
    goto _CCW_D2
    goto _CW_D2
    _CCW_D2:
        MOVLW 0x06
        MOVWF LATD
        MOVLW 0x04
        MOVWF headPosition
        return
    _CW_D2:
        MOVLW 0x0C
        MOVWF LATD
        MOVLW 0x06
        MOVWF headPosition
        return

HEAD_OF_SNAKE_AT_D3
    MOVLW 0x01
    CPFSEQ isCW
    goto _CCW_D3
    goto _CW_D3
    _CCW_D3:
        MOVLW 0x0C
        MOVWF LATD
        CLRF  LATC
        MOVLW 0x05
        MOVWF headPosition
        return
    _CW_D3:
        MOVLW 0x08
        MOVWF LATD
        MOVWF LATC
        MOVLW 0x07
        MOVWF headPosition
        return

HEAD_OF_SNAKE_AT_C3
    MOVLW 0x01
    CPFSEQ isCW
    goto _CCW_C3
    goto _CW_C3
    _CCW_C3:
        MOVLW 0x08
        MOVWF LATD
        CLRF  LATB
        MOVLW 0x06
        MOVWF headPosition
        return
    _CW_C3:
        MOVLW 0x08
        CLRF LATD
        MOVWF LATB
        MOVLW 0x08
        MOVWF headPosition
        return

HEAD_OF_SNAKE_AT_B3
    MOVLW 0x01
    CPFSEQ isCW
    goto _CCW_B3
    goto _CW_B3
    _CCW_B3:
        MOVLW 0x08
        MOVWF LATC
        CLRF  LATA
        MOVLW 0x07
        MOVWF headPosition
        return
    _CW_B3:
        MOVLW 0x08
        CLRF LATC
        MOVWF LATA
        MOVLW 0x09
        MOVWF headPosition
        return

HEAD_OF_SNAKE_AT_A3
    MOVLW 0x01
    CPFSEQ isCW
    goto _CCW_A3
    goto _CW_A3
    _CCW_A3:
        MOVLW 0x08
        MOVWF LATB
        MOVWF LATA
        MOVLW 0x08
        MOVWF headPosition
        return
    _CW_A3:
        MOVLW 0x0C
        CLRF LATB
        MOVWF LATA
        MOVLW 0x0A
        MOVWF headPosition
        return

HEAD_OF_SNAKE_AT_A2
    MOVLW 0x01
    CPFSEQ isCW
    goto _CCW_A2
    goto _CW_A2
    _CCW_A2:
        MOVLW 0x0C
        MOVWF LATA
        MOVLW 0x09
        MOVWF headPosition
        return
    _CW_A2:
        MOVLW 0x06
        MOVWF LATA
        MOVLW 0x0B
        MOVWF headPosition
        return

HEAD_OF_SNAKE_AT_A1
    MOVLW 0x01
    CPFSEQ isCW
    goto _CCW_A1
    goto _CW_A1
    _CCW_A1:
        MOVLW 0x06
        MOVWF LATA
        MOVLW 0x0A
        MOVWF headPosition
        return
    _CW_A1:
        MOVLW 0x03
        MOVWF LATA
        MOVLW 0x0
        MOVWF headPosition
        return

HEAD_OF_SNAKE_AT_A0
    MOVLW 0x01
    CPFSEQ isCW
    goto _CCW_A0
    goto _CW_A0
    _CCW_A0:
        MOVLW 0x03
        MOVWF LATA
        CLRF  LATB
        MOVLW 0x0B
        MOVWF headPosition
        return
    _CW_A0:
        MOVLW 0x01
        MOVWF LATA
        MOVWF LATB
        MOVLW 0x1
        MOVWF headPosition
        return

ONE_STEP_FORWARD
    MOVLW 0x01
    CPFSEQ headPosition
    goto _next1
    call HEAD_OF_SNAKE_AT_BO
    return
    _next1:
        MOVLW 0x02
        CPFSEQ headPosition
        goto _next2
        call HEAD_OF_SNAKE_AT_CO
        return
    _next2:
        MOVLW 0x03
        CPFSEQ headPosition
        goto _next3
        call HEAD_OF_SNAKE_AT_DO
        return
    _next3:
        MOVLW 0x04
        CPFSEQ headPosition
        goto _next4
        call HEAD_OF_SNAKE_AT_D1
        return
    _next4:
        MOVLW 0x05
        CPFSEQ headPosition
        goto _next5
        call HEAD_OF_SNAKE_AT_D2
        return
    _next5:
        MOVLW 0x06
        CPFSEQ headPosition
        goto _next6
        call HEAD_OF_SNAKE_AT_D3
        return
    _next6:
        MOVLW 0x07
        CPFSEQ headPosition
        goto _next7
        call HEAD_OF_SNAKE_AT_C3
        return
    _next7:
        MOVLW 0x08
        CPFSEQ headPosition
        goto _next8
        call HEAD_OF_SNAKE_AT_B3
        return
    _next8:
        MOVLW 0x09
        CPFSEQ headPosition
        goto _next9
        call HEAD_OF_SNAKE_AT_A3
        return
    _next9:
        MOVLW 0x0A
        CPFSEQ headPosition
        goto _next10
        call HEAD_OF_SNAKE_AT_A2
        return
    _next10:
        MOVLW 0x0B
        CPFSEQ headPosition
        goto _next11
        call HEAD_OF_SNAKE_AT_A1
        return
    _next11:
        MOVLW 0x00
        CPFSEQ headPosition
        goto _next12
        call HEAD_OF_SNAKE_AT_A0
        return
    _next12:
        return


RB5_BUTTON ; very primitive button task
    BTFSS PORTB,5
    return
    _debounce:
	BTFSC PORTB,5
	goto _debounce	; busy waiting. FIXME !!!
    CLRF isCorner
    MOVLW 0x01
    MOVWF flag
	return

CHANGE_CCW_CW
    MOVLW 0x01
    CPFSEQ isCW
    goto _doCW
    goto _doCCW
    _doCCW:
        CLRF isCW
        return
    _doCW:
        MOVLW 0x01
        MOVWF isCW
        return

CHANGE_HEAD_POSITION
    MOVLW 0x01
    CPFSEQ isCW
    goto _CCW2CW_WithInc
    goto _CW2CCW_WithDec
    _CCW2CW_WithInc:
        INCF headPosition, 1
        return
    _CW2CCW_WithDec:
        DECF headPosition, 1
        return

RA4_BUTTON ; very primitive button task
    BTFSS PORTA,4
    goto _notpress
    goto _press
    _notpress:
        MOVLW 0x01
        CPFSEQ isPressedOnRB5
        return
        goto _doNextJob
   _press:
    MOVLW 0x01
    MOVWF isPressedOnRB5
    return
    _doNextJob:
    call CHANGE_HEAD_POSITION
    call CHANGE_CCW_CW
    MOVLW 0x01
    MOVWF flag
    CLRF isPressedOnRB5
	return
	



END