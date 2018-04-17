# Sequential-Lava-Maze

######################################################################
# 		                 Sequential Lava Maze                          #
######################################################################
#                   Programmed by Samuel Zrna                        #
######################################################################
#	This program requires the Keyboard and Display MMIO                #
#       and the Bitmap Display to be connected to MIPS.              #
#								                                                     #
#       Bitmap Display Settings:                                     #
#	Unit Width: 32						                                         #
#	Unit Height: 32						                                         #
#	Display Width: 256					                                       #
#	Display Height: 256					                                       #
#	Base Address for Display: 0x10008000 ($gp)		                     #
#								                                                     #
#	DESCRIPTION: I made a maze-like game using lava pixels that        #
#	update each time your player moves. The idea is to get             #
#	across the map without running into or stepping on the lava.       #
#								                                                     #
#	CONTROLS: Use w, a, s, d to move character up, right, down,        #
#	left. 							                                               #
#								                                                     #
#	TIPS: Stepping onto a dark red pixel, is 100% safe. Stepping       #
# 	onto a black pixel is 50% safe. Keep track of the sequence!      #
######################################################################
