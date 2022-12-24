#| Map only the last item matching the predicate, if any.
#`{
    # Last negative to positive
    >>> map-last [2, -3, 4, -6, 8], * < 0, -*
    (2, -3, 4, 6, 8)

    # Can use with all-pass filter to change the last element :)
    >>> map-last [3, 4, 7, NaN], { True }, { -1 }
    (3, 4, 7, -1)

    # Last lowercase to uppercase
    >>> "here we are!".&map-last(/ <.lower> /, &uc)
    "here we arE!"

    # If noone matches, everyone is yielded as is
    >>> [57, 91, -13].&map-last(*.is-prime, { 0 });
    (57, 91, -13)
}
unit module Map-Last;

use Iter::Able::Map-First;

# implemented in terms of `map-first`
our proto map-last(\ist, &pred, &mapper) is export {*}

multi map-last(Iterable \it, &pred, &mapper) {
    reverse map-first it.reverse.iterator, (&pred ~~ Regex ?? (* ~~ &pred).so !! &pred), &mapper
}

multi map-last(Iterator \it, &pred, &mapper) {
    it.push-all(my @tmp);
    reverse map-first @tmp.reverse.iterator, (&pred ~~ Regex ?? (* ~~ &pred).so !! &pred), &mapper
}

multi map-last(Str \st, &pred, &mapper) {
    join "", reverse map-first st.comb.reverse, (&pred ~~ Regex ?? (* ~~ &pred).so !! &pred), &mapper
}
