#| Check if some of the elements (any, at least one) satisfy the given predicate.
#| It has a short-circuiting behaviour, i.e., if a satisfactory element is found, traversal immediately stops.
#| `any` would be a better name but it's taken.
#`{
    # Any positive elements?
    >>> [-4, 0, 5, 2, -8].&some(* > 0)
    True

    # Any primes?
    >>> some &is-prime, [1, -1, 0]
    False

    # Default predicate is truthfulness
    >>> some (Any, 0, [], "")
    False

    # Stops once it finds a matching element
    >>> some (4, |(5 xx *)), * == 4
    True

    # Empty input yields False regardless of the predicate
    >>> some []
    False

    # Strings are also accepted as inputs
    >>> "thereisnospacehere".&some(/ \s /)
    False
}
unit module Some;

our proto some(\ist, &pred = {$_} --> Bool:D) is export {*}

multi some(Iterable:D \it, &pred = {$_} --> Bool:D) { it.grep(&pred).so }

multi some(Iterator:D \it, &pred = {$_} --> Bool:D) { Seq.new(it).grep(&pred).so }

multi some(Str:D \st, &pred = {$_} --> Bool:D) { st.comb.grep(&pred).so }
