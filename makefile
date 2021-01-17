comp : main.o init.o parser.o lexer.o emitter.o error.o symbol.o
	g++ -o comp main.o init.o parser.o lexer.o emitter.o error.o symbol.o -lfl

main.o : main.cpp global.h parser.hpp
	g++ -c main.cpp

init.o : init.cpp global.h parser.hpp
	g++ -c init.cpp

# parser.o : parser_old.c global.h
# 	g++ -c -o parser.o parser_old.c

parser.o : parser.cpp global.h parser.hpp
	g++ -c -o parser.o parser.cpp

parser.cpp parser.hpp: parser.y
	bison -d -o parser.cpp parser.y

lexer.o : lexer.cpp global.h parser.hpp
	g++ -c -o lexer.o lexer.cpp

lexer.cpp : lexer.l
	flex -o lexer.cpp lexer.l

emitter.o : emitter.cpp global.h parser.hpp
	g++ -c emitter.cpp

error.o : error.cpp global.h
	g++ -c error.cpp

symbol.o : symbol.cpp global.h
	g++ -c symbol.cpp

.PHONY : clean
clean :
	@rm comp main.o init.o parser.o parser.cpp parser.hpp lexer.o lexer.cpp emitter.o error.o symbol.o