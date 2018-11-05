	#include p18f87k22.inc
	global	delay,delay_v_long
    
delay_vars    udata_acs	    ; named variables in access ram
delay_counter1 res 1
delay_counter2 res 1
delay_counter3 res 1
 
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
	; Re-run program from start
	
delay_loop2

	DECFSZ  delay_counter2, F, ACCESS
	bra delay_loop2
	return
	
	
delay_v_long
	movlw   0x10
	movwf   delay_counter3, ACCESS
	call delay_loop
	DECFSZ  delay_counter2, F, ACCESS
	bra delay_v_long
	return


    end