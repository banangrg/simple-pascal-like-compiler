#include "global.h"
#include "parser.hpp"
#include <list>
#include <set>

using std::list;
using std::set;

set<string> jumpset{"jump", "jne", "jle", "jge", "jeq", "jg", "jl"};

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
			gencode(string("write"), write_arg_pos);
		}
		else if (read_func_pos == fn_or_proc_pos)
		{
			int read_arg_pos = *arg_list.begin();
			gencode(string("read"), read_arg_pos);
		}
		else
		{
			//TODO:other procedure
		}
	}
	else if (symtable[fn_or_proc_pos].type == entry_type::FUNCTION)
	{
	}
	else
	{
		//TODO:error;
	}
}

void print_label(int label_pos)
{
	cout << symtable[label_pos].name + ":" << endl;
}

string print_symbol_content(int arg_pos, bool use_ref)
{
	if (
			symtable[arg_pos].type == entry_type::NUMBER || symtable[arg_pos].type == entry_type::LABEL
		 	|| symtable[arg_pos].type == entry_type::PROGRAM_NAME
		)
	{
		return "#" + symtable[arg_pos].name;
	}
	if (symtable[arg_pos].type == entry_type::VARIABLE || symtable[arg_pos].type == entry_type::ARRAY)
	{
		if (!symtable[arg_pos].is_pointer && use_ref)
		{
			return "#" + to_string(symtable[arg_pos].offset);
		}
		else if (symtable[arg_pos].is_pointer && !use_ref) 
		{
			return "*" + to_string(symtable[arg_pos].offset);
		}
		return to_string(symtable[arg_pos].offset);
	}
	//TODO:error
	return "";
}

void gencode(string mnem, int arg1_pos, int arg2_pos, int arg3_pos, bool arg1_by_ref, bool arg2_by_ref, bool arg3_by_ref)
{
	string command = "";
	int argcount = 0;
	if (arg1_pos >= 0)
	{
		command += print_symbol_content(arg1_pos, arg1_by_ref) + ",";
		argcount++;
	}
	if (arg2_pos >= 0)
	{
		command += print_symbol_content(arg2_pos, arg2_by_ref) + ",";
		argcount++;
	}
	if (arg3_pos >= 0)
	{
		command += print_symbol_content(arg3_pos, arg3_by_ref) + ",";
		argcount++;
	}

	if (argcount > 0)
	{
		if (symtable[arg1_pos].dtype == data_type::REAL)
		{
			command = mnem + ".r " + command.substr(0, command.length() - 1);
		}
		else
		{
			command = mnem + ".i " + command.substr(0, command.length() - 1);
		}
	}
	else
	{
		command = mnem;
	}
	cout << command << endl;
}
