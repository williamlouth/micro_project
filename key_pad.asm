#include p18f87k22.inc
	
	global	key_pad_start,key_pad_setup
	extern	delay
    
	
key_pad_vars    udata_acs	    ; named variables in access ram
raw_numb_row res 1
raw_numb_col res 1
dec_numb_row res 1
dec_numb_col res 1
col_numb res 1
row_numb res 1
numb_final res 1
actual_input res 1
table_counter res 2
send_command res 1
table_data_out_length  res  1
zero	res 1
invalid_file res 1
 
decode_numb res 1
;decode


key_pad_tables udata 
myArray1 res 16
myArray2 res 16
table_data_out	res 0x50
 
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
	movwf	send_command
	
	movlw	"£"
	movwf	invalid_file
	call key_pad_decode_setup
	movlw	0x0
	movwf	zero
	return
	
key_pad_start
	lfsr	FSR2,table_data_out ;point fsr2 at the output table data
	movlw	0x0
	movwf	table_data_out_length
	
key_pad_run
	movlw b'00001111'    ;set low 4 to inputs, high 4 to outputs 
	movwf TRISE, ACCESS ;on port E
	call delay
	movff PORTE, raw_numb_row


	
	movlw b'11110000'    ;set high 4 to inputs, low 4 to outputs 
	movwf TRISE, ACCESS ;on port E
	call delay
	;movf PORTE,w
	;addwf raw_numb,f
	movff PORTE, raw_numb_col
		
	
 	movlw 0x00
	movwf	TRISD
	movf raw_numb_col,w
	addwf raw_numb_row,w
	movwf PORTD,ACCESS
	call delay
	bra key_pad_decode
	
	
key_pad_reading_tables
	tblrd*+			; move one byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, POSTINC0	; move read data from TABLAT to (FSR0), increment FSR0	
	decfsz	table_counter		; count down to zero
	bra	key_pad_reading_tables
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
	movff PLUSW0,row_numb
	
	movf	row_numb,w
	cpfseq	invalid_file
	bra	next3
	bra	key_pad_run
	
	
	;lfsr	FSR0, myArray2
next3	movf dec_numb_col,w
	movff PLUSW0,col_numb
	
	movf	col_numb,w
	cpfseq	invalid_file
	bra	next4
	bra	key_pad_run
	
next4	lfsr	FSR0, myArray1
	movlw	.4
	mulwf	col_numb
	movff	PRODL,numb_final
	movf	row_numb, w
	addwf	numb_final, f
	movf	numb_final,W
	movff	PLUSW0, actual_input
	movf	actual_input,w
	;cpfseq	invalid_file ;check if either row or col has £ call invalid input
	bra	check_send
	;bra	key_pad_run
	
check_send
	cpfseq	send_command
	bra store_data
	movf	table_data_out_length,w
	cpfseq	zero
	bra	send_data
	bra	key_pad_run
send_data
	movf	table_data_out_length,w
	lfsr	FSR2,table_data_out
	return
	
store_data
	incf	table_data_out_length,f
	movff	actual_input,POSTINC2
	call	delay
	goto key_pad_run
	
	
;invalid input
    
    end
    
    
    
    
    
    
    


