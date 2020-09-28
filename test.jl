include("CoinCard.jl")

P = CoinCard.CoinProblem(coins=CoinCard.CanadianCoins())
CoinCard.CoinProblem!(P, 86., 54.)
CoinCard.CoinProblem!(P, [5*i for i in 1:100])
print(P)
CoinCard.getCoinLayout(P, max_margin = 0.1)
CoinCard.generateSVG(P)
CoinCard.generateSCAD(P)
