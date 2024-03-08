
; ------------------------------------------------------------------------
; ??? AL ???????
; ------------------------------------------------------------------------
DispAL:
	push	ecx
	push	edx
	push	edi

	mov	edi, [dwDispPos]

	mov	ah, 0Fh			; 0000b: ???    1111b: ????
	mov	dl, al
	shr	al, 4
	mov	ecx, 2
.begin:
	and	al, 01111b
	cmp	al, 9
	ja	.1
	add	al, '0'
	jmp	.2
.1:
	sub	al, 0Ah
	add	al, 'A'
.2:
	mov	[gs:edi], ax
	add	edi, 2

	mov	al, dl
	loop	.begin
	;add	edi, 2

	mov	[dwDispPos], edi

	pop	edi
	pop	edx
	pop	ecx

	ret
; DispAL ????-------------------------------------------------------------


; ------------------------------------------------------------------------
; ????????????
; ------------------------------------------------------------------------
DispInt:
	mov	eax, [esp + 4]
	shr	eax, 24
	call	DispAL

	mov	eax, [esp + 4]
	shr	eax, 16
	call	DispAL

	mov	eax, [esp + 4]
	shr	eax, 8
	call	DispAL

	mov	eax, [esp + 4]
	call	DispAL

	mov	ah, 07h			; 0000b: ???    0111b: ????
	mov	al, 'h'
	push	edi
	mov	edi, [dwDispPos]
	mov	[gs:edi], ax
	add	edi, 4
	mov	[dwDispPos], edi
	pop	edi

	ret
; DispInt ????------------------------------------------------------------

; ------------------------------------------------------------------------
; ???????????
; ------------------------------------------------------------------------
DispStr:
	push	ebp
	mov	    ebp, esp
	push	ebx
	push	esi
	push	edi

	mov	esi, [ebp + 8]	; pszInfo
	mov	edi, [dwDispPos]
	mov	ah, 0Fh
.1:
	lodsb
	test	al, al
	jz	.2
	cmp	al, 0Ah	; ???????
	jnz	.3
	push	eax
	mov	eax, edi
	mov	bl, 160
	div	bl
	and	eax, 0FFh
	inc	eax
	mov	bl, 160
	mul	bl
	mov	edi, eax
	pop	eax
	jmp	.1
.3:
	mov	[gs:edi], ax
	add	edi, 2
	jmp	.1

.2:
	mov	[dwDispPos], edi

	pop	edi
	pop	esi
	pop	ebx
	pop	ebp
	ret
; DispStr ????------------------------------------------------------------

; ------------------------------------------------------------------------
; ????
; ------------------------------------------------------------------------
DispReturn:
	push	szReturn
	call	DispStr			;printf("\n");
	add	esp, 4

	ret
; DispReturn ????---------------------------------------------------------


; ------------------------------------------------------------------------
; ????????? memcpy
; ------------------------------------------------------------------------
; void* MemCpy(void* es:pDest, void* ds:pSrc, int iSize);
; ------------------------------------------------------------------------
MemCpy:
	push	ebp
	mov	ebp, esp

	push	esi
	push	edi
	push	ecx

	mov	edi, [ebp + 8]	; Destination
	mov	esi, [ebp + 12]	; Source
	mov	ecx, [ebp + 16]	; Counter
.1:
	cmp	ecx, 0		; ????????
	jz	.2		; ??????????????

	mov	al, [ds:esi]		; ??
	inc	esi			; ??
					; ?? ????????
	mov	byte [es:edi], al	; ??
	inc	edi			; ??

	dec	ecx		; ?????????
	jmp	.1		; ???
.2:
	mov	eax, [ebp + 8]	; ?????

	pop	ecx
	pop	edi
	pop	esi
	mov	esp, ebp
	pop	ebp

	ret			; ??????????????
; MemCpy ????-------------------------------------------------------------

; ------------------------------------------------------------------------
; ????????
; ------------------------------------------------------------------------
ClearScreen:
	push	eax
	push	ebx
	push	ecx

	mov		ah, 00000000b			; 0000: ???    0000: ????
	mov		al, 0
	mov		ebx, 0
	mov		ecx, 4000
.1:
	mov		[gs:ebx], ax
	add		ebx, 2
	loop 	.1

	pop		ecx
	pop		ebx
	pop		eax

	ret
; END of ClearScreen -----------------------------------------------------------

; Init8259A ---------------------------------------------------------------------------------------------
Init8259A:
	mov		al, 011h
	out		020h, al		; ??8259, ICW1.
	call	io_delay

	out		0A0h, al		; ??8259, ICW1.
	call	io_delay

	mov		al, 020h		; IRQ0 ?????????? 0x20
	out		021h, al		; ??8259, ICW2.
	call	io_delay

	mov		al, 028h		; IRQ8 ?????????? 0x28
	out		0A1h, al		; ??8259, ICW2.
	call	io_delay

	mov		al, 004h		; IR2 ?????8259
	out		021h, al		; ??8259, ICW3.
	call	io_delay

	mov		al, 002h		; ?????8259?? IR2
	out		0A1h, al		; ??8259, ICW3.
	call	io_delay

	mov		al, 001h
	out		021h, al		; ??8259, ICW4.
	call	io_delay

	out		0A1h, al		; ??8259, ICW4.
	call	io_delay

	;mov	al, 11111111b	; ??????8259???????
	mov		al, 11111110b	; ????????????????
	out		021h, al		; ??8259, OCW1.
	call	io_delay

	mov		al, 11111111b	; ?????8259???????
	out		0A1h, al		; ??8259, OCW1.
	call	io_delay

	ret
; Init8259A ---------------------------------------------------------------------------------------------

; Init8253A --------------------------------------------------------------------
Init8253A:
	mov		al, 00110110b		; ?? 0 ? CONTROL ??
	out		043h, al			; ?? 8253A ??, 2 ?????, ?? 3, ?????
	call	io_delay

	mov		ax, 59659			; ?? 20 Hz, ?????50ms, ?? COUNT ? 1193180 / 20 = 59659
	out		040h, al			; ? COUNT ??????? 0
	call	io_delay

	mov		al, ah
	out		040h, al			; ? COUNT ??????? 0
	call	io_delay

	ret
; END of Init8253A -------------------------------------------------------------

; SetRealmode8259A -------------------------------------------------------------
SetRealmode8259A:
	mov	ax, SelectorData
	mov	fs, ax

	mov	al, 017h
	out	020h, al	; ??8259, ICW1.
	call	io_delay

	mov	al, 008h	; IRQ0 ?????????? 0x8
	out	021h, al	; ??8259, ICW2.
	call	io_delay

	mov	al, 001h
	out	021h, al	; ??8259, ICW4.
	call	io_delay

	mov	al, [fs:SavedIMREG]	; ????????????????(IMREG)????
	out	021h, al		    ; ??
	call	io_delay

	ret
; SetRealmode8259A -------------------------------------------------------------
io_delay:
	nop
	nop
	nop
	nop
	ret

; DispMemSize ????????????-----------------------------------------------------------
DispMemSize:
	push	esi
	push	edi
	push	ecx

	mov		esi, MemChkBuf
	mov		ecx, [dwMCRNumber]		;for(int i = 0; i < [MCRNumber]; i++) // ????????ARDS(Address Range Descriptor Structure)??
.loop:								;{
	mov		edx, 5					;	for(int j = 0; j < 5; j++)	// ????????ARDS?????????5?????
	mov		edi, ARDStruct			;	{
.1:									;		// ?????????BaseAddrLow??BaseAddrHigh??LengthLow??LengthHigh??Type
	push	dword [esi]				;
	call	DispInt					;		DispInt(MemChkBuf[j * 4]); // ?????????
	pop		eax						;
	stosd							;		ARDStruct[j * 4] = MemChkBuf[j * 4];
	add		esi, 4					;
	dec		edx						;
	cmp		edx, 0					;
	jnz		.1						;	}
	call	DispReturn				;	printf("\n");
	cmp		dword [dwType], 1		;	if(Type == AddressRangeMemory) // AddressRangeMemory : 1, AddressRangeReserved : 2
	jne		.2						;	{
	mov		eax, [dwBaseAddrLow]	;
	add		eax, [dwLengthLow]		;
	cmp		eax, [dwMemSize]		;		if(BaseAddrLow + LengthLow > MemSize)
	jb		.2						;
	mov		[dwMemSize], eax		;			MemSize = BaseAddrLow + LengthLow;
.2:									;	}
	loop	.loop					;}
									;
	call	DispReturn				;printf("\n");
	push	szRAMSize				;
	call	DispStr					;printf("RAM size:");
	add		esp, 4					;
									;
	push	dword [dwMemSize]		;
	call	DispInt					;DispInt(MemSize);
	add		esp, 4					;

	pop		ecx
	pop		edi
	pop		esi
	ret
; End of DispMemSize -------------------------------------------------------------------