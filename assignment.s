.section .data

d1: .byte 0x00,0x1c,0x00,0x00,0x00,0x24,0x00,0x00,0,0,0,0,0,0,0,0
d2: .byte 0x50,0x01,0x00,0x00,0x50,0x02,0x00,0x00,0,0,0,0,0,0,0,0
d3: .byte 0x12,0x34,0x56,0x78,0x87,0x65,0x43,0x21,0,0,0,0,0,0,0,0

n_7ffff:    .word 0x7ffff
n_70000:    .word 0x70000
n_80000:    .word 0x80000
n_fffff000: .word 0xfffff000
n_fff:      .word 0xfff



	

.section .text

@arguments....... r5 = S,  r6 = E in 32 bits,  r7 = 1+M
@arguments....... r2 = address of result
storeresult:        
	stmfd sp!, {r0-r9,lr}
	ldr r9 ,=n_fff
	ldr r9 ,[r9]
    	and r6,r6,r9
	lsl r0, r5,#7
	lsr r1, r6,#5
	orr r0,r1,r0
	strb r0,[r2]

	ldr r9,=n_7ffff
	ldr r9,[r9]
	and r7, r7, r9

	and r0, r6,#31
	lsl r0, r0, #3
	ldr r9,=n_70000
	ldr r9,[r9]
	and r1,r7,r9
	lsr r1,#16
	orr r0,r0,r1
	strb r0,[r2,#1]

	and r0,r7,#0xff00
	lsr r0,#8
	strb r0,[r2,#2]

	and r0,r7,#0xff
	strb r0,[r2,#3]

	ldmfd sp!, {r0-r9,pc}






@arguments....... r7 = most significat bits
@arguments....... r8 = least significant bits
@returns......... r0 = number of shift required to normalize 
countshiftmul:
	stmfd sp!, {r1-r9,lr}
	mov r1,#1
	lsl r1,#6
	and r2,r1,r7
	cmp r2,r1
	moveq r0,#19
	lsl r1,#1
	and r2,r1,r7
	cmp r2,r1
	moveq r0,#20
	ldmfd  sp!, {r1-r9,pc}




	

@arguments r8 = number
@returns r0 
countshiftadd:
	stmfd sp!, {r1-r9,lr}
	mov r1,#1
	mov r2,#1
	mov r0,#2
	loop:
		and r3,r8,r2
		cmp r3,r2
		subeq r0,r1,#20
		cmp r1,#21
		add r1,#1
		lsl r2,#1
		bne loop
	ldmfd sp!, {r1-r9,pc}



	

@argument r0
@returns r0
signextend:
	stmfd sp!, {r1-r9,lr}
	and r1,r0,#0x800
	cmp r1,#0x800
	ldr r9,=n_fffff000
	ldr r9,[r9]
	orreq r0,r0,r9
	ldmfd sp!, {r1-r9,pc}



	

@arguments....... r9 = number_addres
@returns......... r0 = S
ldsign:
	stmfd sp!, {r1-r9,lr}
	ldrb r1, [r9] 
	mov r2,#128
	and r3,r1,r2
	lsr r0,r3,#7
	ldmfd sp!, {r1-r9,pc}



	

@arguments....... r9 = number_addres
@returns......... r0 = E
ldexp:
	stmfd sp!, {r1-r9,lr}
	ldrb r1, [r9]
	ldrb r2, [r9,#1]
	mov r3,#127
	and r3,r1,r3
	lsl r3,r3,#5
	mov r4,#248
	and r4,r2,r4
	lsr r4,r4,#3
	orr r0,r3,r4
	bl signextend
	ldmfd sp!, {r1-r9,pc}



	

@arguments....... r9 = number_addres
@returns......... r0 = M
ldmantissa:
	stmfd sp!, {r1-r9,lr}
	ldrb r1, [r9,#1]
	ldrb r2, [r9,#2]
	ldrb r3, [r9,#3]
	mov r4,#7
	and r4,r1,r4
	lsl r4,r4,#16
	mov r5,#255
	and r5,r2,r5
	lsl r5,r5,#8
	mov r6,#255
	and r6,r3,r6
	orr r0,r4,r5
	orr r0,r0,r6
	orr r0,r0,#0x80000
	ldmfd sp!, {r1-r9,pc}



	

@argument r3,r4 r5,r6 r7,r8
@return   r6,r7,r8,r3,r4,r5
swap:
	stmfd sp!, {r0-r2,r9,lr}
	stmfd sp!, {r3-r5}
	stmfd sp!, {r6-r8}
	ldmfd sp!, {r3-r5}
	ldmfd sp!, {r6-r8}
	ldmfd sp!, {r0-r2,r9,pc}



	

@arguments......... r1 = address of input
nfpadd:
	stmfd sp!, {r0-r9,lr}
	add r2,r1,#8
	                              
 	mov r9 , r1
	bl ldsign
	mov r3,r0
	bl ldexp
	mov r4,r0
	bl ldmantissa
	mov r5,r0
    
	add r9,r1,#4
	bl ldsign
	mov r6,r0
	bl ldexp
	mov r7,r0
	bl ldmantissa
	mov r8,r0
    
    
	cmp r4,r7
	bmi swap
	sub r9,r4,r7
	lsr r8,r8,r9
	mov r7,r4
    
	@merge sign bit in significants
	mov r9,#0
	cmp r3,#1
	subeq r5,r9,r5
	cmp r6,#1
	subeq r8, r9,r8

	@perform addition, seperate sign bit
	add r8,r8,r5
	mov r9,#0
	cmp r8,r9
	mov r6,#0
	movmi r6,#1
	submi r8,r9,r8
   
    @got sign bit in r6
	@got exponent in r7
	@got 1+M in r8
	@renormalize
	bl countshiftadd
	add r7,r7,r0

    cmp r0,#1
	lsreq r8,r8,#1

	cmp r0,#0
	mov r9,#-1
	mul r0,r0,r9
	lslmi r8,r8,r0

	cmp r0,#-2
	moveq r5,#0
	moveq r6,#0
	moveq r7,#0

	@store arguments for storeresult
	stmfd sp!, {r6-r8}
	ldmfd sp!, {r5-r7}

 	bl storeresult

	ldmfd sp!, {r0-r9,pc}



	

@arguments......... r1 = address of input
nfpmul:
 	stmfd sp!, {r0-r9,lr}
 	add r2,r1,#12
 	
 	mov r9 , r1
 	bl ldsign
 	mov r3 , r0
	add r9 , r1, #4
 	bl ldsign 
 	mov r4 , r0
 	eor r5,r3,r4
 	
 	mov r9 , r1
 	bl ldexp
 	mov r3 , r0
	add r9 , r1, #4
 	bl ldexp 
 	mov r4 , r0
 	add r6,r3,r4
 	
 	mov r9 , r1
 	bl ldmantissa
 	mov r3 , r0
	add r9 , r1, #4
 	bl ldmantissa 
 	mov r4 , r0
 	umull r8,r7,r3,r4
 	
 	mov r0,#0
 	bl countshiftmul
 	lsr r8,r8,r0
 	add r6,r6,r0
 	add r6,r6,#-19
	mov r9,#32
 	sub r0,r9,r0
 	lsl r7,r7,r0
	orr r7,r7,r8
 	
	bl storeresult

	ldmfd sp!, {r0-r9,pc}



	

.global _start

_start:
	ldr r1, =d2
	bl nfpadd
	bl nfpmul
