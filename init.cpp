#include "global.h"
#include "parser.hpp"

/*consider storing keywords here like div mod and or etc with specific*/
struct op_entry operators[] = {
	{string("<>"), 1, RELOP},
	{string("<="), 2, RELOP},
	{string(">="), 3, RELOP},
	{string("="), 4, RELOP},
	{string(">"), 5, RELOP},
	{string("<"), 6, RELOP},
	{string("+"), 1, SIGN},
	{string("-"), 2, SIGN},
	{string("*"), 1, MULOP},
	{string("/"), 2, MULOP},
	{string("div"), 3, MULOP},
	{string("mod"), 4, MULOP},
	{string("and"), 5, MULOP},
	{string("\0"), 0, 0},
};
void init()
{
	insert(string("\0"), 0); //insert a 0 used for stop condition of lookup function
	struct op_entry *p;
	for (p = operators; p->token; p++)
	{
		optable.push_back(*p);
	}
	int pos = insert(string("write"), ID);
	symtable[pos].type = entry_type::PROCEDURE;
	pos = insert(string("read"), ID);
	symtable[pos].type = entry_type::PROCEDURE;	
}
