#
# CMPUT 229 Public Materials License
# Version 1.0
#
# Copyright 2020 University of Alberta
# Copyright 2022 Yufei Chen, Shijie Bu
# This software is distributed to students in the course
# CMPUT 229 - Computer Organization and Architecture I at the University of
# Alberta, Canada.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the disclaimer below in the documentation
#    and/or other materials provided with the distribution.
#
# 2. Neither the name of the copyright holder nor the names of its
#    contributors may be used to endorse or promote products derived from this
#    software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
#-------------------------------
# Lab_Snake_Game Lab
#
# CCID: sbu1
# Student ID: 1720680                
# Name: SHIJIE BU                
# Lecture Section: CMPUT 229 WINTER 2022     
# Instructor: Matthew Gaudet, J. Nelson Amaral         
# Lab Section: LAB D01, T B-38, TUESDAY         
# Teaching Assistant: Islam Ali, Mostafa Yadegari     
#-------------------------------

.include "common.s"

.data
.align 2

#this is where input ascii code stored
KEYBOARD_INTERRUPT:	.word 0xFFFF0000
KEYBOARD_ASCII:     .word 0xFFFF0004
DISPLAY_CONTROL:    .word 0xFFFF0008
DISPLAY_DATA:       .word 0xFFFF000C

TIME:	.word 0xFFFF0018
TIME_CMP:	.word 0xFFFF0020

#this is the welcome string to ask the user for a level choose
startstring:	.asciz "Please enter 1, 2 or 3 to choose the level and start the game"
points:	.asciz "points"
seconds:	.asciz "seconds"
onetwozero:	.asciz "120"
thirty:	.asciz "030"
fifteen:	.asciz "015"
startpoints:	.asciz "000"

INTERRUPT_ERROR:	.asciz "Error: Unhandled interrupt with exception code: "
INSTRUCTION_ERROR:	.asciz "\n   Originating from the instruction at address: "

Brick:      .asciz "#"


.text


#
#Arguments
#None
#Return Values
#None
#
#register use: 
#a series: for various location saving, especially for the colume and row, also character to print
#t series: for temp use, often use to store value
#s series: for saved values, often about immidiate value or integers

snakeGame:
	#save registers

	addi	sp, sp, -112
	sw	ra, 0(sp)
	sw	t0, 4(sp)
	sw	t1, 8(sp)
	sw	t2, 12(sp)
	sw	t3, 16(sp)
	sw	a0, 20(sp)
	sw	a1, 24(sp)
	sw	a2, 28(sp)

	#print the start screen(string)
	la	t0, startstring
	mv	a0, t0	# a0 <- strAddr
	li	a1, 0	# a1 <- row = i
	li	a2, 0	# a2 <- col = 0
	jal	printStr

	#read from the user imput to change difficulty
    	#load ascii code stored in DISPLAY_CONTROL, and see if its 1, 2, 3
	#make a loop
	#three difficulties
	li	t1, 49	#ascii of 1
	li	t2, 50	#ascii of 2
	li	t3, 51	#ascii of 3

	difficultyloop:
    		#if its not 1, 2, 3, then loop till we have the correct input
		lw	t0, KEYBOARD_ASCII	#read the input address
		lw	t0, 0(t0)	#read the address's value
		
		#determine level
		beq	t0, t1, level1	#if its difficulty 1, start as level 1
		beq	t0, t2, level2	#if its difficulty 2, start as level 2
		beq	t0, t3, level3	#if its difficulty 3, start as level 3
		j	difficultyloop	#if not correct difficulty, read until get a valid input

	#level 1
	#initial time 120
	#bonus time 8
	level1:
		#clean the enter screen
		li	a0, 61
		li	a3, 32	#ascii for space
		li	a1, 0
		li	a2, 0
		jal	printMultipleSameChars
		jal	printAllWalls

		#print points label
		la	a0, points
		li	a1, 0
		li	a2, 28
		jal	printStr

		#print seconds label
		la	a0, seconds
		li	a1, 1
		li	a2, 28
		jal	printStr

		#print original points
		la	a0, startpoints
		li	a1, 0
		li	a2, 24
		jal	printStr

		#print original seconds
		la	a0, onetwozero
		li	a1, 1
		li	a2, 24
		jal	printStr

		#store snake's head location in stack
		li	a0, 64
		li	a1, 5
		li	a2, 10
		sw	a1, 32(sp)
		sw	a2, 36(sp)
		jal	printChar
		
		#store snake's first body location in stack
		li	a0, 42
		li	a1, 5
		li	a2, 9
		sw	a1, 40(sp)
		sw	a2, 44(sp)
		jal	printChar

		#store snake's second body location in stack
		li	a0, 42
		li	a1, 5
		li	a2, 8
		sw	a1, 48(sp)
		sw	a2, 52(sp)
		jal	printChar

		#store snake's third body location in stack
		li	a0, 42
		li	a1, 5
		li	a2, 7
		sw	a1, 56(sp)
		sw	a2, 60(sp)
		jal	printChar
		
		#print first apple
		jal	random
		mv	a1, a0
		addi	a1, a1, 1
		jal	random
		mv	a2, a0
		addi	a2, a2, 1
		li	a0, 97
		sw	a1, 96(sp)
		sw	a2, 100(sp)
		jal	printChar

		#modify uie's 4th digit to enable timer interrupt
		csrrwi	t0, 0, 1	#enable user interrupt(ustatus)
		li	t0, 272		#set bit 4 and 8 to 1
		csrrw	t1, 4, t0	#enable timer/external interrupt(uie)
		

		li	s0, 119	#set s0 to the base time
		li	t0, 0	#set points to 0
		sw	t0, 104(sp)	#points is stored in sp

		
		#set timecmp to 1 sec after time

		lw	t0, TIME	#get time's location
		lw	t0, 0(t0)	#get time's value
		addi	t2, t0, 1000	#add one second
		lw	t1, TIME_CMP	#get timecmp's location
		sw	t2, 0(t1)	#store timecmp back to time
		
		interruptloop:
			la	t3, handler
			csrrw	t4, 5, t3	#write handler location into utvec
			lw	t1, TIME_CMP	#get timecmp's location
			sw	t2, 0(t1)	#store timecmp back to time

			#enable keyboard interrupt
			la	t0, KEYBOARD_INTERRUPT
			li	t1, 1
			sw	t1, 0(t0)

			j	interruptloop

	#level 2
	#initial time 30
	#bonus time 5
	level2:
		#clean the enter screen
		li	a0, 61
		li	a3, 32	#ascii for space
		li	a1, 0
		li	a2, 0
		jal	printMultipleSameChars
		jal	printAllWalls

		#print points label
		la	a0, points
		li	a1, 0
		li	a2, 28
		jal	printStr

		#print seconds label
		la	a0, seconds
		li	a1, 1
		li	a2, 28
		jal	printStr

		#print original points
		la	a0, startpoints
		li	a1, 0
		li	a2, 24
		jal	printStr

		#print original seconds
		la	a0, thirty
		li	a1, 1
		li	a2, 24
		jal	printStr

		#store snake's head location in stack
		li	a0, 64
		li	a1, 5
		li	a2, 10
		sw	a1, 32(sp)
		sw	a2, 36(sp)
		jal	printChar
		
		#store snake's first body location in stack
		li	a0, 42
		li	a1, 5
		li	a2, 9
		sw	a1, 40(sp)
		sw	a2, 44(sp)
		jal	printChar

		#store snake's second body location in stack
		li	a0, 42
		li	a1, 5
		li	a2, 8
		sw	a1, 48(sp)
		sw	a2, 52(sp)
		jal	printChar

		#store snake's third body location in stack
		li	a0, 42
		li	a1, 5
		li	a2, 7
		sw	a1, 56(sp)
		sw	a2, 60(sp)
		jal	printChar
		
		#print first apple
		jal	random
		mv	a1, a0
		addi	a1, a1, 1
		jal	random
		mv	a2, a0
		addi	a2, a2, 1
		li	a0, 97
		sw	a1, 96(sp)
		sw	a2, 100(sp)
		jal	printChar

		#modify uie's 4th digit to enable timer interrupt
		csrrwi	t0, 0, 1	#enable user interrupt(ustatus)
		li	t0, 272		#set bit 4 and 8 to 1
		csrrw	t1, 4, t0	#enable timer/external interrupt(uie)
		

		li	s0, 29	#set s0 to the base time
		li	t0, 0	#set points to 0
		sw	t0, 104(sp)	#points is stored in sp

		
		#set timecmp to 1 sec after time

		lw	t0, TIME	#get time's location
		lw	t0, 0(t0)	#get time's value
		addi	t2, t0, 1000	#add one second
		lw	t1, TIME_CMP	#get timecmp's location
		sw	t2, 0(t1)	#store timecmp back to time
		
		interruptloop_2:
			la	t3, handler
			csrrw	t4, 5, t3	#write handler location into utvec
			lw	t1, TIME_CMP	#get timecmp's location
			sw	t2, 0(t1)	#store timecmp back to time

			#enable keyboard interrupt
			la	t0, KEYBOARD_INTERRUPT
			li	t1, 1
			sw	t1, 0(t0)

			j	interruptloop_2

	#level 3
	#initial time 15
	#bonus time 3
	level3:
		#clean the enter screen
		li	a0, 61
		li	a3, 32	#ascii for space
		li	a1, 0
		li	a2, 0
		jal	printMultipleSameChars
		jal	printAllWalls

		#print points label
		la	a0, points
		li	a1, 0
		li	a2, 28
		jal	printStr

		#print seconds label
		la	a0, seconds
		li	a1, 1
		li	a2, 28
		jal	printStr

		#print original points
		la	a0, startpoints
		li	a1, 0
		li	a2, 24
		jal	printStr

		#print original seconds
		la	a0, fifteen
		li	a1, 1
		li	a2, 24
		jal	printStr

		#store snake's head location in stack
		li	a0, 64
		li	a1, 5
		li	a2, 10
		sw	a1, 32(sp)
		sw	a2, 36(sp)
		jal	printChar
		
		#store snake's first body location in stack
		li	a0, 42
		li	a1, 5
		li	a2, 9
		sw	a1, 40(sp)
		sw	a2, 44(sp)
		jal	printChar

		#store snake's second body location in stack
		li	a0, 42
		li	a1, 5
		li	a2, 8
		sw	a1, 48(sp)
		sw	a2, 52(sp)
		jal	printChar

		#store snake's third body location in stack
		li	a0, 42
		li	a1, 5
		li	a2, 7
		sw	a1, 56(sp)
		sw	a2, 60(sp)
		jal	printChar
		
		#print first apple
		jal	random
		mv	a1, a0
		addi	a1, a1, 1
		jal	random
		mv	a2, a0
		addi	a2, a2, 1
		li	a0, 97
		sw	a1, 96(sp)
		sw	a2, 100(sp)
		jal	printChar

		#modify uie's 4th digit to enable timer interrupt
		csrrwi	t0, 0, 1	#enable user interrupt(ustatus)
		li	t0, 272		#set bit 4 and 8 to 1
		csrrw	t1, 4, t0	#enable timer/external interrupt(uie)
		li	s0, 14	#set s0 to the base time
		li	t0, 0	#set points to 0
		sw	t0, 104(sp)	#points is stored in sp

		#set timecmp to 1 sec after time
		lw	t0, TIME	#get time's location
		lw	t0, 0(t0)	#get time's value
		addi	t2, t0, 1000	#add one second
		lw	t1, TIME_CMP	#get timecmp's location
		sw	t2, 0(t1)	#store timecmp back to time
		
		interruptloop_3:
			la	t3, handler
			csrrw	t4, 5, t3	#write handler location into utvec
			lw	t1, TIME_CMP	#get timecmp's location
			sw	t2, 0(t1)	#store timecmp back to time

			#enable keyboard interrupt
			la	t0, KEYBOARD_INTERRUPT
			li	t1, 1
			sw	t1, 0(t0)

			j	interruptloop_3

#Arguments:
#None
#Return Values:
#a0: a pseudorandom number, Xi, between 0 and 8
#register use:
#a series: for various location saving, especially for the colume and row, also character to print
#t series: for temp use, often use to store value
#s series: for saved values, often about immidiate value or integers

random:
	#store to stack
	addi	sp, sp, -20
	sw	s0, 0(sp)
	sw	s1, 4(sp)
	sw	s2, 8(sp)
	sw	s3, 12(sp)
	sw	s4, 16(sp)
	
	#caculate
	lw	s0, XiVar	#get Xi
	lw	s1, aVar	#get a
	lw	s2, cVar	#get c
	lw	s3, mVar	#get m
	li	s4, 0	#initialize final value
	mul	s4, s1, s0	#aXi
	add	s4, s4, s2	#aXi + c
	rem	a0, s4, s3	#a0 = (aXi + c) % m
	la	s4, XiVar	#get location of XiVar
	sw	a0, 0(s4)	#store changed Xi back

	#restore registers
	lw	s0, 0(sp)
	lw	s1, 4(sp)
	lw	s2, 8(sp)
	lw	s3, 12(sp)
	lw	s4, 16(sp)
	addi	sp, sp, 20
	ret

#HANDLER
#register use:
#a series: for various location saving, especially for the colume and row, also character to print
#t series: for temp use, often use to store value
#s series: for saved values, often about immidiate value or integers

handler:
	# swap a0 and uscratch
	csrrw	a0, 0x040, a0	# a0 <- Addr[iTrapData], uscratch <- PROGRAMa0 

	# save all used registers except a0
	sw	t0, 0(a0)	# save PROGRAMt0
	sw	t1, -4(a0)	# save PROGRAMt1
	sw	t2, -8(a0)	# save PROGRAMt2
	sw	s0, -12(a0)	# save PROGRAMs0
	sw	s1, -16(a0)	# save PROGRAMs1
	sw	s2, -20(a0)	# save PROGRAMs2
	sw	a1, -24(a0)	# save PROGRAMa1
	sw	a2, -28(a0)	# save PROGRAMa2



	# save a0
	csrr    t0, 0x040         # t0 <- PROGRAMa0    
	sw      t0, -32(a0)         # save PROGRAMa0



	# swap a0 and uscratch
	csrrw	a0, 0x040, a0	# a0 <- Addr[iTrapData], uscratch <- PROGRAMa0 

	#s0 now contains the value of seconds
	li	s1, 100
	li	s2, 10

	#third digit
	divu	t0, s0, s1	#t0 has the third digit
	addi	t0, t0, 48	#t0 is the ascii code of the third digit

	#second digit
	rem	t1, s0, s1
	divu	t1, t1, s2	#t1 has the second digit
	addi	t1, t1, 48	#t1 is the ascii code of the second digit

	#first digit
	rem	t2, s0, s2
	addi	t2, t2, 48	#t2 is the ascii code of the first digit

	#store the three digits number on stack
	#use a1 to store the string
	add	a1, t2, zero
	slli	a1, a1, 8
	add	a1, a1, t1
	slli	a1, a1, 8
	add	a1, a1, t0

	#save a1 on our stack
	# swap a0 and uscratch

	csrrw	a0, 0x040, a0	# a0 <- Addr[iTrapData], uscratch <- PROGRAMa0

	sw	a1, -36(a0)

	addi	a3, a0, -36
	mv	a0, a3
	li	a1, 1
	li	a2, 24
	jal	printStr

	#let the snake move

	#if its not 1, 2, 3, then loop till we have the correct input
	lw	t0, KEYBOARD_ASCII	#read the input address
	lw	t0, 0(t0)	#read the address's value
	li	t1, 119
	li	t2, 97
	li	t3, 115
	li	t4, 100

	#determine direction
	beq	t0, t1, w_up	#if its w, move up
	beq	t0, t2, a_left	#if its a, move left
	beq	t0, t3, s_down	#if its s, move down
	beq	t0, t4, d_right	#if its d, move right
		
	#otherwise, automatically go right
	j	d_right

	w_up:

		#head
		#save head for body 1
		lw	a1, 32(sp)
		lw	a2, 36(sp)
		sw	a1, 64(sp)
		sw	a2, 68(sp)
		
		addi	a1, a1, -1
		li	a0, 64
		jal	printChar
		sw	a1, 32(sp)
		sw	a2, 36(sp)


			
		#body1
		#save previous body 1 for body 2
		lw	a1, 40(sp)
		lw	a2, 44(sp)
		sw	a1, 72(sp)
		sw	a2, 76(sp)
			
		lw	a1, 64(sp)
		lw	a2, 68(sp)
		li	a0, 42
		sw	a1, 40(sp)
		sw	a2, 44(sp)
		jal	printChar

		#body2

		#save previous body 2 for body 3
		lw	a1, 48(sp)
		lw	a2, 52(sp)
		sw	a1, 80(sp)
		sw	a2, 84(sp)
		
		lw	a1, 72(sp)
		lw	a2, 76(sp)
		li	a0, 42
		sw	a1, 48(sp)
		sw	a2, 52(sp)
		jal	printChar

		#body3
		#save previous body 3 for space
		lw	a1, 56(sp)
		lw	a2, 60(sp)
		sw	a1, 88(sp)
		sw	a2, 92(sp)
			
		lw	a1, 80(sp)
		lw	a2, 84(sp)
		li	a0, 42
		sw	a1, 56(sp)
		sw	a2, 60(sp)
		jal	printChar
			
		#print a space at previous body3 location
		lw	a1, 88(sp)
		lw	a2, 92(sp)
		li	a0, 32
		jal	printChar
		j	endhandler



	a_left:

		#head
		#save head for body 1
		lw	a1, 32(sp)
		lw	a2, 36(sp)
		sw	a1, 64(sp)
		sw	a2, 68(sp)

		addi	a2, a2, -1
		li	a0, 64
		jal	printChar
		sw	a1, 32(sp)
		sw	a2, 36(sp)

			
		#body1
		#save previous body 1 for body 2
		lw	a1, 40(sp)
		lw	a2, 44(sp)
		sw	a1, 72(sp)
		sw	a2, 76(sp)
			
		lw	a1, 64(sp)
		lw	a2, 68(sp)
		li	a0, 42
		sw	a1, 40(sp)
		sw	a2, 44(sp)
		jal	printChar

		#body2

		#save previous body 2 for body 3
		lw	a1, 48(sp)
		lw	a2, 52(sp)
		sw	a1, 80(sp)
		sw	a2, 84(sp)
			
		lw	a1, 72(sp)
		lw	a2, 76(sp)
		li	a0, 42
		sw	a1, 48(sp)
		sw	a2, 52(sp)
		jal	printChar

		#body3
		#save previous body 3 for space
		lw	a1, 56(sp)
		lw	a2, 60(sp)
		sw	a1, 88(sp)
		sw	a2, 92(sp)
			
		lw	a1, 80(sp)
		lw	a2, 84(sp)
		li	a0, 42
		sw	a1, 56(sp)
		sw	a2, 60(sp)
		jal	printChar
			
		#print a space at previous body3 location
		lw	a1, 88(sp)
		lw	a2, 92(sp)
		li	a0, 32
		jal	printChar
		j	endhandler

	s_down:

		#head
		#save head for body 1
		lw	a1, 32(sp)
		lw	a2, 36(sp)
		sw	a1, 64(sp)
		sw	a2, 68(sp)
		
		addi	a1, a1, 1
		li	a0, 64
		jal	printChar
		sw	a1, 32(sp)
		sw	a2, 36(sp)
		
		#body1
		#save previous body 1 for body 2
		lw	a1, 40(sp)
		lw	a2, 44(sp)
		sw	a1, 72(sp)
		sw	a2, 76(sp)
		
		lw	a1, 64(sp)
		lw	a2, 68(sp)
		li	a0, 42
		sw	a1, 40(sp)
		sw	a2, 44(sp)
		jal	printChar

		#body2

		#save previous body 2 for body 3
		lw	a1, 48(sp)
		lw	a2, 52(sp)
		sw	a1, 80(sp)
		sw	a2, 84(sp)
		
		lw	a1, 72(sp)
		lw	a2, 76(sp)
		li	a0, 42
		sw	a1, 48(sp)
		sw	a2, 52(sp)
		jal	printChar

		#body3
		#save previous body 3 for space
		lw	a1, 56(sp)
		lw	a2, 60(sp)
		sw	a1, 88(sp)
		sw	a2, 92(sp)
		
		lw	a1, 80(sp)
		lw	a2, 84(sp)
		li	a0, 42
		sw	a1, 56(sp)
		sw	a2, 60(sp)
		jal	printChar
		
		#print a space at previous body3 location
		lw	a1, 88(sp)
		lw	a2, 92(sp)
		li	a0, 32
		jal	printChar
		j	endhandler


	d_right:

		#head
		#save head for body 1
		lw	a1, 32(sp)
		lw	a2, 36(sp)
		sw	a1, 64(sp)
		sw	a2, 68(sp)
		
		addi	a2, a2, 1
		li	a0, 64
		jal	printChar
		sw	a1, 32(sp)
		sw	a2, 36(sp)
			

			
		#body1
		#save previous body 1 for body 2
		lw	a1, 40(sp)
		lw	a2, 44(sp)
		sw	a1, 72(sp)
		sw	a2, 76(sp)
			
		lw	a1, 64(sp)
		lw	a2, 68(sp)
		li	a0, 42
		sw	a1, 40(sp)
		sw	a2, 44(sp)
		jal	printChar

		#body2
		#save previous body 2 for body 3
		lw	a1, 48(sp)
		lw	a2, 52(sp)
		sw	a1, 80(sp)
		sw	a2, 84(sp)
		
		lw	a1, 72(sp)
		lw	a2, 76(sp)
		li	a0, 42
		sw	a1, 48(sp)
		sw	a2, 52(sp)
		jal	printChar

		#body3
		#save previous body 3 for space
		lw	a1, 56(sp)
		lw	a2, 60(sp)
		sw	a1, 88(sp)
		sw	a2, 92(sp)
		
		lw	a1, 80(sp)
		lw	a2, 84(sp)
		li	a0, 42
		sw	a1, 56(sp)
		sw	a2, 60(sp)
		jal	printChar
		
		#print a space at previous body3 location
		lw	a1, 88(sp)
		lw	a2, 92(sp)
		li	a0, 32
		jal	printChar
		j	endhandler

	endhandler:
		#restore a0
		addi	a0, a3, 36

		#read back registers
		lw	t0, -32(a0)	#t0 now is a0
		mv	t1, a0	#store a0(itrapData address) in t1
		mv	a0, t0	#restore a0(original value)

		# swap t1 and uscratch
		csrrw	t1, 0x040, t1	# t1 <- Addr[iTrapData], uscratch <- PROGRAMt1

		# swap a0 and uscratch
		# a0 and ustretch now restored
		csrrw	a0, 0x040, a0	# a0 <- Addr[iTrapData], uscratch <- PROGRAMa0

		#restore registers
		lw	t0, 0(a0)	# read PROGRAMt0
		lw	t1, -4(a0)	# read PROGRAMt1
		lw	t2, -8(a0)	# read PROGRAMt2
		lw	s0, -12(a0)	# read PROGRAMs0
		lw	s1, -16(a0)	# read PROGRAMs1
		lw	s2, -20(a0)	# read PROGRAMs2
		lw	a1, -24(a0)	# read PROGRAMa1
		lw	a2, -28(a0)	# read PROGRAMa2
		lw	a3, -36(a0)


		# swap a0 and uscratch
		csrrw	a0, 0x040, a0	# a0 <- Addr[iTrapData], uscratch <- PROGRAMa0

		#if time interrupt, minus 1 to the original time
		addi	s0, s0, -1

		#add one second after finish handle
		addi	t2, t2, 1000	#add one second to s0
		bltz	s0, handlerQuit
		uret
		
handlerTerminate:
	# Print error msg before terminating
	li     a7, 4
	la     a0, INTERRUPT_ERROR
	ecall
	li     a7, 34
	csrrci a0, 66, 0
	ecall
	li     a7, 4
	la     a0, INSTRUCTION_ERROR
	ecall
	li     a7, 34
	csrrci a0, 65, 0
	ecall
handlerQuit:
	li     a7, 10
	ecall	# End of program


#---------------------------------------------------------------------------------------------
# printAllWalls
#
# Subroutine description: This subroutine prints all the walls within which the snake moves
# 
#   Args:
#  		None
#
# Register Usage
#      s0: the current row
#      s1: the end row
#
# Return Values:
#	None
#---------------------------------------------------------------------------------------------
printAllWalls:
	# Stack
	addi   sp, sp, -12
	sw     ra, 0(sp)
	sw     s0, 4(sp)
	sw     s1, 8(sp)
	# print the top wall
	li     a0, 21
	li     a1, 0
	li     a2, 0
	la     a3, Brick
	lbu    a3, 0(a3)
	jal    ra, printMultipleSameChars

	li     s0, 1	# s0 <- startRow
	li     s1, 10	# s1 <- endRow
printAllWallsLoop:
	bge    s0, s1, printAllWallsLoopEnd
	# print the first brick
	la     a0, Brick	# a0 <- address(Brick)
	lbu    a0, 0(a0)	# a0 <- '#'
	mv     a1, s0		# a1 <- row
	li     a2, 0		# a2 <- col
	jal    ra, printChar
	# print the second brick
	la     a0, Brick
	lbu    a0, 0(a0)
	mv     a1, s0
	li     a2, 20
	jal    ra, printChar
	
	addi   s0, s0, 1
	jal    zero, printAllWallsLoop

printAllWallsLoopEnd:
	# print the bottom wall
	li     a0, 21
	li     a1, 10
	li     a2, 0
	la     a3, Brick
	lbu    a3, 0(a3)
	jal    ra, printMultipleSameChars

	# Unstack
	lw     ra, 0(sp)
	lw     s0, 4(sp)
	lw     s1, 8(sp)
	addi   sp, sp, 12
	jalr   zero, ra, 0


#---------------------------------------------------------------------------------------------
# printMultipleSameChars
# 
# Subroutine description: This subroutine prints white spaces in the Keyboard and Display MMIO Simulator terminal at the
# given row and column.
# 
#   Args:
#   a0: length of the chars
# 	a1: row - The row to print on.
# 	a2: col - The column to start printing on.
#   a3: char to print
#
# Register Usage
#      s0: the remaining number of cahrs
#      s1: the current row
#      s2: the current column
#      s3: the char to be printed
#
# Return Values:
#	None
#---------------------------------------------------------------------------------------------
printMultipleSameChars:
	# Stack
	addi   sp, sp, -20
	sw     ra, 0(sp)
	sw     s0, 4(sp)
	sw     s1, 8(sp)
	sw     s2, 12(sp)
	sw     s3, 16(sp)

	mv     s0, a0
	mv     s1, a1
	mv     s2, a2
	mv     s3, a3

# the loop for printing the chars
printMultipleSameCharsLoop:
	beq    s0, zero, printMultipleSameCharsLoopEnd   # branch if there's no remaining white space to print
	# Print character
	mv     a0, s3	# a0 <- char
	mv     a1, s1	# a1 <- row
	mv     a2, s2	# a2 <- col
	jal    ra, printChar
		
	addi   s0, s0, -1	# s0--
	addi   s2, s2, 1	# col++
	jal    zero, printMultipleSameCharsLoop

# All the printing chars work is done
printMultipleSameCharsLoopEnd:	
	# Unstack
	lw     ra, 0(sp)
	lw     s0, 4(sp)
	lw     s1, 8(sp)
	lw     s2, 12(sp)
	lw     s3, 16(sp)
	addi   sp, sp, 20
	jalr   zero, ra, 0


#------------------------------------------------------------------------------
# printStr
#
# Subroutine description: Prints a string in the Keyboard and Display MMIO Simulator terminal at the
# given row and column.
#
# Args:
# 	a0: strAddr - The address of the null-terminated string to be printed.
# 	a1: row - The row to print on.
# 	a2: col - The column to start printing on.
#
# Register Usage
#      s0: The address of the string to be printed.
#      s1: The current row
#      s2: The current column
#      t0: The current character
#      t1: '\n'
#
# Return Values:
#	None
#
# References: This peice of code is adjusted from displayDemo.s(Zachary Selk, Jul 18, 2019)
#------------------------------------------------------------------------------
printStr:
	# Stack
	addi   sp, sp, -16
	sw     ra, 0(sp)
	sw     s0, 4(sp)
	sw     s1, 8(sp)
	sw     s2, 12(sp)

	mv     s0, a0
	mv     s1, a1
	mv     s2, a2

# the loop for printing string
printStrLoop:
	# Check for null-character
	lb     t0, 0(s0)
	# Loop while(str[i] != '\0')
	beq    t0, zero, printStrLoopEnd

	# Print Char
	mv     a0, t0
	mv     a1, s1
	mv     a2, s2
	jal    ra, printChar

	addi   s0, s0, 1	# i++
	addi   s2, s2, 1	# col++
	jal    zero, printStrLoop

printStrLoopEnd:
	# Unstack
	lw     ra, 0(sp)
	lw     s0, 4(sp)
	lw     s1, 8(sp)
	lw     s2, 12(sp)
	addi   sp, sp, 16
	jalr   zero, ra, 0



#------------------------------------------------------------------------------
# printChar
#
# Subroutine description: Prints a single character to the Keyboard and Display MMIO Simulator terminal
# at the given row and column.
#
# Args:
# 	a0: char - The character to print
#	a1: row - The row to print the given character
#	a2: col - The column to print the given character
#
# Register Usage
#      s0: The character to be printed.
#      s1: the current row
#      s2: the current column
#      t0: Bell ascii 7
#      t1: DISPLAY_DATA
#
# Return Values:
#	None
#
# References: This peice of code is adjusted from displayDemo.s(Zachary Selk, Jul 18, 2019)
#------------------------------------------------------------------------------
printChar:
	# Stack
	addi   sp, sp, -16
	sw     ra, 0(sp)
	sw     s0, 4(sp)
	sw     s1, 8(sp)
	sw     s2, 12(sp)
	# save parameters
	mv     s0, a0
	mv     s1, a1
	mv     s2, a2

	jal    ra, waitForDisplayReady

	# Load bell and position into a register
	addi   t0, zero, 7	# Bell ascii
	slli   s1, s1, 8	# Shift row into position
	slli   s2, s2, 20	# Shift col into position
	or     t0, t0, s1
	or     t0, t0, s2	# Combine ascii, row, & col
	
	# Move cursor
	lw     t1, DISPLAY_DATA
	sw     t0, 0(t1)
	jal    waitForDisplayReady	# Wait for display before printing
	
	# Print char
	lw     t0, DISPLAY_DATA
	sw     s0, 0(t0)
	
	# Unstack
	lw     ra, 0(sp)
	lw     s0, 4(sp)
	lw     s1, 8(sp)
	lw     s2, 12(sp)
	addi   sp, sp, 16
	jalr   zero, ra, 0



#------------------------------------------------------------------------------
# waitForDisplayReady
#
# Subroutine description: A method that will check if the Keyboard and Display MMIO Simulator terminal
# can be writen to, busy-waiting until it can.
#
# Args:
# 	None
#
# Register Usage
#      t0: used for DISPLAY_CONTROL
#
# Return Values:
#	None
#
# References: This peice of code is adjusted from displayDemo.s(Zachary Selk, Jul 18, 2019)
#------------------------------------------------------------------------------
waitForDisplayReady:
	# Loop while display ready bit is zero
	lw     t0, DISPLAY_CONTROL
	lw     t0, 0(t0)
	andi   t0, t0, 1
	beq    t0, zero, waitForDisplayReady
	jalr   zero, ra, 0
