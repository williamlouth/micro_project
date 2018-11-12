#include p18f87k22.inc
	global	table_read_setup,table_u,table_h,table_l,table_address,table_counter
	
	
table_vars    udata_acs	    ; named variables in access ram
table_u res 1
table_h res 1
table_l res 1
table_address res 2
table_counter res 2
 


 ;decode_numb res 
 
 
table_read  code
	;****** Programme FLASH read Setup Code ****  
table_read_setup
	bcf	EECON1, CFGS	; point to Flash program memory  
	bsf	EECON1, EEPGD 	; access Flash program memory
	
	; ******* My data and where to put it in RAM *
;myTable data	"This is just some data"
;	constant 	myArray=0x400	; Address in RAM for data
;	constant 	counter=0x10	; Address of counter variable
	; ******* Main programme *********************
	
start 
	;lfsr	FSR0, table_address	; Load FSR0 with address in RAM	
	;movf	table_u,w	; address of data in PM
	;movwf	TBLPTRU		; load upper bits to TBLPTRU
	;movf	table_h,w	; address of data in PM
	;movwf	TBLPTRH		; load high byte to TBLPTRH
	;movf	table_l,w	; address of data in PM
	;movwf	TBLPTRL		; load low byte to TBLPTRL
	
loop 	tblrd*+			; move one byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, POSTINC0	; move read data from TABLAT to (FSR0), increment FSR0	
	decfsz	table_counter		; count down to zero
	bra	loop		; keep going until finished
	
	return

	end
    


