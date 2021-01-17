#include "global.h"
#include "parser.hpp"

/*consider storing keywords here like div mod and or etc with specific*/
struct entry keywords[] = {{string("\0"), 0}};
void init()
{
	struct entry *p;
	for (p = keywords; p->token; p++)
	{
		insert(p->name, p->token);
	}

	int pos = insert(string("write"), ID);
	symtable[pos].type = entry_type::PROCEDURE;
	pos = insert(string("read"), ID);
	symtable[pos].type = entry_type::PROCEDURE;
}

