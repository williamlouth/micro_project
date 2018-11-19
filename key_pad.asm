#include p18f87k22.inc
	
	global	key_pad_start,key_pad_setup
	extern	delay
	extern	lcd_write_interup,recieved_message_flag ;self interupt for recieved message
    
	
key_pad_vars    udata_acs	    ; named variables in access ram
raw_numb_row res 1		    ;input on portE
raw_numb_col res 1		    ;input on portE
dec_numb_row res 1		    ;decoded value
dec_numb_col res 1		    ;decoded value
col_numb res 1			    ;output value
row_numb res 1			    ;output value
numb_final res 1		    ;pointer to large lookup table
actual_input res 1		    ;final output value in ascii
table_counter res 1		    ;for writing look-up tables into ram
send_command res 1		    ;store the ascii for A to compare against
table_data_out_length  res  1	    ;stores the length of the output data table
zero	res 1			    ;stores 0 to compare against
invalid_file res 1		    ;stores ascii £ to check for invalid inputs
temp_fsr2h  res 1
temp_fsr2l  res 1

key_pad_tables udata 
myArray1 res 16		    ;first lookup table used to lookup in second table
myArray2 res 16		    ;second lookup table. Used to store all valid inputs
table_data_out	res 0x39    ;stores the data that will be output at send time
 
key_pad code
 
 
table_keys db  "1","2","3","A","4","5","6","B","7","8","9","C","*","0","#","D"; message, plus carriage return
	constant    myTable_l=.16	; length of data
	
table_power db  '£',.0,.1,'£',.2,'£','£','£',.3  ;
	constant    myTable_2 = .9
	
	
key_pad_setup	;setup porte pull ups
	banksel PADCFG1 ; PADCFG1 is not in Access Bank!!
	bsf PADCFG1, REPU, BANKED ; PortE pull-ups on
	movlb 0x00 ; set BSR back to Bank 0
	clrf	LATE
	movlw	"A"
	movwf	send_command  ;fill this with ascii A
	
	movlw	"£"
	movwf	invalid_file	;fill this with ascii £
	call key_pad_decode_setup
	movlw	0x0
	movwf	zero
	return
	
key_pad_decode_setup
	lfsr	FSR0, myArray1	; Load FSR0 with address in RAM	
	movlw	upper(table_keys)	; address of data in PM
	movwf	TBLPTRU		; load upper bits to TBLPTRU
	movlw	high(table_keys)	; address of data in PM
	movwf	TBLPTRH		; load high byte to TBLPTRH
	movlw	low(table_keys)	; address of data in PM
	movwf	TBLPTRL		; load low byte to TBLPTRL
	
	movlw myTable_l
	movwf table_counter
	call key_pad_reading_tables
	
	
	
	lfsr	FSR0, myArray2	; Load FSR0 with address in RAM	
	movlw	upper(table_power)	; address of data in PM
	movwf	TBLPTRU		; load upper bits to TBLPTRU
	movlw	high(table_power)	; address of data in PM
	movwf	TBLPTRH		; load high byte to TBLPTRH
	movlw	low(table_power)	; address of data in PM
	movwf	TBLPTRL		; load low byte to TBLPTRL
	
	movlw myTable_2
	movwf table_counter
	call key_pad_reading_tables
	
	return
	
key_pad_reading_tables
	tblrd*+			; move one byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, POSTINC0	; move read data from TABLAT to (FSR0), increment FSR0	
	decfsz	table_counter		; count down to zero
	bra	key_pad_reading_tables
	return
	
	
	
	
key_pad_start
	lfsr	FSR2,table_data_out ;point fsr2 at the output table data
	movlw	0x0
	movwf	table_data_out_length
	
key_pad_run
	tstfsz	recieved_message_flag	;poll to see if have recieved a message
	call	do_interupt		;write the recieved message to the lcd
	
	movlw b'00001111'    ;set low 4 to inputs, high 4 to outputs 
	movwf TRISE, ACCESS ;on port E
	call delay
	movff PORTE, raw_numb_row

	movlw b'11110000'    ;set high 4 to inputs, low 4 to outputs 
	movwf TRISE, ACCESS ;on port E
	call delay
	movff PORTE, raw_numb_col
		
	bra key_pad_decode
	
	
key_pad_decode
	movff raw_numb_col, dec_numb_col
	movff raw_numb_row, dec_numb_row
	
	movlw b'11110000'
	addwf dec_numb_row
	swapf dec_numb_col
	movlw b'11110000'
	addwf dec_numb_col
	
	comf dec_numb_row,f
	movf	dec_numb_row,w
	cpfseq	zero		;check to see if the input is all zero, only true 
	bra next1		;if no button pressed
	bra key_pad_run
	
next1	comf dec_numb_col,f	
	movf	dec_numb_col,w	
	cpfseq	zero		    ;check to see if the input is all zero, only true 
	bra next2		    ;if no button pressed
	bra key_pad_run

	
next2	lfsr	FSR0, myArray2
	movlw	0x9
	CPFSLT	dec_numb_row	;if inp > 8 call invalid input
	bra key_pad_run
	
	CPFSLT	dec_numb_col	;if inp > 8 call invalid input
	bra key_pad_run

	movf dec_numb_row,w
	movff PLUSW0,row_numb	;stores the row number from first lookup table
	
	movf	row_numb,w
	cpfseq	invalid_file	;check if only 1 button has been pressed
	bra	next3
	bra	key_pad_run
	
next3	movf dec_numb_col,w
	movff PLUSW0,col_numb	;stores the column number from first lookup table
	
	movf	col_numb,w
	cpfseq	invalid_file	;check if only 1 button has been pressed
	bra	next4
	bra	key_pad_run
	
next4	lfsr	FSR0, myArray1
	movlw	.4
	mulwf	col_numb	;make the right offset for second lookup table
	movff	PRODL,numb_final    ;store value from mulwf
	movf	row_numb, w
	addwf	numb_final, f	    ;final offset in second lookup table
	movf	numb_final,W
	movff	PLUSW0, actual_input	;read actual input out of second lookup table
	movf	actual_input,w
	
	
check_send
	cpfseq	send_command	;check to see if it is the send command(A)
	bra store_data		;if it isnt store the data
	movf	table_data_out_length,w	
	cpfseq	zero		;check to see if there is actually data to send
	bra	send_data	;send if there is
	bra	key_pad_run	;loop back to start if not
send_data
	movff	table_data_out_length,POSTINC2	;add length of data to the message
	movlw	0x00	    ;Null in ascii = end of transmission
	movwf	POSTINC2    ;add it to the message
	incf	table_data_out_length,f	    ;keep track of  data length
	incf	table_data_out_length,f	    ;add the length data length
	movf	table_data_out_length,w	    ;put length of data in w reg
	lfsr	FSR2,table_data_out	    ;point fsr2 at start of data table
	return				    ;jump out of key_pad code
	
store_data
	movlw	0x39
	CPFSLT	table_data_out_length	    ;stops user from filling reciever buffer
	bra	key_pad_run		    ;if they are loop to start		    
	incf	table_data_out_length,f	    ;increase variable that stores length
	movff	actual_input,POSTINC2	    ;put value to store onto fsr2 table and move fsr2 on 1
	call	delay
	goto key_pad_run
	
	
	
do_interupt
	movff	FSR2H,temp_fsr2h	;stores the fsr2 value so that you can
	movff	FSR2L,temp_fsr2l	;type numbers while recieving messages
	call lcd_write_interup
	movff	temp_fsr2h,FSR2H
	movff	temp_fsr2l,FSR2L
	return
   
    end
    
    
    
    
    
    
    


