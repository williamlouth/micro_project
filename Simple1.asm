	#include p18f87k22.inc

	extern	UART_Setup, UART_Transmit_Message,delay,delay_v_long  ; external subroutines
	extern	UART_Transmit_Byte
	
acs0	udata_acs  ; reserve data space in access ram
counter	    res 1   ; reserve one byte for a counter variable

;myArray res 0x80
;delay_count res 1   ; reserve one byte for counter in the delay routine

tables	udata	0x400    ; reserve data anywhere in RAM (here at 0x400)
myArray res 0xF    ; reserve 128 bytes for message data
 
new_group udata 0x500
data_test   res 1
received    res 0x45	    ;stores the data that is sent in on the Uart
counter2    res 1
consec_dig_counter res 1
	constant   size_of_data = .50

 
rst	code	0    ; reset vector
	goto	setup

int_hi	code 0x0008	    ;high interup code
	btfss	PIE1,RC1IE  ;checking that this is the RC1IF interup(uart read)
	retfie	FAST	    ;return if not
	movff	RCREG1,POSTINC1
	retfie	FAST	    ;return
	
	
	
pdata	code    ; a section of programme memory for storing data
	; ******* myTable, data in programme memory, and its length *****
myTable data	    "Send nudes\n"	; message, plus carriage return
	constant    myTable_l=.11	; length of data
	
main	code
	; ******* Programme FLASH read Setup Code ***********************
setup	bcf	EECON1, CFGS	; point to Flash program memory  
	bsf	EECON1, EEPGD 	; access Flash program memory
	call	UART_Setup	; setup UART
	; ******* Setting up handshake **********************************
	movlw	b'00000010'
	movwf	TRISD		;sets portd pin1 to input
	bsf PORTD,0
	
	bsf	RCON,IPEN	    ;enables different levels of interupts
	bsf	INTCON,PEIE	    ;enables peripheral interupts
	bsf	INTCON,GIE	    ;enables global interupts
	bsf	PIE1,RC1IE     ;enables the RC1IF interupt
	lfsr	FSR1, received	;setup the fsr so that if there is any uart data it is stored correctly
		
	
	
	goto start2

	; ******* Main programme ****************************************
start 	lfsr	FSR0, myArray	; Load FSR0 with address in RAM	
	movlw	upper(myTable)	; address of data in PM
	movwf	TBLPTRU		; load upper bits to TBLPTRU
	movlw	high(myTable)	; address of data in PM
	movwf	TBLPTRH		; load high byte to TBLPTRH
	movlw	low(myTable)	; address of data in PM
	movwf	TBLPTRL		; load low byte to TBLPTRL
	movlw	myTable_l	; bytes to read
	movwf 	counter		; our counter register
loop 	tblrd*+			; one byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, POSTINC0; move data from TABLAT to (FSR0), inc FSR0	
	decfsz	counter		; count down to zero
	bra	loop		; keep going until finished
	
	goto	test_rif
	
test	movlw	myTable_l	; output message to UART
	lfsr	FSR2, myArray
	call	UART_Transmit_Message
;	movlw	0xff
;	movwf	delay_count
	call	delay
	
	;RC1IF
	
	movlw	0x0
	movf	INDF2,w
	movf    RCREG1,w
	
	bra	test
	goto	$		; goto current line in code

test_rif   
		
	lfsr	FSR1, received
	movlw	myTable_l	; bytes to read
	movwf 	counter2	; our counter register
	;movlw	myTable_l	; output message to UART
	lfsr	FSR2, myArray
send_loop
	movf	POSTINC2,w
	call	UART_Transmit_Byte
	call	delay

	movf    RCREG1,w
	movwf	POSTINC1
	decfsz	counter2
	bra	send_loop
	goto	$		
	
start2
	lfsr	FSR2, data_test
	
	movlw	size_of_data
	movwf	consec_dig_counter
	call	delay
	call	delay
	call	delay

	

	
consec_loop
	movf	consec_dig_counter,w
	movwf	INDF2
	movlw	0x1
	call	UART_Transmit_Message
	decfsz	consec_dig_counter
	bra consec_loop	    ;this block sends a bunch of data
	
	
	;movlw	0x0
	;movf	INDF2,w
	;movlw   0x0
	
	
	call delay
	
	lfsr	FSR1,received
	bcf PORTD,0	;pulse to reciever to get it to send its buffered data
	call delay
	call delay
	call delay
	bsf PORTD,0
	
	lfsr	FSR1,received		;point fsr1 to start of uart data table
	movlw	size_of_data
	movwf	consec_dig_counter	;keep track of length of data
read_loop
	movf	POSTINC1,w		;read data in table to working to check
	decfsz	consec_dig_counter
	bra read_loop

	bra	start2
	

uart_read
	
	
	

	; a delay subroutine if you need one, times around loop in delay_count
;delay	decfsz	delay_count	; decrement until zero
;	bra delay
;	return

	end