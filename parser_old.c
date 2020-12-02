#include "global.h"

#define NUM 256
#define DIV 257
#define MOD 258
#define ID 259

int lookahead;
void parse()
{
	lookahead = lexan();

	while (lookahead != DONE)
	{
		expr();
		match(';');
	}
}
void expr()
{
	int t;
	term();
	while (1)
		switch (lookahead)
		{
		case '+':
		case '-':
			t = lookahead;
			match(lookahead);
			term();
			emit(t, NONE);
			continue;
		default:
			return;
		}
}
void term()
{
	int t;
	factor();
	while (1)
		switch (lookahead)
		{
		case '*':
		case '/':
		case DIV:
		case MOD:
			t = lookahead;
			match(lookahead);
			factor();
			emit(t, NONE);
			continue;
		default:
			return;
		}
}
void factor()
{
	switch (lookahead)
	{
	case '(':
		match('(');
		expr();
		match(')');
		break;
	case NUM:
		emit(NUM, tokenval);
		match(NUM);
		break;
	case ID:
		emit(ID, tokenval);
		match(ID);
		break;
	default:
		error("syntax error (factor)");
	}
}
void match(int t)
{
	if (lookahead == t)
		lookahead = lexan();
	else
		error("syntax error (match)");
}