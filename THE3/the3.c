
#include <p18cxxx.h>
#include <p18f8722.h>
#pragma config OSC = HSPLL, FCMEN = OFF, IESO = OFF, PWRT = OFF, BOREN = OFF, WDT = OFF, MCLRE = ON, LPT1OSC = OFF, LVP = OFF, XINST = OFF, DEBUG = OFF

#define _XTAL_FREQ   40000000

#include "Includes.h"
#include "LCD.h"
#include<stdio.h>



unsigned char c1;
unsigned int a =3 , b = 3, c = 6;
unsigned int waitFlag = 0;

unsigned int timer0counter;
unsigned int timer0counterShadow;
unsigned int tmr0shadow;
int tmr0Flag = 0;

unsigned int tmr0blinkCounter;
unsigned int tmr0blinkCounterShadow;
unsigned int blinkFlag = 0;

unsigned int tmr0setDoneCounter;
unsigned int tmr0setDoneCounterShadow;
unsigned int setDoneFlag = 0;


unsigned int tmr020secCounter;
unsigned int tmr020secCounterShadow;
unsigned int timeIsUpFor20Sec = 0;

unsigned int tmr01secCounter;
unsigned int tmr01secCounterShadow;
unsigned int timeIsUpFor1Sec = 0;

unsigned int potientimeterValue=-1;
unsigned int oldPotientimeterValue;
unsigned int oldPotientimeterValueForInt;
unsigned int dummyRB;
int activeLine = 0;
int isRBPressed = 0;
int RB6Flag = 0;
unsigned int pin[4];
unsigned int userPin[4];
unsigned int blinkSharpSign = 0;
unsigned int setPinFlag[4];

unsigned int isStep2 = 0;
unsigned int isFinishedProgram = 0;

int getDigitFromADC(int antValue);

int sym[]={
0b00111111,                     // 7-Segment = 0
0b00000110,                     // 7-Segment = 1
0b01011011,                     // 7-Segment = 2
0b01001111,                     // 7-Segment = 3
0b01100110,                     // 7-Segment = 4
0b01101101,                     // 7-Segment = 5
0b01111101,                     // 7-Segment = 6
0b00000111,                     // 7-Segment = 7
0b01111111,                     // 7-Segment = 8
0b01101111,                     // 7-Segment = 9
0b01000000,                     // 7-Segment = -
0b00000000                      // 7-Segment = turn off
};

unsigned int clockTime[4];

void appConfiguration(){
    TRISH4 = 1;                     // A/D port input setting
    ADCON0 = 0b00110000;            // set chanel 1100 => chanel12
    ADCON1 = 0b00000000;            // set voltage limits and set analog all.
    ADCON2 = 0b10001111;            // right justified
    PIE1bits.ADIE = 1;              // A/D interrupt enable
    ADON=1;                         // active gibi bisey

    TRISE = 0x02;
    INTCONbits.TMR0IE = 1;          // enable TMR0 interrupts
    INTCONbits.TMR0IF = 0;          // clear timer0 interrupt flag

    TRISB6 = 1;                     // set RB6 as input pin to use PORTB interrupt
    TRISB7 = 1;                     // set RB7 as input pin to use PORTB interrupt
    PORTB = 0;                      // clear PORTB in order to avoid unexpected situations
    LATB = 0;                       // clear LATB in order to avoid unexpected situations
    INTCONbits.RBIE = 1;            // enable PORTB change interrupts
    INTCONbits.RBIF = 0;            // clear PORTB interrupt flag
    INTCON2bits.RBPU = 0;           // PORTB pull-ups are enabled by individual port latch values

    T0CON = 0b01000111;             // set pre-scaler 1:256, use timer0 as 8-bit
    timer0counterShadow = 20;       // counter for timer0 250ms (2500000 instruction => 256 * 50 *(256-60) )
    timer0counter = timer0counterShadow;     // setTimer0Counter
    tmr0shadow = 60;                // timer0 initial value configuration for 100ms
    TMR0 = tmr0shadow;              // set timer0's initial value

    tmr0blinkCounterShadow = 50;       // counter for timer0 100ms (1000000 instruction => 256 * 50 *(256-60) )
    tmr0blinkCounter = tmr0blinkCounterShadow;     // setTimer0Counter

    tmr0setDoneCounterShadow = 100;       // counter for timer0 500ms (5000000 instruction => 256 * 50 *(256-60) )
    tmr0setDoneCounter = tmr0setDoneCounterShadow;     // setTimer0Counter
    setDoneFlag = 0;

    tmr020secCounterShadow = 4000;       // counter for timer0 10 (400000000 instruction => 256 * 50 *(256-60) )
    tmr020secCounter = tmr020secCounterShadow;     // setTimer0Counter
    timeIsUpFor20Sec = 0;

    tmr01secCounterShadow = 200;       // counter for timer0 10 (400000000 instruction => 256 * 50 *(256-60) )
    tmr020secCounter = tmr01secCounterShadow;     // setTimer0Counter
    timeIsUpFor1Sec = 0;

    INTCONbits.GIE_GIEH = 1;        // enable global interrupts
    INTCONbits.PEIE_GIEL = 1;       // enable peripheral interrupts

    ADON = 1;                       // enable A/D conversion module
    ADIF = 0;                       // clear A/D interrupt flag
    ADIE = 1;                       // enable A/D interrupts
    
    TRISA = 0x00;
    LATA2 = 1;
    
    TMR0ON = 1;

    TRISJ = 0;                      // Seven segment display configures for output
    LATJ = 0;                       // clear LATJ in order to avoid unexpected situations
    LATH = 0;                       // clear LATH in order to avoid unexpected situations
    TRISH = TRISH & 0b11110000;     // set PORTH<3:0> as output

    LATH = LATH & 0xF0;

    for(int i = 0; i < 4; i++){
        setPinFlag[i] =0;
        clockTime[i] = 0;
    }
}

void interrupt ISR(void){

    if(TMR0IE && TMR0IF){               // timer0 interrupt comes
        TMR0 = tmr0shadow;              // set timer0's initial value
        if(--timer0counter == 0){       //timer0 has arrived set its initial values and restart again
            timer0counter = timer0counterShadow; //reset timer0counter to it is initial value
            tmr0Flag = 1;               // set tmr0flag to 1
            ADCON0bits.GO_DONE=1;       // start an A/D conversion


        }
        if(--tmr0blinkCounter == 0){      
            tmr0blinkCounter = tmr0blinkCounterShadow; 
            blinkFlag = 1;            

        }

        if(--tmr0setDoneCounter == 0){      
            tmr0setDoneCounter = tmr0setDoneCounterShadow; 
            setDoneFlag = 1;            

        }

        if(--tmr020secCounter == 0){
            tmr020secCounter = tmr020secCounterShadow;
            timeIsUpFor20Sec = 1;

        }

        if(--tmr01secCounter == 0){
            tmr01secCounter = tmr01secCounterShadow;
            timeIsUpFor1Sec = 1;

        }

        TMR0IF = 0;                     // clear interrupt flag
        return;

    }else if(ADIE && ADIF){             // A/D interrupt comes
//        WriteStringToLCD(" GIRDI ");	// Write Hello World on LCD

        potientimeterValue = ADRES;     // Every time the A/D conversion finishes write the result into potientimeterValue
        ADIF = 0;                       // clear interrupt flag
        return;
    }else if(RBIE && RBIF){             // RB port change interrupt comes
        dummyRB = PORTB;                // read PORTB in order to avoid mismatch condition
        RBIF = 0;                       // clear interrupt flag

        // By this if-else we fire PORTB dependent events on button release
        if(isRBPressed == 0){
            if(!PORTBbits.RB6){
                isRBPressed = 1;  
                // save pressed button
                //WriteStringToLCD(" PRESSED ");	// Write Hello World on LCD

            }else if(!PORTBbits.RB7){
                isRBPressed = 2;       // save pressed button
//                WriteStringToLCD(" PRESSED ");	// Write Hello World on LCD

            }
            for(int i=0;i<10;i++)
                    __delay_ms(10);
        }else if(isRBPressed == 1){    // PORTB6 released
            if(getDigitFromADC( oldPotientimeterValueForInt)!=getDigitFromADC( potientimeterValue)){
                RB6Flag++;
                oldPotientimeterValueForInt=ADRES;
            }
            isRBPressed = 0;


        }else if(isRBPressed == 2){    // PORTB7 released
            if(RB6Flag>3)
                activeLine = !activeLine;
            isRBPressed = 0;
//            WriteStringToLCD(" RELEASED ");	// Write Hello World on LCD

        }
        return;

    }
    return;
}

void initApp() {
  appConfiguration();
    WriteCommandToLCD(0x80);   // G
    WriteStringToLCD(" $>Very  Safe<$");	// Write Hello World on LCD
    WriteCommandToLCD(0xC0); // Goto to the beginning of the second line
    WriteStringToLCD(" $$$$$$$$$$$$$$ ");	// Write Hello World on LCD
  while(!waitFlag){
      if(PORTEbits.RE1 == 0){ // pressed
          while(1){
             if(PORTEbits.RE1 == 1){
              waitFlag = 1;
              break;
          }
        }
      }
  }
              // Clear LCD screen
}


void printSevenDigit(int digit0,int digit1,int digit2,int digit3){
    LATH = LATH & 0xF0;

    LATJ = sym[digit0];                     // Set LATJ to d0 parameter
    LATH0 = 1;                          // Turn on D0 of 7-segment display
    __delay_us(50);                    // wait for shortly
    LATH0 = 0;

    LATJ = sym[digit1];                     // Set LATJ to d1 parameter
    LATH1 = 1;                          // Turn on D1 of 7-segment display
    __delay_us(50);                    // wait for shortly
    LATH1 = 0;


    LATJ = sym[digit2];                     // Set LATJ to d2 parameter
    LATH2 = 1;                          // Turn on D2 of 7-segment display
    __delay_us(50);                    // wait for shortly
    LATH2 = 0;

    LATJ = sym[digit3];                     // Set LATJ to d3 parameter
    LATH3 = 1;                          // Turn on D3 of 7-segment display
    __delay_us(50);                    // wait for shortly
    LATH3 = 0;
}


void updateLCD();

int getDigitFromADC(int antValue){
    if(antValue>=0 && antValue<100 ){
        return 0;
    }
    if(antValue>=100 && antValue<200 ){
        return 1;
    }
    if(antValue>=200 && antValue<300 ){
        return 2;
    }
    if(antValue>=300 && antValue<400 ){
        return 3;
    }
    if(antValue>=400 && antValue<500 ){
        return 4;
    }
    if(antValue>=500 && antValue<600 ){
        return 5;
    }
    if(antValue>=600 && antValue<700 ){
        return 6;
    }
    if(antValue>=700 && antValue<800 ){
        return 7;
    }
    if(antValue>=800 && antValue<900 ){
        return 8;
    }
    if(antValue>=900 && antValue<1025 ){
        return 9;
    }
}

void digitalEkran(){

            LATJ = sym[0];                     // Set LATJ to d3 parameter
            LATH3 = 1;                          // Turn on D3 of 7-segment display
            __delay_us(500);                    // wait for shortly
            LATH3 = 0;
}



void arrangePassword(){
 char result[1];
 oldPotientimeterValueForInt=ADRES;
 oldPotientimeterValue= ADRES;
    int isClearedLCD = 0;
    int count = 0;
    while(1){
        // all digits
        printSevenDigit(10,10,10,10);
        if(RB6Flag == 0){
            if(getDigitFromADC( oldPotientimeterValue)!=getDigitFromADC( potientimeterValue)){
                WriteCommandToLCD(0x8b);
                sprintf(result, "%d", getDigitFromADC( potientimeterValue));
                WriteStringToLCD(result);
                pin[0] = getDigitFromADC( potientimeterValue);  //get AD value
                setPinFlag[0] = 1;
                oldPotientimeterValue=potientimeterValue;

            }
            
            

        }else if(RB6Flag == 1){
            if(getDigitFromADC( oldPotientimeterValue)!=getDigitFromADC( potientimeterValue)){
                WriteCommandToLCD(0x8c);
                sprintf(result, "%d", getDigitFromADC( potientimeterValue));
                WriteStringToLCD(result);
                pin[1] = getDigitFromADC( potientimeterValue);
                setPinFlag[1] = 1;
                oldPotientimeterValue=potientimeterValue;
            }
            


        }else if(RB6Flag == 2){
            if(getDigitFromADC( oldPotientimeterValue)!=getDigitFromADC( potientimeterValue)){
                WriteCommandToLCD(0x8d);
                sprintf(result, "%d", getDigitFromADC( potientimeterValue));
                WriteStringToLCD(result);
                pin[2] = getDigitFromADC( potientimeterValue);
                setPinFlag[2] = 1;
                oldPotientimeterValue=potientimeterValue;

            }
            

        }else if(RB6Flag == 3){
            if(getDigitFromADC( oldPotientimeterValue)!=getDigitFromADC( potientimeterValue)){
                 WriteCommandToLCD(0x8e);
                 sprintf(result, "%d", getDigitFromADC( potientimeterValue));
                 WriteStringToLCD(result);
                 pin[3] = getDigitFromADC( potientimeterValue);
                 setPinFlag[3] = 1;
                 oldPotientimeterValue=potientimeterValue;


            }
           


        }
        if(RB6Flag > 3 && activeLine && !isStep2){
            if(setDoneFlag == 1){
                if(isClearedLCD){
                    WriteCommandToLCD(0x80);   // G
                    WriteStringToLCD(" The new pin is");
                    WriteCommandToLCD(0xC0); // Goto to the beginning of the second line
                    char result[14];
                    sprintf(result, "   ---%d%d%d%d---", pin[0],pin[1],pin[2],pin[3]);

                    WriteStringToLCD(result);
                    
                }else{
                    ClearLCDScreen();
                    count++;

                }

                
                isStep2 = count == 4 ? 1:0;
                isClearedLCD = !isClearedLCD;
                setDoneFlag = 0;
//                WriteCommandToLCD(0xC0); // Goto to the beginning of the second line
//                char result[10];
//                sprintf(result, "%d-%d", count,isStep2);
//                WriteStringToLCD(result);
            }


        }

        if(blinkFlag){
            if(RB6Flag==0 && !setPinFlag[0]){
                WriteCommandToLCD(0x8b);
                char sign;
                sign = blinkSharpSign ? '#':' ';
                WriteDataToLCD(sign);
                blinkSharpSign =!blinkSharpSign;
            }else if(RB6Flag==1 && !setPinFlag[1]){
                WriteCommandToLCD(0x8c);
                char sign;
                sign = blinkSharpSign ? '#':' ';
                WriteDataToLCD(sign);
                blinkSharpSign =!blinkSharpSign;
            }else if(RB6Flag==2 && !setPinFlag[2]){
                WriteCommandToLCD(0x8d);
                char sign;
                sign = blinkSharpSign ? '#':' ';
                WriteDataToLCD(sign);
                blinkSharpSign =!blinkSharpSign;
            }else if(RB6Flag==3 && !setPinFlag[3]){
                WriteCommandToLCD(0x8e);
                char sign;
                sign = blinkSharpSign ? '#':' ';
                WriteDataToLCD(sign);
                blinkSharpSign =!blinkSharpSign;
            }



            blinkFlag =!blinkFlag;

        }

        if(isStep2){
            ClearLCDScreen();
            break;
        }

    }

}

void appStart(){

    for(int i = 0; i < 3; i++){
        for(int j = 0; j < 100; j++){
            __delay_ms(10);
        }
    }
    ClearLCDScreen();           // Clear LCD screen

    WriteCommandToLCD(0x80);   // G

    

    WriteStringToLCD(" Set a pin:####");
    // Write Hello World on LCD
    arrangePassword();

}

int controlPin (){
    int isEqual = 1;
    for(int i = 0; i < 4; i++)
        if(pin[i] != userPin[i])
            isEqual = 0;


    return isEqual;
}

void startingClock(){
    clockTime[0] = 0;
    clockTime[1] = 1;
    clockTime[2] = 2;
    clockTime[3] = 0;

    tmr01secCounter = tmr01secCounterShadow;

}

void timerMovement(){

    if(timeIsUpFor1Sec){
        if(clockTime[3] == 0){
            if(clockTime[2] == 0){
                if(clockTime[1] == 0){
                    //time is Up guy
                    isFinishedProgram = 1;
                    return;
                }else{
                    clockTime[1]--;
                    clockTime[2] = 9;                
                    clockTime[3] = 9; 
                }

            }else{
                clockTime[2]--;
                clockTime[3] = 9; 
            }
            
        }else{
            clockTime[3]--;        
        }

        
        timeIsUpFor1Sec = 0;
    }

    printSevenDigit(clockTime[0],clockTime[1],clockTime[2],clockTime[3]);

}

void enterPin(){

    int attempt = 2;
    RB6Flag = 0;
    oldPotientimeterValue= ADRES;
    activeLine = 0;

    for(int i = 0; i < 4; i++)
        setPinFlag[i] =0;

    WriteCommandToLCD(0x80); // Goto to the beginning of the second line
    WriteStringToLCD(" Enter pin:####");
    WriteCommandToLCD(0xC0); // Goto to the beginning of the second line
    char result[40];
    sprintf(result, "  Attempts:%d", attempt);
    WriteStringToLCD(result);


    //clock settings
    startingClock();

    int wait20SecFlag = 0;

    while(!isFinishedProgram){

        //clock settings
        timerMovement();
        if(wait20SecFlag){
            if(timeIsUpFor20Sec){
                wait20SecFlag=0;
                activeLine = !activeLine;
                RB6Flag = 0;
                for(int i = 0; i < 4; i++)
                    setPinFlag[i] =0;
                attempt = 2;
                ClearLCDScreen();
                WriteCommandToLCD(0x80); // Goto to the beginning of the second line
                WriteStringToLCD(" Enter pin:####");
                WriteCommandToLCD(0xC0); // Goto to the beginning of the second line
                char result[40];
                sprintf(result, "  Attempts:%d", attempt);
                WriteStringToLCD(result);

            }
            continue;
        }


        if(RB6Flag == 0){

//            WriteCommandToLCD(0xC0); // Goto to the beginning of the second line
//            char result[10];
//            sprintf(result, "%d-%d", getDigitFromADC( potientimeterValue),getDigitFromADC( oldPotientimeterValue));
//            WriteStringToLCD(result);
            if(getDigitFromADC( oldPotientimeterValue)!=getDigitFromADC( potientimeterValue)){
                WriteCommandToLCD(0x8b);
                char result[3];
                sprintf(result, "%d", getDigitFromADC( potientimeterValue));
                WriteStringToLCD(result);
                userPin[0] = getDigitFromADC( potientimeterValue);  //get AD value
                setPinFlag[0] = 1;
                oldPotientimeterValue=potientimeterValue;

            }



        }else if(RB6Flag == 1){

            if(getDigitFromADC( oldPotientimeterValue)!=getDigitFromADC( potientimeterValue)){
                WriteCommandToLCD(0x8c);
                char result[3];

                sprintf(result, "%d", getDigitFromADC( potientimeterValue));
                WriteStringToLCD(result);
                userPin[1] = getDigitFromADC( potientimeterValue);
                setPinFlag[1] = 1;
                oldPotientimeterValue=potientimeterValue;
            }



        }else if(RB6Flag == 2){
            if(getDigitFromADC( oldPotientimeterValue)!=getDigitFromADC( potientimeterValue)){
                WriteCommandToLCD(0x8d);
                char result[3];

                sprintf(result, "%d", getDigitFromADC( potientimeterValue));
                WriteStringToLCD(result);
                userPin[2] = getDigitFromADC( potientimeterValue);
                setPinFlag[2] = 1;
                oldPotientimeterValue=potientimeterValue;

            }


        }else if(RB6Flag == 3){
            if(getDigitFromADC( oldPotientimeterValue)!=getDigitFromADC( potientimeterValue)){
                 WriteCommandToLCD(0x8e);
                char result[3];
                sprintf(result, "%d", getDigitFromADC( potientimeterValue));
                WriteStringToLCD(result);
                userPin[3] = getDigitFromADC( potientimeterValue);
                setPinFlag[3] = 1;
                oldPotientimeterValue=potientimeterValue;


            }



        }

        if(blinkFlag){
            if(RB6Flag==0 && !setPinFlag[0]){
                WriteCommandToLCD(0x8b);
                char sign;
                sign = blinkSharpSign ? '#':' ';
                WriteDataToLCD(sign);
                blinkSharpSign =!blinkSharpSign;
            }else if(RB6Flag==1 && !setPinFlag[1]){
                WriteCommandToLCD(0x8c);
                char sign;
                sign = blinkSharpSign ? '#':' ';
                WriteDataToLCD(sign);
                blinkSharpSign =!blinkSharpSign;
            }else if(RB6Flag==2 && !setPinFlag[2]){
                WriteCommandToLCD(0x8d);
                char sign;
                sign = blinkSharpSign ? '#':' ';
                WriteDataToLCD(sign);
                blinkSharpSign =!blinkSharpSign;
            }else if(RB6Flag==3 && !setPinFlag[3]){
                WriteCommandToLCD(0x8e);
                char sign;
                sign = blinkSharpSign ? '#':' ';
                WriteDataToLCD(sign);
                blinkSharpSign =!blinkSharpSign;
            }



            blinkFlag =!blinkFlag;

        }

        if(RB6Flag >= 3 && activeLine){

                if(controlPin()){
                    // equal
                    WriteCommandToLCD(0x80); // Goto to the beginning of the second line
                    WriteStringToLCD("Safe is opening!");
                    WriteCommandToLCD(0xC0); // Goto to the beginning of the second line
                    WriteStringToLCD("$$$$$$$$$$$$$$$$");
                }else{
                    attempt--;
                    if(attempt == 0){
                        // wait 20 sec.
                        timeIsUpFor20Sec = 0;
                        tmr020secCounter = tmr020secCounterShadow;
                        wait20SecFlag=1;
                        WriteCommandToLCD(0x80); // Goto to the beginning of the second line
                        WriteStringToLCD(" Enter pin:XXXX");
                        WriteCommandToLCD(0xC0); // Goto to the beginning of the second line
                        WriteStringToLCD("Try after 20 sec.");

                    }else{
                        WriteCommandToLCD(0x80); // Goto to the beginning of the second line
                        WriteStringToLCD(" Enter pin:####");
                        WriteCommandToLCD(0xC0); // Goto to the beginning of the second line
                        char result[40];
                        sprintf(result, "  Attempts:%d", attempt);
                        WriteStringToLCD(result);
                    }

                    activeLine = !activeLine;
                    RB6Flag = 0;
                    for(int i = 0; i < 4; i++)
                        setPinFlag[i] =0;
                }

                



            }



    }
}


// Main Function
void main(void)
{
    __delay_ms(15);
    __delay_ms(15);
    __delay_ms(15);
    __delay_ms(15);

    InitLCD();			// Initialize LCD in 4bit mode


    ClearLCDScreen();           // Clear LCD screen
    WriteCommandToLCD(0x80);   // Goto to the beginning of the first line


    initApp();



    appStart();
   
    enterPin();
    
}


void updateLCD() {

    WriteCommandToLCD(0xC0); // Goto to the beginning of the second line
    c1 = (char)(((int)'0') + a);
    WriteDataToLCD(c1);
    c1 = (char)(((int)'0') + b);
    WriteDataToLCD(c1);
    c1 = (char)(((int)'0') + c);
    WriteDataToLCD(c1);
    __delay_ms(2);

}
