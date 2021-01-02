#include "global.h"
#include "parser.h"

/*consider storing keywords here like div mod and or etc with specific*/
struct entry keywords[] = {
	{":=", ASSIGNOP},
	{"<>", RELOP},
	{"<=", RELOP},
	{">=", RELOP},
	{"<", RELOP},
	{">", RELOP},
	{"=", RELOP},
	{"div", MULOP},
	{"mod", MULOP},
	{"*", MULOP},
	{"/", MULOP},
	{"and", MULOP},
	{"+", SIGN},
	{"-", SIGN},
	{"or", OR},
	{"not", NOT},
	{0, 0}};
void init()
{
	struct entry *p;
	for (p = keywords; p->token; p++)
		insert(p->lexptr, p->token);
}
