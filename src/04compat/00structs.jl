struct Wrapped_Equalise_Obj{F}
	f::F
end

function (w::Wrapped_Equalise_Obj)(obj1, obj2, l, r)
	obj1 = addfcall(obj1, 2)
	z = w.f((obj1.ℒ, obj2.ℒ), l, r)
	(!isa(z, Number) || isnan(z)) && error("zero_D_j_obj now must return a number")
	return z, obj1
end

struct Wrapped_Zero_D_j_Obj{F}
	f::F
	J::Vector{Bool}
end

function (w::Wrapped_Zero_D_j_Obj)(obj, i, zleft, zright)
	copyto!(w.J, obj.ℒ)
	z = w.f(i, w.J, zleft, zright)
	obj = addfcall(obj, 1)
	(!isa(z, Number) || isnan(z)) && error("zero_D_j_obj now must return a number")
	return z, obj
end

struct Interval{T <: AbstractVector{Bool}, N <: Real}
	sub::T
	sup::T
	aux::T
	l::N
	r::N
end
function Interval(J::AbstractVector{Bool}, l::Real, r::Real)
	Interval(J, deepcopy(J), deepcopy(J), l, r)
end
function Interval(Vs, l::Real, r::Real)
	Interval(Vs..., l, r)
end

struct Equal_Obj{M,KW<:NamedTuple}
	m::M
	kwargs::KW
	fcall::RefValue{Int}
end
function Equal_Obj(m, kwargs::NamedTuple=NamedTuple())
	Equal_Obj(m, kwargs, Ref(0))
end
