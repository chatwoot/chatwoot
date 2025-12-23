#ifndef SASS_PATHS_H
#define SASS_PATHS_H

#include <vector>

namespace Sass {

  // Returns a list of all possible paths through the given lists.
  //
  // For example, given `[[1, 2], [3, 4], [5, 6]]`, this returns:
  //
  // ```
  // [[1, 3, 5],
  //  [2, 3, 5],
  //  [1, 4, 5],
  //  [2, 4, 5],
  //  [1, 3, 6],
  //  [2, 3, 6],
  //  [1, 4, 6],
  //  [2, 4, 6]]
  // ```
  // 
  // Note: called `paths` in dart-sass
  template <class T>
  sass::vector<sass::vector<T>> permutate(
    const sass::vector<sass::vector<T>>& in)
  {

    size_t L = in.size(), n = 0;

    if (L == 0) return {};
    // Exit early if any entry is empty
    for (size_t i = 0; i < L; i += 1) {
      if (in[i].size() == 0) return {};
    }

    size_t* state = new size_t[L + 1];
    sass::vector<sass::vector<T>> out;

    // First initialize all states for every permutation group
    for (size_t i = 0; i < L; i += 1) {
      state[i] = in[i].size() - 1;
    }
    while (true) {
      sass::vector<T> perm;
      // Create one permutation for state
      for (size_t i = 0; i < L; i += 1) {
        perm.push_back(in.at(i).at(in[i].size() - state[i] - 1));
      }
      // Current group finished
      if (state[n] == 0) {
        // Find position of next decrement
        while (n < L && state[++n] == 0) {}

        if (n == L) {
          out.push_back(perm);
          break;
        }

        state[n] -= 1;

        for (size_t p = 0; p < n; p += 1) {
          state[p] = in[p].size() - 1;
        }

        // Restart from front
        n = 0;

      }
      else {
        state[n] -= 1;
      }
      out.push_back(perm);
    }

    delete[] state;
    return out;
  }
  // EO permutate

  // ToDo: this variant is used in resolveParentSelectors
  // Returns a list of all possible paths through the given lists.
  //
  // For example, given `[[1, 2], [3, 4], [5, 6]]`, this returns:
  //
  // ```
  // [[1, 3, 5],
  //  [1, 3, 6],
  //  [1, 4, 5],
  //  [1, 4, 6],
  //  [2, 3, 5],
  //  [2, 3, 6],
  //  [2, 4, 5],
  //  [2, 4, 6]]
  // ```
  // 
  template <class T>
  sass::vector<sass::vector<T>>
    permutateAlt(const sass::vector<sass::vector<T>>& in) {

    size_t L = in.size();
    size_t n = in.size() - 1;

    if (L == 0) return {};
    // Exit early if any entry is empty
    for (size_t i = 0; i < L; i += 1) {
      if (in[i].size() == 0) return {};
    }

    size_t* state = new size_t[L];
    sass::vector<sass::vector<T>> out;

    // First initialize all states for every permutation group
    for (size_t i = 0; i < L; i += 1) {
      state[i] = in[i].size() - 1;
    }

    while (true) {
      /*
      // std::cerr << "PERM: ";
      for (size_t p = 0; p < L; p++)
      { // std::cerr << state[p] << " "; }
      // std::cerr << "\n";
      */
      sass::vector<T> perm;
      // Create one permutation for state
      for (size_t i = 0; i < L; i += 1) {
        perm.push_back(in.at(i).at(in[i].size() - state[i] - 1));
      }
      // Current group finished
      if (state[n] == 0) {
        // Find position of next decrement
        while (n > 0 && state[--n] == 0) {}

        // Check for end condition
        if (state[n] != 0) {
          // Decrease next on the left side
          state[n] -= 1;
          // Reset all counters to the right
          for (size_t p = n + 1; p < L; p += 1) {
            state[p] = in[p].size() - 1;
          }
          // Restart from end
          n = L - 1;
        }
        else {
          out.push_back(perm);
          break;
        }
      }
      else {
        state[n] -= 1;
      }
      out.push_back(perm);
    }

    delete[] state;
    return out;
  }
  // EO permutateAlt

}

#endif
