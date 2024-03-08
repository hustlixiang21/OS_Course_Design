; ==========================================
; pmtest5.asm
; ���뷽����nasm pmtest5.asm -o pmtest5.com
;����Ĵ���ִ�й����ǣ�����ģʽ�½���16b�Ĵ���Σ�ring=0����ʼ����ض�������������������ldt�����������ݶ�����������ջ����������ldt�е���������ring 3�Ĵ����������TSS��������
;����gdt��ͨ����jmp�����뱣��ģʽ������32b�Ĵ���Σ�ring =0����ʼ�����ݶΡ���ջ�Ρ���Ƶ�ε�ѡ���ӼĴ�������ʾһ���ַ�����load TSS��
;����retfָ���ring 0ת�Ƶ�ring 3�Ĵ���Σ��ڴ��������ʾ��3����Ȼ��ͨ�������Ž���ring 0�Ĵ���Σ���ӡ��ĸC��Ȼ��ͨ��jmp��ת���ֲ�����Σ���ӡ��ĸ��L��������ص�ring 3����Ϊѭ����
; ==========================================

%include	"pmtestSrc/pmtest5/pm.inc"	; ����, ��, �Լ�һЩ˵��

org	0100h
	jmp	LABEL_BEGIN     ;LABEL_BEGIN �����������ʱ����ڴ�������ʵģʽ�£�����Ҫѡ����

[SECTION .gdt]
; GDT
;                                         �λ�ַ,         �ν���     , ����
LABEL_GDT:		Descriptor	       0,                   0, 0			; ��������
LABEL_DESC_NORMAL:	Descriptor	       0,              0ffffh, DA_DRW			; Normal ������
LABEL_DESC_CODE32:	Descriptor	       0,    SegCode32Len - 1, DA_C + DA_32		; ��һ�´����, 32;������������Ļ���ַ������λ0���Ժ�Ҫ����Ϊ32λ����������׵�ַ
LABEL_DESC_CODE16:	Descriptor	       0,              0ffffh, DA_C			; ��һ�´����, 16
LABEL_DESC_CODE_DEST:	Descriptor	       0,  SegCodeDestLen - 1, DA_C + DA_32		; ��һ�´����, 32;ʵ�ʻ�ַ��s16ʵģʽ��
LABEL_DESC_CODE_RING3:	Descriptor	       0, SegCodeRing3Len - 1, DA_C + DA_32 + DA_DPL3	; ��һ�´����, 32
LABEL_DESC_DATA:	Descriptor	       0,	  DataLen - 1, DA_DRW			; Data
LABEL_DESC_STACK:	Descriptor	       0,          TopOfStack, DA_DRWA + DA_32		; Stack, 32 λ
LABEL_DESC_STACK3:	Descriptor	       0,         TopOfStack3, DA_DRWA + DA_32 + DA_DPL3; Stack, 32 λ��ring3
LABEL_DESC_LDT:		Descriptor	       0,          LDTLen - 1, DA_LDT			; LDT
LABEL_DESC_TSS:		Descriptor	       0,          TSSLen - 1, DA_386TSS		; TSS
LABEL_DESC_VIDEO:	Descriptor	 0B8000h,              0ffffh, DA_DRW + DA_DPL3		; �Դ��׵�ַ,���32λ����ε������׵�ַ����ʵģʽ�¼���õ���.;Ϊ������ring 3�ж�д�Դ棬���Ǹı����Դ�ε���Ȩ����

; ��                                            Ŀ��ѡ����,       ƫ��, DCount, ����
LABEL_CALL_GATE_TEST:	Gate		  SelectorCodeDest,          0,      0, DA_386CGate + DA_DPL3  ;������������Ȩ����Ҳ��ring 3����Ȼû�����ʣ�GateΪ�꣬��Descriptor����
; GDT ����

GdtLen		equ	$ - LABEL_GDT	; GDT����
GdtPtr		dw	GdtLen - 1	; GDT����,���ȶ���ʵ�ʳ��ȼ�һ;������һ��Gdtptr�����ݽṹ����16λdw����Ϊλ�ν��ޣ���32λΪ0��һ��48λ����32λ�Ժ�Ҫ����
		dd	0		; GDT����ַ���λ���ַ������֮����û��ֱ���ƶ�������Ϊ��û��ȷ������ģʽ��gdt�Ļ���ַ;0��1Ϊ��16λ����32λ�Ǵ�2��ʼ������GdtPtr+2����32λӦ�÷�GDT��������ַ

; GDT ѡ����
SelectorNormal		equ	LABEL_DESC_NORMAL	- LABEL_GDT					;���ѡ������ת�������ʵģʽ�����
SelectorCode32		equ	LABEL_DESC_CODE32	- LABEL_GDT					;���ѡ������ת�������32λ����ģʽ����Ρ���Ϊselectorѡ���������ڱ���ģʽ�µģ� ��ʹ��32λ�ı���ģʽ
SelectorCode16		equ	LABEL_DESC_CODE16	- LABEL_GDT                 ;���ѡ������ת�������16λ����ģʽ����Ρ���Ϊselectorѡ���������ڱ���ģʽ�µģ� ��ʹ��16λ�ı���ģʽ
SelectorCodeDest	equ	LABEL_DESC_CODE_DEST	- LABEL_GDT	            ;���ѡ������ת�������ring0�������
SelectorCodeRing3	equ	LABEL_DESC_CODE_RING3	- LABEL_GDT + SA_RPL3   ;���ѡ������ת�������ring3�������
SelectorData		equ	LABEL_DESC_DATA		- LABEL_GDT					;���ѡ������ת����������ݶ�
SelectorStack		equ	LABEL_DESC_STACK	- LABEL_GDT					;���ѡ������ת������Ķ�ջ��(ring0��)
SelectorStack3		equ	LABEL_DESC_STACK3	- LABEL_GDT + SA_RPL3       ;���ѡ������ת������Ķ�ջ��(ring3��)
SelectorLDT		equ	LABEL_DESC_LDT		- LABEL_GDT						;LDTѡ������ת���������������
SelectorTSS		equ	LABEL_DESC_TSS		- LABEL_GDT		                ;���ѡ������ת������ĳ�ʼ������״̬��ջ��
SelectorVideo		equ	LABEL_DESC_VIDEO	- LABEL_GDT					;��Ƶѡ������ת��������Դ��׵�ַ

SelectorCallGateTest	equ	LABEL_CALL_GATE_TEST	- LABEL_GDT + SA_RPL3     ;���ѡ������ת����������Ȩ���任�Ĵ����
; END of [SECTION .gdt]

;section�Ͷ�֮��û�б�Ȼ����ϵ��һ������ϰ�߽�һ��section����һ�������棬���������û�ϰ�ߣ������﷨Ҫ�󡪡����ǿ��԰�����section���ڶ����档
;mov ax��cs�����ʵģʽ��offsetһ�㲻����0������ģʽ�£���һ���ƫ��һ����0.

[SECTION .data1]	 ; ���ݶ�
ALIGN	32           ;align��һ�������ݶ���ĺꡣͨ��align�Ķ�����1��4��8�ȡ������align 32��û������ģ���Ϊ��������ֻ��32b�ĵ�ַ���߿��ȡ�
[BITS	32]          ;'BITS'ָ��ָ��NASM�����Ĵ����Ǳ����������16λģʽ�Ĵ������ϻ���������32λģʽ�Ĵ�������,BITS 32��ָ����������32λģʽ�Ĵ�������
LABEL_DATA:                                         ;���ݶ�
SPValueInRealMode	dw	0                           ;��������ʵģʽ��sp����������ʵģʽǰ���¸�ֵ��sp
; �ַ���
PMMessage:		db	"In Protect Mode now. ^-^", 0	; ���뱣��ģʽ����ʾ���ַ���,
               
OffsetPMMessage		equ	PMMessage - $$              ;$:��ǰ�б����֮��ĵ�ַ����ʵ�ʵ����Ե�ַ,$$:һ��section�Ŀ�ʼ�ط�������Ժ�ĵ�ַ��Ҳ��ʵ�ʵ����Ե�ַ,pmmessage:ƫ�Ƶ�ַ����Զε��׵�ַ��
                                                    ;���λ�����Ȼ�ڳ�ʼ������������ʱ����Ȼ�����˱仯����������base*16+offset����offset�ǲ�ͬ�ģ���
													;��pmmessage-$$������ʵ���壬pmmessage��$$����ʾʵģʽ�������λ���ַ��offset�����������Ŷλ���ַ��Ư�ƣ�
													;$$������׵�ַ������pmmessage��Ӧ�ڱ���ģʽ�µ�ƫ����ȻҲ�ͷ����˱仯����Ҫ��ȥ$$��Ӧ�ĵ�ַ���С�
StrTest:		db	"ABCDEFGHIJKLMNOPQRSTUVWXYZ", 0 ;����ͬ��
OffsetStrTest		equ	StrTest - $$
DataLen			equ	$ - LABEL_DATA                  ;���ݶγ���
; END of [SECTION .data1]


; ȫ�ֶ�ջ��
[SECTION .gs]
ALIGN	32         ;align��һ�������ݶ���ĺꡣͨ��align�Ķ�����1��4��8�ȡ������align 32��û������ģ���Ϊ��������ֻ��32b�ĵ�ַ���߿��ȡ�
[BITS	32]        ;32λģʽ�Ļ�������
LABEL_STACK:       ;����LABEL_STACK
	times 512 db 0
TopOfStack	equ	$ - LABEL_STACK - 1  ;��ջ�εĴ�С
; END of [SECTION .gs]             //�ڲ�ring0����ջ��


; ��ջ��ring3
[SECTION .s3]
ALIGN	32          ;align��һ�������ݶ���ĺꡣͨ��align�Ķ�����1��4��8�ȡ������align 32��û������ģ���Ϊ��������ֻ��32b�ĵ�ַ���߿��ȡ�
[BITS	32]         ;32λģʽ�Ļ�������
LABEL_STACK3:       ;����LABEL_STACK3
	times 512 db 0
TopOfStack3	equ	$ - LABEL_STACK3 - 1  ;���ring3����ջ�εĴ�С
; END of [SECTION .s3]            //���ring3����ջ��


; TSS ---------------------------------------------------------------------------------------------
;��ʼ������״̬��ջ��(TSS)
[SECTION .tss]          ;��ø��εĴ�С
ALIGN	32              ;align��һ�������ݶ���ĺꡣͨ��align�Ķ�����1��4��8�ȡ������align 32��û������ģ���Ϊ��������ֻ��32b�ĵ�ַ���߿��ȡ�
[BITS	32]             ;32λģʽ�Ļ�������
LABEL_TSS:              ;����LABEL_TSS
		DD	0			; Back
		DD	TopOfStack		; 0 ����ջ   //�ڲ�ring0����ջ����TSS��
		DD	SelectorStack		; 
		DD	0			; 1 ����ջ
		DD	0			; 
		DD	0			; 2 ����ջ
		DD	0			;               //TSS�����ֻ�ܷ���Ring2����ջ��ring3����ջ����Ҫ����
		DD	0			; CR3
		DD	0			; EIP
		DD	0			; EFLAGS
		DD	0			; EAX
		DD	0			; ECX
		DD	0			; EDX
		DD	0			; EBX
		DD	0			; ESP
		DD	0			; EBP
		DD	0			; ESI
		DD	0			; EDI
		DD	0			; ES
		DD	0			; CS
		DD	0			; SS
		DD	0			; DS
		DD	0			; FS
		DD	0			; GS
		DD	0			; LDT
		DW	0			; ���������־
		DW	$ - LABEL_TSS + 2	; I/Oλͼ��ַ
		DB	0ffh			; I/Oλͼ������־
TSSLen		equ	$ - LABEL_TSS   ;��öεĴ�С
; TSS ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


[SECTION .s16]          ;ʵģʽ������β���Ҫѡ���ӵģ���Ϊ������ʵģʽ�¡�������Ҫ��ʼ�����������Ķλ�ַ������һ��16λ����� ��������޸���gdt�е�һЩֵ Ȼ��ִ����ת��������section
[BITS	16]             ;32λģʽ�Ļ������� 
LABEL_BEGIN:            ;ʵģʽ�µĴ���
	mov	ax, cs          
	mov	ds, ax          
	mov	es, ax
	mov	ss, ax          ;���ds es ss����cs,��ʾ����κ����ݶ���ͬһƬ�ڴ��ϣ�ֻ��ƫ������һ����
                        ;�����μĴ�����Ӧ������ɽֵ��ţ�����ƫ������Ӧ����������ƺ�,ֻ������������������γ�������������ַ��
					    ;���������ֻ����ƫ������ʵ����Ҳ�ǺͲ���ϵͳ��Ĭ�ϵ����ƫ�����ĶμĴ�����ֻ�Ǵ���û����ʽ�������ѣ�һ�����������ַ��
					    ;����ip��Ĭ�ϵĶμĴ�������cs��������Ҳ������ʽ�����μĴ�����ƫ���������ʱ��ĶμĴ����Ͳ�һ�������ƫ������Ĭ�ϵĶμĴ�����
	mov	sp, 0100h       ;��ջָ��ָ��0100h

	mov	[LABEL_GO_BACK_TO_REAL+3], ax  ;Ϊ�ص�ʵģʽ�������תָ��ָ����ȷ�Ķε�ַ��LABEL_GO_BACK_TO_REAL+3ǡ�þ���Segment�ĵ�ַ���������ŵ�mov ax��csָ��ִ��֮ǰax��ֵ�Ѿ���ʵģʽ�µ�cs
	                                   ;����������cs���浽Segment��λ�ã��ȵ�[SECTION .s16code]��jmpָ��ִ��ʱ����jmp  0:LABEL_REAL_ENTRY,�������jmp cs_real_mode:LABEL_REAL_ENTRY    
	mov	[SPValueInRealMode], sp        ;��SPValueInRealModeѹ���ջ��

	; ��ʼ�� 16 λ�����������
	mov	ax, cs                         
	movzx	eax, ax                    ;��cs�Ĵ����е����ݴ���eax�Ĵ�����
	shl	eax, 4                         ;����4λ
	add	eax, LABEL_SEG_CODE16          ;�������
	mov	word [LABEL_DESC_CODE16 + 2], ax  
	shr	eax, 16                        ;����16λ
	mov	byte [LABEL_DESC_CODE16 + 4], al
	mov	byte [LABEL_DESC_CODE16 + 7], ah  ;���������η���16λ������У���ʼ�� 16 λ�����������

	; ��ʼ�� 32 λ�����������
	;���ǿ�����ʵģʽ��ͨ�� �μĴ�����16 �� ƫ���� �õ�������ַ����ô�����ǾͿ��Խ����������ַ�ŵ����������У��Թ�����ģʽ��ʹ�ã���Ϊ����ģʽ��ֻ��ͨ����ѡ���� �� ƫ����
	xor	eax, eax
	mov	ax, cs
	shl	eax, 4                             
	add	eax, LABEL_SEG_CODE32
	mov	word [LABEL_DESC_CODE32 + 2], ax       ;������ַ��ax���ڶλ�ַ 2��3
	shr	eax, 16
	mov	byte [LABEL_DESC_CODE32 + 4], al
	mov	byte [LABEL_DESC_CODE32 + 7], ah

	; ��ʼ�����Ե����ŵĴ����������
	xor	eax, eax
	mov	ax, cs
	shl	eax, 4
	add	eax, LABEL_SEG_CODE_DEST               ;�����ŵĴ����
	mov	word [LABEL_DESC_CODE_DEST + 2], ax
	shr	eax, 16
	mov	byte [LABEL_DESC_CODE_DEST + 4], al
	mov	byte [LABEL_DESC_CODE_DEST + 7], ah

	; ��ʼ�����ݶ�������
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_DATA
	mov	word [LABEL_DESC_DATA + 2], ax
	shr	eax, 16
	mov	byte [LABEL_DESC_DATA + 4], al
	mov	byte [LABEL_DESC_DATA + 7], ah

	; ��ʼ����ջ��������(ring0)
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_STACK
	mov	word [LABEL_DESC_STACK + 2], ax
	shr	eax, 16
	mov	byte [LABEL_DESC_STACK + 4], al
	mov	byte [LABEL_DESC_STACK + 7], ah

	; ��ʼ����ջ��������(ring3)
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_STACK3
	mov	word [LABEL_DESC_STACK3 + 2], ax
	shr	eax, 16
	mov	byte [LABEL_DESC_STACK3 + 4], al
	mov	byte [LABEL_DESC_STACK3 + 7], ah

	; ��ʼ�� LDT �� GDT �е�������,LABEL_LDTΪLDT�Ķ����ַ
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_LDT
	mov	word [LABEL_DESC_LDT + 2], ax
	shr	eax, 16
	mov	byte [LABEL_DESC_LDT + 4], al
	mov	byte [LABEL_DESC_LDT + 7], ah

	; ��ʼ�� LDT �е�������,LABEL_CODE_A����������LDT����
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_CODE0
	mov	word [LABEL_LDT_DESC_CODEA + 2], ax
	shr	eax, 16
	mov	byte [LABEL_LDT_DESC_CODEA + 4], al
	mov	byte [LABEL_LDT_DESC_CODEA + 7], ah

	; ��ʼ��Ring3������
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_CODE_RING3
	mov	word [LABEL_DESC_CODE_RING3 + 2], ax
	shr	eax, 16
	mov	byte [LABEL_DESC_CODE_RING3 + 4], al
	mov	byte [LABEL_DESC_CODE_RING3 + 7], ah

	; ��ʼ�� TSS ������
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_TSS
	mov	word [LABEL_DESC_TSS + 2], ax
	shr	eax, 16
	mov	byte [LABEL_DESC_TSS + 4], al
	mov	byte [LABEL_DESC_TSS + 7], ah

	; Ϊ���� GDTR ��׼��
	xor	eax, eax
	mov	ax, ds              ;GDT�Ķε�ַΪ���ݼĴ���DS
	shl	eax, 4
	add	eax, LABEL_GDT		; eax <- gdt ����ַ
	mov	dword [GdtPtr + 2], eax	; [GdtPtr + 2] <- gdt ����ַ,dword ��ʾ��˫������Ϊ32λ��eaxҲ��32λ

	; ���� GDTR
	
	lgdt	[GdtPtr]        ;���ص�gdtr,��Ϊ���ڶ������������ڴ��У����Ǳ���Ҫ��CPU֪���������� �����ĸ�λ��ͨ��ʹ��lgdtr�Ϳ��Խ�Դ���ص�gdtr�Ĵ�����

	; ���ж�
	cli

	; �򿪵�ַ��A20
	in	al, 92h
	or	al, 00000010b
	out	92h, al

	; ׼���л�������ģʽ,����PEΪ1
	mov	eax, cr0           ;���Ĵ���cr0�е�����ת�Ƶ�eax�Ĵ�����
	or	eax, 1             ;�����߼����������eax�Ĵ�����1
	mov	cr0, eax           ;�����Ѿ����ڱ���ģʽ�ֶλ����£�����Ѱַ����ʹ�ö�ѡ���ӣ�ƫ������Ѱַ

	; �������뱣��ģʽ
	jmp	dword SelectorCode32:0	; ִ����һ���� SelectorCode32 װ�� cs, ����ת�� Code32Selector:0 ������Ϊ��ʱƫ����λ32λ�����Ա���dword���߱���������Ȼ���������������16λ

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LABEL_REAL_ENTRY:		; �ӱ���ģʽ���ص�ʵģʽ�͵�������
	mov	ax, cs
	mov	ds, ax
	mov	es, ax
	mov	ss, ax                      ;���ds es ss����cs,��ʾ����κ����ݶ���ͬһƬ�ڴ��ϣ�ֻ��ƫ������һ����

	mov	sp, [SPValueInRealMode]     ;ָ������˶�ջ��  ���ص�ʵģʽ

	in	al, 92h		; ��
	and	al, 11111101b	; �� �ر� A20 ��ַ��
	out	92h, al		; ��

	sti			; ���ж�

	mov	ax, 4c00h	; ��
	int	21h		; ���ص� DOS
; END of [SECTION .s16]                    //���ص�ʵģʽ����ɻص�DOS�Ĺ���


[SECTION .s32]; 32 λ����εı���ģʽ����ʵģʽ����,��Ҫѡ����SelectorCode32
[BITS	32]   ;32λģʽ�Ļ�������

LABEL_SEG_CODE32:        ;����LABEL_SEG_CODE32
	mov	ax, SelectorData
	mov	ds, ax			; ���ݶ�ѡ����
	mov	ax, SelectorVideo
	mov	gs, ax			; ��Ƶ��ѡ����,gsָ���Դ�

	mov	ax, SelectorStack
	mov	ss, ax			; ��ջ��ѡ����     //ss esp ָ���ڲ�ring0��ջ

	mov	esp, TopOfStack ;ȷ����ջ�εĴ�С


	; ������ʾһ���ַ���
	mov	ah, 0Ch			; 0000: �ڵ�    1100: ����
	xor	esi, esi                ;��esi�Ĵ����ÿ�
	xor	edi, edi                ;��edi�Ĵ����ÿ�
	mov	esi, OffsetPMMessage	; Դ����ƫ��
	mov	edi, (80 * 10 + 0) * 2	; Ŀ������ƫ�ơ���Ļ�� 10 ��, �� 0 �С�
	cld                         ; �����ַ�����ǰ�ƶ�
.1:
	lodsb                       ;���ַ����е�siָ����ָ���һ���ֽ�װ��al��
	test	al, al              
	jz	.2                      ;�ж�al�Ƿ�Ϊ��  Ϊ����ת��2
	mov	[gs:edi], ax            ;��Ϊ����ʾ��ǰ�ַ�
	add	edi, 2                  ;edi�Ӷ�  
	jmp	.1
.2:	; ��ʾ���

	call	DispReturn          ;�س� ����

	; Load TSS
	mov	ax, SelectorTSS         ;ltr ��ring0��ָ�ֻ��������ring0��������С���ring0����Ҫ�ֶ�����tssʵ�ֶ�ջ�л�����call����ϵͳ�Զ�����tss�л���
	ltr	ax	; �������ڷ�����Ȩ���任ʱҪ�л���ջ�����ڲ��ջ��ָ�����ڵ�ǰ�����TSS�У�����Ҫ��������״̬�μĴ��� TR��

	push	SelectorStack3      ;ִ��retfָ��ʱϵͳ�����ѡ����(ring3��)
	push	TopOfStack3         ;ִ��retfָ��ʱϵͳ���Զ��ڵ��Ĳ��л���ring3���������ջ
	push	SelectorCodeRing3   ;retf ʱ����Ҫ����ѡ���ӵ�rpl�����Ƿ���Ҫ�任��Ȩ��
	push	0                   ;��Ȩת��ʹ��retfʹ��֮ǰ��ѹ��ss��sp��cs��ip ���ڲ�Ring0��ջ  push 0 ��ʾipΪ0.    0Ϊƫ����
	retf				; Ring0 -> Ring3����ʷ��ת�ƣ�����ӡ���� '3'������ret��retf���Ǻ�call���ʹ�õ�ָ��������ضϵ㡣
	                    ;���ﵥ��ʹ�ã���������Ϊ����[SECTION .32]����[SECTION .ring3]���������Ӹ���Ȩ����ת������Ȩ������ת���̣�
						;step1:��鱻�����߶�ջ�б����CS�е�RPL����Ӧ����push SelectorCodeRing3�������жϷ���ʱ�Ƿ�Ҫ�任��Ȩ����
						;��ʱ���ֵ�ǰ��Ȩ��Ϊ0��ת����Ȩ��Ϊ3�Ĵ���Σ���������Ȩ���仯����-->�ͣ���
						;step2:���ر������߶�ջ�ϵ�cs��eip��SelectorCodeRing3��0������ʱ���ͷ��ضϵ��ˡ����ڱ�������cs��eip�Ѿ�ָ��[SECTION .ring3]���ˡ�
						;step3:��retf������������������esp������������ǰ��ջ�Ǳ�������([SECTION .s32])��ջ��
						;step4:���ر�������([SECTION .s32)��ջ�е�ss��esp���л���������([SECTION .ring3])��ջ����ʱ����������([SECTION .s32)��ջ�е�ss��esp�������������ڵȻ����Ҫ��
						;����Ȩ��ת���ظ���Ȩ��������Ҫ����0����ջ��SelectorStack��TopOfStack����ǰ����TSS����ʱ����ǰ��ջ�ӱ�������([SECTION .s32])��ջ����˵�����([SECTION .ring3)��ջ�ˡ�
						;step5:��retf������������������esp������������ǰ��ջ�ǵ�����([SECTION .ring3)��ջ��
						;step6:���ds��es��fs��gs��ֵ�����������һ���Ĵ���ָ��Ķε�DPLС��CPL���˹���������һ�´���Σ�����ôһ���������������ص��üĴ�������ʱ�⼸���Ĵ��������ÿ���������

; ------------------------------------------------------------------------
DispReturn:             ;��ӡһ���س�,return��ʾ�س�
	push	eax
	push	ebx
	mov	eax, edi
	mov	bl, 160
	div	bl
	and	eax, 0FFh
	inc	eax
	mov	bl, 160
	mul	bl
	mov	edi, eax
	pop	ebx
	pop	eax

	ret
; DispReturn ����---------------------------------------------------------

SegCode32Len	equ	$ - LABEL_SEG_CODE32       ;����32λ����εĴ�С
; END of [SECTION .s32]


[SECTION .sdest]; ������Ŀ��Σ�[SECTION .sdest]���Ƿ�һ��32λ�Σ�����DPL=0�����ҵ�ǰCPL=0�����˺��õ��ġ�DPL���͡�ѡ�����е�RPL����Ϊ0�����������Ȩ������ת������Ҫ���Ȩ�޼����
[BITS	32]

LABEL_SEG_CODE_DEST:    ;ring0�������
	mov	ax, SelectorVideo
	mov	gs, ax			; ��Ƶ��ѡ����(Ŀ��)

	mov	edi, (80 * 12 + 0) * 2	; ��Ļ�� 12 ��, �� 0 �С�
	mov	ah, 0Ch			; 0000: �ڵ�    1100: ����
	mov	al, 'C'         ;���ַ���C������al�Ĵ�����
	mov	[gs:edi], ax    ;��Ϊ����ʾ��ǰ�ַ�

	; Load LDT
	mov	ax, SelectorLDT ;��LDTѡ��������ax�Ĵ�����
	lldt	ax          ;���ؾֲ�������

	jmp	SelectorLDTCodeA:0	; ����LDT����ľֲ��Σ�����ֲ����񣬽���ӡ��ĸ 'L'��

	retf                   ;ͨ��retf����ɴ�Ring0-->Ring3����ת��������Ȩ����ת������Ȩ��,��ת������"jmp $"

SegCodeDestLen	equ	$ - LABEL_SEG_CODE_DEST   ;���������Ŀ��εĴ�С
; END of [SECTION .sdest]


; 16 λ�����. �� 32 λ���������, ������ʵģʽ
[SECTION .s16code]
ALIGN	32
[BITS	16]
LABEL_SEG_CODE16:
	; ����ʵģʽ:
	mov	ax, SelectorNormal  
	mov	ds, ax
	mov	es, ax
	mov	fs, ax
	mov	gs, ax
	mov	ss, ax               ;ͨ������ʵģʽ�����ԣ��ν��޵�ѡ����SelectorNormal���Ը����Ĵ����ĸ��ٻ������¸�ֵ��ʹ֮����ʵģʽ��״̬

	mov	eax, cr0
	and	al, 11111110b
	mov	cr0, eax             ;��cr0ĩλΪ0

LABEL_GO_BACK_TO_REAL:
	jmp	0:LABEL_REAL_ENTRY	; �ε�ַ���ڳ���ʼ�������ó���ȷ��ֵ,ͨ��ʵģʽ�µ���ת����ɶ�CS�ĸ�ֵ

Code16Len	equ	$ - LABEL_SEG_CODE16    ;���Ͼ�Ӧ��LABEL_REAL_ENTRY������ƺţ��Ʋ⵽�Ǹ��ֵ���LABEL_BEGIN��

; END of [SECTION .s16code]             //��������[section .!!!]��������룬ͨ��ѡ������ɸ�section֮�����ת��


; LDT
[SECTION .ldt]
ALIGN	32
LABEL_LDT:
;                                         �λ�ַ       �ν���     ,   ����
LABEL_LDT_DESC_CODEA:	Descriptor	       0,     CodeALen - 1,   DA_C + DA_32	; Code, 32 λ

LDTLen		equ	$ - LABEL_LDT           ;����LDT�Ĵ�С

; LDT ѡ����
SelectorLDTCodeA	equ	LABEL_LDT_DESC_CODEA	- LABEL_LDT + SA_TIL
; END of [SECTION .ldt]


; CodeA (LDT, 32 λ�����)
[SECTION .la]
ALIGN	32
[BITS	32]
LABEL_CODE0:
	mov	ax, SelectorVideo
	mov	gs, ax			; ��Ƶ��ѡ����(Ŀ��)

	mov	edi, (80 * 13 + 0) * 2	; ��Ļ�� 13 ��, �� 0 �С�
	mov	ah, 0Ch			; 0000: �ڵ�    1100: ����
	mov	al, 'L'
	mov	[gs:edi], ax    ;��Ϊ����ʾ��ǰ�ַ�'L'

	
	jmp	SelectorCode16:0 ; ׼������16λ���������ʵģʽ
CodeALen	equ	$ - LABEL_CODE0       ;����CodeA (LDT, 32 λ�����)�Ĵ�С
; END of [SECTION .la]


; CodeRing3
[SECTION .ring3]
ALIGN	32
[BITS	32]
LABEL_CODE_RING3:       ;ring3�������
	mov	ax, SelectorVideo
	mov	gs, ax			; ��Ƶ��ѡ����(Ŀ��)

	mov	edi, (80 * 14 + 0) * 2	; ��Ļ�� 14 ��, �� 0 �С�
	mov	ah, 0Ch			; 0000: �ڵ�    1100: ����
	mov	al, '3'
	mov	[gs:edi], ax    ;��Ϊ����ʾ��ǰ�ַ�'3'

	call	SelectorCallGateTest:0	; ʹ��call������ʵ����Ȩת����ʵ�ִ�ring3---->ring0�������ת��ͨ�������Ŵӵ͵�����Ȩ����
	                                ;��ת����: step1:ָʾ�����ŵ�ѡ���ӵ�RPL<=��������DPL & ��ǰ����ε�CPL<=����������DPL����ʱ,��[SECTION .ring3]�С�
									;��Ϊ[SECTION .ring3]�Ƿ�һ�´���Σ����ڴ�[SECTION .s32]��ת���ö�ʱ���Ѿ�����CPL=3  ����˵����ʱCPL=3��
                                    ;call SelectorCallGateTest:0���õ����ţ���SelectorCallGateTest	equ	LABEL_CALL_GATE_TEST	- LABEL_GDT + SA_RPL3����֪�������ŵ�RPLΪ3��
									;����˵����ʱRPL=3���ֵ����ŵ�DPL=3�� ���������ε������У� CPL<=������DPL & RPL<=������DPL���ʿ��Է��ʵ��������е�Ŀ���ѡ������^_^
                                    ;step2:   CPL>=DPL��RPL������飨��ΪRPL�ܱ���0�����ڣ�CPL=3�� Ŀ���[SECTION .sdest]��DPL=0����Ϊ��һ�´���Ρ�
									;��CPL>=DPL(RPL�������)��������Ȩ����飬��ת��[SECTION .sdest].
									;step3:��ת��CPL���޸�Ϊ0(ԭ��Ϊ3)��ΪCPL=Ŀ���[SECTION .sdest]��DPL(=0)����ˣ���ת��[SECTION .sdest]��CPL=0 
    jmp $									
SegCodeRing3Len	equ	$ - LABEL_CODE_RING3   ;��Ϊ����3���Ĵ����У�������ҲҪ����Ϊ3����ͨ�������ſ�������0������
; END of [SECTION .ring3]
