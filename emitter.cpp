#include "global.h"
#include "parser.hpp"
#include <list>
#include <set>

using std::list;
using std::set;

set<string> jumpset { "jump", "jne", "jle", "jge", "jeq", "jg", "jl" };


void emit(int t, int tval)
{
	char t_c = (char)t;
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
		printf("%s\n", symtable[tval].name.c_str());
		break;
	default:
		printf("token %d , tokenval %d\n", t, tval);
	}
}

void emit_procedure(int fn_or_proc_pos, list<int> arg_list)
{
	if (symtable[fn_or_proc_pos].type == entry_type::PROCEDURE)
	{
		int write_func_pos = lookup(string("write"));
		int read_func_pos = lookup(string("read"));

		if (write_func_pos == fn_or_proc_pos)
		{
			int write_arg_pos = *arg_list.begin();
			gencode(string("write"), 1 , write_arg_pos);
		}
		else if (read_func_pos == fn_or_proc_pos)
		{
			int read_arg_pos = *arg_list.begin();
			gencode(string("read"), 1 ,read_arg_pos);
		}
		else
		{
			//other procedure
		}
	}
	else if (symtable[fn_or_proc_pos].type == entry_type::FUNCTION)
	{
	}
	else
	{
		//error;
	}
}

void print_label(int label_pos)
{
	cout<<symtable[label_pos].name + ":"<<endl;
}

void gencode(string mnem, int argcount, int arg1_pos, int arg2_pos, int arg3_pos)
{
	string command = mnem;
	bool uses_real = false;
	list<int> sym_idx_list = {arg1_pos, arg2_pos, arg3_pos};
	if (argcount > 0)
	{
		//TODO: make getType func
		if (symtable[arg1_pos].dtype == data_type::REAL)
		{
			command += ".r ";
		}
		else
		{
			command += ".i ";
		}
	}
	int i = 0;
	for (list<int>::iterator it = sym_idx_list.begin(); (i < argcount) && (it != sym_idx_list.end()); it++)
	{
		int arg_pos = *it;
		if ( 
				symtable[arg_pos].type == entry_type::NUMBER ||
				( (i == argcount - 1) && jumpset.find(mnem) != jumpset.end() )
			)//find is similar to 'contains'
		{
			command += "#" + symtable[arg_pos].name + ",";
		}
		else if (symtable[arg_pos].type == entry_type::VARIABLE)
		{
			command += std::to_string(symtable[arg_pos].offset) + ",";
		}
		else
		{
			//error('some error');
		}
		i++;
	}
	if (argcount > 0)
	{
		command = command.substr(0, command.length() - 1);
	}
	cout << command << endl;
}
