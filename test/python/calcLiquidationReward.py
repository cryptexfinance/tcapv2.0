import sys

args = sys.argv[1:]
burnAmount = int(args[0]) / 1e18
tcapPrice = int(args[1]) / 1e18
collateralPrice = int(args[2]) / 1e18
liquidationFee = int(args[3]) / 1e18

liquidationReward = (burnAmount * tcapPrice * (1 + liquidationFee)) / collateralPrice

sys.stdout.write(
    hex(int(liquidationReward * 1e18))[2:].zfill(64)
)
