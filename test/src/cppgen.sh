for i in $(seq 1 100); do
cat << EOF > test$i.cpp
#include "main.h"

void test$i()
{
  std::cout << "test$i" << std::endl;
  return;
}
EOF
done
