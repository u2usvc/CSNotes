# Resolution

## Shared lib

### resolve SO address from link_map

```cpp
#include <cstdint>
#include <cstdio>
#include <elf.h>
#include <link.h>
#include "../hash/hash.hpp"
#include "../static/debug.hpp"

void* resolve_lib(uint64_t libHash) {
  // resolve the address of .dynamic section
  extern Elf64_Dyn _DYNAMIC[];

  r_debug* dbg = nullptr;
  for (Elf64_Dyn* dyn = _DYNAMIC; dyn->d_tag != DT_NULL; dyn++) {
    if (dyn->d_tag == DT_DEBUG) {
      dbg = (r_debug*)dyn->d_un.d_ptr;
    }
  }
  if (dbg == nullptr) {
    DEBUG_ERR("Failed to get r_debug");
    return nullptr;
  }
  DEBUG_TRACE("Found r_debug: %p", dbg);

  for (link_map* lm = dbg->r_map; lm != nullptr; lm = lm->l_next) {
    uint64_t retrievedhash = hash(lm->l_name);
    DEBUG_TRACE("Retrieved hash: %lu", retrievedhash);
    DEBUG_TRACE("SO hash: %lu", libHash);

    if (retrievedhash == libHash) {
      DEBUG_VERBOSE("lib resolved");
      return lm;
    }
  }

  return nullptr;
}
```
