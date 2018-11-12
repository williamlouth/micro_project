#include p18f87k22.inc
    global  transceiver_setup,received
    
transceiver_data udata 0x600
received    res 0x50	    ;stores the data that is sent in on the Uart
 
 
transceiver code

transceiver_setup
    bsf	RCON,IPEN	    ;enables different levels of interupts
    bsf	INTCON,PEIE	    ;enables peripheral interupts
    bsf	INTCON,GIE	    ;enables global interupts
    bsf	PIE1,RC1IE     ;enables the RC1IF interupt
    lfsr	FSR1, received	;setup the fsr so that if there is any uart data it is stored correctly
    
    clrf    TRISD   ;ensure RD0 is an output
    bsf	    PORTD,0    ;start the rts pin high. It will be pulsed down later to send data
    ;from the reviever to the microprocessor
    return
    
 
 
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
   
    
    
    
    
    
    end


