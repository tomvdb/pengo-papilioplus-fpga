Since the Pengo hardware is very similar to the Pacman hardware, I based this project on MikeJ's Pacman implementation from FPGAArcade and added the necessary changes to make Pengo work.

Specifically, additional program and graphics ROMs were added to fit the Pengo game, a ROM descrambler was implemented (based on MAME source code) and all the required address remapping for the game components.

Simply by changing ROM files and flipping the state of the PACMAN constant in the top level module, this implementation will run either Pengo or all the Pacman based games such as Pacman, Gorkans, Liz Wiz, Paint Roller, etc.

Added memmory mapper and descramble logic for Ms Pacman so this game will also play now in this implementation.