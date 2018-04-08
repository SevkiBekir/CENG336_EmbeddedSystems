
list P=18F8722

#include <p18f8722.inc>
config OSC = HSPLL, FCMEN = OFF, IESO = OFF, PWRT = OFF, BOREN = OFF, WDT = OFF, MCLRE = ON, LPT1OSC = OFF, LVP = OFF, XINST = OFF, DEBUG = OFF


state   udata 0x21
state

counter   udata 0x22
counter

w_temp  udata 0x23
w_temp

status_temp udata 0x24
status_temp

pclath_temp udata 0x25
pclath_temp

portb_var   udata 0x26
portb_var

UDATA_ACS
  t1	res 1	; used in delay
  t2	res 1	; used in delay
  t3	res 1	; used in delay
  headPositionA res 1; used in ra
  headPositionF res 1; used in rf
  direction res 1; direction of ball
  isLeft res 1; is left or right movement of ball
  ballLocationX res 1; the location of ball wrt x-axis
  ballLocationY res 1; the location of ball wrt y-axis
  pointsOfP1 res 1; the points of P1
  pointsOfP2 res 1; the points of P2
  buttonFlag res 1 ;



org     0x00
goto    init

org     0x08
goto    isr             ;go to interrupt service routine

TABLE
    MOVF    PCL, F  ; A simple read of PCL will update PCLATH, PCLATU
    RLNCF   WREG, W ; multiply index X2
    ADDWF   PCL, F  ; modify program counter
    RETLW b'00111111' ;0 representation in 7-seg. disp. portJ
    RETLW b'00000110' ;1 representation in 7-seg. disp. portJ
    RETLW b'01011011' ;2 representation in 7-seg. disp. portJ
    RETLW b'01001111' ;3 representation in 7-seg. disp. portJ
    RETLW b'01100110' ;4 representation in 7-seg. disp. portJ
    RETLW b'01101101' ;5 representation in 7-seg. disp. portJ
    RETLW b'01111101' ;6 representation in 7-seg. disp. portJ
    RETLW b'00000111' ;7 representation in 7-seg. disp. portJ
    RETLW b'01111111' ;8 representation in 7-seg. disp. portJ
    RETLW b'01100111' ;9 representation in 7-seg. disp. portJ
    RETLW b'01110111' ;10 representation in 7-seg. disp. portJ ~A
    RETLW b'00111000' ;11 representation in 7-seg. disp. portJ ~L



init:
    call initalSetup

    call turnOnAllLights
    call delay
    fast:

    CLRF buttonFlag


    call initialInterruptConf

    goto main

initialInterruptConf:
 ;Disable interrupts
    clrf    INTCON
    clrf    INTCON2

;Initialize Timer0
    movlw   b'01000111' ;Disable Timer0 by setting TMR0ON to 0 (for now)
                        ;Configure Timer0 as an 8-bit timer/counter by setting T08BIT to 1
                        ;Timer0 increment from internal clock with a prescaler of 1:256.
    movwf   T0CON ; T0CON = b'01000111'
    movlw   b'00000001' ;Disable Timer0 by setting TMR0ON to 0 (for now)
    movwf   T1CON ; T1CON = b'00000001'


    ;Enable interrupts
    movlw   b'11100000' ;Enable Global, peripheral, Timer0 by setting GIE, PEIE, TMR0IE and RBIE bits to 1
    movwf   INTCON

    bsf     T0CON, 7    ;Enable Timer0 by setting TMR0ON to 1

    return

initalSetup:


    CLRF TRISA
    CLRF TRISB
    CLRF TRISC
    CLRF TRISD
    CLRF TRISE
    CLRF TRISF

    MOVLW 0x0F
    MOVWF TRISG


    clrf    PORTJ
    clrf    TRISJ
    clrf    PORTH
    clrf    TRISH

    return



turnOnAllLights:
    MOVLW   0x3F
    MOVWF   LATA
    MOVWF   LATB
    MOVWF   LATC
    MOVWF   LATD
    MOVWF   LATE
    MOVWF   LATF
    return


starting:


   MOVLW b'00011100'
   MOVWF LATA
   MOVWF LATF

   CLRF  LATB
   CLRF  LATC

   MOVLW 0x08
   MOVWF LATD
   CLRF LATE

   MOVLW 0x02
   MOVWF headPositionA
   MOVWF headPositionF
   MOVWF ballLocationX

   MOVLW 0x03
   MOVWF ballLocationY

   CLRF isLeft
;   COMF isLeft
   CLRF direction
   CLRF	state

   ;DEBUG
;   MOVLW b'00001110'
;   MOVWF LATA
;   MOVWF LATF
;   MOVLW 0x01
;   MOVWF ballLocationY
;   MOVLW 0x02
;
;   MOVWF LATD
;
;   MOVLW 0x01
;   MOVWF headPositionA
;   MOVWF headPositionF





   return




buttonLoop:

    MOVLW 0x05
    CPFSEQ pointsOfP1
    goto nextScoreCheck
    goto fast
    nextScoreCheck:
        CPFSEQ pointsOfP2
        goto nextJob
        goto fast
        nextJob:
        MOVF pointsOfP1,0	; prepare WREG before table lookup
        CALL  TABLE	; 0's bit settings for 7-seg. disp. returned into WREG
        MOVWF LATJ	; apply correct bit settings to portJ (7-seg. disp.)
        bsf     LATH, 0

        call delayMin
        bcf   LATH,0

        MOVF pointsOfP2,0	; prepare WREG before table lookup
        CALL  TABLE	; 0's bit settings for 7-seg. disp. returned into WREG
        MOVWF LATJ	; apply correct bit settings to portJ (7-seg. disp.)
        bsf     LATH, 3
        call delayMin
        bcf   LATH,3



    BTFSC state,0
    call movementOfBall
    call buttonRG0
    call buttonRG1
    call buttonRG2
    call buttonRG3
    goto buttonLoop



main:
   call starting
   CLRF pointsOfP1
   CLRF pointsOfP2
    goto buttonLoop


getBallDirection:

    BTFSS TMR1,0 ;xxxx-xxx1?
    goto lastBitZero
    goto lastBitOne
    lastBitZero:
        BTFSS TMR1,1;xxxx-xx1x?
        goto last00
        goto last01
    lastBitOne:
        BTFSS TMR1,1;xxxx-xx1x?
        goto last10
        goto last11

    last00:
        MOVLW 0x02
        MOVWF direction
        return

    last11:
        goto last00
        return

    last01:
        MOVLW 0x01
        MOVWF direction
        return

    last10:
        MOVLW 0x03
        MOVWF direction
        return

arrangeFlagsOfLeftUp:
    DECF ballLocationX
    DECF ballLocationY
    return

arrangeFlagsOfLeftStraight:
    DECF ballLocationX
    return

arrangeFlagsOfLeftDown:
    DECF ballLocationX
    INCF ballLocationY
    return

arrangeFlagsOfRightUp:
    INCF ballLocationX
    DECF ballLocationY
    return

arrangeFlagsOfRightStraight:
    INCF ballLocationX
    return

arrangeFlagsOfRightDown:
    INCF ballLocationX
    INCF ballLocationY
    return



movementOfBall:


    comf state,f
    call getBallDirection
    MOVLW 0x00
    CPFSEQ ballLocationX ; is at B
    goto notB

    call ballAtPortB
    return
    notB:
        MOVLW 0x01
        CPFSEQ ballLocationX ; is at C
        goto notC
        call ballAtPortC
        return
    notC:
        MOVLW 0x02
        CPFSEQ ballLocationX ; is at D
        goto notD
        call ballAtPortD
        return
   notD:
        call ballAtPortE
        return

ballAtPortC:

    MOVLW 0x01
    CPFSEQ direction ; isMoveUp
    goto otherCasePortC
    goto moveUpFromC
    otherCasePortC:
        MOVLW 0x02
        CPFSEQ direction; isStraight
        goto moveDownFromC       ; down
        goto moveStraightFromC   ; straight

    moveUpFromC:
        BTFSC isLeft, 0 ; isLeft?
        goto leftUpFromC
        goto rightUpFromC

        leftUpFromC:

            MOVLW 0x00
            CPFSEQ ballLocationY ; y==0  at RC0, cannot go to up
            goto doOperationOfLeftUpFromC
            call leftStraightFromC  ; go left straight
            return
            doOperationOfLeftUpFromC: ; left up
                call arrangeFlagsOfLeftUp
                MOVFF   LATC,LATB
                CLRF    LATC
                RRNCF    LATB, f
                return
        rightUpFromC:
            MOVLW 0x00
            CPFSEQ ballLocationY ; y==0  at RC0, cannot go to up
            goto doOperationOfRightUpFromC
            call rightStraightFromC  ; go right straight
            return
            doOperationOfRightUpFromC: ; right up
                call arrangeFlagsOfRightUp
                MOVFF   LATC,LATD
                CLRF    LATC
                RRNCF    LATD, f
                return

    moveDownFromC:
        BTFSC isLeft, 0 ; isLeft?
        goto leftDownFromC
        goto rightDownFromC

        leftDownFromC:
            MOVLW 0x05
            CPFSEQ ballLocationY ; y==5  at RC5, cannot go to up
            goto doOperationOfLeftDownFromC
            call leftStraightFromC  ; go left straight
            return
            doOperationOfLeftDownFromC: ; left down
                call arrangeFlagsOfLeftDown
                MOVFF   LATC,LATB
                CLRF    LATC
                RLNCF    LATB, f
                return
        rightDownFromC:
            MOVLW 0x05
            CPFSEQ ballLocationY ; y==5  at RC5, cannot go to up
            goto doOperationOfRightDownFromC
            call rightStraightFromC  ; go rightt straight
            return
            doOperationOfRightDownFromC: ; right down
                call arrangeFlagsOfRightDown
                MOVFF   LATC,LATD
                CLRF    LATC
                RLNCF    LATD, f                         ;;   Eksi hali  RRNCF
                return

    moveStraightFromC:
        BTFSC isLeft, 0 ; isLeft?
        goto leftStraightFromC
        goto rightStraightFromC

        leftStraightFromC:
            call arrangeFlagsOfLeftStraight

            MOVFF   LATC,LATB
            CLRF    LATC
            return
        rightStraightFromC:
            call arrangeFlagsOfRightStraight
            MOVFF   LATC,LATD
            CLRF    LATC
            return

ballAtPortD:
    MOVLW 0x01
    CPFSEQ direction ; isMoveUp
    goto otherCasePortD
    goto moveUpFromD
    otherCasePortD:
        MOVLW 0x02
        CPFSEQ direction; isStraight
        goto moveDownFromD
        goto moveStraightFromD

    moveUpFromD:

        BTFSC isLeft, 0 ; isLeft?
        goto leftUpFromD
        goto rightUpFromD

        leftUpFromD:
            MOVLW 0x00
            CPFSEQ ballLocationY ; y==0  at RD0, cannot go to up
            goto doOperationOfLeftUpFromD
            call leftStraightFromD  ; go left straight
            return
            doOperationOfLeftUpFromD: ; left up
                call arrangeFlagsOfLeftUp
                MOVFF   LATD,LATC
                CLRF    LATD
                RRNCF    LATC, f
                return
        rightUpFromD:
            MOVLW 0x00
            CPFSEQ ballLocationY ; y==0  at RD0, cannot go to up
            goto doOperationOfRightUpFromD
            call rightStraightFromD  ; go right straight
            return
            doOperationOfRightUpFromD: ; right up
                call arrangeFlagsOfRightUp
                MOVFF   LATD,LATE
                CLRF    LATD
                RRNCF    LATE, f
                return

    moveDownFromD:


        BTFSC isLeft, 0 ; isLeft?
        goto leftDownFromD
        goto rightDownFromD

        leftDownFromD:
            MOVLW 0x05
            CPFSEQ ballLocationY ; y==5  at RD5, cannot go to up
            goto doOperationOfLeftDownFromD
            call leftStraightFromD  ; go left straight
            return
            doOperationOfLeftDownFromD: ; left down
            call arrangeFlagsOfLeftDown
                MOVFF   LATD,LATC
                CLRF    LATD
                RLNCF    LATC, f
                return
        rightDownFromD:
            MOVLW 0x05
            CPFSEQ ballLocationY ; y==5  at RD5, cannot go to up
            goto doOperationOfRightDownFromD
            call rightStraightFromD  ; go rightt straight
            return
            doOperationOfRightDownFromD: ; right down
                call arrangeFlagsOfRightDown
                MOVFF   LATD,LATE
                CLRF    LATD
                RLNCF    LATE, f
                return

    moveStraightFromD:
        BTFSC isLeft, 0 ; isLeft?
        goto leftStraightFromD
        goto rightStraightFromD

        leftStraightFromD:
            call arrangeFlagsOfLeftStraight
            MOVFF   LATD,LATC
            CLRF    LATD
            return
        rightStraightFromD:
            call arrangeFlagsOfRightStraight
            MOVFF   LATD,LATE
            CLRF    LATD
            return

ballAtPortE:
    MOVLW 0x01
    CPFSEQ direction ; isMoveUp
    goto otherCasePortE
    goto moveUpFromE
    otherCasePortE:
        MOVLW 0x02
        CPFSEQ direction; isStraight
        goto moveDownFromE
        goto moveStraightFromE

    moveUpFromE:
        BTFSC isLeft, 0 ; isLeft?
        goto leftUpFromE
        goto rightUpFromE

        rightUpFromE:
            MOVLW 0x00
            CPFSEQ ballLocationY ; y==0  at RE0, cannot go to up
            goto doOperationOfRightUpFromE
            call rightStraightFromE  ; go right straight
            return
            doOperationOfRightUpFromE: ; left up
                movlw 0x01
                CPFSEQ ballLocationY ; y==1
                goto not1OfE
                btfss LATF , 0
                goto incrementPointsOfP1
                COMF isLeft,f

                return
                incrementPointsOfP1:
                    INCF pointsOfP1, f
                    call starting
                    return

                not1OfE:
                movlw 0x02
                CPFSEQ ballLocationY ; y==2
                goto not2OfE
                btfss LATF , 1
                goto incrementPointsOfP1
                COMF isLeft,f
                return

                not2OfE:
                movlw 0x03
                CPFSEQ ballLocationY ; y==3
                goto not3OfE
                btfss LATF , 2
                goto incrementPointsOfP1
                COMF isLeft,f
                return

                not3OfE:
                movlw 0x04
                CPFSEQ ballLocationY ; y==4
                goto not4OfE
                btfss LATF , 3
                goto incrementPointsOfP1
                COMF isLeft,f
                return

                not4OfE:
                btfss LATF , 4 ; y = 5
                goto incrementPointsOfP1
                COMF isLeft,f
                return


        leftUpFromE:
            MOVLW 0x00
            CPFSEQ ballLocationY ; y==0  at RE0, cannot go to up
            goto doOperationOfLeftUpFromE
            call leftStraightFromE  ; go left straight
            return
            doOperationOfLeftUpFromE:
                call arrangeFlagsOfLeftUp
                MOVFF   LATE,LATD
                CLRF    LATE
                RRNCF    LATD, f
                return


    moveDownFromE:
        BTFSC isLeft, 0 ; isLeft?
        goto leftDownFromE
        goto rightDownFromE

        rightDownFromE:
            MOVLW 0x05
            CPFSEQ ballLocationY ; y==5  at RE5, cannot go to down
            goto doOperationOfRightDownFromE
            call rightStraightFromE  ; go right straight
            return
            doOperationOfRightDownFromE: ; right down
                movlw 0x00
                CPFSEQ ballLocationY ; y==0
                goto not0OfEd
                btfss LATF , 1
                goto incrementPointsOfP1
                COMF isLeft,f
                return

                not0OfEd:
                movlw 0x01
                CPFSEQ ballLocationY ; y==1
                goto not1OfEd
                btfss LATF , 2
                goto incrementPointsOfP1
                COMF isLeft,f
                return

                not1OfEd:
                movlw 0x02
                CPFSEQ ballLocationY ; y==2
                goto not2OfEd
                btfss LATF , 3
                goto incrementPointsOfP1
                COMF isLeft,f
                return

                not2OfEd:
                movlw 0x03
                CPFSEQ ballLocationY ; y==3
                goto not3OfEd
                btfss LATF , 4
                goto incrementPointsOfP1
                COMF isLeft,f
                return

                not3OfEd:
                btfss LATF , 5 ; y = 4
                goto incrementPointsOfP1
                COMF isLeft,f
                return


        leftDownFromE:
            MOVLW 0x05
            CPFSEQ ballLocationY ; y==5  at RB0, cannot go to down
            goto doOperationOfLeftDownFromE
            call leftStraightFromE  ; go right straight
            return
            doOperationOfLeftDownFromE:
                call arrangeFlagsOfLeftDown
                MOVFF   LATE,LATD
                CLRF    LATE
                RLNCF   LATD, f
                return

    moveStraightFromE:
        BTFSC isLeft, 0 ; isLeft?
        goto leftStraightFromE
        goto rightStraightFromE

        rightStraightFromE:
            movlw 0x00
            CPFSEQ ballLocationY ; y==0
            goto not0OfEs
            btfss LATF , 0
            goto incrementPointsOfP1
            COMF isLeft,f
            return

            not0OfEs:
            movlw 0x01
            CPFSEQ ballLocationY ; y==1
            goto not1OfEs
            btfss LATF , 1
            goto incrementPointsOfP1
            COMF isLeft,f
            return

            not1OfEs:
            movlw 0x02
            CPFSEQ ballLocationY ; y==2
            goto not2OfEs
            btfss LATF , 2
            goto incrementPointsOfP1
            COMF isLeft,f
            return

            not2OfEs:
            movlw 0x03
            CPFSEQ ballLocationY ; y==3
            goto not3OfEs
            btfss LATF , 3
            goto incrementPointsOfP1
            COMF isLeft,f
            return

            not3OfEs:
            movlw 0x04
            CPFSEQ ballLocationY ; y==4
            goto not4OfEs
            btfss LATF , 4
            goto incrementPointsOfP1
            COMF isLeft,f
            return

            not4OfEs:
            btfss LATF , 5; y = 5
            goto incrementPointsOfP1
            COMF isLeft,f
            return


        leftStraightFromE:
            call arrangeFlagsOfLeftStraight

            MOVFF   LATE,LATD
            CLRF    LATE
            return

ballAtPortB:
    MOVLW 0x01
    CPFSEQ direction ; isMoveUp
    goto otherCasePortB
    goto moveUpFromB
    otherCasePortB:
        MOVLW 0x02
        CPFSEQ direction; isStraight
        goto moveDownFromB
        goto moveStraightFromB


    moveUpFromB:
        BTFSC isLeft, 0 ; isLeft?
        goto leftUpFromB
        goto rightUpFromB

        leftUpFromB:
            MOVLW 0x00
            CPFSEQ ballLocationY ; y==0  at RB0, cannot go to up
            goto doOperationOfLeftUpFromB
            call leftStraightFromB  ; go left straight
            return
            doOperationOfLeftUpFromB: ; left up
                movlw 0x01
                CPFSEQ ballLocationY ; y==1
                goto not1OfB
                btfss LATA , 0
                goto incrementPointsOfP2
                COMF isLeft,f
                return
                incrementPointsOfP2:
                    INCF pointsOfP2, f
                    call starting
                    return

                not1OfB:
                movlw 0x02
                CPFSEQ ballLocationY ; y==2
                goto not2OfB
                btfss LATA , 1
                goto incrementPointsOfP2
                COMF isLeft,f
                return

                not2OfB:
                movlw 0x03
                CPFSEQ ballLocationY ; y==3
                goto not3OfB
                btfss LATA , 2
                goto incrementPointsOfP2
                COMF isLeft,f
                return

                not3OfB:
                movlw 0x04
                CPFSEQ ballLocationY ; y==4
                goto not4OfB
                btfss LATA , 3
                goto incrementPointsOfP2
                COMF isLeft,f
                return

                not4OfB:
                btfss LATA , 4 ; y = 5
                goto incrementPointsOfP2
                COMF isLeft,f
                return


        rightUpFromB:
            MOVLW 0x00
            CPFSEQ ballLocationY ; y==0  at RB0, cannot go to up
            goto doOperationOfRightUpFromB
            call rightStraightFromB  ; go left straight
            return
            doOperationOfRightUpFromB:
                call arrangeFlagsOfRightUp
                MOVFF   LATB,LATC
                CLRF    LATB
                RRNCF    LATC, f
                return


    moveStraightFromB:

        BTFSC isLeft, 0 ; isLeft?
        goto leftStraightFromB
        goto rightStraightFromB

        leftStraightFromB:

            movlw 0x00
            CPFSEQ ballLocationY ; y==0
            goto not0OfBs
            btfss LATA , 0
            goto incrementPointsOfP2
            COMF isLeft,f
            return

            not0OfBs:
            movlw 0x01
            CPFSEQ ballLocationY ; y==1
            goto not1OfBs
            btfss LATA , 1
            goto incrementPointsOfP2
            COMF isLeft,f
            return

            not1OfBs:
            movlw 0x02
            CPFSEQ ballLocationY ; y==2
            goto not2OfBs
            btfss LATA , 2
            goto incrementPointsOfP2
            COMF isLeft,f
            return

            not2OfBs:
            movlw 0x03
            CPFSEQ ballLocationY ; y==3
            goto not3OfBs
            btfss LATA , 3
            goto incrementPointsOfP2
            COMF isLeft,f
            return

            not3OfBs:
            movlw 0x04
            CPFSEQ ballLocationY ; y==4
            goto not4OfBs
            btfss LATA , 4
            goto incrementPointsOfP2
            COMF isLeft,f
            return

            not4OfBs:
            btfss LATA , 5; y = 5
            goto incrementPointsOfP2
            COMF isLeft,f
            return


        rightStraightFromB:
            call arrangeFlagsOfRightStraight
            MOVFF   LATB,LATC
            CLRF    LATB
            return


    moveDownFromB:
        BTFSC isLeft, 0 ; isLeft?
        goto leftDownFromB
        goto rightDownFromB

        leftDownFromB:
            MOVLW 0x05
            CPFSEQ ballLocationY ; y==5  at RB5, cannot go to down
            goto doOperationOfLeftDownFromB
            call leftStraightFromB  ; go left straight
            return
            doOperationOfLeftDownFromB: ; left down
                movlw 0x00
                CPFSEQ ballLocationY ; y==0
                goto not0OfBd
                btfss LATA , 1
                goto incrementPointsOfP2
                COMF isLeft,f
                return

                not0OfBd:
                movlw 0x01
                CPFSEQ ballLocationY ; y==1
                goto not1OfBd
                btfss LATA , 2
                goto incrementPointsOfP2
                COMF isLeft,f
                return

                not1OfBd:
                movlw 0x02
                CPFSEQ ballLocationY ; y==2
                goto not2OfBd
                btfss LATA , 3
                goto incrementPointsOfP2
                COMF isLeft,f
                return

                not2OfBd:
                movlw 0x03
                CPFSEQ ballLocationY ; y==3
                goto not3OfBd
                btfss LATA , 4
                goto incrementPointsOfP2
                COMF isLeft,f
                return

                not3OfBd:
                btfss LATA , 5 ; y = 4
                goto incrementPointsOfP2
                COMF isLeft,f
                return


        rightDownFromB:
            MOVLW 0x05
            CPFSEQ ballLocationY ; y==5  at RB0, cannot go to down
            goto doOperationOfRightDownFromB
            call rightStraightFromB  ; go right straight
            return
            doOperationOfRightDownFromB:
                call arrangeFlagsOfRightDown
                MOVFF   LATB,LATC
                CLRF    LATB
                RLNCF    LATC, f
                return








isr:
    call    save_registers  ;Save current content of STATUS and PCLATH registers to be able to restore them later

    goto    timer_interrupt ;Yes. Goto timer interrupt handler part

;;;;;;;;;;;;;;;;;;;;;;;; Timer interrupt handler part ;;;;;;;;;;;;;;;;;;;;;;;;;;
timer_interrupt:
    incf	counter, f              ;Timer interrupt handler part begins here by incrementing count variable
    movf	counter, w              ;Move count to Working register
    sublw	d'60'                    ;Decrement 5 from Working register
    btfss	STATUS, Z               ;Is the result Zero?
    goto	timer_interrupt_exit    ;No, then exit from interrupt service routine
    clrf	counter                 ;Yes, then clear count variable
    comf	state, f


timer_interrupt_exit:
    bcf     INTCON, 2           ;Clear TMROIF
	movlw	d'61'               ;256-61=195; 195*256*60 = 2995000 instruction cycle;
	movwf	TMR0
	call	restore_registers   ;Restore STATUS and PCLATH registers to their state before interrupt occurs
	retfie



;;;;;;;;;;;; Register handling for proper operation of main program ;;;;;;;;;;;;
save_registers:
    movwf 	w_temp          ;Copy W to TEMP register
    swapf 	STATUS, w       ;Swap status to be saved into W
    clrf 	STATUS          ;bank 0, regardless of current bank, Clears IRP,RP1,RP0
    movwf 	status_temp     ;Save status to bank zero STATUS_TEMP register
    movf 	PCLATH, w       ;Only required if using pages 1, 2 and/or 3
    movwf 	pclath_temp     ;Save PCLATH into W
    clrf 	PCLATH          ;Page zero, regardless of current page
    return

restore_registers:
    movf 	pclath_temp, w  ;Restore PCLATH
    movwf 	PCLATH          ;Move W into PCLATH
    swapf 	status_temp, w  ;Swap STATUS_TEMP register into W
    movwf 	STATUS          ;Move W into STATUS register
    swapf 	w_temp, f       ;Swap W_TEMP
    swapf 	w_temp, w       ;Swap W_TEMP into W
    return

delay:	; Time Delay Routine with 3 nested loops
    MOVLW 80	; Copy desired value to W
    MOVWF t3	; Copy W into t3
    _loop33:
	MOVLW 0xFF  ; Copy desired value to W
	MOVWF t2    ; Copy W into t2
	_loop22:
	    MOVLW 0x5FF	; Copy desired value to W
	    MOVWF t1	; Copy W into t1
	    _loop11:
		decfsz t1,F ; Decrement t1. If 0 Skip next instruction
		GOTO _loop11 ; ELSE Keep counting down
		decfsz t2,F ; Decrement t2. If 0 Skip next instruction
		GOTO _loop22 ; ELSE Keep counting down
		decfsz t3,F ; Decrement t3. If 0 Skip next instruction
		GOTO _loop33 ; ELSE Keep counting down
		return


delayMin:	; Time Delay Routine with 3 nested loops
    MOVLW 0x0	; Copy desired value to W
    MOVWF t3	; Copy W into t3
    MOVWF t3
    MOVWF t3
    MOVWF t3
    return

delayGoal:	; Time Delay Routine with 3 nested loops
   MOVLW 10	; Copy desired value to W
    MOVWF t3	; Copy W into t3
    _loop331:
	MOVLW 0xFF  ; Copy desired value to W
	MOVWF t2    ; Copy W into t2
	_loop221:
	    MOVLW 0x5FF	; Copy desired value to W
	    MOVWF t1	; Copy W into t1
	    _loop111:
		decfsz t1,F ; Decrement t1. If 0 Skip next instruction
		GOTO _loop111 ; ELSE Keep counting down
		decfsz t2,F ; Decrement t2. If 0 Skip next instruction
		GOTO _loop221 ; ELSE Keep counting down
		decfsz t3,F ; Decrement t3. If 0 Skip next instruction
		GOTO _loop331 ; ELSE Keep counting down
		return
;///////////////////////
; BELOW ?S PADDLE
;///////////////////////
moveDownForRA0:
    MOVLW   0x0E
    MOVWF   LATA

    INCF    headPositionA, 1
    return

moveDownForRA1:
    MOVLW   0x1C
    MOVWF   LATA

    INCF    headPositionA, 1
    return

moveDownForRA2:
    MOVLW   0x38
    MOVWF   LATA

    INCF    headPositionA, 1
    return

moveUpForRA3:
    MOVLW   0x1C
    MOVWF   LATA

    DECF    headPositionA, 1
    return
moveUpForRA2:
    MOVLW   0x0E
    MOVWF   LATA

    DECF    headPositionA, 1
    return

moveUpForRA1:
    MOVLW   0x07
    MOVWF   LATA

    DECF    headPositionA, 1
    return

;RF PADDELS
moveDownForRF0:
    MOVLW   0x0E
    MOVWF   LATF

    INCF    headPositionF, 1
    return

moveDownForRF1:
    MOVLW   0x1C
    MOVWF   LATF

    INCF    headPositionF, 1
    return

moveDownForRF2:
    MOVLW   0x38
    MOVWF   LATF

    INCF    headPositionF, 1
    return

moveUpForRF3:
    MOVLW   0x1C
    MOVWF   LATF

    DECF    headPositionF, 1
    return
moveUpForRF2:
    MOVLW   0x0E
    MOVWF   LATF

    DECF    headPositionF, 1
    return

moveUpForRF1:
    MOVLW   0x07
    MOVWF   LATF

    DECF    headPositionF, 1
    return

doOperationRG0ForDown:
    MOVLW 0x00
    CPFSEQ headPositionF
    goto checkHeadRF1ForDown; head !=0
    call moveDownForRF0; head =0
    return
    checkHeadRF1ForDown:
        MOVLW 0x01
        CPFSEQ headPositionF
        goto checkHeadRF2ForDown; head !=1
        call moveDownForRF1; head =1
        return
        checkHeadRF2ForDown:
            MOVLW 0x02
            CPFSEQ headPositionF
            return; head !=2 goto exit
            call moveDownForRF2; head =2
            return

doOperationRG1ForUp:
    MOVLW 0x03
    CPFSEQ headPositionF
    goto checkHeadRF2ForUp; head !=3
    call moveUpForRF3; head =3
    return
    checkHeadRF2ForUp:
        MOVLW 0x02
        CPFSEQ headPositionF
        goto checkHeadRF1ForUp; head !=2
        call moveUpForRF2; head =2
        return
        checkHeadRF1ForUp:
            MOVLW 0x01
            CPFSEQ headPositionF
            return; head !=1 goto exit
            call moveUpForRF1; head =1
            return



doOperationRG3ForUp:
    MOVLW 0x03
    CPFSEQ headPositionA
    goto checkHeadRA2ForUp; head !=3
    call moveUpForRA3; head =3
    return
    checkHeadRA2ForUp:
        MOVLW 0x02
        CPFSEQ headPositionA
        goto checkHeadRA1ForUp; head !=2
        call moveUpForRA2; head =2
        return
        checkHeadRA1ForUp:
            MOVLW 0x01
            CPFSEQ headPositionA
            return; head !=1 goto exit
            call moveUpForRA1; head =1
            return


doOperationRG2ForDown:
    MOVLW 0x00
    CPFSEQ headPositionA
    goto checkHeadRA1ForDown; head !=0
    call moveDownForRA0; head =0
    return
    checkHeadRA1ForDown:
        MOVLW 0x01
        CPFSEQ headPositionA
        goto checkHeadRA2ForDown; head !=1
        call moveDownForRA1; head =1
        return
        checkHeadRA2ForDown:
            MOVLW 0x02
            CPFSEQ headPositionA
            return; head !=2 goto exit
            call moveDownForRA2; head =2
            return



buttonRG0IsPush:
    BTFSS PORTG , 0
    RETURN
    BSF buttonFlag , 0
    RETURN

buttonRG0IsRelease:
    BTFSC PORTG , 0
    RETURN
    BCF buttonFlag , 0
    call doOperationRG0ForDown
    RETURN

buttonRG0: ; very primitive button task
   BTFSS buttonFlag ,0
   GOTO nopush
   call buttonRG0IsRelease
   RETURN
   nopush:
     call buttonRG0IsPush
     RETURN


buttonRG1IsPush:
    BTFSS PORTG , 1
    RETURN
    BSF buttonFlag , 1
    RETURN

buttonRG1IsRelease:
    BTFSC PORTG , 1
    RETURN
    BCF buttonFlag , 1
    call doOperationRG1ForUp
    RETURN

buttonRG1: ; very primitive button task
     BTFSS buttonFlag ,1
     GOTO nopush1
     call buttonRG1IsRelease
     RETURN
     nopush1:
     call buttonRG1IsPush
     RETURN




buttonRG2IsPush:
    BTFSS PORTG , 2
    RETURN
    BSF buttonFlag , 2
    RETURN

buttonRG2IsRelease:
    BTFSC PORTG , 2
    RETURN
    BCF buttonFlag , 2
    call doOperationRG2ForDown
    RETURN

buttonRG2: ; very primitive button task
     BTFSS buttonFlag ,2
     GOTO nopush2
     call buttonRG2IsRelease
     RETURN
     nopush2:
     call buttonRG2IsPush
     RETURN

buttonRG3IsPush:
    BTFSS PORTG , 3
    RETURN
    BSF buttonFlag , 3
    RETURN

buttonRG3IsRelease:
    BTFSC PORTG , 3
    RETURN
    BCF buttonFlag , 3
    call doOperationRG3ForUp
    RETURN

buttonRG3: ; very primitive button task
     BTFSS buttonFlag ,3
     GOTO nopush3
     call buttonRG3IsRelease
     RETURN
     nopush3:
     call buttonRG3IsPush
     RETURN

end
