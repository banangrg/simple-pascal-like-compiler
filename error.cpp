#include "global.h"

using std::string;
using std::endl;

void error(string m)
{
	std::cerr<<"Line "<<lineno<<" : "<<m<<endl;
	close_stream();
	exit(1);
}
