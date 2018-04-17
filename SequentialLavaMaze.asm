######################################################################
# 		       Sequential Lava Maze                          #
######################################################################
#                   Programmed by Samuel Zrna                        #
######################################################################
#	This program requires the Keyboard and Display MMIO          #
#       and the Bitmap Display to be connected to MIPS.              #
#								     #
#       Bitmap Display Settings:                                     #
#	Unit Width: 32						     #
#	Unit Height: 32						     #
#	Display Width: 256					     #
#	Display Height: 256					     #
#	Base Address for Display: 0x10008000 ($gp)		     #
#								     #
#	DESCRIPTION: I made a maze-like game using lava pixels that  #
#	update each time your player moves. The idea is to get       #
#	across the map without running into or stepping on the lava. #
#								     #
#	CONTROLS: Use w, a, s, d to move character up, right, down,  #
#	left. 							     #
#								     #
#	TIPS: Stepping onto a dark red pixel, is 100% safe. Stepping #
# 	onto a black pixel is 50% safe. Keep track of the sequence!  #
######################################################################

.data

# Screen 
screenWidth: 	.word 8
screenHeight: 	.word 8

test:	.asciiz "test red"

# Colors
initialLavaColor:	.word	0xe60000	# red		(0)
finalLavaColor: 	.word	0xb30000	# dark red	(1)
backgroundColor:	.word	0x000000	# black		(2, 3, 4 & 9)
destinationColor:	.word	0x00ff00	# green		(5)
keyColor: 		.word	0xffff00	# yellow	(6 & 7)
dudeColor:		.word	0x0099ff	# baby blue	(8)

keyboard:		.word	0xffff0004

# Listener & total time
frameRate:	.word 25

# Initial dude position
dudeR:	.word 0
dudeC:	.word 0

# Count the number of moves
moveCount:	.word 0
totalMoveCount: .word 0

#end game message
lostMessage:		.asciiz "OUCH! You stepped on lava..."
replayMessage:		.asciiz "Would you like to play again?"
winMessage:		.asciiz "NICE! You made it across alive!\nMove Count: "
continueMessage:	.asciiz "Would you like to continue to the next level?"
finishedMessage:	.asciiz "CONGRATS! You made through all 3 levels!\nTotal Number of moves: "

# booleans
shouldDrawGateBoolean:	.word 0
gameOverBoolean:	.word 0
winBoolean:		.word 0

# keeps track of level number
levelNumber:	.word 1

initialMap:	.word   0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0
			
level_1:	.word   3, 1, 0, 0, 2, 1, 0, 5,
			3, 0, 2, 1, 3, 3, 2, 3,
			1, 2, 9, 9, 9, 9, 3, 1,
			0, 3, 9, 0, 3, 9, 0, 3,
			1, 2, 9, 1, 0, 9, 3, 0,
			0, 0, 9, 9, 9, 9, 2, 1,
			9, 9, 0, 2, 3, 2, 3, 1,
			9, 9, 0, 1, 2, 1, 0, 3

level_2:	.word   2, 1, 0, 0, 0, 0, 0, 5,
			3, 0, 3, 2, 1, 0, 3, 0,
			0, 1, 0, 0, 0, 0, 2, 1,
			3, 2, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0,
			1, 0, 0, 0, 0, 0, 0, 0,
			9, 9, 2, 1, 0, 1, 0, 1,
			9, 9, 0, 0, 3, 2, 3, 2

level_3:	.word   1, 1, 0, 0, 2, 2, 3, 5,
			3, 2, 3, 1, 1, 0, 0, 0,
			0, 2, 1, 1, 2, 3, 2, 1,
			1, 2, 3, 0, 3, 0, 1, 3,
			1, 1, 0, 1, 0, 2, 0, 2,
			0, 2, 1, 1, 0, 3, 2, 1,
			9, 9, 2, 2, 1, 2, 0, 1,
			9, 9, 3, 1, 3, 0, 1, 2

finishedMap:	.word   9, 9, 9, 9, 9, 9, 9, 9,
			9, 9, 9, 9, 9, 9, 9, 9,
			0, 0, 0, 1, 9, 1, 9, 5,
			9, 0, 9, 1, 9, 1, 9, 5,
			9, 0, 9, 9, 1, 9, 9, 9,
			9, 0, 6, 9, 1, 6, 9, 5,
			9, 9, 9, 9, 9, 9, 9, 9,
			9, 9, 9, 9, 9, 9, 9, 9
			
.text
		
main:
	# resetting
	li $t0, 1		# loads 1 into $t0
	sw $t0, dudeC		# sets dude's x position to 1
	li $t0, 6		# loads 6 into $t0
	sw $t0, dudeR		# sets dude's y position to 6
	li $t0, 0		# loads 0 into $t0
	sw $t0, moveCount	# zeros out moveCount
	li $t0, 0		# loads 0 into $t0
	sw $t0, gameOverBoolean	# sets gameOverBoolean back to false
	li $t0, 0		# loads 0 into $t0
	sw $t0, winBoolean	# sets gameOverBoolean back to false
		
	lw $t1, levelNumber		# level number will either be 1, 2, 3 or 4
	beq $t1, 1, loadLevel_1		# jumps to loadLevel 1 if levelNumber is 1
	beq $t1, 2, loadLevel_2		# jumps to loadLevel 2 if levelNumber is 2
	beq $t1, 3, loadLevel_3		# jumps to loadLevel 3 if levelNumber is 3
	beq $t1, 4, loadFinishedMap     # jumps to last map if levelNumber is 4
		
loadLevel_1:
	la $a0, level_1		# passes the level 1 map array as a parameter for loadMap
	jal loadMap		# jumps to loadMap
	j drawMap		# draws map now that initial map has the same values as level 1

loadLevel_2:
	la $a0, level_2		# passes the level 2 map array as a parameter for loadMap
	jal loadMap		# jumps to loadMap
	j drawMap		# draws map now that initial map has the same values as level 1
	
loadLevel_3:
	la $a0, level_3		# passes the level 3 map array as a parameter for loadMap
	jal loadMap		# jumps to loadMap
	j drawMap		# draws map now that initial map has the same values as level 1

loadFinishedMap:
	la $a0, finishedMap	# passes the last level map array as a parameter for loadMap
	jal loadMap		# jumps to loadMap
	j drawMap		# draws map now that initial map has the same values as level 1
	
######################################################
# Draws the initial map
######################################################	

drawMap:
	li $t6, 0		# register $t6 is a boolean for update lava
	lw $a3, screenWidth	# loads screenWidth
	
	lw $t7, gameOverBoolean	# should always load 0 (false) into $t7 until player moves then it will be 1 (true)
	beq $t7, 1, gameOver	# jumps to checkCollision if $t7 is 1 (true)
	lw $t7, winBoolean	# should always load 0 (false) into $t7 until player moves then it will be 1 (true)
	beq $t7, 1, win		# jumps to checkCollision if $t7 is 1 (true)
	
	mul $a2, $a3, $a3 	# total number of pixels on screen
	mul $a2, $a2, 4 	# align addresses
	add $a2, $a2, $gp 	# add base of gp
	add $a3, $gp, $zero 	# loop counter
	
	li $t1, 256		# 64 words * 4 bits each = 256 bits
	li $t2, 0		# counter to begin initial display
	la $t0, initialMap	# load the address of the array
	
fillLoop:
	beq $t1, $t2, gameLoop		# check to see if all elements have been displayed
	add $t3, $t0, $t2		# gets index of initial map
	lw  $t4, 0($t3)			# gets value of index stores it into $t4
	beq $t4, 0, redPixel		# jumps to redPixel if the value is 0
	beq $t4, 1, darkRedPixel	# jumps to darkRedPixel if the value is 1
	beq $t4, 2, blackPixel		# jumps to blackPixel if the value is 2
	beq $t4, 3, blackPixel		# jumps to blackPixel if the value is 3
	beq $t4, 5, greenPixel		# jumps to greenPixel if the value is 5
	beq $t4, 6, yellowPixel		# jumps to yellowPixel if the value is 6
	beq $t4, 7, yellowPixel		# jumps to yellowPixel if the value is 7
	beq $t4, 9, blackPixel		# jumps to blackPixel if the value is 9

continueMapping:
	add $t2, $t2, 4		# increment counter
	addiu $a3, $a3, 4 	# update pixel location 
	j fillLoop

redPixel:
	lw $a1, initialLavaColor	# loads color into #a1
	sw $a1, 0($a3) 			# store color
	j continueMapping		# jumps back to continueMapping
	
darkRedPixel:
	lw $a1, finalLavaColor		# loads color into #a1
	sw $a1, 0($a3) 			# store color
	j continueMapping		# jumps back to continueMapping

blackPixel:
	lw $a1, backgroundColor		# loads color into #a1
	sw $a1, 0($a3) 			# store color
	j continueMapping		# jumps back to continueMapping
	
greenPixel:
	lw $a1, destinationColor	# loads color into #a1
	sw $a1, 0($a3) 			# store color
	j continueMapping		# jumps back to continueMapping

yellowPixel:
	lw $a1, keyColor		# loads color into #a1
	sw $a1, 0($a3) 			# store color
	j continueMapping		# jumps back to continueMapping

# game loop
gameLoop:
	# getting use input
	lw $t0, keyboard		# keyboard is #ffff0004
	lbu $t1, 0($t0)			# loads whatever char that the user presses into $t1
	move $a0, $t1			# moves character to $a0 as a parameter for moveCharacter
	jal moveCharacter		# jumps to moveCharacter 	
	li $t1, 'q'			# loads 'q' back to into $t1
	sw $t1, 0($t0)			# stores it so that the dude won't keep moving in the previous direction
	
	lw $a0, frameRate		# there needs to be a slight pause in the game loop
	jal pause			# jumps to pause w/ the parameter of frameRate stored as #a0

	# draw dude
	lw $a0, dudeC			# loads dude's x coordinate into parameter #a0
	lw $a1, dudeR			# loads dude's y coordinate into parameter #a1
	jal coordinateToAddress		# calls coordinateToAddress with parameters $a0 and $a1
	add $a0, $v0, $zero		# adds value from $v0 to $a0
	lw $a1, dudeColor		# loads dude color into $a1
	jal drawPixel			# draws dude in the current (x, y) position
	
	beq $t6, 1, updateLava		# if $t6 boolean is true, update lava

	j gameLoop			# continues with the game loop
	
updateLava:
	lw $t0, moveCount		# loads moveCount
	addi $t0, $t0, 1		# adds one to move count
	sw $t0, moveCount		# stores new move count

	jal updateMap			# jumps to updateMap
	jal checkCollision
#	li $t0, 1			# loads 1 (true) into $t0
#	sw $t0, checkCollisionBoolean	# stores value of $t0 into variable as a boolean
	j drawMap			# jumps to drawMap

##################################################################
# Dude movement
# Takes the keyboard's input, checks to see if it matches w,a,s,d
##################################################################
moveCharacter:
	addi $sp, $sp, -4	# points to the next spot in on the stack
	sw $ra, 0($sp)		# saves the address onto that stack
	
	move $s0, $a0		# moves parameter $a0 into $s0
	beq $s0, 'w', moveUp	# if it's w branch to moveUp
	beq $s0, 'a', moveLeft	# if it's a branch to moveLeft
	beq $s0, 's', moveDown	# if it's s branch to moveDown
	beq $s0, 'd', moveRight	# if it's d branch to moveRight
	
	lw $ra, 0($sp)		# gets the address from the stack
	addi $sp, $sp, 4	# goes back to the original spot of the stack
	jr $ra			# jump returns 

############# MOVE UP ############# 
moveUp:
	addi $sp, $sp, -4	# points to the next spot in on the stack
	sw $ra, 0($sp)		# saves the address onto that stack

	lw $s1, dudeR			# gets dude's y position
	lw $s2, dudeC			# gets dude's x position
	beq $s1, 0, moveUpReturn	# return if dude is adjacent to the top wall
	li $t6, 1			# toggles register $t6 as a boolean, if it doesn't hit wall
	
	# erase out dated dude
	lw $a0, dudeC			# gets dude's x position
	lw $a1, dudeR			# gets dude's y position
	jal coordinateToAddress		# takes $a0 and $a1 as parameters for 
	add $a0, $v0, $zero		# stores dude's old index to $a0
	lw $a1, backgroundColor		# stores black to  $a1 
	jal drawPixel			# draws pixel to clear old dude position
	
	sub $a0, $s1, 1			# places dude's new y coordinate to $a0
	move $a1, $s2			# places dude's x coordinate to $a0

	sub $s1, $s1, 1			# gets dude's current position
	sw $s1, dudeR			# stores it as dudeR
	
moveUpReturn:
	lw $ra, 0($sp)		# gets the address from the stack
	addi $sp, $sp, 4	# goes back to the original spot of the stack
	jr $ra			# jump returns
# END MOVE UP

############# MOVE DOWN ############# 
moveDown:
	addi $sp, $sp, -4	# points to the next spot in on the stack
	sw $ra, 0($sp)		# saves the address onto that stack
	
	lw $s1, dudeR			# gets dude's y position
	lw $s2, dudeC			# gets dude's x position
	beq $s1, 7, moveDownReturn	# return if dude is adjacent to the bottom wall
	li $t6, 1			# toggles register $t6 as a boolean, if it doesn't hit wall
	
	# erase out dated dude
	lw $a0, dudeC			# gets dude's x position
	lw $a1, dudeR			# gets dude's y position
	jal coordinateToAddress		# takes $a0 and $a1 as parameters for 
	add $a0, $v0, $zero		# stores dude's old index to $a0
	lw $a1, backgroundColor		# stores black to  $a1 
	jal drawPixel			# draws pixel to clear old dude position
	
	add $a0, $s1, 1			# places dude's new y coordinate to $a0
	move $a1, $s2			# places dude's x coordinate to $a0

	add $s1, $s1, 1			# gets dude's current position
	sw $s1, dudeR			# stores it as dudeR
	
moveDownReturn:
	lw $ra, 0($sp)		# gets the address from the stack
	addi $sp, $sp, 4	# goes back to the original spot of the stack
	jr $ra			# jump returns
# END MOVE DOWN

############## MOVE RIGHT #################
moveRight:
	addi $sp, $sp, -4	# points to the next spot in on the stack
	sw $ra, 0($sp)		# saves the address onto that stack
	
	lw $s1, dudeR			# gets dude's y position
	lw $s2, dudeC			# gets dude's x position
	beq $s2, 7, moveRightReturn	# return if dude is adjacent to the right wall
	li $t6, 1			# toggles register $t6 as a boolean, if it doesn't hit wall
	
	# erase out dated dude
	lw $a0, dudeC			# gets dude's x position
	lw $a1, dudeR			# gets dude's y position
	jal coordinateToAddress		# takes $a0 and $a1 as parameters for 
	add $a0, $v0, $zero		# stores dude's old index to $a0
	lw $a1, backgroundColor		# stores black to  $a1 
	jal drawPixel			# draws pixel to clear old dude position
	
	add $a0, $s2, 1			# places dude's new x coordinate to $a0
	move $a1, $s1			# places dude's y coordinate to $a0

	add $s2, $s2, 1			# gets dude's current position
	sw $s2, dudeC			# stores it as dudeC
	
moveRightReturn:
	lw $ra, 0($sp)		# gets the address from the stack
	addi $sp, $sp, 4	# goes back to the original spot of the stack
	jr $ra			# jump returns
# END MOVE RIGHT			

############## MOVE LEFT #################
moveLeft:
	addi $sp, $sp, -4	# points to the next spot in on the stack
	sw $ra, 0($sp)		# saves the address onto that stack
	
	lw $s1, dudeR			# gets dude's y position
	lw $s2, dudeC			# gets dude's x position
	beq $s2, 0, moveLeftReturn	# return if dude is adjacent to the left wall
	li $t6, 1			# toggles register $t6 as a boolean, if it doesn't hit wall

	# erase out dated dude
	lw $a0, dudeC			# gets dude's x position
	lw $a1, dudeR			# gets dude's y position
	jal coordinateToAddress		# takes $a0 and $a1 as parameters for 
	add $a0, $v0, $zero		# stores dude's old index to $a0
	lw $a1, backgroundColor		# stores black to  $a1 
	jal drawPixel			# draws pixel to clear old dude position
	
	sub $a0, $s2, 1			# places dude's new x coordinate to $a0
	move $a1, $s1			# places dude's y coordinate to $a0

	sub $s2, $s2, 1			# gets dude's current position
	sw $s2, dudeC			# stores it as dudeC
	
moveLeftReturn:
	lw $ra, 0($sp)		# gets the address from the stack
	addi $sp, $sp, 4	# goes back to the original spot of the stack
	jr $ra			# jump returns
# END MOVE LEFT


##################################################################
#CoordinatesToAddress Function
# $a0 -> x coordinate
# $a1 -> y coordinate
##################################################################
# returns $v0 -> the address of the coordinates for bitmap display
##################################################################
coordinateToAddress:
	lw $v0, screenWidth 	#Store screen width into $v0
	mul $v0, $v0, $a1	#multiply by y position
	add $v0, $v0, $a0	#add the x position
	mul $v0, $v0, 4		#multiply by 4
	add $v0, $v0, $gp	#add global pointerfrom bitmap display
	jr $ra			# return $v0

##################################################################
#Draw Function
# $a0 -> Address position to draw at
# $a1 -> Color the pixel should be drawn
##################################################################
# no return value
##################################################################
drawPixel:
	sw $a1, ($a0) 	#fill the coordinate with specified color
	jr $ra		#return
	
######################################################
# Pause function
######################################################
pause:
	li $v0, 32 #syscall value for sleep
	syscall
	jr $ra
		
######################################################
# Update map
######################################################
updateMap:
	addi $sp, $sp, -4	# points to the next spot in on the stack
	sw $ra, 0($sp)		# saves the address onto that stack

	li $t1, 256		# 64 * 4 = 256 which is needed to access all elements of the array
	li $t2, 0		# i = 0, will break once it reaches 256
	la $t0, initialMap	# loads map into register $t0
	
# this loop will iterate until $t2 = $t1 (256)
loopMap:
	beq $t1, $t2, finishedUpdatingLava	# branches to finishedUpdatingLava
	add $t3, $t0, $t2			# accesses next element of array based on where $t2 is at
	lw  $t4, 0($t3)				# stores content of that element into register $t4
	blt $t4, 4, changeLava			# if $t4 is less than 4 branch to change lava

# else
continueUpdating:
	sw  $t4, 0($t3)		# keeps the same value (any value 4 or more) as it was
	add $t2, $t2, 4		# increments $t2 by 4 to access next element of the array and continues the iteration
	j loopMap		# jumps back to loopMap to contine the loop

# if $t4 is less than 4
changeLava:
	addi $t4, $t4, 1 	# increment lava state by 1	
	beq $t4, 4, resetLava	# if lava state is equal to 4 branch to 
	j continueUpdating	# jumps back to loopMap at continueUpdating

# if lava state is equal to 4	
resetLava:
	li $t4, 0		# resets lava state back to 0
	j continueUpdating	# jumps back to loopMap at continueUpdating
	
finishedUpdatingLava:
	lw $ra, 0($sp)		# gets the address from the stack
	addi $sp, $sp, 4	# goes back to the original spot of the stack
	jr $ra			# jump returns

checkCollision:
	addi $sp, $sp, -4	# points to the next spot in on the stack
	sw $ra, 0($sp)		# saves the address onto that stack

	# gets dude's position
	lw $a0, dudeC			# gets dude's x position
	lw $a1, dudeR			# gets dude's y position
	lw $t0, screenWidth
	mul $t0, $t0, $a1	# multiply by y position
	add $t0, $t0, $a0	# add the x position
	mul $t0, $t0, 4		# multiply by 4
	
	la $t1, initialMap 	# loads map into
	add $t2, $t1, $t0	# gets index of element
	lw  $t3, 0($t2)		# stores contents of current element into $t2
	
	beq $t3, 0, gameOverSwitch	# jumps to gameOver if collides with lava
	beq $t3, 1, gameOverSwitch	# jumps to gameOver if collides with lava
	beq $t3, 5, winSwitch		# jumps to win if collides with finish zone
	
	lw $ra, 0($sp)		# gets the address from the stack
	addi $sp, $sp, 4	# goes back to the original spot of the stack
	jr $ra			# jump returns
	
gameOverSwitch:
	li $t0, 1
	sw $t0, gameOverBoolean
	
	lw $ra, 0($sp)		# gets the address from the stack
	addi $sp, $sp, 4	# goes back to the original spot of the stack
	jr $ra			# jump returns
	
winSwitch:
	li $t0, 1
	sw $t0, winBoolean
	
	lw $ra, 0($sp)		# gets the address from the stack
	addi $sp, $sp, 4	# goes back to the original spot of the stack
	jr $ra			# jump returns
	
loadMap:
	# stores space onto stack to safely use registers
	addi $sp, $sp, -32	# points to the next spot in on the stack
	sw $ra, 0($sp)		# saves the address onto that stack
	sw $t0, 4($sp)
	sw $t1, 8($sp)
	sw $t2, 12($sp)
	sw $t3, 16($sp)
	sw $t4, 20($sp)
	sw $t5, 24($sp)
	sw $t6, 28($sp)

	li $t1, 64		# branch count is 64 b/c I'm using sll this time
	li $t2, 0		# i = 0
	la $t0, initialMap	# loads initial map into $t0
	move $a1, $a0		# moves parameter #a0 into $a1 because I needed to use $a0 to debug

copyMap: 
	beq $t2, $t1, exitCopyMap	# branches to exitCopyMap once $t2 = 64
	sll $t3, $t2, 2			# points to the next inex of the array
	add $t4, $t0, $t3 		# getting the next element of the array of initialMap
	add $t5, $a1, $t3		# getting the next element of the array of selected level
	lw $t6, ($t5)			# loads element from selected leve
	sw $t6, ($t4)			# stores element into initialMap
	addi $t2, $t2, 1		# increments $t2 by 1
	
	j copyMap			# continues to copyMap

exitCopyMap:
	
	# returns stored space from stack to safely use registers
	lw $ra, 0($sp)		# saves the address onto that stack
	lw $t0, 4($sp)
	lw $t1, 8($sp)
	lw $t2, 12($sp)
	lw $t3, 16($sp)
	lw $t4, 20($sp)
	lw $t5, 24($sp)
	lw $t6, 28($sp)
	addi $sp, $sp, 32	# goes back to the original spot of the stack
	jr $ra			# jump returns

gameOver:
	lw $v0, levelNumber	# loads level number
	beq $v0, 4, congrats	# if last level jump to congrats
	
	li $v0, 55 		#syscall value for dialog
	la $a0, lostMessage 	#get message
	li $a1, 1
	syscall
	
	li $v0, 50 		#syscall for yes/no dialog
	la $a0, replayMessage 	#get message
	syscall
	
	li $t0, 1		# stores 1 into register $t0
	sw $t0, levelNumber	# returns to level one
	
	beq $a0, 0, main	# replay level
	beq $a0, 1, exit	# exit game
	beq $a0, 2, exit	# exit game
	
win:
	lw $t0, moveCount	# gets move count
	lw $t1, totalMoveCount	# gets total move count
	add $t1, $t1, $t0	# adds them together
	sw $t1, totalMoveCount	# stores new totalMoveCount

	lw $v0, levelNumber	# loads level number
	beq $v0, 4, congrats	# if last level jump to congrats
	
	li $v0, 56 		#syscall value for dialog
	la $a0, winMessage 	#get message
	lw $a1, moveCount
	syscall
	
	li $v0, 50 			#syscall for yes/no dialog
	la $a0, continueMessage 	#get message
	syscall
	
	lw $t0, levelNumber	# loads level # into $t0
	addi $t0, $t0, 1	# adds 1 to reguster $t0
	sw $t0, levelNumber	# stores next level into level number
	
	beq $a0, 0, main	# continue to next level
	beq $a0, 1, exit	# exit game
	beq $a0, 2, exit	# exit game

congrats:
	li $v0, 56 			#syscall value for dialog
	la $a0, finishedMessage 	#get message
	lw $a1, totalMoveCount
	syscall
exit:
		
	li $v0, 10
	syscall 
