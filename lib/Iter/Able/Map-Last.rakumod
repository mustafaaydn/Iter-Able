#| Maps only the last item that satisfies the predicate, if any.
#`{
    # Last negative to positive
    >>> map-last [2, -3, 4, -6, 8], * < 0, -*
    (2, -3, 4, 6, 8).Seq

    # Can use with all-pass filter to change the last element :)
    >>> map-last [3, 4, 7, NaN], { True }, { -1 }
    (3, 4, 7, -1).Seq

    # Last lowercase to uppercase
    >>> "here we are!".&map-last(/ <.lower> /, &uc)
    "here we arE!"

    # If no one matches, everyone is yielded as is
    >>> [57, 91, -13].&map-last(*.is-prime, { 0 });
    (57, 91, -13).Seq
}
unit module Map-Last;

use Iter::Able::Map-First;

# Implemented in terms of `map-first`
our proto map-last(\ist, &pred, &mapper) is export {*}

multi map-last(Iterable:D \it, &pred, &mapper --> Seq:D) {
    reverse map-first it.reverse, (&pred ~~ Regex ?? (* ~~ &pred).so !! &pred), &mapper
}

multi map-last(Iterator:D \it, &pred, &mapper --> Iterator:D) {
    it.push-all(my @tmp);
    (reverse Seq.new: map-first @tmp.reverse.iterator, (&pred ~~ Regex ?? (* ~~ &pred).so !! &pred), &mapper).iterator but role { method Seq { Seq.new(self) } }
}

multi map-last(Str:D \st, &pred, &mapper --> Str:D) {
    join "", reverse map-first st.comb.reverse, (&pred ~~ Regex ?? (* ~~ &pred).so !! &pred), &mapper
}
