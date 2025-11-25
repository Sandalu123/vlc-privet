# VLC-WiFi Hybrid Network

## 1. CORE CONFIGURATION & SETUP

## load_config.m

**Purpose** : Central configuration file that defines all system parameters
**Key Parameters** :

- Network capacity: 1000 Mbps (total)
- Simulation time: 50 steps
- User base: 20 users with ±5 variation
- Room size: 20m × 20m
- WiFi/VLC AP positions and coverage radii
- QoS weights: [0.4, 0.3, 0.2, 0.1] (Bandwidth, Delay, Jitter, BER)
- Handover threshold: 0.15
- Resource ratio: WiFi 70%, VLC 30%

**Location in Code** : Line 1-43 of load_config.m

## 2. NETWORK & USER GENERATION

## create_network.m

**Purpose** : Creates network structure with AP positions and coverage
**Outputs** : Network struct with WiFi/VLC AP positions, coverage radius, capacities
**File Size** : 12 lines

## create_hybrid_users.m

**Purpose** : Generates users with dynamic position, velocity, weight, bandwidth requests
**Key Features** :

- Random user positioning in room
- Random velocity (±0.25 m/step)
- User weight: 1-10 (priority)
- Bandwidth request: Based on Service Profile (e.g., Video 15-25 Mbps)
- Uplink Request: 20-50% of Downlink request
- Initial network assignment (VLC if within coverage, else WiFi)


**Location** : Lines 1-47 of create_hybrid_users.m

### update_user_movement.m

**Purpose** : Updates user positions each time step with boundary reflection
**Mechanics** : Users bounce off room boundaries

## 3. HANDOVER MANAGEMENT

### perform_handover.m PROPOSED ALGORITHM

### #

**Purpose** : Implements fuzzy logic-based handover mechanism
**Algorithm Steps** :

1. Find available networks for each user (within coverage radius)
2. Calculate QoS for each network:

```
o Bandwidth: max_bw * (1 - 0.7*dist/max_range) * (0.9-1.2 random)
```
```
o Delay: base_delay + (dist/max_range)*10 + random*2
o Jitter: base_jitter + (dist/max_range)*5 + random
```
```
o BER: 1e-6 * (1 + dist/max_range*10)
```
3. Apply fuzzy scoring: fuzzy_score() function (Lines 87-96)

```
o Normalizes all QoS metrics
```
```
o Weights: [0.4, 0.3, 0.2, 0.1]
o Formula: score = 0.4*bw_norm + 0.3*delay_norm + 0.2*jitter_norm + 0.1*ber_norm
```
4. Handover occurs if: best_score > current_score + handover_threshold


**Key Code Section** :

```matlab
function score = fuzzy_score(qos)
    bw_norm = min(1, max(0, qos.bandwidth / 30));
    delay_norm = max(0, min(1, 1 - qos.delay / 50));
    jitter_norm = max(0, min(1, 1 - qos.jitter / 20));
    ber_norm = max(0, min(1, 1 - log10(max(qos.ber, 1e-10)) / -3));
    
    weights = [0.4, 0.3, 0.2, 0.1];
    score = weights(1) * bw_norm + weights(2) * delay_norm + ...
            weights(3) * jitter_norm + weights(4) * ber_norm;
end
```

## 4. RESOURCE ALLOCATION

## ALGORITHMS

### wwa_algorithm.m PROPOSED ALGORITHM #2 -

### WWA

**Purpose** : Weight-weighted allocation with reduced dynamic range
**Full Name** : Weight-based allocation with weighted unions to reduce dynamic range

**Algorithm Implementation** :

Input: users[], total_capacity
Output: allocations[]

Step 1: Create Unions

- If odd users: pair from start/end, middle gets 2x
- If even users: pair from start/end

Step 2: Group Allocation

- Sum each union's request rates
- Allocate bandwidth to each group proportionally

Step 3: User-Level Allocation Within Groups

- Distribute group bandwidth by user weight

Step 4: Recycle Leftover

- If user gets more than requested, collect surplus
- Reassign surplus to needy users
- Recalculate weights among remaining users
- Repeat until convergence

**Union Creation Logic** :


- **Odd case** (n=5): [r1+r5], [r2+r4], [2*r3]
- **Even case** (n=4): [r1+r4], [r2+r3]

This reduces dynamic range by grouping extreme requests together.

### allocate_resources.m

**Purpose** : Router function that calls active allocation algorithm
**Switchable Between** :

- WBA (Weight-Based Allocation) - simpler method
- WWA (Weight-weighted Allocation) - proposed method
- Proportional allocation - baseline

**Controlled by** : set_allocation_method.m

### set_allocation_method.m

**Purpose** : Dynamically rewrites allocate_resources.m to use selected algorithm
**Methods** : 'wwa' | 'proportional' | 'wba'

## 5. NETWORK SIMULATION CORE

### split_users_by_network.m

**Purpose** : Separates users into WiFi (network_id=1) and VLC (network_id>1) groups

### merge_allocations.m

**Purpose** : Combines WiFi and VLC allocations back into user array

### record_results.m

**Purpose** : Logs metrics per time step
**Metrics Tracked** :

- Handover count
- WiFi/VLC user distribution
- **Fairness index** : (sum(ratios))² / (N * sum(ratios²))

```
o Where ratios = allocations / requests
```
- Average bandwidth allocation


**Formula** (Lines 19-27):

ratios = allocations ./ max(requests, 0.01);
if sum(ratios.^2) > 0
fairness(t) = (sum(ratios))^2 / (length(users) * sum(ratios.^2));
else
fairness(t) = 0.5;
end

### initialize_results.m

**Purpose** : Pre-allocates result arrays for simulation

## 6. MAIN SIMULATIONS

### hybrid_simulation.m

**Purpose** : Baseline simulation (WWA + Fuzzy Handover, no RL)
**Workflow** :

1. Generate users at each time step
2. Update user movement
3. Perform handover
4. Split users by network
5. Allocate resources (WWA)
6. Merge allocations
7. Record metrics
8. Repeat 50 steps

**Outputs** : Plots 9-panel visualization + performance metrics

### wwa_simulation.m

**Purpose** : Dedicated WWA algorithm testing with detailed fairness analysis
**Features** : 9 separate fairness plots showing distribution, trends, stability

### run_single_simulation.m

**Purpose** : Runs one complete simulation and returns mean fairness, throughput,
handovers


### compare_baselines.m

**Purpose** : Compares WWA vs Proportional allocation over 10 runs
**Outputs** : Bar chart comparison

## 7. REINFORCEMENT LEARNING (RL)

## LAYER

### extract_state.m RL STATE SPACE DEFINITION

**Purpose** : Converts network conditions into 12-dimensional state vector for RL
**State Components** :

state(1): WiFi user ratio
state(2): VLC user ratio
state(3): Total user density (normalized to 30)
state(4): WiFi demand ratio (normalized)
state(5): VLC demand ratio (normalized)
state(6): Current fairness index
state(7): Mean user distance to nearest AP
state(8): Handover frequency ratio
state(9): Average allocation ratio
state(10): User density with coverage ratio
state(11): Fairness improvement trend (past vs recent)
state(12): Handover frequency trend

**Code Location** : Lines 15-70 of extract_state.m

All values normalized to [0, 1] or [0, 1.5] range with NaN/Inf handling.

### calculate_reward.m RL REWARD FUNCTION

**Purpose** : Computes reward signal for RL agent
**Reward Components** :

reward = fairness_reward (45×)

- handover_penalty (35×)
+ throughput_reward (6×)
+ high_fairness_bonus (8 or 15)
+ high_throughput_bonus (10, 25, or 40)
+ low_handover_bonus (30 or 60)

Range: Clamped to [-200, 400]


**Logic** :

- Maximize fairness (primary objective)
- Minimize handovers
- Balance WiFi/VLC utilization
- Maintain fairness stability
- Reward improvement over time

**Code** : Lines 1-70 of calculate_reward.m

### define_action_space.m RL ACTION SPACE

**Purpose** : Defines 135 discrete actions (5×3×3×3)
**Action Parameters** :

- Handover threshold: [0.05, 0.10, 0.15, 0.20, 0.25] (5 values)
- WiFi ratio: [0.5, 0.6, 0.7] (3 values)
- Weight range max: [3, 5, 7] (3 values)
- QoS presets: 3 different weight combinations

**Total Actions** : 5 × 3 × 3 × 3 = **135 actions**

### define_action_space_reduced.m

**Purpose** : Simplified action space with 24 actions
**Reduced to** : 3×2×2×1×2 = **24 actions** (faster training)
**Parameters**:
- Handover Thresholds: [0.20, 0.25, 0.30]
- WiFi Ratios: [0.60, 0.70]
- Weight Max: [6, 8]
- QoS Presets: 2 options

### apply_rl_action.m

**Purpose** : Applies selected RL action to network parameters
**Modifies** :

- handover_threshold
- wifi_capacity_ratio / vlc_capacity_ratio
- weight_range
- qos_weights

## 8. RL AGENTS

### QLearningAgent.m Q-LEARNING

### IMPLEMENTATION


**Purpose** : Traditional Q-Learning agent with state discretization
**Key Components** :

- State discretization: Bins each state dimension into discrete levels
- Q-table: bins_per_dim ^ state_dim table
- Epsilon-greedy exploration
- Temporal difference update

**Algorithm** :

Q(s,a) ← Q(s,a) + α[r + γ·max_a'Q(s',a') - Q(s,a)]

Q(s,a) = Your current knowledge about taking action a in state s
α = Learning rate (0.3) - how much to update each time
r = Reward you just received
γ = Discount factor (0.9) - how much you value future rewards vs immediate ones
max_a'Q(s',a') = Best possible reward from the next state s'
[r + γ·max_a'Q(s',a') - Q(s,a)] = TD Error (difference between what you expected vs
reality)

**Key Methods** :

- select_action(): Epsilon-greedy policy
- update(): TD update
- discretize_state(): Maps continuous state to table index
- decay_epsilon(): Reduces exploration over time

**Hyperparameters** (Lines 7-12):

learning_rate: 0.012
discount_factor (gamma): 0.97
epsilon_start: 1.0
epsilon_decay: 0.9995
epsilon_min: 0.05
bins_per_dim: 4


### ThroughputQLearning.m SIMPLIFIED Q-

### LEARNING (MAIN AGENT)

**Purpose** : Lightweight Q-Learning focused on throughput with fairness penalty
**State Discretization** : Custom (not uniform binning)

- State 1: Throughput (5 bins)
- State 2: Fairness (5 bins, with thresholds at [0.85, 0.90, 0.93, 0.96])
- State 3: Handover frequency (5 bins)

**Total States** : 5³ = **125 states** (vs 100⁴ in QLearningAgent)

**Key Difference** : Adaptive binning for fairness emphasizes critical thresholds

## 9. TRAINING PIPELINE

### train_rl_agent.m

**Purpose** : Full training loop for RL agent
**Process** (per episode):

1. Create network and results array
2. For each time step:
    o Generate/update users

```
o Extract state
o Select action (ε-greedy)
```
```
o Apply RL action
o Perform handover & allocation
```
```
o Record results
o Calculate reward
```
```
o Update Q-table (if not first step)
```
3. Decay epsilon
4. Log episode statistics

**Training Outputs** :

- trained_agent.mat: Trained Q-table
- training_stats.mat: Episode metrics
- Plot visualization


**Config** : Lines 1- 30

agent = QLearningAgent(struct(
'learning_rate', 0.2,
'gamma', 0.95,
'epsilon_start', 1.0,
'epsilon_decay', 0.998,
'epsilon_min', 0.05,
'num_actions', 135,
'state_dim', 4,
'bins_per_dim', 5));

### main_rl_pipeline.m

**Purpose** : High-level orchestration of entire pipeline
**Modes** :

1. train (2000 episodes)
2. test (100 episodes)
3. wwa (WWA simulation)
4. baseline (Hybrid baseline)
5. evaluate (RL-enhanced)
6. compare (vs baseline)
7. full (all steps)
8. report (generate report)

**Interactive Menu** : Lines 35- 70

## 10. EVALUATION & ANALYSIS

### hybrid_simulation_rl.m

**Purpose** : Runs simulation using trained RL agent
**Workflow** : Same as hybrid_simulation.m but uses RL for action selection

### compare_rl_baseline.m

**Purpose** : Compares trained RL agent vs baseline (10 runs each)
**Metrics Compared** :

- Fairness (mean ± std)
- Handovers (mean ± std)
- Utilization (mean ± std)


- % Improvement calculation

### run_complete_analysis.m

**Purpose** : 4-phase complete pipeline
**Phases** :

1. Baseline comparison (WWA vs Proportional)
2. RL training with WWA
3. RL training with Proportional
4. Final comparison & report

### evaluate_system_performance.m

**Purpose** : Comprehensive performance metric calculation
**Computes** (7 categories):

1. Throughput (mean, max, utilization %)
2. Latency (network, handover, queue delays)
3. Reliability (PDR, stability, outage)
4. Fairness (Jain's index, trend, stability)
5. Energy efficiency (W/Mbps, W/user)
6. QoE (MOS scores for video, web, VoIP, gaming)
7. Summary ratings (0-1 scale for each)

**Output** : 7-metric performance struct

## 11. VISUALIZATION & REPORTING

### plot_hybrid_results.m

**Purpose** : 9-panel visualization of simulation
**Panels** :

1. Fairness over time
2. User distribution (WiFi vs VLC)
3. Handover events (stem plot)
4. Fairness histogram
5. Average bandwidth allocation
6. Fairness vs handovers (dual-axis)
7. Smoothed fairness


8. Network load distribution (area chart)
9. Cumulative handovers

### plot_training_results.m

**Purpose** : 6-panel RL training visualization
**Panels** :

1. Episode rewards
2. Average fairness per episode
3. Total handovers per episode
4. Epsilon decay
5. Smoothed rewards (50-episode moving average)
6. Smoothed fairness

### plot_baseline_comparison.m

**Purpose** : 3-panel comparison (WWA vs Proportional)

### plot_performance_evaluation.m

**Purpose** : Comprehensive performance dashboard (9 panels + radar chart + gauge)

### generate_performance_report.m

**Purpose** : Generates detailed text report (8 sections)
**Sections** :

1. Throughput Performance
2. Latency Analysis
3. Reliability Metrics
4. Fairness Analysis
5. Energy Efficiency
6. QoE (by application)
7. Summary Ratings
8. Performance Interpretation

### generate_comparison_report.m

**Purpose** : RL training summary report


## 12. UTILITIES & HELPERS

## setup_rl_environment.m

**Purpose** : Pre-training verification of all required files and functions

## setup_rl_environment.m

**Purpose** : Validates all 15+ required files exist and tests basic functions

# PROPOSED ALGORITHMS

# LOCATION SUMMARY

## ALGORITHM #1: Fuzzy Logic-Based

## Dynamic Handover

**File** : perform_handover.m
**Lines** : 87-96 (fuzzy_score function)
**Algorithm Type** : Rule-based handover with fuzzy scoring

**Key Formula** :

score = 0.4×bw_norm + 0.3×delay_norm + 0.2×jitter_norm + 0.1×ber_norm

**Decision Rule** :

if best_score > current_score + threshold:
handover_to_best_network()

## ALGORITHM #2: WWA (Weight-

## Weighted Allocation)

**File** : wwa_algorithm.m
**Lines** : 1- 50
**Algorithm Type** : Fair resource allocation with dynamic range reduction

**Key Steps** :


1. Create unions: Pair user requests from ends toward middle
2. Group allocation: Bandwidth distributed to unions proportionally
3. User-level allocation: Within groups, by user weight
4. Recycle surplus: Collect over-allocations and redistribute
5. Iterate until convergence

**Union Formula** :

Odd (n=5): [r1+r5], [r2+r4], [2×r3]
Even (n=4): [r1+r4], [r2+r3]

## ALGORITHM #3: RL-Based Adaptive

## Resource Management

**Files** :

- ThroughputQLearning.m (Agent)
- extract_state.m (State)
- calculate_reward.m (Reward)
- define_action_space_reduced.m (Actions)
- train_rl_agent.m (Training)

**Algorithm Type** : Q-Learning with continuous state discretization
**From Document** : Not explicitly detailed (extension of paper)

**State Space** : 12-dimensional
**Action Space** : 36-135 discrete actions
**Reward Components** : Fairness + Utilization - Handovers - Instability


# FAIRNESS METRIC

**Location** : record_results.m (Lines 19-27)
**Formula** (Jain's Fairness Index):

F = (Σ ratios)² / (N × Σ ratios²)

where ratios_i = allocated_i / requested_i

**Ref** : https://reimbar.org/posts/jain-fairness/

**Range** : [0, 1]

- F = 1: Perfect fairness
- F → 0: High unfairness

# SYSTEM WORKFLOW

#### START

#### ↓

[1] Generate Users + Network
↓
[2] For each time step:
├─ Update user positions

├─ PERFORM HANDOVER (Fuzzy Logic) ALGO #
├─ Split users (WiFi/VLC)

├─ ALLOCATE RESOURCES (WWA) ALGO #

├─ Extract state + Select RL action ALGO #
├─ Calculate reward
├─ Update Q-table
├─ Record fairness + metrics
└─ Loop
↓
[3] Calculate Jain's fairness index
↓
[4] Visualize + Report
↓
END


# CONFIGURATION

# PARAMETERS

All configurable in load_config.m:

- Total capacity: 1000 Mbps
- Simulation time: 50 steps
- Base users: 20 ± 5
- Room size: 20m × 20m
- WiFi capacity ratio: 70%
- VLC capacity ratio: 30%
- Handover threshold: 0.15
- QoS weights: [0.4, 0.3, 0.2, 0.1]

# TRAINING PARAMETERS

All configurable in train_rl_agent.m:

- Learning rate (α): 0.012
- Discount factor (γ): 0.97
- Epsilon start: 1.0
- Epsilon decay: 0.9995
- Epsilon min: 0.05
- Number of actions: 24 (Reduced)
- State dimensions: 4 (key features)
- Bins per dimension: 4
