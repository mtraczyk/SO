#include <assert.h>
#include <pthread.h>
#include <stdint.h>

// Interfejs między C a Asemblerem
uint64_t notec(uint32_t n, char const *calc);
int64_t debug(uint32_t n, uint64_t *stack_pointer);

// Chcemy wystartować wszystkie obliczenia możliwie jednocześnie.
volatile unsigned wait = 1;

// Startujemy co najwyżej jedno obliczenie calc_1
// i parzystą liczbę obliczeń calc_2.
static const char calc_1[] = "6N8ZXab=12-+3*~FFF&cDe09|g";
static const char calc_2[] = "nY1^W";
static const uint64_t result_1 = (~((0xab - 0x12) * 3) & 0xfff) | 0xcde09;

// Ta funkcja jest wywoływana tylko w obliczeniu calc_1
// w celu sprawdzenia jego poprawności.
int64_t debug(uint32_t n, uint64_t *stack_pointer) {
  assert(n == N - 1 && (n & 1) == 0);
  assert(*stack_pointer == result_1);

  // Usuwamy wynik ze stosu.
  return 1;
}

int main () {
  char *napis = "121AB";
  int64_t res = notec(0, napis);

  printf("%lld\n", res);

  return 0;
}
