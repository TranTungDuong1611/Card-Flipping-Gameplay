.eqv IN_ADDRESS_HEXA_KEYBOARD 0xFFFF0012
.eqv OUT_ADDRESS_HEXA_KEYBOARD 0xFFFF0014

.eqv BLACK 	0x00000000	
.eqv RED 	0x00FF0000	# 1
.eqv GREEN 	0x0000FF00 	# 2
.eqv BLUE 	0x000000FF	# 3
.eqv WHITE 	0x00FFFFFF	# 4
.eqv YELLOW 	0x00FFFF00	# 5
.eqv CYAN	0xFF00FFFF	# 6
.eqv PURPLE	0XFF800080	# 7
.eqv GREY	0xFF808080	# 8
.eqv MONITOR_SCREEN 0x10010000

.data
NULL: .space 64
Color: .space 32 	# Save the value of color
NumberColorBitmap: .space 32 
GeneratedColorOnBitmap: .space 64
FlippedCard: .space 64
PairOfCardFlipped: .space 8		# 2 cards
PairOfIndexFlipped: .space 8		# 2 cards
FlipOrNot: .space 64			# Save index of the pairs with the same color flipped
message1: .asciz "Waiting...\n"
message2: .asciz "Choose a card to flip\n"
message3: .asciz "Game start\n"
message4: .asciz "End game"
message5: .asciz "Correct!\n"
message6: .asciz "Wrong answer\n"

# -----------------------------------------------------------------
# MAIN Procedure
# -----------------------------------------------------------------
.text
initialize:

color_array:
	li t0, 4		# index
	li t1, 7		# number of elements in the array
	la t2, Color
	# RED
	li t3, RED
	sw t3, 0(t2)
	
	# GREEN
	add t2, t2, t0
	li t3, GREEN
	sw t3, 0(t2)
	
	# BLUE
	add t2, t2, t0
	li t3, BLUE
	sw t3, 0(t2)

	# WHITE
	add t2, t2, t0
	li t3, WHITE
	sw t3, 0(t2)
	
	# YELLOW
	add t2, t2, t0
	li t3, YELLOW
	sw t3, 0(t2)
	
	# CYAN
	add t2, t2, t0
	li t3, CYAN
	sw t3, 0(t2)
	
	# PURPLE
	add t2, t2, t0
	li t3, PURPLE
	sw t3, 0(t2)
	
	# GREY
	add t2, t2, t0
	li t3, GREY
	sw t3, 0(t2)
	
# Assign the color value for bitmap
li t0, MONITOR_SCREEN	# address of monitor screen
li t1, 0		# Number of color generated
li t2, 64		# end of the bitmap
	
assign_color:
	beq t1, t2, end_assign_color
	li a7, 42		# Random a number in a range
	li a1, 8		# Range [0, 8]
	ecall
	addi t0, t0, 4		# index of the next unit in the bitmap
	add t4, a0, zero	# save the random number
	jal check_number_bitmap
	
	j assign_color
	
check_number_bitmap:
	li a3, 4
	la a1, NumberColorBitmap
	mul a0, a0, a3		# index on the check color array
	add a1, a1, a0
	lw a0, 0(a1)		# Load the number of times, this color is assigned
	li a3, 2		# a color only appears 2 times on bitmap
	beq a0, a3, do_not_add
	addi a0, a0, 1		# increase the times, this color is assigned
	sw a0, 0(a1)
	
	# Draw this color into the bitmap
	la a1, Color
	add a0, t4, zero
	li a3, 4
	mul a0, a0, a3
	add a1, a1, a0		# index on the Color array coresponding
	lw a1, 0(a1)		# Load the color value
	
	# li a0, MONITOR_SCREEN	# Draw into the bitmap
	# add a0, a0, t1
	# sw a1, 0(a0)
	
	la a0, GeneratedColorOnBitmap
	add a0, a0, t1
	sw a1, 0(a0)
	
	addi t1, t1, 4		# next unit

	jr ra
do_not_add:
	jr ra
		
end_assign_color:
		
main:
	li a6, 0		# number of card fliped (reset each 2 card) 
	li a5, 0		# message bit
	li a4, 8		# count the number of pair flipped
	# Load the interrupt service routine address to the UTVEC register
	la t0, handler
	csrrs zero, utvec, t0
	# Set the UEIE (User External Interrupt Enable) bit in UIE register
	li t1, 0x100
	csrrs zero, uie, t1 # uie - ueie bit (bit 8)
	# Set the UIE (User Interrupt Enable) bit in USTATUS register
	csrrsi zero, ustatus, 0x1 # ustatus - enable uie (bit 0)
	# Enable the interrupt of keypad of Digital Lab Sim
	li t1, IN_ADDRESS_HEXA_KEYBOARD
	li t3, 0x80 # bit 7 = 1 to enable interrupt 
	sb t3, 0(t1)
	
	li a7, 4
	la a0, message3
	ecall
	
sleep:
	beq a5, zero, print_message2
	j not_print_message2
	
print_message2:
	li a7, 4
	la a0, message2
	ecall
	li a5, 1		# Disallow print message2 again
	
not_print_message2:	
	addi a7, zero, 32
	li a0, 3000 # Sleep 300 ms
	ecall
	j sleep
end_main:
# -----------------------------------------------------------------
# Interrupt service routine
# -----------------------------------------------------------------
handler:
	# Print message1
	li a7, 4
	la a0, message1
	ecall
	li a5, 0
	
	# Saves the context
	addi sp, sp, -16
	sw a0, 0(sp)
	sw a7, 4(sp)
	sw t1, 8(sp)
	sw t2, 12(sp)
	# Handles the interrupt
	li t5, 0x01
	li t6, 0	# counter = 0
get_key_code:
	addi t6, t6, 1
	sll t2, t5, t6
	li t3, 0x80
	add t2, t2, t3
	li t1, IN_ADDRESS_HEXA_KEYBOARD
	sb t2, 0(t1) 
	li t1, OUT_ADDRESS_HEXA_KEYBOARD
	lb a0, 0(t1)
	beq a0, zero, get_key_code
	li a7, 34
	ecall
	
convert_key_code_to_index:
	li t0, 0xF		
	and t1, a0, t0        # t1 = Get Column (0x1, 0x2, 0x4, 0x8)

	srli t2, a0, 4        # Shift right 4 bits to get the row
	and t2, t2, t0        # t2 = Get row (0x1, 0x2, 0x4, 0x8)
	
	# Convert column and row to the form (0, 1, 2, 3)
        # Get column
        li a0, 0              # index = 0
        jal bitmask_to_index  # Call the function convert hexa into index
        mv t4, a0             # t4 = Column Index
        
        # Get row
    	li a0, 0
    	add t2, t1, zero 
    	jal bitmask_to_index  # 
    	mv t3, a0             # t3 = Row Index
    	addi t3, t3, -1	      # index start from 0

    	li t5, 4              # S? c?t trong m?t hàng
    	mul t6, t3, t5        # t6 = Row Index * 4
    	add a1, t6, t4        # a1 = Row Index * 4 + Column Index
    	addi a1, a1, -1	      # index start from 0
    	
    	# Check this card is up or down
    	la a0, FlipOrNot
    	mul a2, a1, t5	      # index * 4
    	add a0, a0, a2	      # Adress = first address + index * 4
    	lw t1, 0(a0)	      
    	bne t1, zero, Flipped	      # Equal 0 means down, else is up
    
    	jal flip_card    
    	
    	beq a4, zero, end_program

Flipped:	
	# Restores the context
	lw t2, 12(sp)
	lw t1, 8(sp)
	lw a7, 4(sp)
	lw a0, 0(sp)
	addi sp, sp, 16
	# Back to the main procedure
	uret
	
bitmask_to_index:
    # Input: t2 (bitmask)
    # Output: a0 (index)
    beq t2, zero, done    # N?u bitmask = 0, return
    srli t2, t2, 1        # D?ch ph?i 1 bit
    addi a0, a0, 1        # T?ng index
    j bitmask_to_index    # L?p l?i
done:
    jr ra

flip_card:
	li t1, 2
	beq a6, t1, end_flip_card
	
	# Draw this color into the bitmap
    	la a0, GeneratedColorOnBitmap	# Load the address of Generated color
    	mul a1, a1, t5			# index * 4 => address
    	add a0, a0, a1			# Get address
    	lw t3, 0(a0)			# Load the color value of this index
    	li a0, MONITOR_SCREEN		# Load the address of monitor screen
    	add a0, a0, a1
    	sw t3, 0(a0)			# Draw on the bitmap
    	
    	la a0, PairOfIndexFlipped
    	add t1, a6, a6
    	add t1, t1, t1
    	add a0, a0, t1
    	sw a1, 0(a0)			# Save the index of color flipped
    	
    	la a0, PairOfCardFlipped
    	add t1, a6, a6
    	add t1, t1, t1
    	add a0, a0, t1
    	sw t3, 0(a0)			# Save the color flipped
    		
    	addi a6, a6, 1
    	li t1, 2
    	# Check the same color or not	
    	bne a6, t1, Just_one_card_flipped	
    	addi a0, a0, -4			# previous color
    	lw t2, 0(a0)			# previous color
    	
    	beq t2, t3, same_color		# same color

	li a6, 0			# reset the number of card flipped is 0
	
	# Face down 2 card fliped
	la a0, PairOfIndexFlipped
	lw t2, 0(a0)			# First index
	addi a0, a0, 4			
	lw t3, 0(a0)			# Second index
	
	li a0, MONITOR_SCREEN
	add a0, a0, t2			# First index on the bitmap
	li t1, BLACK
	sw t1, 0(a0)			# Face down first card
	
	li a0, MONITOR_SCREEN
	add a0, a0, t3			# Second index on the bitmap
	li t1, BLACK
	sw t1, 0(a0)			# Face down second card
	
	li a7, 4
	la a0, message6
	ecall
	
	jr ra
   
same_color:
	li a6, 0			# reset the number of card flipped is 0
	
	# Index of 2 card flipped
	la a0, PairOfIndexFlipped
	lw t2, 0(a0)			# First index
	addi a0, a0, 4			
	lw t3, 0(a0)			# Second index
	
	# Check 2 card flipped is the same index or not
	# If same index, flip down the card
	
	beq t2, t3, same_index		# same index
	
	# Else
	la a0, FlipOrNot		
	add a0, a0, t2			# Index of first card
	li t1, 1
	sw t1, 0(a0)			# Load the value of 1 (same color) into this index
	
	la a0, FlipOrNot		
	add a0, a0, t3			# Index of second card
	sw t1, 0(a0)			# Load the value of 1 (same color) into this index
		
	li a7, 4
	la a0, message5
	ecall
	
	addi a4, a4, -1			# increase number of correct pair into 1
	
	jr ra

Just_one_card_flipped:
	jr ra
    	
end_flip_card:
	jr ra
	
same_index:
	# Flip down this card
	li a0, MONITOR_SCREEN
	li t1, BLACK
	add a0, a0, t2
	sw t1, 0(a0)			# Flip down this card
	
	jr ra

end_program:
	li a7, 4
	la a0, message4
	ecall
	li a7, 10
	ecall
