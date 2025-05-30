function zero_margin(obj::Objective{TestObj}, i, zleft, zright)
	δ, S, val = obj.f.δ, obj.f.S, obj.f.val
	f = range(0.1, length=S, step=0.1)
	ℒ1 = setindex(obj.ℒ, true, i)
	ℒ0 = setindex(obj.ℒ, false, i)
	z = f[i] / (sum(i->ℒ1[i]*val[i], 1:S)^δ - sum(i->ℒ0[i]*val[i], 1:S)^δ)
	obj = addfcall(obj, 2) # Needed for maxfcall to work
	return z, obj
end

function equal_obj(obj1::Objective{TestObj}, obj2::Objective{TestObj}, zleft, zright)
	δ, S, val = obj1.f.δ, obj1.f.S, obj1.f.val
	f = range(0.1, length=S, step=0.1)
	z = sum(i->obj1.ℒ[i]*val[i], 1:S)^δ - sum(i->obj2.ℒ[i]*val[i], 1:S)^δ
	z = sum(i->(obj1.ℒ[i]-obj2.ℒ[i])*f[i], 1:S) / z
	obj1 = addfcall(obj1, 2) # Needed for maxfcall to work
	return z, obj1
end

@testset "SqueezingPolicy" begin
	f = TestObj(1.5, 10, v)
	obj = Objective(f, SVector{10,Bool}(trues(10)))
	p = init(SqueezingPolicy, obj, 10, false, equal_obj, (-Inf, Inf); zero_margin)
	@time solve!(p);

	@test p.x.cutoffs ≈ [-Inf, 0.4705380164247549, 0.5811985707132651, 0.5910258492101572,
		0.6559185330002524, 0.8052845010662988, 40.44680615292511]
	@test findall(p.x.itemstates_s[2] .== included) == [1,2,6,8]
	@test findall(p.x.itemstates_s[3] .== included) == [1,2,5,6,8]
	@test findall(p.x.itemstates_s[4] .== included) == [1,2,5,6,8,9]
	@test findall(p.x.itemstates_s[5] .== included) == [1:6...,8,9]
	@test findall(p.x.itemstates_s[6] .== included) == [1:6...,8:10...]

	# refinement only
	p0 = init(SqueezingPolicy, obj, 10, false, equal_obj, (p.x.cutoffs[2], last(p.x.cutoffs)); zero_margin)
	@time solve!(p0; refinementonly = true)
	@test p0.x == p.x[2:end-1]

	# Use Default_Zero_Margin
	p1 = init(SqueezingPolicy, obj, 10, false, equal_obj, (-Inf, Inf))
	@time solve!(p1);
	@test p1.x == p.x

	p2 = init(SqueezingPolicy, obj, 10, false, Equal_Obj(Roots.Order1()), (-Inf, Inf))
	@time solve!(p2);
	@test p2.x.itemstates_s == p.x.itemstates_s
	@test p2.x.cutoffs ≈ p.x.cutoffs atol=1e-8

	p3 = init(SqueezingPolicy, obj, 10, false, equal_obj, (-Inf, Inf); zero_margin)
	@time solve!(p3);
	@test p3.x.itemstates_s == p.x.itemstates_s
	@test p3.x.cutoffs ≈ p.x.cutoffs atol=1e-8

	f = TestObj(0.25, 10, v)
	obj = Objective(f, SVector{10,Bool}(trues(10)))
	p = init(SqueezingPolicy, obj, 10, true, equal_obj, (-Inf, Inf); zero_margin)
	@time solve!(p);

	@test p.x.cutoffs ≈ [-Inf, 0.14148816109753773, 1.2729439592296217, 2.36954935176131,
		3.141838673348731, 5.619051140627841, 11.138003949478707, 14.010847831463815,
		18.10966757034304, 19.287030294614915, 26.385707657641486, 1417.5118285950603]
	@test findall(p.x.itemstates_s[2] .== included) == [1]
	@test findall(p.x.itemstates_s[3] .== included) == [1,2]
	@test findall(p.x.itemstates_s[4] .== included) == [1,6]
	@test findall(p.x.itemstates_s[5] .== included) == [1,2,6]
	@test findall(p.x.itemstates_s[6] .== included) == [1,2,6,8]
	@test findall(p.x.itemstates_s[7] .== included) == [1,2,5,6,8]
	@test findall(p.x.itemstates_s[8] .== included) == [1,2,5,6,8,9]
	@test findall(p.x.itemstates_s[9] .== included) == [1,2,3,5,6,8,9]
	@test findall(p.x.itemstates_s[10] .== included) == [1:6...,8,9]
	@test findall(p.x.itemstates_s[11] .== included) == [1:6...,8:10...]

	p1 = init(SqueezingPolicy, obj, 10, true, equal_obj, (-Inf, Inf); zero_margin)
	@time solve!(p1);
	@test p1.x.itemstates_s == p.x.itemstates_s
	@test p1.x.cutoffs ≈ p.x.cutoffs atol=1e-8

	f = TestObj(0.75, 10, v)
	obj = Objective(f, SVector{10,Bool}(trues(10)))
	p1 = init(SqueezingPolicy, obj, 10, true, equal_obj, (-Inf, Inf); zero_margin)
	@time solve!(p1);

	@test p1.x.cutoffs ≈ [-Inf, 0.2832437310101619, 0.6857035921447168, 0.8760196369273678,
		0.9238909114659961, 1.3723336411432008, 2.333946876012932, 2.697236328631773,
		3.282285962843947, 3.401442745510605, 4.460867313570078, 233.2431869924403]
	@test p1.x.itemstates_s == p.x.itemstates_s

	p2 = init(SqueezingPolicy, obj, 10, true, equal_obj, (-Inf, Inf); zero_margin)
	@time solve!(p2);
	@test p2.x.itemstates_s == p1.x.itemstates_s
	@test p2.x.cutoffs ≈ p1.x.cutoffs atol=1e-8

	N = 20
	v1 = rand(N)
	f = TestObj(1.2, N, v1)
	obj = Objective(f, SVector{N,Bool}(trues(N)))
	p = init(SqueezingPolicy, obj, N, false, equal_obj, (-Inf, Inf); zero_margin)
	@time solve!(p);

	# Check results from the single-type problem at points near cutoffs
	for k in 2:length(p.x.cutoffs)
		p1 = init(Squeezing, obj, N, false,
			z=0.99*p.x.cutoffs[k]+0.01*max(-0.1,p.x.cutoffs[k-1]))
		solve!(p1)
		@test p1.x == p.x.itemstates_s[k-1]
		if k < length(p.x.cutoffs)
			p1 = init(Squeezing, obj, N, false,
				z=0.99*p.x.cutoffs[k]+0.01*p.x.cutoffs[k+1])
		else
			p1 = init(Squeezing, obj, N, false, z=p.x.cutoffs[k]+1)
		end
		solve!(p1)
		@test p1.x == p.x.itemstates_s[k]
	end

	f = TestObj(0.5, N, v1)
	obj = Objective(f, SVector{N,Bool}(trues(N)))
	p = init(SqueezingPolicy, obj, N, true, equal_obj, (-Inf, Inf); zero_margin)
	@time solve!(p);
	policy0 = deepcopy(p.x)

	for k in 2:length(p.x.cutoffs)
		p1 = init(Squeezing, obj, N, true,
			z=0.99*p.x.cutoffs[k]+0.01*max(-0.1,p.x.cutoffs[k-1]))
		solve!(p1)
		@test p1.x == p.x.itemstates_s[k-1]
		if k < length(p.x.cutoffs)
			p1 = init(Squeezing, obj, N, true,
				z=0.99*p.x.cutoffs[k]+0.01*p.x.cutoffs[k+1])
		else
			p1 = init(Squeezing, obj, N, true, z=p.x.cutoffs[k]+1)
		end
		solve!(p1)
		@test p1.x == p.x.itemstates_s[k]
	end

	# Verify restart is working
	N = 20
	f = TestObj(1.2, N, v1)
	obj = Objective(f, SVector{N,Bool}(trues(N)))
	p = init(SqueezingPolicy, obj, N, false, equal_obj, (-Inf, Inf); zero_margin)
	@time solve!(p);

	f = TestObj(0.5, N, v1)
	obj = Objective(f, SVector{N,Bool}(trues(N)))
	solve!(p; restart=true, obj=obj, scdca=true)
	@test p.x == policy0
end
