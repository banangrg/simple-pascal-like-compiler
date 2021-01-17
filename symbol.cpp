#include "global.h"
#include "parser.hpp"

#define STACKMAX 999
#define SYMMAX 100

int lastpos = 0;
struct entry symtable[SYMMAX];
int lastentry = 0;
int lasttempno = 0;
int lookup(string s)
{
	int p;
	for (p = lastentry; p > 0; p--)
		if (s.compare(symtable[p].name) == 0)
			return p;
	return 0;
}

int insert(string s, int tok)
{
	lastentry++;
	symtable[lastentry].token = tok;
	symtable[lastentry].name = s;
	return lastentry;
}

int insert_temp()
{
	string s = "$t" + std::to_string(lasttempno++);
	return insert(s, ID);
}

void allocate(int pos, data_type dtype)
{
	int identifier_size;
	if (dtype == data_type::INTEGER)
	{
		identifier_size = 4;
		symtable[pos].dtype = dtype;
	}
	else if (dtype == data_type::REAL)
	{
		identifier_size = 8;
		symtable[pos].dtype = dtype;
	} 
	else
	{
		/* code for arrays */
	}
	symtable[pos].offset = lastpos;
	lastpos += identifier_size;	
}

int promote_assign(data_type left_dtype, int right_arg_pos)
{
	if ( left_dtype == symtable[right_arg_pos].dtype )
	{
		return right_arg_pos;
	}
	else if (left_dtype == data_type::INTEGER)
	{
		int temp_pos = insert_temp();
		symtable[temp_pos].type = entry_type::VARIABLE;
		allocate(temp_pos, left_dtype);
		gencode(string("realtoint"), 2, right_arg_pos, temp_pos);
		return temp_pos;
	}
	else if (left_dtype == data_type::REAL)
	{
		int temp_pos = insert_temp();
		symtable[temp_pos].type = entry_type::VARIABLE;
		allocate(temp_pos, left_dtype);
		gencode(string("inttoreal"), 2, right_arg_pos, temp_pos);
		return temp_pos;
	}
	else
	{
		//TODO: error
		return -1;
	}
}

tuple<int, int> promote(int first_arg_pos, int second_arg_pos)
{
	if (symtable[first_arg_pos].dtype == symtable[second_arg_pos].dtype)
	{
		return std::make_tuple(first_arg_pos, second_arg_pos);
	}
	else if (symtable[first_arg_pos].dtype == data_type::REAL)
	{
		int temp_pos = insert_temp();
		symtable[temp_pos].type = entry_type::VARIABLE;
		allocate(temp_pos, data_type::REAL);
		gencode(string("inttoreal"), 2, second_arg_pos, temp_pos);
		return std::make_tuple(first_arg_pos, temp_pos);
	}
	else if (symtable[second_arg_pos].dtype == data_type::REAL)
	{
		int temp_pos = insert_temp();
		symtable[temp_pos].type = entry_type::VARIABLE;
		allocate(temp_pos, data_type::REAL);
		gencode(string("inttoreal"), 2, first_arg_pos, temp_pos);
		return std::make_tuple(temp_pos, second_arg_pos);
	}
	else
	{
		//TODO:error
		return std::make_tuple(-1, -1);
	}
}

void dump()
{
	cout<<endl<<"SYMTABLE: (top = "<<lastpos<<")"<<endl;
	cout<<"ADDR\t - \tNAME\t - \tTOKEN\t - \tOFFSET\t - \tTYPE\t - \tDTYPE\t - \tVALUE"<<endl;
	for (int p = lastentry; p > 0; p--)
	{
		struct entry symbol = symtable[p];
		cout<<p<<"\t - \t"<<symbol.name<<"\t - \t"<<symbol.token<<"\t - \t"<<symbol.offset<<"\t - \t"<<static_cast<int>(symbol.type)<<"\t - \t"<<static_cast<int>(symbol.dtype)<<"\t - \t"<<symbol.value<<endl;
	}
	cout<<endl;
}