#| Remove the last element satisfying the predicate, if any. Without any predicate, the last element is thrown.
#`{
    # Without an argument, it's like *.head(*-1)
    >>> [1, 2, 3, 0, 4, 5].&remove-last
    (1, 2, 3, 0, 4).Seq

    # Remove the last zero (and only that zero)
    >>> (4, 0, 5, 2, 0, 0).&remove-last(* == 0)
    (4, 0, 5, 2, 0).Seq

    # If nothing to remove, yield back as is
    >>> remove-last * %% 2, [1, 3, 5, 7]
    (1, 3, 5, 7).Seq

    # String invocants as well as regex predicates are accepted as well
    >>> "This is important. Right? Yes!".&remove-last(/ <punct> /)
    "This is important. Right? Yes"
}
unit module Remove-Last;

use Iter::Able::Remove-First;

# Implemented in terms of `&remove-first`
our proto remove-last(\ist, &pred?) is export {
    # When no predicate is supplied, remove 0th
    without &pred {
        given ist {
            when Iterable:D { return ist.head(*-1) }
            when Str:D      { return ist ?? ist.substr(0, *-1) !! "" }
        }
    }
    {*}
}

multi remove-last(Iterable:D \it, &pred? --> Seq:D) {
    reverse remove-first it.reverse, (&pred ~~ Regex ?? (* ~~ &pred).so !! &pred)
}

multi remove-last(Iterator:D \it, &pred? --> Iterator:D) {
    it.push-all(my @tmp);
    (reverse Seq.new: remove-first @tmp.reverse.iterator, (&pred ~~ Regex ?? (* ~~ &pred).so !! &pred)).iterator
        but role { method Seq { Seq.new(self) } }
}

multi remove-last(Str:D \st, &pred? --> Str:D) {
    join "", reverse remove-first st.comb.reverse, (&pred ~~ Regex ?? (* ~~ &pred).so !! &pred)
}
