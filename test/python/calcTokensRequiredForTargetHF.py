import sys

args = sys.argv[1:]
collateralDecimals = int(args[6])
targetHealthFactor = int(args[0]) / 1e18
mintAmount = int(args[1]) / 1e18
tcapPrice = int(args[2]) / 1e18
collateralAmount = int(args[3]) / 10 ** collateralDecimals
collateralPrice = int(args[4]) / 1e18
liquidationPenalty = int(args[5]) / 1e18

if (1 + liquidationPenalty >= targetHealthFactor):
    raise Exception("targetHealthFactor is too low")

tokensRequired = ((collateralAmount*collateralPrice/tcapPrice) - (targetHealthFactor*mintAmount))/(1+liquidationPenalty-targetHealthFactor)

tokensRequired = max(0, tokensRequired)

sys.stdout.write(
    # abi encode uint256
    hex(int(tokensRequired * 1e18))[2:].zfill(64)
)
