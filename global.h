#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>
#include <iostream>
#include <vector>
#include <string>
#include <list>
#include <tuple>

using std::string;
using std::cout;
using std::endl;
using std::list;
using std::vector;
using std::tuple;


#define BSIZE 128
#define NONE -1
#define EOS '\0'
// #define NUM 256
// #define DIV 257
// #define MOD 258
// #define ID 259
#define DONE 0
enum class entry_type { UNDEFINED, VARIABLE, NUMBER, PROCEDURE, FUNCTION, PROGRAM_NAME, LABEL };
enum class data_type { UNDEFINED, INTEGER, REAL };

struct entry
{
	string name;
	int token;
	unsigned int offset;
	entry_type type;
	data_type dtype;
	int value;
	vector<entry> *inner_table;
};

struct op_entry
{
	string name;
	int shortcut;
	int token;
};

extern int tokenval;
extern int lineno;
extern vector<struct entry> symtable;
extern vector<struct op_entry> optable;
extern void emit_procedure(int fn_or_proc_pos, list<int> arg_list);

int insert(string s, int tok);
int insert_tempvar();
int insert_label();

int promote_assign(data_type dtype, int right_arg_pos);
tuple<int,int> promote(int left_arg_pos, int right_arg_pos);

void error(string m);
int lookup(string s);
int lookup_op(string s);
int get_number(string number_name, data_type dtype);

void allocate(int pos, data_type dtype);
void dump();
void init();
void parse();
int yylex();
int lexan();
void expr();
void term();
void factor();
void match(int t);
void emit(int t, int tval);

void gencode(string mnem, int argcount, int arg1_pos = -1, int arg2_pos = -1, int arg3_pos = -1);
void print_label(int label_pos);