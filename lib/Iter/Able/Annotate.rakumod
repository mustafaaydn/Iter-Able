#| Generates =(x, f(x))= lists. By default, =f(x) = x=. Returns a Seq
#| for strings.
#`{ # Mirrors the items by default
    >>> [-4, 3, 0].&annotate
    ((-4, -4), (3, 3), (0, 0))

    # Let items carry their length with them
    >>> ("piano", "drum", "violin").&annotate(&chars)
    (("piano", 5), ("drum", 4), ("violin", 6))

    # Originals and matches
    >>> ["this and that", "yes and no", "real"].&annotate(/ .? <before ' and'>/)
    (("this and that", ｢this｣), ("yes and no", ｢yes｣), ("real", Nil))

    # is-upper decoration
    >>> annotate "reAL", {$_ eq .uc}  # or `so * ~~ / <.upper> /`
    (("r", False), ("e", False), ("A", True), ("L", True))
}
unit module Annotate;

use nqp;
my class Annotate does Iterator {
    has Mu $!iter;  #= Passed iterator
    has &!mapper;   #= Transformer

    method !SET-SELF($!iter, &!mapper) { self }

    method new(\iterator, \mapper) {
        nqp::create(self)!SET-SELF(iterator, mapper)
    }

    method pull-one {
        nqp::if(
            # Is the iterable exhausted?
            nqp::eqaddr((my $next := $!iter.pull-one), IterationEnd),
            # Yes; signal
            IterationEnd,
            # No; ...
            ($next, &!mapper($next))
        )
    }

    method is-lazy() { $!iter.is-lazy }
}

our proto annotate(\ist, &mapper = {$_}) is export {*}

multi annotate(Iterable \it, &mapper = {$_}) {
    Seq.new: Annotate.new: it.iterator, (&mapper ~~ Regex ?? (* ~~ &mapper) !! &mapper)
}

multi annotate(Iterator \it, &mapper = {$_}) {
    Seq.new: Annotate.new: it, (&mapper ~~ Regex ?? (* ~~ &mapper) !! &mapper)
}

multi annotate(Str \st, &mapper = {$_}) {
    Seq.new: Annotate.new: st.comb.iterator, (&mapper ~~ Regex ?? (* ~~ &mapper) !! &mapper)
}
