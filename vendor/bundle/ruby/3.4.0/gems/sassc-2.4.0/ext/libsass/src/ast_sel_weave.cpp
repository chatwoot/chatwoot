// sass.hpp must go before all system headers to get the
// __EXTENSIONS__ fix on Solaris.
#include "sass.hpp"

#include "ast.hpp"
#include "permutate.hpp"
#include "dart_helpers.hpp"

namespace Sass {

  // ##########################################################################
  // Returns whether or not [compound] contains a `::root` selector.
  // ##########################################################################
  bool hasRoot(const CompoundSelector* compound)
  {
    // Libsass does not yet know the root selector
    return false;
  }
  // EO hasRoot

  // ##########################################################################
  // Returns whether a [CompoundSelector] may contain only
  // one simple selector of the same type as [simple].
  // ##########################################################################
  bool isUnique(const SimpleSelector* simple)
  {
    if (Cast<IDSelector>(simple)) return true;
    if (const PseudoSelector * pseudo = Cast<PseudoSelector>(simple)) {
      if (pseudo->is_pseudo_element()) return true;
    }
    return false;
  }
  // EO isUnique

  // ##########################################################################
  // Returns whether [complex1] and [complex2] need to be unified to
  // produce a valid combined selector. This is necessary when both
  // selectors contain the same unique simple selector, such as an ID.
  // ##########################################################################
  bool mustUnify(
    const sass::vector<SelectorComponentObj>& complex1,
    const sass::vector<SelectorComponentObj>& complex2)
  {

    sass::vector<const SimpleSelector*> uniqueSelectors1;
    for (const SelectorComponent* component : complex1) {
      if (const CompoundSelector * compound = component->getCompound()) {
        for (const SimpleSelector* sel : compound->elements()) {
          if (isUnique(sel)) {
            uniqueSelectors1.push_back(sel);
          }
        }
      }
    }
    if (uniqueSelectors1.empty()) return false;

    // ToDo: unsure if this is correct
    for (const SelectorComponent* component : complex2) {
      if (const CompoundSelector * compound = component->getCompound()) {
        for (const SimpleSelector* sel : compound->elements()) {
          if (isUnique(sel)) {
            for (auto check : uniqueSelectors1) {
              if (*check == *sel) return true;
            }
          }
        }
      }
    }

    return false;

  }
  // EO isUnique

  // ##########################################################################
  // Helper function used by `weaveParents`
  // ##########################################################################
  bool cmpGroups(
    const sass::vector<SelectorComponentObj>& group1,
    const sass::vector<SelectorComponentObj>& group2,
    sass::vector<SelectorComponentObj>& select)
  {

    if (group1.size() == group2.size() && std::equal(group1.begin(), group1.end(), group2.begin(), PtrObjEqualityFn<SelectorComponent>)) {
      select = group1;
      return true;
    }

    if (!Cast<CompoundSelector>(group1.front())) {
      select = {};
      return false;
    }
    if (!Cast<CompoundSelector>(group2.front())) {
      select = {};
      return false;
    }

    if (complexIsParentSuperselector(group1, group2)) {
      select = group2;
      return true;
    }
    if (complexIsParentSuperselector(group2, group1)) {
      select = group1;
      return true;
    }

    if (!mustUnify(group1, group2)) {
      select = {};
      return false;
    }

    sass::vector<sass::vector<SelectorComponentObj>> unified
      = unifyComplex({ group1, group2 });
    if (unified.empty()) return false;
    if (unified.size() > 1) return false;
    select = unified.front();
    return true;
  }
  // EO cmpGroups

  // ##########################################################################
  // Helper function used by `weaveParents`
  // ##########################################################################
  template <class T>
  bool checkForEmptyChild(const T& item) {
    return item.empty();
  }
  // EO checkForEmptyChild

  // ##########################################################################
  // Helper function used by `weaveParents`
  // ##########################################################################
  bool cmpChunkForEmptySequence(
    const sass::vector<sass::vector<SelectorComponentObj>>& seq,
    const sass::vector<SelectorComponentObj>& group)
  {
    return seq.empty();
  }
  // EO cmpChunkForEmptySequence

  // ##########################################################################
  // Helper function used by `weaveParents`
  // ##########################################################################
  bool cmpChunkForParentSuperselector(
    const sass::vector<sass::vector<SelectorComponentObj>>& seq,
    const sass::vector<SelectorComponentObj>& group)
  {
    return seq.empty() || complexIsParentSuperselector(seq.front(), group);
  }
   // EO cmpChunkForParentSuperselector

  // ##########################################################################
  // Returns all orderings of initial subseqeuences of [queue1] and [queue2].
  // The [done] callback is used to determine the extent of the initial
  // subsequences. It's called with each queue until it returns `true`.
  // Destructively removes the initial subsequences of [queue1] and [queue2].
  // For example, given `(A B C | D E)` and `(1 2 | 3 4 5)` (with `|` denoting
  // the boundary of the initial subsequence), this would return `[(A B C 1 2),
  // (1 2 A B C)]`. The queues would then contain `(D E)` and `(3 4 5)`.
  // ##########################################################################
  template <class T>
  sass::vector<sass::vector<T>> getChunks(
    sass::vector<T>& queue1, sass::vector<T>& queue2,
    const T& group, bool(*done)(const sass::vector<T>&, const T&)
  ) {

    sass::vector<T> chunk1;
    while (!done(queue1, group)) {
      chunk1.push_back(queue1.front());
      queue1.erase(queue1.begin());
    }

    sass::vector<T> chunk2;
    while (!done(queue2, group)) {
      chunk2.push_back(queue2.front());
      queue2.erase(queue2.begin());
    }

    if (chunk1.empty() && chunk2.empty()) return {};
    else if (chunk1.empty()) return { chunk2 };
    else if (chunk2.empty()) return { chunk1 };

    sass::vector<T> choice1(chunk1), choice2(chunk2);
    std::move(std::begin(chunk2), std::end(chunk2),
      std::inserter(choice1, std::end(choice1)));
    std::move(std::begin(chunk1), std::end(chunk1),
      std::inserter(choice2, std::end(choice2)));
    return { choice1, choice2 };
  }
  // EO getChunks

  // ##########################################################################
  // If the first element of [queue] has a `::root` 
  // selector, removes and returns that element.
  // ##########################################################################
  CompoundSelectorObj getFirstIfRoot(sass::vector<SelectorComponentObj>& queue) {
    if (queue.empty()) return {};
    SelectorComponent* first = queue.front();
    if (CompoundSelector* sel = Cast<CompoundSelector>(first)) {
      if (!hasRoot(sel)) return {};
      queue.erase(queue.begin());
      return sel;
    }
    return {};
  }
  // EO getFirstIfRoot

  // ##########################################################################
  // Returns [complex], grouped into sub-lists such that no sub-list
  // contains two adjacent [ComplexSelector]s. For example,
  // `(A B > C D + E ~ > G)` is grouped into `[(A) (B > C) (D + E ~ > G)]`.
  // ##########################################################################
  sass::vector<sass::vector<SelectorComponentObj>> groupSelectors(
    const sass::vector<SelectorComponentObj>& components)
  {
    bool lastWasCompound = false;
    sass::vector<SelectorComponentObj> group;
    sass::vector<sass::vector<SelectorComponentObj>> groups;
    for (size_t i = 0; i < components.size(); i += 1) {
      if (CompoundSelector* compound = components[i]->getCompound()) {
        if (lastWasCompound) {
          groups.push_back(group);
          group.clear();
        }
        group.push_back(compound);
        lastWasCompound = true;
      }
      else if (SelectorCombinator* combinator = components[i]->getCombinator()) {
        group.push_back(combinator);
        lastWasCompound = false;
      }
    }
    if (!group.empty()) {
      groups.push_back(group);
    }
    return groups;
  }
  // EO groupSelectors

  // ##########################################################################
  // Extracts leading [Combinator]s from [components1] and [components2]
  // and merges them together into a single list of combinators.
  // If there are no combinators to be merged, returns an empty list.
  // If the combinators can't be merged, returns `null`.
  // ##########################################################################
  bool mergeInitialCombinators(
    sass::vector<SelectorComponentObj>& components1,
    sass::vector<SelectorComponentObj>& components2,
    sass::vector<SelectorComponentObj>& result)
  {

    sass::vector<SelectorComponentObj> combinators1;
    while (!components1.empty() && Cast<SelectorCombinator>(components1.front())) {
      SelectorCombinatorObj front = Cast<SelectorCombinator>(components1.front());
      components1.erase(components1.begin());
      combinators1.push_back(front);
    }

    sass::vector<SelectorComponentObj> combinators2;
    while (!components2.empty() && Cast<SelectorCombinator>(components2.front())) {
      SelectorCombinatorObj front = Cast<SelectorCombinator>(components2.front());
      components2.erase(components2.begin());
      combinators2.push_back(front);
    }

    // If neither sequence of combinators is a subsequence
    // of the other, they cannot be merged successfully.
    sass::vector<SelectorComponentObj> LCS = lcs<SelectorComponentObj>(combinators1, combinators2);

    if (ListEquality(LCS, combinators1, PtrObjEqualityFn<SelectorComponent>)) {
      result = combinators2;
      return true;
    }
    if (ListEquality(LCS, combinators2, PtrObjEqualityFn<SelectorComponent>)) {
      result = combinators1;
      return true;
    }

    return false;

  }
  // EO mergeInitialCombinators

  // ##########################################################################
  // Extracts trailing [Combinator]s, and the selectors to which they apply,
  // from [components1] and [components2] and merges them together into a
  // single list. If there are no combinators to be merged, returns an
  // empty list. If the sequences can't be merged, returns `null`.
  // ##########################################################################
  bool mergeFinalCombinators(
    sass::vector<SelectorComponentObj>& components1,
    sass::vector<SelectorComponentObj>& components2,
    sass::vector<sass::vector<sass::vector<SelectorComponentObj>>>& result)
  {

    if (components1.empty() || !Cast<SelectorCombinator>(components1.back())) {
      if (components2.empty() || !Cast<SelectorCombinator>(components2.back())) {
        return true;
      }
    }
    
    sass::vector<SelectorComponentObj> combinators1;
    while (!components1.empty() && Cast<SelectorCombinator>(components1.back())) {
      SelectorCombinatorObj back = Cast<SelectorCombinator>(components1.back());
      components1.erase(components1.end() - 1);
      combinators1.push_back(back);
    }

    sass::vector<SelectorComponentObj> combinators2;
    while (!components2.empty() && Cast<SelectorCombinator>(components2.back())) {
      SelectorCombinatorObj back = Cast<SelectorCombinator>(components2.back());
      components2.erase(components2.end() - 1);
      combinators2.push_back(back);
    }

    // reverse now as we used push_back (faster than new alloc)
    std::reverse(combinators1.begin(), combinators1.end());
    std::reverse(combinators2.begin(), combinators2.end());

    if (combinators1.size() > 1 || combinators2.size() > 1) {
      // If there are multiple combinators, something hacky's going on. If one
      // is a supersequence of the other, use that, otherwise give up.
      auto LCS = lcs<SelectorComponentObj>(combinators1, combinators2);
      if (ListEquality(LCS, combinators1, PtrObjEqualityFn<SelectorComponent>)) {
        result.push_back({ combinators2 });
      }
      else if (ListEquality(LCS, combinators2, PtrObjEqualityFn<SelectorComponent>)) {
        result.push_back({ combinators1 });
      }
      else {
        return false;
      }
      return true;
    }

    // This code looks complicated, but it's actually just a bunch of special
    // cases for interactions between different combinators.
    SelectorCombinatorObj combinator1, combinator2;
    if (!combinators1.empty()) combinator1 = combinators1.back();
    if (!combinators2.empty()) combinator2 = combinators2.back();

    if (!combinator1.isNull() && !combinator2.isNull()) {

      CompoundSelector* compound1 = Cast<CompoundSelector>(components1.back());
      CompoundSelector* compound2 = Cast<CompoundSelector>(components2.back());

      components1.pop_back();
      components2.pop_back();

      if (combinator1->isGeneralCombinator() && combinator2->isGeneralCombinator()) {

        if (compound1->isSuperselectorOf(compound2)) {
          result.push_back({ { compound2, combinator2 } });
        }
        else if (compound2->isSuperselectorOf(compound1)) {
          result.push_back({ { compound1, combinator1 } });
        }
        else {
          sass::vector<sass::vector<SelectorComponentObj>> choices;
          choices.push_back({ compound1, combinator1, compound2, combinator2 });
          choices.push_back({ compound2, combinator2, compound1, combinator1 });
          if (CompoundSelector* unified = compound1->unifyWith(compound2)) {
            choices.push_back({ unified, combinator1 });
          }
          result.push_back(choices);
        }
      }
      else if ((combinator1->isGeneralCombinator() && combinator2->isAdjacentCombinator()) ||
        (combinator1->isAdjacentCombinator() && combinator2->isGeneralCombinator())) {

        CompoundSelector* followingSiblingSelector = combinator1->isGeneralCombinator() ? compound1 : compound2;
        CompoundSelector* nextSiblingSelector = combinator1->isGeneralCombinator() ? compound2 : compound1;
        SelectorCombinator* followingSiblingCombinator = combinator1->isGeneralCombinator() ? combinator1 : combinator2;
        SelectorCombinator* nextSiblingCombinator = combinator1->isGeneralCombinator() ? combinator2 : combinator1;

        if (followingSiblingSelector->isSuperselectorOf(nextSiblingSelector)) {
          result.push_back({ { nextSiblingSelector, nextSiblingCombinator } });
        }
        else {
          CompoundSelectorObj unified = compound1->unifyWith(compound2);
          sass::vector<sass::vector<SelectorComponentObj>> items;
          
          if (!unified.isNull()) {
            items.push_back({
              unified, nextSiblingCombinator
            });
          }

          items.insert(items.begin(), {
            followingSiblingSelector,
            followingSiblingCombinator,
            nextSiblingSelector,
            nextSiblingCombinator,
          });

          result.push_back(items);
        }

      }
      else if (combinator1->isChildCombinator() && (combinator2->isAdjacentCombinator() || combinator2->isGeneralCombinator())) {
        result.push_back({ { compound2, combinator2 } });
        components1.push_back(compound1);
        components1.push_back(combinator1);
      }
      else if (combinator2->isChildCombinator() && (combinator1->isAdjacentCombinator() || combinator1->isGeneralCombinator())) {
        result.push_back({ { compound1, combinator1 } });
        components2.push_back(compound2);
        components2.push_back(combinator2);
      }
      else if (*combinator1 == *combinator2) {
        CompoundSelectorObj unified = compound1->unifyWith(compound2);
        if (unified.isNull()) return false;
        result.push_back({ { unified, combinator1 } });
      }
      else {
        return false;
      }

      return mergeFinalCombinators(components1, components2, result);

    }
    else if (!combinator1.isNull()) {

      if (combinator1->isChildCombinator() && !components2.empty()) {
        const CompoundSelector* back1 = Cast<CompoundSelector>(components1.back());
        const CompoundSelector* back2 = Cast<CompoundSelector>(components2.back());
        if (back1 && back2 && back2->isSuperselectorOf(back1)) {
          components2.pop_back();
        }
      }

      result.push_back({ { components1.back(), combinator1 } });

      components1.pop_back();

      return mergeFinalCombinators(components1, components2, result);

    }

    if (combinator2->isChildCombinator() && !components1.empty()) {
      const CompoundSelector* back1 = Cast<CompoundSelector>(components1.back());
      const CompoundSelector* back2 = Cast<CompoundSelector>(components2.back());
      if (back1 && back2 && back1->isSuperselectorOf(back2)) {
        components1.pop_back();
      }
    }

    result.push_back({ { components2.back(), combinator2 } });

    components2.pop_back();

    return mergeFinalCombinators(components1, components2, result);

  }
  // EO mergeFinalCombinators

  // ##########################################################################
  // Expands "parenthesized selectors" in [complexes]. That is, if
  // we have `.A .B {@extend .C}` and `.D .C {...}`, this conceptually
  // expands into `.D .C, .D (.A .B)`, and this function translates
  // `.D (.A .B)` into `.D .A .B, .A .D .B`. For thoroughness, `.A.D .B`
  // would also be required, but including merged selectors results in
  // exponential output for very little gain. The selector `.D (.A .B)`
  // is represented as the list `[[.D], [.A, .B]]`.
  // ##########################################################################
  sass::vector<sass::vector<SelectorComponentObj>> weave(
    const sass::vector<sass::vector<SelectorComponentObj>>& complexes) {

    sass::vector<sass::vector<SelectorComponentObj>> prefixes;

    prefixes.push_back(complexes.at(0));

    for (size_t i = 1; i < complexes.size(); i += 1) {

      if (complexes[i].empty()) {
        continue;
      }
      const sass::vector<SelectorComponentObj>& complex = complexes[i];
      SelectorComponent* target = complex.back();
      if (complex.size() == 1) {
        for (auto& prefix : prefixes) {
          prefix.push_back(target);
        }
        continue;
      }

      sass::vector<SelectorComponentObj> parents(complex);

      parents.pop_back();

      sass::vector<sass::vector<SelectorComponentObj>> newPrefixes;
      for (sass::vector<SelectorComponentObj> prefix : prefixes) {
        sass::vector<sass::vector<SelectorComponentObj>>
          parentPrefixes = weaveParents(prefix, parents);
        if (parentPrefixes.empty()) continue;
        for (auto& parentPrefix : parentPrefixes) {
          parentPrefix.push_back(target);
          newPrefixes.push_back(parentPrefix);
        }
      }
      prefixes = newPrefixes;

    }
    return prefixes;

  }
  // EO weave

  // ##########################################################################
  // Interweaves [parents1] and [parents2] as parents of the same target
  // selector. Returns all possible orderings of the selectors in the
  // inputs (including using unification) that maintain the relative
  // ordering of the input. For example, given `.foo .bar` and `.baz .bang`,
  // this would return `.foo .bar .baz .bang`, `.foo .bar.baz .bang`,
  // `.foo .baz .bar .bang`, `.foo .baz .bar.bang`, `.foo .baz .bang .bar`,
  // and so on until `.baz .bang .foo .bar`. Semantically, for selectors A
  // and B, this returns all selectors `AB_i` such that the union over all i
  // of elements matched by `AB_i X` is identical to the intersection of all
  // elements matched by `A X` and all elements matched by `B X`. Some `AB_i`
  // are elided to reduce the size of the output.
  // ##########################################################################
  sass::vector<sass::vector<SelectorComponentObj>> weaveParents(
    sass::vector<SelectorComponentObj> queue1,
    sass::vector<SelectorComponentObj> queue2)
  {

    sass::vector<SelectorComponentObj> leads;
    sass::vector<sass::vector<sass::vector<SelectorComponentObj>>> trails;
    if (!mergeInitialCombinators(queue1, queue2, leads)) return {};
    if (!mergeFinalCombinators(queue1, queue2, trails)) return {};
    // list comes out in reverse order for performance
    std::reverse(trails.begin(), trails.end());

    // Make sure there's at most one `:root` in the output.
    // Note: does not yet do anything in libsass (no root selector)
    CompoundSelectorObj root1 = getFirstIfRoot(queue1);
    CompoundSelectorObj root2 = getFirstIfRoot(queue2);

    if (!root1.isNull() && !root2.isNull()) {
      CompoundSelectorObj root = root1->unifyWith(root2);
      if (root.isNull()) return {}; // null
      queue1.insert(queue1.begin(), root);
      queue2.insert(queue2.begin(), root);
    }
    else if (!root1.isNull()) {
      queue2.insert(queue2.begin(), root1);
    }
    else if (!root2.isNull()) {
      queue1.insert(queue1.begin(), root2);
    }

    // group into sub-lists so no sub-list contains two adjacent ComplexSelectors.
    sass::vector<sass::vector<SelectorComponentObj>> groups1 = groupSelectors(queue1);
    sass::vector<sass::vector<SelectorComponentObj>> groups2 = groupSelectors(queue2);

    // The main array to store our choices that will be permutated
    sass::vector<sass::vector<sass::vector<SelectorComponentObj>>> choices;

    // append initial combinators
    choices.push_back({ leads });

    sass::vector<sass::vector<SelectorComponentObj>> LCS =
      lcs<sass::vector<SelectorComponentObj>>(groups1, groups2, cmpGroups);

    for (auto group : LCS) {

      // Create junks from groups1 and groups2
      sass::vector<sass::vector<sass::vector<SelectorComponentObj>>>
        chunks = getChunks<sass::vector<SelectorComponentObj>>(
          groups1, groups2, group, cmpChunkForParentSuperselector);

      // Create expanded array by flattening chunks2 inner
      sass::vector<sass::vector<SelectorComponentObj>>
        expanded = flattenInner(chunks);

      // Prepare data structures
      choices.push_back(expanded);
      choices.push_back({ group });
      if (!groups1.empty()) {
        groups1.erase(groups1.begin());
      }
      if (!groups2.empty()) {
        groups2.erase(groups2.begin());
      }

    }

    // Create junks from groups1 and groups2
    sass::vector<sass::vector<sass::vector<SelectorComponentObj>>>
      chunks = getChunks<sass::vector<SelectorComponentObj>>(
        groups1, groups2, {}, cmpChunkForEmptySequence);

    // Append chunks with inner arrays flattened
    choices.emplace_back(flattenInner(chunks));

    // append all trailing selectors to choices
    std::move(std::begin(trails), std::end(trails),
      std::inserter(choices, std::end(choices)));

    // move all non empty items to the front, then erase the trailing ones
    choices.erase(std::remove_if(choices.begin(), choices.end(), checkForEmptyChild
      <sass::vector<sass::vector<SelectorComponentObj>>>), choices.end());

    // permutate all possible paths through selectors
    sass::vector<sass::vector<SelectorComponentObj>>
      results = flattenInner(permutate(choices));

    return results;

  }
  // EO weaveParents

  // ##########################################################################
  // ##########################################################################

}
