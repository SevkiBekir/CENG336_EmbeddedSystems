/* 
 * File:   Includes.h
 * Author: e2099398
 *
 * Created on April 27, 2018, 9:16 PM
 */

#ifndef INCLUDES_H
#define	INCLUDES_H

#ifdef	__cplusplus
extern "C" {
#endif

// Define CPU Frequency
// This must be defined, if __delay_ms() or
// __delay_us() functions are used in the code
#define _XTAL_FREQ   40000000


#include <htc.h> 


#ifdef	__cplusplus
}
#endif

#endif	/* INCLUDES_H */

