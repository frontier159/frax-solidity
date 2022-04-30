// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;
pragma experimental ABIEncoderV2;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ======================= FraxUnifiedFarm_ERC20 ======================
// ====================================================================
// For ERC20 Tokens
// Uses FraxUnifiedFarmTemplate.sol

import "./FraxUnifiedFarmTemplate.sol";

// -------------------- VARIES --------------------

// G-UNI
// import "../Misc_AMOs/gelato/IGUniPool.sol";

// mStable
// import '../Misc_AMOs/mstable/IFeederPool.sol';

// StakeDAO sdETH-FraxPut
// import '../Misc_AMOs/stakedao/IOpynPerpVault.sol';

// StakeDAO Vault
// import '../Misc_AMOs/stakedao/IStakeDaoVault.sol';

// Uniswap V2
import '../Uniswap/Interfaces/IUniswapV2Pair.sol';

// Vesper
// import '../Misc_AMOs/vesper/IVPool.sol';

// ------------------------------------------------

contract FraxUnifiedFarm_ERC20 is FraxUnifiedFarmTemplate {

    /* ========== STATE VARIABLES ========== */

    // -------------------- VARIES --------------------

    // G-UNI
    // IGUniPool public stakingToken;
    
    // mStable
    // IFeederPool public stakingToken;

    // sdETH-FraxPut Vault
    // IOpynPerpVault public stakingToken;

    // StakeDAO Vault
    // IStakeDaoVault public stakingToken;

    // Uniswap V2
    IUniswapV2Pair public stakingToken;

    // Vesper
    // IVPool public stakingToken;

    // ------------------------------------------------

    // Stake tracking
    mapping(address => LockedStake[]) public lockedStakes;

    /* ========== STRUCTS ========== */

    // Struct for the stake
    struct LockedStake {
        bytes32 kek_id;
        uint256 start_timestamp;
        uint256 liquidity;
        uint256 ending_timestamp;
        uint256 lock_multiplier; // 6 decimals of precision. 1x = 1000000
    }
    
    /* ========== CONSTRUCTOR ========== */

    constructor (
        address _owner,
        address[] memory _rewardTokens,
        address[] memory _rewardManagers,
        uint256[] memory _rewardRatesManual,
        address[] memory _gaugeControllers,
        address[] memory _rewardDistributors,
        address _stakingToken
    ) 
    FraxUnifiedFarmTemplate(_owner, _rewardTokens, _rewardManagers, _rewardRatesManual, _gaugeControllers, _rewardDistributors)
    {

        // -------------------- VARIES --------------------
        // G-UNI
        // stakingToken = IGUniPool(_stakingToken);
        // address token0 = address(stakingToken.token0());
        // frax_is_token0 = token0 == frax_address;

        // mStable
        // stakingToken = IFeederPool(_stakingToken);

        // StakeDAO sdETH-FraxPut Vault
        // stakingToken = IOpynPerpVault(_stakingToken);

        // StakeDAO Vault
        // stakingToken = IStakeDaoVault(_stakingToken);

        // Uniswap V2
        stakingToken = IUniswapV2Pair(_stakingToken);
        address token0 = stakingToken.token0();
        if (token0 == frax_address) frax_is_token0 = true;
        else frax_is_token0 = false;

        // Vesper
        // stakingToken = IVPool(_stakingToken);
    }

    /* ============= VIEWS ============= */

    // ------ FRAX RELATED ------

    function fraxPerLPToken() public view override returns (uint256) {
        // Get the amount of FRAX 'inside' of the lp tokens
        uint256 frax_per_lp_token;

        // G-UNI
        // ============================================
        // {
        //     (uint256 reserve0, uint256 reserve1) = stakingToken.getUnderlyingBalances();
        //     uint256 total_frax_reserves = frax_is_token0 ? reserve0 : reserve1;

        //     frax_per_lp_token = (total_frax_reserves * 1e18) / stakingToken.totalSupply();
        // }

        // mStable
        // ============================================
        // {
        //     uint256 total_frax_reserves;
        //     (, IFeederPool.BassetData memory vaultData) = (stakingToken.getBasset(frax_address));
        //     total_frax_reserves = uint256(vaultData.vaultBalance);
        //     frax_per_lp_token = (total_frax_reserves * 1e18) / stakingToken.totalSupply();
        // }

        // StakeDAO sdETH-FraxPut Vault
        // ============================================
        // {
        //    uint256 frax3crv_held = stakingToken.totalUnderlyingControlled();
        
        //    // Optimistically assume 50/50 FRAX/3CRV ratio in the metapool to save gas
        //    frax_per_lp_token = ((frax3crv_held * 1e18) / stakingToken.totalSupply()) / 2;
        // }

        // StakeDAO Vault
        // ============================================
        // {
        //    uint256 frax3crv_held = stakingToken.balance();
        
        //    // Optimistically assume 50/50 FRAX/3CRV ratio in the metapool to save gas
        //    frax_per_lp_token = ((frax3crv_held * 1e18) / stakingToken.totalSupply()) / 2;
        // }

        // Uniswap V2
        // ============================================
        {
            uint256 total_frax_reserves;
            (uint256 reserve0, uint256 reserve1, ) = (stakingToken.getReserves());
            if (frax_is_token0) total_frax_reserves = reserve0;
            else total_frax_reserves = reserve1;

            frax_per_lp_token = (total_frax_reserves * 1e18) / stakingToken.totalSupply();
        }

        // Vesper
        // ============================================
        // frax_per_lp_token = stakingToken.pricePerShare();

        return frax_per_lp_token;
    }

    // ------ LIQUIDITY AND WEIGHTS ------

    // Calculate the combined weight for an account
    function calcCurCombinedWeight(address account) public override view
        returns (
            uint256 old_combined_weight,
            uint256 new_vefxs_multiplier,
            uint256 new_combined_weight
        )
    {
        // Get the old combined weight
        old_combined_weight = _combined_weights[account];

        // Get the veFXS multipliers
        // For the calculations, use the midpoint (analogous to midpoint Riemann sum)
        new_vefxs_multiplier = veFXSMultiplier(account);

        uint256 midpoint_vefxs_multiplier;
        if (_locked_liquidity[account] == 0 && _combined_weights[account] == 0) {
            // This is only called for the first stake to make sure the veFXS multiplier is not cut in half
            midpoint_vefxs_multiplier = new_vefxs_multiplier;
        }
        else {
            midpoint_vefxs_multiplier = (new_vefxs_multiplier + _vefxsMultiplierStored[account]) / 2;
        }

        // Loop through the locked stakes, first by getting the liquidity * lock_multiplier portion
        new_combined_weight = 0;
        for (uint256 i = 0; i < lockedStakes[account].length; i++) {
            LockedStake memory thisStake = lockedStakes[account][i];
            uint256 lock_multiplier = thisStake.lock_multiplier;

            // If the lock is expired
            if (thisStake.ending_timestamp <= block.timestamp) {
                // If the lock expired in the time since the last claim, the weight needs to be proportionately averaged this time
                if (lastRewardClaimTime[account] < thisStake.ending_timestamp){
                    uint256 time_before_expiry = thisStake.ending_timestamp - lastRewardClaimTime[account];
                    uint256 time_after_expiry = block.timestamp - thisStake.ending_timestamp;

                    // Get the weighted-average lock_multiplier
                    uint256 numerator = (lock_multiplier * time_before_expiry) + (MULTIPLIER_PRECISION * time_after_expiry);
                    lock_multiplier = numerator / (time_before_expiry + time_after_expiry);
                }
                // Otherwise, it needs to just be 1x
                else {
                    lock_multiplier = MULTIPLIER_PRECISION;
                }
            }

            uint256 liquidity = thisStake.liquidity;
            uint256 combined_boosted_amount = (liquidity * (lock_multiplier + midpoint_vefxs_multiplier)) / MULTIPLIER_PRECISION;
            new_combined_weight = new_combined_weight + combined_boosted_amount;
        }
    }

    // ------ LOCK RELATED ------

    // All the locked stakes for a given account
    function lockedStakesOf(address account) external view returns (LockedStake[] memory) {
        return lockedStakes[account];
    }

    // Returns the length of the locked stakes for a given account
    function lockedStakesOfLength(address account) external view returns (uint256) {
        return lockedStakes[account].length;
    }

    // // All the locked stakes for a given account [old-school method]
    // function lockedStakesOfMultiArr(address account) external view returns (
    //     bytes32[] memory kek_ids,
    //     uint256[] memory start_timestamps,
    //     uint256[] memory liquidities,
    //     uint256[] memory ending_timestamps,
    //     uint256[] memory lock_multipliers
    // ) {
    //     for (uint256 i = 0; i < lockedStakes[account].length; i++){ 
    //         LockedStake memory thisStake = lockedStakes[account][i];
    //         kek_ids[i] = thisStake.kek_id;
    //         start_timestamps[i] = thisStake.start_timestamp;
    //         liquidities[i] = thisStake.liquidity;
    //         ending_timestamps[i] = thisStake.ending_timestamp;
    //         lock_multipliers[i] = thisStake.lock_multiplier;
    //     }
    // }

    /* =============== MUTATIVE FUNCTIONS =============== */

    // ------ STAKING ------

    // Provided as a helper for clients for kek_id => arr_idx, 
    // and for backwards compat functions which take kek_id only.
    function getLockedStakeArrIndex(address staker_address, bytes32 kek_id) public view returns (uint256) {
        for (uint256 i = 0; i < lockedStakes[staker_address].length; i++) { 
            if (kek_id == lockedStakes[staker_address][i].kek_id) {
                return i;
            }
        }
        revert("Stake not found");
    }

    function _getStake(address staker_address, bytes32 kek_id, uint256 arr_idx) internal view returns (LockedStake memory locked_stake) {
        locked_stake = lockedStakes[staker_address][arr_idx];
        require(locked_stake.kek_id == kek_id, "Stake not found");
    }

    // Add additional LPs to an existing locked stake
    //
    // @deprecated -- idea in the new version is to pass in the arr_idx (handled off-chain) 
    //                and avoid an on-chain lockedStakes arr iteration.
    //
    // In original form, it actually iterated over lockedStakes 3x times.
    //   1. In the updateRewardAndBalance modifier (which calls calcCurCombinedWeight)
    //   2. Within _getStake (now moved to be outside, in getLockedStakeArrIndex())
    //   3. _updateRewardAndBalance is called again.
    // So if lockedStakes is a large array then it would be gassy.
    //
    //
    // For discussion: Do we need to keep this older version (on-chain arr_idx lookup)?
    //                 Is overload ok, or better to have a v2?
    function lockAdditional(bytes32 kek_id, uint256 addl_liq) public {
        // For backwards compat - look up the array idx first
        uint256 arr_idx = getLockedStakeArrIndex(msg.sender, kek_id);
        lockAdditional(kek_id, arr_idx, addl_liq);
    }

    /**
    Dependency Analysis for updateRewardAndBalance() usage...

    updateRewardAndBalance():
      Read-only:
        gaugeControllers
        rewardDistributors[i]
        rewardsDuration
        rewardTokens[i]
        _total_liquidity_locked
        stakingToken
        frax_is_token0
        veFXS
        vefxs_max_multiplier
        vefxs_boost_scale_factor
        MULTIPLIER_PRECISION
        _locked_liquidity
        lockedStakes[i]
        lastRewardClaimTime
        userRewardsPerTokenPaid[account][i]
        
      Write:
        last_gauge_relative_weights[i]
        last_gauge_time_totals[i]
        periodFinish
        rewardsPerTokenStored[i]
        lastUpdateTime
        fraxPerLPStored
        rewardRatesManual[1]   (aave aFRAX only)
        rewards[account][i]
        userRewardsPerTokenPaid[account][i]
        _vefxsMultiplierStored[account]
        _total_combined_weight
        _combined_weights[account]
    
    lockAdditional() dep analysis:
      Read-only:
        stakingToken
        valid_vefxs_proxies
        staker_designated_proxies
    
      Write:
        lockedStakes
        _total_liquidity_locked
        _locked_liquidity
        proxy_lp_balances
    */

    // Add additional LPs to an existing locked stake.
    //
    // _updateRewardAndBalance is called twice - before (with period sync) and after (no sync)
    // Question: Is this to make sure the rewardsPerTokenStored and other vars for a past reward period is calc'd using the existing lockedStakes
    //           (ie prior to this new liquidity being added)? 
    //           Not super obvious to me.
    function lockAdditional(bytes32 kek_id, uint256 arr_idx, uint256 addl_liq) updateRewardAndBalance(msg.sender, true) public {
        // Get the stake. Verifies the expected kek_id matches the stake at arr_idx.
        // NB: arr_idx can be rugged as the items in lockedStakes[staker_address] vector are pop()'d in _withdrawLocked.
        LockedStake memory thisStake = _getStake(msg.sender, kek_id, arr_idx);

        // Calculate the new amount
        uint256 new_amt = thisStake.liquidity + addl_liq;

        // Checks
        require(addl_liq >= 0, "Must be nonzero");

        // Pull the tokens from the sender
        TransferHelper.safeTransferFrom(address(stakingToken), msg.sender, address(this), addl_liq);

        // Update the stake
        lockedStakes[msg.sender][arr_idx] = LockedStake(
            kek_id,
            thisStake.start_timestamp,
            new_amt,
            thisStake.ending_timestamp,
            thisStake.lock_multiplier
        );

        // Update liquidities
        _total_liquidity_locked += addl_liq;
        _locked_liquidity[msg.sender] += addl_liq;
        {
            address the_proxy = getProxyFor(msg.sender);
            if (the_proxy != address(0)) proxy_lp_balances[the_proxy] += addl_liq;
        }

        // Need to call to update the combined weights
        _updateRewardAndBalance(msg.sender, false);
    }

    // Extend the lock period on an existing locked stake by secs
    function extendLock(bytes32 kek_id, uint256 arr_idx, uint256 secs) updateRewardAndBalance(msg.sender, true) external returns (bytes32) {
        require(stakingPaused == false || valid_migrators[msg.sender] == true, "Staking paused or in migration");

        // Get the stake
        LockedStake memory thisStake = _getStake(msg.sender, kek_id, arr_idx);

        // Can only extend a stake which is still locked.
        require(thisStake.ending_timestamp > block.timestamp, "Stake is not locked");

        uint256 newEndingTimestamp = thisStake.ending_timestamp + secs;
        uint256 newLockDurationSecs;
        unchecked {
            newLockDurationSecs = newEndingTimestamp - block.timestamp;
        }
        require(newLockDurationSecs >= lock_time_min, "Minimum stake time not met");
        require(newLockDurationSecs <= lock_time_for_max_multiplier, "Trying to lock for too long");

        // Increased lockMultiplier
        uint256 lock_multiplier = lockMultiplier(newLockDurationSecs);

        // Update the stake in place
        lockedStakes[msg.sender][arr_idx] = LockedStake(
            kek_id,
            thisStake.start_timestamp,  // Not used in weight calcs, can remain as the original lock start.
            thisStake.liquidity,
            newEndingTimestamp,
            lock_multiplier
        );
        
        // Need to call again to make sure everything is correct
        _updateRewardAndBalance(msg.sender, true);

        emit StakeLocked(msg.sender, thisStake.liquidity, newLockDurationSecs, new_kek_id, msg.sender);

        return new_kek_id;
    }

    // Two different stake functions are needed because of delegateCall and msg.sender issues (important for migration)
    function stakeLocked(uint256 liquidity, uint256 secs) nonReentrant external returns (bytes32) {
        return _stakeLocked(msg.sender, msg.sender, liquidity, secs, block.timestamp);
    }

    // If this were not internal, and source_address had an infinite approve, this could be exploitable
    // (pull funds from source_address and stake for an arbitrary staker_address)
    function _stakeLocked(
        address staker_address,
        address source_address,
        uint256 liquidity,
        uint256 secs,
        uint256 start_timestamp
    ) internal updateRewardAndBalance(staker_address, true) returns (bytes32) {
        require(stakingPaused == false || valid_migrators[msg.sender] == true, "Staking paused or in migration");
        require(secs >= lock_time_min, "Minimum stake time not met");
        require(secs <= lock_time_for_max_multiplier,"Trying to lock for too long");

        // Pull in the required token(s)
        // Varies per farm
        TransferHelper.safeTransferFrom(address(stakingToken), source_address, address(this), liquidity);

        // Get the lock multiplier and kek_id
        uint256 lock_multiplier = lockMultiplier(secs);
        bytes32 kek_id = keccak256(abi.encodePacked(staker_address, start_timestamp, liquidity, _locked_liquidity[staker_address]));
        
        // Create the locked stake
        lockedStakes[staker_address].push(LockedStake(
            kek_id,
            start_timestamp,
            liquidity,
            start_timestamp + secs,
            lock_multiplier
        ));

        // Update liquidities
        _total_liquidity_locked += liquidity;
        _locked_liquidity[staker_address] += liquidity;
        {
            address the_proxy = getProxyFor(staker_address);
            if (the_proxy != address(0)) proxy_lp_balances[the_proxy] += liquidity;
        }
        
        // Need to call again to make sure everything is correct
        _updateRewardAndBalance(staker_address, false);

        emit StakeLocked(staker_address, liquidity, secs, kek_id, source_address);

        return kek_id;
    }

    // ------ WITHDRAWING ------

    // Two different withdrawLocked functions are needed because of delegateCall and msg.sender issues (important for migration)
    function withdrawLocked(bytes32 kek_id, address destination_address) nonReentrant external returns (uint256) {
        require(withdrawalsPaused == false, "Withdrawals paused");

        // Backwards compat - lookup the index of the stake item first.
        uint256 arr_idx = getLockedStakeArrIndex(msg.sender, kek_id);
        return _withdrawLocked(msg.sender, destination_address, kek_id, arr_idx);
    }

    // Overloaded to take the arr_idx such that it can be computed off-chain.
    // Two different withdrawLocked functions are needed because of delegateCall and msg.sender issues (important for migration)
    function withdrawLocked(bytes32 kek_id, uint256 arr_idx, address destination_address) nonReentrant external returns (uint256) {
        require(withdrawalsPaused == false, "Withdrawals paused");
        return _withdrawLocked(msg.sender, destination_address, kek_id, arr_idx);
    }

    // No withdrawer == msg.sender check needed since this is only internally callable and the checks are done in the wrapper
    // functions like migrator_withdraw_locked() and withdrawLocked()
    function _withdrawLocked(
        address staker_address,
        address destination_address,
        bytes32 kek_id,
        uint256 arr_idx
    ) internal returns (uint256) {
        // Collect rewards first and then update the balances
        _getReward(staker_address, destination_address, true);

        // Get the stake and its index
        LockedStake memory thisStake = _getStake(staker_address, kek_id, arr_idx);
        require(block.timestamp >= thisStake.ending_timestamp || stakesUnlocked == true || valid_migrators[msg.sender] == true, "Stake is still locked!");
        uint256 liquidity = thisStake.liquidity;

        if (liquidity > 0) {
            // Update liquidities
            _total_liquidity_locked = _total_liquidity_locked - liquidity;
            _locked_liquidity[staker_address] = _locked_liquidity[staker_address] - liquidity;
            {
                address the_proxy = getProxyFor(staker_address);
                if (the_proxy != address(0)) proxy_lp_balances[the_proxy] -= liquidity;
            }

            // Remove the stake from the array
            // Move the last element into this slot, then pop the last element to reclaim storage.
            // NB: This changes the order, clients will have to handle the arr_idx change.
            lockedStakes[staker_address][arr_idx] = lockedStakes[staker_address][lockedStakes[staker_address].length - 1];
            lockedStakes[staker_address].pop();

            // Give the tokens to the destination_address
            // Should throw if insufficient balance
            stakingToken.transfer(destination_address, liquidity);

            // Need to call again to make sure everything is correct
            _updateRewardAndBalance(staker_address, false);

            emit WithdrawLocked(staker_address, liquidity, kek_id, destination_address);
        }

        return liquidity;
    }


    function _getRewardExtraLogic(address rewardee, address destination_address) internal override {
        // Do nothing
    }

     /* ========== RESTRICTED FUNCTIONS - Curator / migrator callable ========== */

    // Migrator can stake for someone else (they won't be able to withdraw it back though, only staker_address can). 
    function migrator_stakeLocked_for(address staker_address, uint256 amount, uint256 secs, uint256 start_timestamp) external isMigrating {
        require(staker_allowed_migrators[staker_address][msg.sender] && valid_migrators[msg.sender], "Mig. invalid or unapproved");
        _stakeLocked(staker_address, msg.sender, amount, secs, start_timestamp);
    }

    // Used for migrations
    function migrator_withdraw_locked(address staker_address, bytes32 kek_id) external isMigrating {
        require(staker_allowed_migrators[staker_address][msg.sender] && valid_migrators[msg.sender], "Mig. invalid or unapproved");
        uint256 arr_idx = getLockedStakeArrIndex(msg.sender, kek_id);
        _withdrawLocked(staker_address, msg.sender, kek_id, arr_idx);
    }
    
    /* ========== RESTRICTED FUNCTIONS - Owner or timelock only ========== */

    // Inherited...

    /* ========== EVENTS ========== */

    event StakeLocked(address indexed user, uint256 amount, uint256 secs, bytes32 kek_id, address source_address);
    event WithdrawLocked(address indexed user, uint256 liquidity, bytes32 kek_id, address destination_address);
}
