# Timer

This is a countdown timer written in NASM x86 assembly for linux machines.
It can also be used on Windows using WSL.

NASM is the required version of assembly becuase of how the macros are defined in **helpers.inc**

## How to use

### Requirements

- nasm - for assembly
- ddd - not technically required but a great debugger
- gcc-multilib - for debugging?

### Assemble

```text
nasm -gdwarf -f elf64 timer.asm -o timer.o
```

-gdwarf sets debugging symbols to be enabled in the [dwarf](https://dwarfstd.org/#:~:text=DWARF%20is%20a%20debugging%20file,be%20extensible%20to%20other%20languages.) format vs the [stabs](http://quenelle.org/software%20development/2005/stabs-versus-dwarf.html) format. After trying both, I found no difference for my needs. The main part is that -g is enabled.

Can also be written as -g -F dwarf

-f [elf64](https://en.wikipedia.org/wiki/Executable_and_Linkable_Format) sets the linking format

-o is the output object file

### Link

```text
ld timer.o -o timer
```

### Run

```text
timer <name> 00 00 00
```

For example:

This timer to bake a pizza for 1 hour, 5 minutes, and 30 seconds.

The name is an optional argument

```text
timer Pizza 1 5 30
```

## Resources

There are a lot of resources out there for assembly help, but with all the different syntax and types it can be tricky. Here are a couple of resources that can help if you're getting into it.

- [ASCII Wiki](https://en.wikipedia.org/wiki/ASCII)
- [University of Hawaii PPT](http://courses.ics.hawaii.edu/ReviewICS312/morea/X86NASM/ics312_nasm_data_bss.pdf)
- [Win and Linux Assembly Tutorials](https://www.youtube.com/user/khoraski/playlists)
