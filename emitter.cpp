#include "global.h"
#include "parser.hpp"
#include <fstream>
#include <list>
#include <set>

using std::list;
using std::ofstream;
using std::set;

bool save_to_output;
string output_file_name;
ofstream outfile;
set<entry_type> labelable_set{entry_type::LABEL, entry_type::PROGRAM_NAME, entry_type::FUNCTION, entry_type::PROCEDURE};

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
	if ((symtable[fn_or_proc_pos].name == "write") || (symtable[fn_or_proc_pos].name == "read"))
	{
		int io_arg_pos = *arg_list.begin();
		gencode(symtable[fn_or_proc_pos].name, io_arg_pos);
		return;
	}

	for (list<int>::iterator it = arg_list.begin(); it != arg_list.end(); ++it)
	{
		gencode(string("push"), *it, -1, -1, true, false, false);
	}
	gencode(string("call"), fn_or_proc_pos);

	int size_of_ptrs_pos = get_number(to_string(arg_list.size() * 4), data_type::INTEGER);
	gencode(string("incsp"), size_of_ptrs_pos);
}

void print_label(int label_pos)
{
	if (code_buffering)
	{
		callable_output_buffer += symtable[label_pos].name + ":\n";
	}
	else
	{
		cout << endl; //TODO: for debugging reasons
		emit_to_output(symtable[label_pos].name + ":\n");
	}
}

string print_symbol_content(int arg_pos, bool use_ref)
{
	entry symbol = symtable[arg_pos];
	if (symbol.type == entry_type::NUMBER || (labelable_set.find(symbol.type) != labelable_set.end()))
	{
		return "#" + symbol.name;
	}
	if (symbol.type == entry_type::VARIABLE || symbol.type == entry_type::ARRAY)
	{
		string offset_prefix = "";
		if (!symbol.is_pointer && use_ref)
		{
			offset_prefix += "#";
		}
		else if (symbol.is_pointer && !use_ref)
		{
			offset_prefix += "*";
		}
		if (symbol.is_local)
		{
			offset_prefix += "BP";
			if (symbol.offset > 0)
				offset_prefix += "+";
		}
		return offset_prefix + to_string(symbol.offset);
	}
	error("Incorrect usage of " + symbol.name);
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
		if (symtable[arg1_pos].dtype == data_type::REAL && !arg1_by_ref && (labelable_set.find(symtable[arg1_pos].type) == labelable_set.end()))
		{
			command = ".r " + command.substr(0, command.length() - 1);
		}
		else
		{
			command = ".i " + command.substr(0, command.length() - 1);
		}
	}
	command = mnem + command;
	if (code_buffering)
	{
		callable_output_buffer += command + "\n";
	}
	else
	{
		emit_to_output(command + "\n");
	}
}

void open_stream()
{
	if (save_to_output)
	{
		outfile = ofstream(output_file_name);
	}
}

void close_stream()
{
	if (outfile.is_open())
	{
		outfile.flush();
		outfile.close();
	}
}

void emit_to_output(string s)
{
	if (save_to_output)
		outfile << s;
	cout << s;
}
