// Various functions useful for working with Dirichlet characters, their Galois orbits, and Conrey labels

intrinsic Parity (chi::GrpDrchElt) -> RngIntElt
{ The value of the character on -1. }
    return Integers()!Evaluate(chi,-1);
end intrinsic;

intrinsic IsReal (chi::GrpDrchElt) -> Bool
{ Whether the character takes only real values (trivial or quadratic) or not. }
    return Order(chi) le 2;
end intrinsic;

intrinsic Degree (chi::GrpDrchElt) -> RngIntElt
{ The degree of the number field Q(chi). }
    return EulerPhi(Order(chi));
end intrinsic;

intrinsic UnitGenerators (chi::GrpDrchElt) -> SeqEnum[RngIntElt]
{ Lift to Z of standard generators for (Z/NZ)* where N is the modulus of chi. }
    return UnitGenerators(Parent(chi));
end intrinsic;

intrinsic NumberOfCharacterOrbits (N::RngIntElt) -> RngIntElt
{ The number of Galois orbits of Dirichlet characters of modulus N. }
    require N gt 0: "Modulus N must be a positive integer";
    // this could be made faster but it is already pretty fast for N up to 10^5
    return Integers()! &+[1/EulerPhi(Order(g)):g in MultiplicativeGroup(Integers(N))];
end intrinsic;

intrinsic IsConjugate (chi1::GrpDrchElt,chi2::GrpDrchElt) -> Boolean
{ Returns true if chi1 and chi2 are Galois conjugate Dirichlet characters with the same codomain. }
    e := Order(chi1);
    if Order(chi2) ne e then return false; end if;
    chi1 := MinimalBaseRingCharacter(chi1);  chi2 := MinimalBaseRingCharacter(chi2);
    v1 := ValuesOnUnitGenerators(chi1);  v2 := ValuesOnUnitGenerators(chi2);
    if [OrderOfRootOfUnity(a,e):a in v1] ne [OrderOfRootOfUnity(a,e): a in v2] then return false; end if;
    return #Set(GaloisConjugacyRepresentatives([chi1,Parent(chi1)!chi2])) eq 1 select true else false;
end intrinsic;


intrinsic CompareCharacters (chi1::GrpDrchElt,chi2::GrpDrchElt) -> RngIntElt
{ Compare Dirichlet characters based on order and lexicographic ordering of traces. }
    N := Modulus(chi1);  assert Modulus(chi2) eq N;
    n1 := Order(chi1); n2 := Order(chi2);
    if n1 ne n2 then return n1-n2; end if;
    // this will be very slow when the characters are actually conjugate, try to avoid this use case
    for a:=2 to N-1 do
        if GCD(a,N) ne 1 then continue; end if;
        t1 := Trace(chi1(a));  t2 := Trace(chi2(a));
        if t1 ne t2 then return t1-t2; end if;
    end for;
    return 0;
end intrinsic;

intrinsic CharacterOrbitReps(N::RngIntElt:RepTable:=false) -> List, Assoc
{ The list of Galois orbit representatives of the full Dirichlet group of modulus N with minimal codomains sorted by order and trace vectors.
  If the optional boolean argument RepTable is set then a table mapping Dirichlet characters to indexes in this list is also returned. }
    require N gt 0: "Modulus N must be a positive integer";
    G := [* MinimalBaseRingCharacter(chi): chi in GaloisConjugacyRepresentatives(FullDirichletGroup(N)) *];
    X := [i:i in [1..#G]];
    X := Sort(X,func<i,j|CompareCharacters(G[i],G[j])>);
    G := [* G[i] : i in X *];
    if not RepTable then return G; end if;
    A := AssociativeArray();
    for i:=1 to #G do v:=[OrderOfRootOfUnity(a,Order(G[i])):a in ValuesOnUnitGenerators(G[i])]; if IsDefined(A,v) then Append(~A[v],i); else A[v]:=[i]; end if; end for;
    H := Elements(FullDirichletGroup(N));
    T := AssociativeArray(Parent(H[1]));
    for h in H do
        v := [OrderOfRootOfUnity(a,Order(h)):a in ValuesOnUnitGenerators(h)];
        m := A[v];
        if #m eq 1 then
            T[h] := m[1];
        else
            for i in m do if IsConjugate(h,G[i]) then T[h]:=i; break; end if; end for;
        end if;
    end for;
    return G, T;
end intrinsic;

intrinsic CharacterOrbit(chi::GrpDrchElt) -> RngIntElt
{ The index of the orbit of the specified Dirichlet character in the list of orbit representatives returned by CharacterOrbitReps (this can also be determined using the RepTable parameter). }
    G := CharacterOrbitReps(Modulus(chi));
    m := Order(chi); v := [Trace(z):z in ValueList(MinimalBaseRingCharacter(chi))];
    M := [i : i in [1..#G] | Order(G[i]) eq m and [Trace(z):z in ValueList(G[i])] eq v];
    assert #M eq 1;
    return M[1];
end intrinsic;
    
intrinsic ConreyCharacterValue(q::RngIntElt,n::RngIntElt,m::RngIntElt) -> FldCycElt
{ The value chi_q(n,m) of the Dirichlet character with Conry label q.n at the integer m. }
    require q gt 0: "Modulus q must be positive";
    require GCD(q,n) eq 1: "Parameter n must be coprime to modulus q";
    if q eq 1 then return 1; end if;
    if GCD(q,m) ne 1 then return 0; end if;
    if n mod q eq 1 or m mod q eq 1 then return 1; end if;
    b,p,e:= IsPrimePower(q);
    if not b then return &*[$$(a[1]^a[2],n,m):a in Factorization(q)]; end if;
    R := Integers(q);
    k := EulerPhi(q);
    if p gt 2 then
        r := R!PrimitiveRoot(p);
        A := AssociativeArray();
        for i in [1..k] do A[r^i]:=i; end for;
        a := A[R!n]; b:=A[R!m];
        return RootOfUnity(k)^(a*b);
    else
        if e eq 2 then return -1; end if;   // must have n=m=3 since all other cases handled above
        assert e gt 2;
        r := R!5;
        A := AssociativeArray();
        for s in [1,-1], i in [1..k] do A[s*r^i]:=<s,i>; end for;
        a := A[R!n]; b:=A[R!m];
        return RootOfUnity(8)^((1-a[1])*(1-b[1])) * RootOfUnity(2^(e-2))^(a[2]*b[2]);
    end if;
end intrinsic;

intrinsic ConreyCharacterValues(q::RngIntElt,n::RngIntElt,S::SeqEnum) -> SeqEnum[FldCycElt]
{ The list of values of the Dirichlet character with Conrey label q.n on the integers in S. }
    require q gt 0: "Modulus q must be positive";
    require GCD(q,n) eq 1: "Parameter n must be coprime to modulus q";
    if q eq 1 then return [1:i in S]; end if;
    if n mod q eq 1 then return [GCD(i,q) eq 1 select 1 else 0 : i in S]; end if;
    b,p,e:= IsPrimePower(q);
    if not b then 
        X := [$$(a[1]^a[2],n,S):a in Factorization(q)];
        return [&*[X[i][j]:i in [1..#X]] : j in [1..#S]];
    end if;
    R := Integers(q);
    k := EulerPhi(q);
    if p gt 2 then
        r := R!PrimitiveRoot(p);
        A := AssociativeArray();
        for i in [1..k] do A[r^i]:=i; end for;
        a := A[R!n];
        return [GCD(p,m) eq 1 select RootOfUnity(k)^(a*A[R!m]) else 0 : m in S];
    else
        if e eq 2 then return [IsOdd(m) select (-1)^ExactQuotient(m-1,2) else 0 : m in S]; end if;
        assert e gt 2;
        r := R!5;
        A := AssociativeArray();
        for s in [1,-1], i in [1..k] do A[s*r^i]:=<s,i>; end for;
        a := A[R!n];
        return [GCD(p,m) eq 1 select RootOfUnity(8)^((1-a[1])*(1-b[1])) * RootOfUnity(2^(e-2))^(a[2]*b[2]) where b:=A[R!m] else 0 : m in S];
    end if;
end intrinsic;

intrinsic ConreyCharacterValues(q::RngIntElt,n::RngIntElt,M::RngIntElt) -> SeqEnum[FldCycElt]
{ The list of values of the Dirichlet character with Conrey label q.n on the integers 1..M. }
    return ConreyCharacterValues(q,n,[1..M]);
end intrinsic;

function normalize_angle(r)
    b:=Denominator(r); a:=Numerator(r) mod b;
    return a eq 0 select 1 else a/b;
end function;

intrinsic ConreyCharacterAngle(q::RngIntElt,n::RngIntElt,m::RngIntElt) -> FldRatElt
{ The rational number r such that chi_q(n,m) = e(r) or 0 (returns 1 for 1 not 0). }
    require q gt 0: "Modulus q must be positive";
    require GCD(q,n) eq 1: "Parameter n must be coprime to modulus q";
    if q eq 1 then return 1; end if;
    if GCD(q,m) ne 1 then return 0; end if;
    if n mod q eq 1 or m mod q eq 1 then return 1; end if;
    b,p,e:= IsPrimePower(q);
    if not b then return normalize_angle(&+[$$(a[1]^a[2],n,m):a in Factorization(q)]); end if;
    R := Integers(q);
    k := EulerPhi(q);
    if p gt 2 then
        r := R!PrimitiveRoot(p);
        A := AssociativeArray();
        for i in [1..k] do A[r^i]:=i; end for;
        a := A[R!n]; b:=A[R!m];
        return normalize_angle((a*b) / k);
    else
        if e eq 2 then return 1/2; end if;   // must have n=m=3 since all other cases handled above
        assert e gt 2;
        r := R!5;
        A := AssociativeArray();
        for s in [1,-1], i in [1..k] do A[s*r^i]:=<s,i>; end for;
        a := A[R!n]; b:=A[R!m];
        return normalize_angle(((1-a[1])*(1-b[1])) / 8 + (a[2]*b[2]) / 2^(e-2));
    end if;
end intrinsic;

intrinsic ConreyCharacterComplexValue(q::RngIntElt,n::RngIntElt,m::RngIntElt,CC::FldCom) -> FldComElt
{ Value of chi_q(m,n) in specified complex field. }
    return Exp(2*Pi(CC)*CC.1*ConreyCharacterAngle(q,n,m));
end intrinsic;

intrinsic ConreyCharacterAngles(q::RngIntElt,n::RngIntElt,S::SeqEnum) -> SeqEnum[FldCycElt]
{ The list of values of the Dirichlet character with Conrey label q.n on the integers in S. }
    require q gt 0: "Modulus q must be positive";
    require GCD(q,n) eq 1: "Parameter n must be coprime to modulus q";
    if q eq 1 then return [1:i in S]; end if;
    if GCD(q,n) ne 1 then return [0:i in S]; end if;
    if n mod q eq 1 then return [GCD(i,q) eq 1 select 1 else 0 : i in S]; end if;
    b,p,e:= IsPrimePower(q);
    if not b then 
        X := [$$(a[1]^a[2],n,S):a in Factorization(q)];
        return [GCD(S[j],q) eq 1 select normalize_angle(&+[X[i][j]:i in [1..#X]]) else 0 : j in [1..#S]];
    end if;
    R := Integers(q);
    k := EulerPhi(q);
    if p gt 2 then
        r := R!PrimitiveRoot(p);
        A := AssociativeArray();
        for i in [1..k] do A[r^i]:=i; end for;
        a := A[R!n];
        return [GCD(m,p) eq 1 select normalize_angle((a*A[R!m])/k) else 0 : m in S];
    else
        if e eq 2 then return [IsOdd(m) select (IsEven(ExactQuotient(m-1,2)) select 1 else 1/2) else 0 : m in S]; end if;
        assert e gt 2;
        r := R!5;
        A := AssociativeArray();
        for s in [1,-1], i in [1..k] do A[s*r^i]:=<s,i>; end for;
        a := A[R!n];
        return [GCD(m,p) eq 1 select normalize_angle(((1-a[1])*(1-b[1])) / 8 + (a[2]*b[2]) / 2^(e-2)) where b:=A[R!m] else 0 : m in S];
    end if;
end intrinsic;

intrinsic ConreyCharacterComplexValues(q::RngIntElt,n::RngIntElt,S::RngIntElt,CC::FldCom) -> SeqEnum[FldComElt]
{ List of values of chi_q(n,m) for m in S in specified complex field. }
    return [Exp(2*Pi(CC)*CC.1*t): t in ConreyCharacterAngles(q,n,S)];
end intrinsic;
    
intrinsic ConreyCharacterAngles(q::RngIntElt,n::RngIntElt,M::RngIntElt) -> SeqEnum[FldCycElt]
{ The list of values of the Dirichlet character with Conrey label q.n on the integers 1..M. }
    return ConreyCharacterAngles(q,n,[1..M]);
end intrinsic;

intrinsic ConreyCharacter(q::RngIntElt,n::RngIntElt) -> GrpDrchElt
{ The Dirichlet character with Conrey label q.n. }
    require q gt 0: "Modulus q must be positive";
    require GCD(q,n) eq 1: "Parameter n must be coprime to modulus q";
    G,pi := MultiplicativeGroup(Integers(q));  psi := Inverse(pi);  S := Generators(G);
    m := Order(psi(n));  F := CyclotomicField(m);
    H := Elements(DirichletGroup(q,F));
    v := [F!ConreyCharacterValue(q,n,Integers()!pi(g)):g in S];
    M := [chi: chi in H | Order(chi) eq m and [Evaluate(chi,pi(g)):g in S] eq v];
    assert #M eq 1;
    return M[1];
end intrinsic;

intrinsic ConreyTraces(q::RngIntElt,n::RngIntElt) -> SeqEnum[RngIntElt]
{ The list of traces of values of the Dirichlet character with Conrey label q.n on the integers 1,2,...q. }
    require q gt 0: "Modulus q must be positive";
    require GCD(q,n) eq 1: "Parameter n must be coprime to modulus q";
    G,pi := MultiplicativeGroup(Integers(q));
    F := CyclotomicField(Order(Inverse(pi)(Integers(q)!n)));
    return [Trace(F!z):z in ConreyCharacterValues(q,n,q)];
end intrinsic;

intrinsic ConreyLabel(chi::GrpDrchElt) -> RngIntElt, RngIntElt
{ The integer n such that q.n is the Conrey label of the specified Dirichlet character of modulus q. }
    q := Modulus(chi);  m := Order(chi);
    G,pi := MultiplicativeGroup(Integers(q));  psi:=Inverse(pi);  S := Generators(G);
    F := CyclotomicField(m);
    v := [F!Evaluate(chi,pi(g)):g in S];
    M := [n : n in [1..q] | GCD(n,q) eq 1 and Order(psi(n)) eq m and [F!ConreyCharacterValue(q,n,Integers()!pi(g)):g in S] eq v];
    assert #M eq 1;
    return M[1];
end intrinsic;

intrinsic ConreyLabels (chi::GrpDrchElt) -> SeqEnum[RngIntElt]
{ The sorted list of integers n giving the Conrey labels q.n of all Galois conjugates of the specified Dirichlet character of modulus q. }
    q := Modulus(chi);  m := Order(chi);
    _,pi := MultiplicativeGroup(Integers(q));  psi:=Inverse(pi);
    v := [Trace(z) : z in ValueList(MinimalBaseRingCharacter(chi))];
    M := [n : n in [1..q] | GCD(n,q) eq 1 and Order(psi(n)) eq m and ConreyTraces(q,n) eq v];
    assert #M gt 0;
    return M;
end intrinsic;

intrinsic MinimalConreyLabel (chi::GrpDrchElt) -> RngIntElt
{ The least positive integer n such that q.n is the Conrey label of the specified Dirichlet character of modulus q. }
    return Min(ConreyLabels(chi));
end intrinsic;

intrinsic ConreyCharacterOrbitIndex (q::RngIntElt,n::RngIntElt) -> RngIntElt
{ The index of representative of the Galois orbit of the Conrey character q.n in the list returned by CharacterOrbitReps(q). }
    require q gt 0: "Modulus q must be positive";
    require GCD(q,n) eq 1: "Parameter n must be coprime to modulus q";
    _,pi := MultiplicativeGroup(Integers(q)); m := Order(Inverse(pi)(n));
    G := CharacterOrbitReps(q);
    v := ConreyTraces(q,n);
    M := [i:i in [1..#G] | Order(G[i]) eq m and v eq [Trace(z):z in ValueList(G[i])]];
    assert #M eq 1;
    return M[1];
end intrinsic;

// Given an nth-root of unity in a number field K return angles of conjugates (in standard order of embeddings of K)
// This is a really stupid way to do this...
function ConjugateAngles(z,n)
    C := Conjugates(z);
    CC := Parent(z[1]);
    pi := Pi(RealField());
    return [ normalize_angle(Round(n*Argument(c)/(2*pi))/n) : c in C];
end function;

intrinsic ConreyConjugates (chi::GrpDrchElt, xi::Map: ConreyLabelList:=ConreyLabels(chi)) -> SeqEnum[RngIntElt]
{ Given a Dirichlet character chi embedded as xi with values in a number field K, returns a list of the Conrey labels corresponding to the embeddings of K in C, as ordered by Conjugates. }
    if #ConreyLabelList eq 1 then return [ConreyLabelList[1]:i in [1..Degree(Codomain(xi))]]; end if;
    q := Modulus(chi);  e := Order(chi);
    S := UnitGenerators(chi);
    T := AssociativeArray();
    for n in ConreyLabelList do T[ConreyCharacterAngles(q,n,S)] := n; end for;
    A := [ConjugateAngles(xi(m),e) : m in S];
    return [T[[A[i][j] : i in [1..#S]]] : j in [1..#A[1]]];
end intrinsic;

intrinsic CharacterFromValues (N::RngIntElt,u::SeqEnum,v::SeqEnum:Orbit:=false) -> Map
{ Given a modulus N, a list of generators of (Z/NZ)*, and a corresponding list of roots of unity in a number/cyclotomic field K, returns a map ZZ -> K for the Dirichlet character. }
    require N gt 0: "Modulus must be a positive integer";
    require #u eq #v: "List of unit generators and values must be lists of the same length";
    K := Universe(v);
    if N le 2 then psi:=map< Integers()->K | x :-> GCD(N,x) eq 1 select 1 else 0 >; if Orbit then return psi,1; else return psi; end if; end if;
    A,pi := UnitGroup(Integers(N)); ipi:=Inverse(pi);
    u0 := [pi(A.i):i in [1..NumberOfGenerators(A)]];
    if u ne u0 then error Sprintf("Specified generators %o do not match standard generators %o, conversion not implmented.", u, u0); end if;
    psi := map< Integers()->K | x :-> GCD(N,x) eq 1 select &*[v[i]^(Eltseq(ipi(x))[i]):i in [1..#v]] else K!0>;
    if not Orbit then return psi; end if;
    // if Orbit flag is set, determine the character orbit by comparing traces (note that we need tot take traces from the subfield of K generated by the image of psi)
    m := LCM([Min([d:d in Divisors(EulerPhi(N))|z^d eq 1]):z in v]);
    d := EulerPhi(m); e := ExactQuotient(Degree(K),d);
    t := [ExactQuotient(Trace(psi(n)),e) : n in [1..N]];
    G := CharacterOrbitReps(N);
    M := [i : i in [1..#G] | Order(G[i]) eq m and [Trace(z):z in ValueList(G[i])] eq t];
    assert #M eq 1;
    return psi,M[1];
end intrinsic;

intrinsic Order (xi::Map, N::RngIntElt) -> RngIntElt
{ Given a map ZZ -> K that is a Dirichlet character of modulus N, returns its order. }
    e := Exponent(MultiplicativeGroup(Integers(N)));
    U := UnitGenerators(DirichletGroup(N));
    return LCM([Min([d: d in Divisors(e)|a^d eq 1]) where a:=xi(u) : u in U]);
end intrinsic;

intrinsic Conductor (xi::Map, N::RngIntElt) -> RngIntElt
{ Given a map ZZ -> K that is a Dirichlet character of modulus N, returns its conductor. }
    U := UnitGenerators(DirichletGroup(N));
    M := Min([M : M in Divisors(N) | &and[xi(u) eq xi(u mod M):u in U]]);
    return M;
end intrinsic;

intrinsic Degree (xi::Map, N::RngIntElt) -> RngIntElt
{ Given a map ZZ -> K that is a Dirichlet character of modulus N, returns the degree of the (cyclotomic) subfield of K generated by its image. }
    return Degree(sub<Codomain(xi) | [xi(u) : u in UnitGenerators(DirichletGroup(N))]>);
end intrinsic;

intrinsic Parity (xi::Map) -> RngIntElt
{ Given a map ZZ -> K that is a Dirichlet character, returns its parity xi(-1). }
    return Integers()!xi(-1);
end intrinsic;

intrinsic IsReal (xi::Map, N::RngIntElt) -> Bool
{ Given a map ZZ -> K that is a Dirichlet character, returns a boolean indicating whether the character takes only real values (trivial or quadratic) or not. }
    return Order(xi,N) le 2;
end intrinsic;





