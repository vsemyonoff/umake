for i in $(seq 101 200); do
cat << EOF > test$i.cxx
#include "main.h"

void test$i()
{
  std::cout << "test$i" << std::endl;
  return;
}
EOF
done
