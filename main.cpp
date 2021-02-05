#include "global.h"
#include "parser.hpp"

int main(int argc, char *argv[])
{
	if (argc == 2)
	{
		if (!strlen(argv[1]))
		{
			cout<<"Please provide valid output filename in order to save compiler output"<<endl;
			exit(1);
		} 
		save_to_output = true;
		output_file_name = argv[1];
		open_stream();
	}
	init();
	parse();
	if (argc == 2) close_stream();
	exit(0);
}
