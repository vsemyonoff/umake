#include <iostream>

int main()
{
    int arch = sizeof(void*) == 4 ? 32 : 64;
    std::cout << "current arch: " << arch << "bit" << std::endl;
    return 0;
}
