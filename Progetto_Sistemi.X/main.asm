; TRACCIA
; Si realizzi un firmware che riceva dal computer (tramite porta seriale EUSART) una cifra da 1 a 9 e 
; suoni la nota corrispondente con il buzzer (do, re, ecc). Le note possono essere di durata fissa.
    
    #include "macro.inc"  ; definizione di macro utili

    
    list	p=16f887	; definisco il tipo di processore
    #include	<p16f887.inc>	; file che contiene le definizioni dei simboli (nomi registri, nomi bit dei registri, ecc).
    
;**********************************************************************
; *** Configuration bits ***
; I bit di configurazione (impostazioni dell'hardware settate in fase di
; programmazione del dispostitivo) sono definiti
; tramite una direttiva nel codice.
; Ho attivato il bit

    __CONFIG _CONFIG1, _INTRC_OSC_NOCLKOUT & _CP_OFF & _WDT_OFF & _BOR_OFF & _PWRTE_OFF & _LVP_OFF & _DEBUG_OFF & _CPD_OFF
    
    
;***********************************************************************
; *** Definizione delle costanti ***
; Vado a definire due costanti che saranno i valori 
; che verranno caricati nel contatore del Timer_0 per ottenere il tempo in 
; cui in Buzz emette il suono (Delay_ON)
    
Delay   EQU  (.256 - .195)	; conto 50ms
	
; Definisco ora la costante per il contatore di timer2 con cui ottenere le frequenze
;  delle note desiderate. Dalle impostazioni di timer2 si ha un singolo
;  incremento pari a 16 us. Le note desiderate sono:
;  DO5		f= 261 Hz	T=3831 us	 239 incrementi
;  DO#5		f= 277 Hz	T=3610 us	 225 incrementi
;  RE5		f= 293 Hz	T=3412 us	 213 incrementi
;  RE5#		f= 311 Hz	T= 3215 us	 200 incrementi
;  MI5		f= 330 Hz	T= 3030 us	 189 incrementi
;  FA5		f= 349 HZ	T= 2865 us	 179 incrementi
;  SOL5		f= 392 Hz	T= 2551 us	 159 incrementi
;  LA5		f= 440 Hz	T= 2271 us	 142 incrementi
;  SI5		f= 494 Hz	T= 2024 us	 127 incrementi
	
note_do5	EQU		.60
note_do5#	EQU		.56
note_re5	EQU		.53
note_re5#	EQU		.50
note_mi5	EQU		.47
note_fa5	EQU		.44
note_sol5	EQU		.40
note_la5	EQU		.36
note_si5	EQU		.32
	
;  Questi valori andranno scritti nel registro PR2, dato che il
;  timer2 conta da 0 a PR2 e e riparte da 0, e non da un valore iniziale a FF.
	
;**********************************************************************
; *** Definizione delle variabili ***

; Riservo un byte alla variabile Ch
	UDATA_SHR
ch	RES	    .1
prova   RES	    .1
prova2	RES	    .1
	
;**********************************************************************
; *** Vettore di reset ***
; Il vettore di reset e' l'istruzione che viene eseguita per prima
; dopo un reset del microcontrollore.
; Viene specificato esplicitamente l'indirizzo 0000, in quanto il
; vettore di reset deve trovarsi in questa posizione (codice non rilocabile).

RST_VECTOR	CODE	0x0000
			pagesel	start	
			goto	start			
			
;**********************************************************************
; *** Programma principale ***
; La direttiva CODE dichiara una sezione di codice da allocare in ROM.
; Non viene specificato un indirizzo esplicito, il linker successivamente
; assegnera' un indirizzo assoluto di inizio per la sezione (codice rilocabile)

MAIN		CODE
		
start	    
		; Inizializzazione hardware
		
		pagesel	INIT_HW		
		call	INIT_HW
		
main_loop	
		
wait_ch		
		
		clrf ch
		clrf prova
		clrf prova2
				
		; Entro ora in un loop in attesa di ricevere un carattere
		
		banksel PIR1
		btfss PIR1, RCIF
		goto wait_ch
		
		; Prendo ciò che è contenuto in RCREG (byte ricevuto dalla porta),
		; lo metto in w, per poi inserirlo in char
		
		banksel RCREG
		movf RCREG,w
		
		;movlw .49 ; Per fare le prove
		
		movwf ch
		

		; Scrivo il numero inserito su porta seriale
		banksel TXREG
		movwf TXREG
		banksel PIR1
		btfss PIR1, TXIF
		goto $-1
		
		
		; Controllo ora che il carattere ricevuto sia compreso tra 1 e 9
		; OCCHIO, ricevo caratteri non numeri: in ASCII in carattere 0 
		; corrisponde a 48
		; Come prima cosa controllo che il carattere ricevuto sia maggiore
		; o uguale ad 1 (in ASCII 49)
		
		; Sottraggo al valore contenuto in ch, 49 e salvo il risultato in ch
		; Se il risultato della sottrazione è negativo -> il falg C del registro STATUS
		; sarà uguale a 0 -> torno a wait_ch
		
		movlw .49
		subwf ch,f
		Banksel STATUS
		btfss STATUS, C
		goto main_loop
				
		; Arriviati qui, bisogna controllare che il carattere non sia maggiore di 9
		; OCCHIO: prima ho salvato il risultato della sottrazione in ch
		; quindi ora ho il carattere di prima diminuito di 49
		; Sottraggo questa volta 9 e se C=1, vuol dire che il nuemro è maggiore di 9
		; e quindi devo tornare al wait_ch
		
		movlw .9
		subwf ch,f
		Banksel STATUS
		btfsc STATUS, C
		goto main_loop
		
		addwf ch,f
		; AGGIUNTA: Il carattere non corrisponde più al valore digitato
		; perchè, ad esempio, se avessi inserito 1 (e quindi 49) -> dalla
		; sottrazione ora ho come risultato 0.
		; Per risolvere questo problema sommmo 1 al valore contenuto in ch
		
		; forse no
		
		; incf ch,f
		
		; Controllo ora grazie ad delle sottrazioni qual'è il numero inserito
		; Trovato il numero corretto (sottrazione uguale a zero), passo al
		; all'attivazione del buzzer
				 
		 ; Lavoro con prova 2, in questo modo evito di decrementare sempre ch
		 
		 ; Riscrivo ch su prova2
		 movfw ch
		 movwf prova2
		
		 movlw note_do5
		 movwf prova
		 movlw .1
		 subwf prova2,w
		 btfss STATUS, C
		 goto buzzer
		 
		 ; Riscrivo ch su prova2
		 movf ch,w
		 movwf prova2
		 
		 movlw note_do5#
		 movwf prova
		 movlw .2
		 subwf prova2,w
		 btfss STATUS, C
		 goto buzzer
		 
		 ; Riscrivo ch su prova2
		 movf ch,w
		 movwf prova2
		 
		 movlw note_re5
		 movwf prova
		 movlw .3
		 subwf prova2,w
		 btfss STATUS, C
		 goto buzzer
		 
		 ; Riscrivo ch su prova2		 
		 movf ch,w
		 movwf prova2
		 
		 movlw note_re5#
		 movwf prova
		 movlw .4
		 subwf prova2,w
		 btfss STATUS, C
		 goto buzzer

		 ; Riscrivo ch su prova2		 
		 movf ch,w
		 movwf prova2
		 
		 movlw note_mi5
		 movwf prova
		 movlw .5
		 subwf prova2,w
		 btfss STATUS, C
		 goto buzzer
		 
		 ; Riscrivo ch su prova2
		 movf ch,w
		 movwf prova2
		 
		 movlw note_fa5
		 movwf prova
		 movlw .6
		 subwf prova2,w
		 btfss STATUS, C
		 goto buzzer
		 
		 ; Riscrivo ch su prova2		 
		 movf ch,w
		 movwf prova2
		 
		 movlw note_sol5
		 movwf prova
		 movlw .7
		 subwf prova2,w
		 btfss STATUS, C
		 goto buzzer
		 
		 ; Riscrivo ch su prova2		 
		 movf ch,w
		 movwf prova2
		 
		 movlw note_la5
		 movwf prova
		 movlw .8
		 subwf prova2,w
		 btfss STATUS, C
		 goto buzzer
		 
		 ; Riscrivo ch su prova2		 
		 movf ch,w
		 movwf prova2
		 
		 movlw note_si5
		 movwf prova
		 movlw .9
		 subwf prova2,w
		 btfss STATUS, C
		 
buzzer			
		; Inserisco la frequenza scelta nel registro PR2
		
		movfw prova
		banksel PR2
		movwf	PR2
		
		; Preso dalla prof.
		
		bcf	STATUS, C	; azzera carry per successivo shift
		rrf	PR2, w		; W = PR2 shiftato a destra = meta'
		banksel	CCPR1L
		movwf	CCPR1L
		
		
		; Setto ad 1 il secondo bit del registro T2CON -> attivo il buzzer
		banksel	T2CON
		bsf	T2CON, TMR2ON
		
		; Il buzzer ha iniziato a suonare: applico ora un delay
		 
		call DELAY
		 
		; Spengo il buzzer
		; Setto ad 0 il secondo bit del registro T2CON
		 banksel	T2CON
		 bcf	T2CON, TMR2ON
		 
		call DELAY
		
		goto main_loop
		
		
DELAY
		; Utilizzo del timer in polling: settare il contatore al valore iniziale voluto,
		; azzerare il flag e attendere tramite un loop che il flag venga settato di nuovo.
		movlw	Delay
		banksel	TMR0
		movf	TMR0			; copia W in TMR0 (contatore del timer)
		bcf	INTCON,T0IF		; azzera il flag di overflow di TMR0
		


wait_delay	
		clrwdt				; azzera timer watchdog per evitare reset
			
		; so che la cpu genera un interrupt quando il timer va in overflow -> controllo l'interrupt flag 
		btfss	INTCON,T0IF		; se il flag di overflow del timer è = 1, salta l'istruzione seguente
		goto	wait_delay		; ripeti il loop di attesa
		
		return

		
INIT_HW
		; TIMER_0
		
		; Configuro il registro OPTION_REG (registro di configurazione del timer0):
	
		banksel OPTION_REG
		
		; Setto i primi 3 bit ad 1 -> prescaler 1:256
		
		movlw	B'00000111'		
		movwf	OPTION_REG			
		
		; PORTE
		; Seleziono il banco di memoria in cui c'è TRISA 
		; Non sarà necessarrio poi spostarsi perchè nello stesso banco 
		; trovo anche gli altri TRISx
		
		;port A:
		; RA0-RA5: analog inputs
		; RA6-RA7: digital outputs (flash_ce, bus_switch)
		setRegK PORTA, B'01000000' ; flash_ce = 1, bus_switch = 0 (i2c)
		setRegK ANSEL, B'11111111' ; set RE0-RE2 as analog too
		setRegK TRISA, B'00111111'

		;port B:
		; RB0-RB4: digital inputs (buttons, sd_detect) with pull-up
		; RB5: digital output (sd_ce)
		; RB6-RB7: used by ICSP
		setReg0 ANSELH
		setRegK PORTB, B'00100000' ; sd_ce = 1
		setRegK TRISB, B'11011111'
		setRegK WPUB, B'00011111'

		;port C:
		; RC2: digital output for buzzer
		; others: used by peripherals
		setReg0 PORTC
		setRegK TRISC, B'11111011'

		;port D:
		; RD0-RD3: digital outputs (LEDs)
		; RD4-RD7: not used (digital inputs)
		setReg0 PORTD
		setRegK TRISD, 0xF0

		;port E:
		; RE0-RE2: analog inputs (see ANSEL above)
		; RE3: used by reset
		setReg0 PORTE
		
		; registro INTCON:
		; - tutti gli interrupt inzialmente disabilitati ( lo faccio per evitare che un interrupt possa interrompermi )
		; (verranno abilitati nel programma principale, quando tutte
		;  le periferiche saranno correttamente inizializzate)
			
		clrf	INTCON
			
		; TIMER_2
		
		; Setto i primi 2 bit a 11; in questo modo ho impostato il prescaler a 1:16
		; Setto il bit 2 a 0; in questo modo spengo il Timer_2 (così sono sicuro che all'accensione il buzzer non suoni)
		; Gli altri bit non mi interessano			
			
		banksel T2CON
		movlw B'00000011'
		movwf T2CON
		
		; Configuro il registro CCP1CON
		; Lascio i primi 4 bit come di default per la modalità PWM
		banksel	CCP1CON
		movlw	B'00001100'
		movwf	CCP1CON
		
		; EUSART
		
		; Nel registro TXSTA imposto il quinto bit ad 1 per abilitare 
		; la trasmissione il bit 4 a 0 per usare la modalità asincrona 
		; ed il bit 2 ad 1 per usare un'high speed in asynchronus mode
		
		banksel TXSTA
		movlw B'00100100'   
		movwf TXSTA
		
		; Carico 25 sul registro SPBRG (regola la velocità di 
		; trasmissione)
		banksel SPBRG
		movlw .25
		movwf SPBRG
		
		; Nel registro BAUDCTL setto a zero tutti i bit 
		banksel BAUDCTL 
		clrf BAUDCTL

		; Nel registro RCSTA setto ad 1 il bit 7 per abilitare la porta 
		; seriale e a 1 il bit 4 per abilitare la ricezione da porta 
		; seriale
		banksel RCSTA
		movlw B'10010000' 
		movwf RCSTA
		
		return
		
		END