#include p18f87k22.inc

	extern	delay,delay_v_long  ; external subroutines
	extern	UART_Setup, UART_Transmit_Message,UART_Transmit_Byte
	extern	LCD_Setup, LCD_Write_Message, LCD_clear,LCD_Send_Byte_D,LCD_Write_Hex
	extern	transceiver_setup,received
	extern	key_pad_start,key_pad_setup
	
acs0	udata_acs  ; reserve data space in access ram
counter	    res 1   ; reserve one byte for a counter variable
consec_dig_counter res 1
data_length res 1
	constant   size_of_data = .8

;myArray res 0x80
;delay_count res 1   ; reserve one byte for counter in the delay routine

tables	udata	0x400    ; reserve data anywhere in RAM (here at 0x400)
myArray res 0x12    ; reserve 128 bytes for message data
 
new_group udata 0x300
data_test   res 1
array_test  res 0x20

counter2    res 1


 
rst	code	0    ; reset vector
	goto	setup

int_hi	code 0x0008	    ;high interup code
	btfss	PIE1,RC1IE  ;checking that this is the RC1IF interup(uart read)
	retfie	FAST	    ;return if not
	movff	RCREG1,POSTINC1
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
	call	transceiver_setup
	call	key_pad_setup
	
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
	;lfsr	FSR2, myArray
	
	;movlw	size_of_data
;	movlw	myTable_l
	
;	movwf	consec_dig_counter
		
	
;	call	delay
;	call	delay
	call	key_pad_start
	movwf	data_length
	movf	data_length,w
	;call	delay


	
consec_loop
	;lfsr FSR2, array_test
	;movlw 0x23
	;movwf POSTINC2
	;movlw 0x24
	;movwf POSTINC2
	;movlw 0x25
	;movwf POSTINC2
	;lfsr FSR2, array_test
	;movlw	0x3
	
	;movf	consec_dig_counter,w
	;movwf	INDF2
	;movlw	0x1
	;call	UART_Transmit_Message
	;call	delay
	;decfsz	consec_dig_counter
	;bra consec_loop	    ;this block sends a bunch of data
	
	;movlw	myTable_l
	;lfsr	FSR2, myArray
	;call	UART_Transmit_Message
	
	;movlw	myTable_l
	;lfsr	FSR2, myArray
	call	UART_Transmit_Message
	
	
	
	;movlw	0x0
	;movf	INDF2,w
	;movlw   0x0
	
	
	call delay
	
	lfsr	FSR1,received
	bcf	PORTD,0	;pulse to reciever to get it to send its buffered data
	call	delay
	call	delay
	call	delay
	call	delay
	call	delay
	call	delay
	call	delay
	call	delay
	call	delay
	call	delay
	call	delay
	bsf	PORTD,0
	
	call	delay
	call	delay
	call	delay
	
	lfsr	FSR1,received		;point fsr1 to start of uart data table
	;movf	data_length,w
	;movlw	myTable_l
	;movwf	consec_dig_counter	;keep track of length of data
	call	LCD_clear
read_loop
	;movlw	myTable_l
	;movlw 0x3
	movf	data_length,w
	lfsr	FSR2, received
	call	LCD_Write_Message
	call	delay
	
	;movf	POSTINC1,w		;read data in table to working to check
	;call	LCD_Write_Hex
	;lfsr	FSR2,received
	;movlw	size_of_data
	;call	LCD_Write_Message
	
	;decfsz	consec_dig_counter
	;bra	read_loop

	bra	start2
	

	end