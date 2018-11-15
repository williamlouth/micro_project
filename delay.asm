	#include p18f87k22.inc
	global	delay
    
delay_vars    udata_acs	    ; named variables in access ram
delay_counter1 res 1
delay_counter2 res 1
 
delay code
    
    
delay   movlw   0xff
	movwf   delay_counter1, ACCESS
	call delay_loop
		
	return 
	
delay_loop 
	movlw   0xff 
	movwf   delay_counter2, ACCESS
	call delay_loop2
	DECFSZ  delay_counter1, F, ACCESS
	bra delay_loop
	return
		
delay_loop2

	DECFSZ  delay_counter2, F, ACCESS
	bra delay_loop2
	return
	
	
    end