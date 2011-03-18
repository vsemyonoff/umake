for i in $(seq 1 100); do
cat << EOF > test$i.cc
#include "main.h"

void test$i()
{
  printf("test$i");
}
EOF
done
