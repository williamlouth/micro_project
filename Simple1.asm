#include p18f87k22.inc

	extern	delay  ; external subroutines
	extern	UART_Setup, UART_Transmit_Message,UART_Transmit_Byte
	extern	LCD_Setup, LCD_Write_Message, LCD_clear,LCD_Send_Byte_D,LCD_Write_Hex
	extern	transceiver_setup,received
	extern	key_pad_start,key_pad_setup
	
acs0	udata_acs  ; reserve data space in access ram
counter	    res 1   ; reserve byte for a counter variable for table read fn
data_length res 1   ;stores length of data from key_pad
	

tables	udata	0x400    ; reserve data anywhere in RAM (here at 0x400)
myArray res	0x12    ; reserve 0x12 bytes for message data in ram
 
 
rst	code	0    ; reset vector
	goto	setup

int_hi	code 0x0008	    ;high interup code
	btfss	PIR1,RC1IF  ;checking that this is the RC1IF interup(uart read)
	retfie	FAST	    ;return if not
	movff	RCREG1,POSTINC1	;reading RCREG1 set rc1if low
	retfie	FAST	    ;return
	
	
	
pdata	code    ; a section of programme memory for storing data
	; ******* myTable, data in programme memory, and its length *****
myTable data	    "Will and Rifkat\n"	; message, plus carriage return
	constant    myTable_l=.15	; length of data
	
main	code
	; ******* Programme FLASH read Setup Code ***********************
setup	bcf	EECON1, CFGS	; point to Flash program memory  
	bsf	EECON1, EEPGD 	; access Flash program memory
	call	UART_Setup	; setup UART
	call	LCD_Setup	;setup the LCD
	call	transceiver_setup   ;setup transceiver
	call	key_pad_setup	    ;setup key_pad
	
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
	movwf	data_length	 ;store the length for later use
	;movf	data_length,w    ;dont fiddle with the w reg before Uart_transmit_message
	
	call	UART_Transmit_Message   ;send the message, fsr2 point at start of message, wreg = length
			
	call delay
	
	lfsr	FSR1,received
	bcf	PORTD,0	;pulse to reciever to get it to send its buffered data
	call	delay
	call	delay
	call	delay
	call	delay
	call	delay
	call	delay
	call	delay	;need to wait long enough with portd,0 low to recieve all the data
	call	delay
	call	delay
	call	delay
	call	delay
	bsf	PORTD,0	;end pulse
	
	call	delay
	call	delay	;allow some time for uart to finiish
	call	delay
	
	
	
	call	LCD_clear		;wipe the LCD
	movf	data_length,w
	lfsr	FSR2, received
	call	LCD_Write_Message   ;needs message to write in fsr2 and length in w
	call	delay
	
	lfsr	FSR1,received	;reset the recieved pointer so that new data goes to the right place
	
	bra	start2
	

	end