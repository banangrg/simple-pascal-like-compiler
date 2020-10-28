comp : main.o init.o parser.o lexer.o emitter.o error.o symbol.o
	gcc -o comp main.o init.o parser.o lexer.o emitter.o error.o symbol.o

main.o : main.c global.h
	gcc -c main.c

init.o : init.c global.h
	gcc -c init.c

parser.o : parser.c global.h
	gcc -c parser.c

lexer.o : lexer.c global.h
	gcc -c lexer.c

emitter.o : emitter.c global.h
	gcc -c emitter.c

error.o : error.c global.h
	gcc -c error.c

symbol.o : symbol.c global.h
	gcc -c symbol.c

.PHONY : clean
clean :
	rm main.o init.o parser.o lexer.o emitter.o error.o symbol.o