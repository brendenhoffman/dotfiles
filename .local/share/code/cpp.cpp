//[projectName]
//[Name]
//[date]

//#include "stdafx.h"
#include <iostream>
#include <iomanip>
#include <string>

using namespace std;

void Pause()
{
    //pause the screen
    char freeze;
    cin.ignore(100,'\n');
    cout << "\nPress enter to exit...";
    cin.get(freeze);
}

int main()
{
    

    //run pause function
    Pause();

    return (0);
}
