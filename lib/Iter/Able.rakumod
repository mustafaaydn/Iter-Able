sub EXPORT(*@things) {
    # If thing(s) were passed, selectively export them and die if an unknown
    # symbol is requested. If `*` is passed, export all. If nothing is passed,
    # export nothing; user needs to use the semi-FQNs.
    return Map.new unless @things;
    OUTER::Iter::Able::
        .values
        .map({"\&{.name}" => $_})
        .cache
    andthen
        (@things eqv [ * ] | ["*"])
        ?? $_
        !! (my \d = (@things (-) $_>>.key>>.substr(1)).keys.sort.list)
            ?? die "Can't import {d == 1 ?? d.head.raku !! d.raku} from Iter::Able"
            !! .grep({.value.name (elem) @things})
    andthen
        .Map
}

#| Entry point, gatherer package.
unit package Iter::Able;

# Following might be automatically generated at some point...
use Iter::Able::Group-Conseq;
use Iter::Able::Take-While;
use Iter::Able::Skip-While;

# Subscribe all the subs to the package as well in case one wants to refer
# to them with their semi-FQNs, e.g., `Iter::Able::take-while(...)`, e.g., to
# prevent naming collisions or such.
OUR::{.key} = .value for MY::.grep(*.key.starts-with('&'));
