#include "global.h"
#include "parser.h"

void emit(int t, int tval)
{
	char t_c = (char) t;
	switch (t)
	{
		case ASSIGNOP:
			printf("ASSIGNOP\n");
			break;
		case RELOP:
			printf("RELOP\n");
			break;
		case SIGN:
			printf("SIGN\n");
			break;
		case MULOP:
			printf("MULOP\n");
			break;
		case OR:
			printf("OR\n");
			break;
		case NOT:
			printf("NOT\n");
			break;
		case NUM:
			printf("%d\n", tval);
			break;
		case ID:
			printf("%s\n", symtable[tval].lexptr);
			break;
		default:
			printf("token %d , tokenval %d\n", t, tval);
	}
}
