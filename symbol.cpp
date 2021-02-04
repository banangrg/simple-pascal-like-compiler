#include "global.h"
#include "parser.hpp"
#include <iomanip>

using std::setw;

int lastpos = 0;
vector<struct entry> symtable;
vector<struct op_entry> optable;
int lastentry = 0;
int lasttempno = 0;
int lastcondition = 0;

string decode_type(entry_type type);
string decode_dtype(data_type dtype);

int lookup(string s, bool find_function_only)
{
	for (int i = symtable.size() - 1; i > 0; i--)
		if (s.compare(symtable.at(i).name) == 0) {
			if ( (symtable[i].type != entry_type::FUNCTION) && find_function_only) continue;
			return i;
		}
	return 0;
}

int lookup_op(string s)
{
	for (int i = optable.size() - 1; i > 0; i--)
	{
		if (s.compare(optable.at(i).name) == 0)
			return i;
	}
	return 0;
}

int insert(string s, int tok)
{
	symtable.push_back({.name = s, .token = tok});
	return symtable.size() - 1;
}

int insert_tempvar(bool is_local)
{
	string s = "$t" + to_string(lasttempno++);
	int tempvar_pos = insert(s, ID);
	symtable[tempvar_pos].type = entry_type::VARIABLE;
	symtable[tempvar_pos].is_local = is_local;
	return tempvar_pos;
}

int insert_label(bool is_local)
{
	string s = "$lab" + to_string(lastcondition++);
	int label_pos = insert(s, ID);
	symtable[label_pos].type = entry_type::LABEL;
	symtable[label_pos].is_local = is_local;
	return label_pos;
}

void allocate(int pos, data_type dtype, bool is_pointer)
{
	int identifier_size;
	int element_count = 1;
	if (symtable[pos].type == entry_type::ARRAY)
	{
		element_count = symtable[pos].ainfo.size;
	}
	if (is_pointer)
	{
		identifier_size = 4;
	}
	else if (dtype == data_type::INTEGER)
	{
		identifier_size = 4 * element_count;
	}
	else if (dtype == data_type::REAL)
	{
		identifier_size = 8 * element_count;
	}
	symtable[pos].dtype = dtype;

	if (symtable[pos].is_local)
	{
		callable_offset_top -= identifier_size;
		symtable[pos].offset = callable_offset_top;
	}
	else
	{
		symtable[pos].offset = lastpos;
		lastpos += identifier_size;
	}
	symtable[pos].is_pointer = is_pointer;
}

int promote_assign(data_type left_dtype, int right_arg_pos, bool is_local)
{
	if (left_dtype == symtable[right_arg_pos].dtype)
	{
		return right_arg_pos;
	}
	else if (left_dtype == data_type::INTEGER)
	{
		int temp_pos = insert_tempvar(is_local);
		allocate(temp_pos, left_dtype);
		gencode(string("realtoint"), right_arg_pos, temp_pos);
		return temp_pos;
	}
	else if (left_dtype == data_type::REAL)
	{
		int temp_pos = insert_tempvar(is_local);
		allocate(temp_pos, left_dtype);
		gencode(string("inttoreal"), right_arg_pos, temp_pos);
		return temp_pos;
	}
	else
	{
		//TODO: error
		return -1;
	}
}

tuple<int, int> promote(int first_arg_pos, int second_arg_pos, bool is_local)
{
	if (symtable[first_arg_pos].dtype == symtable[second_arg_pos].dtype)
	{
		return std::make_tuple(first_arg_pos, second_arg_pos);
	}
	else if (symtable[first_arg_pos].dtype == data_type::REAL)
	{
		int temp_pos = insert_tempvar(is_local);
		allocate(temp_pos, data_type::REAL);
		gencode(string("inttoreal"), second_arg_pos, temp_pos);
		return std::make_tuple(first_arg_pos, temp_pos);
	}
	else if (symtable[second_arg_pos].dtype == data_type::REAL)
	{
		int temp_pos = insert_tempvar(is_local);
		allocate(temp_pos, data_type::REAL);
		gencode(string("inttoreal"), first_arg_pos, temp_pos);
		return std::make_tuple(temp_pos, second_arg_pos);
	}
	else
	{
		//TODO:error
		return std::make_tuple(-1, -1);
	}
}

int get_number(string number_name, data_type dtype)
{
	int num_pos = lookup(number_name);
	if (num_pos == 0)
	{
		num_pos = insert(number_name, NUM);
		symtable[num_pos].type = entry_type::NUMBER;
		symtable[num_pos].dtype = dtype;
	}
	return num_pos;
}

void dump(int lower_index)
{
	cout << endl;
	if (lower_index == 0)
	{
		cout << "SYMTABLE: (top = " << lastpos << ")" << endl;
	}
	else
	{
		cout << "LOCAL SYMTABLE:" << endl;
	}

	cout << "ADDR\t - \tNAME\t\t - \tTOKEN\t - \tOFFSET\t - \tTYPE\t - \tDTYPE\t - \tPOINTER\t - \tLOCAL\t - \tAINFO" << endl;
	for (int i = symtable.size() - 1; i > lower_index; i--)
	{
		struct entry symbol = symtable[i];
		cout << i - lower_index << "\t - \t" << setw(12) << symbol.name << "\t - \t" << symbol.token << "\t - \t" << symbol.offset << "\t - \t" << decode_type(symbol.type) << "\t - \t" << decode_dtype(symbol.dtype) << "\t - \t" << symbol.is_pointer << "\t - \t" << symbol.is_local << "\t - \t" << symbol.ainfo.size << endl;
	}
	cout << endl;
}

string decode_type(entry_type type)
{
	switch (type)
	{
	case entry_type::NUMBER:
		return "NUM";
	case entry_type::VARIABLE:
		return "VAR";
	case entry_type::ARRAY:
		return "ARRAY";
	case entry_type::PROCEDURE:
		return "PROC";
	case entry_type::FUNCTION:
		return "FUNC";
	case entry_type::PROGRAM_NAME:
		return "PROG";
	case entry_type::LABEL:
		return "LABEL";
	}
	return "UNDEF";
}

string decode_dtype(data_type dtype)
{
	switch (dtype)
	{
	case data_type::INTEGER:
		return "INT";
	case data_type::REAL:
		return "REAL";
	}
	return "UNDEF";
}