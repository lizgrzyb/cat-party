;
; EGrzyb_CatParty.asm
;
; Created: 11/30/2018 9:38:23 AM
; Author : Liz Grzyb
; Title	 : Cat Party
;

;----------------------------------------------------------------------------
;PRE - SETUP
;----------------------------------------------------------------------------

.equ        WIDTH    = 128						;Screen dimensions                        
.equ        HEIGHT   = 64
.def		io_setup = r16
.def		reg_workhorse = r20
.def		reg_SPI_data = r17
.def		work = r25
.def		adc_value_high	= r13				; used to manipulate the high byte of the result of the ADC conversion
.def		adc_value_low	= r14				; used to manipulate the high byte of the result of the ADC conversion
.def		adcsra_config   = r15

.macro		set_pointer							;macro for pointers
			ldi			@0, low(@2<<1)
			ldi			@1, high(@2<<1)
.endmacro

.cseg
.org		0x0000
rjmp		setup
.org		0x0100

;----------------------------------------------------------------------------
;SETUP
;----------------------------------------------------------------------------

setup:
		rcall			OLED_initialize			;initialize OLED
		rcall			GFX_clear_array			;clear screen
		set_pointer		XL, XH, pixel_array		;look for values in pixel_array
		rcall			OLED_refresh_screen		;refresh screen
		rcall			setup_pot				;setup potentiometer
		ldi				r22, 8					;just a value to move across the screen and draw different parts of the cat.

;----------------------------------------------------------------------------
;LOOP 
;Description: r18 is the x position and r19 is the y position of the 
;first cat on the screen. This is from the TOP LEFT corner of the cat.
;----------------------------------------------------------------------------

loop:

	;(2,1) cat left ear
	set_pointer		ZL, ZH, earL
	rcall	GFX_set_shape						;which shape to write from char table
	rcall	getX
	ldi		r19, 20

	rcall	GFX_set_array_pos					;set array position
	rcall	GFX_draw_shape						;draw a shape to the OLED
	add		r18, r22							;setting up r18 to draw the next part of the cat

	rcall	drawCat								;jump to subroutine to draw the rest of the cat. (I moved this to another section because
												;it was a lot of code, and was making it hard to rcall to othersubroutines because of distance.
	set_pointer		XL, XH, pixel_array
	rcall	OLED_refresh_screen					;refresh screen
	rcall	GFX_clear_array						;clear screen

	rjmp	loop



;----------------------------------------------------------------------------
;SUBROUTINES
;----------------------------------------------------------------------------

;setting up the potentiometers to be read by ADCSRA
setup_pot:
		
		ldi			work, 0b11000111
		mov         adcsra_config, work 		;enabling pins on adcsra register
		sts			ADCSRA, work
		ret

;Read the X position of the cat and store it into register 18
read_cat_pos:	  

		sts			ADCSRA, adcsra_config 

		wait_adc:	lds			work, ADCSRA					;loading into workhorse the value of ADCSRA
					andi		work, 0b00010000				;testing against the interrupt flag of ADCSRA (ADIF)
					breq		wait_adc						;if the flag is not set, keep waiting

		show:
					lds			adc_value_low, ADCL				;x position on screen
					lds			adc_value_high, ADCH
					ror			adc_value_high					;put ADCH and ADCL into one register (adc_value_low)
					ror			adc_value_low
					ror			adc_value_high
					ror			adc_value_low

					lsr			adc_value_low

					ret

; Setup adc5 to be read for x position
getX:
	ldi			work, 0b01000101			;Set ADMUX to read x position (ADC5)
	sts			ADMUX, work				
	rcall		read_cat_pos				;start reading cat position based on potentiometer in ADC5

	mov			r18, adc_value_low			;load adc value into x position register

	ldi			work, 8						;check if cat falls too far to the left of the screen
	cp			work, r18						
	brge		overLowX					;if it does, break to subroutine to make sure it doesn't
	ldi			work, 101					;check if cat falls too far to the right of the screen
	cp			r18, work
	brge		overHighX					;if it does, break to subroutine to make sure it doesn't
	ret

;The over subroutines make sure that the cat stays within the boundaries of the OLED screen
overLowX:
		ldi r18, 8							;set cat at the left edge of screen										
		ret

overHighX:									;set cat at right edge of screen
		ldi	r18, 101
		ret

;This section draws the rest of the cat based on the initial square of the cat drawn from the potentiometers
drawCat:
	;(3,1) cat top head
	set_pointer		ZL, ZH, top
	rcall	GFX_set_shape					;which shape to write from char table
	rcall	GFX_set_array_pos				;set array position
	rcall	GFX_draw_shape					;draw a shape to the OLED
	add		r18, r22
	
	;(4,1) cat right ear
	set_pointer		ZL, ZH, earR
	rcall	GFX_set_shape					;which shape to write from char table
	rcall	GFX_set_array_pos				;set array position
	rcall	GFX_draw_shape					;draw a shape to the OLED
	add		r19, r22

	;cat LR corner
	set_pointer		ZL, ZH, eyeR
	rcall	GFX_set_shape					;which shape to write from char table
	rcall	GFX_set_array_pos				;set array position
	rcall	GFX_draw_shape					;draw a shape to the OLED
	sub		r18, r22

	;cat LR corner
	set_pointer		ZL, ZH, eyeL
	rcall	GFX_set_shape					;which shape to write from char table
	rcall	GFX_set_array_pos				;set array position
	rcall	GFX_draw_shape					;draw a shape to the OLED
	sub		r18, r22

	;cat LR corner
	set_pointer		ZL, ZH, eyeL2
	rcall	GFX_set_shape					;which shape to write from char table
	rcall	GFX_set_array_pos				;set array position
	rcall	GFX_draw_shape					;draw a shape to the OLED
	add		r19, r22

	set_pointer		ZL, ZH, left2
	rcall	GFX_set_shape					;which shape to write from char table
	rcall	GFX_set_array_pos				;set array position
	rcall	GFX_draw_shape					;draw a shape to the OLED
	add		r18, r22
	
	set_pointer		ZL, ZH, mouth
	rcall	GFX_set_shape					;which shape to write from char table
	rcall	GFX_set_array_pos				;set array position
	rcall	GFX_draw_shape					;draw a shape to the OLED
	add		r18, r22

	set_pointer		ZL, ZH, right2
	rcall	GFX_set_shape					;which shape to write from char table
	rcall	GFX_set_array_pos				;set array position
	rcall	GFX_draw_shape					;draw a shape to the OLED
		

;part to draw "cat party" at bottom of screen 
	ldi r18, 12								;position of first letter
	ldi	r19, 62

	set_pointer		ZL, ZH, Char_003
	rcall	GFX_set_shape					;which shape to write from char table
	rcall	GFX_set_array_pos				;set array position
	rcall	GFX_draw_shape					;draw a shape to the OLED
	add		r18, r22

	set_pointer		ZL, ZH, Char_255
	rcall	GFX_set_shape					;which shape to write from char table
	rcall	GFX_set_array_pos				;set array position
	rcall	GFX_draw_shape					;draw a shape to the OLED
	add		r18, r22
	
	set_pointer		ZL, ZH, Char_067
	rcall	GFX_set_shape					;which shape to write from char table
	rcall	GFX_set_array_pos				;set array position
	rcall	GFX_draw_shape					;draw a shape to the OLED
	add		r18, r22

	set_pointer		ZL, ZH, Char_065
	rcall	GFX_set_shape					;which shape to write from char table
	rcall	GFX_set_array_pos				;set array position
	rcall	GFX_draw_shape					;draw a shape to the OLED
	add		r18, r22
	
	set_pointer		ZL, ZH, Char_084
	rcall	GFX_set_shape					;which shape to write from char table
	rcall	GFX_set_array_pos				;set array position
	rcall	GFX_draw_shape					;draw a shape to the OLED
	add		r18, r22

	set_pointer		ZL, ZH, Char_255
	rcall	GFX_set_shape					;which shape to write from char table
	rcall	GFX_set_array_pos				;set array position
	rcall	GFX_draw_shape					;draw a shape to the OLED
	add		r18, r22

	set_pointer		ZL, ZH, Char_080
	rcall	GFX_set_shape					;which shape to write from char table
	rcall	GFX_set_array_pos				;set array position
	rcall	GFX_draw_shape					;draw a shape to the OLED
	add		r18, r22

	set_pointer		ZL, ZH, Char_065
	rcall	GFX_set_shape					;which shape to write from char table
	rcall	GFX_set_array_pos				;set array position
	rcall	GFX_draw_shape					;draw a shape to the OLED
	add		r18, r22

	set_pointer		ZL, ZH, Char_082
	rcall	GFX_set_shape					;which shape to write from char table
	rcall	GFX_set_array_pos				;set array position
	rcall	GFX_draw_shape					;draw a shape to the OLED
	add		r18, r22

	set_pointer		ZL, ZH, Char_084
	rcall	GFX_set_shape					;which shape to write from char table
	rcall	GFX_set_array_pos				;set array position
	rcall	GFX_draw_shape					;draw a shape to the OLED
	add		r18, r22

	set_pointer		ZL, ZH, Char_089
	rcall	GFX_set_shape					;which shape to write from char table
	rcall	GFX_set_array_pos				;set array position
	rcall	GFX_draw_shape					;draw a shape to the OLED
	add		r18, r22

	set_pointer		ZL, ZH, Char_255
	rcall	GFX_set_shape					;which shape to write from char table
	rcall	GFX_set_array_pos				;set array position
	rcall	GFX_draw_shape					;draw a shape to the OLED
	add		r18, r22

	set_pointer		ZL, ZH, Char_003
	rcall	GFX_set_shape					;which shape to write from char table
	rcall	GFX_set_array_pos				;set array position
	rcall	GFX_draw_shape					;draw a shape to the OLED
	add		r18, r22

;part to draw secret message at top of screen
	ldi r19, 0
	ldi r18, 40

	set_pointer		ZL, ZH, s1
	rcall	GFX_set_shape					;which shape to write from char table
	rcall	GFX_set_array_pos				;set array position
	rcall	GFX_draw_shape					;draw a shape to the OLED
	add		r18, r22
	
	set_pointer		ZL, ZH, s2
	rcall	GFX_set_shape					;which shape to write from char table
	rcall	GFX_set_array_pos				;set array position
	rcall	GFX_draw_shape					;draw a shape to the OLED
	add		r18, r22

	set_pointer		ZL, ZH, s3
	rcall	GFX_set_shape					;which shape to write from char table
	rcall	GFX_set_array_pos				;set array position
	rcall	GFX_draw_shape					;draw a shape to the OLED
	add		r18, r22
	
	set_pointer		ZL, ZH, s4
	rcall	GFX_set_shape					;which shape to write from char table
	rcall	GFX_set_array_pos				;set array position
	rcall	GFX_draw_shape					;draw a shape to the OLED
	add		r18, r22

	set_pointer		ZL, ZH, s5
	rcall	GFX_set_shape					;which shape to write from char table
	rcall	GFX_set_array_pos				;set array position
	rcall	GFX_draw_shape					;draw a shape to the OLED
	add		r18, r22
	
	set_pointer		ZL, ZH, s6
	rcall	GFX_set_shape					;which shape to write from char table
	rcall	GFX_set_array_pos				;set array position
	rcall	GFX_draw_shape					;draw a shape to the OLED
	add		r18, r22

	set_pointer		ZL, ZH, s7
	rcall	GFX_set_shape					;which shape to write from char table
	rcall	GFX_set_array_pos				;set array position
	rcall	GFX_draw_shape					;draw a shape to the OLED
	ret

	set_pointer		ZL, ZH, s8
	rcall	GFX_set_shape					;which shape to write from char table
	rcall	GFX_set_array_pos				;set array position
	rcall	GFX_draw_shape					;draw a shape to the OLED
	ret
;----------------------------------------------------------------------------
;LIBRARIES
;----------------------------------------------------------------------------

.include	"lib_delay.asm"
.include	"lib_SSD1306_OLED.asm"
.include	"lib_GFX.asm"
	