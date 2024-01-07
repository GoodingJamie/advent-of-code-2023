#!/usr/local/bin/julia 

using Plots

t = 0:7
d = [0, 6, 10, 12, 12, 10, 6, 0]

a = 1
T = 7
# 'continuous' 
ct = LinRange(0, 7, 1000)
cd = map(t -> a * t * (T - t), ct)

p = scatter(t, d, mc=:red, ms=5, ma=0.8)
plot!(p, ct, cd, lc=:black, lw=2)
xlabel!("Time")
ylabel!("Distance")
savefig(p, "example.pdf")