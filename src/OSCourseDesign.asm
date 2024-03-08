; -----------------------------------------------------------------
; TASK4
; 编译方法：nasm task4.asm -o task4.com
; -----------------------------------------------------------------

%include "./include/pm.inc"

; 4个任务页目录地址
PageDirBase0		equ	200000h	; 页目录开始地址:	2M
PageTblBase0		equ	201000h	; 页表开始地址:		2M + 4K
PageDirBase1		equ	210000h	; 页目录开始地址:	2M + 64K
PageTblBase1		equ	211000h	; 页表开始地址:		2M + 64K + 4K
PageDirBase2		equ	220000h	; 页目录开始地址:	2M + 128K
PageTblBase2		equ	221000h	; 页表开始地址:		2M + 128K + 4K
PageDirBase3		equ	230000h	; 页目录开始地址:	2M + 192K
PageTblBase3		equ	231000h	; 页表开始地址:		2M + 192K + 4K

org 0100h
    jmp LABEL_BEGIN

;===============================================================================================================
; GDT段定义
;===============================================================================================================
[SECTION .gdt]
;                                  段基址,             段界限, 属性
LABEL_GDT:			Descriptor	      	0,                 0, 0								; 空描述符
LABEL_DESC_NORMAL:	Descriptor	       	0,            0ffffh, DA_DRW						; Normal 描述符
LABEL_DESC_FLAT_C:	Descriptor         	0,           0fffffh, DA_CR | DA_32 | DA_LIMIT_4K	; 0 ~ 4G
LABEL_DESC_FLAT_RW:	Descriptor        	0,           0fffffh, DA_DRW | DA_LIMIT_4K			; 0 ~ 4G
LABEL_DESC_CODE32:	Descriptor	      	0,  SegCode32Len - 1, DA_CR | DA_32					; 非一致代码段, 32
LABEL_DESC_CODE16:	Descriptor	       	0,            0ffffh, DA_C							; 非一致代码段, 16
LABEL_DESC_DATA:	Descriptor	       	0,		 DataLen - 1, DA_DRW							; Data
LABEL_DESC_STACK:	Descriptor	       	0,        TopOfStack, DA_DRWA | DA_32				; Stack, 32 位
LABEL_DESC_VIDEO:	Descriptor	  0B8000h,            0ffffh, DA_DRW + DA_DPL3				; 显存首地址
; TSS
LABEL_DESC_TSS0: 	Descriptor 			0,          TSS0Len-1, DA_386TSS	;TSS0
LABEL_DESC_TSS1: 	Descriptor 			0,          TSS1Len-1, DA_386TSS	;TSS1
LABEL_DESC_TSS2: 	Descriptor 			0,          TSS2Len-1, DA_386TSS	;TSS2
LABEL_DESC_TSS3: 	Descriptor 			0,          TSS3Len-1, DA_386TSS	;TSS3

; 4个任务的ldt
LABEL_TASK0_DESC_LDT:    Descriptor         0,   TASK0LDTLen - 1, DA_LDT    ;LDT0
LABEL_TASK1_DESC_LDT:    Descriptor         0,   TASK1LDTLen - 1, DA_LDT	;LDT1
LABEL_TASK2_DESC_LDT:    Descriptor         0,   TASK2LDTLen - 1, DA_LDT	;LDT2
LABEL_TASK3_DESC_LDT:    Descriptor         0,   TASK3LDTLen - 1, DA_LDT	;LDT3

; GDT 结束
GdtLen		equ	$ - LABEL_GDT	; GDT长度
GdtPtr		dw	GdtLen - 1		; GDT界限
			dd	0				; GDT基地址

; GDT 选择子
SelectorNormal		equ	LABEL_DESC_NORMAL	- LABEL_GDT
SelectorFlatC		equ	LABEL_DESC_FLAT_C	- LABEL_GDT
SelectorFlatRW		equ	LABEL_DESC_FLAT_RW	- LABEL_GDT
SelectorCode32		equ	LABEL_DESC_CODE32	- LABEL_GDT
SelectorCode16		equ	LABEL_DESC_CODE16	- LABEL_GDT
SelectorData		equ	LABEL_DESC_DATA		- LABEL_GDT
SelectorStack		equ	LABEL_DESC_STACK	- LABEL_GDT
SelectorVideo		equ	LABEL_DESC_VIDEO	- LABEL_GDT
; 四个任务段选择子
SelectorTSS0        equ LABEL_DESC_TSS0     - LABEL_GDT
SelectorTSS1        equ LABEL_DESC_TSS1     - LABEL_GDT
SelectorTSS2        equ LABEL_DESC_TSS2     - LABEL_GDT
SelectorTSS3        equ LABEL_DESC_TSS3     - LABEL_GDT
SelectorLDT0        equ LABEL_TASK0_DESC_LDT   	- LABEL_GDT
SelectorLDT1        equ LABEL_TASK1_DESC_LDT    - LABEL_GDT
SelectorLDT2        equ LABEL_TASK2_DESC_LDT    - LABEL_GDT
SelectorLDT3        equ LABEL_TASK3_DESC_LDT 	- LABEL_GDT
; END of [SECTION .gdt]

;===============================================================================================================
; 4个任务的LDT和CODE、DATA、STACK段的定义
;===============================================================================================================
; LDT 和任务段定义
DefineTask 0, "VERY", 14, 0Ch  ; 红色文字，黑色背景
DefineTask 1, "LOVE", 14, 0Eh  ; 黄色文字，黑色背景
DefineTask 2, "HUST", 14, 0Ah  ; 绿色文字，黑色背景
DefineTask 3, "MRSU", 14, 0Bh  ; 青色文字，黑色背景

; END of LDT 和任务段定义

;===============================================================================================================
; IDT段的定义
;===============================================================================================================
[SECTION .idt]
ALIGN	32
[BITS	32]
LABEL_IDT:
; 门                          目标选择子,            偏移, DCount, 属性
%rep 32
				Gate	SelectorCode32, SpuriousHandler,      0, DA_386IGate
%endrep
.020h:			Gate	SelectorCode32,    ClockHandler,      0, DA_386IGate
%rep 95
				Gate	SelectorCode32, SpuriousHandler,      0, DA_386IGate
%endrep
.080h:			Gate	SelectorCode32,  UserIntHandler,      0, DA_386IGate

IdtLen		equ	$ - LABEL_IDT	; IDT 长度
IdtPtr		dw	IdtLen - 1		; IDT 段界限
			dd	0				; IDT 基地址, 待设置
; END of [SECTION .idt]

;===============================================================================================================
; 数据段，主要是定义一些符号和变量
;===============================================================================================================
[SECTION .data1]	
ALIGN	32
[BITS	32]
LABEL_DATA:
; 实模式下使用这些符号
; 字符串
_szPMMessage:			db	"In Protect Mode now By LiXiang!", 0Ah, 0Ah, 0	            ; 进入保护模式后显示此字符串
_szMemChkTitle:			db	"BaseAddrL BaseAddrH LengthLow LengthHigh   Type", 0Ah, 0	; 进入保护模式后且打印内存信息时显示此字符串
_szRAMSize			    db	"RAM size:", 0
_szReturn			    db	0Ah, 0
; 变量
_wSPValueInRealMode		dw	0
_dwMCRNumber:			dd	0					; Memory Check Result
_dwDispPos:			    dd	(80 * 2 + 0) * 2	; 屏幕第 2 行, 第 0 列。
_dwMemSize:			    dd	0
_ARDStruct:			         ; Address Range Descriptor Structure
	_dwBaseAddrLow:		    dd	0
	_dwBaseAddrHigh:	    dd	0
	_dwLengthLow:		    dd	0
	_dwLengthHigh:		    dd	0
	_dwType:		        dd	0
_PageTableNumber:	    dd	0
_SavedIDTR:			    dd	0	; 用于保存 IDTR
				        dd	0
_SavedIMREG:			db	0	; 中断屏蔽寄存器值
_MemChkBuf:	times	256	db	0   ; 用于存放内存检测结果

%define tickTimes  50;
_currentTask:			dd	0
_taskPriority:			dd	16*tickTimes, 10*tickTimes, 8*tickTimes, 6*tickTimes
_remainingTicks:				dd	0, 0, 0, 0

; 保护模式下使用这些符号
; $$表示当前段的起始地址，用于获取段内偏移
szPMMessage		equ	_szPMMessage	- $$
szMemChkTitle	equ	_szMemChkTitle	- $$
szRAMSize		equ	_szRAMSize	    - $$
szReturn		equ	_szReturn	    - $$
dwDispPos		equ	_dwDispPos	    - $$
dwMemSize		equ	_dwMemSize	    - $$
dwMCRNumber		equ	_dwMCRNumber	- $$
ARDStruct		equ	_ARDStruct	    - $$
	dwBaseAddrLow	equ	_dwBaseAddrLow	- $$
	dwBaseAddrHigh	equ	_dwBaseAddrHigh	- $$
	dwLengthLow	    equ	_dwLengthLow	- $$
	dwLengthHigh	equ	_dwLengthHigh	- $$
	dwType		    equ	_dwType		    - $$
MemChkBuf		equ	_MemChkBuf	    - $$
SavedIDTR		equ	_SavedIDTR	    - $$
SavedIMREG		equ	_SavedIMREG	    - $$
PageTableNumber	equ	_PageTableNumber- $$
currentTask     equ _currentTask    - $$
taskPriority    equ _taskPriority   - $$
remainingTicks  equ _remainingTicks - $$
DataLen			equ	$ - LABEL_DATA
; END of [SECTION .data1]

;===============================================================================================================
; 全局堆栈段
;===============================================================================================================
[SECTION .gs]
ALIGN	32
[BITS	32]
LABEL_STACK:
	times 512 db 0
TopOfStack	equ	$ - LABEL_STACK - 1
; END of [SECTION .gs]

;===============================================================================================================
;定义16位代码段
;===============================================================================================================
[SECTION .s16]
[BITS	16]
LABEL_BEGIN:
	mov		ax, cs
	mov		ds, ax
	mov		es, ax
	mov		ss, ax
	mov		sp, 0100h

	mov		[LABEL_GO_BACK_TO_REAL+3], ax 	; 设置跳回实模式的基址
	mov		[_wSPValueInRealMode], sp     	; 保存实模式下的sp寄存器

	; 使用中断15h得到内存数
	mov		ebx, 0				  			; 指示当前请求的内存区域，初始为 0，表示请求第一个内存区域。
	mov		di, _MemChkBuf        			; 存放内存检测结果的缓冲区
.loop:							
	mov		eax, 0E820h			  			; BIOS 中断 15h 功能 0E820h 用于获取系统内存映射
	mov		ecx, 20							; 为 BIOS 提供了一个 20 字节的数据结构来存储每个内存区域的信息
	; Base Address (8字节)：内存区域的起始物理地址，占用前 8 个字节。
	; Length       (8字节)：内存区域的长度，表示该内存区域有多大。
	; Type         (4字节)：这个内存区域的类型，1 表示可用内存，2 表示保留内存，3 可重新配置。
	mov		edx, 0534D4150h					; EDX 设置为签名 'SMAP' BIOS 用于验证是否正确调用此功能的签名。
	int		15h
	jc		LABEL_MEM_CHK_FAIL      		; 如果 CF=1，表示调用失败，跳转到 LABEL_MEM_CHK_FAIL
	add		di, 20                  		; 指向下一个内存区域的信息的存储位置
	inc		dword [_dwMCRNumber]  			; 内存区域计数器加 1
	cmp		ebx, 0							; 每次中断后，BIOS更新ebx的值，如果ebx为0，表示没有更多的内存区域
	jne		.loop							; 如果还有内存区域，继续循环
	jmp		LABEL_MEM_CHK_OK
LABEL_MEM_CHK_FAIL:
	mov	dword [_dwMCRNumber], 0 			; 如果调用失败，将内存区域计数器清零
LABEL_MEM_CHK_OK:
	; 初始化全局描述符
	InitDescBase LABEL_SEG_CODE16,LABEL_DESC_CODE16
	InitDescBase LABEL_SEG_CODE32,LABEL_DESC_CODE32
	InitDescBase LABEL_DATA, LABEL_DESC_DATA
	InitDescBase LABEL_STACK, LABEL_DESC_STACK

	; 初始化四个任务的LDT、TSS、代码段、数据段、堆栈段
	; 初始化任务描述符0
	InitTaskDescBase 0
	; 初始化任务描述符1
	InitTaskDescBase 1
	; 初始化任务描述符2
	InitTaskDescBase 2
	; 初始化任务描述符3
	InitTaskDescBase 3

	; 为加载 GDTR 作准备
	xor	    eax, eax
	mov	    ax, ds						; 实模式不区分代码段、数据段和堆栈段等
	shl	    eax, 4						; 段基地址 <- 段地址 << 4 
	add	    eax, LABEL_GDT		        ; eax <- gdt 基地址
	mov	    dword [GdtPtr + 2], eax	    ; [GdtPtr + 2] <- gdt 基地址

	; 为加载 IDTR 作准备
	xor	    eax, eax
	mov	    ax, ds
	shl	    eax, 4
	add	    eax, LABEL_IDT		        ; eax <- idt 基地址
	mov	    dword [IdtPtr + 2], eax	    ; [IdtPtr + 2] <- idt 基地址
	
	sidt    [_SavedIDTR]                ; 保存 IDTR

	in		al, 21h						; ┳ 保存中断屏蔽寄存器(IMREG)值
	mov		[_SavedIMREG], al			; ┛

	lgdt	[GdtPtr]					; 加载 GDTR

	cli								    ; 关中断

	lidt	[IdtPtr]					; 加载 IDTR，新的IDT(中断描述符表)将在保护模式下生效

	in		al, 92h						; ┓
	or		al, 00000010b				; ┣ 打开地址线 A20，以便访问 1M 以上的内存
	out		92h, al						; ┛

	mov		eax, cr0					; ┓
	or		eax, 1						; ┣ 准备切换到保护模式
	mov		cr0, eax					; ┛
	
	; 注意指定长度为双字
	; 执行这一句会把 SelectorCode32 装入 cs, 并跳转到 Code32Selector:0  处执行
	jmp		dword SelectorCode32:0		; 真正进入保护模式
	
; 从保护模式跳回到实模式的位置
LABEL_REAL_ENTRY:	
	mov		ax, cs
	mov		ds, ax
	mov		es, ax
	mov		ss, ax
	mov		sp, [_wSPValueInRealMode]  	; 恢复实模式下的 sp 寄存器

	lidt	[_SavedIDTR]		   		; 恢复 IDTR 的原值

	mov		al, [_SavedIMREG]	      	; ┓恢复中断屏蔽寄存器(IMREG)的原值
	out		21h, al			          	; ┛

	in		al, 92h		               	; ┓
	and		al, 11111101b	           	; ┣ 关闭 A20 地址线
	out		92h, al		               	; ┛

	sti							   		; 开中断

	mov		ax, 4c00h	               	; ┓
	int		21h		                   	; ┛回到 DOS

; END of [SECTION .s16]

;===============================================================================================================
; 32 位代码段. 由实模式跳入.
;===============================================================================================================
[SECTION .s32]
[BITS	32]
LABEL_SEG_CODE32:
	mov		ax, SelectorData
	mov		ds, ax			    ; DS <- 数据段选择子
	mov		es, ax				; ES <- 数据段选择子
	mov		ax, SelectorVideo
	mov		gs, ax			    ; GS <- 视频段选择子

	mov		ax, SelectorStack	
	mov		ss, ax			    ; SS <- 堆栈段选择子
	mov		esp, TopOfStack		; ESP <- 栈顶指针

	call	Init8253A
	call	Init8259A

	call	ClearScreen			; 清屏

	push	szPMMessage			; ┓
	call	DispStr				; ┣ 输出信息
	add		esp, 4				; ┛

	push	szMemChkTitle		; ┓
	call	DispStr				; ┣ 显示内存信息
	add		esp, 4				; ┃
	call	DispMemSize			; ┛

	call	SetupPaging			; 启动分页机制并初始化4个任务页表

	SwitchTask 0				; 从任务0开始执行

	call	SetRealmode8259A

	jmp		dword SelectorCode16:0


; 启动分页机制 --------------------------------------------------------------
SetupPaging:
	; 根据内存大小计算应初始化多少PDE以及多少页表
	xor		edx, edx
	mov		eax, [dwMemSize]
	mov		ebx, 400000h	  		; 400000h = 4M = 4096 * 1024, 一个页表对应的内存大小
	div		ebx
	mov		ecx, eax				; 此时 ecx 为页表的个数，也即 PDE 的个数
	test	edx, edx
	jz		.no_remainder
	inc		ecx						; 如果余数不为 0 就需增加一个页表
.no_remainder:
	mov		[PageTableNumber], ecx	; 暂存页表个数
	call	LABEL_INIT_PAGE_TABLE0
	call	LABEL_INIT_PAGE_TABLE1
	call	LABEL_INIT_PAGE_TABLE2
	call	LABEL_INIT_PAGE_TABLE3

	xor 	ecx, ecx
.initRemainingTicks:
	mov     eax, dword [taskPriority + ecx * 4]             
	mov     dword [remainingTicks + ecx * 4], eax
	inc   	ecx
	cmp    	ecx, 4
	jne     .initRemainingTicks

	xor 	ecx, ecx  
	sti								; 打开中断

	mov		eax, PageDirBase0		; ┳ 加载 CR3
	mov		cr3, eax				; ┛

	mov		ax, SelectorTSS0		; ┳ 加载 TSS
	ltr		ax						; ┛

	mov		eax, cr0				; ┓
	or		eax, 80000000h			; ┣ 打开分页
	mov		cr0, eax				; ┃
	jmp		short .1				; ┛
.1:
	nop
	; 初始化完成

	ret
; 分页机制启动完毕 ----------------------------------------------------------

; 初始化页表 ----------------------------------------------------------------
InitPageTable 0
InitPageTable 1
InitPageTable 2
InitPageTable 3
; 初始化页表完毕 ------------------------------------------------------------

; int handler ---------------------------------------------------------------
_ClockHandler:
ClockHandler equ _ClockHandler - $$
	push	ds  ; 保存当前数据段寄存器
	pushad  	; 保存所有通用寄存器

	; 设置数据段选择子，以便正确访问内存数据
	mov		eax, SelectorData
	mov		ds, ax

	; 向 Programmable Interrupt Controller (PIC) 发送结束中断信号
	mov		al, 0x20
	out		0x20, al

	; 检查当前任务的剩余时间片是否为0
	mov     edx, dword [currentTask] 			; 获取当前任务的索引
	mov     ecx, dword [remainingTicks + edx*4] ; 获取当前任务的剩余时间片
	test    ecx, ecx 							; 测试剩余时间片是否为0
	jnz     .subTicks 							; 如果不为0，跳转到.subTicks继续执行当前任务

	; 如果当前任务的时间片用完，检查是否所有任务的时间片都已用完
	mov     eax, dword [remainingTicks] 		
	or      eax, dword [remainingTicks + 4] 	
	or      eax, dword [remainingTicks + 8] 	
	or      eax, dword [remainingTicks + 12] 	
	jz      .allTaskFinished 	; 如果所有时间片都为0，跳转到.allFinished

.nextTask:
	; 寻找剩余时间片最多的任务
	xor     eax, eax 			; 清零eax，用于循环计数
	xor     esi, esi 			; esi用于标记是否找到了新任务
	xor     ecx, ecx 			; 清零ecx，用于存储当前最大的剩余时间片
.getMaxTicksTask:
	; 检查每个任务的剩余时间片，寻找最大值
	cmp     dword [remainingTicks + eax * 4], ecx
	jle     .isNotMax
	mov     ecx, dword [taskPriority + eax * 4]
	mov     ebx, eax
	mov     esi, 1
.isNotMax:
	add     eax, 1
	cmp     eax, 4
	jnz     .getMaxTicksTask
	mov     eax, esi
	test    al, al
	jz      .subTicks

	; 更新currentTask为剩余时间片最多的任务
	mov     dword [currentTask], ebx
	mov     edx, ebx

	; 根据任务索引切换到相应任务
	cmp     edx, 0
	je      .switchToTask0
	cmp     edx, 1
	je      .switchToTask1
	cmp     edx, 2
	je      .switchToTask2
	cmp     edx, 3
	je      .switchToTask3
	jmp     .exit

.switchToTask0:
	SwitchTask 0 ; 切换到任务0
.switchToTask1:
	SwitchTask 1 ; 切换到任务1
.switchToTask2:
	SwitchTask 2 ; 切换到任务2
.switchToTask3:
	SwitchTask 3 ; 切换到任务3

.subTicks:
	; 减少当前任务的剩余时间片
	sub     dword [remainingTicks + edx * 4], 1
	jmp     .exit

.allTaskFinished:
	; 如果所有任务的时间片都用完，重新为每个任务分配时间片
	xor     ecx, ecx
	
.setLoop:
	mov     eax, dword [taskPriority + ecx * 4]
	mov     dword [remainingTicks + ecx * 4], eax
	inc     ecx
	cmp     ecx, 4
	jne     .setLoop
	xor     ecx, ecx
	jmp     .nextTask

.exit:
	; 恢复寄存器状态并结束中断处理
	popad
	pop     ds
	iretd

_UserIntHandler:
UserIntHandler	equ	_UserIntHandler - $$
	iretd

_SpuriousHandler:
SpuriousHandler	equ	_SpuriousHandler - $$
	iretd
; END of int handler --------------------------------------------------------

%include	"./include/lib.inc"	; 库函数，相当于把代码直接写在这里

SegCode32Len	equ	$ - LABEL_SEG_CODE32
; END of [SECTION .s32]

;===============================================================================================================
; 16 位代码段. 由 32 位代码段跳入, 跳出后到实模式
;===============================================================================================================
[SECTION .s16code]
ALIGN	32
[BITS	16]
LABEL_SEG_CODE16:
	; 跳回实模式:
	mov	ax, SelectorNormal
	mov	ds, ax
	mov	es, ax
	mov	fs, ax
	mov	gs, ax
	mov	ss, ax

	mov	eax, cr0
	and	al, 11111110b
	mov	cr0, eax

LABEL_GO_BACK_TO_REAL:
	jmp	0:LABEL_REAL_ENTRY	; 段地址会在程序开始处被设置成正确的值

Code16Len	equ	$ - LABEL_SEG_CODE16
; END of [SECTION .s16code]