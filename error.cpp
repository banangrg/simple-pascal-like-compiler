#include "global.h"

using std::string;
using std::endl;

void error(string m)
{
	std::cerr<<"line "<<lineno<<" :"<<m<<endl;
	exit(1);
}
