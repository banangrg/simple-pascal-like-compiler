comp : main.o init.o parser.o lexer.o emitter.o error.o symbol.o
	gcc -o comp main.o init.o parser.o lexer.o emitter.o error.o symbol.o -lfl

main.o : main.c global.h parser.h
	gcc -c main.c

init.o : init.c global.h parser.h
	gcc -c init.c

# parser.o : parser_old.c global.h
# 	gcc -c -o parser.o parser_old.c

parser.o : parser.c global.h parser.h
	gcc -c -o parser.o parser.c

parser.c parser.h: parser.y
	bison -d -o parser.c parser.y

lexer.o : lexer.c global.h parser.h
	gcc -c -o lexer.o lexer.c

lexer.c : lexer.l
	flex -o lexer.c lexer.l

emitter.o : emitter.c global.h parser.h
	gcc -c emitter.c

error.o : error.c global.h
	gcc -c error.c

symbol.o : symbol.c global.h
	gcc -c symbol.c

.PHONY : clean
clean :
	@rm comp main.o init.o parser.o parser.c parser.h lexer.o lexer.c emitter.o error.o symbol.o