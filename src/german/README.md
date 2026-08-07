Original READ ME DIZ.txt contents below:

-------------------------------

NOTE: Probably disassembled by Richard Degler

READ ME DIZ (Description In ZIP) for my Reverse Source of the file "GERMAN.X11" (C) 1981 DNA, for WIZARD OF WOR (a BALLY Commercial Arcade Game) ROM socket x11.


Don't rember the exact BBS naming convention, but all file archives had inserted
in them a READ_ME.1ST, FILE_ID.DIZ and ORIGINAL.BBS - and those extentions were
usually associated as being text files by whatever reader was in use back then.
The practice was to hard-wrap all lines to 79 or 80 characters for EGA monitors!
         1         2         3         4         5         6         7         8
12345678901234567890123456789012345678901234567890123456789012345678901234567890

Nowadays, since the turn of the century, we turn on auto word-wrap and only hit Return to start a new paragraph.  Sometimes that's not good, like in .asm files.


So, this is "GERMAN_X11.asm" foreign language file for WIZARD OF WOR arcade game dis-assembled and commented by me.  Some lines must extend up to 160 characters.
MAME currently does NOT recognize "GERMAN.X11", or should it be named "WOW.X11"?

First up at LC000: is the location of 84 GERMAN Speech String pointers which are indexed by an 80-entry GERMAN Phrase Data table (which is pointed to by LC002:).
These contain 1 to 4 entries each as noted by the flagged hex numbers $81 to $84 and still need to be extrapolated from the speech string data, based on a SC-01.

Next at LC004: is a Funny table of 6 entries of ASCII values, of unknown usage.

At LC00A: is the CHECKSUM Byte of 0, which is not even checked by the self-test?

And at LC00B: is the address of an ALTernate FoNT that needs taken advantage of!

Starting at LC00D: are 23 text strings preceded by their length - and these are displayed instead of the English equivalent when the "FOREIGN" dip-switch is on.
The 47 character limit is imposed as ASCII 48 and above are ignored counting up.

Finally, at the very end, after 205 filler bytes, is LCFEB: (ROM Identification only) of "GERMAN WIZARD", "DNA" and what could be the Date stamp of 4/30/1981 - that refers to Dave Nutting Associates (A Bally Co.), who still owns the rights?


"Welcome to my Dungeons of Wor!" (C) 1980 Midway Mfg. Co. "VIDEO IS OUR GAME" tm
