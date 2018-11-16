#include p18f87k22.inc

	global	lcd_write_interup,recieved_message_flag
	extern	delay  ; external subroutines
	extern	UART_Setup, UART_Transmit_Message,UART_Transmit_Byte
	extern	LCD_Setup, LCD_Write_Message, LCD_clear,LCD_Send_Byte_D,LCD_Write_Hex
	extern	transceiver_setup,received
	extern	key_pad_start,key_pad_setup
	
acs0	udata_acs  ; reserve data space in access ram
counter	    res 1   ; reserve byte for a counter variable for table read fn
data_counted_length res 1   ;stores length of data from key_pad
recieved_message_flag res 1
	

tables	udata	0x400    ; reserve data anywhere in RAM (here at 0x400)
myArray res	0x12    ; reserve 0x12 bytes for message data in ram
 
 
rst	code	0    ; reset vector
	goto	setup

int_hi	code 0x0008	    ;high interup code
	btfss	PIR1,RC1IF  ;checking that this is the RC1IF interup(uart read)
	retfie	FAST	    ;return if not
	movff	RCREG1,INDF1	;reading RCREG1, set rc1if low
	incf	data_counted_length,f		 ;add 1 to the data_counted_length
	movlw	0x00
	CPFSEQ	POSTINC1
	retfie	FAST	    ;return
	incf	recieved_message_flag,f  ;set the flag to 1
	decf	data_counted_length,f		 ;dont want to write the end transmit char
	retfie	FAST	    ;return
	
	
	
pdata	code    ; a section of programme memory for storing data
	; ******* myTable, data in programme memory, and its length *****
myTable data	    "Data lost\n"	; message, plus carriage return
	constant    myTable_l=.9	; length of data
	
main	code
	; ******* Programme FLASH read Setup Code ***********************
setup	bcf	EECON1, CFGS	; point to Flash program memory  
	bsf	EECON1, EEPGD 	; access Flash program memory
	call	UART_Setup	; setup UART
	call	LCD_Setup	;setup the LCD
	call	transceiver_setup   ;setup transceiver
	call	key_pad_setup	    ;setup key_pad
	
	bcf	PORTD,0
	
	clrf	recieved_message_flag ;set the flag to 0
	
	goto start

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
	
	goto	start2
	
		
	
start2
	call	key_pad_start    ;this hangs in key_pad until send(A) is pressed
	movwf	data_counted_length	 ;store the length for later use
	call	UART_Transmit_Message   ;send the message, fsr2 point at start of message, wreg = length
	clrf	data_counted_length	    ;set data length back to zero	

	bra	start2
	
lcd_write_interup
	bsf	PORTD,0			;dont want to be interupted when writing to LCD(timing issues)
	call	LCD_clear		;wipe the LCD

	decf	data_counted_length,f	;dont include the data_length byte
	lfsr	FSR2, received
	movf	data_counted_length,w
	movf	PLUSW2,w		;recieved data length value in message
	CPFSEQ	data_counted_length
	bra data_error	

	movf	data_counted_length,w
	lfsr	FSR2, received
	call	LCD_Write_Message   ;needs message to write in fsr2 and length in w
	lfsr	FSR1,received	;reset the recieved pointer so that new data goes to the right place
	clrf	recieved_message_flag ;set the flag to 0
	clrf	data_counted_length	    ;set data length back to zero
	bcf	PORTD,0
	return 
	
data_error
	movlw	myTable_l
	lfsr	FSR2,myArray
	call	LCD_Write_Message   ;needs message to write in fsr2 and length in w
	clrf	recieved_message_flag ;set the flag to 0
	clrf	data_counted_length	    ;set data length back to zero
	bcf	PORTD,0
	return
	
	end